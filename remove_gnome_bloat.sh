#!/usr/bin/env bash

set -euo pipefail

echo "================================================="
echo " Safe GNOME Bloat Removal Tool"
echo "================================================="

# List of safe-to-remove apps and bloatware
PACKAGES_TO_REMOVE=(
    baobab                     # Disk Usage Analyzer
    decibels                   # Audio Previewer / Player
    evince                     # Legacy Document Viewer
    firefox                    # Firefox RPM
    gnome-boxes                # Virtual Machines
    gnome-calculator           # Calculator
    gnome-calendar             # Calendar
    gnome-characters           # Characters
    gnome-clocks               # Clocks
    gnome-connections          # Connections
    gnome-contacts             # Contacts
    gnome-disk-utility         # Disks
    gnome-font-viewer          # Fonts
    gnome-logs                 # Logs
    gnome-maps                 # Maps
    gnome-music                # Audio Player
    gnome-software             # GNOME Software Store
    gnome-tour                 # Tour
    gnome-weather              # Weather
    PackageKit                 # PackageKit Service (Not needed for CLI updates)
    PackageKit-glib            # PackageKit GLib library
    rhythmbox                  # Legacy Audio Player
    showtime                   # Video Player
    simple-scan                # Document Scanner
    snapshot                   # Camera App
    yelp                       # Help Viewer
    mediawriter                # Fedora Media Writer
)

echo "The following packages will be uninstalled:"
printf ' - %s\n' "${PACKAGES_TO_REMOVE[@]}"
echo "-------------------------------------------------"

# Prompt for confirmation
read -p "Do you want to proceed with removal? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation canceled."
    exit 0
fi

echo "Removing selected packages..."
sudo dnf remove -y "${PACKAGES_TO_REMOVE[@]}"

echo "Cleaning up orphaned dependencies..."
sudo dnf autoremove -y

echo "Cleaning up leftover caches..."
rm -rf ~/.cache/gnome-software
sudo rm -rf /var/cache/PackageKit

echo "================================================="
echo " Done! All unwanted apps and services removed."
echo "================================================="
