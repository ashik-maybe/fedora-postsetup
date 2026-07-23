#!/usr/bin/env bash

set -e

# 1. Check if the current desktop environment is GNOME
if [[ "$XDG_CURRENT_DESKTOP" != *"GNOME"* ]]; then
    echo "Error: This script is intended for GNOME desktop environments."
    echo "Current desktop: ${XDG_CURRENT_DESKTOP:-Unknown}"
    exit 1
fi

echo "==> GNOME detected. Proceeding..."

# 2. Install the extension via DNF
echo "==> Installing gnome-shell-extension-appindicator..."
sudo dnf install -y gnome-shell-extension-appindicator

# 3. Enable the extension
EXTENSION_UUID="appindicatorsupport@rgcjonas.gmail.com"

echo "==> Enabling extension: $EXTENSION_UUID..."
gnome-extensions enable "$EXTENSION_UUID"

echo "==> Done! AppIndicator support is installed and enabled."
