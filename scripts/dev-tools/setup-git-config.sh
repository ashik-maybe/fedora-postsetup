#!/usr/bin/env bash
# Setup Git + SSH key with interactive wizard (Fedora)
set -euo pipefail

GREEN="\e[32m"; BLUE="\e[34m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
banner() { echo -e "\n${BLUE}==> $1${RESET}"; }
success() { echo -e "${GREEN}[✓] $1${RESET}"; }
info() { echo -e "${YELLOW}[INFO] $1${RESET}"; }
skip() { echo -e "${BLUE}[SKIP] $1${RESET}"; }
error() { echo -e "${RED}[✗] $1${RESET}"; }
warn() { echo -e "${RED}[!] $1${RESET}"; }

NAME=""
EMAIL=""
SIGN=false
NO_PASSPHRASE=false
DRY_RUN=false
HAS_FLAGS=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --name NAME           Git user.name (skips prompt)
  --email EMAIL         Git user.email (skips prompt)
  --sign                Enable SSH commit signing
  --no-sign             Disable SSH commit signing (default)
  --no-passphrase       Generate SSH key without passphrase (for automation)
  --dry-run, -d         Preview changes without applying
  --help, -h            Show this help

Without flags, runs interactively with guided prompts.
EOF
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --name) NAME="$2"; HAS_FLAGS=true; shift 2 ;;
    --email) EMAIL="$2"; HAS_FLAGS=true; shift 2 ;;
    --sign) SIGN=true; HAS_FLAGS=true; shift ;;
    --no-sign) SIGN=false; HAS_FLAGS=true; shift ;;
    --no-passphrase) NO_PASSPHRASE=true; HAS_FLAGS=true; shift ;;
    --dry-run|-d) DRY_RUN=true; shift ;;
    --help|-h) usage ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

safe_run() {
  if $DRY_RUN; then
    info "[dry-run] $*"
    return 0
  fi
  info "Running: $*"
  eval "$@"
}

confirm_or_skip() {
  local prompt="${1:-Proceed?} [Y/n]: "
  local reply
  read -p "$prompt" -n 1 -r reply
  echo
  [[ "$reply" =~ ^[Nn]$ ]] && return 1 || return 0
}

install_git() {
  banner "Checking Git..."
  if ! command -v git &>/dev/null; then
    info "Installing Git..."
    safe_run "sudo dnf install -y git"
    success "Git installed"
  else
    skip "Git already installed ($(git --version))"
  fi
}

setup_config() {
  banner "Configuring Git identity..."

  if [ -z "$NAME" ]; then
    echo "Git attaches your name and email to every commit."
    echo "Use the same email as your GitHub/GitLab account."
    echo ""
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
    safe_run "git config --global user.name \"$NAME\""
    success "user.name set to $NAME"
  fi

  if [ -n "$cur_email" ]; then
    skip "user.email already set ($cur_email)"
  else
    safe_run "git config --global user.email \"$EMAIL\""
    success "user.email set to $EMAIL"
  fi
}

setup_qol_config() {
  banner "Recommended Git settings..."

  local settings=(
    "init.defaultBranch:main:New repos default to 'main' instead of 'master'"
    "pull.rebase:false:Standard merge behavior on pull (not rebase)"
    "fetch.prune:true:Auto-remove stale remote tracking branches"
    "core.autocrlf:input:Handle Windows line endings correctly on Linux"
  )

  local interactive=true
  $HAS_FLAGS && interactive=false

  for entry in "${settings[@]}"; do
    local key="${entry%%:*}"
    local rest="${entry#*:}"
    local val="${rest%%:*}"
    local desc="${rest#*:}"
    local cur
    cur=$(git config --global "$key" 2>/dev/null || true)

    if [ -n "$cur" ]; then
      skip "$key already set ($cur)"
      continue
    fi

    if $interactive; then
      echo ""
      echo "  $desc"
      read -p "  Set $key to '$val'? [Y/n]: " -n 1 -r reply
      echo
      if [[ "$reply" =~ ^[Nn]$ ]]; then
        skip "$key skipped"
        continue
      fi
    fi

    safe_run "git config --global $key $val"
    success "$key set to $val"
  done

  # global gitignore
  local ignores="$HOME/.config/git/ignore"
  if [ ! -f "$ignores" ]; then
    if $interactive; then
      echo ""
      echo "  A global .gitignore keeps junk (.DS_Store, *.swp, etc.) out of every repo."
      read -p "  Set up global gitignore? [Y/n]: " -n 1 -r reply
      echo
      if [[ ! "$reply" =~ ^[Nn]$ ]]; then
        safe_run "mkdir -p \"$HOME/.config/git\""
        safe_run "cat > \"$ignores\" << 'EOF'
.DS_Store
*.swp
*.swo
*~
.vscode/
.idea/
__pycache__/
*.pyc
*.pyo
EOF"
        safe_run "git config --global core.excludesfile \"$ignores\""
        success "Global gitignore set up"
      fi
    else
      safe_run "mkdir -p \"$HOME/.config/git\""
      safe_run "cat > \"$ignores\" << 'EOF'
.DS_Store
*.swp
*.swo
*~
.vscode/
.idea/
__pycache__/
*.pyc
*.pyo
EOF"
      safe_run "git config --global core.excludesfile \"$ignores\""
      success "Global gitignore set up"
    fi
  else
    skip "Global gitignore already exists"
  fi
}

