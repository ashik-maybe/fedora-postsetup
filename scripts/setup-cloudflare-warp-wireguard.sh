#!/bin/bash
# setup-warp-wireguard.sh (v4.0) — Cloudflare WARP via WireGuard with Reversal Flag

set -euo pipefail

CYAN="\033[0;36m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# Helper to execute commands with unified feedback formatting
run_cmd() {
    echo -e "${CYAN}🔧 Running: $1${RESET}"
    eval "$1"
}

# 1. Handle uninstallation / reversal parameter
if [[ "${1:-}" == "-r" || "${1:-}" == "--reverse" ]]; then
    echo -e "${YELLOW}🛑 Initiating complete reversal/removal of WARP configurations...${RESET}"

    # Safely take down active wireguard interfaces
    if ip link show warp &>/dev/null; then
        run_cmd "sudo wg-quick down warp"
    fi

    # Remove NetworkManager GUI profiles
    if nmcli connection show "Cloudflare WARP" &>/dev/null; then
        run_cmd "sudo nmcli connection delete 'Cloudflare WARP'"
    fi
    if nmcli connection show warp &>/dev/null; then
        run_cmd "sudo nmcli connection delete warp"
    fi

    # Strip filesystem configurations
    if [ -f "/etc/wireguard/warp.conf" ]; then
        run_cmd "sudo rm -f /etc/wireguard/warp.conf"
    fi

    echo -e "${GREEN}✨ Reversal complete. System clean!${RESET}"
    exit 0
fi

echo -e "${YELLOW}🚀 Starting Cloudflare WARP via WireGuard setup (v4.0)...${RESET}"

# 2. Check for existing profile and handle optional re-registration
if [ -f "/etc/wireguard/warp.conf" ]; then
    echo -e "${YELLOW}⚠️ Existing WARP configuration found.${RESET}"
    read -p "🔄 Do you want to re-register and generate a completely fresh identity? (y/N): " FORCE_REG

    if [[ "$FORCE_REG" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🧹 Purging old profile and NetworkManager configurations...${RESET}"
        sudo wg-quick down warp &>/dev/null || true
        sudo nmcli connection delete "Cloudflare WARP" &>/dev/null || true
        sudo nmcli connection delete warp &>/dev/null || true
        sudo rm -f /etc/wireguard/warp.conf
        echo -e "${GREEN}✅ Old identity cleared.${RESET}"
    fi
fi

# 3. Install system dependencies if missing
if ! command -v wg-quick &>/dev/null; then
    echo -e "${YELLOW}📦 Installing wireguard-tools...${RESET}"
    run_cmd "sudo dnf install -y wireguard-tools"
else
    echo -e "${GREEN}✅ wireguard-tools already installed.${RESET}"
fi

# 4. Build profile via wgcf if not present
if [ ! -f "/etc/wireguard/warp.conf" ]; then
    echo -e "${YELLOW}🌐 Generating fresh Cloudflare WARP WireGuard profile...${RESET}"

    WGCF_URL=$(curl -s https://api.github.com/repos/ViRb3/wgcf/releases/latest | grep -oP '"browser_download_url": "\K[^"]*linux_amd64')

    run_cmd "curl -fsSL $WGCF_URL -o wgcf"
    run_cmd "chmod +x wgcf"

    run_cmd "./wgcf register --accept-tos"
    run_cmd "./wgcf generate"

    run_cmd "sudo mkdir -p /etc/wireguard"
    run_cmd "sudo mv wgcf-profile.conf /etc/wireguard/warp.conf"

    rm -f wgcf wgcf-account.toml
    echo -e "${GREEN}✅ Profile generated dynamically.${RESET}"
else
    echo -e "${GREEN}✅ Keeping active WARP WireGuard configuration profile.${RESET}"
fi

# 5. Integrate into NetworkManager for Beautiful GUI Controls
if ! nmcli connection show "Cloudflare WARP" &>/dev/null; then
    echo -e "${YELLOW}⚙️ Integrating into NetworkManager with production naming profile...${RESET}"

    run_cmd "sudo nmcli connection import type wireguard file /etc/wireguard/warp.conf"
    run_cmd "sudo nmcli connection modify warp connection.id 'Cloudflare WARP'"
    run_cmd "sudo nmcli connection modify 'Cloudflare WARP' ipv4.dns-priority -1"

    echo -e "${GREEN}✅ NetworkManager integration complete.${RESET}"
else
    echo -e "${GREEN}✅ NetworkManager connection 'Cloudflare WARP' already configured.${RESET}"
fi

# 6. Final instructions
echo -e "${CYAN}
🎉 Process finished!

🖥️ Beautiful GUI Toggle:
  Look for 'Cloudflare WARP' in your Desktop Environment panel (GNOME, KDE, XFCE).

📟 Terminal Commands:
  ➤ Connect:    sudo wg-quick up warp
  ➤ Status:     sudo wg show warp
  ➤ Disconnect: sudo wg-quick down warp

❌ To completely uninstall/undo everything later:
  ./$(basename "$0") -r
${RESET}"
