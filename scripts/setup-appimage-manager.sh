#!/usr/bin/env bash
# setup-appimage.sh — Installs Gear Lever and FUSE support

set -euo pipefail

# 🎨 Colors
CYAN="\033[0;36m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
RESET="\033[0m"

# 🛠️ Helpers
run_cmd() {
    echo -e "${CYAN}🔧 Running: $1${RESET}"
    eval "$1"
}

# 📦 Ensure Flatpak
ensure_flatpak() {
    echo -e "${YELLOW}📦 Checking Flatpak...${RESET}"
    if ! command -v flatpak &>/dev/null; then
        run_cmd "sudo dnf install -y flatpak"
    else
        echo -e "${GREEN}✅ Flatpak already installed.${RESET}"
    fi
}

# 🌍 Ensure Flathub
ensure_flathub() {
    echo -e "${YELLOW}🌍 Checking Flathub...${RESET}"
    if ! flatpak remotes | grep -q flathub; then
        run_cmd "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
    else
        echo -e "${GREEN}✅ Flathub already configured.${RESET}"
    fi
}

# 🛠️ Ensure FUSE (Required for AppImages)
ensure_fuse() {
    echo -e "${YELLOW}🧬 Checking FUSE libraries...${RESET}"
    run_cmd "sudo dnf install -y fuse-libs"
}

# ⚙️ Install Gear Lever
install_gear_lever() {
    echo -e "${YELLOW}⚙️ Installing Gear Lever...${RESET}"
    if ! flatpak list | grep -q it.mijorus.gearlever; then
        run_cmd "flatpak install -y flathub it.mijorus.gearlever"
    else
        echo -e "${GREEN}✅ Gear Lever already installed.${RESET}"
    fi
}

# ▶️ Run all
ensure_flatpak
ensure_flathub
ensure_fuse
install_gear_lever

echo -e "${GREEN}🎉 AppImage support setup complete.${RESET}"
