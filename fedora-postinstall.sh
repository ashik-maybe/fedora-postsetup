#!/bin/bash
# fedora-postinstall.sh — Clean and complete Fedora post-install script

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
# ⚙️ 1. Optimize DNF
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
    echo -e "${GREEN}✅ DNF optimized.${RESET}"
}

# ──────────────────────────────────────────────────────────────
# 🌐 2. Add third-party repos (RPM Fusion)
add_third_party_repos() {
    echo -e "${YELLOW}🌐 Adding RPM Fusion repositories...${RESET}"

    if ! repo_exists "rpmfusion-free" || ! repo_exists "rpmfusion-nonfree"; then
        run_cmd "sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-\$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-\$(rpm -E %fedora).noarch.rpm"
    else
        echo -e "${GREEN}✅ RPM Fusion already present.${RESET}"
    fi
}

# ──────────────────────────────────────────────────────────────
# 🧹 3. Remove Firefox and LibreOffice
remove_firefox_and_libreoffice() {
    echo -e "${YELLOW}🧹 Removing Firefox and LibreOffice...${RESET}"
    run_cmd "sudo dnf remove -y firefox* libreoffice*"
    run_cmd "rm -rf ~/.mozilla ~/.cache/mozilla ~/.config/libreoffice ~/.cache/libreoffice"
    echo -e "${GREEN}✅ Cleanup complete.${RESET}"
}

# ──────────────────────────────────────────────────────────────
# 🎞️ 4. Remove ffmpeg-free
remove_ffmpeg_free() {
    echo -e "${YELLOW}🎞️ Removing ffmpeg-free...${RESET}"
    run_cmd "sudo dnf remove -y ffmpeg-free"
    echo -e "${GREEN}✅ ffmpeg-free removed.${RESET}"
}

# ──────────────────────────────────────────────────────────────
# ⬆️ 5. System upgrade
upgrade_system() {
    echo -e "${YELLOW}⬆️ Upgrading system...${RESET}"
    run_cmd "sudo dnf upgrade -y"
    echo -e "${GREEN}✅ System upgraded.${RESET}"
}

# ──────────────────────────────────────────────────────────────
# 🎞️ 6. Install ffmpeg (proprietary)
install_proprietary_ffmpeg() {
    echo -e "${YELLOW}🎞️ Installing proprietary ffmpeg...${RESET}"
    run_cmd "sudo dnf install -y ffmpeg"
    echo -e "${GREEN}✅ ffmpeg installed.${RESET}"
}

# ──────────────────────────────────────────────────────────────
# 📦 7. Flatpak + Flatseal
ensure_flatpak_support() {
    echo -e "${YELLOW}📦 Setting up Flatpak & Flatseal...${RESET}"

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

    if ! flatpak list | grep -q com.github.tchx84.Flatseal; then
        run_cmd "flatpak install -y flathub com.github.tchx84.Flatseal"
    else
        echo -e "${GREEN}✅ Flatseal already installed.${RESET}"
    fi
}

# ──────────────────────────────────────────────────────────────
# 🎬 8. Install yt-dlp + aria2
install_yt_dlp_and_aria2c() {
    echo -e "${YELLOW}🎬 Installing yt-dlp and aria2...${RESET}"
    run_cmd "sudo dnf install -y yt-dlp aria2"
    echo -e "${GREEN}✅ yt-dlp and aria2 ready.${RESET}"
}

# ──────────────────────────────────────────────────────────────
# 🦁 9. Install Brave browser
install_brave_browser() {
    echo -e "${YELLOW}🦁 Installing Brave Browser...${RESET}"
    if ! command -v brave-browser &>/dev/null; then
        run_cmd "curl -fsS https://dl.brave.com/install.sh | sh"
    else
        echo -e "${GREEN}✅ Brave is already installed.${RESET}"
    fi
}

# ──────────────────────────────────────────────────────────────
# 🧊 10. Enable fstrim.timer
enable_fstrim() {
    echo -e "${YELLOW}🧊 Enabling fstrim.timer...${RESET}"
    if ! systemctl is-enabled fstrim.timer &>/dev/null; then
        run_cmd "sudo systemctl enable --now fstrim.timer"
    else
        echo -e "${GREEN}✅ fstrim.timer already enabled.${RESET}"
    fi
}

# ──────────────────────────────────────────────────────────────
# 🧼 11. Clean system
post_install_cleanup() {
    echo -e "${YELLOW}🧼 Final cleanup...${RESET}"
    run_cmd "sudo dnf autoremove -y"
    run_cmd "sudo dnf clean all"
    if command -v flatpak &>/dev/null; then
        run_cmd "flatpak uninstall --unused -y"
        run_cmd "flatpak repair"
    fi
    echo -e "${GREEN}✅ All clean.${RESET}"
}

# ──────────────────────────────────────────────────────────────
# ▶️ Run All Steps

clear
echo -e "${CYAN}🚀 Starting Fedora post-install setup...${RESET}"
sudo -v || { echo -e "${RED}❌ Sudo required. Exiting.${RESET}"; exit 1; }

# Keep sudo alive
( while true; do sudo -n true; sleep 60; done ) 2>/dev/null &
KEEP_SUDO_PID=$!
trap 'kill $KEEP_SUDO_PID' EXIT

optimize_dnf_conf
add_third_party_repos
remove_firefox_and_libreoffice
remove_ffmpeg_free
upgrade_system
install_proprietary_ffmpeg
ensure_flatpak_support
install_yt_dlp_and_aria2c
install_brave_browser
enable_fstrim
post_install_cleanup

echo -e "${GREEN}🎉 Done! Your Fedora setup is complete.${RESET}"
