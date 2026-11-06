#!/usr/bin/env bash

# setup-appimage-manager.sh — Install AppImage support with Gear Lever and FUSE (Fedora 44+).
# Gear Lever (Flatpak) manages AppImages; fuse2 + fuse3 give them a filesystem.
#
# Usage:
#   ./setup-appimage-manager.sh [--dry-run] [--yes] [--help]
#
# Exit codes: 0 ok · 1 error · 2 aborted
# Idempotent: safe to re-run. User-level script (uses sudo only for dnf).

set -euo pipefail
IFS=$'\n\t'

# 0. Config
readonly GEAR_LEVER_ID="it.mijorus.gearlever"
readonly FLATHUB_REPO="https://dl.flathub.org/repo/flathub.flatpakrepo"
readonly FUSE_PKGS=(fuse fuse-libs libfuse3)

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

require_sudo() {
    if $DRY_RUN; then warn "Dry-run: skip sudo check"; return 0; fi
    sudo -v || die "Run with sudo for dnf installs."
}

# 3. Steps
step_flatpak() {
    log "Checking Flatpak..."
    if command -v flatpak &>/dev/null; then
        ok "Flatpak already installed"
    else
        run sudo dnf install -y flatpak
    fi
}

step_flathub() {
    log "Checking Flathub..."
    if $DRY_RUN; then
        run flatpak remote-add --if-not-exists flathub "$FLATHUB_REPO"
        return 0
    fi
    if flatpak remotes 2>/dev/null | grep -q flathub; then
        ok "Flathub already configured"
    else
        run flatpak remote-add --if-not-exists flathub "$FLATHUB_REPO"
    fi
}

step_fuse() {
    log "Installing FUSE (fuse2 + fuse3) for AppImages..."
    run sudo dnf install -y "${FUSE_PKGS[@]}"
    ok "FUSE installed"
}

step_gear_lever() {
    log "Checking Gear Lever..."
    if $DRY_RUN; then
        run flatpak install -y flathub "$GEAR_LEVER_ID"
        return 0
    fi
    if flatpak list --app 2>/dev/null | grep -q "$GEAR_LEVER_ID"; then
        ok "Gear Lever already installed"
    else
        run flatpak install -y flathub "$GEAR_LEVER_ID"
    fi
}

# 4. Main
main() {
    parse_args "$@"
    require_sudo
    step_flatpak
    step_flathub
    step_fuse
    step_gear_lever
    echo ""
    ok "Setup complete."
    echo "Run Gear Lever to add AppImages."
}

main "$@"
