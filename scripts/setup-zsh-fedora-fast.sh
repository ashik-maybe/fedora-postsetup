#!/bin/bash

# === Variables ===
ZSH_CUSTOM_DIR="$HOME/.oh-my-zsh/custom"
ZSHRC_BACKUP="$HOME/.zshrc.bak"
FAST_ZSH_PLUGIN="$ZSH_CUSTOM_DIR/plugins/fast-syntax-highlighting"
ZSH_SUGGESTIONS_PLUGIN="$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"

# === Functions ===

function install_zsh() {
    echo "🔍 Checking if Zsh is installed..."
    if ! command -v zsh &> /dev/null; then
        echo "📦 Installing Zsh..."
        sudo dnf install -y zsh
    else
        echo "✅ Zsh already installed."
    fi
}

function install_plugins() {
    mkdir -p "$ZSH_CUSTOM_DIR/plugins"

    # fast-syntax-highlighting
    if [ -d "$FAST_ZSH_PLUGIN" ]; then
        echo "✅ fast-syntax-highlighting already installed."
    else
        echo "📦 Installing fast-syntax-highlighting..."
        git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$FAST_ZSH_PLUGIN"
    fi

    # zsh-autosuggestions
    if [ -d "$ZSH_SUGGESTIONS_PLUGIN" ]; then
        echo "✅ zsh-autosuggestions already installed."
    else
        echo "📦 Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_SUGGESTIONS_PLUGIN"
    fi
}

function write_fast_zshrc() {
    echo "📝 Writing ultra-fast .zshrc with working history..."

    cat > "$HOME/.zshrc" << 'EOL'
# Minimal and fast Zsh config with full history support

# === History Settings ===
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt inc_append_history     # Save each command instantly
setopt share_history          # Share history between sessions
setopt hist_ignore_dups       # Ignore duplicates
setopt extended_history       # Save timestamps (optional)
setopt hist_verify            # Confirm before running from history

# === Prompt with Git info ===
autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )
setopt PROMPT_SUBST
PS1='%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ :) %~ ${vcs_info_msg_0_} %# '

# === Plugin Paths ===
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# === Fast Syntax Highlighting ===
source "$ZSH_CUSTOM/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

# === Delay Autosuggestions for Speed ===
autoload -Uz add-zsh-hook
load_autosuggest() {
  source "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
}
add-zsh-hook -Uz precmd load_autosuggest

# === Completion Setup (Cached) ===
autoload -Uz compinit
if [[ -n ${ZDOTDIR} ]]; then
  zcompdump="${ZDOTDIR}/.zcompdump"
else
  zcompdump="${HOME}/.zcompdump"
fi
if [[ ! -f "$zcompdump" || "$zcompdump"(+m-24) ]]; then
  compinit -d "$zcompdump"
else
  compinit -C -d "$zcompdump"
fi

# === PATH and Editor ===
export PATH="$PATH:$HOME/bin"
export EDITOR='code'
EOL
}

function backup_old_zshrc() {
    if [ -f "$HOME/.zshrc" ]; then
        echo "💾 Backing up existing .zshrc to $ZSHRC_BACKUP"
        cp "$HOME/.zshrc" "$ZSHRC_BACKUP"
    fi
}

function set_default_shell() {
    read -p "🔐 Change default shell to Zsh? (y/n): " yn
    case $yn in
        [Yy]* ) chsh -s $(which zsh); echo "✅ Shell changed to Zsh. Re-login to apply.";;
        * ) echo "ℹ️  Shell unchanged.";;
    esac
}

function remove_zsh_setup() {
    echo "🗑️  Removing Zsh setup..."

    if [ -d "$HOME/.oh-my-zsh" ]; then
        rm -rf "$HOME/.oh-my-zsh"
    fi

    if [ -f "$HOME/.zshrc" ]; then
        rm -f "$HOME/.zshrc"
    fi

    if [ -f "$ZSHRC_BACKUP" ]; then
        mv "$ZSHRC_BACKUP" "$HOME/.zshrc"
        echo "♻️  Restored old .zshrc from backup."
    fi

    read -p "🔐 Switch default shell back to Bash? (y/n): " yn
    case $yn in
        [Yy]* ) chsh -s $(which bash); echo "✅ Shell changed back to Bash.";;
        * ) echo "ℹ️  Shell unchanged.";;
    esac

    echo "✅ Revert complete!"
}

# === Main ===

clear
echo "🚀 Welcome to the Ultra-Fast Zsh Setup Script for Fedora"
echo
echo "What would you like to do?"
echo "1) Install super fast Zsh environment"
echo "2) Remove Zsh setup and revert to Bash"
read -p "Enter choice [1 or 2]: " choice

case $choice in
    1)
        echo "🛠️  Setting up ultra-fast Zsh environment..."
        install_zsh
        backup_old_zshrc
        install_plugins
        write_fast_zshrc
        set_default_shell
        echo "🎉 Done! Restart your terminal or run 'zsh' to try it out."
        ;;
    2)
        echo "🚨 Warning: This will delete your current Zsh config (.zshrc) and plugins."
        read -p "Are you sure you want to continue? (y/n): " confirm
        case $confirm in
            [Yy]* ) remove_zsh_setup;;
            * ) echo "❌ Cancelled.";;
        esac
        ;;
    *)
        echo "❌ Invalid choice. Exiting."
        ;;
esac