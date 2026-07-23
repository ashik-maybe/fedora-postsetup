#!/usr/bin/env bash

set -e

# 1. Check if the current desktop environment is GNOME
if [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* ]]; then
    echo "Error: This script is intended for GNOME desktop environments."
    echo "Current desktop: ${XDG_CURRENT_DESKTOP:-Unknown}"
    exit 1
fi

echo "==> GNOME detected. Proceeding..."

# 2. Install extensions via DNF
echo "==> Installing GNOME extensions via DNF..."
sudo dnf install -y \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-dash-to-dock \
    gnome-shell-extension-caffeine

echo "==> Installation complete!"
echo ""

# 3. Print usage instructions
cat << 'EOF'
====================================================================
               GNOME Extensions Management Commands
====================================================================

NOTE: If these extensions don't show up immediately, log out and log
back in so GNOME Shell can discover the newly installed packages.

--- LIST EXTENSIONS ---
  List installed extensions:
    gnome-extensions list

  List only enabled extensions:
    gnome-extensions list --enabled

  List extensions with extra details (UUID, status, description):
    gnome-extensions list --verbose

--- ENABLE / DISABLE EXTENSIONS ---
  Enable an extension:
    gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com
    gnome-extensions enable dash-to-dock@micxgx.gmail.com
    gnome-extensions enable caffeine@ealessio.github.com

  Disable an extension:
    gnome-extensions disable <extension-uuid>

  Disable ALL extensions globally:
    gsettings set org.gnome.shell disable-user-extensions true

  Re-enable ALL extensions globally:
    gsettings set org.gnome.shell disable-user-extensions false

--- QUICK TROUBLESHOOTING ---
  Check an extension's status:
    gnome-extensions info <extension-uuid>

====================================================================
EOF
