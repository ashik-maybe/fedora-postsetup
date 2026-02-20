#!/usr/bin/env bash
# setup-warp.sh — Installs Warp Terminal on Fedora

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
    # Checks if the repo ID exists in any .repo file
    grep -q "\[$1\]" /etc/yum.repos.d/*.repo &>/dev/null
}

# ────────────────────────────────────────────────────────────
# 🚀 Start

clear
echo -e "${CYAN}🧠 Warp Terminal Setup for Fedora${RESET}"
sudo -v || { echo -e "${RED}❌ Sudo privileges required. Exiting.${RESET}"; exit 1; }

# ────────────────────────────────────────────────────────────
# 📦 Add Warp Repository

echo -e "${YELLOW}📦 Checking Warp repository...${RESET}"

if ! repo_exists "warpdotdev"; then
    # Import GPG key directly from Warp's CDN
    run_cmd "sudo rpm --import https://releases.warp.dev/linux/keys/warp.asc"

    # Create the repo file
    run_cmd "sudo tee /etc/yum.repos.d/warpdotdev.repo > /dev/null <<EOF
[warpdotdev]
name=warpdotdev
baseurl=https://releases.warp.dev/linux/rpm/stable
enabled=1
gpgcheck=1
gpgkey=https://releases.warp.dev/linux/keys/warp.asc
EOF"
else
    echo -e "${GREEN}✅ Warp repo already configured.${RESET}"
fi

# ────────────────────────────────────────────────────────────
# 🧰 Install Warp

echo -e "${YELLOW}🔧 Installing Warp...${RESET}"

if ! command -v warp-terminal &>/dev/null; then
    run_cmd "sudo dnf install -y warp-terminal"
else
    echo -e "${GREEN}✅ Warp Terminal already installed.${RESET}"
fi

# ────────────────────────────────────────────────────────────
# ✅ Done
echo -e "${GREEN}🎉 Warp is ready to use!${RESET}"
