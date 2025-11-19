#!/usr/bin/env bash
# install-google-chrome-stable.sh — Installs Google Chrome Stable on RPM-based Linux

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
echo -e "${CYAN}🔍 Installing Google Chrome Stable${RESET}"
sudo -v || { echo -e "${RED}❌ Sudo privileges required. Exiting.${RESET}"; exit 1; }

# ────────────────────────────────────────────────────────────
# 📦 Add Google Chrome Repo

echo -e "${YELLOW}📦 Checking Google Chrome repository...${RESET}"

if ! repo_exists "google-chrome"; then
    run_cmd "sudo tee /etc/yum.repos.d/google-chrome.repo > /dev/null <<EOF
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF"
    echo -e "${GREEN}✅ Google Chrome repository added.${RESET}"
else
    echo -e "${GREEN}✅ Google Chrome repo already configured.${RESET}"
fi

# ────────────────────────────────────────────────────────────
# 🧰 Install Google Chrome

echo -e "${YELLOW}🔧 Installing Google Chrome Stable...${RESET}"

if ! command -v google-chrome-stable &>/dev/null; then
    # Update package cache first
    run_cmd "sudo dnf makecache"
    # Install the package
    run_cmd "sudo dnf install -y google-chrome-stable"
    echo -e "${GREEN}✅ Google Chrome Stable installed.${RESET}"
else
    echo -e "${GREEN}✅ Google Chrome Stable already installed.${RESET}"
fi

# ────────────────────────────────────────────────────────────
# ✅ Done
echo -e "${GREEN}🎉 Google Chrome Stable is ready to use!${RESET}"
echo -e "${GREEN}   Launch it from your app menu or by running 'google-chrome-stable'${RESET}"
