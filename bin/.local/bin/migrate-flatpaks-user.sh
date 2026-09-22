#!/bin/bash
# Migrate system-installed flatpaks to user space. App data in ~/.var/app
# is shared between system and user installs, so nothing is lost.
set -uo pipefail

flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

apps=$(flatpak list --system --app --columns=application 2>/dev/null | grep -v '^$' || true)

if [[ -z "$apps" ]]; then
  echo "No system-installed flatpaks to migrate."
  exit 0
fi

count=0
failed=0

for app in $apps; do
  if flatpak install --user --noninteractive "$app"; then
    flatpak uninstall --system -y "$app"
    count=$((count + 1))
    echo "migrated: $app"
  else
    failed=$((failed + 1))
    echo "WARN: could not install $app in user space, left system copy in place" >&2
  fi
done

echo "Migrated $count app(s) to user space, $failed failed."

if (( failed == 0 )); then
  echo "Optional cleanup (system remotes no longer needed):"
  echo "  sudo flatpak remote-delete --system flathub-beta"
  echo "  sudo flatpak remote-delete --system gnome-nightly"
fi
