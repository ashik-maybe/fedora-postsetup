#!/bin/bash
# setup-warp-wireguard.sh — Cloudflare WARP via WireGuard for Fedora 44+
# Usage:
#   ./setup-warp-wireguard.sh           # Install/configure WARP
#   ./setup-warp-wireguard.sh -r        # Remove WARP completely

set -euo pipefail

CYAN="\033[0;36m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

run_cmd() {
    echo -e "${CYAN}🔧 Running: $1${RESET}"
    eval "$1"
}

# ── Reversal / Uninstall
if [[ "${1:-}" == "-r" || "${1:-}" == "--reverse" ]]; then
    echo -e "${YELLOW}🛑 Removing Cloudflare WARP configuration...${RESET}"

    if ip link show warp &>/dev/null; then
        run_cmd "sudo wg-quick down warp"
    fi

    if nmcli connection show "Cloudflare WARP" &>/dev/null; then
        run_cmd "sudo nmcli connection delete 'Cloudflare WARP'"
    fi
    if nmcli connection show warp &>/dev/null; then
        run_cmd "sudo nmcli connection delete warp"
    fi

    if [ -f "/etc/wireguard/warp.conf" ]; then
        run_cmd "sudo rm -f /etc/wireguard/warp.conf"
    fi

    echo -e "${GREEN}✨ Removal complete.${RESET}"
    exit 0
fi

echo -e "${YELLOW}🚀 Cloudflare WARP via WireGuard — Setup${RESET}"

# ── Ensure curl is available (Fedora minimal might not have it)
if ! command -v curl &>/dev/null; then
    run_cmd "sudo dnf install -y curl"
fi

# ── Handle existing profile
if [ -f "/etc/wireguard/warp.conf" ]; then
    echo -e "${YELLOW}⚠️ Existing WARP configuration found.${RESET}"
    read -p "Re-register for a fresh identity? (y/N): " -n 1 -r
    echo

    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🧹 Removing old profile...${RESET}"
        sudo wg-quick down warp &>/dev/null || true
        sudo nmcli connection delete "Cloudflare WARP" &>/dev/null || true
        sudo nmcli connection delete warp &>/dev/null || true
        sudo rm -f /etc/wireguard/warp.conf
        echo -e "${GREEN}✅ Old profile cleared.${RESET}"
    fi
fi

# ── Install wireguard-tools
if ! command -v wg-quick &>/dev/null; then
    echo -e "${YELLOW}📦 Installing wireguard-tools...${RESET}"
    run_cmd "sudo dnf install -y wireguard-tools"
else
    echo -e "${GREEN}✅ wireguard-tools already installed.${RESET}"
fi

# ── Generate profile via wgcf
if [ ! -f "/etc/wireguard/warp.conf" ]; then
    echo -e "${YELLOW}🌐 Generating WARP WireGuard profile...${RESET}"

    WGCF_URL=$(curl -s https://api.github.com/repos/ViRb3/wgcf/releases/latest | grep -oE '"browser_download_url": "[^"]*linux_amd64"' | cut -d'"' -f4)

    WORKDIR=$(mktemp -d)
    cd "$WORKDIR"

    run_cmd "curl -fsSL $WGCF_URL -o wgcf"
    run_cmd "chmod +x wgcf"

    run_cmd "./wgcf register --accept-tos"
    run_cmd "./wgcf generate"

    run_cmd "sudo mkdir -p /etc/wireguard"
    run_cmd "sudo mv wgcf-profile.conf /etc/wireguard/warp.conf"

    cd - > /dev/null
    rm -rf "$WORKDIR"
    echo -e "${GREEN}✅ Profile generated.${RESET}"
else
    echo -e "${GREEN}✅ Using existing WARP profile.${RESET}"
fi

# ── NetworkManager integration
if ! nmcli connection show "Cloudflare WARP" &>/dev/null; then
    echo -e "${YELLOW}⚙️ Adding to NetworkManager...${RESET}"

    run_cmd "sudo nmcli connection import type wireguard file /etc/wireguard/warp.conf"
    run_cmd "sudo nmcli connection modify warp connection.id 'Cloudflare WARP'"
    run_cmd "sudo nmcli connection modify 'Cloudflare WARP' ipv4.dns-priority -1"

    echo -e "${GREEN}✅ NetworkManager integration complete.${RESET}"
else
    echo -e "${GREEN}✅ NetworkManager already configured.${RESET}"
fi

# ── Done
echo -e "${CYAN}
🎉 Setup complete!

🖥️  GUI: Toggle 'Cloudflare WARP' in your network panel

📟 Terminal:
  Connect:    sudo wg-quick up warp
  Status:     sudo wg show warp
  Disconnect: sudo wg-quick down warp

❌ Remove everything:
  ./$(basename "$0") -r
${RESET}"
