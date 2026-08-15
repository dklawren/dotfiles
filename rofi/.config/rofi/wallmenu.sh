#! /bin/bash

# define wallpapers directory
WALL_DIR="$HOME/.config/sway/wallpapers"

# list the pictures
SELECTED=$(ls -1 "$WALL_DIR" | rofi -dmenu -i -p "Select Wallpaper:" -theme "theme.rasi")

# check selected wallpaper and create full path
if [ -n "$SELECTED" ]; then
    FULL_PATH="$WALL_DIR/$SELECTED"

# Create/Update persistent symlink for wallpaper (is required to make wallpapers set by script persistent)
    ln -sf "$FULL_PATH" "$HOME/.config/sway/wallpaper"

# Reload output command so wallpaper gets updated live on screen
    swaymsg "output * bg $HOME/.config/sway/wallpaper fill"

fi
