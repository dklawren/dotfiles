# Install Hyprland packages
sudo dnf -y copr enable solopasha/hyprland/
sudo dnf -y copr enable errornointernet/walker

sudo dnf -y install --skip-broken --skip-unavailable \
   blueman \
   elephant \
   hyperpanel \
   hypridle \
   hyprland \
   hyprlock \
   hyprpanel \
   hyprpaper \
   hyprshot \
   hyprsunset \
   mako \
   pseudo \
   walker \
   waybar \
   wl-clipboard \
   xarchiver
