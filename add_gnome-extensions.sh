#!/usr/bin/env bash

# add_gnome-extensions.sh — Install GNOME Shell extensions (Fedora 44+, GNOME 50+, Wayland)
#
# Usage:
#   ./add_gnome-extensions.sh [--dry-run] [--yes] [--help]
#
# Exit codes: 0 ok · 1 error · 2 aborted
# Idempotent: safe to re-run. Extensions are installed but NOT auto-enabled
# (enable manually — see summary). Run as your user, not root.

set -euo pipefail
IFS=$'\n\t'

# 0. Config
readonly EXTENSIONS=(
    "gnome-shell-extension-appindicator"  # Tray icons
    "gnome-shell-extension-dash-to-dock"  # Customizable dock
    "gnome-shell-extension-caffeine"      # Disable screen blanking/suspend
)
readonly EXTENSION_UUIDS=(
    "appindicatorsupport@rgcjonas.gmail.com"
    "dash-to-dock@micxgx.gmail.com"
    "caffeine@patapon.info"
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
    echo "  --dry-run   Print steps without changing the system"
    echo "  --yes, -y   Skip confirmation prompts"
    echo "  --help, -h  Show this help"
    exit 0
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

require_gnome() {
    if $DRY_RUN; then warn "Dry-run: skip GNOME desktop check"; return 0; fi
    [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]] \
        || die "GNOME desktop required (current: ${XDG_CURRENT_DESKTOP:-Unknown})"
    ok "GNOME desktop detected"
    if [[ "${XDG_SESSION_TYPE:-}" != "wayland" ]]; then
        warn "Wayland session not detected — GNOME 50+ targets Wayland."
    fi
}

require_sudo() {
    if $DRY_RUN; then warn "Dry-run: skip sudo check"; return 0; fi
    sudo -v || die "Run with sudo to install packages."
}

# 3. Steps
step_install() {
    log "Installing GNOME Shell extensions..."
    local pkg
    for pkg in "${EXTENSIONS[@]}"; do
        if $DRY_RUN; then
            run sudo dnf install -y "$pkg"
            continue
        fi
        printf "  - %s ... " "$pkg"
        if sudo dnf install -y "$pkg" &>/dev/null; then
            echo -e "${GREEN}done${NC}"
        else
            echo -e "${RED}failed${NC}"
            die "Could not install $pkg"
        fi
    done
    ok "All extensions installed"
}

step_summary() {
    log "Enable these extensions:"
    local uuid
    for uuid in "${EXTENSION_UUIDS[@]}"; do
        echo "  gnome-extensions enable $uuid"
    done
    echo ""
    log "List or disable extensions:"
    echo "  gnome-extensions list --enabled   # check what's on"
    echo "  gnome-extensions disable <uuid>   # toggle one off"
    echo "  gsettings set org.gnome.shell disable-user-extensions true  # all off"
    echo ""
    warn "Log out and back in."
}

# 4. Main
main() {
    parse_args "$@"
    require_gnome
    require_sudo
    step_install
    step_summary
}

main "$@"
