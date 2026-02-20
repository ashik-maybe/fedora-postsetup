#!/usr/bin/env bash
# install-flatpak-support.sh — Ensures Flatpak, Flathub, and Flatseal are installed

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
# 🛡️ Install Flatseal
install_flatseal() {
    echo -e "${YELLOW}🛡 Installing Flatseal...${RESET}"
    if ! flatpak list | grep -q com.github.tchx84.Flatseal; then
        run_cmd "flatpak install -y flathub com.github.tchx84.Flatseal"
    else
        echo -e "${GREEN}✅ Flatseal already installed.${RESET}"
    fi
}

# ──────────────────────────────────────────────────────────────
# Install Warehouse
install_warehouse() {
    echo -e "${YELLOW}🛡 Installing Warehouse...${RESET}"
    if ! flatpak list | grep -q io.github.flattool.Warehouse; then
        run_cmd "flatpak install -y flathub io.github.flattool.Warehouse"
    else
        echo -e "${GREEN}✅ Warehouse already installed.${RESET}"
    fi
}

# ──────────────────────────────────────────────────────────────
# ▶️ Run all
ensure_flatpak
ensure_flathub
install_flatseal
install_warehouse

echo -e "${GREEN}🎉 Flatpak support setup complete.${RESET}"
