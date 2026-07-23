#!/bin/bash

set -euo pipefail

REPO_PATH="/etc/yum.repos.d/google-chrome.repo"

# 1. Check if Google Chrome is already installed
if command -v google-chrome &>/dev/null; then
  echo "Google Chrome is already installed."
  exit 0
fi

# 2. Prompt user for confirmation
read -r -p "Google Chrome is not installed. Would you like to install it now? (y/n): " CONFIRM

if [[ "${CONFIRM,,}" != "y" ]]; then
  echo "Installation aborted."
  exit 1
fi

# 3. Add the Google Chrome repository if it doesn't exist
if [[ ! -f "$REPO_PATH" ]]; then
  echo "Adding Google Chrome repository..."
  cat <<EOF | sudo tee "$REPO_PATH" >/dev/null
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
fi

# 4. Install Google Chrome using DNF
echo "Installing Google Chrome..."
sudo dnf install google-chrome-stable -y

echo "Installation complete!"
