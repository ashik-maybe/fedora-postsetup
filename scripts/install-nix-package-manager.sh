#!/usr/bin/env bash
# install-nix.sh — Install Nix package manager on Fedora & setup environment

set -euo pipefail

CYAN="\033[0;36m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

info() { echo -e "${CYAN}[INFO]${RESET} $1"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; }

# Detect SELinux status
SELINUX_MODE=$(getenforce 2>/dev/null || echo "Unknown")

info "SELinux mode detected: $SELINUX_MODE"

if [[ "$SELINUX_MODE" == "Enforcing" ]]; then
    warn "SELinux is enforcing; running single-user install (--no-daemon)"
    info "Running Nix single-user install..."
    sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon
else
    info "Running Nix multi-user install (--daemon) with sudo..."
    sudo sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
fi

# Source nix profile for current shell
if [[ -f ~/.nix-profile/etc/profile.d/nix.sh ]]; then
    info "Sourcing Nix profile script..."
    source ~/.nix-profile/etc/profile.d/nix.sh
else
    warn "Nix profile script not found. You may need to start a new shell session or source manually:"
    echo "  source ~/.nix-profile/etc/profile.d/nix.sh"
fi

# Confirm nix command works
if ! command -v nix &>/dev/null; then
    error "Nix command not found after installation! Please check the installation."
    exit 1
fi

info "Nix installation complete. Testing package installation with 'hello'..."

nix-env -iA nixpkgs.hello

echo -e "${GREEN}🎉 Nix is installed and 'hello' package installed successfully.${RESET}"
echo "You can now use 'nix-env' or other nix commands to install packages."
