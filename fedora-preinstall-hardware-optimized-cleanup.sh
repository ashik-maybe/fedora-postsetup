#!/bin/bash

# pre-install-optimizations.sh - Optimizes Fedora installation for HP EliteBook 840 G3
# Run this BEFORE fedora-postinstall.sh

set -euo pipefail

echo "🔧 Pre-installation optimizations for HP EliteBook 840 G3"
echo "====================================================="
echo "This script will perform several optimization steps"
echo "Answer all questions first, then all selected steps will run automatically"
echo

# Arrays to track user choices
run_repo_cleanup=false
run_package_removal=false
run_gpu_cleanup=false
run_dnf_cleanup=false

# Question 1: Repository cleanup
echo "📋 Step 1: Repository Cleanup"
echo "Removes unnecessary repositories like PyCharm COPR, NVIDIA drivers, Cisco H264, etc."
read -p "Do you want to run repository cleanup? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    run_repo_cleanup=true
fi
echo

# Question 2: Package removal
echo "📋 Step 2: Package Removal"
echo "Removes Firefox, LibreOffice, GNOME Boxes, and other bloatware"
read -p "Do you want to remove unnecessary packages? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    run_package_removal=true
fi
echo

# Question 3: GPU firmware cleanup
echo "📋 Step 3: GPU Firmware Cleanup"
echo "Removes AMD/NVIDIA GPU firmware (SKIP if you have dedicated GPU)"
read -p "Do you want to remove GPU firmware? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    run_gpu_cleanup=true
fi
echo

# Question 4: DNF cache cleanup
echo "📋 Step 4: DNF Cache Cleanup"
echo "Cleans DNF cache to save space and ensure fresh metadata"
read -p "Do you want to clean DNF cache? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    run_dnf_cleanup=true
fi
echo

# Summary of choices
echo "📋 Your choices:"
echo "Repository cleanup: $([[ $run_repo_cleanup == true ]] && echo "YES" || echo "NO")"
echo "Package removal: $([[ $run_package_removal == true ]] && echo "YES" || echo "NO")"
echo "GPU firmware cleanup: $([[ $run_gpu_cleanup == true ]] && echo "YES" || echo "NO")"
echo "DNF cache cleanup: $([[ $run_dnf_cleanup == true ]] && echo "YES" || echo "NO")"
echo

# Final confirmation
if [[ $run_repo_cleanup == false && $run_package_removal == false && $run_gpu_cleanup == false && $run_dnf_cleanup == false ]]; then
    echo "❌ No steps selected. Exiting."
    exit 0
fi

read -p "Proceed with selected steps? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborted by user"
    exit 1
fi

echo
echo "🚀 Starting optimizations..."
echo

# Execute selected steps
# Step 1: Repository cleanup
if [[ $run_repo_cleanup == true ]]; then
    echo "🗑️  Removing unnecessary repositories..."
    cd /etc/yum.repos.d/

    repos_to_remove=(
        "_copr:copr.fedorainfracloud.org:phracek:PyCharm.repo"
        "rpmfusion-nonfree-nvidia-driver.repo"
        "rpmfusion-nonfree-steam.repo"
        "fedora-cisco-openh264.repo"
    )

    for repo in "${repos_to_remove[@]}"; do
        if [ -f "$repo" ]; then
            echo "Removing $repo..."
            sudo rm "$repo"
        else
            echo "⚠️  $repo not found (skipping)"
        fi
    done

    echo "✅ Repository cleanup completed"
    echo
fi

# Step 2: Package removal
if [[ $run_package_removal == true ]]; then
    echo "🗑️  Removing unnecessary packages..."

    packages_to_remove=(
        "firefox*"
        "libreoffice-*"
        "gnome-boxes"
    )

    for pkg in "${packages_to_remove[@]}"; do
        echo "Removing $pkg..."
        sudo dnf remove -y "$pkg" || echo "⚠️  Failed to remove $pkg (may not be installed)"
    done

    echo "✅ Package removal completed"
    echo
fi

# Step 3: GPU firmware cleanup
if [[ $run_gpu_cleanup == true ]]; then
    echo "🗑️  Removing discrete GPU firmware..."

    gpu_firmware=(
        "amd-gpu-firmware"
        "nvidia-gpu-firmware"
    )

    for firmware in "${gpu_firmware[@]}"; do
        echo "Removing $firmware..."
        sudo dnf remove -y "$firmware" || echo "⚠️  Failed to remove $firmware (may not be installed)"
    done

    echo "✅ GPU firmware cleanup completed"
    echo
fi

# Step 4: DNF cache cleanup
if [[ $run_dnf_cleanup == true ]]; then
    echo "🧹 Cleaning DNF cache..."
    sudo dnf clean all
    echo "✅ DNF cache cleanup completed"
    echo
fi

echo "🎉 Pre-installation optimizations completed!"
echo "You can now run fedora-postinstall.sh"
