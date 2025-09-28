#!/bin/bash

# Usage:
# ./wayland-desktop-overrides.sh          -> Detects installed browsers, offers to patch them for Wayland.
# ./wayland-desktop-overrides.sh --undo  -> Removes patched .desktop files.
# ./wayland-desktop-overrides.sh --remove -> Same as --undo.

# Chromium-based browser .desktop filenames (RPM versions)
BROWSERS=(
    "brave-browser.desktop"
    "google-chrome.desktop"
    "google-chrome-unstable.desktop"
    "microsoft-edge.desktop"
    "microsoft-edge-dev.desktop"
    "opera.desktop"
    "vivaldi-stable.desktop"
    "ungoogled-chromium.desktop"
    "chromium.desktop"
    "yandex-browser.desktop"
)

SOURCE_DIR="/usr/share/applications"
DEST_DIR="$HOME/.local/share/applications"
mkdir -p "$DEST_DIR"

# List installed .desktop files for supported browsers
list_installed_browsers() {
    INSTALLED_BROWSERS=()
    for BROWSER in "${BROWSERS[@]}"; do
        if [[ -f "$SOURCE_DIR/$BROWSER" ]]; then
            INSTALLED_BROWSERS+=("$BROWSER")
        fi
    done
}

# Patch for Wayland support
patch_wayland() {
    for BROWSER in "${INSTALLED_BROWSERS[@]}"; do
        SRC="$SOURCE_DIR/$BROWSER"
        DEST="$DEST_DIR/$BROWSER"
        cp "$SRC" "$DEST"
        sed -i '/^Exec=/s|$| --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=TouchpadOverscrollHistoryNavigation|' "$DEST"
        chmod +x "$DEST"
        echo -e "\033[32m✔ Patched for Wayland: $DEST\033[0m"
    done
}

# Remove patched .desktop files
remove_patched() {
    list_installed_browsers
    for BROWSER in "${INSTALLED_BROWSERS[@]}"; do
        DEST="$DEST_DIR/$BROWSER"
        if [[ -f "$DEST" ]]; then
            rm -f "$DEST"
            echo -e "\033[31m✘ Removed override: $DEST\033[0m"
        fi
    done
    echo -e "\033[32m✔ All patched .desktop overrides removed.\033[0m"
    exit 0
}

# Handle undo/remove
if [[ "$1" == "--undo" || "$1" == "--remove" ]]; then
    echo -e "\033[34m→ Reversing Wayland patches...\033[0m"
    remove_patched
fi

# Default patching flow
list_installed_browsers
if [[ ${#INSTALLED_BROWSERS[@]} -eq 0 ]]; then
    echo -e "\033[31mNo supported Chromium-based browsers found in $SOURCE_DIR.\033[0m"
    exit 1
fi

echo -e "\033[34mThe following RPM-installed browsers were found:\033[0m"
for B in "${INSTALLED_BROWSERS[@]}"; do echo -e "\033[34m - $B\033[0m"; done
echo -n -e "\033[33mWould you like to patch them for Wayland support? (y/n): \033[0m"
read -r CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo -e "\033[31mAborted.\033[0m"; exit 0; }

patch_wayland
echo -e "\033[32m✅ Done. Please log out and back in to apply changes.\033[0m"
