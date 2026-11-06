#!/usr/bin/env bash

# setup-git-config.sh — Install Git and SSH key with a wizard (Fedora 44+).
#
# Usage:
#   ./setup-git-config.sh [OPTIONS]
#   ./setup-git-config.sh --name "Name" --email "a@b.c" --sign --dry-run
#
# Exit codes: 0 ok · 1 error · 2 aborted
# Idempotent: existing config/keys are skipped, never overwritten.

set -euo pipefail
IFS=$'\n\t'

# 0. Config
readonly SSH_KEY="$HOME/.ssh/id_ed25519"
readonly GITIGNORE_FILE="$HOME/.config/git/ignore"

NAME=""
EMAIL=""
SIGN=false
NO_PASSPHRASE=false
DRY_RUN=false
HAS_FLAGS=false

# 1. Helpers
GREEN="\e[32m"; BLUE="\e[34m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
banner() { echo -e "\n${BLUE}==> $1${RESET}"; }
ok()     { echo -e "${GREEN}[OK]${RESET} $1"; }
info()   { echo -e "${YELLOW}[INFO]${RESET} $1"; }
skip()   { echo -e "${BLUE}[SKIP]${RESET} $1"; }
warn()   { echo -e "${YELLOW}[!]${RESET} $1"; }
die()    { echo -e "${RED}[ERROR]${RESET} $1" >&2; exit 1; }

run() {
    local IFS=' '
    info "→ $*"
    if $DRY_RUN; then return 0; fi
    "$@"
}

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

Without flags, run the interactive wizard.
EOF
    exit 0
}

confirm_or_skip() {
    local prompt="${1:-Proceed?} [Y/n]: "
    local reply
    read -p "$prompt" -n 1 -r reply || true
    echo
    [[ "$reply" =~ ^[Nn]$ ]] && return 1 || return 0
}

# 2. Pre-flight guards
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name) NAME="$2"; HAS_FLAGS=true; shift 2 ;;
            --email) EMAIL="$2"; HAS_FLAGS=true; shift 2 ;;
            --sign) SIGN=true; HAS_FLAGS=true; shift ;;
            --no-sign) SIGN=false; HAS_FLAGS=true; shift ;;
            --no-passphrase) NO_PASSPHRASE=true; HAS_FLAGS=true; shift ;;
            --dry-run|-d) DRY_RUN=true; shift ;;
            --help|-h) usage ;;
            *) die "Unknown argument: $1" ;;
        esac
    done
}

# 3. Steps
step_git() {
    banner "Check Git..."
    if command -v git &>/dev/null; then
        skip "Git already installed ($(git --version))"
    else
        run sudo dnf install -y git
        ok "Git installed"
    fi
}

step_identity() {
    banner "Configure Git identity..."
    if [[ -z "$NAME" ]]; then
        echo "Git attaches your name and email to every commit."
        read -p "Git user.name: " -r NAME || true
    fi
    if [[ -z "$EMAIL" ]]; then
        read -p "Git user.email: " -r EMAIL || true
    fi
    if git config --global user.name 2>/dev/null | grep -q .; then
        skip "user.name already set ($(git config --global user.name))"
    else
        run git config --global user.name "$NAME"
        ok "user.name set to $NAME"
    fi
    if git config --global user.email 2>/dev/null | grep -q .; then
        skip "user.email already set ($(git config --global user.email))"
    else
        run git config --global user.email "$EMAIL"
        ok "user.email set to $EMAIL"
    fi
}

step_qol() {
    banner "Set recommended Git values..."
    local interactive=true
    if $HAS_FLAGS; then interactive=false; fi
    local -a entries=(
        "init.defaultBranch|main|Make 'main' the default branch"
        "pull.rebase|false|Use merge on pull"
        "fetch.prune|true|Remove stale remote branches"
        "core.autocrlf|input|Convert Windows line endings"
    )
    local entry key val desc cur reply
    for entry in "${entries[@]}"; do
        IFS='|' read -r key val desc <<< "$entry"
        cur="$(git config --global "$key" 2>/dev/null || true)"
        if [[ -n "$cur" ]]; then
            skip "$key already set ($cur)"
            continue
        fi
        if $interactive; then
            echo ""
            echo "  $desc"
            read -p "  Set $key to '$val'? [Y/n]: " -n 1 -r reply || true
            echo
            if [[ "$reply" =~ ^[Nn]$ ]]; then skip "$key skipped"; continue; fi
        fi
        run git config --global "$key" "$val"
        ok "$key set to $val"
    done
    if [[ -f "$GITIGNORE_FILE" ]]; then
        skip "Global gitignore already exists"
        return 0
    fi
    if $interactive; then
        echo ""
        read -p "  Set up global gitignore? [Y/n]: " -n 1 -r reply || true
        echo
        [[ "$reply" =~ ^[Nn]$ ]] && { skip "Global gitignore skipped"; return 0; }
    fi
    if $DRY_RUN; then
        run mkdir -p "$(dirname "$GITIGNORE_FILE")"
        return 0
    fi
    mkdir -p "$(dirname "$GITIGNORE_FILE")"
    cat > "$GITIGNORE_FILE" <<'EOF'
.DS_Store
*.swp
*.swo
*~
.vscode/
.idea/
__pycache__/
*.pyc
*.pyo
EOF
    run git config --global core.excludesfile "$GITIGNORE_FILE"
    ok "Global gitignore installed."
}

