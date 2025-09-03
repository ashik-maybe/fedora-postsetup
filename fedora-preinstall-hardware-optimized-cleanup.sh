#!/bin/bash

# Fedora Pre-Installation Optimizations for HP EliteBook 840 G3
# Run this BEFORE fedora-postinstall.sh

set -euo pipefail

echo "Fedora Pre-Installation Optimizations"
echo "===================================="
echo "This script removes unnecessary packages and repositories"
echo

# Configuration
run_repo_cleanup=false
run_package_removal=false
run_gpu_cleanup=false
run_dnf_cleanup=false

# Questions
echo "1. Repository Cleanup (PyCharm COPR, NVIDIA drivers, Cisco H264)"
read -p "Remove unnecessary repositories? (y/N): " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && run_repo_cleanup=true
echo

echo "2. Package Removal (Firefox, LibreOffice, GNOME Boxes)"
read -p "Remove unnecessary packages? (y/N): " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && run_package_removal=true
echo

echo "3. GPU Firmware Cleanup (AMD/NVIDIA - SKIP if you have dedicated GPU)"
read -p "Remove GPU firmware? (y/N): " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && run_gpu_cleanup=true
echo

echo "4. DNF Cache Cleanup"
read -p "Clean DNF cache? (y/N): " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && run_dnf_cleanup=true
echo

# Summary
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
read -p "Proceed with selected actions? (y/N): " -n 1 -r
echo
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
    cd /etc/yum.repos.d/

    repos_to_remove=(
        "_copr:copr.fedorainfracloud.org:phracek:PyCharm.repo"
        "rpmfusion-nonfree-nvidia-driver.repo"
        "rpmfusion-nonfree-steam.repo"
        "fedora-cisco-openh264.repo"
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
    )

    for pkg in "${packages_to_remove[@]}"; do
        echo "Removing $pkg"
        sudo dnf remove -y "$pkg" || echo "Failed to remove $pkg (may not be installed)"
    done

    echo "Package removal completed"
    echo
fi

# GPU firmware cleanup
if [[ $run_gpu_cleanup == true ]]; then
    echo "Removing discrete GPU firmware..."

    gpu_firmware=(
        "amd-gpu-firmware"
        "nvidia-gpu-firmware"
    )

    for firmware in "${gpu_firmware[@]}"; do
        echo "Removing $firmware"
        sudo dnf remove -y "$firmware" || echo "Failed to remove $firmware (may not be installed)"
    done

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
