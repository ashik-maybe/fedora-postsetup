#!/usr/bin/env bash

# remove_kde_bloat.sh — Lean KDE Plasma for Fedora 44+
# Usage: ./remove_kde_bloat.sh

set -euo pipefail

# ── Colors
GREEN='\033[0;32m' BLUE='\033[0;34m' YELLOW='\033[0;33m' RED='\033[0;31m' CYAN='\033[0;36m' NC='\033[0m'
log()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success(){ echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── Guard
[[ "${XDG_CURRENT_DESKTOP:-}" == *"KDE"* ]] || error "KDE Plasma required. Current: ${XDG_CURRENT_DESKTOP:-Unknown}"
sudo -v &>/dev/null || error "Sudo privileges required."

clear
echo -e "${CYAN}=================================================${NC}"
echo -e "${CYAN}        KDE Plasma Bloat Removal Tool${NC}"
echo -e "${CYAN}=================================================${NC}"
echo ""

# ── Packages to remove
PKGS=(
    akregator
    dragon
    elisa-player
    filelight
    firefox
    gnome-abrt
    kaddressbook
    kamoso
    kcalc
    kcharselect
    kde-connect
    kdeconnectd
    kdf
    keditbookmarks
    kfind
    khelpcenter
    kleopatra
    kmahjongg
    kmag
    kmail
    kmines
    kmousetool
    kmouth
    kolourpaint
    konversation
    kontact
    korganizer
    kpat
    kpatience
    krdc
    krfb
    ktnef
    kteatime
    ktimer
    kwalletmanager
    kwalletmanager5
    kwalletmanager6
    kwrite
    libreoffice-calc
    libreoffice-draw
    libreoffice-impress
    libreoffice-math
    libreoffice-writer
    mediawriter
    neochat
    PackageKit
    PackageKit-qt6
    pim
    plasma-discover
    plasma-welcome
    qrca
    skanpage
    sweeper
)

# ── Show list
log "Packages to remove:"
echo ""
for pkg in "${PKGS[@]}"; do
    echo "  • $pkg"
done
echo ""

read -p "Proceed? (y/N): " -n 1 -r
echo ""
[[ $REPLY =~ ^[Yy]$ ]] || { warn "Cancelled."; exit 0; }
echo ""

# ── Install Foot terminal first (so we have a terminal after Konsole is gone)
log "Installing Foot terminal..."
sudo dnf install -y foot
success "Foot terminal installed"
echo ""

# ── Remove packages
log "Removing packages..."
sudo dnf remove -y "${PKGS[@]}"
success "Packages removed"
echo ""

# ── Baloo
log "Disabling Baloo..."
if command -v balooctl6 &>/dev/null; then
    balooctl6 suspend 2>/dev/null || true
    balooctl6 disable 2>/dev/null || true
    success "Baloo disabled"
elif command -v balooctl &>/dev/null; then
    balooctl suspend 2>/dev/null || true
    balooctl disable 2>/dev/null || true
    success "Baloo disabled"
else
    warn "Baloo not found"
fi

# ── Akonadi
echo ""
log "Stopping Akonadi..."
if command -v akonadictl &>/dev/null; then
    akonadictl stop 2>/dev/null || true
    success "Akonadi stopped"
else
    warn "akonadictl not found"
fi

# ── User services
echo ""
log "Disabling leftover user services..."
systemctl --user disable --now akonadi-server 2>/dev/null || true
systemctl --user disable --now akonadi-control 2>/dev/null || true
systemctl --user disable --now akonadi-indexing-agent 2>/dev/null || true
systemctl --user disable --now baloo_file 2>/dev/null || true
systemctl --user disable --now baloo-file 2>/dev/null || true
success "User services handled"

# ── PackageKit
echo ""
log "Disabling PackageKit..."
if systemctl is-active packagekit.service &>/dev/null 2>&1; then
    sudo systemctl disable --now packagekit.service
    success "PackageKit disabled"
else
    warn "PackageKit not running"
fi

# ── Cleanup
echo ""
log "Cleaning up..."
sudo dnf autoremove -y
rm -rf ~/.cache/plasma-discover* ~/.cache/packagekit ~/.local/share/akonadi ~/.config/akonadi ~/.local/share/baloo 2>/dev/null || true
sudo rm -rf /var/cache/PackageKit 2>/dev/null || true
success "Cleanup complete"

# ── Done
echo ""
echo -e "${CYAN}=================================================${NC}"
echo -e "${GREEN}  ✓ KDE Plasma debloat complete${NC}"
echo -e "${CYAN}=================================================${NC}"
echo ""
echo -e "${BLUE}Installed:${NC} Foot terminal"
echo -e "${BLUE}Kept:${NC} Dolphin, Kate, Gwenview, Okular, Ark, Spectacle, KRunner"
echo -e "${YELLOW}→ Log out or restart to finish${NC}"
echo ""
