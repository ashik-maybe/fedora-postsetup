#!/usr/bin/env bash

set -e

REPO_FILE="/etc/yum.repos.d/vscodium.repo"

# 1. Check and create the repo file
if [ ! -f "$REPO_FILE" ]; then
    echo "👉 Creating VSCodium repository file..."
    sudo tee "$REPO_FILE" > /dev/null <<EOF
[gitlab.com_paulcarroty_vscodium_repo]
name=gitlab.com_paulcarroty_vscodium_repo
baseurl=https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/rpms/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg
metadata_expire=1h
EOF
    sudo chmod 644 "$REPO_FILE"
    echo "✅ Repository file created."
else
    echo "✅ VSCodium repository file already exists."
fi

# 2. Check if vscodium is installed, if not install it
if ! rpm -q codium &> /dev/null; then
    echo "👉 Installing VSCodium..."
    sudo dnf install -y codium
    echo "✅ VSCodium installed."
else
    echo "✅ VSCodium is already installed."
fi

echo "🎉 All done! You can now launch VSCodium."
