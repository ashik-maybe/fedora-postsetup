#!/usr/bin/env bash
# install-brave-browser.sh — Installs Brave Browser on RPM-based Linux

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
echo -e "${CYAN}🦊 Installing Brave Browser${RESET}"
sudo -v || { echo -e "${RED}❌ Sudo privileges required. Exiting.${RESET}"; exit 1; }

# ────────────────────────────────────────────────────────────
# 📦 Add Brave Repo

echo -e "${YELLOW}📦 Checking Brave Browser repository...${RESET}"

if ! repo_exists "brave-browser"; then
    run_cmd "sudo tee /etc/yum.repos.d/brave-browser.repo > /dev/null <<EOF
[brave-browser]
name=Brave Browser
enabled=1
gpgcheck=1
gpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
baseurl=https://brave-browser-rpm-release.s3.brave.com/\$basearch
EOF"
    echo -e "${GREEN}✅ Brave Browser repository added.${RESET}"
else
    echo -e "${GREEN}✅ Brave Browser repo already configured.${RESET}"
fi

# ────────────────────────────────────────────────────────────
# 🧰 Install Brave

echo -e "${YELLOW}🔧 Installing Brave Browser...${RESET}"

if ! command -v brave-browser &>/dev/null; then
    # Update package cache first
    run_cmd "sudo dnf makecache"
    # Install the package
    run_cmd "sudo dnf install -y brave-browser"
    echo -e "${GREEN}✅ Brave Browser installed.${RESET}"
else
    echo -e "${GREEN}✅ Brave Browser already installed.${RESET}"
fi

# ────────────────────────────────────────────────────────────
# ✅ Done
echo -e "${GREEN}🎉 Brave Browser is ready to use!${RESET}"
echo -e "${GREEN}   Launch it from your app menu or by running 'brave-browser'${RESET}"