setup_ssh() {
  banner "Setting up SSH key..."

  local key="$HOME/.ssh/id_ed25519"
  local PASSPHRASE=""

  if [ -f "$key" ]; then
    skip "SSH key already exists ($key.pub)"
  else
    local passphrase_flag=""
    if $NO_PASSPHRASE; then
      passphrase_flag="-N \"\""
      info "Generating SSH key without passphrase..."
    else
      echo ""
      echo "A passphrase encrypts your SSH key on disk. Without it, anyone who"
      echo "steals your key file can access your accounts with no extra step."
      echo "The ssh-agent remembers it for you — enter it once per session."
      echo ""
      read -s -p "Enter passphrase for SSH key (empty for none): " PASSPHRASE
      echo
      read -s -p "Enter same passphrase again: " PASSPHRASE_CONFIRM
      echo
      if [ "$PASSPHRASE" != "$PASSPHRASE_CONFIRM" ]; then
        error "Passphrases do not match"
        exit 1
      fi
      if [ -n "$PASSPHRASE" ]; then
        passphrase_flag="-N \"$PASSPHRASE\""
      else
        warn "No passphrase — your private key will be stored unencrypted."
        echo ""
        confirm_or_skip "Continue without passphrase?" || { info "Aborted."; exit 0; }
        passphrase_flag="-N \"\""
      fi
    fi

    safe_run "mkdir -p \"$HOME/.ssh\" && chmod 700 \"$HOME/.ssh\""
    safe_run "ssh-keygen -t ed25519 -a 64 -C \"$EMAIL\" -f \"$key\" $passphrase_flag"
    success "SSH key generated"

    # fix permissions
    safe_run "chmod 600 \"$key\" && chmod 644 \"${key}.pub\""
    success "SSH key permissions set"

    # start agent only if not running
    if ! ssh-add -l &>/dev/null; then
      info "Starting ssh-agent..."
      eval "$(ssh-agent -s)" >/dev/null
    else
      info "ssh-agent already running"
    fi

    if [ -n "$PASSPHRASE" ] && ! $DRY_RUN; then
      echo ""
      echo "Enter your passphrase once to add the key to the agent:"
      ssh-add "$key"
      success "SSH key added to agent"
    elif $DRY_RUN; then
      info "[dry-run] ssh-add \"$key\""
    else
      safe_run "ssh-add \"$key\""
      success "SSH key added to agent"
    fi
  fi

  if $SIGN; then
    if [ ! -f "$key.pub" ]; then
      warn "No public key found at $key.pub — skipping signing setup"
      return
    fi
    safe_run "git config --global gpg.format ssh"
    safe_run "git config --global user.signingkey \"${key}.pub\""
    safe_run "git config --global commit.gpgSign true"
    success "SSH commit signing enabled"
  fi
}

verify_config() {
  banner "Verifying Git configuration..."
  echo ""
  git config --global --list | grep -E "^(user\.|init\.|pull\.|fetch\.|core\.|gpg\.|commit\.)" || true
  echo ""

  if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    local fingerprint
    fingerprint=$(ssh-keygen -lf "$HOME/.ssh/id_ed25519.pub" 2>/dev/null | awk '{print $2}')
    success "SSH key fingerprint: $fingerprint"
  fi
}

print_done() {
  local pubkey="$HOME/.ssh/id_ed25519.pub"
  if [ ! -f "$pubkey" ]; then
    skip "No public SSH key found — you may need to generate one later."
    return
  fi

  banner "Next step"
  echo "Add this public key to your Git provider:"
  echo ""
  cat "$pubkey"
  echo ""
  echo "  GitHub: https://github.com/settings/keys"
  echo "  GitLab: https://gitlab.com/-/user_settings/ssh_keys"
  echo "  Gitea:  Your instance SSH keys page"
  echo ""
  echo "Tip: run 'ssh -T git@github.com' to test after adding."
}

main() {
  install_git
  setup_config
  setup_qol_config
  setup_ssh
  verify_config
  print_done
}

main "$@"
