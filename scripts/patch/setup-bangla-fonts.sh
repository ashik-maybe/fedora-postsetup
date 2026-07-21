#!/usr/bin/env bash

# Exit on error, unset variable, or failed pipe
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log "Starting Bangla Font Setup..."

# 1. Install Google Noto Bengali Fonts via DNF
log "Installing Noto Bengali packages from Fedora repositories..."
sudo dnf install -y \
  google-noto-sans-bengali-fonts \
  google-noto-sans-bengali-ui-fonts \
  google-noto-serif-bengali-fonts

# 2. Generate Fontconfig Setup for UI & Document Fallbacks
log "Creating local font configuration (~/.config/fontconfig/fonts.conf)..."
mkdir -p "$HOME/.config/fontconfig"

cat << 'EOF' > "$HOME/.config/fontconfig/fonts.conf"
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
    <!-- Sans-Serif & System UI Fallback -->
    <match target="pattern">
        <test qual="any" name="family"><string>sans-serif</string></test>
        <edit name="family" mode="prepend" binding="strong">
            <string>Noto Sans Bengali UI</string>
            <string>Noto Sans Bengali</string>
        </edit>
    </match>

    <!-- Serif Fallback -->
    <match target="pattern">
        <test qual="any" name="family"><string>serif</string></test>
        <edit name="family" mode="prepend" binding="strong">
            <string>Noto Serif Bengali</string>
        </edit>
    </match>
</fontconfig>
EOF

# 3. Rebuild Font Cache
log "Updating font cache..."
fc-cache -fv

echo ""
success "Bangla font setup complete! Restart your browser to apply changes."
