#!/usr/bin/env bash

# remove_gnome_bloat.sh — GNOME Bloat Removal for Fedora 44+
# Minimal, targeted — keeps what matters, removes what doesn't
#
# Usage:
#   chmod +x remove_gnome_bloat.sh
#   ./remove_gnome_bloat.sh

set -euo pipefail

# ──────────────────────────────────────────────────────────────
# Colors
# ──────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success(){ echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()  { echo -e "${RED}[ERROR]${NC} $1"; }

# ──────────────────────────────────────────────────────────────
# Header
# ──────────────────────────────────────────────────────────────
clear
echo -e "${CYAN}=================================================${NC}"
echo -e "${CYAN}        GNOME Bloat Removal Tool${NC}"
echo -e "${CYAN}=================================================${NC}"
echo ""

# ──────────────────────────────────────────────────────────────
# Applications to remove
# ──────────────────────────────────────────────────────────────
APP_PACKAGES=(
    baobab                     # Disk Usage Analyzer
    decibels                   # Audio Previewer
    evince                     # Document Viewer
    firefox                    # Firefox RPM (use Flatpak instead)
    gnome-boxes                # Virtual Machines
    gnome-calculator           # Calculator
    gnome-calendar             # Calendar
    gnome-characters           # Character Map
    gnome-clocks               # Clocks
    gnome-connections          # Remote Desktop
    gnome-contacts             # Contacts
    gnome-disk-utility         # Disk Manager
    gnome-font-viewer          # Font Viewer
    gnome-logs                 # Log Viewer
    gnome-maps                 # Maps
    gnome-music                # Music Player
    gnome-software             # Software Center
    gnome-tour                 # Welcome Tour
    gnome-weather              # Weather
    mediawriter                # Fedora Media Writer
    rhythmbox                  # Music Player (legacy)
    showtime                   # Video Player
    simple-scan                # Document Scanner
    snapshot                   # Camera
    yelp                       # Help Browser

    # Background services
    PackageKit                 # PackageKit daemon
    PackageKit-glib            # PackageKit GLib library
)

# ──────────────────────────────────────────────────────────────
# Display packages to be removed
# ──────────────────────────────────────────────────────────────
log "The following packages will be removed:"
echo ""
printf '  • %s\n' "${APP_PACKAGES[@]}"
echo ""

log "Additional cleanup tasks:"
echo "  • Disable Tracker 3 (file content indexer)"
echo "  • Remove GNOME Software cache"
echo "  • Remove PackageKit cache"
echo ""

# ──────────────────────────────────────────────────────────────
# Confirmation
# ──────────────────────────────────────────────────────────────
read -p "Proceed with removal? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    warn "Operation cancelled."
    exit 0
fi

echo ""

# ──────────────────────────────────────────────────────────────
# 1. Remove packages
# ──────────────────────────────────────────────────────────────
log "Removing selected packages..."
if sudo dnf remove -y "${APP_PACKAGES[@]}" 2>/dev/null; then
    success "Packages removed successfully"
else
    warn "Some packages were not installed — continuing..."
fi

# ──────────────────────────────────────────────────────────────
# 2. Disable Tracker 3
# ──────────────────────────────────────────────────────────────
echo ""
log "Disabling Tracker 3 (file content indexer)..."

# Tracker indexes file contents — not needed for Super key app search or Nautilus
if command -v tracker3 &>/dev/null; then
    tracker3 daemon -t 2>/dev/null || true
    success "Tracker daemon terminated"
fi

systemctl --user mask tracker-miner-fs-3.service 2>/dev/null || true
systemctl --user mask tracker-extract-3.service 2>/dev/null || true
systemctl --user mask tracker-writeback-3.service 2>/dev/null || true
success "Tracker services masked"

# ──────────────────────────────────────────────────────────────
# 3. Cleanup
# ──────────────────────────────────────────────────────────────
echo ""
log "Cleaning up..."

# Remove orphaned dependencies
sudo dnf autoremove -y &>/dev/null
success "Orphaned packages removed"

# Remove caches
rm -rf ~/.cache/gnome-software 2>/dev/null || true
rm -rf ~/.cache/tracker3 2>/dev/null || true
rm -rf ~/.local/share/tracker3 2>/dev/null || true
sudo rm -rf /var/cache/PackageKit 2>/dev/null || true
success "Caches cleaned"

# ──────────────────────────────────────────────────────────────
# Done
# ──────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}=================================================${NC}"
echo -e "${GREEN}  ✓ GNOME debloat complete${NC}"
echo -e "${CYAN}=================================================${NC}"
echo ""
echo -e "${BLUE}Changes applied:${NC}"
echo "  • Removed unused GNOME applications"
echo "  • Removed GNOME Software + PackageKit"
echo "  • Disabled Tracker 3 (content indexer)"
echo "  • Cleaned package manager caches"
echo ""
echo -e "${BLUE}Still intact:${NC}"
echo "  • GNOME Shell & Super key app search"
echo "  • Nautilus file search"
echo "  • All essential system functionality"
echo ""
echo -e "${YELLOW}→ Log out or restart to complete the cleanup${NC}"
echo ""
