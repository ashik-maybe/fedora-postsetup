#!/bin/bash
# setup-warp.sh — installs Cloudflare WARP and performs optional setup

set -euo pipefail

CYAN="\033[0;36m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# Helper to run commands with feedback
run_cmd() {
    echo -e "${CYAN}🔧 Running: $1${RESET}"
    eval "$1"
}

# 1. Add repo if not present
if ! grep -q "\[cloudflare-warp\]" /etc/yum.repos.d/*.repo &>/dev/null; then
    echo -e "${YELLOW}🌐 Adding Cloudflare WARP repository...${RESET}"
    run_cmd "curl -fsSL https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | sudo tee /etc/yum.repos.d/cloudflare-warp.repo"
else
    echo -e "${GREEN}✅ Cloudflare WARP repo already present.${RESET}"
fi

# 2. Install warp-cli
if ! command -v warp-cli &>/dev/null; then
    echo -e "${YELLOW}📦 Installing WARP CLI...${RESET}"
    run_cmd "sudo dnf install -y cloudflare-warp"
else
    echo -e "${GREEN}✅ WARP CLI already installed.${RESET}"
fi

# 3. Optional first-time registration
echo -e "${YELLOW}🆕 Is this your first time using WARP?${RESET}"
read -p "👉 Register this device now? (y/n): " reg_ans
if [[ "$reg_ans" =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}🔐 Registering with Cloudflare WARP...${RESET}"
    printf "y\n" | warp-cli registration new && echo -e "${GREEN}✅ Registration complete.${RESET}"
else
    echo -e "${CYAN}⏭️ Skipping WARP registration.${RESET}"
fi

# 4. Usage guide
echo -e "${CYAN}
📘 WARP CLI Quick Reference:

  ➤ Connect:   warp-cli connect
  ➤ Status:    warp-cli status
  ➤ Disconnect: warp-cli disconnect

⚙️ Mode switching:
  🔸 DNS only (DoH):     warp-cli mode doh
  🔹 WARP + DoH:         warp-cli mode warp+doh

👨‍👩‍👧‍👦 1.1.1.1 for Families:
  🚫 Off:                warp-cli dns families off
  🛡️ Malware filter:     warp-cli dns families malware
  🔞 Full filter:        warp-cli dns families full

📚 More commands: warp-cli --help
${RESET}"
