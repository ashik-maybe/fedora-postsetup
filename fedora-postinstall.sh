#!/usr/bin/env bash

set -euo pipefail

# Helper functions
run_cmd() {
    echo "Executing: $1"
    eval "$1"
}

repo_exists() {
    grep -q "\[$1\]" /etc/yum.repos.d/*.repo &>/dev/null
}

# 1. Optimize DNF configuration
optimize_dnf_conf() {
    echo "Optimizing DNF configuration..."
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
    echo "DNF configuration optimized successfully."
}

# 2. Add third-party repositories (RPM Fusion)
add_third_party_repos() {
    echo "Adding RPM Fusion repositories..."

    if ! repo_exists "rpmfusion-free" || ! repo_exists "rpmfusion-nonfree"; then
        run_cmd "sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
    else
        echo "RPM Fusion repositories already present."
    fi
}

# 3. Remove Firefox
remove_firefox() {
    echo "Removing Firefox..."
    run_cmd "sudo dnf remove -y firefox"
    echo "Firefox removed successfully."
}

# 4. Remove LibreOffice
remove_libreoffice() {
    echo "Removing LibreOffice..."
    run_cmd "sudo dnf remove -y libreoffice-*"
    echo "LibreOffice removed successfully."
}

# 5. Swap ffmpeg-free with proprietary ffmpeg
swap_ffmpeg_with_proprietary() {
    echo "Swapping ffmpeg-free with proprietary ffmpeg..."
    run_cmd "sudo dnf swap ffmpeg-free ffmpeg --allowerasing -y"
    echo "Proprietary ffmpeg installed successfully."
}

# 6. System upgrade
upgrade_system() {
    echo "Upgrading system packages..."
    run_cmd "sudo dnf upgrade -y"
    echo "System upgrade completed."
}

# 7. Install yt-dlp and aria2
install_yt_dlp_and_aria2c() {
    echo "Installing yt-dlp and aria2..."
    run_cmd "sudo dnf install -y yt-dlp aria2"
    echo "yt-dlp and aria2 installed successfully."
}

# 8. Enable fstrim.timer for SSD optimization
enable_fstrim() {
    echo "Enabling fstrim.timer for SSD optimization..."
    if ! systemctl is-enabled fstrim.timer &>/dev/null; then
        run_cmd "sudo systemctl enable --now fstrim.timer"
    else
        echo "fstrim.timer is already enabled."
    fi
}

# 9. Post-installation cleanup
post_install_cleanup() {
    echo "Performing post-installation cleanup..."
    run_cmd "sudo dnf autoremove -y"
    if command -v flatpak &>/dev/null; then
        run_cmd "flatpak uninstall --unused -y"
    fi
    echo "Post-installation cleanup completed."
}

# Main execution
clear
echo "Fedora Core Post-Installation Setup"
echo "=================================="
echo "This script will configure your Fedora system with optimal settings."
echo

# Check for sudo privileges
sudo -v || { echo "Error: Sudo privileges required. Exiting."; exit 1; }

# Keep sudo alive during execution
( while true; do sudo -n true; sleep 60; done ) 2>/dev/null &
KEEP_SUDO_PID=$!
trap 'kill $KEEP_SUDO_PID' EXIT

# Execute all configuration steps
optimize_dnf_conf
add_third_party_repos
remove_firefox
remove_libreoffice
swap_ffmpeg_with_proprietary
upgrade_system
install_yt_dlp_and_aria2c
enable_fstrim
post_install_cleanup

echo
echo "Fedora core setup completed successfully."
echo "You can now run additional modular configuration scripts as needed."
