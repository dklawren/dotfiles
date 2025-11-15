# Initialize flatpak support
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak remote-add --if-not-exists gnome-nightly https://nightly.gnome.org/gnome-nightly.flatpakrepo
flatpak install https://gitlab.com/projects261/firefox-nightly-flatpak/-/raw/main/firefox-nightly.flatpakref
flatpak update --appstream
flatpak update

# Remove fedora flatpak repo
flatpak install --reinstall flathub $(flatpak list --app-runtime=org.fedoraproject.Platform --columns=application | tail -n +1 )
flatpak remote-delete fedora

# Install addition flatpak apps
flatpak install -y --or-update flathub \
  ca.desrt.dconf-editor \
  com.github.alexkdeveloper.somafm \
  com.github.johnfactotum.Foliate \
  com.github.d4nj1.tlpui \
  com.github.tchx84.Flatseal \
  com.google.Chrome \
  com.jeffser.Alpaca \
  com.jeffser.Alpaca.Plugins.Ollama \
  com.mattjakeman.ExtensionManager \
  com.slack.Slack \
  com.transmissionbt.Transmission \
  com.ultimaker.cura \
  com.usebottles.bottles \
  io.github.alexkdeveloper.radio \
  io.github.flattool.Warehouse \
  io.gitlab.adhami3310.Impression \
  io.gitlab.librewolf-community \
  io.missioncenter.MissionCenter \
  io.podman_desktop.PodmanDesktop \
  it.mijorus.gearlever \
  md.obsidian.Obsidian \
  me.iepure.devtoolbox \
  org.cockpit_project.CockpitClient \
  org.gnome.Firmware \
  org.gnome.SimpleScan \
  org.gnome.Solanum \
  org.gnome.World.PikaBackup \
  org.libreoffice.LibreOffice \
  org.mamedev.MAME \
  org.mozilla.firefox \
  org.videolan.VLC \
  us.zoom.Zoom \
  dev.geopjr.Tuba \
  org.gnome.gitlab.cheywood.Pulp \
  org.localsend.localsend_app \
  org.gnome.Fractal \
  it.mijorus.gearlever \
  de.capypara.FieldMonitor \
  com.spotify.Client \
  me.iepure.devtoolbox \
  io.github.kolunmi.Bazaar

flatpak install -y --or-update flathub-beta org.mozilla.Thunderbird
flatpak install -y --or-update firefoxnightly-origin org.mozilla.FirefoxNightly

# Enable Wayland support for Thunderbird
sudo flatpak override --system --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.Thunderbird

# Themes
sudo flatpak override --system --filesystem=xdg-data/themes
