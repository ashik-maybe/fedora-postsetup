#!/bin/bash

# Fedora Pre-Installation Optimizations
# Run this BEFORE fedora-postinstall.sh

set -euo pipefail

echo "Fedora Pre-Installation Optimizations"
echo "===================================="
echo "This script removes unnecessary packages and repositories"
echo

# Configuration flags
run_repo_cleanup=false
run_package_removal=false
run_gpu_cleanup=false
run_dnf_cleanup=false

# Questions
echo "1. Repository Cleanup (PyCharm COPR, NVIDIA drivers, Cisco H264)"
read -p "Remove unnecessary repositories? (y/N): " -n 1 -r; echo
[[ $REPLY =~ ^[Yy]$ ]] && run_repo_cleanup=true

echo "2. Package Removal (Firefox, LibreOffice, GNOME Boxes, Extras)"
read -p "Remove unnecessary packages? (y/N): " -n 1 -r; echo
[[ $REPLY =~ ^[Yy]$ ]] && run_package_removal=true

echo "3. GPU Firmware Cleanup (Auto-detect GPUs)"
read -p "Remove unnecessary GPU firmware? (y/N): " -n 1 -r; echo
[[ $REPLY =~ ^[Yy]$ ]] && run_gpu_cleanup=true

echo "4. DNF Cache Cleanup"
read -p "Clean DNF cache? (y/N): " -n 1 -r; echo
[[ $REPLY =~ ^[Yy]$ ]] && run_dnf_cleanup=true

# Summary
echo
echo "Selected actions:"
echo "Repositories: $([[ $run_repo_cleanup == true ]] && echo "YES" || echo "NO")"
echo "Packages: $([[ $run_package_removal == true ]] && echo "YES" || echo "NO")"
echo "GPU firmware: $([[ $run_gpu_cleanup == true ]] && echo "YES" || echo "NO")"
echo "DNF cache: $([[ $run_dnf_cleanup == true ]] && echo "YES" || echo "NO")"
echo

# Exit if nothing selected
if [[ $run_repo_cleanup == false && $run_package_removal == false && $run_gpu_cleanup == false && $run_dnf_cleanup == false ]]; then
    echo "No actions selected. Exiting."
    exit 0
fi

# Confirmation
read -p "Proceed with selected actions? (y/N): " -n 1 -r; echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo
echo "Starting optimizations..."
echo

# Repository cleanup
if [[ $run_repo_cleanup == true ]]; then
    echo "Removing unnecessary repositories..."
    cd /etc/yum.repos.d/ || exit 1

    repos_to_remove=(
        "_copr:copr.fedorainfracloud.org:phracek:PyCharm.repo"
        "rpmfusion-nonfree-nvidia-driver.repo"
        "rpmfusion-nonfree-steam.repo"
        "fedora-cisco-openh264.repo"
        "google-chrome.repo"
    )

    for repo in "${repos_to_remove[@]}"; do
        if [ -f "$repo" ]; then
            echo "Removing $repo"
            sudo rm "$repo"
        else
            echo "$repo not found (skipping)"
        fi
    done

    echo "Repository cleanup completed"
    echo
fi

# Package removal
if [[ $run_package_removal == true ]]; then
    echo "Removing unnecessary packages..."

    packages_to_remove=(
        "firefox*"
        "libreoffice-*"
        "gnome-boxes"
        "gnome-contacts"
        "gnome-maps"
        "gnome-weather"
        "evolution"
        "rhythmbox"
        "totem"
        "gnome-characters"
        "gnome-calendar"
        "mediawriter"
        "simple-scan"
        "gnome-connections"
        "gnome-backgrounds"
        "gnome-tour"
        "baobab"
    )

    for pkg in "${packages_to_remove[@]}"; do
        echo "Removing $pkg"
        sudo dnf remove -y "$pkg" || echo "Failed to remove $pkg (may not be installed)"
    done

    echo "Package removal completed"
    echo
fi

# GPU firmware cleanup (auto-detect)
if [[ $run_gpu_cleanup == true ]]; then
    echo "Checking installed GPUs..."
    GPU_INFO=$(lspci | /usr/bin/grep -E "VGA|3D" | tr '[:upper:]' '[:lower:]')

    if echo "$GPU_INFO" | grep -q "nvidia"; then
        echo "NVIDIA GPU detected. Removing AMD firmware..."
        sudo dnf remove -y amd-gpu-firmware || echo "AMD firmware not installed"
    elif echo "$GPU_INFO" | grep -q "amd"; then
        echo "AMD GPU detected. Removing NVIDIA firmware..."
        sudo dnf remove -y nvidia-gpu-firmware || echo "NVIDIA firmware not installed"
    else
        echo "No dedicated AMD/NVIDIA GPU detected (Intel iGPU detected)."
        echo "Removing both AMD and NVIDIA firmware..."
        sudo dnf remove -y amd-gpu-firmware nvidia-gpu-firmware || echo "Firmware not installed"
    fi

    echo "GPU firmware cleanup completed"
    echo
fi

# DNF cache cleanup
if [[ $run_dnf_cleanup == true ]]; then
    echo "Cleaning DNF cache..."
    sudo dnf clean all
    echo "DNF cache cleanup completed"
    echo
fi

echo "Pre-installation optimizations completed!"
echo "You can now run fedora-postinstall.sh"
