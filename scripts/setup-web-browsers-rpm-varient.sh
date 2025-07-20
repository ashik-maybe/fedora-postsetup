#!/usr/bin/env bash
# setup-web-browsers.sh — Interactive browser installer for Fedora

set -euo pipefail

# ──────────────────────────────────────────────────────────────
# 🎨 Colors
CYAN="\033[0;36m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# ──────────────────────────────────────────────────────────────
# 🛠️ Helpers
run_cmd() {
    echo -e "${CYAN}🔧 Running: $1${RESET}"
    eval "$1"
}

repo_exists() {
    grep -q "\[$1\]" /etc/yum.repos.d/*.repo &>/dev/null
}

# ──────────────────────────────────────────────────────────────
# Individual Installers

install_brave() {
    echo -e "${YELLOW}🦁 Installing Brave Browser...${RESET}"
    if command -v brave-browser &>/dev/null; then
        echo -e "${GREEN}✅ Brave is already installed.${RESET}"
        return
    fi

    run_cmd "curl -fsS https://dl.brave.com/install.sh | sh"
}

install_chrome() {
    echo -e "${YELLOW}🌐 Installing Google Chrome...${RESET}"
    if command -v google-chrome &>/dev/null; then
        echo -e "${GREEN}✅ Google Chrome is already installed.${RESET}"
        return
    fi
    if ! repo_exists "google-chrome"; then
        sudo tee /etc/yum.repos.d/google-chrome.repo > /dev/null <<EOF
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
    fi
    run_cmd "sudo dnf install -y google-chrome-stable"
}

install_edge() {
    echo -e "${YELLOW}🪟 Installing Microsoft Edge...${RESET}"
    if command -v microsoft-edge &>/dev/null; then
        echo -e "${GREEN}✅ Microsoft Edge is already installed.${RESET}"
        return
    fi
    if ! repo_exists "microsoft-edge"; then
        sudo tee /etc/yum.repos.d/microsoft-edge.repo > /dev/null <<EOF
[microsoft-edge]
name=Microsoft Edge
baseurl=https://packages.microsoft.com/yumrepos/edge/
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    fi
    run_cmd "sudo dnf install -y microsoft-edge-stable"
}

install_vivaldi() {
    echo -e "${YELLOW}🧭 Installing Vivaldi...${RESET}"
    if command -v vivaldi &>/dev/null; then
        echo -e "${GREEN}✅ Vivaldi is already installed.${RESET}"
        return
    fi
    if ! repo_exists "vivaldi"; then
        sudo tee /etc/yum.repos.d/vivaldi.repo > /dev/null <<EOF
[vivaldi]
name=vivaldi
baseurl=https://repo.vivaldi.com/archive/rpm/x86_64
enabled=1
gpgcheck=1
gpgkey=https://repo.vivaldi.com/archive/linux_signing_key.pub
EOF
    fi
    run_cmd "sudo dnf install -y vivaldi-stable"
}

install_opera() {
    echo -e "${YELLOW}🦉 Installing Opera...${RESET}"
    if command -v opera &>/dev/null; then
        echo -e "${GREEN}✅ Opera is already installed.${RESET}"
        return
    fi
    if ! repo_exists "opera"; then
        sudo tee /etc/yum.repos.d/opera.repo > /dev/null <<EOF
[opera]
name=Opera packages
type=rpm-md
baseurl=https://rpm.opera.com/rpm
gpgcheck=1
gpgkey=https://rpm.opera.com/rpmrepo.key
enabled=1
EOF
    fi
    run_cmd "sudo dnf install -y opera-stable"
}

install_librewolf() {
    echo -e "${YELLOW}🐺 Installing LibreWolf...${RESET}"
    if command -v librewolf &>/dev/null; then
        echo -e "${GREEN}✅ LibreWolf is already installed.${RESET}"
        return
    fi
    if ! repo_exists "librewolf"; then
        curl -fsSL https://repo.librewolf.net/librewolf.repo | sudo tee /etc/yum.repos.d/librewolf.repo > /dev/null
    fi
    run_cmd "sudo dnf install -y librewolf"
}

# ──────────────────────────────────────────────────────────────
# Interactive Prompt

select_browsers() {
    echo -e "${CYAN}🌐 Select browsers to install (space-separated numbers):${RESET}"
    echo "  1) Brave"
    echo "  2) Google Chrome"
    echo "  3) Microsoft Edge"
    echo "  4) Vivaldi"
    echo "  5) Opera"
    echo "  6) LibreWolf"
    echo -ne "${YELLOW}Enter your choice(s): ${RESET}"
    read -r choices

    for choice in $choices; do
        case "$choice" in
            1) install_brave ;;
            2) install_chrome ;;
            3) install_edge ;;
            4) install_vivaldi ;;
            5) install_opera ;;
            6) install_librewolf ;;
            *) echo -e "${RED}❌ Invalid choice: $choice${RESET}" ;;
        esac
    done
}

# ──────────────────────────────────────────────────────────────
# ▶️ Run
select_browsers
echo -e "${GREEN}🎉 Browser installation complete.${RESET}"
