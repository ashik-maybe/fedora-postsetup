#!/bin/bash

CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

error_handler() {
    echo -e "${RED}Error: $1${RESET}"
}

run_cmd() {
    local cmd="$1"
    echo -e "${CYAN}Running: $cmd${RESET}"
    eval "$cmd"
    if [ $? -ne 0 ]; then
        error_handler "Command failed: $cmd"
        exit 1
    fi
}

repo_exists() {
    grep -q "\[$1\]" /etc/yum.repos.d/*.repo &>/dev/null
}

clear
echo -e "${CYAN}Fedora Git, VS Code & GitHub Desktop Setup Starting...${RESET}"
sudo -v || { echo -e "${RED}Failed to acquire sudo privileges. Exiting.${RESET}"; exit 1; }

echo -e "${GREEN}Adding repositories if needed...${RESET}"

# VS Code Repo
if ! repo_exists "vscode"; then
    run_cmd "sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc"
    run_cmd "echo -e \"[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc\" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null"
else
    echo -e "${YELLOW}VS Code repository already exists. Skipping.${RESET}"
fi

# GitHub Desktop Repo
if ! repo_exists "mwt-packages"; then
    run_cmd "sudo rpm --import https://mirror.mwt.me/shiftkey-desktop/gpgkey"
    run_cmd "echo -e \"[mwt-packages]
name=GitHub Desktop
baseurl=https://mirror.mwt.me/shiftkey-desktop/rpm
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirror.mwt.me/shiftkey-desktop/gpgkey\" | sudo tee /etc/yum.repos.d/mwt-packages.repo > /dev/null"
else
    echo -e "${YELLOW}GitHub Desktop repository already exists. Skipping.${RESET}"
fi

echo -e "${GREEN}Installing Git, VS Code, and GitHub Desktop...${RESET}"

# Git
if ! command -v git &> /dev/null; then
    run_cmd "sudo dnf install -y git"
else
    echo -e "${YELLOW}Git is already installed. Skipping.${RESET}"
fi

# VS Code & GitHub Desktop
run_cmd "sudo dnf install -y code github-desktop"

echo -e "${GREEN}Installation complete!${RESET}"
