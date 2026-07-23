#!/bin/bash

set -euo pipefail

REPO_PATH="/etc/yum.repos.d/google-chrome.repo"
RPM_TMP="/tmp/google-chrome-stable_current_x86_64.rpm"
RPM_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"

# 1. Check if Chrome is already installed
if command -v google-chrome &>/dev/null; then
  echo "google-chrome is already installed."
  exit 0
fi

# 2. Prompt for confirmation
read -r -p "Google Chrome is not installed. Proceed with downloading and installing the RPM? (y/n): " CONFIRM

if [[ "${CONFIRM,,}" != "y" ]]; then
  echo "Installation aborted."
  exit 1
fi

# 3. Clean up any existing repo file
if [[ -f "$REPO_PATH" ]]; then
  echo "Removing existing repository file at $REPO_PATH..."
  sudo rm -f "$REPO_PATH"
fi

# 4. Download RPM to /tmp
echo "Downloading Chrome RPM to /tmp..."
curl -fsSL "$RPM_URL" -o "$RPM_TMP"

# 5. Install the RPM package (dnf handles dependencies and GPG setup)
echo "Installing google-chrome-stable..."
sudo dnf install -y "$RPM_TMP"

# 6. Clean up temporary RPM file
rm -f "$RPM_TMP"

echo "Installation complete!"
