#!/usr/bin/env bash
# setup-vscode.sh — Installs Visual Studio Code on Fedora

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
echo -e "${CYAN}🧠 Visual Studio Code Setup for Fedora${RESET}"
sudo -v || { echo -e "${RED}❌ Sudo privileges required. Exiting.${RESET}"; exit 1; }

# ────────────────────────────────────────────────────────────
# 📦 Add VS Code Repo

echo -e "${YELLOW}📦 Checking Visual Studio Code repository...${RESET}"

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
    echo -e "${GREEN}✅ VS Code repo already configured.${RESET}"
fi

# ────────────────────────────────────────────────────────────
# 🧰 Install VS Code

echo -e "${YELLOW}🔧 Installing Visual Studio Code...${RESET}"

if ! command -v code &>/dev/null; then
    run_cmd "sudo dnf install -y code"
else
    echo -e "${GREEN}✅ Visual Studio Code already installed.${RESET}"
fi

# ────────────────────────────────────────────────────────────
# ✅ Done
echo -e "${GREEN}🎉 VS Code is ready to use!${RESET}"
