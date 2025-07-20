#!/usr/bin/env bash
# install-homebrew.sh — Install Homebrew on Fedora (Linuxbrew)

set -euo pipefail

CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

info() { echo -e "${CYAN}[INFO]${RESET} $1"; }
success() { echo -e "${GREEN}[OK]${RESET} $1"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error() { echo -e "${RED}[ERROR]${RESET} $1"; }

# Check if brew is installed
if command -v brew &>/dev/null; then
  success "Homebrew is already installed at $(command -v brew)"
  exit 0
fi

info "Starting Homebrew installation..."

# Run official Homebrew install script in non-interactive mode
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Source Homebrew environment (default prefix for Linux is /home/linuxbrew/.linuxbrew)
if [[ -d "$HOME/.linuxbrew" ]]; then
  BREW_PREFIX="$HOME/.linuxbrew"
elif [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
  BREW_PREFIX="/home/linuxbrew/.linuxbrew"
else
  # Try default path fallback (just in case)
  BREW_PREFIX="/home/linuxbrew/.linuxbrew"
fi

if [[ -f "$BREW_PREFIX/bin/brew" ]]; then
  info "Sourcing Homebrew environment for this shell session..."
  eval "$($BREW_PREFIX/bin/brew shellenv)"
else
  warn "Could not find Homebrew at expected prefix: $BREW_PREFIX"
  warn "You may need to add Homebrew to your PATH manually."
fi

success "Homebrew installed successfully!"

cat <<EOF

🎉 To ensure Homebrew works in future shell sessions,
add the following line to your shell config (~/.bashrc, ~/.zshrc, etc):

  eval "\$(${BREW_PREFIX}/bin/brew shellenv)"

You can verify by running:

  brew --version
  brew install hello

EOF
