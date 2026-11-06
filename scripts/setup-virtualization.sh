#!/usr/bin/env bash

# setup-virtualization.sh — Install or remove Virt-Manager, QEMU, KVM (Fedora 44+).
#
# Usage:
#   ./setup-virtualization.sh [--remove] [--dry-run] [--yes] [--help]
#   ./setup-virtualization.sh -r [--dry-run] [--yes]
#
# Exit codes: 0 ok · 1 error · 2 aborted
# Idempotent: safe to re-run.

set -euo pipefail
IFS=$'\n\t'

# 0. Config
readonly GROUP_NAME="@virtualization"
readonly LIBVIRT_SOCKETS=(libvirtd.socket libvirtd-admin.socket libvirtd-ro.socket libvirtd.service)

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
    echo "  --remove, -r  Remove virtualization instead of installing"
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
            --remove|-r) REMOVE_MODE=true ;;
            --dry-run)   DRY_RUN=true ;;
            --yes|-y)    ASSUME_YES=true ;;
            --help|-h)   usage ;;
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
step_install() {
    log "Installing Virt-Manager, QEMU, and KVM..."
    run sudo dnf install -y "$GROUP_NAME"
    ok "Virtualization packages installed"
}

step_enable() {
    log "Enabling and starting libvirtd..."
    run sudo systemctl enable --now libvirtd
    ok "libvirtd active and enabled at boot"
}

step_user_group() {
    log "Checking '$USER' in libvirt group..."
    if id -nG "$USER" 2>/dev/null | grep -qw libvirt; then
        ok "User already in libvirt group"
    else
        run sudo usermod -aG libvirt "$USER"
        warn "Log out and back in."
    fi
}

step_remove() {
    log "Stopping and disabling libvirtd..."
    local svc
    for svc in "${LIBVIRT_SOCKETS[@]}"; do
        run sudo systemctl stop "$svc"
        run sudo systemctl disable "$svc"
    done
    if id -nG "$USER" 2>/dev/null | grep -qw libvirt; then
        run sudo gpasswd -d "$USER" libvirt
    fi
    log "Removing virtualization packages..."
    run sudo dnf remove -y "$GROUP_NAME"
    warn "VM images in /var/lib/libvirt/ and ~/.config/libvirt/ were kept."
}

# 4. Main
main() {
    parse_args "$@"
    require_sudo
    if $REMOVE_MODE; then
        confirm
        step_remove
        ok "Removal complete."
    else
        step_install
        step_enable
        step_user_group
        ok "Setup complete."
        warn "Log out and back in."
    fi
}

main "$@"
