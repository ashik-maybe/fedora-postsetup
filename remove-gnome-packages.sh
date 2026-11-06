#!/usr/bin/env bash

# remove-gnome-packages.sh — Remove unnecessary GNOME packages (Fedora 44+)
#
# Usage:
#   ./remove-gnome-packages.sh [--dry-run] [--yes] [--help]
#
# Exit codes: 0 ok · 1 error · 2 aborted
# Idempotent: missing packages are skipped. Destructive — use --dry-run first.

set -euo pipefail
IFS=$'\n\t'

# 0. Config
readonly PACKAGES=(
    baobab decibels evince firefox gnome-boxes gnome-calculator
    gnome-calendar gnome-characters gnome-clocks gnome-connections
    gnome-contacts gnome-disk-utility gnome-font-viewer gnome-logs
    gnome-maps gnome-music gnome-software gnome-tour gnome-weather
    mediawriter rhythmbox showtime simple-scan snapshot yelp
    PackageKit PackageKit-glib
)

DRY_RUN=false
ASSUME_YES=false

# 1. Helpers
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
log()     { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()      { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
die()     { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }

run() {
    local IFS=' '
    log "→ $*"
    if $DRY_RUN; then return 0; fi
    "$@"
}

usage() {
    sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
    echo ""
    echo "Options:"
    echo "  --dry-run   List packages without removing anything"
    echo "  --yes, -y   Remove without confirmation"
    echo "  --help, -h  Show this help"
    exit 0
}

confirm() {
    if $ASSUME_YES; then return 0; fi
    if $DRY_RUN; then return 0; fi
    local reply
    read -rp "Proceed? (y/N): " -n 1 reply || true
    echo ""
    [[ "$reply" =~ ^[Yy]$ ]] || { warn "Cancelled."; exit 2; }
}

# 2. Pre-flight guards
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run) DRY_RUN=true ;;
            --yes|-y)  ASSUME_YES=true ;;
            --help|-h) usage ;;
            *) die "Unknown argument: $1 (try --help)" ;;
        esac
        shift
    done
}

require_sudo() {
    if $DRY_RUN; then warn "Dry-run: skip sudo check"; return 0; fi
    sudo -v || die "Run with sudo."
}

# 3. Steps
step_list() {
    log "Packages to remove (${#PACKAGES[@]}):"
    local pkg
    for pkg in "${PACKAGES[@]}"; do echo "  - $pkg"; done
    echo ""
}

step_remove() {
    log "Removing packages (per-package, missing ones skipped)..."
    local pkg
    for pkg in "${PACKAGES[@]}"; do
        if $DRY_RUN; then
            run sudo dnf remove -y "$pkg"
            continue
        fi
        if rpm -q "$pkg" &>/dev/null; then
            run sudo dnf remove -y "$pkg"
        else
            log "  – $pkg not installed, skipping"
        fi
    done
    ok "Packages removed"
}

step_cleanup() {
    log "Removing orphaned packages..."
    run sudo dnf autoremove -y
    ok "Cleanup complete"
}

# 4. Main
main() {
    parse_args "$@"
    require_sudo
    step_list
    confirm
    step_remove
    step_cleanup
    echo ""
    ok "Packages removed."
    log "Kept: GNOME Shell, Nautilus, Terminal, Settings."
}

main "$@"
