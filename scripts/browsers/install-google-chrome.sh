#!/usr/bin/env bash

# install-google-chrome.sh — Install Google Chrome from Google's RPM (Fedora 44+)
#
# Usage:
#   ./install-google-chrome.sh [--dry-run] [--yes] [--help]
#
# Exit codes: 0 ok · 1 error · 2 aborted
# Idempotent: exits early if Chrome is already installed.
# Note: downloads the upstream RPM to a private temp dir (never bare /tmp).

set -euo pipefail
IFS=$'\n\t'

# 0. Config
readonly REPO_PATH="/etc/yum.repos.d/google-chrome.repo"
readonly RPM_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"

DRY_RUN=false
ASSUME_YES=false
TMPDIR_WORK=""

# 1. Helpers
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'
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

cleanup() {
    if [[ -n "${TMPDIR_WORK:-}" && -d "$TMPDIR_WORK" ]]; then
        rm -rf "$TMPDIR_WORK"
    fi
}
trap cleanup EXIT

usage() {
    sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
    echo ""
    echo "Options:"
    echo "  --dry-run   Print steps without downloading/installing"
    echo "  --yes, -y   Install without confirmation"
    echo "  --help, -h  Show this help"
    exit 0
}

confirm() {
    if $ASSUME_YES || $DRY_RUN; then return 0; fi
    local reply
    read -rp "Download and install Google Chrome? (y/n): " reply || true
    # shellcheck disable=SC2119 # intentional: case-insensitive compare below
    [[ "${reply,,}" == "y" ]] || { warn "Installation aborted."; exit 2; }
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

# 3. Steps
step_check() {
    if command -v google-chrome &>/dev/null; then
        ok "google-chrome is already installed."
        exit 0
    fi
    confirm
}

step_download() {
    TMPDIR_WORK="$(mktemp -d)"
    local rpm="$TMPDIR_WORK/google-chrome.rpm"
    log "Downloading Chrome RPM to a private temp dir..."
    run curl -fsSL "$RPM_URL" -o "$rpm"
    RPM_FILE="$rpm"
}

step_install() {
    log "Installing google-chrome-stable..."
    run sudo dnf install -y "$RPM_FILE"
    ok "Installation complete."
}

# 4. Main
main() {
    parse_args "$@"
    step_check
    step_download
    step_install
}

main "$@"
