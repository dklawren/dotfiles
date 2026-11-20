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

- Compositors: `niri/` (KDL), `sway/` (+ `swaylock/`; see Sway desktop below), `fedora-hypr/` &
  `omarchy-hypr/` (Hyprland variants)
- Bars: `waybar/`
- Notifications: `swaync/` (used by Sway), `mako/`, `dunst/`
- OSD: `swayosd/`
- Launchers: `fuzzel/` (used by Sway), `rofi/`, `wofi/`
- Terminal config for Sway: `ghostty/`
- Output/display: `kanshi/`

`niri/.config/niri/config.kdl` includes the other KDL files (`binds.kdl`,
`inputs.kdl`, `outputs.kdl`, `layout.kdl`, `windowrules.kdl`, `startup.kdl`);
respect that include structure and KDL syntax when editing.

## Sway desktop (Ubuntu laptop, Gruvbox)

The active Sway setup targets an Ubuntu laptop with GDM kept as the login
manager (Sway appears as a session; GNOME stays as the alternative). Packages
come from `bin/.local/bin/install-sway-ubuntu.sh`, then `stow .`.

- `sway/.config/sway/config` sets variables/palette and includes
  `config.d/*.conf`: `10-appearance` (gaps, thin borders, no rounded corners,
  wallpaper), `20-input` (US layout, tap-to-click, natural scroll, lid
  switch), `30-keybindings`, `40-startup` (autostart + swayidle).
- `15-workspaces`: with both monitors, workspace 1 is on the laptop panel and 2-10 on the Dell (falls back to one monitor); kanshi `desk` profile puts the laptop on the left.
- Modifier is `Super`; focus/move with arrows or hjkl; terminal is `ghostty`.
- Wallpaper: `sway/.config/sway/wallpapers/gruvbox.png`, set via
  `output * bg` in `10-appearance.conf` (sway draws it; no swaybg needed).
- Notifications + control center: `swaync/` (config.json + style.css).
- Volume/mic/brightness OSD: `swayosd/` (`swayosd-server` started by sway;
  keys call `swayosd-client`). Brightness uses the `intel_backlight` device
  explicitly (the NVIDIA one does not work) in the keybindings, swayidle dim,
  waybar, and swaync.
- Launcher/menus: `fuzzel` (also used in `--dmenu` mode by the power menu and
  clipboard picker). Clipboard history: `cliphist` + `wl-clipboard`.
- Lock/idle: `swaylock` + `swayidle` (dim 5m, lock 10m, screen off 15m,
  suspend 30m on battery only, via `sway-idle-suspend`; Waybar `idle_inhibitor`
  blocks all of them). Lid close locks, or disables the internal panel when an
  external monitor is attached.
- Night light: `wlsunset` (fixed 07:00-19:00 schedule, 3500K) via
  `sway-nightlight`; Waybar has a toggle. Screen recording: `wf-recorder`.
- Keyboard shortcuts are documented in `KEYBOARD.md`; update it when bindings change.
- Helper scripts live in `bin/.local/bin/sway-*` (`lock`, `lid`, `powermenu`,
  `clipboard`, `screenshot`, `record`, `nightlight`, `idle-suspend`). Screenshots use
  `grim`/`slurp`/`swappy`.
- Portals: `xdg-desktop-portal/.config/xdg-desktop-portal/sway-portals.conf`
  (wlr for screencast, gtk fallback). Display profiles: `kanshi/`.

## Theming (color schemes)

**Catppuccin Mocha** is the color scheme for most apps. The Sway desktop
(`sway/`, `waybar/`, `swaync/`, `swayosd/`, `swaylock/`, `fuzzel/`, `ghostty/`)
uses **Gruvbox dark** instead (accent `#83a598`), also baked into each config. There is no runtime theme switching and no `theme` stow package.

- `alacritty/.config/alacritty/alacritty.toml` — inline `[colors.*]` palette
- `tmux/.config/tmux/tmux.conf` — `catppuccin-tmux` plugin + status config
- `rofi/.config/rofi/themes/layout.rasi` — `* { ... }` palette variables
- Sway (Gruvbox) palettes are inline in: `sway/.config/sway/config`,
  `waybar/.config/waybar/style.css`, `swaync/.config/swaync/style.css`,
  `swayosd/.config/swayosd/style.css`, `swaylock/.config/swaylock/config`,
  `fuzzel/.config/fuzzel/fuzzel.ini`, `ghostty/.config/ghostty/config`
- `nvim/.config/nvim/lua/config/lazy.lua` — colorscheme `"catppuccin"` (mocha)

To change a color, edit the relevant file directly and reload the app.

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
- `ubuntu.sh` — Ubuntu/Debian base; `install-sway-ubuntu.sh` — packages for the
  Gruvbox Sway desktop (run before `stow .`)
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
