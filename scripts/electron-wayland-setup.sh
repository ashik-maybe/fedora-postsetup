#!/usr/bin/env bash

CONFIG_DIR="$HOME/.config"
FLAGS_FILE="$CONFIG_DIR/electron-flags.conf"
PROFILE_FILE="$HOME/.profile"
ENV_LINE='export ELECTRON_OZONE_PLATFORM_HINT=auto'

enable_wayland_support() {
    echo "Enabling Electron Wayland support..."

    mkdir -p "$CONFIG_DIR"

    cat > "$FLAGS_FILE" <<EOF
--enable-features=WaylandWindowDecorations
--ozone-platform-hint=auto
--enable-features=WebRTCPipeWireCapturer
EOF
    echo "✔ Created $FLAGS_FILE"

    if ! grep -Fxq "$ENV_LINE" "$PROFILE_FILE"; then
        echo "$ENV_LINE" >> "$PROFILE_FILE"
        echo "✔ Appended environment variable to $PROFILE_FILE"
    else
        echo "ℹ Environment variable already present in $PROFILE_FILE"
    fi

    echo "✅ Wayland support for Electron apps is now enabled (you may need to reboot or re-login)."
}

disable_wayland_support() {
    echo "Disabling Electron Wayland support..."

    if [ -f "$FLAGS_FILE" ]; then
        rm "$FLAGS_FILE"
        echo "✔ Removed $FLAGS_FILE"
    else
        echo "ℹ $FLAGS_FILE does not exist"
    fi

    if grep -Fxq "$ENV_LINE" "$PROFILE_FILE"; then
        sed -i "\|$ENV_LINE|d" "$PROFILE_FILE"
        echo "✔ Removed environment variable from $PROFILE_FILE"
    else
        echo "ℹ Environment variable not found in $PROFILE_FILE"
    fi

    echo "❌ Wayland support for Electron apps has been disabled (you may need to reboot or re-login)."
}

show_menu() {
    echo "Choose an action:"
    echo "1) Enable Electron Wayland support"
    echo "2) Disable Electron Wayland support (revert)"
    echo "3) Quit"
    read -rp "Enter your choice [1-3]: " choice

    case "$choice" in
        1) enable_wayland_support ;;
        2) disable_wayland_support ;;
        *) echo "Bye!" ;;
    esac
}

show_menu
