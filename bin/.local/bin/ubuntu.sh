# Install some stuff
sudo apt update && sudo apt upgrade -y && apt install \
	alacritty \
	distrobox \
  flatpak gnome-software-plugin-flatpak \
  fstrim \
  gnome-session \
	gnome-software-plugin-flatpak \
  gnupg \
  libfuse2t64 \
  preload \
  software-properties-gtk \
	syncthing \
  timsehift \
  ubuntu-restricted-extras \
  wget

# Remove some stuff
sudo apt remove --purge \
  libreoffice* \
  firefox

# Turn on firewall
sudo ufw enable
timedatectl set-local-rtc 1

# Turn on syncthing
sudo systemctl daemon-reload
echo "fs.inotify.max_user_watches=204800" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w fs.inotify.max_user_watches=204800
systemctl --user --now enable syncthing

# Add Flathub repo
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.mozilla.thunderbird

# Remove Snap support
sudo snap remove --purge firefozx
sudo snap remove --purge firefox
sudo snap remove --purge thunderbird
sudo snap remove --purge gnome-46-2404
sudo snap remove --purge desktop-security-center
sudo snap remove --purge gtk-common-themes
sudo snap remove --purge core24
sudo snap remove --purge core24 mesa-2404
sudo snap remove --purge mesa-2404
sudo snap remove --purge core24 mesa-2404
sudo snap remove --purge core24
sudo snap remove --purge snapd-desktop-integration
sudo snap remove --purge prompting-client
sudo snap remove --purge bare
sudo snap remove --purge core24
sudo snap remove --purge snapd
sudo apt remove --autoremove snapd
sudo umount /run/snapd/ns
sudo rm -rf /snap

sudo tee /etc/apt/preferences.d/no-snap.pref <<'EOF'
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF

# Install Firefox deb repo
sudo install -d -m 0755 /etc/apt/keyrings
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla
sudo apt update
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null
sudo apt install firefox

# Install additional drivers
sudo ubuntu-drivers install

# Turn off apparmor
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="apparmor=0 /' /etc/default/grub
sudo update-grub

# Cleanup
sudo apt autoremove
