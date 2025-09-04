#!/bin/bash

# docker installer script - Install Docker Engine OR Docker Desktop on Fedora
# Choose one: CLI-only (Engine) or full GUI (Desktop)

set -euo pipefail

echo "Docker Installation for Fedora"
echo "=============================="
echo "This script lets you install either:"
echo "  1. Docker Engine (CLI-only, runs natively)"
echo "  2. Docker Desktop (GUI + VM-based, includes Engine, Compose, Scout, etc.)"
echo
echo "⚠️  Note: Commercial use in companies with >250 employees or >$10M revenue"
echo "    requires a paid Docker subscription."
echo

# Check if running on supported Fedora version
FEDORA_VERSION=$(rpm -E %fedora)
if [[ ! "$FEDORA_VERSION" =~ ^(41|42)$ ]]; then
    echo "⚠️  Warning: This script is tested on Fedora 41/42"
    echo "    You are running Fedora $FEDORA_VERSION"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Ask user for installation type
echo "Choose installation type:"
echo "1) Docker Engine (CLI-only, lightweight)"
echo "2) Docker Desktop (GUI + VM, full dev environment)"
read -p "Enter choice (1 or 2): " INSTALL_CHOICE
echo

case $INSTALL_CHOICE in
    1)
        INSTALL_ENGINE=true
        INSTALL_DESKTOP=false
        ;;
    2)
        INSTALL_ENGINE=false
        INSTALL_DESKTOP=true
        ;;
    *)
        echo "Invalid choice. Aborting."
        exit 1
        ;;
esac

# Confirmation
if [[ "$INSTALL_ENGINE" == true ]]; then
    read -p "Install Docker Engine? (y/N): " -n 1 -r
else
    read -p "Install Docker Desktop? (y/N): " -n 1 -r
fi
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo "Starting installation..."
echo

# Ensure no conflicting services are running
if systemctl --user is-active docker-desktop &>/dev/null; then
    echo "⚠️  Stopping existing Docker Desktop..."
    systemctl --user stop docker-desktop
fi

if systemctl is-active docker &>/dev/null; then
    echo "⚠️  Stopping existing Docker Engine..."
    sudo systemctl stop docker
fi


# -------------------------------
# INSTALL DOCKER ENGINE (CLI-only)
# -------------------------------
if [[ "$INSTALL_ENGINE" == true ]]; then

    echo "🔧 Installing Docker Engine..."
    echo

    # Remove old versions
    echo "Removing old Docker packages..."
    sudo dnf remove -y docker \
                      docker-client \
                      docker-client-latest \
                      docker-common \
                      docker-latest \
                      docker-latest-logrotate \
                      docker-logrotate \
                      docker-selinux \
                      docker-engine-selinux \
                      docker-engine 2>/dev/null || true
    echo

    # Install prerequisites
    echo "Installing prerequisites..."
    sudo dnf -y install dnf-plugins-core
    echo

    # Add Docker repo
    echo "Adding Docker repository..."
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    echo

    # Install Docker Engine
    echo "Installing Docker Engine, CLI, and plugins..."
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo

    # Enable and start Docker service
    echo "Enabling and starting Docker service..."
    sudo systemctl enable --now docker
    echo

    # Test installation
    echo "Testing Docker..."
    if sudo docker run --rm hello-world; then
        echo "✅ Docker Engine installed successfully!"
    else
        echo "❌ Docker test failed. Check installation."
        exit 1
    fi

    # Offer to add user to docker group
    echo
    read -p "Add '$USER' to 'docker' group to run Docker without sudo? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo usermod -aG docker $USER
        echo "✅ User '$USER' added to 'docker' group."
        echo "   Log out and back in to apply."
    fi

fi


# -------------------------------
# INSTALL DOCKER DESKTOP (GUI + VM)
# -------------------------------
if [[ "$INSTALL_DESKTOP" == true ]]; then

    echo "🖥️  Installing Docker Desktop..."
    echo

    # Check for KVM support
    echo "Checking for KVM virtualization support..."
    if ! lsmod | grep -q kvm; then
        echo "❌ KVM modules not loaded. Enable virtualization in BIOS and run:"
        echo "   sudo modprobe kvm && sudo modprobe kvm_intel (or kvm_amd)"
        exit 1
    fi

    # Add user to kvm group
    echo "Adding user to 'kvm' group for VM access..."
    sudo usermod -aG kvm $USER
    echo

    # Install GNOME extensions (for tray icons)
    echo "Installing AppIndicator support for system tray..."
    sudo dnf install -y gnome-shell-extension-appindicator
    sudo dnf install -y gnome-terminal  # Required for terminal-in-app
    echo "Enabling GNOME extension..."
    sudo gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com || true
    echo

    # Add Docker repo
    echo "Adding Docker repository..."
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    echo

    # Download latest Docker Desktop RPM
    echo "Downloading Docker Desktop RPM..."
    wget -qO docker-desktop.rpm https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm
    if [ ! -f "docker-desktop.rpm" ]; then
        echo "❌ Failed to download Docker Desktop. Check URL or visit:"
        echo "   https://www.docker.com/products/docker-desktop/"
        exit 1
    fi
    echo

    # Install Docker Desktop
    echo "Installing Docker Desktop..."
    sudo dnf install -y ./docker-desktop-x86_64.rpm
    rm -f docker-desktop.rpm
    echo

    # Enable and start Docker Desktop
    echo "Starting Docker Desktop..."
    systemctl --user enable docker-desktop
    systemctl --user start docker-desktop
    echo

    # Wait a bit for startup
    sleep 5

    if systemctl --user is-active docker-desktop; then
        echo "✅ Docker Desktop installed and started!"
        echo "   Launch it from your Applications menu or run:"
        echo "   systemctl --user start docker-desktop"
    else
        echo "❌ Docker Desktop failed to start. Check logs with:"
        echo "   journalctl --user -u docker-desktop --since '5 minutes ago'"
        exit 1
    fi

fi


# Final Notes
echo
echo "🎉 Installation completed!"
echo "➡️  Next steps:"
echo

if [[ "$INSTALL_ENGINE" == true ]]; then
    echo "- Run 'docker run hello-world' to test (after logging out/in if you added your user to the docker group)"
    echo "- Docs: https://docs.docker.com/engine/install/linux-postinstall/"
fi

if [[ "$INSTALL_DESKTOP" == true ]]; then
    echo "- Open Docker Desktop from your app launcher"
    echo "- Accept the subscription agreement on first launch"
    echo "- Sign in with your Docker ID to unlock features"
    echo "- Docs: https://docs.docker.com/desktop/install/fedora/"
fi

echo "- More: https://docs.docker.com/"
echo
echo "💡 Tip: You can switch between Docker contexts with 'docker context use <name>'"
echo "    Docker Desktop uses 'desktop-linux', Engine uses 'default'."
echo
echo "Log out and back in to apply group changes (kvm, docker)."
