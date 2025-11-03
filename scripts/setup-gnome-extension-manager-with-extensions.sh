#!/bin/bash
# gnome-setup.sh — GNOME setup for Fedora

set -euo pipefail

# ──────────────────────────────────────────────────────────────
# 🎨 Colors
CYAN="\033[0;36m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# ──────────────────────────────────────────────────────────────
# 🛠️ Helpers
run_cmd() {
    echo -e "${CYAN}🔧 Running: $1${RESET}"
    eval "$1"
}

is_gnome() {
    [ "$(gnome-shell --version &>/dev/null && echo true)" == "true" ]
}

# ──────────────────────────────────────────────────────────────
# 📦 Install Flatpak and Extension Manager
install_flatpak_and_extension_manager() {
    if ! command -v flatpak &>/dev/null; then
        echo -e "${YELLOW}🔧 Flatpak is not installed. Would you like to install it? (y/n): ${RESET}"
        read -r install_flatpak
        if [[ "$install_flatpak" =~ ^[Yy]$ ]]; then
            run_cmd "sudo dnf install -y flatpak"
            echo -e "${GREEN}✅ Flatpak installed.${RESET}"
        else
            echo -e "${RED}❌ Flatpak installation skipped.${RESET}"
            return
        fi
    fi

    # Add Flathub repo if it's not already added
    if ! flatpak remotes | grep -q flathub; then
        echo -e "${YELLOW}🔧 Flathub repository not found. Would you like to add it? (y/n): ${RESET}"
        read -r add_flathub
        if [[ "$add_flathub" =~ ^[Yy]$ ]]; then
            run_cmd "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
            echo -e "${GREEN}✅ Flathub repository added.${RESET}"
        else
            echo -e "${RED}❌ Flathub repository addition skipped.${RESET}"
            return
        fi
    else
        echo -e "${GREEN}✅ Flathub repository already configured.${RESET}"
    fi

    # Install Extension Manager if not installed
    if ! flatpak list | grep -q com.mattjakeman.ExtensionManager; then
        echo -e "${YELLOW}🔧 Extension Manager (com.mattjakeman.ExtensionManager) is not installed. Would you like to install it? (y/n): ${RESET}"
        read -r install_extension_manager
        if [[ "$install_extension_manager" =~ ^[Yy]$ ]]; then
            run_cmd "flatpak install -y flathub com.mattjakeman.ExtensionManager"
            echo -e "${GREEN}✅ Extension Manager installed.${RESET}"
        else
            echo -e "${RED}❌ Extension Manager installation skipped.${RESET}"
        fi
    else
        echo -e "${GREEN}✅ Extension Manager is already installed.${RESET}"
    fi
}

# ──────────────────────────────────────────────────────────────
# 🧩 Install GNOME Extensions
install_gnome_extensions() {
    # List of GNOME extensions to check and install
    local extensions=(
        "gnome-shell-extension-appindicator"
        #"gnome-shell-extension-blur-my-shell"
        #"gnome-shell-extension-dash-to-dock"
        #"gnome-shell-extension-caffeine"
        #"gnome-shell-extension-forge"
        # "gnome-shell-extension-gsconnect"
    )

    for extension in "${extensions[@]}"; do
        if rpm -q "$extension" &>/dev/null; then
            echo -e "${GREEN}✅ $extension is already installed.${RESET}"
        else
            echo -e "${YELLOW}🔧 $extension is not installed. Would you like to install it? (y/n): ${RESET}"
            read -r install_extension
            if [[ "$install_extension" =~ ^[Yy]$ ]]; then
                run_cmd "sudo dnf install -y $extension"
                echo -e "${GREEN}✅ $extension installed.${RESET}"
            else
                echo -e "${RED}❌ $extension installation skipped.${RESET}"
            fi
        fi
    done
}

# ──────────────────────────────────────────────────────────────
# ▶️ Run Setup for GNOME
if is_gnome; then
    echo -e "${CYAN}🌟 GNOME environment detected. Proceeding with GNOME setup...${RESET}"

    # Check and install Flatpak and Extension Manager
    install_flatpak_and_extension_manager

    # Check and install GNOME extensions
    install_gnome_extensions

else
    echo -e "${RED}❌ GNOME environment not detected. Skipping GNOME-specific setup.${RESET}"
fi
