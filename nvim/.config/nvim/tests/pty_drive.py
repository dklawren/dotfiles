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

for path in (status_path, status_path + ".heart"):
    if os.path.exists(path):
        os.remove(path)

def heartbeat(status_path):
    """How the editor was still ticking when a step stopped arriving."""
    try:
        with open(status_path + ".heart") as fh:
            beats = fh.read().count("tick")
    except OSError:
        return "and nothing was ticking"
    return f"and the editor had ticked {beats} times" if beats else "and the editor never ticked"


def exited(wait_status):
    """What became of the editor, which a run with no result has to say."""
    if wait_status is None:
        return "and it was still running"
    return f"and it had exited, status {wait_status}"


pid, fd = pty.fork()
if pid == 0:
    os.environ["PICKER_STATUS"] = status_path
    os.environ["PICKER_HEART"] = status_path + ".heart"
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
wait_status = None
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


def pump(timeout):
    """Read what the editor has drawn, or nothing, or None when it has gone."""
    global screen, tail
    ready, _, _ = select.select([fd], [], [], timeout)
    if not ready:
        return b""
    try:
        chunk = os.read(fd, 65536)
    except OSError:
        return None
    if not chunk:
        return None
    screen = (screen + chunk)[-8000:]
    # Counted in what has just arrived rather than in the whole screen: a query
    # can scroll out of the last few kilobytes before we look, and a query can
    # also be split across two reads.
    seen = tail + chunk
    for query, reply in ANSWERS.items():
        asked = answered[query] + seen.count(query)
        while answered[query] < asked:
            answered[query] += 1
            os.write(fd, reply)
    tail = seen[-8:]
    return chunk


def pace(seconds):
    """Wait between keys without blocking the editor on a full terminal.

    A tty holds a few kilobytes. An editor that is drawing a picker fills that
    while nobody reads it, and it stops inside the write, timers included, so a
    fixed sleep between steps turns every heavy step into a stall. Read while
    waiting instead, which is also what a terminal a person is typing at does.
    """
    end = time.time() + seconds
    while True:
        left = end - time.time()
        if left <= 0:
            return
        pump(min(left, 0.02))

# How long to keep the terminal if nothing ends the run. A test that expects
# the nvim to quit says so through PTY_DEADLINE, so a hop that never completes
# is reported in seconds rather than in a minute of silence.
deadline = time.time() + float(os.environ.get("PTY_DEADLINE", "60"))
# A loaded machine drives the same steps more slowly, so the total deadline is
# generous and progress is what is watched instead: a step that never answers is
# reported in a stall interval, not at the end of the whole run.
stall = float(os.environ.get("PTY_STALL", "120"))
progress = time.time()
last_step = "the first step"
while time.time() < deadline:
    if time.time() - progress > stall:
        print(f"no step for {int(stall)}s, stuck at {last_step}, {heartbeat(status_path)}", file=sys.stderr)
        print("screen:", screen.decode("utf8", "replace"), file=sys.stderr)
        sys.exit(1)
    chunk = pump(0.2)
    if chunk is None:
        break
    names = []
    if os.path.exists(status_path):
        with open(status_path) as fh:
            names = [line for line in fh.read().split("\n") if line]
    if len(names) > sent:
        name = names[sent]
        sent += 1
        progress = time.time()
        last_step = name
        if name == "done":
            continue
        if name not in keys:
            print(f"no keys registered for step {name!r}", file=sys.stderr)
            sys.exit(2)
        # One write for the whole sequence. A byte at a time is not how a
        # terminal delivers a key: Neovim reads ESC on its own as <Esc>, so an
        # arrow key typed slowly comes in as <Esc> then "[B".
        os.write(fd, keys[name])
        pace(0.2)
    reaped, wait_status = os.waitpid(pid, os.WNOHANG)
    if reaped:
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
    print(f"the script wrote no result after {sent} steps, last was {last_step}, {heartbeat(status_path)}, {exited(wait_status)}", file=sys.stderr)
    print("screen:", screen.decode("utf8", "replace"), file=sys.stderr)
    status = 1
sys.exit(status)
