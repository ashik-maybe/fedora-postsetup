#!/bin/bash
# fedora-devtools.sh — Git, VS Code, and GitHub Desktop setup for Fedora

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
echo -e "${CYAN}🚀 Fedora Dev Tools Setup (Git, VS Code, GitHub Desktop)${RESET}"
sudo -v || { echo -e "${RED}❌ Failed to acquire sudo privileges. Exiting.${RESET}"; exit 1; }

# ────────────────────────────────────────────────────────────
# 📦 Add Repositories

echo -e "${YELLOW}📦 Checking and adding repositories...${RESET}"

# VS Code
if ! repo_exists "code"; then
    run_cmd "sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc"
    run_cmd "sudo tee /etc/yum.repos.d/vscode.repo > /dev/null <<EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF"
else
    echo -e "${GREEN}✅ VS Code repository already exists.${RESET}"
fi

# GitHub Desktop
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
    echo -e "${GREEN}✅ GitHub Desktop repository already exists.${RESET}"
fi

# ────────────────────────────────────────────────────────────
# 🧰 Install Tools

echo -e "${YELLOW}🔧 Installing development tools...${RESET}"

# Git
if ! command -v git &>/dev/null; then
    run_cmd "sudo dnf install -y git"
else
    echo -e "${GREEN}✅ Git already installed.${RESET}"
fi

# VS Code
if ! command -v code &>/dev/null; then
    run_cmd "sudo dnf install -y code"
else
    echo -e "${GREEN}✅ VS Code already installed.${RESET}"
fi

# GitHub Desktop
if ! command -v github-desktop &>/dev/null; then
    run_cmd "sudo dnf install -y github-desktop"
else
    echo -e "${GREEN}✅ GitHub Desktop already installed.${RESET}"
fi

# ────────────────────────────────────────────────────────────
# ✅ Done
echo -e "${GREEN}🎉 All done! Your Fedora dev tools are ready to roll!${RESET}"
