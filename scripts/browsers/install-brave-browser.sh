#!/bin/bash

set -euo pipefail

BRAVE_INSTALLED=0
REPO_EXISTS=0
REPO_PATH="/etc/yum.repos.d/brave-browser.repo"

if command -v brave-browser &>/dev/null; then
  BRAVE_INSTALLED=1
fi

if [[ -f "$REPO_PATH" ]]; then
  REPO_EXISTS=1
fi

if [[ $BRAVE_INSTALLED -eq 1 ]]; then
  echo "brave-browser is already installed."
  exit 0
fi

NEED_REPO=0
if [[ $REPO_EXISTS -eq 0 ]]; then
  NEED_REPO=1
fi

read -r -p "brave-browser is not installed.$([[ $NEED_REPO -eq 1 ]] && echo " brave-browser.repo is missing.") Install now? (y/n): " CONFIRM

if [[ "$CONFIRM" != "y" ]]; then
  echo "Installation aborted."
  exit 1
fi

if [[ $NEED_REPO -eq 1 ]]; then
  sudo install -m 644 /dev/null "$REPO_PATH"
  cat <<EOF | sudo tee "$REPO_PATH" >/dev/null
[brave-browser]
name=Brave Browser
enabled=1
gpgcheck=1
gpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
baseurl=https://brave-browser-rpm-release.s3.brave.com/\$basearch
EOF
fi

sudo dnf install brave-browser -y
