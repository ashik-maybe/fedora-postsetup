#!/usr/bin/env bash
#
# install-docker.sh - Install or Remove Docker Engine on Fedora
#
# Usage:
#   ./install-docker.sh        → installs Docker
#   ./install-docker.sh -r     → completely removes Docker & restores system
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ---------------------------------------------------------------------------
#  FUNCTIONS
# ---------------------------------------------------------------------------

remove_docker() {
    echo -e "${RED}WARNING: This will completely remove Docker, all containers, images, volumes, and configurations!${NC}"
    read -r -n 1 -p "Are you sure you want to remove Docker completely? (y/N): " CONFIRM
    echo
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborting removal. No changes made.${NC}"
        exit 0
    fi

    echo -e "${YELLOW}Removing Docker and cleaning up...${NC}"

    # Stop Docker services if active
    if systemctl is-active --quiet docker; then
        sudo systemctl stop docker
    fi
    if systemctl is-active --quiet docker.socket; then
        sudo systemctl stop docker.socket
    fi

    # Remove Docker packages
    echo -e "${YELLOW}Uninstalling Docker packages...${NC}"
    sudo dnf remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || true

    # Remove legacy Docker packages
    sudo dnf remove -y docker docker-client docker-common docker-latest docker-latest-logrotate \
        docker-logrotate docker-selinux docker-engine-selinux docker-engine || true

    # Remove Docker data & configs
    echo -e "${YELLOW}Removing Docker configuration and data...${NC}"
    sudo rm -rf /var/lib/docker /var/lib/containerd /etc/docker /etc/yum.repos.d/docker-ce.repo

    # Remove docker group if exists
    if getent group docker > /dev/null; then
        echo -e "${YELLOW}Removing docker group...${NC}"
        sudo groupdel docker || true
    fi

    # Clean up user-level Docker data
    echo -e "${YELLOW}Cleaning up user Docker files...${NC}"
    sudo rm -rf ~/.docker || true

    # Autoremove unneeded dependencies
    echo -e "${YELLOW}Autoremoving unused dependencies...${NC}"
    sudo dnf autoremove -y || true

    echo -e "${GREEN}Docker removed successfully.${NC}"

    # Offer to reinstall Podman
    read -r -n 1 -p "Do you want to reinstall Podman? (Y/n): " REPLY
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        echo -e "${YELLOW}Reinstalling Podman...${NC}"
        sudo dnf install -y podman podman-plugins podman-compose toolbox
        echo -e "${GREEN}Podman reinstalled.${NC}"
    else
        echo -e "${YELLOW}Skipping Podman reinstall.${NC}"
    fi

    echo -e "${GREEN}System restored to pre-Docker state.${NC}"
    exit 0
}

# ---------------------------------------------------------------------------
#  MAIN SCRIPT
# ---------------------------------------------------------------------------

# Reverse/uninstall mode
if [[ "$1" == "-r" ]]; then
    remove_docker
fi

echo -e "${GREEN}Installing Docker Engine on Fedora${NC}"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}This script should not be run as root. Please run without sudo.${NC}"
   exit 1
fi

# Check Fedora version
echo -e "${YELLOW}Checking Fedora version...${NC}"
if ! grep -q "Fedora" /etc/os-release; then
    echo -e "${RED}This script is designed for Fedora only.${NC}"
    exit 1
fi

FEDORA_VERSION=$(grep VERSION_ID /etc/os-release | cut -d'=' -f2 | tr -d '"')
if [[ $FEDORA_VERSION -lt 41 ]]; then
    echo -e "${YELLOW}Warning: Docker recommends Fedora 41 or newer. Current version: $FEDORA_VERSION${NC}"
fi

# Podman check
if command -v podman &> /dev/null; then
    echo -e "${YELLOW}Podman is currently installed on your system.${NC}"
    echo -e "${YELLOW}Having both Docker and Podman can cause conflicts.${NC}"
    read -r -n 1 -p "Do you want to remove Podman before installing Docker? (Y/n): " REPLY
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        echo -e "${YELLOW}Removing Podman...${NC}"
        sudo dnf remove -y podman podman-plugins podman-compose toolbox
    else
        echo -e "${YELLOW}Warning: Keeping both Docker and Podman may cause conflicts.${NC}"
    fi
fi

# Remove old Docker versions
echo -e "${YELLOW}Removing old Docker versions...${NC}"
sudo dnf remove -y docker docker-client docker-common docker-latest docker-latest-logrotate \
    docker-logrotate docker-selinux docker-engine-selinux docker-engine || true

# Install dnf-plugins-core
echo -e "${YELLOW}Installing dnf-plugins-core...${NC}"
sudo dnf -y install dnf-plugins-core

# Add Docker repo
echo -e "${YELLOW}Adding Docker repository...${NC}"
sudo tee /etc/yum.repos.d/docker-ce.repo > /dev/null <<EOF
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/fedora/\$releasever/\$basearch/stable
enabled=1
metadata_expire=1d
gpgcheck=1
gpgkey=https://download.docker.com/linux/fedora/gpg
EOF

# Update package cache
echo -e "${YELLOW}Updating package cache...${NC}"
sudo dnf makecache

# Install Docker
echo -e "${YELLOW}Installing Docker Engine...${NC}"
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start & enable service
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

# Post-installation notes
echo -e "${GREEN}Docker installation completed!${NC}"
echo -e "${GREEN}To use Docker without sudo, run:${NC} newgrp docker"
echo
echo -e "${GREEN}Recommended next steps:${NC}"
echo " 1. Log out and back in to apply group changes"
echo " 2. Test Docker: docker run hello-world"
echo " 3. Check version: docker --version"
echo " 4. Check Compose: docker compose version"

# Optional daemon config
read -r -n 1 -p "Do you want to configure Docker daemon settings? (y/N): " REPLY
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Configuring Docker daemon...${NC}"
    sudo mkdir -p /etc/docker
    cat > /tmp/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" },
  "default-ulimits": { "nofile": { "Name": "nofile", "Soft": 64000, "Hard": 64000 } }
}
EOF
    sudo cp /tmp/daemon.json /etc/docker/daemon.json
    sudo systemctl restart docker
    echo -e "${GREEN}Docker daemon configured with basic settings.${NC}"
fi

echo -e "${GREEN}Installation complete!${NC}"
