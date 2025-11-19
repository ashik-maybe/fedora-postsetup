#!/usr/bin/env bash
# install-antigravity.sh — Installs Google's Antigravity AI Coding IDE on RPM-based Linux

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
echo -e "${CYAN}🚀 Installing Google's Antigravity AI Coding IDE${RESET}"
echo -e "${CYAN}   (Built on VS Code - productivity-focused with AI features)${RESET}"
sudo -v || { echo -e "${RED}❌ Sudo privileges required. Exiting.${RESET}"; exit 1; }

# ────────────────────────────────────────────────────────────
# 📦 Add Antigravity Repo

echo -e "${YELLOW}📦 Checking Antigravity repository...${RESET}"

if ! repo_exists "antigravity-rpm"; then
    run_cmd "sudo tee /etc/yum.repos.d/antigravity.repo > /dev/null <<EOF
[antigravity-rpm]
name=Antigravity RPM Repository
baseurl=https://us-central1-yum.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-rpm
enabled=1
gpgcheck=0
EOF"
    echo -e "${GREEN}✅ Antigravity repository added.${RESET}"
else
    echo -e "${GREEN}✅ Antigravity repo already configured.${RESET}"
fi

# ────────────────────────────────────────────────────────────
# 🧰 Install Antigravity

echo -e "${YELLOW}🔧 Installing Antigravity IDE...${RESET}"

if ! command -v antigravity &>/dev/null; then
    # Update package cache first
    run_cmd "sudo dnf makecache"
    # Install the package
    run_cmd "sudo dnf install -y antigravity"
    echo -e "${GREEN}✅ Antigravity IDE installed.${RESET}"
else
    echo -e "${GREEN}✅ Antigravity IDE already installed.${RESET}"
fi

# ────────────────────────────────────────────────────────────
# ✅ Done
echo -e "${GREEN}🎉 Antigravity AI Coding IDE is ready to use!${RESET}"
echo -e "${GREEN}   Launch it from your app menu or by running 'antigravity'${RESET}"
