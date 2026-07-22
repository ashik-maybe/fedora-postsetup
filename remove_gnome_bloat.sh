#!/usr/bin/env bash

set -euo pipefail

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
    rhythmbox                  # Legacy Audio Player
    showtime                   # Video Player (Fedora 44 default)
    simple-scan                # Document Scanner
    snapshot                   # Camera App
    yelp                       # Help Viewer
)

echo "================================================="
echo " Safe GNOME & Bloat Removal Tool for Fedora 44"
echo "================================================="
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

echo "Cleaning up orphaned dependencies..."
sudo dnf autoremove -y

echo "Done! Unwanted apps removed safely."