step_ssh() {
    banner "Install SSH key..."
    local passphrase=""
    if [[ -f "$SSH_KEY" ]]; then
        skip "SSH key already exists ($SSH_KEY.pub)"
    else
        if $NO_PASSPHRASE; then
            passphrase=""
            info "Generate SSH key without passphrase..."
        else
            echo ""
            echo "A passphrase protects the key."
            echo "The ssh-agent stores it in memory."

            echo ""
            read -s -p "Enter passphrase for SSH key (empty for none): " passphrase || true
            echo
            local confirm_pass=""
            read -s -p "Enter same passphrase again: " confirm_pass || true
            echo
            [[ "$passphrase" == "$confirm_pass" ]] || die "Passphrases do not match"
            if [[ -z "$passphrase" ]]; then
                warn "No passphrase. The key is not encrypted."
                confirm_or_skip "Continue without passphrase?" || { info "Aborted."; exit 2; }
            fi
        fi
        run mkdir -p "$HOME/.ssh"
        run chmod 700 "$HOME/.ssh"
        run ssh-keygen -t ed25519 -a 64 -C "$EMAIL" -f "$SSH_KEY" -N "$passphrase"
        ok "SSH key generated"
        run chmod 600 "$SSH_KEY"
        run chmod 644 "$SSH_KEY.pub"
        ok "SSH key permissions set"
        if $DRY_RUN; then
            info "[dry-run] ssh-add \"$SSH_KEY\""
        else
            if ! ssh-add -l &>/dev/null; then
                info "Starting ssh-agent..."
                eval "$(ssh-agent -s)" >/dev/null
            fi
            if [[ -n "$passphrase" ]]; then
                echo ""
                echo "Enter the passphrase to add the key to ssh-agent:"
                ssh-add "$SSH_KEY"
            else
                run ssh-add "$SSH_KEY"
            fi
            ok "SSH key added to agent"
        fi
    fi
    if $SIGN; then
        if [[ ! -f "$SSH_KEY.pub" ]]; then
            warn "No public key. Skip signing setup."
            return 0
        fi
        run git config --global gpg.format ssh
        run git config --global user.signingkey "$SSH_KEY.pub"
        run git config --global commit.gpgSign true
        ok "SSH commit signing enabled"
    fi
}

step_verify() {
    banner "Verify Git configuration..."
    echo ""
    git config --global --list 2>/dev/null | grep -E "^(user\.|init\.|pull\.|fetch\.|core\.|gpg\.|commit\.)" || true
    echo ""
    if [[ -f "$SSH_KEY.pub" ]]; then
        local fingerprint
        fingerprint="$(ssh-keygen -lf "$SSH_KEY.pub" 2>/dev/null | awk '{print $2}')"
        ok "SSH key fingerprint: $fingerprint"
    fi
}

step_done() {
    local pubkey="$SSH_KEY.pub"
    if [[ ! -f "$pubkey" ]]; then
        skip "No public SSH key found — generate one later."
        return 0
    fi
    banner "Add the public key"
    echo "Add this public key to Git:"
    echo ""
    cat "$pubkey"
    echo ""
    echo "  GitHub: https://github.com/settings/keys"
    echo "  GitLab: https://gitlab.com/-/user_settings/ssh_keys"
    echo ""
    echo "Test with: ssh -T git@github.com"
}

# 4. Main
main() {
    parse_args "$@"
    step_git
    step_identity
    step_qol
    step_ssh
    step_verify
    step_done
}

main "$@"
