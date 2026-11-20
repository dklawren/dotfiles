# Sway keyboard shortcuts

`Super` is the modifier (`$mod`). Source: `sway/.config/sway/config.d/30-keybindings.conf`
(and `20-input.conf` for the lid switch). Keep this file in sync when bindings change.

## Apps and system

| Keys | Action |
|---|---|
| `Super+Enter` | Terminal (ghostty) |
| `Super+D` / `Super+Space` | App launcher (fuzzel) |
| `Super+V` | Clipboard history |
| `Super+/` | Window switcher (all windows) |
| `Super+N` | Toggle notification center |
| `Super+Shift+N` | Toggle Do Not Disturb |
| `Super+Esc` | Lock screen |
| `Super+Shift+E` | Power menu (lock, logout, suspend, reboot, shutdown) |
| `Super+Shift+C` | Reload sway config |
| `Super+Shift+Q` | Close focused window |

## Focus and move windows

| Keys | Action |
|---|---|
| `Super+H/J/K/L` or `Super+←/↓/↑/→` | Focus left/down/up/right |
| `Super+Shift+H/J/K/L` or `Super+Shift+←/↓/↑/→` | Move window left/down/up/right |
| `Super+Tab` | Toggle focus between tiling and floating |
| `Super+A` | Focus parent container |
| `Super+Shift+Grave` (backtick) | Move window to scratchpad |
| `Super+Grave` (backtick) | Show/cycle scratchpad |
| `Super+Left mouse drag` | Move floating window |
| `Super+Right mouse drag` | Resize floating window |

## Layout

| Keys | Action |
|---|---|
| `Super+\` | Split horizontally |
| `Super+-` | Split vertically |
| `Super+S` | Stacking layout |
| `Super+W` | Tabbed layout |
| `Super+E` | Toggle split layout |
| `Super+F` | Fullscreen |
| `Super+Shift+Space` | Toggle floating |
| `Super+R` | Enter resize mode |

**Resize mode:** `H/J/K/L` or arrows resize (left shrinks width, down grows height, up shrinks height, right grows width) in 40px steps. `Enter` or `Esc` exits.

## Workspaces

| Keys | Action |
|---|---|
| `Super+1` … `Super+9`, `Super+0` | Go to workspace 1–10 |
| `Super+Shift+1` … `Super+Shift+0` | Move window to workspace 1–10 |
| `Super+Ctrl+←` / `Super+Ctrl+H` | Previous workspace |
| `Super+Ctrl+→` / `Super+Ctrl+L` | Next workspace |
| `Super+Ctrl+Shift+←/→` or `+H/L` | Move workspace to left/right monitor |

Pressing the key for the workspace you are already on jumps back to the previous one.

## Media, volume, brightness

These also work while the screen is locked.

| Keys | Action |
|---|---|
| `XF86AudioRaiseVolume` / `XF86AudioLowerVolume` | Volume +/− 5% (OSD) |
| `XF86AudioMute` | Mute toggle |
| `XF86AudioMicMute` | Mic mute toggle |
| `XF86MonBrightnessUp` / `XF86MonBrightnessDown` | Brightness +/− (intel_backlight, OSD) |
| `XF86AudioPlay` / `XF86AudioNext` / `XF86AudioPrev` | Play-pause / next / previous |

## Screenshots, recording, night light

| Keys | Action |
|---|---|
| `Print` | Screenshot: select area |
| `Shift+Print` | Screenshot: full screen |
| `Ctrl+Print` | Screenshot: select area, then edit (swappy) |
| `Super+Print` | Screenshot: focused window |
| `Super+Shift+R` | Start/stop region screen recording |
| `Super+Shift+T` | Toggle night light |

Screenshots go to `~/Pictures/Screenshots` and the clipboard; recordings to `~/Videos/Recordings`.

## Other triggers

| Event | Action |
|---|---|
| Laptop lid closed | Lock (suspends) if alone; disable internal panel if an external monitor is connected |
| Laptop lid opened | Re-enable internal panel |
| Idle 5 / 10 / 15 / 30 min | Dim / lock / screen off / suspend (suspend on battery only; Waybar idle toggle blocks all) |
