#!/bin/bash
# fedora-postinstall.sh — Post-install setup for Fedora Workstation

set -euo pipefail

# Styling
CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

# Title
clear
echo -e "${CYAN}🚀 Fedora Post-Install Script Starting...${RESET}"
sudo -v || { echo -e "${RED}❌ Failed to acquire sudo privileges. Exiting.${RESET}"; exit 1; }

# Keep sudo alive while the script runs
( while true; do sudo -n true; sleep 60; done ) 2>/dev/null &
KEEP_SUDO_PID=$!
trap 'kill $KEEP_SUDO_PID' EXIT

# Helper: run command with feedback
run_cmd() {
    local cmd="$1"
    echo -e "${CYAN}🔧 Running: $cmd${RESET}"
    eval "$cmd" || echo -e "${RED}❌ Error: Command failed: $cmd${RESET}"
}

# Helper: check if repo exists
repo_exists() {
    grep -q "\[$1\]" /etc/yum.repos.d/*.repo &>/dev/null
}

# ===============================
# Phase 1: Essentials
# ===============================

# 1. Overwrite and optimize DNF configuration
optimize_dnf_conf() {
    echo -e "${YELLOW}⚙️ Optimizing DNF configuration...${RESET}"
    sudo tee /etc/dnf/dnf.conf > /dev/null <<EOF
[main]
gpgcheck=True
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
max_parallel_downloads=10
fastestmirror=True
color=auto
EOF
    echo -e "${GREEN}✅ DNF optimized and configuration overwritten.${RESET}"
}

# 2. Ensure Flatpak and Flathub
ensure_flatpak_support() {
    echo -e "${YELLOW}📦 Checking Flatpak setup...${RESET}"
    if ! command -v flatpak &>/dev/null; then
        run_cmd "sudo dnf install -y flatpak"
    else
        echo -e "${GREEN}✅ Flatpak already installed.${RESET}"
    fi

    if ! flatpak remotes | grep -q flathub; then
        run_cmd "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
    else
        echo -e "${GREEN}✅ Flathub already configured.${RESET}"
    fi
}

# 3. Add RPM Fusion, Chrome, and WARP Repos
add_third_party_repos() {
    echo -e "${YELLOW}🌐 Adding third-party repositories...${RESET}"

    if ! repo_exists "rpmfusion-free" || ! repo_exists "rpmfusion-nonfree"; then
        run_cmd "sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-\$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-\$(rpm -E %fedora).noarch.rpm"
    else
        echo -e "${GREEN}✅ RPM Fusion repos already added.${RESET}"
    fi

    if ! repo_exists "cloudflare-warp"; then
        run_cmd "curl -fsSl https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | sudo tee /etc/yum.repos.d/cloudflare-warp.repo"
    else
        echo -e "${GREEN}✅ Cloudflare WARP repo already exists.${RESET}"
    fi

    if ! repo_exists "google-chrome"; then
        run_cmd "sudo sh -c 'echo -e \"[google-chrome]
name=Google Chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub\" > /etc/yum.repos.d/google-chrome.repo'"
    else
        echo -e "${GREEN}✅ Google Chrome repo already exists.${RESET}"
    fi
}

# 4. Remove Firefox & LibreOffice
remove_firefox_and_libreoffice() {
    echo -e "${YELLOW}🧹 Removing Firefox and LibreOffice...${RESET}"
    run_cmd "sudo dnf remove -y firefox* libreoffice*"
    run_cmd "rm -rf ~/.mozilla ~/.cache/mozilla ~/.config/libreoffice ~/.cache/libreoffice"
    echo -e "${GREEN}✅ Firefox and LibreOffice removed.${RESET}"
}

# ===============================
# Phase 2: Optional Installations
# ===============================

# === User Choices ===
# Chrome
if ! command -v google-chrome &>/dev/null; then
    read -p "🧭 Install Google Chrome? (y/n): " chrome_choice
else
    echo -e "${GREEN}✅ Google Chrome already installed. Skipping prompt.${RESET}"
    chrome_choice="n"
fi

# Brave
if ! command -v brave-browser &>/dev/null; then
    read -p "🧭 Install Brave Browser? (y/n): " brave_choice
else
    echo -e "${GREEN}✅ Brave Browser already installed. Skipping prompt.${RESET}"
    brave_choice="n"
fi

# virt-manager / virtualization
if ! rpm -q virt-manager &>/dev/null; then
    read -p "🧭 Install virt-manager and virtualization tools? (y/n): " virt_choice
else
    echo -e "${GREEN}✅ virt-manager already installed. Skipping prompt.${RESET}"
    virt_choice="n"
fi

# Handle Chrome Installation
if [[ "$chrome_choice" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🌐 Installing Google Chrome...${RESET}"
    run_cmd "sudo dnf install -y google-chrome-stable"
else
    echo -e "${CYAN}⏭️ Skipping Google Chrome installation.${RESET}"
fi

# Handle Brave Installation
if [[ "$brave_choice" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🌐 Installing Brave Browser...${RESET}"
    run_cmd "curl -fsS https://dl.brave.com/install.sh | sh"
else
    echo -e "${CYAN}⏭️ Skipping Brave Browser installation.${RESET}"
fi

# Handle Virtualization Installation
if [[ "$virt_choice" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⚙️ Installing virt-manager...${RESET}"
    run_cmd "sudo dnf group install -y 'Virtualization'"
    run_cmd "sudo systemctl enable --now libvirtd"
else
    echo -e "${CYAN}⏭️ Skipping virt-manager installation.${RESET}"
fi

# ===============================
# Phase 3: Cleanup
# ===============================

# 5. Swap to proprietary ffmpeg
replace_ffmpeg_with_proprietary() {
    echo -e "${YELLOW}🎞️ Replacing ffmpeg-free with proprietary ffmpeg...${RESET}"
    run_cmd "sudo dnf -y swap ffmpeg-free ffmpeg --allowerasing"
    echo -e "${GREEN}✅ ffmpeg replaced.${RESET}"
}

# 6. System upgrade
upgrade_system() {
    echo -e "${YELLOW}⬆️ Upgrading system...${RESET}"
    run_cmd "sudo dnf upgrade -y"
    echo -e "${GREEN}✅ System up to date.${RESET}"
}

# 7. Install yt-dlp and aria2
install_yt_dlp_and_aria2c() {
    echo -e "${YELLOW}🎥 Installing yt-dlp and aria2...${RESET}"
    run_cmd "sudo dnf install -y yt-dlp aria2"
    echo -e "${GREEN}✅ yt-dlp and aria2 installed.${RESET}"
}

# 8. Enable fstrim
enable_fstrim() {
    echo -e "${YELLOW}🧊 Enabling fstrim.timer...${RESET}"
    if ! systemctl is-enabled fstrim.timer &>/dev/null; then
        run_cmd "sudo systemctl enable --now fstrim.timer"
    else
        echo -e "${GREEN}✅ fstrim.timer already enabled.${RESET}"
    fi
}

# 9. Clean up
post_install_cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up...${RESET}"
    run_cmd "sudo dnf autoremove -y"
    run_cmd "sudo dnf clean all"
    if command -v flatpak &>/dev/null; then
        run_cmd "flatpak uninstall --unused -y"
        run_cmd "flatpak repair"
    fi
    echo -e "${GREEN}✅ System cleaned.${RESET}"
}

# ==== Execute All Steps ====
optimize_dnf_conf
ensure_flatpak_support
add_third_party_repos
remove_firefox_and_libreoffice
replace_ffmpeg_with_proprietary
upgrade_system
install_yt_dlp_and_aria2c
enable_fstrim
post_install_cleanup

echo -e "${GREEN}🎉 All done! Fedora is ready to roll!${RESET}"
