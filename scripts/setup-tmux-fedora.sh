#!/bin/bash

# === Variables ===
TMUX_PLUGIN_DIR="$HOME/.tmux/plugins"
TMUX_CONF="$HOME/.tmux.conf"
TMUX_CONF_BACKUP="$HOME/.tmux.conf.bak"

# === Functions ===

function install_tmux() {
    echo "🔍 Checking if Tmux is installed..."
    if ! command -v tmux &> /dev/null; then
        echo "📦 Installing Tmux..."
        sudo dnf install -y tmux
    else
        echo "✅ Tmux already installed."
    fi
}

function install_tpm() {
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        echo "✅ TPM (Tmux Plugin Manager) already installed."
        return
    fi

    echo "📦 Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
}

function write_tmux_conf() {
    echo "📝 Writing minimal .tmux.conf..."

    cat > "$TMUX_CONF" << 'EOL'
# Minimal, fast, and useful tmux config for VS Code users

# Set prefix to Ctrl-a (like screen)
set-option -g prefix C-a
unbind C-b
bind C-a send-prefix

# Reload config
bind r source-file ~/.tmux.conf \; display-message "Reloaded!"

# Start window index at 1
set-option -g base-index 1
set-option -g pane-base-index 1

# Set status bar refresh interval
set -g status-interval 5

# Status bar color
set -g status-style bg=default,fg=colour247,dim

# Left side: session name
set -g status-left '#[fg=green]#S'

# Right side: date and time
set -g status-right '#[fg=yellow]%Y-%m-%d %H:%M'

# Window list format
set -g window-status-format "#I #W"
set -g window-status-current-format "#[fg=cyan]#I #W"

# Enable mouse support
set -g mouse on

# Set clipboard to use system clipboard (if using tmux >=3.2)
set -g set-clipboard both

# Split panes with | and -
bind | split-window -h
bind - split-window -v

# Easy resizing with Alt + arrow keys
bind -n M-Left resize-pane -L 5
bind -n M-Right resize-pane -R 5
bind -n M-Up resize-pane -U 5
bind -n M-Down resize-pane -D 5

# Navigation shortcuts (with Ctrl + Arrow)
bind-key -n C-Left select-pane -L
bind-key -n C-Right select-pane -R
bind-key -n C-Up select-pane -U
bind-key -n C-Down select-pane -D

# Plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'

# Initialize TMUX plugin manager (keep last)
run '~/.tmux/plugins/tpm/tpm'
EOL
}

function backup_old_tmux_conf() {
    if [ -f "$TMUX_CONF" ]; then
        echo "💾 Backing up existing .tmux.conf to $TMUX_CONF_BACKUP"
        cp "$TMUX_CONF" "$TMUX_CONF_BACKUP"
    fi
}

function install_tmux_plugins() {
    echo "🔌 Installing tmux plugins via TPM..."
    mkdir -p "$TMUX_PLUGIN_DIR"
    install_tpm

    # Load tmux and install plugins non-interactively
    tmux start-server
    tmux new-session -d -s tmp-install
    sleep 1
    ~/.tmux/plugins/tpm/bin/install_plugins
    tmux kill-session -t tmp-install
    echo "✅ Plugins installed!"
}

function remove_tmux_setup() {
    echo "🗑️  Removing Tmux setup..."

    if [ -d "$HOME/.tmux" ]; then
        rm -rf "$HOME/.tmux"
    fi

    if [ -f "$TMUX_CONF" ]; then
        rm -f "$TMUX_CONF"
    fi

    if [ -f "$TMUX_CONF_BACKUP" ]; then
        mv "$TMUX_CONF_BACKUP" "$TMUX_CONF"
        echo "♻️  Restored old .tmux.conf from backup."
    fi

    echo "✅ Tmux setup removed!"
}

# === Main ===

clear
echo "🚀 Welcome to the Ultra-Fast Tmux Setup Script for VS Code Users (Fedora)"
echo
echo "What would you like to do?"
echo "1) Install Tmux (for VS Code users)"
echo "2) Remove Tmux config and plugins"
read -p "Enter choice [1 or 2]: " choice

case $choice in
    1)
        echo "🛠️  Setting up Tmux environment..."
        install_tmux
        backup_old_tmux_conf
        write_tmux_conf
        install_tmux_plugins
        echo "🎉 Done! Run 'tmux' to try it out."
        ;;
    2)
        echo "🚨 Warning: This will delete your current Tmux config and plugins."
        read -p "Are you sure you want to continue? (y/n): " confirm
        case $confirm in
            [Yy]* ) remove_tmux_setup;;
            * ) echo "❌ Cancelled.";;
        esac
        ;;
    *)
        echo "❌ Invalid choice. Exiting."
        ;;
esac