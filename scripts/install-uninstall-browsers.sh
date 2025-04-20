#!/bin/bash

# Usage:
# Run this script to install or uninstall Flatpak browsers.
# You'll be shown available browsers to install and installed ones to uninstall.
# Select using space-separated numbers (e.g., 1 3 7), or 'q' to quit.

# Browser Categories
CHROMIUM_BROWSERS=(
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

FIREFOX_BROWSERS=(
    "app.zen_browser.zen"
    "net.mullvad.MullvadBrowser"
    "one.ablaze.floorp"
    "org.mozilla.firefox"
    "io.gitlab.librewolf-community"
)

SPECIAL_BROWSERS=(
    "org.torproject.torbrowser-launcher"
)

ALL_BROWSERS=("${CHROMIUM_BROWSERS[@]}" "${FIREFOX_BROWSERS[@]}" "${SPECIAL_BROWSERS[@]}")

# Check installed Flatpak apps
is_installed() {
    flatpak info "$1" &>/dev/null
}

# Categorized maps
declare -A INSTALLABLE
declare -A REMOVABLE
declare -A ID_MAP
counter=1

# Build maps for display
echo "───────────────"
echo "📥 CAN BE INSTALLED:"
echo "───────────────"
for b in "${CHROMIUM_BROWSERS[@]}"; do
    if ! is_installed "$b"; then
        echo "$counter. [Chromium] $b"
        INSTALLABLE[$counter]="$b"
        ID_MAP[$counter]="install"
        ((counter++))
    fi
done
for b in "${FIREFOX_BROWSERS[@]}"; do
    if ! is_installed "$b"; then
        echo "$counter. [Firefox]  $b"
        INSTALLABLE[$counter]="$b"
        ID_MAP[$counter]="install"
        ((counter++))
    fi
done
for b in "${SPECIAL_BROWSERS[@]}"; do
    if ! is_installed "$b"; then
        echo "$counter. [Special]  $b"
        INSTALLABLE[$counter]="$b"
        ID_MAP[$counter]="install"
        ((counter++))
    fi
done

echo
echo "───────────────"
echo "🗑️ CAN BE UNINSTALLED:"
echo "───────────────"
for b in "${ALL_BROWSERS[@]}"; do
    if is_installed "$b"; then
        echo "$counter. [Installed] $b"
        REMOVABLE[$counter]="$b"
        ID_MAP[$counter]="uninstall"
        ((counter++))
    fi
done

echo
echo "💡 Enter number(s) to act, separated by spaces (e.g., 1 3 10), or 'q' to quit"
read -rp "Your choice: " INPUT

[[ "$INPUT" == "q" || "$INPUT" == "Q" ]] && echo "Aborted." && exit

for i in $INPUT; do
    action="${ID_MAP[$i]}"
    app="${INSTALLABLE[$i]:-${REMOVABLE[$i]}}"

    if [[ "$action" == "install" && -n "$app" ]]; then
        echo "➕ Installing $app..."
        flatpak install -y flathub "$app"

    elif [[ "$action" == "uninstall" && -n "$app" ]]; then
        echo "➖ Uninstalling $app..."
        flatpak uninstall --delete-data -y "$app"

        # Remove leftover .desktop file from local applications
        desktop_file="$HOME/.local/share/applications/$app.desktop"
        if [[ -f "$desktop_file" ]]; then
            rm -f "$desktop_file"
            echo "🧹 Removed leftover desktop file: $desktop_file"
        fi
    else
        echo "⚠️ Invalid option: $i"
    fi
done

