#!/usr/bin/env python3
"""Drive a Neovim in a real pty and type at it, step by step.

The Lua script under test calls `step("name")` to say it is ready for the keys
registered under that name. This waits for the name, sends the keys, and moves
on. Headless Neovim has no input loop, so insert mode and key mappings cannot
be exercised there; a pty is the only way to type at it honestly.

usage: pty_drive.py <keys-file> <status-file> <result-file> -- <nvim> [args...]
keys file: one `name<TAB>hex-encoded-keys` per line.
"""

import binascii
import fcntl
import os
import pty
import re
import select
import struct
import sys
import termios
import time

KEYS_INDEX = sys.argv.index("--")
keys_path, status_path, result_path = sys.argv[1:KEYS_INDEX]
cmd = sys.argv[KEYS_INDEX + 1 :]

keys = {}
with open(keys_path) as fh:
    for line in fh:
        line = line.rstrip("\n")
        if not line or line.startswith("#"):
            continue
        name, _, hexkeys = line.partition("\t")
        keys[name] = binascii.unhexlify(hexkeys.strip())

for path in (status_path,):
    if os.path.exists(path):
        os.remove(path)

pid, fd = pty.fork()
if pid == 0:
    os.environ["PICKER_STATUS"] = status_path
    os.environ["PICKER_RESULT"] = result_path
    # The caller's TERM is whatever the CI shell had, and nvim will not read
    # keys at all without a terminal type it knows.
    os.environ["TERM"] = "xterm-256color"
    os.environ["LINES"] = "40"
    os.environ["COLUMNS"] = "120"
    os.execvp(cmd[0], cmd)

fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 120, 0, 0))

sent = 0
screen = b""
# A terminal is asked who it is before a UI will attach to it, and Neovim gives
# up on the TUI if nothing answers ("TUI: timed out waiting for DA1 response").
# A pty is not a terminal, so answer here: primary device attributes, and the
# background colour it asks for next, which is a warning when unanswered.
ANSWERS = {
    b"\x1b[c": b"\x1b[?1;2c",  # DA1: a VT100 with advanced video options
    b"\x1b]11;?\x07": b"\x1b]11;rgb:1e1e/1e1e/1e1e\x07",  # background colour
    b"\x1b]10;?\x07": b"\x1b]10;rgb:cdcd/d7d7/eeee\x07",  # foreground colour
}
answered = dict.fromkeys(ANSWERS, 0)
tail = b""
# How long to keep the terminal if nothing ends the run. A test that expects
# the nvim to quit says so through PTY_DEADLINE, so a hop that never completes
# is reported in seconds rather than in a minute of silence.
deadline = time.time() + float(os.environ.get("PTY_DEADLINE", "60"))
while time.time() < deadline:
    ready, _, _ = select.select([fd], [], [], 0.2)
    if ready:
        try:
            chunk = os.read(fd, 65536)
        except OSError:
            break
        if not chunk:
            break
        screen = (screen + chunk)[-8000:]
        # Counted in what has just arrived rather than in the whole screen: a
        # query can scroll out of the last few kilobytes before we look, and a
        # query can also be split across two reads.
        seen = tail + chunk
        for query, reply in ANSWERS.items():
            asked = answered[query] + seen.count(query)
            while answered[query] < asked:
                answered[query] += 1
                os.write(fd, reply)
        tail = seen[-8:]
    names = []
    if os.path.exists(status_path):
        with open(status_path) as fh:
            names = [line for line in fh.read().split("\n") if line]
    if len(names) > sent:
        name = names[sent]
        sent += 1
        if name == "done":
            continue
        if name not in keys:
            print(f"no keys registered for step {name!r}", file=sys.stderr)
            sys.exit(2)
        # One write for the whole sequence. A byte at a time is not how a
        # terminal delivers a key: Neovim reads ESC on its own as <Esc>, so an
        # arrow key typed slowly comes in as <Esc> then "[B".
        os.write(fd, keys[name])
        time.sleep(0.2)
    if os.waitpid(pid, os.WNOHANG)[0]:
        break

# The pty is a screen, not a log, so the script reports through a file.
status = 0
if os.path.exists(result_path):
    with open(result_path) as fh:
        report = fh.read()
    print(report, end="" if report.endswith("\n") or not report else "\n")
    match = re.search(r"failures=(\d+)", report)
    status = 1 if match and int(match.group(1)) else 0
else:
    print(f"the script wrote no result after {sent} steps", file=sys.stderr)
    print("screen:", screen.decode("utf8", "replace"), file=sys.stderr)
    status = 1
sys.exit(status)
