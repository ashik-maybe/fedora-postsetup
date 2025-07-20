#!/usr/bin/env bash
# setup-github-desktop.sh — Installs GitHub Desktop on Fedora (ShiftKey fork)

set -euo pipefail

# ────────────────────────────────────────────────────────────
# 🎨 Terminal Styling
CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

# ────────────────────────────────────────────────────────────
# 🛠️ Helper Functions

error_handler() {
    echo -e "${RED}❌ Error: $1${RESET}"
}

run_cmd() {
    local cmd="$1"
    echo -e "${CYAN}🔧 Running: $cmd${RESET}"
    if ! eval "$cmd"; then
        error_handler "Command failed: $cmd"
        exit 1
    fi
}

repo_exists() {
    grep -q "\[$1\]" /etc/yum.repos.d/*.repo &>/dev/null
}

# ────────────────────────────────────────────────────────────
# 🚀 Start

clear
echo -e "${CYAN}🐙 GitHub Desktop Setup for Fedora${RESET}"
sudo -v || { echo -e "${RED}❌ Sudo privileges required. Exiting.${RESET}"; exit 1; }

# ────────────────────────────────────────────────────────────
# 📦 Add GitHub Desktop Repo

echo -e "${YELLOW}📦 Checking GitHub Desktop repository...${RESET}"

if ! repo_exists "mwt-packages"; then
    run_cmd "sudo rpm --import https://mirror.mwt.me/shiftkey-desktop/gpgkey"
    run_cmd "sudo tee /etc/yum.repos.d/mwt-packages.repo > /dev/null <<EOF
[mwt-packages]
name=GitHub Desktop
baseurl=https://mirror.mwt.me/shiftkey-desktop/rpm
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirror.mwt.me/shiftkey-desktop/gpgkey
EOF"
else
    echo -e "${GREEN}✅ GitHub Desktop repo already configured.${RESET}"
fi

# ────────────────────────────────────────────────────────────
# 🧰 Install GitHub Desktop

echo -e "${YELLOW}🔧 Installing GitHub Desktop...${RESET}"

if ! command -v github-desktop &>/dev/null; then
    run_cmd "sudo dnf install -y github-desktop"
else
    echo -e "${GREEN}✅ GitHub Desktop already installed.${RESET}"
fi

# ────────────────────────────────────────────────────────────
# ✅ Done
echo -e "${GREEN}🎉 GitHub Desktop is ready to use!${RESET}"
