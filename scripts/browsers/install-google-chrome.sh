#!/bin/bash

set -euo pipefail

CHROME_INSTALLED=0
REPO_EXISTS=0
REPO_PATH="/etc/yum.repos.d/google-chrome.repo"

if command -v google-chrome &>/dev/null; then
  CHROME_INSTALLED=1
fi

if [[ -f "$REPO_PATH" ]]; then
  REPO_EXISTS=1
fi

if [[ $CHROME_INSTALLED -eq 1 ]]; then
  echo "google-chrome is already installed."
  exit 0
fi

NEED_REPO=0
if [[ $REPO_EXISTS -eq 0 ]]; then
  NEED_REPO=1
fi

read -r -p "google-chrome is not installed.$([[ $NEED_REPO -eq 1 ]] && echo " google-chrome.repo is missing.") Install now? (y/n): " CONFIRM

if [[ "$CONFIRM" != "y" ]]; then
  echo "Installation aborted."
  exit 1
fi

if [[ $NEED_REPO -eq 1 ]]; then
  sudo install -m 644 /dev/null "$REPO_PATH"
  cat <<EOF | sudo tee "$REPO_PATH" >/dev/null
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
fi

sudo dnf install google-chrome-stable -y
