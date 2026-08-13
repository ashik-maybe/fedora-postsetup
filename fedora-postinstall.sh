#!/usr/bin/env bash

# fedora-postinstall.sh — General Fedora Post-Installation Setup (Fedora 44+)
# Enables RPM Fusion, Flathub, multimedia codecs, and optimizes DNF
#
# Usage:
#   sudo ./fedora-postinstall.sh

# Exit on error, unset variable, or failed pipe
set -euo pipefail

# Visual colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Ensure script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Please run this script with sudo:${NC}"
    echo "  sudo $0"
    exit 1
fi

# Check if running on Fedora
if [ ! -f /etc/fedora-release ]; then
    warn "This script is designed for Fedora. Proceed with caution."
fi

log "Starting General Fedora Post-Installation Setup..."

# ----------------------------------------------------------------------
# 1. Optimize DNF Configuration
# ----------------------------------------------------------------------
log "Configuring DNF for faster downloads..."
DNF_CONF="/etc/dnf/dnf.conf"

# max_parallel_downloads works in both DNF4 and DNF5
if ! grep -q "max_parallel_downloads" "$DNF_CONF"; then
    echo "max_parallel_downloads=10" >> "$DNF_CONF"
    log "Added max_parallel_downloads=10"
else
    log "max_parallel_downloads already configured"
fi

# fastestmirror is required to be appended
if ! grep -q "fastestmirror" "$DNF_CONF"; then
    echo "fastestmirror=True" >> "$DNF_CONF"
    log "Added fastestmirror=True"
else
    log "fastestmirror already configured"
fi

# max_downloads_per_mirror limits simultaneous connections per mirror
if ! grep -q "max_downloads_per_mirror" "$DNF_CONF"; then
    echo "max_downloads_per_mirror=5" >> "$DNF_CONF"
    log "Added max_downloads_per_mirror=5"
else
    log "max_downloads_per_mirror already configured"
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
log "Setting up Flatpak and Flathub..."
if command -v flatpak &> /dev/null; then
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    log "Flathub repository enabled"
else
    warn "Flatpak not installed - skipping Flathub setup"
fi

log "Enabling Cisco OpenH264 repository for Firefox and WebRTC..."
# Ensure dnf config-manager plugin is available
if ! dnf config-manager --help &>/dev/null; then
    dnf install -y dnf-plugins-core
fi
dnf config-manager setopt fedora-cisco-openh264.enabled=1
dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264

# ----------------------------------------------------------------------
# 5. Swap FFmpeg & Install Multimedia Codecs
# ----------------------------------------------------------------------
log "Swapping to full FFmpeg build from RPM Fusion..."
dnf swap -y ffmpeg-free ffmpeg --allowerasing

log "Installing GStreamer multimedia plugins..."
dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin

# ----------------------------------------------------------------------
# 6. Cleanup
# ----------------------------------------------------------------------
log "Cleaning up unused packages and temporary cache..."
dnf autoremove -y
dnf clean all

# ----------------------------------------------------------------------
# Done
# ----------------------------------------------------------------------
echo ""
success "General Fedora post-installation setup complete!"
echo ""
log "What was configured:"
echo "  ✓ DNF optimized for parallel downloads (max_parallel_downloads=10)"
echo "  ✓ DNF configured with fastestmirror=True"
echo "  ✓ DNF limited to 5 downloads per mirror (max_downloads_per_mirror=5)"
echo "  ✓ RPM Fusion repositories (Free & Non-Free)"
echo "  ✓ Flathub Flatpak repository"
echo "  ✓ Cisco OpenH264 codecs"
echo "  ✓ Full FFmpeg with multimedia codecs"
echo "  ✓ System cleaned and updated"
echo ""
warn "Please restart your machine to apply all changes."
