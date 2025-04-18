#!/bin/bash

# ------------------------
# Color definitions
# ------------------------
CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
MAGENTA="\033[0;35m"
RESET="\033[0m"

# ------------------------
# Path setup
# ------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
FILES_DIR="${REPO_ROOT}/files"

# ------------------------
# Run command safely
# ------------------------
run_cmd() {
    echo -e "${CYAN}Running: $1${RESET}"
    eval "$1"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Command failed: $1${RESET}"
        exit 1
    fi
}

# ------------------------
# Ask for user confirmation
# ------------------------
ask_yes_no() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# ------------------------
# Force Wayland for Brave
# ------------------------
force_brave_wayland() {
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        if command -v brave-browser &>/dev/null; then
            if ask_yes_no "Do you want to force Brave browser to use Wayland?"; then
                echo -e "${GREEN}Checking for Brave .desktop file...${RESET}"

                if [[ -f "${FILES_DIR}/brave-browser.desktop" ]]; then
                    echo -e "${GREEN}Found Brave .desktop file. Copying to ~/.local/share/applications/${RESET}"
                    run_cmd "cp '${FILES_DIR}/brave-browser.desktop' ~/.local/share/applications/brave-browser.desktop"
                    run_cmd "chmod +x ~/.local/share/applications/brave-browser.desktop"
                    echo -e "${GREEN}🎉 Brave .desktop file copied and made executable.${RESET}"
                else
                    echo -e "${RED}❌ Brave .desktop file not found in ${FILES_DIR}! Skipping.${RESET}"
                fi
            else
                echo -e "${YELLOW}Skipping Brave Wayland setup.${RESET}"
            fi
        else
            echo -e "${RED}❌ Brave browser is not installed!${RESET}"
        fi
    else
        echo -e "${YELLOW}❌ Not using Wayland. Skipping Brave setup.${RESET}"
    fi
}

# ------------------------
# Force Wayland for Chrome
# ------------------------
force_chrome_wayland() {
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        if command -v google-chrome &>/dev/null; then
            if ask_yes_no "Do you want to force Google Chrome to use Wayland?"; then
                echo -e "${GREEN}Checking for Chrome .desktop file...${RESET}"

                if [[ -f "${FILES_DIR}/google-chrome.desktop" ]]; then
                    echo -e "${GREEN}Found Chrome .desktop file. Copying to ~/.local/share/applications/${RESET}"
                    run_cmd "cp '${FILES_DIR}/google-chrome.desktop' ~/.local/share/applications/google-chrome.desktop"
                    run_cmd "chmod +x ~/.local/share/applications/google-chrome.desktop"
                    echo -e "${GREEN}🎉 Chrome .desktop file copied and made executable.${RESET}"
                else
                    echo -e "${RED}❌ Chrome .desktop file not found in ${FILES_DIR}! Skipping.${RESET}"
                fi
            else
                echo -e "${YELLOW}Skipping Chrome Wayland setup.${RESET}"
            fi
        else
            echo -e "${RED}❌ Google Chrome is not installed!${RESET}"
        fi
    else
        echo -e "${YELLOW}❌ Not using Wayland. Skipping Chrome setup.${RESET}"
    fi
}

# ------------------------
# Force Wayland for Discord
# ------------------------
setup_discord() {
    if [[ -f "$HOME/software/Discord/Discord" ]]; then
        echo -e "${MAGENTA}🔍 Found Discord executable. Checking for discord.desktop...${RESET}"

        if [[ -f "${FILES_DIR}/discord.desktop" ]]; then
            echo -e "${GREEN}✅ Found Discord .desktop file. Copying to ~/.local/share/applications/${RESET}"
            run_cmd "cp '${FILES_DIR}/discord.desktop' ~/.local/share/applications/discord.desktop"
            run_cmd "chmod +x ~/.local/share/applications/discord.desktop"
            echo -e "${GREEN}🎉 Discord .desktop file copied and made executable.${RESET}"
        else
            echo -e "${RED}❌ Discord .desktop file not found in ${FILES_DIR}! Skipping.${RESET}"
        fi
    else
        echo -e "${YELLOW}❌ Discord executable not found at ~/software/Discord/Discord! Skipping.${RESET}"
    fi
}

# ------------------------
# Main Execution
# ------------------------
clear
echo -e "${CYAN}Force Wayland for Browsers Script Starting...${RESET}"

force_brave_wayland
force_chrome_wayland
setup_discord

echo -e "${CYAN}Script completed.${RESET}"
