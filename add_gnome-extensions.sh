#!/usr/bin/env bash

# setup-gnome-extensions.sh — Install and configure essential GNOME Shell extensions
# Fedora 44+ | GNOME 50+ | Wayland only
#
# Usage:
#   chmod +x setup-gnome-extensions.sh
#   ./setup-gnome-extensions.sh

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
# Pre-flight checks
# ──────────────────────────────────────────────────────────────
clear
echo -e "${CYAN}=================================================${NC}"
echo -e "${CYAN}     GNOME Shell Extension Installer${NC}"
echo -e "${CYAN}=================================================${NC}"
echo ""

# Verify GNOME desktop
if [[ "${XDG_CURRENT_DESKTOP:-}" != *"GNOME"* ]]; then
    error "This script requires the GNOME desktop environment."
    echo "   Current desktop: ${XDG_CURRENT_DESKTOP:-Unknown}"
    exit 1
fi
success "GNOME desktop detected"

# Verify Wayland (GNOME 50 dropped X11)
if [[ "${XDG_SESSION_TYPE:-}" != "wayland" ]]; then
    warn "Wayland session not detected. GNOME 50+ targets Wayland."
    echo "   Session type: ${XDG_SESSION_TYPE:-Unknown}"
fi

# Verify sudo access
if ! sudo -v &>/dev/null; then
    error "Sudo privileges required to install packages."
    exit 1
fi

echo ""

# ──────────────────────────────────────────────────────────────
# Extension definitions
# ──────────────────────────────────────────────────────────────
EXTENSIONS=(
    # Package name                              # Description
    "gnome-shell-extension-appindicator"        # Tray icons (AppIndicator/KStatusNotifier)
    "gnome-shell-extension-dash-to-dock"        # Customizable dock
    "gnome-shell-extension-caffeine"            # Disable screen blanking/suspend
)

EXTENSION_UUIDS=(
    "appindicatorsupport@rgcjonas.gmail.com"
    "dash-to-dock@micxgx.gmail.com"
    "caffeine@patapon.info"
)

# ──────────────────────────────────────────────────────────────
# Install extensions
# ──────────────────────────────────────────────────────────────
log "Installing GNOME Shell extensions..."

for pkg in "${EXTENSIONS[@]}"; do
    printf "  • %s ... " "$pkg"
    if sudo dnf install -y "$pkg" &>/dev/null; then
        echo -e "${GREEN}done${NC}"
    else
        echo -e "${RED}failed${NC}"
        error "Could not install $pkg"
        exit 1
    fi
done

echo ""
success "All extensions installed"
echo ""

# ──────────────────────────────────────────────────────────────
# Post-install guidance
# ──────────────────────────────────────────────────────────────
echo -e "${CYAN}=================================================${NC}"
echo -e "${CYAN}     Extension Management Reference${NC}"
echo -e "${CYAN}=================================================${NC}"
echo ""

echo -e "${BLUE}─── Enable Extensions ───${NC}"
echo ""
echo "  Enable all three:"
for uuid in "${EXTENSION_UUIDS[@]}"; do
    echo "    gnome-extensions enable $uuid"
done
echo ""
echo "  Or enable via the Extensions app (GUI)."
echo ""

echo -e "${BLUE}─── List Extensions ───${NC}"
echo ""
echo "  All installed:   gnome-extensions list"
echo "  Enabled only:    gnome-extensions list --enabled"
echo "  Verbose:         gnome-extensions list --verbose"
echo "  Info on one:     gnome-extensions info <uuid>"
echo ""

echo -e "${BLUE}─── Disable / Toggle ───${NC}"
echo ""
echo "  Single ext:      gnome-extensions disable <uuid>"
echo "  All extensions:  gsettings set org.gnome.shell disable-user-extensions true"
echo "  Re-enable all:   gsettings set org.gnome.shell disable-user-extensions false"
echo ""

echo -e "${BLUE}─── Troubleshooting ───${NC}"
echo ""
echo "  Check status:    gnome-extensions info <uuid>"
echo "  Restart Shell:   Press Alt+F2, type 'r', press Enter (X11 only)"
echo "                   On Wayland: log out and back in"
echo "  Verify loaded:   gnome-extensions list --enabled"
echo ""

echo -e "${YELLOW}─────────────────────────────────────────────${NC}"
echo -e "${YELLOW}  Log out and back in for extensions to appear${NC}"
echo -e "${YELLOW}─────────────────────────────────────────────${NC}"
echo ""
