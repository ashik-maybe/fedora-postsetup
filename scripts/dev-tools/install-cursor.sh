#!/usr/bin/env bash

# install-cursor.sh — Install Cursor IDE from the official repo (Fedora 44+)
#
# Usage:
#   ./install-cursor.sh [--dry-run] [--yes] [--help]
#
# Exit codes: 0 ok, 1 error, 2 aborted.
# Safe to re-run. Uses the official Anysphere repo.

set -euo pipefail
IFS=$'\n\t'

# 0. Config
readonly REPO_FILE="/etc/yum.repos.d/cursor.repo"
readonly REPO_BASE="https://downloads.cursor.com/yumrepo"
readonly REPO_KEY="https://downloads.cursor.com/keys/anysphere.asc"
readonly PKG="cursor"

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
    read -rp "Install cursor now? (y/n): " reply || true
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
    if rpm -q "$PKG" &>/dev/null; then
        ok "cursor is already installed."
        exit 0
    fi
    confirm
}

step_repo() {
    if [[ -f "$REPO_FILE" ]]; then
        log "Repo already exists at $REPO_FILE"
        return 0
    fi
    log "Creating Cursor repo at $REPO_FILE..."
    if $DRY_RUN; then
        run sudo install -m 644 /dev/null "$REPO_FILE"
        return 0
    fi
    sudo install -m 644 /dev/null "$REPO_FILE"
    sudo tee "$REPO_FILE" >/dev/null <<EOF
[cursor]
name=Cursor
baseurl=$REPO_BASE
enabled=1
gpgcheck=1
gpgkey=$REPO_KEY
repo_gpgcheck=1
EOF
    ok "Repo created"
}

step_install() {
    log "Installing cursor..."
    run sudo dnf install -y "$PKG"
    ok "Installation complete."
}

step_verify() {
    log "Verifying installation..."
    if $DRY_RUN; then
        run rpm -q cursor
        return 0
    fi
    rpm -q cursor
    command -v cursor || warn "cursor not in PATH."
    cursor --version 2>/dev/null | head -3 || true
}

# 4. Main
main() {
    parse_args "$@"
    step_check
    step_repo
    step_install
    step_verify
}

main "$@"
