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
# Check if a repository exists in /etc/yum.repos.d/
# ------------------------

repo_exists() {
    local repo_name="$1"
    if [ -f "/etc/yum.repos.d/$repo_name.repo" ]; then
        return 0  # Repo exists
    else
        return 1  # Repo doesn't exist
    fi
}

# ------------------------
# Ask Yes/No Question
# ------------------------

ask_yes_no() {
    local question="$1"
    while true; do
        echo -e "${YELLOW}$question (y/n): ${RESET}"
        read -r response
        case "$response" in
            [Yy]* ) return 0 ;;  # User answered "yes"
            [Nn]* ) return 1 ;;  # User answered "no"
            * ) echo -e "${RED}Please answer 'y' for yes or 'n' for no.${RESET}" ;;
        esac
    done
}

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
# Optimize dnf.conf if not already optimized
# ------------------------

optimize_dnf_conf() {
    if ! grep -q "max_parallel_downloads=10" /etc/dnf/dnf.conf; then
        echo -e "${GREEN}Optimizing dnf.conf...${RESET}"
        sudo bash -c 'cat > /etc/dnf/dnf.conf << EOF
[main]
gpgcheck=True
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
max_parallel_downloads=10
fastestmirror=True
color=auto
EOF'
        echo -e "${GREEN}Optimized dnf.conf.${RESET}"
    else
        echo -e "${YELLOW}dnf.conf is already optimized. Skipping.${RESET}"
    fi
}

# ------------------------
# Ensure Flatpak and Flathub are installed
# ------------------------

ensure_flatpak_support() {
    echo -e "${GREEN}Ensuring Flatpak and Flathub support...${RESET}"

    # Install Flatpak if not already installed
    if ! command -v flatpak &> /dev/null; then
        echo -e "${YELLOW}Flatpak is not installed. Installing Flatpak...${RESET}"
        run_cmd "sudo dnf install -y flatpak"
    fi

    # Add Flathub repository if not already added
    if ! flatpak remotes | grep -q "flathub"; then
        echo -e "${YELLOW}Adding Flathub repository...${RESET}"
        run_cmd "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
    else
        echo -e "${YELLOW}Flathub repository already added. Skipping.${RESET}"
    fi

    echo -e "${GREEN}Flatpak and Flathub support ensured.${RESET}"
}

# ------------------------
# Add third-party repositories if not already added
# ------------------------

add_third_party_repos() {
    # Check if RPM Fusion Free and Non-Free are installed
    if ! repo_exists "rpmfusion-free" && ! repo_exists "rpmfusion-nonfree"; then
        echo -e "${GREEN}Adding third-party repositories...${RESET}"

        run_cmd "sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

        # Cloudflare Warp Repo
        if ! repo_exists "cloudflare-warp"; then
            run_cmd "curl -fsSl https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | sudo tee /etc/yum.repos.d/cloudflare-warp.repo"
        fi

        # GitHub Desktop Repo
        if ! repo_exists "mwt-packages"; then
            run_cmd "sudo rpm --import https://mirror.mwt.me/shiftkey-desktop/gpgkey"
            run_cmd "sudo sh -c 'echo -e \"[mwt-packages]\nname=GitHub Desktop\nbaseurl=https://mirror.mwt.me/shiftkey-desktop/rpm\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://mirror.mwt.me/shiftkey-desktop/gpgkey\" > /etc/yum.repos.d/mwt-packages.repo'"
        fi

        # Visual Studio Code Repo
        if ! repo_exists "vscode"; then
            run_cmd "sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc"
            run_cmd "echo -e \"[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null"
        fi

        echo -e "${GREEN}Third-party repositories added.${RESET}"
    else
        echo -e "${YELLOW}Repositories are already added. Skipping.${RESET}"
    fi
}

# ------------------------
# Remove Firefox and LibreOffice if needed
# ------------------------

remove_firefox_and_libreoffice() {
    if ask_yes_no "Do you want to remove Firefox and LibreOffice?"; then
        echo -e "${GREEN}Removing Firefox and LibreOffice...${RESET}"
        run_cmd "sudo dnf remove -y firefox* libreoffice*"
        run_cmd "rm -rf ~/.mozilla ~/.cache/mozilla ~/.config/libreoffice ~/.cache/libreoffice"
        run_cmd "sudo dnf autoremove"
        echo -e "${GREEN}Removed packages and leftover configs.${RESET}"
    else
        echo -e "${YELLOW}Skipping Firefox and LibreOffice removal.${RESET}"
    fi
}

