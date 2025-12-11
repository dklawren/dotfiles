#!/bin/bash
flatpak list --app --columns=installation,ref > ~/devel/flatpak-apps.txt
flatpak remotes --columns=name,url > ~/devel/flatpak-remotes.txt
flatpak override --show > ~/devel/flatpak-overrides.txt
echo "Flatpak backup completed on $(date)" >> ~/devel/flatpak-backup.log
