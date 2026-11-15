#!/usr/bin/env bash

# install-ghostty.sh — Install Ghostty from the scottames COPR (Fedora 44+).
#
# Usage:
#   ./install-ghostty.sh [--dry-run] [--yes] [--help]
#
# Exit codes: 0 ok · 1 error · 2 aborted
# Idempotent. Needs network for the COPR repository.

set -euo pipefail
IFS=$'\n\t'

# 0. Config
readonly COPR="scottames/ghostty"
readonly COPR_ID="copr.fedorainfracloud.org/scottames/ghostty"
readonly PKG="ghostty"

DRY_RUN=false
ASSUME_YES=false

# 1. Helpers
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
ok() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
die() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

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
    echo "  --yes, -y   Install without confirmation"
    echo "  --help, -h  Show this help"
    exit 0
}

confirm() {
    if $ASSUME_YES || $DRY_RUN; then return 0; fi
    local reply
    read -rp "Install $PKG from COPR $COPR now? (y/n): " reply || true
    [[ "${reply,,}" == "y" ]] || {
        warn "Installation aborted."
        exit 2
    }
}

# 2. Pre-flight guards
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --dry-run) DRY_RUN=true ;;
        --yes | -y) ASSUME_YES=true ;;
        --help | -h) usage ;;
        *) die "Unknown argument: $1 (try --help)" ;;
        esac
        shift
    done
}

# 3. Steps
step_check() {
    if rpm -q "$PKG" &>/dev/null; then
        ok "$PKG is already installed."
        exit 0
    fi
    confirm
}

step_deps() {
    if command -v dnf >/dev/null 2>&1 && dnf copr --help >/dev/null 2>&1; then
        return 0
    fi
    log "Installing dnf-plugins-core for COPR support..."
    run sudo dnf install -y dnf-plugins-core
}

step_repo() {
    if dnf copr list 2>/dev/null | grep -qx "$COPR_ID"; then
        log "COPR $COPR is already enabled"
        return 0
    fi
    log "Enabling COPR $COPR..."
    run sudo dnf copr enable -y "$COPR"
    ok "COPR enabled"
}

step_install() {
    log "Installing $PKG..."
    run sudo dnf install -y "$PKG"
    $DRY_RUN && {
        log "Dry-run: install skipped"
        return 0
    }
    ok "Installation complete."
}

step_verify() {
    log "Verifying installation..."
    if $DRY_RUN; then
        run rpm -q "$PKG"
        return 0
    fi
    rpm -q "$PKG"
    command -v "$PKG" >/dev/null 2>&1 || warn "$PKG not in PATH."
    "$PKG" --version 2>/dev/null | head -2 || true
}

# 4. Main
main() {
    parse_args "$@"
    step_check
    step_deps
    step_repo
    step_install
    step_verify
}

main "$@"
