#!/usr/bin/env bash

# install-brave-browser.sh — Install Brave Browser from the official repo (Fedora 44+)
#
# Usage:
#   ./install-brave-browser.sh [--dry-run] [--yes] [--help]
#
# Exit codes: 0 ok · 1 error · 2 aborted
# Idempotent: exits early if Brave is already installed.

set -euo pipefail
IFS=$'\n\t'

# 0. Config
readonly REPO_PATH="/etc/yum.repos.d/brave-browser.repo"
readonly REPO_URL="https://brave-browser-rpm-release.s3.brave.com/brave-core.asc"
readonly REPO_BASE="https://brave-browser-rpm-release.s3.brave.com/\$basearch"

DRY_RUN=false
ASSUME_YES=false

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
    read -rp "Install brave-browser now? (y/n): " reply || true
    [[ "$reply" == "y" ]] || { warn "Installation aborted."; exit 2; }
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
    if command -v brave-browser &>/dev/null; then
        ok "brave-browser is already installed."
        exit 0
    fi
    confirm
}

step_repo() {
    if [[ -f "$REPO_PATH" ]]; then
        log "Repo already exists at $REPO_PATH"
        return 0
    fi
    log "Creating Brave repo at $REPO_PATH..."
    if $DRY_RUN; then
        run sudo install -m 644 /dev/null "$REPO_PATH"
        return 0
    fi
    sudo install -m 644 /dev/null "$REPO_PATH"
    sudo tee "$REPO_PATH" >/dev/null <<EOF
[brave-browser]
name=Brave Browser
enabled=1
gpgcheck=1
gpgkey=$REPO_URL
baseurl=$REPO_BASE
EOF
    ok "Repo created"
}

step_install() {
    log "Installing brave-browser..."
    run sudo dnf install -y brave-browser
    ok "Installation complete."
}

# 4. Main
main() {
    parse_args "$@"
    step_check
    step_repo
    step_install
}

main "$@"
