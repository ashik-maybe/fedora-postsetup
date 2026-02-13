#!/usr/bin/env bash
# install-cursor.sh — Installs Cursor AI Code Editor on RPM-based Linux

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
    exit 1
}

run_cmd() {
    local cmd="$1"
    echo -e "${CYAN}🔧 Running: $cmd${RESET}"
    if ! eval "$cmd"; then
        error_handler "Command failed: $cmd"
    fi
}

repo_exists() {
    grep -q "\[$1\]" /etc/yum.repos.d/*.repo &>/dev/null
}

# ────────────────────────────────────────────────────────────
# 🚀 Start

clear
echo -e "${CYAN}🚀 Installing Cursor AI Code Editor${RESET}"
echo -e "${CYAN}   (VS Code fork with deep AI integration)${RESET}"
sudo -v || { echo -e "${RED}❌ Sudo privileges required. Exiting.${RESET}"; exit 1; }

# ────────────────────────────────────────────────────────────
# 🔑 Import GPG Key

echo -e "${YELLOW}🔑 Importing Cursor GPG key...${RESET}"
run_cmd "sudo rpm --import https://downloads.cursor.com/keys/anysphere.asc"

# ────────────────────────────────────────────────────────────
# 📦 Add Cursor Repo

echo -e "${YELLOW}📦 Checking Cursor repository...${RESET}"

if ! repo_exists "cursor"; then
    run_cmd "sudo tee /etc/yum.repos.d/cursor.repo > /dev/null <<'EOF'
[cursor]
name=Cursor
baseurl=https://downloads.cursor.com/yumrepo
enabled=1
gpgcheck=1
gpgkey=https://downloads.cursor.com/keys/anysphere.asc
repo_gpgcheck=1
EOF"
    echo -e "${GREEN}✅ Cursor repository added.${RESET}"
else
    echo -e "${GREEN}✅ Cursor repo already configured.${RESET}"
fi

# ────────────────────────────────────────────────────────────
# 🧰 Install Cursor

echo -e "${YELLOW}🔧 Installing Cursor...${RESET}"

if ! command -v cursor &>/dev/null; then
    run_cmd "sudo dnf makecache"
    run_cmd "sudo dnf install -y cursor"
    echo -e "${GREEN}✅ Cursor installed.${RESET}"
else
    echo -e "${GREEN}✅ Cursor already installed.${RESET}"
fi

# ────────────────────────────────────────────────────────────
# ✅ Done
echo -e "${GREEN}🎉 Cursor is ready to use!${RESET}"
echo -e "${GREEN}   Launch with 'cursor' or from your app menu${RESET}"
