# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository for a Fedora Linux system using the Niri window manager with Noctalia desktop environment. Configuration files are organized by application/tool and managed using GNU Stow for symlink management.

## Repository Structure

Configuration files are organized into directories by application:
- `nvim/` - Multiple Neovim configurations (nvim-custom, nvim-lazyvim, nvim-bare)
- `niri/` - Niri window manager configuration (KDL format)
- `noctalia/` - Noctalia desktop environment settings (JSON)
- `alacritty/` - Terminal emulator configuration
- `helix/` - Helix editor configuration
- `yazi/` - File manager configuration
- `bash/`, `zsh/` - Shell configurations
- `environment/` - Shared shell environment (.aliases, .functions, .exports, .path, .helpers)
- `tmux/` - Terminal multiplexer configuration
- `git/` - Git configuration
- `bin/` - Local scripts and utilities
- `containers/` - Podman/systemd container configurations
- Other directories for desktop-related tools (waybar, rofi, sway, etc.)

## Dotfile Management

This repository uses **GNU Stow** for managing dotfiles:

```bash
# Install/link all dotfiles
stow .

# Sync dotfiles from remote (includes stash, pull, pop, and stow)
~/.local/bin/stow-dotfiles

# Manual git operations for dotfiles
git --git-dir=$HOME/.dotfiles --work-tree=$HOME <command>
# Or use the alias:
config <command>
```

The `stow-dotfiles` script at `bin/.local/bin/stow-dotfiles` handles syncing with git remote and re-stowing after updates.

## Key Configuration Locations

### Shell Environment
- Main shell configs: `bash/.bashrc`, `zsh/.zshrc`
- Shared environment files in `environment/`:
  - `.aliases` - Command aliases (git, docker, podman, navigation shortcuts)
  - `.functions` - Shell functions (y() for yazi, docker/podman cleanup, etc.)
  - `.exports` - Environment variable exports
  - `.path` - PATH modifications
  - `.helpers` - Helper utilities

Both bash and zsh source these shared files for consistent environment.

### Editors
**Neovim**: Multiple configurations available via NVIM_APPNAME:
- `nvim-custom/` - Custom configuration using lazy.nvim plugin manager
  - Uses Lazy.nvim with plugins organized in `lua/plugins/`
  - Leader key: Space
  - Maplocalleader: Backslash
- `nvim-lazyvim/` - LazyVim distribution (alias: `nvim-lazy`)
- `nvim-bare/` - Minimal configuration

**Helix**: Configuration at `helix/.config/helix/config.toml`
- Theme: dark_plus
- Keybindings customized for buffer navigation

### Window Manager & Desktop
**Niri**: Wayland compositor configured via KDL files in `niri/.config/niri/`:
- `config.kdl` - Main config that includes other files
- `binds.kdl` - Key bindings
- `inputs.kdl` - Input device configuration
- `outputs.kdl` - Monitor configuration
- `layout.kdl` - Window layout rules
- `windowrules.kdl` - Per-application window rules
- `startup.kdl` - Autostart applications
- `noctalia.kdl` - Noctalia integration

**Noctalia**: Desktop environment configuration in JSON format:
- `settings.json` - Main settings (bar, dock, widgets, theming)
- `colors.json` - Color scheme (Material You style with mPrimary, mSecondary, etc.)
- Extensible via plugins in `noctalia/.config/noctalia/plugins/`
- Templates enabled for: alacritty, fuzzel, gtk, niri, qt, yazi

### Terminal
**Alacritty**: `alacritty/.config/alacritty/alacritty.toml`
- Font: Fira Code Nerd Font Mono, size 12
- Shell: zsh
- Colors: Tokyo Night theme
- Noctalia theme available but commented out

### File Manager
**Yazi**: Configuration in `yazi/.config/yazi/`
- Helper function `y()` in `.functions` for directory navigation on exit

## Development Environment

### Language-specific tools
- **Node.js**: nvm managed, config at `~/.config/nvm`
- **Python**: pyenv, virtualenv workflows via aliases (`venv`, `ae`, `de`)
- **Perl**: local::lib setup, cpanm available
- **Rust**: Cargo environment sourced
- **Docker/Podman**: Extensive aliases and cleanup functions

### Container Management
Systemd container units in `containers/.config/containers/systemd/`:
- `open-webui.container`
- `silverbullet.container`

## Common Workflows

### Making Configuration Changes
1. Edit files in this repository
2. Changes are automatically reflected (files are symlinked via stow)
3. For Niri: Changes to KDL files require reload or restart
4. For Noctalia: Settings.json changes are typically hot-reloaded

### Syncing Dotfiles
```bash
stow-dotfiles  # Pulls from remote, handles conflicts, re-stows
```

### Switching Neovim Configs
```bash
nvim          # Default (nvim-custom)
nvim-lazy     # LazyVim
nvim-kick     # Kickstart
nvim-chad     # NvChad
nvim-astro    # AstroNvim
```

### Shell Features
- **oh-my-zsh** with extensive plugins (git, docker, fzf, systemd, etc.)
- **starship** prompt
- **zoxide** for directory jumping (aliased as `cd`)
- **fzf** for fuzzy finding
- **bat** (aliased as `cat`)
- **eza** (aliased as `ls`, `ll`, `la`)

## Important Notes

- This is a Fedora-specific setup with paths assuming `/var/home/dkl/`
- Many configs reference `$HOME/.local/bin` for custom scripts
- Git worktree aliases available via `gwt`
- Extensive use of modern CLI tools (bat, eza, zoxide, yazi, fzf)
- Noctalia generates templates for configured applications (alacritty, niri, etc.)
- When editing Niri config files, respect KDL syntax and the include structure
- When editing Noctalia configs, settings.json uses a specific schema with versioning
