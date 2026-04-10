#! /bin/bash

# Define wallpaper save paths and file names
SCRIPT_PATH=$(realpath $0)
WALLPAPER_DIR="$HOME/Pictures/BingWallpaper"
WALLPAPER_FILE="$WALLPAPER_DIR/bing_wallpaper_$(date +%Y%m%d)_original.jpg"
BLURRED_FILE="$WALLPAPER_DIR/bing_wallpaper_$(date +%Y%m%d)_blurred.jpg"
MAX_WALLPAPERS=8 # Set the maximum number of wallpapers reserved
SWAYLOCK_CONFIG="$HOME/.config/swaylock/config"
DEFAULT_SWAYLOCK_CONFIG="/etc/swaylock/config"
SWAY_CONFIG="$HOME/.config/sway/config"
DEFAULT_SWAY_CONFIG="$HOME/etc/sway/config"

# Create wallpaper directory (if it doesn't exist)
mkdir -p "$WALLPAPER_DIR"

# Get Bing Daily Wallpaper URL
BING_URL="https://www.bing.com/HPImageArchive.aspx? format=js&idx=0&n=1&mkt=en-US"
IMAGE_URL=$(curl -s "$BING_URL" | jq -r '.images[0].url' | sed 's/^/https:\\/www.bing.com/')

# Download wallpaper (if the wallpaper does not exist)
if [! -f "$WALLPAPER_FILE"] then
    curl -s -o "$WALLPAPER_FILE" "$IMAGE_URL"
fi

# If the wallpaper is downloaded successfully or exists on the same day wallpaper
if [ -f "$WALLPAPER_FILE"]; then

    #************ Set wallpaper ******************************************************
    Creating a Blurred Version
    if [! -f "$BLURRED_FILE"]; then
        convert "$WALLPAPER_FILE" -blur 0x8 "$BLURRED_FILE"
    fi

    # Handle the swaylock configuration file
    if [ -f "$SWAYLOCK_CONFIG"]; then
        # Modify the image= lines directly if the user profile exists
        sed -i "s|^image=.*$|image=$BLUURRED_FILE|" "$SWAYLOCK_CONFIG"
    else
        # Copy and modify from /etc/swaylock/config if the user profile does not exist
        if [ -f "$DEFAULT_SWAYLOCK_CONFIG"]; then
            mkdir -p "$(dirname "$SWAYLOCK_CONFIG")"
            cp "$DEFAULT_SWAYLOCK_CONFIG" "$SWAYLOCK_CONFIG"
            sed -i "s|^image=.*$|image=$BLUURRED_FILE|" "$SWAYLOCK_CONFIG"
        else
            # If /etc/swaylock/config does not exist, create a basic configuration file
            mkdir -p "$(dirname "$SWAYLOCK_CONFIG")"
            cat << EOF > $SWAYLOCK_CONFIG
