#!/usr/bin/env bash

# install-vscodium.sh — Install VSCodium from the upstream repo (Fedora 44+)
#
# Usage:
#   ./install-vscodium.sh [--dry-run] [--yes] [--help]
#
# Exit codes: 0 ok, 1 error, 2 aborted.
# Safe to re-run. Validates repo metadata before install.

set -euo pipefail
IFS=$'\n\t'

# 0. Config
readonly REPO_FILE="/etc/yum.repos.d/vscodium.repo"
readonly REPO_ID="gitlab.com_paulcarroty_vscodium_repo"
readonly REPO_BASE="https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/rpms/"
readonly REPO_KEY="https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg"
readonly PKG="codium"

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
    read -rp "Install codium now? (y/n): " reply || true
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
        ok "codium is already installed."
        exit 0
    fi
    confirm
}

step_repo() {
    if [[ -f "$REPO_FILE" ]]; then
        log "Repo already exists at $REPO_FILE"
        return 0
    fi
    log "Creating VSCodium repo at $REPO_FILE..."
    if $DRY_RUN; then
        run sudo install -m 644 /dev/null "$REPO_FILE"
        return 0
    fi
    sudo install -m 644 /dev/null "$REPO_FILE"
    sudo tee "$REPO_FILE" >/dev/null <<EOF
[$REPO_ID]
name=$REPO_ID
baseurl=$REPO_BASE
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=$REPO_KEY
metadata_expire=1h
EOF
    ok "Repo created"
}

step_health() {
    log "Validating repo metadata..."
    if $DRY_RUN; then
        run sudo dnf -y makecache --repo "$REPO_ID"
        return 0
    fi
    if ! sudo dnf -y makecache --repo "$REPO_ID" >/dev/null 2>&1; then
        die "VSCodium repo failed validation. Upstream key may be rotated. Fallback: flatpak install flathub com.vscodium.codium"
    fi
    ok "Repo metadata is valid"
}

step_install() {
    log "Installing codium..."
    run sudo dnf install -y "$PKG"
    ok "Installation complete."
}

# 4. Main
main() {
    parse_args "$@"
    step_check
    step_repo
    step_health
    step_install
}

main "$@"
