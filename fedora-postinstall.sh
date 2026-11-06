#!/usr/bin/env bash

# fedora-postinstall.sh — Install baseline Fedora software (Fedora 44+).
# Enables RPM Fusion, Flathub, multimedia codecs, and optimizes DNF.
#
# Usage:
#   sudo ./fedora-postinstall.sh [--dry-run] [--yes] [--help]
#
# Exit codes: 0 ok · 1 error · 2 aborted
# Idempotent: safe to re-run. Must run as root (except --dry-run).

set -euo pipefail
IFS=$'\n\t'

# 0. Config
readonly DNF_CONF="/etc/dnf/dnf.conf"
readonly DNF_KEYS=(
    "max_parallel_downloads=10"
    "fastestmirror=True"
    "max_downloads_per_mirror=5"
)
readonly RPMFUSION_URLS=(
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-%s.noarch.rpm"
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-%s.noarch.rpm"
)

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

require_root() {
    if $DRY_RUN; then warn "Dry-run: skip root check"; return 0; fi
    [[ $EUID -eq 0 ]] || die "Please run with sudo: sudo $0"
}

require_fedora() {
    [[ -f /etc/fedora-release ]] || warn "Not Fedora (/etc/fedora-release missing) — proceeding with caution."
}

# 3. Steps
step_optimise_dnf() {
    log "Configuring DNF for faster downloads..."
    local kv
    for kv in "${DNF_KEYS[@]}"; do
        local key="${kv%%=*}"
        if grep -q "^${key}=" "$DNF_CONF" 2>/dev/null; then
            log "${key} already configured"
        else
            run bash -c "printf '%s\n' '$kv' >> '$DNF_CONF'"
            ok "Added $kv"
        fi
    done
}

step_system_update() {
    log "Refreshing repositories and upgrading packages..."
    run dnf upgrade --refresh -y
}

step_rpmfusion() {
    log "Enabling RPM Fusion (Free & Non-Free)..."
    local ver url
    ver="$(rpm -E %fedora 2>/dev/null || echo 44)"
    for url in "${RPMFUSION_URLS[@]}"; do
        run dnf install -y "$(printf "$url" "$ver")"
    done
    run dnf install -y rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data
}

step_flatpak_openh264() {
    log "Installing Flatpak and Flathub..."
    if command -v flatpak &>/dev/null; then
        run flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        ok "Flathub repository enabled"
    else
        warn "Flatpak not installed — skipping Flathub setup"
    fi

    log "Enabling Cisco OpenH264 repository..."
    if ! dnf config-manager --help &>/dev/null; then
        run dnf install -y dnf-plugins-core
    fi
    run dnf config-manager setopt fedora-cisco-openh264.enabled=1
    run dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264
}

step_codecs() {
    log "Swapping to full FFmpeg build from RPM Fusion..."
    run dnf swap -y ffmpeg-free ffmpeg --allowerasing
    log "Installing GStreamer multimedia plugins..."
    run dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
}

step_cleanup() {
    log "Removing unused packages and cache..."
    run dnf autoremove -y
    run dnf clean all
}

# 4. Main
main() {
    parse_args "$@"
    require_root
    require_fedora
    log "Starting Fedora post-installation setup..."
    step_optimise_dnf
    step_system_update
    step_rpmfusion
    step_flatpak_openh264
    step_codecs
    step_cleanup
    echo ""
    ok "Setup complete."
    echo "DNF: parallel downloads, fastestmirror, 5 per mirror."
    echo "RPM Fusion, Flathub, OpenH264, FFmpeg: installed."
    echo "Codecs and cleanup: complete."
    warn "Restart the machine."
}

main "$@"