# The defaults below could be overridden in \$XDG_CONFIG_HOME/swaylock/config
# (~/.config/swaylock/config)
#
# Image path supports environment variables and shell extensions,
# e.g. image=\$HOME/Pictures/default.png
# image=/usr/share/backgrounds/default.png
image=$Blurred_File
scaling = fill
EOF
        fi
    fi

    # Modify the output * bg line in ~/.config/sway/config
    if [ -f "$SWAY_CONFIG"]; then
        Check if the output * bg line exists and replace it
        if grep -q "^output \* bg" "$SWAY_CONFIG"; then
            sed -i "s|^output \* bg .*|output * bg $WALPAPER_FILE fill|" "$SWAY_CONFIG"
        else
            If there is no line, append to the end of the file
            echo "output * bg $WALLPAPER_FILE fill" >> "$SWAY_CONFIG"
        fi
    else
        if [ -f "$DEFAULT_SWAY_CONFIG"] then
            mkdir -p "$(dirname "$SWAY_CONFIG")"
            cp "$DEFAULT_SWAY_CONFIG" "$SWAY_CONFIG"
            Check if the output * bg line exists and replace it
            if grep -q "^output \* bg" "$SWAY_CONFIG"; then
                sed -i "s|^output \* bg .*|output * bg $WALPAPER_FILE fill|" "$SWAY_CONFIG"
            else
                If there is no line, append to the end of the file
                echo "output * bg $WALLPAPER_FILE fill" >> "$SWAY_CONFIG"
            fi
        else
            mkdir -p "$(dirname "$SWAY_CONFIG")"
            echo "output * bg $WALPAPER_FILE fill" > "$SWAY_CONFIG"
        fi
    fi

    Get the current swaybg PID
    OLD_PID=$(pidof swaybg)
    Start a new swaybg instance
    swaybg -i "$WALLPAPER_FILE" -m fill &
    Waiting for a new instance to be completed
    Sleep 1
    Kill the old example (if it exists)
    if [ -n "$OLD_PID"]; then
        kill "$OLD_PID"
    fi

    #****** delete redundant historical wallpaper ******
    # Use ls -t sort by time, list all jpg files, skip the latest n, delete the rest
    OLD_FILES=()
    mapfile -t TO_DELETE_ORIGINAL <<(ls -t "$WALLPAPER_DIR"/bing_wallpaper_*_original.jpg 2>/dev/null | tail -n +$((MAX_WALLPAPERS + 1)))
    OLD_FILES+=("${TO_DELETE_ORIGINAL[@]}")

    mapfile -t TO_DELETE_BLURRED <<(ls -t "$WALLPAPER_DIR"/bing_wallpaper_*_blurred.jpg 2>/dev/null | tail -n +$((MAX_WALLPAPERS + 1)))
    OLD_FILES+=("${TO_DELETE_BLURRED[@]}")
    if [ ${#OLD_FILES[@]} -gt 0]; then
        rm -f "${OLD_FILES[@]}"
    fi
fi

# Set the systemd refresh timer
REFRESH_DUE_H="24"
REFRESH_DUE_M="5"
TIMER_FILE="$HOME/.config/systemd/user/bing-wallpaper.timer"
TIMER_SERVICE="$HOME/.config/systemd/user/bing-wallpaper.service"

API_URL="https://www.bing.com/HPImageArchive.aspx? format=js&idx=0&n=1"
FULLSTARTDATE=$(curl -s "$API_URL" | grep -m 1 -o '"fullstartdate":"[^"]*"' | sed 's/"fullstartdate":"\(. *\)"/\1/')
# FULLSTARTDATE=$(curl -s "$API_URL" | awk -F'"' '{for (i=1; i<=NF; i++); if ($i=="fullstartdate") {print $(i+2); exit}}')

Check to see if it was successful
if [ -z "$FULLSTARTDATE"]; then
    echo "You can't get fullstartdate, check if the network or API is available."
    NEXT_RUN_TIME=$(TZ=$(timedatectl | grep "Time zone" | awk '{print $3}') date -d "+ $REFRESH_DUE_H hours $REFRESH_DUE_M minutes" "+%Y-%m-%d %H:%M:%S")
else
    FULLSTARTDATE_FMT=$(date -d "${FULLSTARTDATE:0:8} ${FULLSTARTDATE:8:2}:${FULLSTARTDATE:10:2}" "+%Y-%m-%d %H:%M UTC")
    NEXT_RUN_TIME=$(TZ=$(timedatectl | grep "Time zone" | awk '{print $3}') date -d "$FULLSTARTDATE_FMT + $REFRESH_DUE_H hours $REFRESH_DUE_M minutes" "+%Y-%m-%d %H:%M:%S")
fi

If there is no timed service file
if [! -f "$TIMER_SERVICE"]; then
    mkdir -p "$(dirname "$TIMER_SERVICE")"
    cat << EOF > $TIMER_SERVICE
[Unit]
Description=Example of one-time task at a specific time
After=graphical-session.target
Wants=graphical-session.target

[Service]
ExecStart=$SCRIPT_PATH
Type = oneshot
RemainAfterExit=no
KillMode = process
EOF
fi

If there is no timer file
if [ -f "TIMER_FILE"]; then
    sed -i "s|^OnCalendar=. *$|OnCalendar=$NEXT_RUN_TIME|" "$TIMER_FILE"
else
    mkdir -p "$(dirname "$TIMER_FILE")"
    cat << EOF > $TIMER_FILE
[Unit]
Description=Temporal task example for a specific time

[Timer]
OnCalendar=$NEXT_RUN_TIME
Persistent = true
OnBootSet = 1 min
Unit=bing-wallpaper.service

[Install]
WantedBy=timers.target
EOF
fi

systemctl --user daemon-reload
if [! -f "$HOME/.config/systemd/user/timers.target.target.wants/bing-wallpaper.timer"]; then
    systemctl --user enable bing-wallpaper.timer
fi
systemctl --user restart bing-wallpaper.timer

