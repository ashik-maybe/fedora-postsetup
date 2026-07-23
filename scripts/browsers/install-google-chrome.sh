#!/bin/bash

set -euo pipefail

REPO_PATH="/etc/yum.repos.d/google-chrome.repo"

# 1. Check if Chrome is already installed
if command -v google-chrome &>/dev/null; then
  echo "google-chrome is already installed."
  exit 0
fi

# 2. Prompt for confirmation
read -r -p "Google Chrome is not installed. Proceed with fresh repo setup and installation? (y/n): " CONFIRM

if [[ "${CONFIRM,,}" != "y" ]]; then
  echo "Installation aborted."
  exit 1
fi

# 3. Delete existing chrome repo file if present
if [[ -f "$REPO_PATH" ]]; then
  echo "Removing existing repository file at $REPO_PATH..."
  sudo rm -f "$REPO_PATH"
fi

# 4. Add Google's official repo configuration directly
echo "Adding Google's official Chrome repository..."
cat <<EOF | sudo tee "$REPO_PATH" >/dev/null
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

# 5. Import GPG signing key & install Chrome
echo "Importing Google GPG signing key..."
sudo rpm --import https://dl.google.com/linux/linux_signing_key.pub

echo "Installing google-chrome-stable..."
sudo dnf install google-chrome-stable -y

echo "Installation complete!"