# ------------------------
# Replace FFmpeg with the proprietary version
# ------------------------

replace_ffmpeg_with_proprietary() {
    echo -e "${GREEN}Replacing FFmpeg with proprietary version...${RESET}"
    run_cmd "sudo dnf swap ffmpeg-free ffmpeg --allowerasing"
    echo -e "${GREEN}Proprietary FFmpeg installed.${RESET}"
}

# ------------------------
# Install yt-dlp and aria2c
# ------------------------

install_yt_dlp_and_aria2c() {
    echo -e "${GREEN}Installing yt-dlp and aria2c...${RESET}"
    run_cmd "sudo dnf install -y yt-dlp aria2"
    echo -e "${GREEN}yt-dlp and aria2c installed.${RESET}"
}

# ------------------------
# Install GNOME Tweaks and Extension Manager
# ------------------------

install_gnome_tweaks_and_extension_manager() {
    # Check if the current DE is GNOME
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        echo -e "${GREEN}Installing GNOME Tweaks and Extension Manager...${RESET}"

        # Install GNOME Tweaks via DNF
        run_cmd "sudo dnf install -y gnome-tweaks"

        # Install Extension Manager via Flatpak
        run_cmd "flatpak install -y flathub com.mattjakeman.ExtensionManager"

        echo -e "${GREEN}GNOME Tweaks and Extension Manager installed.${RESET}"
    else
        echo -e "${YELLOW}Not running GNOME desktop environment. Skipping GNOME Tweaks and Extension Manager installation.${RESET}"
    fi
}

# ------------------------
# Install Browsers
# ------------------------

install_browsers() {
    echo -e "${GREEN}Installing browsers (Google Chrome, Brave)...${RESET}"
    run_cmd "sudo dnf install -y google-chrome-stable"
    run_cmd "curl -fsS https://dl.brave.com/install.sh | sh"
}

# ------------------------
# Install Cloudflare Warp CLI
# ------------------------

install_cloudflare_warp() {
    echo -e "${GREEN}Installing Cloudflare WARP CLI...${RESET}"
    run_cmd "sudo dnf install -y cloudflare-warp"

    echo -e "${CYAN}+++ Cloudflare Warp Initial Connection +++${RESET}"
    echo -e "${YELLOW}
Initial Connection
To connect for the very first time:

  Register the client:    warp-cli registration new
  Connect:                warp-cli connect
  Verify:                 curl https://www.cloudflare.com/cdn-cgi/trace/ (look for warp=on)

Switching modes:
  DNS only mode via DoH:  warp-cli mode doh
  WARP with DoH:          warp-cli mode warp+doh
${RESET}"
}

# ------------------------
# Install All Apps Suite
# ------------------------

install_apps_suite() {
    install_development_tools
    install_browsers
    install_cloudflare_warp
}

# ------------------------
# Install virt-manager and enable systemd services
# ------------------------

install_virt_manager() {
    echo -e "${GREEN}Installing virt-manager and enabling systemd services...${RESET}"

    # Install virt-manager and dependencies
    run_cmd "sudo dnf install -y @virtualization"

    # Enable the necessary system services
    run_cmd "sudo systemctl start libvirtd"
    run_cmd "sudo systemctl enable libvirtd"

    echo -e "${GREEN}virt-manager installed and services enabled.${RESET}"
}

# ------------------------
# Main Execution
# ------------------------

clear
echo -e "${CYAN}Fedora Post-Install Script Starting...${RESET}"
optimize_dnf_conf
ensure_flatpak_support  # Ensure Flatpak and Flathub are installed first
add_third_party_repos
remove_firefox_and_libreoffice
replace_ffmpeg_with_proprietary  # Replace FFmpeg with proprietary version
upgrade_system_packages
install_yt_dlp_and_aria2c
install_gnome_tweaks_and_extension_manager  # Install GNOME Tweaks and Extension Manager
install_apps_suite
install_virt_manager
echo -e "${CYAN}Script completed.${RESET}"
