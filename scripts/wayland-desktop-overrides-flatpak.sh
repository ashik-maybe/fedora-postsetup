#!/bin/bash

# Usage guide:
# ./wayland-desktop-overrides-flatpak.sh   -> Detects supported browsers, asks to patch them for Wayland.
# ./wayland-desktop-overrides-flatpak.sh --undo   -> Removes patched .desktop files (undo patch).
# ./wayland-desktop-overrides-flatpak.sh --remove   -> Alias for --undo, removes patched .desktop files.

#####
# BrowseRating
# https://www.browserating.com/
# Browser Performance Ranking for macOS/Windows/Android
#####

# List of Chromium-based browsers
BROWSERS=(
    "com.brave.Browser"
    "com.google.Chrome"
    "com.google.ChromeDev"
    "com.microsoft.Edge"
    "com.microsoft.EdgeDev"
    "com.opera.Opera"
    "com.vivaldi.Vivaldi"
    "io.github.ungoogled_software.ungoogled_chromium"
    "org.chromium.Chromium"
    "ru.yandex.Browser"
)

DEST_DIR="$HOME/.local/share/applications"
mkdir -p "$DEST_DIR"

# Function to list installed browsers
list_installed_browsers() {
    INSTALLED_BROWSERS=()
    for BROWSER in "${BROWSERS[@]}"; do
        if [ -f "/var/lib/flatpak/exports/share/applications/$BROWSER.desktop" ]; then
            INSTALLED_BROWSERS+=("$BROWSER")
        fi
    done
}

# Function to apply Wayland patch to the browsers
patch_wayland() {
    for BROWSER in "${INSTALLED_BROWSERS[@]}"; do
        SRC="/var/lib/flatpak/exports/share/applications/$BROWSER.desktop"
        DEST="$DEST_DIR/$BROWSER.desktop"
        cp "$SRC" "$DEST"
        sed -i '/^Exec=/s|$| --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=TouchpadOverscrollHistoryNavigation|' "$DEST"
        chmod +x "$DEST"
        echo -e "\033[32m✔ Patched $BROWSER for Wayland: $DEST\033[0m"
    done
}

# Function to remove patched .desktop files
remove_patched() {
    list_installed_browsers
    for BROWSER in "${INSTALLED_BROWSERS[@]}"; do
        DEST="$DEST_DIR/$BROWSER.desktop"
        if [ -f "$DEST" ]; then
            rm "$DEST"
            echo -e "\033[31m✘ Removed: $DEST\033[0m"
        fi
    done
    echo -e "\033[32m✔ All patched .desktop files removed.\033[0m"
    exit 0
}

# Handle undo flag
if [[ "$1" == "--undo" || "$1" == "--remove" ]]; then
    echo -e "\033[34m→ Reversing Wayland patch for Chromium-based Flatpak browsers...\033[0m"
    remove_patched
fi

# Default flow: patch
list_installed_browsers
if [ ${#INSTALLED_BROWSERS[@]} -eq 0 ]; then
    echo -e "\033[31mNo supported Chromium-based browsers found.\033[0m"
    exit 1
fi

echo -e "\033[34mThe following browsers were found:\033[0m"
for B in "${INSTALLED_BROWSERS[@]}"; do echo -e "\033[34m - $B\033[0m"; done
echo -n -e "\033[33mWould you like to patch them for Wayland support? (y/n): \033[0m"
read -r CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo -e "\033[31mAborted.\033[0m"; exit 0; }

patch_wayland

# Colorful exit message
echo -e "\033[32m✅ Done. Please log out and back in to apply changes.\033[0m"
