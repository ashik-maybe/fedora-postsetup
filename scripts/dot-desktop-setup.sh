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
BOLD="\033[1m"
ITALIC="\033[3m"

# ------------------------
# Run command safely
# ------------------------

run_cmd() {
    echo -e "${CYAN}💻 Running: $1${RESET}"
    eval "$1"
    if [ $? -ne 0 ]; then
        echo -e "${RED}⚠️ Command failed: $1${RESET}"
        exit 1
    fi
}

# ------------------------
# Ask for user confirmation
# ------------------------

ask_yes_no() {
    while true; do
        read -p "${YELLOW}💬 $1 (y/n): ${RESET}" yn
        case $yn in
            [Yy]* ) return 0;;  # Yes
            [Nn]* ) return 1;;  # No
            * ) echo -e "${RED}❌ Please answer yes or no.${RESET}";;
        esac
    done
}

# ------------------------
# Check if the system is using Wayland
# ------------------------

is_wayland() {
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        return 0  # Wayland is active
    else
        return 1  # Not Wayland
    fi
}

# ------------------------
# Force Wayland for Brave
# ------------------------

force_brave_wayland() {
    # Check if the system is Wayland
    if ! is_wayland; then
        echo -e "${RED}❌ Not using Wayland! Skipping Brave Wayland setup.${RESET}"
        return
    fi

    # Check if Brave is installed
    if ! command -v brave-browser &>/dev/null; then
        echo -e "${RED}❌ Brave Browser is not installed! Skipping Wayland setup.${RESET}"
        return
    fi

    if ask_yes_no "🌟 Do you want to force Brave browser to use Wayland?"; then
        echo -e "${MAGENTA}🔍 Checking for Brave .desktop file...${RESET}"

        if [[ -f "./files/brave-browser.desktop" ]]; then
            echo -e "${GREEN}✅ Found Brave .desktop file. Copying to ~/.local/share/applications/${RESET}"

            # Copy the Brave .desktop file to ~/.local/share/applications/ and ensure it's executable
            run_cmd "cp ./files/brave-browser.desktop ~/.local/share/applications/brave-browser.desktop"
            run_cmd "chmod +x ~/.local/share/applications/brave-browser.desktop"

            echo -e "${GREEN}🎉 Brave .desktop file copied and made executable.${RESET}"
        else
            echo -e "${RED}❌ Brave .desktop file not found! Skipping Wayland setup.${RESET}"
        fi
    else
        echo -e "${YELLOW}🔸 Skipping Brave Wayland force.${RESET}"
    fi
}

# ------------------------
# Force Wayland for Chrome
# ------------------------

force_chrome_wayland() {
    # Check if the system is Wayland
    if ! is_wayland; then
        echo -e "${RED}❌ Not using Wayland! Skipping Chrome Wayland setup.${RESET}"
        return
    fi

    # Check if Google Chrome is installed
    if ! command -v google-chrome &>/dev/null; then
        echo -e "${RED}❌ Google Chrome is not installed! Skipping Wayland setup.${RESET}"
        return
    fi

    if ask_yes_no "🌟 Do you want to force Google Chrome to use Wayland?"; then
        echo -e "${MAGENTA}🔍 Checking for Chrome .desktop file...${RESET}"

        if [[ -f "./files/google-chrome.desktop" ]]; then
            echo -e "${GREEN}✅ Found Chrome .desktop file. Copying to ~/.local/share/applications/${RESET}"

            # Copy the Chrome .desktop file to ~/.local/share/applications/ and ensure it's executable
            run_cmd "cp ./files/google-chrome.desktop ~/.local/share/applications/google-chrome.desktop"
            run_cmd "chmod +x ~/.local/share/applications/google-chrome.desktop"

            echo -e "${GREEN}🎉 Chrome .desktop file copied and made executable.${RESET}"
        else
            echo -e "${RED}❌ Google Chrome .desktop file not found! Skipping Wayland setup.${RESET}"
        fi
    else
        echo -e "${YELLOW}🔸 Skipping Chrome Wayland force.${RESET}"
    fi
}

# ------------------------
# Main Execution
# ------------------------

clear
echo -e "${CYAN}🌟 Starting the Force Wayland for Browsers Script...${RESET}"

# Handle Brave and Chrome separately
force_brave_wayland
force_chrome_wayland

echo -e "${CYAN}✅ Script completed!${RESET}"
