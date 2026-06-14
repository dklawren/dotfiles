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
