#!/bin/bash

CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

error_handler() {
    echo -e "${RED}Error: $1${RESET}"
}

run_cmd() {
    local cmd="$1"
    echo -e "${CYAN}Running: $cmd${RESET}"
    eval "$cmd" || error_handler "Command failed: $cmd"
}

ask_yes_no() {
    local question="$1"
    while true; do
        echo -e "${YELLOW}$question (y/n): ${RESET}"
        read -r response
        case "$response" in
            [Yy]* ) return 0 ;;
            [Nn]* ) return 1 ;;
            * ) echo -e "${RED}Please answer 'y' or 'n'.${RESET}" ;;
        esac
    done
}

repo_exists() {
    grep -q "\[$1\]" /etc/yum.repos.d/*.repo && return 0 || return 1
}

optimize_dnf_conf() {
    if ! grep -q "max_parallel_downloads=10" /etc/dnf/dnf.conf; then
        run_cmd "sudo bash -c 'cat > /etc/dnf/dnf.conf << EOF
[main]
gpgcheck=True
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
max_parallel_downloads=10
fastestmirror=True
color=auto
EOF'"
    fi
}

ensure_flatpak_support() {
    if ! command -v flatpak &> /dev/null; then
        run_cmd "sudo dnf install -y flatpak"
    fi
    if ! flatpak remotes | grep -q "flathub"; then
        run_cmd "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
    fi
}

enable_fstrim() {
    if ! systemctl is-enabled fstrim.timer &> /dev/null; then
        run_cmd "sudo systemctl enable --now fstrim.timer"
    fi
}

add_third_party_repos() {
    if ! repo_exists "rpmfusion-free" && ! repo_exists "rpmfusion-nonfree"; then
        run_cmd "sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
    fi

    if ! repo_exists "cloudflare-warp"; then
        run_cmd "curl -fsSl https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | sudo tee /etc/yum.repos.d/cloudflare-warp.repo"
    fi

    if ! repo_exists "google-chrome"; then
        run_cmd "sudo sh -c 'echo -e \"[google-chrome]
name=Google Chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub\" > /etc/yum.repos.d/google-chrome.repo'"
    fi
}

remove_firefox_and_libreoffice() {
    run_cmd "sudo dnf remove -y firefox* libreoffice*"
    run_cmd "rm -rf ~/.mozilla ~/.cache/mozilla ~/.config/libreoffice ~/.cache/libreoffice"
}

replace_ffmpeg_with_proprietary() {
    run_cmd "sudo dnf swap ffmpeg-free ffmpeg --allowerasing"
}

install_yt_dlp_and_aria2c() {
    run_cmd "sudo dnf install -y yt-dlp aria2"
}

install_browsers() {
    run_cmd "sudo dnf install -y google-chrome-stable"
    run_cmd "curl -fsS https://dl.brave.com/install.sh | sh"
}

install_cloudflare_warp() {
    if ask_yes_no "Install Cloudflare WARP CLI?"; then
        run_cmd "sudo dnf install -y cloudflare-warp"
        echo -e "${YELLOW}
To connect:
  Register: warp-cli registration new
  Connect:  warp-cli connect
  Verify:   curl https://www.cloudflare.com/cdn-cgi/trace/ (look for warp=on)
Switch modes:
  DNS only: warp-cli mode doh
  WARP+DoH: warp-cli mode warp+doh
${RESET}"
    fi
}

install_gnome_tweaks_and_extension_manager() {
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        if ask_yes_no "Install GNOME Tweaks and Extension Manager?"; then
            run_cmd "sudo dnf install -y gnome-tweaks"
            run_cmd "flatpak install -y flathub com.mattjakeman.ExtensionManager"
        fi
    fi
}

install_virt_manager() {
    if ask_yes_no "Install virt-manager and enable virtualization?"; then
        run_cmd "sudo dnf install -y @virtualization"
        run_cmd "sudo systemctl enable --now libvirtd"
    fi
}

post_install_cleanup() {
    run_cmd "sudo dnf autoremove -y"
    run_cmd "sudo dnf clean all"
    if command -v flatpak &> /dev/null; then
        run_cmd "flatpak uninstall --unused -y"
        run_cmd "flatpak repair"
    fi
}

clear
echo -e "${CYAN}Fedora Post-Install Script Starting...${RESET}"
sudo -v || { echo -e "${RED}Failed to acquire sudo privileges. Exiting.${RESET}"; exit 1; }

optimize_dnf_conf
ensure_flatpak_support
add_third_party_repos
remove_firefox_and_libreoffice
replace_ffmpeg_with_proprietary
run_cmd "sudo dnf upgrade -y"
install_yt_dlp_and_aria2c
install_browsers
install_cloudflare_warp
install_gnome_tweaks_and_extension_manager
install_virt_manager
enable_fstrim
post_install_cleanup

echo -e "${CYAN}Script completed.${RESET}"
