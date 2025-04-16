#!/bin/bash
# fedora-postinstall.sh — Modular post-install script for Fedora

set -euo pipefail

# === Colors ===
CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

# === Helpers ===
run_cmd() {
    echo -e "${CYAN}▶ $1${RESET}"
    eval "$1"
}

phase() {
    echo -e "\n${YELLOW}==> $1${RESET}"
}

# === Intro ===
clear
echo -e "${CYAN}🚀 Fedora Post-Install Script — Starting...${RESET}"
sudo -v || { echo -e "${RED}❌ Sudo required. Exiting.${RESET}"; exit 1; }

# Keep sudo alive
( while true; do sudo -n true; sleep 60; done ) 2>/dev/null &
trap 'kill $!' EXIT

# === User Choices ===
read -p "🧭 Install Google Chrome? (y/n): " chrome_choice
read -p "🧭 Install Brave Browser? (y/n): " brave_choice
read -p "🧭 Install virt-manager and virtualization tools? (y/n): " virt_choice

# ==========================================================
# PHASE 1: ESSENTIALS
# ==========================================================
phase "Phase 1: Essentials Setup"

# DNF Optimization
run_cmd "sudo tee /etc/dnf/dnf.conf > /dev/null <<EOF
[main]
gpgcheck=True
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
max_parallel_downloads=10
fastestmirror=True
color=auto
EOF"

# Flatpak & Flatseal
if ! command -v flatpak &>/dev/null; then
    run_cmd "sudo dnf install -y flatpak"
else echo -e "${GREEN}✅ Flatpak already installed.${RESET}"; fi

if ! flatpak remotes | grep -q flathub; then
    run_cmd "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
else echo -e "${GREEN}✅ Flathub already added.${RESET}"; fi

if ! flatpak list | grep -q com.github.tchx84.Flatseal; then
    run_cmd "flatpak install -y flathub com.github.tchx84.Flatseal"
else echo -e "${GREEN}✅ Flatseal already installed.${RESET}"; fi

# Repositories
phase "➕ Adding RPM Fusion and WARP Repositories"

if ! rpm -q rpmfusion-free-release &>/dev/null; then
    run_cmd "sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-\$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-\$(rpm -E %fedora).noarch.rpm"
else echo -e "${GREEN}✅ RPM Fusion already added.${RESET}"; fi

if [ ! -f /etc/yum.repos.d/cloudflare-warp.repo ]; then
    run_cmd "curl -fsSl https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | sudo tee /etc/yum.repos.d/cloudflare-warp.repo"
else echo -e "${GREEN}✅ WARP repo already exists.${RESET}"; fi

if [ ! -f /etc/yum.repos.d/google-chrome.repo ]; then
    run_cmd "sudo sh -c 'cat > /etc/yum.repos.d/google-chrome.repo <<EOF
[google-chrome]
name=Google Chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF'"
else echo -e "${GREEN}✅ Google Chrome repo already exists.${RESET}"; fi

# Remove Firefox and LibreOffice
phase "🧹 Removing Firefox and LibreOffice"
run_cmd "sudo dnf remove -y firefox* libreoffice*"
rm -rf ~/.mozilla ~/.cache/mozilla ~/.config/libreoffice ~/.cache/libreoffice

# ffmpeg non-free
phase "🎞️ Switching to non-free ffmpeg"
run_cmd "sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing"

# System Upgrade & Tools
phase "⬆️ System Upgrade & CLI Tools"
run_cmd "sudo dnf upgrade -y"
run_cmd "sudo dnf install -y yt-dlp aria2"

# ==========================================================
# PHASE 2: OPTIONAL SOFTWARE
# ==========================================================
phase "Phase 2: Optional Software"

# Chrome
if [[ "$chrome_choice" =~ ^[Yy]$ ]]; then
    if ! command -v google-chrome &>/dev/null; then
        run_cmd "sudo dnf install -y google-chrome-stable"
    else echo -e "${GREEN}✅ Chrome already installed.${RESET}"; fi
fi

# Brave
if [[ "$brave_choice" =~ ^[Yy]$ ]]; then
    if ! command -v brave-browser &>/dev/null; then
        run_cmd "curl -fsS https://dl.brave.com/install.sh | sh"
    else echo -e "${GREEN}✅ Brave already installed.${RESET}"; fi
fi

# virt-manager
if [[ "$virt_choice" =~ ^[Yy]$ ]]; then
    if ! command -v virt-manager &>/dev/null; then
        phase "📦 Installing virt-manager + enabling libvirtd"
        run_cmd "sudo dnf group install -y 'Virtualization'"
        run_cmd "sudo systemctl enable --now libvirtd"
    else echo -e "${GREEN}✅ virt-manager already installed.${RESET}"; fi
fi

# WARP CLI
if ! command -v warp-cli &>/dev/null; then
    phase "☁️ Installing Cloudflare WARP CLI"
    run_cmd "sudo dnf install -y cloudflare-warp"
else echo -e "${GREEN}✅ WARP CLI already installed.${RESET}"; fi

# ==========================================================
# PHASE 3: CLEANUP
# ==========================================================
phase "Phase 3: Cleanup & Final Touches"

# fstrim
run_cmd "sudo systemctl enable --now fstrim.timer"

# Cleanup
run_cmd "sudo dnf autoremove -y"
run_cmd "sudo dnf clean all"

# Optional Flatpak cleanup
# run_cmd "flatpak uninstall --unused -y"
# run_cmd "flatpak repair"

echo -e "${GREEN}🎉 All done! Fedora is clean, optimized, and ready to roll.${RESET}"
