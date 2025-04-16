#!/bin/bash

# ------------------------
# Color definitions
# ------------------------
CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

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
            [Yy]* ) return 0;;  # Yes
            [Nn]* ) return 1;;  # No
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# ------------------------
# Force Wayland for Brave
# ------------------------

force_brave_wayland() {
    if ask_yes_no "Do you want to force Brave browser to use Wayland?"; then
        echo -e "${GREEN}Checking for Brave .desktop file...${RESET}"

        if [[ -f "./brave-browser.desktop" ]]; then
            echo -e "${GREEN}Found Brave .desktop file. Copying to ~/.local/share/applications/${RESET}"

            # Copy the Brave .desktop file to ~/.local/share/applications/ and ensure it's executable
            run_cmd "cp ./brave-browser.desktop ~/.local/share/applications/brave-browser.desktop"
            run_cmd "chmod +x ~/.local/share/applications/brave-browser.desktop"

            echo -e "${GREEN}.desktop file copied and made executable.${RESET}"
        else
            echo -e "${RED}Brave .desktop file not found! Skipping Wayland setup.${RESET}"
        fi
    else
        echo -e "${YELLOW}Skipping Brave Wayland force.${RESET}"
    fi
}

# ------------------------
# Force Wayland for Chrome
# ------------------------

force_chrome_wayland() {
    if ask_yes_no "Do you want to force Google Chrome to use Wayland?"; then
        echo -e "${GREEN}Checking for Chrome .desktop file...${RESET}"

        if [[ -f "./google-chrome.desktop" ]]; then
            echo -e "${GREEN}Found Chrome .desktop file. Copying to ~/.local/share/applications/${RESET}"

            # Copy the Chrome .desktop file to ~/.local/share/applications/ and ensure it's executable
            run_cmd "cp ./google-chrome.desktop ~/.local/share/applications/google-chrome.desktop"
            run_cmd "chmod +x ~/.local/share/applications/google-chrome.desktop"

            echo -e "${GREEN}.desktop file copied and made executable.${RESET}"
        else
            echo -e "${RED}Google Chrome .desktop file not found! Skipping Wayland setup.${RESET}"
        fi
    else
        echo -e "${YELLOW}Skipping Chrome Wayland force.${RESET}"
    fi
}

# ------------------------
# Main Execution
# ------------------------

clear
echo -e "${CYAN}Force Wayland for Browsers Script Starting...${RESET}"

# Handle Brave and Chrome separately
force_brave_wayland
force_chrome_wayland

echo -e "${CYAN}Script completed.${RESET}"
