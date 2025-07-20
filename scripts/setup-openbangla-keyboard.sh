#!/usr/bin/env bash
# install-openbangla-keyboard.sh — Install OpenBangla Keyboard (IBus) for Fedora/RHEL-based systems (GNOME focused)

set -euo pipefail

# ───────────── Terminal Styling ─────────────
CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

info()    { echo -e "${CYAN}[INFO]${RESET} $1"; }
success() { echo -e "${GREEN}[OK]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; }

# ───────────── Start Installation ─────────────
info "🔁 Updating system and enabling EPEL & CRB..."
sudo dnf update -y
sudo dnf install -y epel-release
sudo dnf config-manager --set-enabled crb
sudo dnf update -y

info "🛠 Installing Development Tools and build dependencies..."
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y rust cargo cmake qt5-qtdeclarative-devel ibus-devel libzstd-devel git

# ───────────── Clone and Build ─────────────
if [ -d "OpenBangla-Keyboard" ]; then
    warn "📁 'OpenBangla-Keyboard' directory already exists. Skipping clone."
else
    info "📥 Cloning OpenBangla-Keyboard repo..."
    git clone --recursive https://github.com/OpenBangla/OpenBangla-Keyboard.git
fi

cd OpenBangla-Keyboard

info "📦 Switching to 'develop' branch and updating submodules..."
git checkout develop
git submodule update --init --recursive

info "⚙️ Configuring the project with CMake..."
cmake . -DCMAKE_INSTALL_PREFIX="/usr" -DENABLE_IBUS=ON

info "🔨 Building the source..."
make -j"$(nproc)"

info "🔐 Installing OpenBangla Keyboard system-wide..."
sudo make install

success "✅ OpenBangla Keyboard installed successfully!"

# ───────────── Post-Install Instructions ─────────────
cat <<'EOF'

🎉 Installation Complete!

🧭 NEXT STEPS FOR GNOME (Wayland/X11):
────────────────────────────────────────────
1. 🔁 Log out and log back in (to reload input methods).
2. 🧩 Open **OpenBangla Keyboard** from the app menu (first-time config).
3. ⚙️ Open **Settings > Keyboard > Input Sources**.
   → Click '+' → Scroll to "Bangla (OpenBangla Keyboard)" → Add it.
4. 🌐 Switch between layouts using Super+Space or your configured shortcut.

💡 TIP: You can customize input method switching from:
   GNOME Settings → Keyboard → Keyboard Shortcuts → Input.

────────────────────────────────────────────
📌 KDE USERS:
→ Use System Settings > Input Devices > Virtual Keyboard → Set to **IBus (Wayland)**.
→ Launch OpenBangla and disable suggestion (for stability).

EOF
