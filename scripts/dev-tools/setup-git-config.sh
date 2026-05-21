#!/usr/bin/env bash
# Setup Git config + SSH key (Fedora)
set -euo pipefail

GREEN="\e[32m"; BLUE="\e[34m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
banner() { echo -e "\n${BLUE}==> $1${RESET}"; }
success() { echo -e "${GREEN}[✓] $1${RESET}"; }
info() { echo -e "${YELLOW}[INFO] $1${RESET}"; }
skip() { echo -e "${BLUE}[SKIP] $1${RESET}"; }
error() { echo -e "${RED}[✗] $1${RESET}"; }

NAME=""
EMAIL=""
SIGN=false

while [ $# -gt 0 ]; do
  case "$1" in
    --name) NAME="$2"; shift 2 ;;
    --email) EMAIL="$2"; shift 2 ;;
    --sign) SIGN=true; shift ;;
    --no-sign) SIGN=false; shift ;;
    --help|-h)
      echo "Usage: $(basename "$0") [--name NAME] [--email EMAIL] [--sign] [--no-sign]"
      exit 0 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

install_git() {
  banner "Checking Git..."
  if ! command -v git &>/dev/null; then
    info "Installing Git..."
    sudo dnf install -y git
    success "Git installed"
  else
    skip "Git already installed"
  fi
}

setup_config() {
  banner "Configuring Git..."

  if [ -z "$NAME" ]; then
    read -p "Git user.name: " -r NAME
  fi
  if [ -z "$EMAIL" ]; then
    read -p "Git user.email: " -r EMAIL
  fi

  local cur_name cur_email
  cur_name=$(git config --global user.name 2>/dev/null || true)
  cur_email=$(git config --global user.email 2>/dev/null || true)

  if [ -n "$cur_name" ]; then
    skip "user.name already set ($cur_name)"
  else
    git config --global user.name "$NAME"
    success "user.name set to $NAME"
  fi

  if [ -n "$cur_email" ]; then
    skip "user.email already set ($cur_email)"
  else
    git config --global user.email "$EMAIL"
    success "user.email set to $EMAIL"
  fi
}

setup_ssh() {
  banner "Setting up SSH key..."

  local key="$HOME/.ssh/id_ed25519"

  if [ -f "$key" ]; then
    skip "SSH key already exists ($key.pub)"
  else
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$key" -N "" &>/dev/null
    success "SSH key generated"

    eval "$(ssh-agent -s)" &>/dev/null
    ssh-add "$key" &>/dev/null
    success "SSH key added to agent"
  fi

  if $SIGN; then
    local sign_key="$HOME/.ssh/id_ed25519.pub"
    git config --global gpg.format ssh
    git config --global user.signingkey "$sign_key"
    git config --global commit.gpgSign true
    success "SSH commit signing enabled"
  fi
}

print_done() {
  banner "Next step"
  echo "Add this public key to GitHub/GitLab:"
  echo ""
  cat "$HOME/.ssh/id_ed25519.pub"
  echo ""
  echo "  https://github.com/settings/keys"
}

main() {
  install_git
  setup_config
  setup_ssh
  print_done
}

main "$@"
