# Personal CLAUDE.md

## Container tooling

I use **podman**, not Docker. The `docker compose` CLI on my machine routes
through the podman-compose provider, so project instructions that say
`docker compose ...` work as-is, with one caveat:

- The podman API socket must be running first, otherwise compose fails with
  "Cannot connect to the Docker daemon at .../podman/podman.sock".
  Start it with:

  ```bash
  systemctl --user start podman.socket
  ```

- Equivalently, `podman-compose` can be substituted for `docker compose` in
  any project command.

# General guidance when wrking on coding tasks
Before you touch anything, tell me in 2–3 sentences what you think I'm after and what problem we're solving. Start only after I say yes.

When there's a tradeoff, weigh all three:
→ UX: is it easy for users to use?
→ DX: is it easy for developers to change later?
→ AX: can the next agent understand it and keep going?

Don't touch anything outside this task, and don't break anything that already works. When you're done, tell me in 2–3 lines what you picked, what you gave up, and why.
