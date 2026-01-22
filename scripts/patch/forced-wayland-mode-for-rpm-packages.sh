#!/bin/bash

# Supported filenames
BROWSERS=(
    "brave-browser.desktop" "com.brave.Browser.desktop"
    "google-chrome.desktop" "com.google.Chrome.desktop"
    "microsoft-edge.desktop" "chromium.desktop"
)

SOURCE_DIR="/usr/share/applications"
DEST_DIR="$HOME/.local/share/applications"
FLAGS="--enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=TouchpadOverscrollHistoryNavigation"

mkdir -p "$DEST_DIR"

# Handle Undo
if [[ "$1" == "--undo" || "$1" == "--remove" ]]; then
    for B in "${BROWSERS[@]}"; do
        [ -f "$DEST_DIR/$B" ] && rm -f "$DEST_DIR/$B" && echo -e "\033[31m✘ Removed: $B\033[0m"
    done
    exit 0
fi

# Patch Logic
for B in "${BROWSERS[@]}"; do
    if [[ -f "$SOURCE_DIR/$B" ]]; then
        cp "$SOURCE_DIR/$B" "$DEST_DIR/$B"
        # Wipe old manual flags to prevent duplication, then add fresh ones
        sed -i "s| --enable-features=.*||g" "$DEST_DIR/$B"
        sed -i "/^Exec=/s|$| $FLAGS|" "$DEST_DIR/$B"
        echo -e "\033[32m✔ Patched: $B\033[0m"
    fi
done

echo -e "\033[34mDone. Restart your browser or log out/in to apply.\033[0m"
