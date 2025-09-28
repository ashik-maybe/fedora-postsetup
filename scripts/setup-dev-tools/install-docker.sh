#!/usr/bin/env bash

# install-docker.sh - Script to install Docker Engine on Fedora
# https://docs.docker.com/engine/install/fedora/

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing Docker Engine on Fedora${NC}"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}This script should not be run as root. Please run without sudo.${NC}"
   exit 1
fi

# Check if Fedora version is supported
echo -e "${YELLOW}Checking Fedora version...${NC}"
if ! grep -q "Fedora" /etc/os-release; then
    echo -e "${RED}This script is designed for Fedora only.${NC}"
    exit 1
fi

FEDORA_VERSION=$(grep VERSION_ID /etc/os-release | cut -d'=' -f2 | tr -d '"')
if [[ $FEDORA_VERSION -lt 41 ]]; then
    echo -e "${YELLOW}Warning: Docker recommends Fedora 41 or newer. Current version: $FEDORA_VERSION${NC}"
fi

# Check if Podman is installed and ask user what to do
if command -v podman &> /dev/null; then
    echo -e "${YELLOW}Podman is currently installed on your system.${NC}"
    echo -e "${YELLOW}Having both Docker and Podman can cause conflicts.${NC}"
    read -p "Do you want to remove Podman before installing Docker? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        echo -e "${YELLOW}Removing Podman...${NC}"
        sudo dnf remove -y podman podman-plugins podman-compose
    else
        echo -e "${YELLOW}Warning: Keeping both Docker and Podman may cause conflicts.${NC}"
    fi
fi

# Remove old Docker versions
echo -e "${YELLOW}Removing old Docker versions...${NC}"
sudo dnf remove -y \
    docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-selinux \
    docker-engine-selinux \
    docker-engine || true

# Install dnf-plugins-core for repository management
echo -e "${YELLOW}Installing dnf-plugins-core...${NC}"
sudo dnf -y install dnf-plugins-core

# Add Docker repository
echo -e "${YELLOW}Adding Docker repository...${NC}"
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

# Install Docker Engine
echo -e "${YELLOW}Installing Docker Engine...${NC}"
sudo dnf install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Start and enable Docker service
echo -e "${YELLOW}Starting Docker service...${NC}"
sudo systemctl enable --now docker

# Verify installation
echo -e "${YELLOW}Verifying Docker installation...${NC}"
if sudo docker run hello-world; then
    echo -e "${GREEN}Docker installation verified successfully!${NC}"
else
    echo -e "${RED}Docker verification failed!${NC}"
    exit 1
fi

# Add current user to docker group
echo -e "${YELLOW}Adding current user to docker group...${NC}"
sudo usermod -aG docker $USER

# Post-installation recommendations
echo -e "${GREEN}Docker installation completed!${NC}"
echo -e "${GREEN}To use Docker without sudo, you need to log out and log back in, or run:${NC}"
echo -e "${GREEN}  newgrp docker${NC}"
echo ""

# Ask if user wants Podman Desktop GUI
echo -e "${GREEN}Optional: Podman Desktop provides a GUI for container management${NC}"
read -p "Do you want to install Podman Desktop GUI? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    echo -e "${YELLOW}Installing Podman Desktop (GUI for container management)...${NC}"

    # Check if Flatpak is available
    if command -v flatpak &> /dev/null; then
        echo -e "${YELLOW}Using Flatpak to install Podman Desktop...${NC}"
        flatpak install -y flathub io.podman_desktop.PodmanDesktop
    else
        echo -e "${YELLOW}Flatpak not found. Installing Flatpak first...${NC}"
        sudo dnf install -y flatpak
        flatpak install -y flathub io.podman_desktop.PodmanDesktop
    fi

    echo -e "${GREEN}Podman Desktop installed! You can launch it from your applications menu.${NC}"
    echo -e "${GREEN}It will automatically detect and manage your Docker installation.${NC}"
fi

# Post-installation recommendations
echo ""
echo -e "${GREEN}Recommended next steps:${NC}"
echo -e "${GREEN}1. Log out and log back in to apply group changes${NC}"
echo -e "${GREEN}2. Test Docker: docker run hello-world${NC}"
echo -e "${GREEN}3. Check Docker version: docker --version${NC}"
echo -e "${GREEN}4. Check Docker Compose: docker compose version${NC}"
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    echo -e "${GREEN}5. Launch Podman Desktop from your applications menu${NC}"
fi

# Optional: Configure Docker daemon settings
read -p "Do you want to configure Docker daemon settings? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Configuring Docker daemon...${NC}"

    # Create daemon.json directory if it doesn't exist
    sudo mkdir -p /etc/docker

    # Create a basic daemon configuration
    cat > /tmp/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Hard": 64000,
      "Name": "nofile",
      "Soft": 64000
    }
  }
}
EOF

    sudo cp /tmp/daemon.json /etc/docker/daemon.json
    sudo systemctl restart docker

    echo -e "${GREEN}Docker daemon configured with basic settings${NC}"
fi

echo -e "${GREEN}Installation complete!${NC}"
