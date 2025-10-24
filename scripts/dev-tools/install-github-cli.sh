#!/usr/bin/env bash
#
# install-github-cli.sh — Install GitHub CLI (gh) on Fedora using dnf5
# Compatible with Fedora 40+ (dnf5-based)
# https://cli.github.com

set -euo pipefail

# Logging helpers

log() { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*"; exit 1; }

# Check for dnf5

if ! command -v dnf5 &>/dev/null; then
  log "dnf5 not found. Installing dnf5-plugins..."
  sudo dnf install -y dnf5-plugins || err "Failed to install dnf5-plugins"
fi

# Add GitHub CLI repo

REPO_URL="https://cli.github.com/packages/rpm/gh-cli.repo"
REPO_NAME="gh-cli"

log "Adding GitHub CLI repo from $REPO_URL"
sudo dnf5 config-manager addrepo --from-repofile="$REPO_URL" || err "Failed to add GitHub CLI repo"

# Install GitHub CLI

log "Installing GitHub CLI (gh)..."
sudo dnf5 install -y gh --repo "$REPO_NAME" || err "Failed to install GitHub CLI"

# Done

log "GitHub CLI installed successfully 🎉"
gh --version
