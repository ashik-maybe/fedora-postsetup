#!/bin/bash

# Exit on error
set -euo pipefail

# Ensure the script is run as root (or via sudo)
if [[ $EUID -ne 0 ]]; then
  echo "❌ This script must be run as root (use: sudo ./install-podman.sh)" >&2
  exit 1
fi

echo "🔹 Updating system packages..."
dnf update -y

echo "🔹 Installing Podman and Podman Compose..."
dnf install -y podman podman-compose

echo "✅ Podman and Podman Compose installed successfully."
echo "💡 Use 'podman --version' and 'podman-compose --version' to verify."
