#!/usr/bin/env bash

set -euo pipefail

# 🎨 Colors
CYAN="\033[0;36m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# 🛠️ Helpers
run_cmd() {
    echo -e "${CYAN}🔧 Running: $1${RESET}"
    eval "$1"
}

repo_exists() {
    grep -q "\[$1\]" /etc/yum.repos.d/*.repo &>/dev/null
}

# ⚙️ 1. Optimize DNF
optimize_dnf_conf() {
    echo -e "${YELLOW}⚙️ Optimizing DNF configuration...${RESET}"
    sudo tee /etc/dnf/dnf.conf > /dev/null <<EOF
[main]
gpgcheck=True
installonly_limit=3
clean_requirements_on_remove=True
fastestmirror=True
max_parallel_downloads=10
timeout=15
retries=2
skip_if_unavailable=True
best=True
keepcache=False
color=auto
errorlevel=1
EOF
    echo -e "${GREEN}✅ DNF optimized.${RESET}"
}

# 🌐 2. Add third-party repos (RPM Fusion)
add_third_party_repos() {
    echo -e "${YELLOW}🌐 Adding RPM Fusion repositories...${RESET}"

    if ! repo_exists "rpmfusion-free" || ! repo_exists "rpmfusion-nonfree"; then
        run_cmd "sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-\$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-\$(rpm -E %fedora).noarch.rpm"
    else
        echo -e "${GREEN}✅ RPM Fusion already present.${RESET}"
    fi
}

# 🧹 3. Remove Firefox
remove_firefox() {
    echo -e "${YELLOW}🧹 Removing Firefox...${RESET}"
    run_cmd "sudo dnf remove -y firefox"
    echo -e "${GREEN}✅ Firefox removed.${RESET}"
}

# 🎞️ 4. Swap ffmpeg-free with proprietary ffmpeg
swap_ffmpeg_with_proprietary() {
    echo -e "${YELLOW}🎞️ Swapping ffmpeg-free with proprietary ffmpeg...${RESET}"
    run_cmd "sudo dnf swap ffmpeg-free ffmpeg --allowerasing -y"
    echo -e "${GREEN}✅ Proprietary ffmpeg installed.${RESET}"
}

# ⬆️ 5. System upgrade
upgrade_system() {
    echo -e "${YELLOW}⬆️ Upgrading system...${RESET}"
    run_cmd "sudo dnf upgrade -y"
    echo -e "${GREEN}✅ System upgraded.${RESET}"
}

# 🎬 6. Install yt-dlp + aria2
install_yt_dlp_and_aria2c() {
    echo -e "${YELLOW}🎬 Installing yt-dlp and aria2...${RESET}"
    run_cmd "sudo dnf install -y yt-dlp aria2"
    echo -e "${GREEN}✅ yt-dlp and aria2 ready.${RESET}"
}

# 🧊 7. Enable fstrim.timer
enable_fstrim() {
    echo -e "${YELLOW}🧊 Enabling fstrim.timer...${RESET}"
    if ! systemctl is-enabled fstrim.timer &>/dev/null; then
        run_cmd "sudo systemctl enable --now fstrim.timer"
    else
        echo -e "${GREEN}✅ fstrim.timer already enabled.${RESET}"
    fi
}

# 🧼 8. Clean system
post_install_cleanup() {
    echo -e "${YELLOW}🧼 Final cleanup...${RESET}"
    run_cmd "sudo dnf autoremove -y"
    if command -v flatpak &>/dev/null; then
        run_cmd "flatpak uninstall --unused -y"
    fi
    echo -e "${GREEN}✅ All clean.${RESET}"
}

# ▶️ Run All Core Steps

clear
echo -e "${CYAN}🚀 Starting Fedora core post-install setup...${RESET}"
sudo -v || { echo -e "${RED}❌ Sudo required. Exiting.${RESET}"; exit 1; }

# Keep sudo alive
( while true; do sudo -n true; sleep 60; done ) 2>/dev/null &
KEEP_SUDO_PID=$!
trap 'kill $KEEP_SUDO_PID' EXIT

optimize_dnf_conf
add_third_party_repos
remove_firefox
swap_ffmpeg_with_proprietary
upgrade_system
install_yt_dlp_and_aria2c
enable_fstrim
post_install_cleanup

echo -e "${GREEN}🎉 Core Fedora setup complete. Run modular scripts as needed!${RESET}"
