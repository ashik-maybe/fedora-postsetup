#!/usr/bin/env bash
# install-appimage-manager.sh — Installs Gear Lever (AppImage manager) via Flatpak

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

# ──────────────────────────────────────────────────────────────
# 📦 Ensure Flatpak
ensure_flatpak() {
    echo -e "${YELLOW}📦 Checking Flatpak...${RESET}"
    if ! command -v flatpak &>/dev/null; then
        run_cmd "sudo dnf install -y flatpak"
    else
        echo -e "${GREEN}✅ Flatpak already installed.${RESET}"
    fi
}

# ──────────────────────────────────────────────────────────────
# 🌍 Ensure Flathub
ensure_flathub() {
    echo -e "${YELLOW}🌍 Checking Flathub...${RESET}"
    if ! flatpak remotes | grep -q flathub; then
        run_cmd "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
    else
        echo -e "${GREEN}✅ Flathub already configured.${RESET}"
    fi
}

# ──────────────────────────────────────────────────────────────
# ⚙️ Install Gear Lever
install_gear_lever() {
    echo -e "${YELLOW}⚙️ Installing Gear Lever...${RESET}"
    if ! flatpak list | grep -q it.mijorus.gearlever; then
        run_cmd "flatpak install -y flathub it.mijorus.gearlever"
    else
        echo -e "${GREEN}✅ Gear Lever already installed.${RESET}"
    fi
}

# ──────────────────────────────────────────────────────────────
# ▶️ Run all
ensure_flatpak
ensure_flathub
install_gear_lever

echo -e "${GREEN}🎉 Gear Lever setup complete.${RESET}"
