#!/bin/bash
# install-virt.sh — Set up Virt-Manager, QEMU, and KVM on Fedora

set -euo pipefail

# ──────────────────────────────────────────────────────────────
# 🎨 Colors
CYAN="\033[0;36m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# ──────────────────────────────────────────────────────────────
# 🛠️ Helper
run_cmd() {
    echo -e "${CYAN}🔧 Running: $1${RESET}"
    eval "$1"
}

# ──────────────────────────────────────────────────────────────
# 📦 Install virtualization tools
install_virtualization_packages() {
    echo -e "${YELLOW}📦 Installing Virt-Manager, QEMU, and KVM tools...${RESET}"
    run_cmd "sudo dnf install -y @virtualization"
    echo -e "${GREEN}✅ Virtualization packages installed.${RESET}"
}

# 🔌 Enable and start libvirtd
enable_libvirtd_service() {
    echo -e "${YELLOW}🔌 Enabling and starting libvirtd...${RESET}"
    run_cmd "sudo systemctl enable --now libvirtd"
    echo -e "${GREEN}✅ libvirtd is active and enabled at boot.${RESET}"
}

# 👤 Add current user to libvirt group
add_user_to_libvirt_group() {
    echo -e "${YELLOW}👤 Adding user '$USER' to libvirt group...${RESET}"
    run_cmd "sudo usermod -aG libvirt $USER"
    echo -e "${GREEN}✅ You may need to log out and log back in for group changes to take effect.${RESET}"
}

# ──────────────────────────────────────────────────────────────
# ▶️ Run all
clear
echo -e "${CYAN}🚀 Setting up Virt-Manager and KVM...${RESET}"
sudo -v || { echo -e "${RED}❌ Sudo required. Exiting.${RESET}"; exit 1; }

install_virtualization_packages
enable_libvirtd_service
# add_user_to_libvirt_group

echo -e "${GREEN}🎉 Virt-Manager & KVM setup complete!${RESET}"
