#!/bin/bash
# setup-virtualization.sh — Set up or remove Virt-Manager, QEMU, and KVM on Fedora 44
# Usage:
#   ./setup-virtualization.sh           # Install and configure virtualization
#   ./setup-virtualization.sh --remove  # Remove virtualization packages and config
#   ./setup-virtualization.sh -r        # Same as --remove

set -euo pipefail

# ──────────────────────────────────────────────────────────────
# 🎨 Colors
CYAN="\033[0;36m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# ──────────────────────────────────────────────────────────────
# 🛠 Helper
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

# 👤 Add current user to libvirt group (if not already a member)
add_user_to_libvirt_group() {
    echo -e "${YELLOW}👤 Checking if user '$USER' is in the 'libvirt' group...${RESET}"
    if id -nG "$USER" | grep -qw "libvirt"; then
        echo -e "${GREEN}✅ User '$USER' is already in the 'libvirt' group.${RESET}"
    else
        echo -e "${YELLOW}👤 Adding user '$USER' to libvirt group...${RESET}"
        run_cmd "sudo usermod -aG libvirt $USER"
        echo -e "${GREEN}✅ Added. You may need to log out and log back in for group changes to take effect.${RESET}"
    fi
}

# ──────────────────────────────────────────────────────────────
# 🗑 Remove virtualization setup
remove_virtualization() {
    echo -e "${YELLOW}🗑 Stopping libvirtd service...${RESET}"
    run_cmd "sudo systemctl stop libvirtd.socket libvirtd-admin.socket libvirtd-ro.socket libvirtd.service 2>/dev/null || true"
    run_cmd "sudo systemctl disable libvirtd.socket libvirtd-admin.socket libvirtd-ro.socket libvirtd.service 2>/dev/null || true"
    echo -e "${GREEN}✅ libvirtd stopped and disabled.${RESET}"

    echo -e "${YELLOW}🗑 Removing user '$USER' from libvirt group...${RESET}"
    if id -nG "$USER" | grep -qw "libvirt"; then
        run_cmd "sudo gpasswd -d $USER libvirt"
        echo -e "${GREEN}✅ User '$USER' removed from libvirt group.${RESET}"
    else
        echo -e "${YELLOW}ℹ️  User '$USER' is not in the libvirt group, skipping.${RESET}"
    fi

    echo -e "${YELLOW}🗑 Removing virtualization packages...${RESET}"
    run_cmd "sudo dnf remove -y @virtualization"
    echo -e "${GREEN}✅ Virtualization packages removed.${RESET}"

    echo -e "${YELLOW}⚠️  Note: VM images and configurations in /var/lib/libvirt/ and ~/.config/libvirt/ were not removed.${RESET}"
    echo -e "${YELLOW}   Remove them manually if desired.${RESET}"
}

# ──────────────────────────────────────────────────────────────
# 🎯 Main script logic
main() {
    # Check for removal mode
    if [[ "${1:-}" == "--remove" || "${1:-}" == "-r" ]]; then
        clear
        echo -e "${RED}🗑 Setting up to REMOVE Virt-Manager and KVM...${RESET}"
        sudo -v || { echo -e "${RED}❌ Sudo required. Exiting.${RESET}"; exit 1; }
        remove_virtualization
        echo -e "${GREEN}🎉 Virt-Manager & KVM removal complete!${RESET}"
        echo -e "${YELLOW}💡 You may want to log out and back in for group changes to take effect.${RESET}"
        exit 0
    fi

    # Default: Installation mode
    clear
    echo -e "${CYAN}🚀 Setting up Virt-Manager and KVM...${RESET}"
    sudo -v || { echo -e "${RED}❌ Sudo required. Exiting.${RESET}"; exit 1; }

    install_virtualization_packages
    enable_libvirtd_service
    add_user_to_libvirt_group

    echo -e "${GREEN}🎉 Virt-Manager & KVM setup complete!${RESET}"
    echo -e "${YELLOW}💡 You may need to log out and log back in for group changes to take effect.${RESET}"
}

# Run main function with all arguments
main "$@"
