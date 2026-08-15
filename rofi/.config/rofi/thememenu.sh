#! /usr/bin/env bash

# Dotfiles directory
DOTFILES_DIR="$HOME/dotfiles"
cd "$DOTFILES_DIR" || exit 1

# Find all of the dotfiles excluding "common", "wallpapers" and hidden files
THEMES=$(find "$DOTFILES_DIR" -maxdepth 1 -mindepth 1 -type d ! -name "common" ! -name "wallpapers" ! -name ".*" -exec basename {} \;)

# Promt user with rofi
CHOSEN_THEME=$(echo "$THEMES" | rofi -dmenu -i -p "Select Theme:" -theme "theme.rasi")

# Exit if user pressed ESC (exited rofi)
if [ -z "$CHOSEN_THEME" ]; then
    exit 0
fi

cd "$DOTFILES_DIR" || exit 1

# Unstow all existing theme packages to avoid symlink conflicts
for theme in $THEMES; do
    stow -t "$HOME" -d "$DOTFILES_DIR" -D "$theme" 2>/dev/null
done

# Stow the newly selected theme
stow -t "$HOME" -d "$DOTFILES_DIR" "$CHOSEN_THEME"

# Kill all waybar sessions (launching waybar is included in sway config so if we restart waybar here we get 2 waybar sessions)
if pgrep -x "waybar" 2>/dev/null; then
    killall waybar
fi

# Reload swaync (if running) 
if pgrep -x "swaync" 2>/dev/null; then
    swaync-client -R -rs 2>/dev/null
fi

# Reload sway
if pgrep -x "sway" 2>/dev/null; then
    swaymsg reload
fi

# Show notification
notify-send "Theme Switcher" "Applied theme: $CHOSEN_THEME. Use super+shift+w to change wallpaper" 
