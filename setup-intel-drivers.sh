#!/usr/bin/env bash

# setup-intel-drivers.sh — Intel VA-API, OpenCL, Vulkan, thermald (Fedora 44+)
# Use for Intel HD 520 and newer.
#
# Usage:
#   sudo ./setup-intel-drivers.sh [--dry-run] [--yes] [--help]
#
# Exit codes: 0 ok · 1 error · 2 aborted
# Idempotent: safe to re-run. Must run as root (except --dry-run).

set -euo pipefail
IFS=$'\n\t'

# 0. Config
readonly VAAPI_PKGS=(intel-media-driver libva-intel-driver libva libva-utils)
readonly COMPUTE_PKGS=(intel-opencl intel-mediasdk)
readonly VULKAN_PKGS=(mesa-vulkan-drivers vulkan-tools)
readonly ENV_FILE="/etc/environment"
readonly PROFILE_FILE="/etc/profile.d/intel-media.sh"
readonly VAAPI_EXPORT="LIBVA_DRIVER_NAME=iHD"

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

check_intel_gpu() {
    if lspci 2>/dev/null | grep -iE "vga|3d|display" | grep -qi "intel"; then
        ok "Intel GPU detected"
    else
        warn "No Intel GPU detected — some packages may be unnecessary."
    fi
}

# 3. Steps
step_vaapi() {
    log "Installing Intel Media Driver (iHD) and VA-API utilities..."
    run dnf install -y "${VAAPI_PKGS[@]}"
}

step_env() {
    log "Configuring environment for iHD driver..."
    if grep -qxF "$VAAPI_EXPORT" "$ENV_FILE" 2>/dev/null; then
        log "$VAAPI_EXPORT already in $ENV_FILE"
    else
        run bash -c "printf '%s\n' '$VAAPI_EXPORT' >> '$ENV_FILE'"
        ok "Set $VAAPI_EXPORT in $ENV_FILE"
    fi
    if [[ -f "$PROFILE_FILE" ]]; then
        log "$PROFILE_FILE already exists"
    else
        run bash -c "cat > '$PROFILE_FILE' <<'EOF'
# Intel Media Driver Configuration
export $VAAPI_EXPORT
EOF"
        run chmod 644 "$PROFILE_FILE"
        ok "Created $PROFILE_FILE"
    fi
}

step_compute() {
    log "Installing Intel OpenCL runtime and Media SDK..."
    run dnf install -y "${COMPUTE_PKGS[@]}"
}

step_vulkan() {
    log "Installing Vulkan drivers..."
    run dnf install -y "${VULKAN_PKGS[@]}"
}

step_monitoring() {
    log "Installing Intel GPU monitoring tools..."
    run dnf install -y intel-gpu-tools
}

step_thermald() {
    log "Installing Thermald..."
    run dnf install -y thermald
    run systemctl enable --now thermald
}

# 4. Main
main() {
    parse_args "$@"
    require_root
    check_intel_gpu
    step_vaapi
    step_env
    step_compute
    step_vulkan
    step_monitoring
    step_thermald
    echo ""
    ok "Setup complete."
    echo "Verify with: vainfo · vulkaninfo --summary · clinfo · sudo intel_gpu_top"
    echo "Encode test: ffmpeg -hwaccel vaapi -hwaccel_output_format vaapi -i input.mp4 -c:v h264_vaapi output.mp4"
    warn "Restart or log out."
}

main "$@"
