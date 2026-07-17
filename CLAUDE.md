# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles for Linux, managed with **GNU Stow**. The setup targets
multiple distros (Fedora and Ubuntu/Debian) and multiple Wayland compositors
(Niri, Sway, and Hyprland variants), so many configs come in parallel
alternatives rather than a single canonical stack.

## Stow package model (most important thing to understand)

Each top-level directory is a **stow package** whose internal layout mirrors the
target relative to `$HOME`. For example:

- `zsh/.zshrc` → `~/.zshrc`
- `sway/.config/sway/...` → `~/.config/sway/...`
- `bin/.local/bin/stow-dotfiles` → `~/.local/bin/stow-dotfiles`

Running `stow .` from the repo root symlinks every package into `$HOME`. When
adding a new config file, place it at the path under a package dir that matches
where it must land in `$HOME` — do not edit `~/.config/...` directly, edit the
source here (the live file is a symlink back into this repo).

```bash
stow .                    # link/relink all packages into $HOME
stow <package>            # link a single package, e.g. `stow sway`
~/.local/bin/stow-dotfiles  # git stash + pull origin main + stash pop + stow .
```

`bin/.local/bin/stow-dotfiles` is the normal sync path; it handles pulling from
the remote and re-stowing. It aborts stowing if the stash-pop produces merge
conflicts.

Note: `.aliases` also defines `config='git --git-dir=$HOME/.dotfiles ...'`, a
*separate* bare-repo mechanism. This stow repo is the source of truth; the
`config` alias is legacy and unrelated to the files here.

## Shared shell environment

`bash/.bashrc` and `zsh/.zshrc` both source the files in `environment/` so the
two shells stay consistent. Edit these rather than the per-shell rc files for
anything that should apply to both:

- `environment/.aliases` — the live, maintained alias set (git, docker/podman,
  nvim variants, eza/bat/zoxide shortcuts, navigation)
- `environment/.exports` — env vars (Wayland/Qt/Moz vars, `EDITOR=nvim`,
  pyenv/perl paths)
- `environment/.path` — PATH assembly; **note** it sets
  `DOCKER_HOST=unix:///run/user/1000/podman/podman.sock` so `docker` talks to
  podman
- `environment/.functions` — shell functions (`y()` for yazi cd-on-exit,
  container cleanup, Mozilla bastion SSH helpers)
- `environment/.helpers` — older grab-bag; contains **macOS leftovers**
  (`pbcopy`, `open`) that don't apply on Linux — don't treat it as canonical

Shell stack: oh-my-zsh + starship prompt, zoxide (aliased over `cd`), fzf, `bat`
(aliased `cat`), `eza` (aliased `ls`/`ll`/`la`).

## Desktop config alternatives

Because the repo spans several compositors, expect overlapping packages. Know
which one you're editing:

- Compositors: `niri/` (KDL), `sway/` (+ `swaylock/`), `fedora-hypr/` &
  `omarchy-hypr/` (Hyprland variants)
- Bars: `waybar/`
- Notifications: `mako/`, `dunst/`
- Launchers: `fuzzel/`, `rofi/`, `wofi/`
- Output/display: `kanshi/`

`niri/.config/niri/config.kdl` includes the other KDL files (`binds.kdl`,
`inputs.kdl`, `outputs.kdl`, `layout.kdl`, `windowrules.kdl`, `startup.kdl`);
respect that include structure and KDL syntax when editing.

## Editors

**Neovim** — multiple configs selected via `NVIM_APPNAME` (aliases in
`.aliases`): `nvim` (default), `nvim-lazy` (LazyVim), `nvim-kick`, `nvim-chad`,
`nvim-astro`. Source configs live under `nvim/.config/` (`nvim-custom`,
`nvim-lazyvim`, `nvim-bare`); generated files like `lazy-lock.json` and `pack/`
are gitignored.

**Helix** — `helix/.config/helix/config.toml`.

## Install / provisioning scripts

Provisioning is script-per-target under `bin/.local/bin/` — pick the one
matching the machine; there is no single bootstrap entrypoint:

- `workstation.sh` — Fedora workstation (dnf repos + package install)
- `ubuntu.sh`, `install-sway-ubuntu.sh` — Ubuntu/Debian
- `silverblue.sh`, `sericea.sh` — Fedora Atomic variants
- `omarchy.sh`, `hyprland.sh`, `sway.sh` — desktop-specific setup
- `terminal.sh` — shell tooling (oh-my-zsh, starship, tmux TPM, perl modules)
- `distrobox.sh`, `flatpaks.sh`, `flatpak-backup.sh`, `backup.sh` — container /
  package / backup helpers

## Containers

The user runs **podman**, not Docker (see the podman note in the global
CLAUDE.md). Compose routes through podman; `docker`/`dc` aliases and
`DOCKER_HOST` all point at the podman socket. `systemd/.config/systemd/` holds
user-level unit symlinks.

## Conventions

- These are dotfiles, not an application — there is no build/lint/test suite.
  "Verifying" a change means reloading the relevant tool (reload the compositor,
  restart the bar, re-source the shell) rather than running a test command.
- Paths and package managers are distro-specific; a command in one install
  script (e.g. `dnf`) won't apply on another target (`apt`). Match the script
  to the machine.
