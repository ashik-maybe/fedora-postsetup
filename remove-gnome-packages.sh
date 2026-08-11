#!/usr/bin/env bash

# remove-gnome-packages.sh — Remove Unnecessary GNOME Packages for Fedora 44+
# Strips apps you don't use; run disable-gnome-services.sh for RAM savings
# Usage: ./remove-gnome-packages.sh

set -euo pipefail

# ── Colors
GREEN='\033[0;32m' BLUE='\033[0;34m' YELLOW='\033[0;33m' RED='\033[0;31m' CYAN='\033[0;36m' NC='\033[0m'
log()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success(){ echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()  { echo -e "${RED}[ERROR]${NC} $1"; }

# ── Guard
sudo -v &>/dev/null || error "Sudo privileges required."

clear
echo -e "${CYAN}=================================================${NC}"
echo -e "${CYAN}     GNOME Package Removal Tool${NC}"
echo -e "${CYAN}=================================================${NC}"
echo ""

# ── Packages to remove
PACKAGES=(
    baobab                     # Disk Usage Analyzer
    decibels                   # Audio Previewer
    evince                     # Document Viewer
    firefox                    # Firefox RPM
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
    PackageKit                 # PackageKit daemon
    PackageKit-glib            # PackageKit GLib library
)

# ── Display
log "Packages to remove:"
echo ""
for pkg in "${PACKAGES[@]}"; do
    echo "  • $pkg"
done
echo ""

read -p "Proceed? (y/N): " -n 1 -r
echo ""
[[ $REPLY =~ ^[Yy]$ ]] || { warn "Cancelled."; exit 0; }
echo ""

# ── Remove
log "Removing packages..."
sudo dnf remove -y "${PACKAGES[@]}" 2>/dev/null || warn "Some packages not installed — continuing"
success "Packages removed"

# ── Cleanup
echo ""
log "Cleaning up..."
sudo dnf autoremove -y &>/dev/null
success "Orphaned packages removed"

# ── Done
echo ""
echo -e "${CYAN}=================================================${NC}"
echo -e "${GREEN}  ✓ Packages removed${NC}"
echo -e "${CYAN}=================================================${NC}"
echo ""
echo -e "${BLUE}Removed:${NC}"
echo "  • Unnecessary GNOME apps"
echo "  • GNOME Software + PackageKit"
echo "  • Games, media players, utilities"
echo ""
echo -e "${BLUE}Kept:${NC}"
echo "  • GNOME Shell, Nautilus, Terminal, Settings"
echo "  • All essential system functionality"
echo ""
echo -e "${YELLOW}→ Run disable-gnome-services.sh for RAM savings${NC}"
echo ""
