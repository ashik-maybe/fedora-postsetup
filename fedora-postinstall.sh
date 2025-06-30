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

# ✅ Speed up mirror selection and downloads
fastestmirror=True
max_parallel_downloads=10
timeout=15
retries=2
skip_if_unavailable=True

# ✅ Use latest *stable* packages
best=True
#deltarpm=True

# ✅ Script/automation-friendly behavior
#defaultyes=True
keepcache=False

# ✅ Cleaner output
color=auto
errorlevel=1
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
# 🧹 3. Remove Firefox
remove_firefox() {
    echo -e "${YELLOW}🧹 Removing Firefox...${RESET}"
    run_cmd "sudo dnf remove -y firefox"
    echo -e "${GREEN}✅ Cleanup complete.${RESET}"
}

# ──────────────────────────────────────────────────────────────
# 🎞️ 4. Swap ffmpeg-free with proprietary ffmpeg
swap_ffmpeg_with_proprietary() {
    echo -e "${YELLOW}🎞️ Swapping ffmpeg-free with proprietary ffmpeg...${RESET}"
    run_cmd "sudo dnf swap ffmpeg-free ffmpeg --allowerasing -y"
    echo -e "${GREEN}✅ Proprietary ffmpeg installed.${RESET}"
}

# ──────────────────────────────────────────────────────────────
# ⬆️ 5. System upgrade
upgrade_system() {
    echo -e "${YELLOW}⬆️ Upgrading system...${RESET}"
    run_cmd "sudo dnf upgrade -y"
    echo -e "${GREEN}✅ System upgraded.${RESET}"
}

# ──────────────────────────────────────────────────────────────
# 📦 6. Flatpak + Flatseal
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
# 🧰 7. Install Gear Lever (AppImage Manager)
install_gear_lever() {
    echo -e "${YELLOW}🧰 Installing Gear Lever (AppImage Manager)...${RESET}"
    if ! flatpak list | grep -q it.mijorus.gearlever; then
        run_cmd "flatpak install -y flathub it.mijorus.gearlever"
    else
        echo -e "${GREEN}✅ Gear Lever is already installed.${RESET}"
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
# 🌍 9. Browser Setup:
#  - Blink (Chromium-based): Brave, Chrome, Edge, Vivaldi, Opera
#  - Gecko (Firefox-based): LibreWolf

# 🦁 Brave Browser
install_brave_browser() {
    echo -e "${YELLOW}🦁 Installing Brave Browser...${RESET}"
    if command -v brave-browser &>/dev/null; then
        echo -e "${GREEN}✅ Brave is already installed.${RESET}"
        return
    fi
    run_cmd "curl -fsS https://dl.brave.com/install.sh | sh"
}

# 🌐 Google Chrome
install_chrome_browser() {
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

# 🪟 Microsoft Edge
install_edge_browser() {
    echo -e "${YELLOW}🪟 Installing Microsoft Edge...${RESET}"
    if command -v microsoft-edge &>/dev/null; then
        echo -e "${GREEN}✅ Microsoft Edge is already installed.${RESET}"
        return
    fi
    if ! repo_exists "microsoft-edge"; then
        sudo tee /etc/yum.repos.d/microsoft-edge.repo > /dev/null <<EOF
[microsoft-edge]
name=microsoft-edge
baseurl=https://packages.microsoft.com/yumrepos/edge/
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    fi
    run_cmd "sudo dnf install -y microsoft-edge-stable"
}

# 🧭 Vivaldi Browser
install_vivaldi_browser() {
    echo -e "${YELLOW}🧭 Installing Vivaldi Browser...${RESET}"
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

# 🦉 Opera Browser
install_opera_browser() {
    echo -e "${YELLOW}🦉 Installing Opera Browser...${RESET}"
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

# 🐺 LibreWolf Browser
install_librewolf_browser() {
    echo -e "${YELLOW}🐺 Installing LibreWolf (Native RPM)...${RESET}"
    if command -v librewolf &>/dev/null; then
        echo -e "${GREEN}✅ LibreWolf is already installed.${RESET}"
        return
    fi
    if ! repo_exists "librewolf"; then
        echo -e "${CYAN}🔧 Adding LibreWolf repository...${RESET}"
        curl -fsSL https://repo.librewolf.net/librewolf.repo | pkexec tee /etc/yum.repos.d/librewolf.repo > /dev/null
    fi
    run_cmd "sudo dnf install -y librewolf"
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
    if command -v flatpak &>/dev/null; then
        run_cmd "flatpak uninstall --unused -y"
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
remove_firefox
swap_ffmpeg_with_proprietary
upgrade_system
ensure_flatpak_support
install_gear_lever
install_brave_browser
# install_chrome_browser
# install_edge_browser
# install_vivaldi_browser
# install_opera_browser
# install_librewolf_browser
install_yt_dlp_and_aria2c
install_brave_browser
enable_fstrim
post_install_cleanup

echo -e "${GREEN}🎉 Done! Your Fedora setup is complete.${RESET}"
