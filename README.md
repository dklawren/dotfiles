# Dotfiles — fresh workstation setup

Personal dotfiles managed with **GNU Stow**. A single Ansible playbook
provisions either an **Ubuntu workstation** or a **Fedora Silverblue** host
from scratch, then configures an identical `fedora` distrobox dev environment
on both.

The entire desktop uses one baked-in color scheme: **Catppuccin Mocha**. There
is no theme switcher; colors are inline in each app's config.

## What you get

Both targets end up with the same end state:

- **Host**
  - User `dkl` (uid 1000) with passwordless sudo
  - A shared flatpak app list (flathub + flathub-beta + gnome-nightly remotes)
  - A `fedora:latest` distrobox container (`fedora`)
- **Dev** (inside the `fedora` distrobox — identical on both host OSes)
  - dnf dev packages (cargo, gh, neovim, zsh, stow, podman-docker, yazi, …)
  - rustup + cargo tools (zoxide, eza, worktrunk, perl-lsp, foxtail, stylua)
  - opencode, Linuxbrew, nvm/node + global `neovim`, gh extensions (gh-dash,
    gh-stack), pyenv, lazydocker, `code-review-graph`
  - Shell: oh-my-zsh + zsh-autosuggestions, starship, tpm/tmux plugins, perl
    local::lib + modules, `zsh` as default shell
  - Dotfiles cloned to `~/.dotfiles` and linked with `stow .`

Per-distro host differences:

| | Ubuntu | Fedora Silverblue |
|---|---|---|
| Packages | `apt` (from `apt_packages` in `ansible/group_vars/ubuntu.yml`) | rpmfusion free+nonfree, docker-ce repo, `rpm-ostree` layered packages (akmod-nvidia, docker-ce, onedrive, syncthing, …) |
| Services | ufw enabled, local-RTC, user `syncthing` | `docker.service`, user `syncthing` + `onedrive` |
| Reboot needed | no | yes, after layering packages |

## Prerequisites

- Freshly installed OS, network connection
- Create the first-boot account as **`dkl`** with UID 1000 and sudo rights
- Ubuntu additionally needs `podman` (distrobox backend used by the playbook)

## Install on Ubuntu

1. Install Ubuntu and log in as `dkl`.
2. Install prerequisites:
   ```bash
   sudo apt update && sudo apt install -y git ansible podman
   ```
3. Get the repo:
   ```bash
   git clone https://github.com/dklawren/dotfiles.git
   cd dotfiles
   ```
4. Install Ansible collections:
   ```bash
   ansible-galaxy collection install -r ansible/requirements.yml
   ```
5. Run the playbook (prompts for the sudo password):
   ```bash
   ansible-playbook ansible/main.yml -K
   ```
6. Verify:
   ```bash
   distrobox enter fedora
   zsh --version && starship --version
   ```

## Install on Fedora Silverblue

1. Install Silverblue and log in as `dkl`.
2. Layer `ansible` (rpm-ostree packages require a reboot before use):
   ```bash
   sudo rpm-ostree install ansible
   sudo reboot
   ```
3. Get the repo and install collections:
   ```bash
   git clone https://github.com/dklawren/dotfiles.git
   cd dotfiles
   ansible-galaxy collection install -r ansible/requirements.yml
   ```
4. Run the playbook (prompts for the sudo password):
   ```bash
   ansible-playbook ansible/main.yml -K
   ```
5. The playbook layers more packages (nvidia, docker, onedrive, …) — it ends
   with a reboot warning. Reboot so they become active:
   ```bash
   sudo reboot
   ```
6. Verify:
   ```bash
   distrobox enter fedora
   docker --version      # docker-ce, layered on the host
   ```

## What the playbook does

Entry point: `ansible/main.yml` — two plays.

**Play 1 — provision host** (`host` inventory group, local connection)
1. `host/user.yml` — create user `dkl` + `/etc/sudoers.d/10-dkl` NOPASSWD
2. `host/packages.yml` — dispatch on `ansible_distribution`:
   - `host/packages_ubuntu.yml` — apt packages
   - `host/packages_fedora.yml` — RPM Fusion + docker-ce repo + rpm-ostree layer
3. `host/services.yml` — enable-linger; Ubuntu ufw/local-RTC/syncthing, Fedora
   docker/syncthing/onedrive
4. `host/flatpaks.yml` — flatpak remotes + shared app list (as `dkl`)
5. `host/distrobox.yml` — create + start the `fedora` container if absent
6. Reboot warning when Silverblue layered new packages

**Play 2 — provision dev environment** (`devbox` inventory group, podman
connection into the `fedora` container)
1. `dev/bootstrap.yml` — `dnf install python3 python3-pip` (needed for the podman connection)
2. `dev/packages.yml` — dnf speed-up, repos (copr lazygit/act-cli/yazi,
   hashicorp, google-cloud), dev package list, `distrobox-host-exec` symlinks
3. `dev/tools.yml` — rustup + cargo tools, opencode, Linuxbrew, nvm/node, gh
   extensions, pyenv, lazydocker, `code-review-graph`
4. `dev/shell.yml` — oh-my-zsh, starship, tpm + plugins, perl modules, `chsh zsh`
5. `dev/dotfiles.yml` — clone repo → `~/.dotfiles`, `stow .`

## Day-to-day

- **Edit a config**: edit the source file under this repo (e.g.
  `waybar/.config/waybar/config`) — the live file in `~/.config/...` is a
  symlink back here. Do not edit `~/.config/...` directly.
- **Re-link after adding files**: `stow .` from the repo root.
- **Sync from remote**: `~/.local/bin/stow-dotfiles` (git stash + pull + stash
  pop + stow).
- **Verify a change**: reload the app (reload the compositor, restart the bar,
  re-source the shell) — there is no test suite.

## Notes

- `ansible-playbook ansible/main.yml -K` prompts for the become (sudo) password.
- Containers use **podman**, not Docker; `docker`/`dc` aliases and
  `DOCKER_HOST` point at the podman socket.
- On Silverblue, layering packages with `rpm-ostree` requires a reboot before
  the packages are usable.
- The legacy shell scripts in `bin/.local/bin/` (`ubuntu.sh`, `silverblue.sh`,
  `terminal.sh`, …) are the older manual provisioning path and are superseded
  by the Ansible playbook.
