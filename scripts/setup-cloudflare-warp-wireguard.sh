#!/usr/bin/env bash

# setup-cloudflare-warp-wireguard.sh — Install Cloudflare WARP from the official repo (Fedora 44+).
# Installs cloudflare-warp (warp-cli + warp-svc) and registers the device.
#
# Usage:
#   ./setup-cloudflare-warp-wireguard.sh [--dry-run] [--yes] [--help]
#   ./setup-cloudflare-warp-wireguard.sh --remove [-r] [--dry-run] [--yes]
#
# Exit codes: 0 ok, 1 error, 2 aborted. Safe to re-run.

set -euo pipefail
IFS=$'\n\t'

# 0. Config
readonly WARP_REPO="/etc/yum.repos.d/cloudflare-warp.repo"
readonly WARP_REPO_URL="https://pkg.cloudflareclient.com/rpm/\$releasever"
readonly WARP_GPGKEY="https://pkg.cloudflareclient.com/pubkey.gpg"

DRY_RUN=false
ASSUME_YES=false
REMOVE_MODE=false

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
    echo "  --remove, -r  Remove WARP (repo, package, registration)"
    echo "  --dry-run     Print steps without changing the system"
    echo "  --yes, -y     Skip confirmation prompts"
    echo "  --help, -h    Show this help"
    exit 0
}

confirm() {
    if $ASSUME_YES || $DRY_RUN; then return 0; fi
    local reply
    read -rp "Proceed? (y/N): " -n 1 reply || true
    echo ""
    [[ "$reply" =~ ^[Yy]$ ]] || { warn "Cancelled."; exit 2; }
}

# 2. Pre-flight guards
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --remove|-r|--reverse) REMOVE_MODE=true ;;
            --dry-run)  DRY_RUN=true ;;
            --yes|-y)   ASSUME_YES=true ;;
            --help|-h)  usage ;;
            *) die "Unknown argument: $1 (try --help)" ;;
        esac
        shift
    done
}

require_sudo() {
    if $DRY_RUN; then warn "Dry-run: skip sudo check"; return 0; fi
    sudo -v || die "Sudo required."
}

# 3. Steps
step_repo() {
    if [[ -f "$WARP_REPO" ]]; then
        log "Official Cloudflare repo already present"
        return 0
    fi
    log "Creating official Cloudflare WARP repo..."
    if $DRY_RUN; then
        run sudo install -m 644 /dev/null "$WARP_REPO"
        return 0
    fi
    sudo install -m 644 /dev/null "$WARP_REPO"
    sudo tee "$WARP_REPO" >/dev/null <<EOF
[cloudflare-warp-stable]
name=cloudflare-warp-stable
baseurl=$WARP_REPO_URL
enabled=1
type=rpm
gpgcheck=1
gpgkey=$WARP_GPGKEY
EOF
    ok "Repo created"
}

step_install() {
    log "Installing cloudflare-warp..."
    run sudo dnf install -y cloudflare-warp
    ok "cloudflare-warp installed"
}

step_service() {
    log "Enabling and starting warp-svc..."
    run sudo systemctl enable --now warp-svc
}

step_register() {
    log "Registering this device with WARP..."
    if $DRY_RUN; then
        run warp-cli registration new
        return 0
    fi
    if warp-cli registration show 2>/dev/null | grep -q "Account"; then
        log "Already registered"
    else
        run warp-cli registration new
    fi
    run warp-cli mode warp
    run warp-cli connect
    ok "WARP connected"
}

step_remove() {
    log "Disconnecting WARP..."
    run warp-cli disconnect
    run warp-cli registration delete
    log "Stopping warp-svc..."
    run sudo systemctl disable --now warp-svc
    log "Removing cloudflare-warp package..."
    run sudo dnf remove -y cloudflare-warp
    if [[ -f "$WARP_REPO" ]]; then
        run sudo rm -f "$WARP_REPO"
    fi
    ok "WARP removed"
}

# 4. Main
main() {
    parse_args "$@"
    require_sudo
    if $REMOVE_MODE; then
        echo -e "${YELLOW}Removing Cloudflare WARP...${NC}"
        confirm
        step_remove
        echo ""
        ok "Removal complete."
        echo "Status:  warp-cli status"
        echo "Connect: warp-cli connect"
        return 0
    fi
    log "Installing Cloudflare WARP..."
    step_repo
    step_install
    step_service
    step_register
    echo ""
    ok "Setup complete."
    echo "  Status:  warp-cli status"
    echo "  Connect: warp-cli connect"
    echo "  Remove:  ./$(basename "$0") --remove"
}

main "$@"
