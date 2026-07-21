#!/usr/bin/env bash

# Exit on error, unset variable, or failed pipe
set -euo pipefail

# Visual colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Ensure script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo:"
    echo "  sudo ./fedora-postinstall.sh"
    exit 1
fi

log "Starting Fedora Post-Installation Setup for Intel Hardware..."

# ----------------------------------------------------------------------
# 1. Optimize DNF Configuration
# ----------------------------------------------------------------------
log "Configuring DNF for faster downloads..."
DNF_CONF="/etc/dnf/dnf.conf"

if ! grep -q "max_parallel_downloads" "$DNF_CONF"; then
    echo "max_parallel_downloads=10" >> "$DNF_CONF"
fi

if ! grep -q "fastestmirror" "$DNF_CONF"; then
    echo "fastestmirror=True" >> "$DNF_CONF"
fi

# ----------------------------------------------------------------------
# 2. System Refresh & Update
# ----------------------------------------------------------------------
log "Refreshing repositories and upgrading existing packages..."
dnf upgrade --refresh -y

# ----------------------------------------------------------------------
# 3. Enable RPM Fusion Repositories & AppStream Metadata
# ----------------------------------------------------------------------
log "Enabling RPM Fusion (Free & Non-Free)..."
dnf install -y \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

log "Installing RPM Fusion AppStream metadata for Software Center..."
dnf install -y rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data

# ----------------------------------------------------------------------
# 4. Enable Flathub & Cisco OpenH264
# ----------------------------------------------------------------------
log "Enabling Flathub repository..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

log "Enabling Cisco OpenH264 repo for Firefox and WebRTC..."
dnf config-manager setopt fedora-cisco-openh264.enabled=1
dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264

# ----------------------------------------------------------------------
# 5. Swap FFmpeg & Install Multimedia Codecs
# ----------------------------------------------------------------------
log "Swapping to full system-wide FFmpeg build..."
dnf swap -y ffmpeg-free ffmpeg --allowerasing

log "Installing GStreamer multimedia plugins..."
dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin

# ----------------------------------------------------------------------
# 6. Intel VA-API Hardware Video Acceleration
# ----------------------------------------------------------------------
log "Installing Intel VA-API driver (intel-media-driver) for HD 520 GPU..."
dnf install -y intel-media-driver libva libva-utils fuse-libs

# ----------------------------------------------------------------------
# 7. Cleanup
# ----------------------------------------------------------------------
log "Cleaning up unused packages and temporary cache..."
dnf autoremove -y
dnf clean all

echo ""
success "Post-installation setup complete! Please restart your machine to apply all changes."
