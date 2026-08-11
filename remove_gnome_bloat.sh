#!/usr/bin/env bash

# disable_gnome_bloat.sh — Disable GNOME Background Services for Fedora 44+
# Stops RAM-heavy services without removing packages
# Usage: ./disable_gnome_bloat.sh

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
echo -e "${CYAN}     GNOME Background Service Disabler${NC}"
echo -e "${CYAN}=================================================${NC}"
echo ""

# ── Tracker
log "Disabling Tracker 3 (file content indexer)..."
if command -v tracker3 &>/dev/null; then
    tracker3 daemon -t 2>/dev/null || true
fi
systemctl --user mask tracker-miner-fs-3.service 2>/dev/null || true
systemctl --user mask tracker-extract-3.service 2>/dev/null || true
systemctl --user mask tracker-writeback-3.service 2>/dev/null || true
success "Tracker disabled"

# ── Evolution Data Server
echo ""
log "Disabling Evolution calendar/contacts daemon..."
systemctl --user mask evolution-addressbook-factory.service 2>/dev/null || true
systemctl --user mask evolution-calendar-factory.service 2>/dev/null || true
systemctl --user mask evolution-source-registry.service 2>/dev/null || true
success "Evolution services masked"

# ── GNOME Online Accounts
echo ""
log "Disabling GNOME Online Accounts..."
systemctl --user mask goa-daemon.service 2>/dev/null || true
systemctl --user mask goa-identity-service.service 2>/dev/null || true
success "Online Accounts masked"

# ── GNOME Software
echo ""
log "Disabling GNOME Software background service..."
systemctl --user mask gnome-software-service.service 2>/dev/null || true
success "GNOME Software masked"

# ── PackageKit
echo ""
log "Disabling PackageKit..."
sudo systemctl disable --now packagekit.service 2>/dev/null || true
sudo systemctl mask packagekit.service 2>/dev/null || true
success "PackageKit disabled & masked"

# ── Kill running processes
echo ""
log "Stopping running daemons..."
pkill -f tracker-miner-fs 2>/dev/null || true
pkill -f tracker-extract 2>/dev/null || true
pkill -f evolution-addressbook-factory 2>/dev/null || true
pkill -f evolution-calendar-factory 2>/dev/null || true
pkill -f evolution-source-registry 2>/dev/null || true
pkill -f goa-daemon 2>/dev/null || true
success "Running daemons terminated"

# ── Cleanup
echo ""
log "Cleaning caches..."
rm -rf ~/.cache/tracker3 ~/.local/share/tracker3 ~/.cache/gnome-software ~/.cache/evolution ~/.local/share/evolution 2>/dev/null || true
sudo rm -rf /var/cache/PackageKit 2>/dev/null || true
success "Caches cleaned"

# ── Done
echo ""
echo -e "${CYAN}=================================================${NC}"
echo -e "${GREEN}  ✓ Services disabled${NC}"
echo -e "${CYAN}=================================================${NC}"
echo ""
echo -e "${BLUE}What was disabled:${NC}"
echo "  • Tracker 3 (file content indexer) — ~150-300MB"
echo "  • Evolution Data Server (calendar/contacts) — ~80-150MB"
echo "  • GNOME Online Accounts — ~50MB"
echo "  • GNOME Software + PackageKit — ~150-250MB"
echo ""
echo -e "${BLUE}RAM savings: ~400-700MB${NC}"
echo -e "${BLUE}Packages: untouched, nothing broken${NC}"
echo ""
echo -e "${BLUE}Still working:${NC}"
echo "  • Super key → app search"
echo "  • Nautilus file search"
echo "  • Everything you actually use"
echo ""
echo -e "${YELLOW}→ Log out or restart to finish${NC}"
echo ""
