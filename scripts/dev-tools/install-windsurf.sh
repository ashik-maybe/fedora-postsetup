#!/usr/bin/env bash
# install-windsurf.sh — Installs Windsurf AI Code Editor on RPM-based Linux

set -euo pipefail

CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

error_handler() {
    echo -e "${RED}❌ Error: $1${RESET}" >&2
    exit 1
}

run_cmd() {
    echo -e "${CYAN}🔧 Running: $*${RESET}"
    if ! "$@"; then
        error_handler "Command failed: $*"
    fi
}

repo_exists() {
    grep -q "\[$1\]" /etc/yum.repos.d/*.repo &>/dev/null
}

clear
echo -e "${CYAN}🚀 Installing Windsurf AI Code Editor${RESET}"

if ! sudo -v; then
    echo -e "${RED}❌ Sudo privileges required. Exiting.${RESET}" >&2
    exit 1
fi

echo -e "${YELLOW}🔑 Importing Windsurf GPG key...${RESET}"
run_cmd sudo rpm --import https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/RPM-GPG-KEY-windsurf

echo -e "${YELLOW}📦 Checking Windsurf repository...${RESET}"
if ! repo_exists "windsurf"; then
    sudo tee /etc/yum.repos.d/windsurf.repo > /dev/null <<EOF
[windsurf]
name=Windsurf Repository
baseurl=https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/repo/
enabled=1
autorefresh=1
gpgcheck=1
gpgkey=https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/yum/RPM-GPG-KEY-windsurf
repo_gpgcheck=1
EOF
    echo -e "${GREEN}✅ Windsurf repository added.${RESET}"
else
    echo -e "${GREEN}✅ Windsurf repo already configured.${RESET}"
fi

echo -e "${YELLOW}🔧 Installing Windsurf...${RESET}"
if ! command -v windsurf &>/dev/null; then
    run_cmd sudo dnf makecache
    run_cmd sudo dnf install -y windsurf
    echo -e "${GREEN}✅ Windsurf installed.${RESET}"
else
    echo -e "${GREEN}✅ Windsurf already installed.${RESET}"
fi

echo -e "${GREEN}🎉 Windsurf is ready to use!${RESET}"
echo -e "${GREEN}   Launch with 'windsurf' or from your app menu${RESET}"
