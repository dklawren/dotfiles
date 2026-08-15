#! /bin/bash

option=$(printf "Shutdown\nReboot\nLogout\nLock" | rofi -dmenu -p "Powermenu" -theme "powermenu.rasi")

case "$option" in
    "Shutdown")poweroff;;
    "Reboot")reboot;;
    "Logout")loginctl terminate-user $USER;;
    "Lock")swaylock;;
esac
