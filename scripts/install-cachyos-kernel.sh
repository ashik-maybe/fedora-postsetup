#!/bin/bash

# install-cachyos-kernel.sh
# Installs, removes, or checks status of CachyOS kernel + KSMD stack on Fedora Workstation
# Usage:
#   ./install-cachyos-kernel.sh           → Install everything (after confirmation)
#   ./install-cachyos-kernel.sh -r        → Remove everything (after confirmation)
#   ./install-cachyos-kernel.sh -s        → Show current kernel and KSMD status

set -e

# Repositories
KERNEL_REPO="bieszczaders/kernel-cachyos"
ADDONS_REPO="bieszczaders/kernel-cachyos-addons"

# Kernel packages
KERNEL_PACKAGES=(
  kernel-cachyos
  kernel-cachyos-devel-matched
)

# KSMD stack packages
KSMD_PACKAGES=(
  libcap-ng
  libcap-ng-devel
  procps-ng
  procps-ng-devel
  cachyos-ksm-settings
)

function confirm_install() {
  echo ""
  echo "This script will perform the following actions:"
  echo "  - Enable COPR repositories for CachyOS kernel and addons"
  echo "  - Install the GCC-compiled CachyOS kernel with BORE-EEVDF scheduler"
  echo "  - Configure SELinux to allow kernel module loading"
  echo "  - Install KSMD stack for memory merging optimization"
  echo "  - Automatically activate KSMD using 'ksmctl --enable'"
  echo "  - Recommend reboot after installation"
  echo ""
  read -rp "Do you want to proceed with installation? [y/N]: " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
}

function confirm_removal() {
  echo ""
  echo "This will remove the following components:"
  echo "  - CachyOS kernel and development headers"
  echo "  - KSMD stack and performance addons"
  echo "  - COPR repositories for kernel and addons"
  echo ""
  read -rp "Are you sure you want to remove everything? [y/N]: " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
}

function install_everything() {
  confirm_install

  echo "Enabling COPR repositories..."
  sudo dnf copr enable -y "$KERNEL_REPO"
  sudo dnf copr enable -y "$ADDONS_REPO"

  echo "Installing CachyOS kernel..."
  sudo dnf install -y "${KERNEL_PACKAGES[@]}"

  echo "Configuring SELinux policy..."
  sudo setsebool -P domain_kernel_load_modules on

  echo "Installing KSMD stack..."
  sudo dnf install -y "${KSMD_PACKAGES[@]}"

  echo "Activating KSMD..."
  sudo ksmctl --enable

  echo ""
  echo "Installation complete. Reboot is recommended to apply the new kernel."
  echo ""
  echo "After reboot, you can verify the setup with the following commands:"
  echo "  Kernel version:        uname -r"
  echo "  KSMD status:           sudo ksmctl --status"
  echo "  Memory merge stats:    ksmstats"
  echo ""
}

function remove_everything() {
  confirm_removal

  echo "Removing CachyOS kernel and KSMD stack..."
  sudo dnf remove -y "${KERNEL_PACKAGES[@]}" "${KSMD_PACKAGES[@]}"

  echo "Disabling COPR repositories..."
  sudo dnf copr disable -y "$KERNEL_REPO"
  sudo dnf copr disable -y "$ADDONS_REPO"

  echo "Removal complete. Reboot to switch back to your previous kernel."
}

function show_status() {
  echo ""
  echo "System Status Report"
  echo "--------------------"
  echo "Kernel version:"
  uname -r
  echo ""

  echo "KSMD status:"
  if command -v ksmctl &>/dev/null; then
    sudo ksmctl --status
  else
    echo "ksmctl not found."
  fi
  echo ""

  echo "Memory merge statistics:"
  if command -v ksmstats &>/dev/null; then
    ksmstats
  else
    echo "ksmstats not found."
  fi
  echo ""
}

# Main logic
case "$1" in
  -r) remove_everything ;;
  -s|--status) show_status ;;
  *) install_everything ;;
esac
