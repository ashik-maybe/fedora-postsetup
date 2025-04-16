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

# Error handler
error_handler() {
    echo -e "${RED}❌ Error: $1${RESET}"
}

# Helper: run command with feedback
run_cmd() {
    local cmd="$1"
    echo -e "${CYAN}🔧 Running: $cmd${RESET}"
    eval "$cmd" || error_handler "Command failed: $cmd"
}

# Helper: check if repo exists
repo_exists() {
    grep -q "\[$1\]" /etc/yum.repos.d/*.repo &>/dev/null
}

# Check if the current DE is GNOME
is_gnome() {
    [ "$(echo $XDG_CURRENT_DESKTOP)" = "GNOME" ]
}

# === Essentials ===
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

    if ! flatpak list | grep -q com.github.tchx84.Flatseal; then
        echo -e "${YELLOW}🔒 Installing Flatseal...${RESET}"
        run_cmd "flatpak install -y flathub com.github.tchx84.Flatseal"
    else
        echo -e "${GREEN}✅ Flatseal already installed.${RESET}"
    fi
}

# === Optional Installations ===
install_browsers() {
    echo -e "${YELLOW}🌐 Checking browsers...${RESET}"
    if ! command -v google-chrome &>/dev/null; then
        read -p "🧭 Install Google Chrome? (y/n): " chrome_choice
        if [[ "$chrome_choice" =~ ^[Yy]$ ]]; then
            run_cmd "sudo dnf install -y google-chrome-stable"
            echo -e "${GREEN}✅ Google Chrome installed.${RESET}"
        else
            echo -e "${CYAN}⏭️ Skipping Chrome installation.${RESET}"
        fi
    else
        echo -e "${GREEN}✅ Google Chrome already installed.${RESET}"
    fi

    if ! command -v brave-browser &>/dev/null; then
        read -p "🧭 Install Brave Browser? (y/n): " brave_choice
        if [[ "$brave_choice" =~ ^[Yy]$ ]]; then
            run_cmd "curl -fsS https://dl.brave.com/install.sh | sh"
            echo -e "${GREEN}✅ Brave Browser installed.${RESET}"
        else
            echo -e "${CYAN}⏭️ Skipping Brave Browser installation.${RESET}"
        fi
    else
        echo -e "${GREEN}✅ Brave Browser already installed.${RESET}"
    fi
}

install_yt_dlp_and_aria2c() {
    echo -e "${YELLOW}🎥 Installing yt-dlp and aria2...${RESET}"
    run_cmd "sudo dnf install -y yt-dlp aria2"
    echo -e "${GREEN}✅ yt-dlp and aria2 installed.${RESET}"
}

install_virt_manager() {
    echo -e "${YELLOW}⚙️ Installing Virt-Manager and Virtualization tools...${RESET}"

    if ! command -v virt-manager &>/dev/null; then
        read -p "🧭 Install virt-manager and enable virtualization? (y/n): " virt_choice
        if [[ "$virt_choice" =~ ^[Yy]$ ]]; then
            run_cmd "sudo dnf install -y @virtualization"
            run_cmd "sudo systemctl enable --now libvirtd"
            run_cmd "sudo systemctl start libvirtd"  # Ensure the service is started
            echo -e "${GREEN}✅ Virt-Manager and virtualization setup complete.${RESET}"
        else
            echo -e "${CYAN}⏭️ Skipping Virt-Manager installation.${RESET}"
        fi
    else
        echo -e "${GREEN}✅ Virt-Manager already installed.${RESET}"
    fi
}

# === GNOME Customization ===
install_gnome_customization_tools() {
    if is_gnome; then
        read -p "🧭 Install GNOME Tweaks and Extensions Manager for customization? (y/n): " gnome_choice
        if [[ "$gnome_choice" =~ ^[Yy]$ ]]; then
            run_cmd "sudo dnf install -y gnome-tweaks"
            run_cmd "flatpak install flathub com.mattjakeman.ExtensionManager -y"
            echo -e "${GREEN}✅ GNOME Tweaks and Extension Manager installed.${RESET}"
        else
            echo -e "${CYAN}⏭️ Skipping GNOME customization tools installation.${RESET}"
        fi
    fi
}

# === Cleanup ===
post_install_cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up...${RESET}"
    run_cmd "sudo dnf autoremove -y"
    # run_cmd "sudo dnf clean all"
    if command -v flatpak &>/dev/null; then
        run_cmd "flatpak uninstall --unused -y"
        # run_cmd "flatpak repair"
    fi
    echo -e "${GREEN}✅ System cleaned.${RESET}"
}

# ==== Execute All Steps ====
optimize_dnf_conf
ensure_flatpak_support
install_browsers
install_yt_dlp_and_aria2c
install_virt_manager
install_gnome_customization_tools
post_install_cleanup

echo -e "${GREEN}🎉 All done! Fedora is ready to roll!${RESET}"
