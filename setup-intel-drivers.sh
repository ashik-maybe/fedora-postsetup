#!/usr/bin/env bash

# setup-intel.sh — Intel Hardware Acceleration & Media Codecs for Productivity on Fedora
# Optimized for Intel HD Graphics 520 (Skylake) and newer — 3D, Video Editing, Compute
#
# Usage:
#   sudo ./setup-intel.sh

set -euo pipefail

# Visual colors for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Ensure script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Please run this script with sudo:${NC}"
    echo "  sudo $0"
    exit 1
fi

# Check for Intel GPU
if ! lspci | grep -iE "vga|3d|display" | grep -qi "intel"; then
    warn "No Intel GPU detected. Some packages may be unnecessary."
fi

log "Starting Intel-specific Hardware Acceleration & Media Optimization..."

# ----------------------------------------------------------------------
# 1. Install VA-API & Intel Media Drivers
# ----------------------------------------------------------------------
log "Installing Intel Media Driver (iHD) and VA-API utilities..."

# intel-media-driver: Modern iHD driver (Broadwell+ / HD 520 / 6th Gen+)
# libva-intel-driver: Legacy i965 driver (fallback for older apps)
# libva / libva-utils: Core VA-API library and vainfo inspection tool
dnf install -y \
    intel-media-driver \
    libva-intel-driver \
    libva \
    libva-utils

# ----------------------------------------------------------------------
# 2. Configure System Environment for iHD Driver
# ----------------------------------------------------------------------
log "Configuring environment variables for Intel VA-API..."

# Set globally via /etc/environment (works with most shells)
ENV_FILE="/etc/environment"
if ! grep -q "LIBVA_DRIVER_NAME" "$ENV_FILE" 2>/dev/null; then
    echo "LIBVA_DRIVER_NAME=iHD" >> "$ENV_FILE"
    log "Set LIBVA_DRIVER_NAME=iHD in /etc/environment"
fi

# Also set via profile.d for better DM compatibility (GDM, SDDM, etc.)
PROFILE_FILE="/etc/profile.d/intel-media.sh"
if [ ! -f "$PROFILE_FILE" ]; then
    cat > "$PROFILE_FILE" << 'EOF'
# Intel Media Driver Configuration
export LIBVA_DRIVER_NAME=iHD
EOF
    chmod 644 "$PROFILE_FILE"
    log "Created $PROFILE_FILE for better display manager compatibility"
fi

# ----------------------------------------------------------------------
# 3. Intel OpenCL & Media SDK for Compute Tasks
# ----------------------------------------------------------------------
log "Installing Intel OpenCL runtime and Media SDK..."

# OpenCL: GPU compute acceleration (Blender, DaVinci Resolve, darktable)
# Media SDK: Hardware encoding/decoding API (OBS Studio, FFmpeg, HandBrake)
dnf install -y \
    intel-opencl \
    intel-mediasdk

# ----------------------------------------------------------------------
# 4. Vulkan Support (optional but useful for modern 3D apps)
# ----------------------------------------------------------------------
log "Installing Vulkan drivers for 3D viewport acceleration..."

# mesa-vulkan-drivers: Intel ANV Vulkan driver (Blender viewport, modern compositors)
# vulkan-tools: vulkaninfo diagnostic utility
dnf install -y \
    mesa-vulkan-drivers \
    vulkan-tools

# ----------------------------------------------------------------------
# 5. Intel GPU Monitoring Tools
# ----------------------------------------------------------------------
log "Installing Intel GPU monitoring utilities..."

# intel-gpu-tools: Provides intel_gpu_top for real-time GPU usage monitoring
dnf install -y intel-gpu-tools

# ----------------------------------------------------------------------
# 6. Thermal & Power Management
# ----------------------------------------------------------------------
log "Setting up Thermald for Intel thermal management..."

# thermald: Prevents thermal throttling on mobile Intel chips during sustained workloads
dnf install -y thermald
systemctl enable --now thermald

# ----------------------------------------------------------------------
# 7. Verification & Diagnostics Summary
# ----------------------------------------------------------------------
echo ""
success "Intel productivity setup complete!"
echo "----------------------------------------------------------------------"
log "To verify hardware acceleration is working on your GPU, run:"
echo "  1. vainfo                     (Should list iHD driver and supported codecs)"
echo "  2. vulkaninfo --summary       (Should detect Intel ANV driver)"
echo "  3. clinfo                     (Should show Intel OpenCL platform)"
echo "  4. sudo intel_gpu_top         (Real-time GPU utilization monitor)"
echo ""
log "For video encoding benchmarks, try:"
echo "  ffmpeg -hwaccel vaapi -hwaccel_output_format vaapi -i input.mp4 -c:v h264_vaapi output.mp4"
echo "----------------------------------------------------------------------"
warn "Please restart your computer or log out to apply environment variable changes."
