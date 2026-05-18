#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🎵 Starting EasyEffects Premium Audio Setup..."

# 0. Quick sanity check for Git dependency
if ! command -v git &> /dev/null; then
    echo "❌ Error: 'git' is not installed. Please install it first." >&2
    exit 1
fi

# 1. Install EasyEffects via Flatpak if it isn't already installed
if ! flatpak list | grep -q "com.github.wwmm.easyeffects"; then
    echo "📦 EasyEffects not found. Installing from Flathub..."
    flatpak install flathub com.github.wwmm.easyeffects -y
else
    echo "✅ EasyEffects is already installed."
fi

# 2. Define the target Flatpak configuration directories
TARGET_DIR="$HOME/.var/app/com.github.wwmm.easyeffects/config/easyeffects"
OUTPUT_DIR="$TARGET_DIR/output"
IRS_DIR="$TARGET_DIR/irs"

echo "📂 Creating necessary directory structures..."
mkdir -p "$OUTPUT_DIR" "$IRS_DIR"

# 3. Setup temporary workspace
TMP_DIR=$(mktemp -d -t easyeffects-build-XXXXXX)
echo "📂 Created temporary workspace at $TMP_DIR"

# Ensure cleanup happens even if the script fails midway
trap 'rm -rf "$TMP_DIR"; echo "🧹 Cleaned up temporary files."' EXIT

# 4. Clone the community presets repo
echo "📥 Cloning JackHack96 EasyEffects Presets repository..."
git clone --depth 1 https://github.com/JackHack96/EasyEffects-Presets.git "$TMP_DIR/presets"

# 5. Copy the preset JSON configuration files (Safe wildcard execution)
echo "⚙️ Deploying tuning preset files..."
cp "$TMP_DIR"/presets/*.json "$OUTPUT_DIR/"

# 6. Copy the Impulse Response (IRS) files (Cleaner directory copying)
echo "🔊 Deploying Impulse Response acoustic profiles..."
if [ -d "$TMP_DIR/presets/irs" ]; then
    cp -R "$TMP_DIR/presets/irs" "$TARGET_DIR/"
fi

echo "✨ All presets successfully installed to your Flatpak profile!"
echo "🚀 Launching the EasyEffects background service..."

# 7. Quit old instances and launch daemon silently in background without blocking terminal
# flatpak run com.github.wwmm.easyeffects -q || true
# flatpak run com.github.wwmm.easyeffects --gapplication-service &> /dev/null &

echo "🎉 Setup complete! Open EasyEffects, go to Presets, and load 'Advanced Auto Gain'."
