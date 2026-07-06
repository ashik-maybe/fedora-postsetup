#!/usr/bin/env bash
#
# KDE Plasma 6 Complete Workstation Cleansing & Optimization Script
# Drops deep resource-heavy background processes while keeping total visual fidelity.
#
set -euo pipefail
IFS=$'\n\t'

# Track active context targets
REAL_USER="${SUDO_USER:-$USER}"
USER_CONFIG_DIR="/home/$REAL_USER/.config"

if [ "$(id -u)" -ne 0 ]; then
    echo -e "\e[31m[ERROR] This script must be run with sudo.\e[0m" >&2
    exit 1
fi

echo -e "\e[34m[INFO]\e[0m Commencing background workspace optimizations for: $REAL_USER"

# ----------------------------------------------------
# 1. Kill & Hard-Mask Deep Disk Indexing (Baloo)
# ----------------------------------------------------
echo -e "\e[34m[INFO]\e[0m Eliminating background file content indexing..."
if command -v balooctl6 &>/dev/null; then
    sudo -u "$REAL_USER" balooctl6 purge || true
    sudo -u "$REAL_USER" balooctl6 disable || true
fi

if [ "$REAL_USER" != "root" ]; then
    sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$REAL_USER")" \
         DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" \
         systemctl --user mask kde-baloo.service || true
fi

# ----------------------------------------------------
# 2. Balanced App Launcher Search (GNOME Style)
# ----------------------------------------------------
echo -e "\e[34m[INFO]\e[0m Setting up instant application and settings lookups..."
mkdir -p "$USER_CONFIG_DIR"

cat << 'EOF' > "$USER_CONFIG_DIR/krunnerrc"
[Plugins]
CharacterRunnerEnabled=false
DictionaryEnabled=false
KWinEnabled=true
LocationRunnerEnabled=false
PlacesRunnerEnabled=false
PowerDevilEnabled=true
SpellCheckEnabled=false
WebSearchKeywordsEnabled=false
calculatorEnabled=false
gdriveEnabled=false
helprunnerEnabled=false
katesessionsEnabled=false
konsoleprofilesEnabled=true
org.kde.activitiesEnabled=false
org.kde.windowedwidgetsEnabled=false
recentdocumentsEnabled=false
bookmarksEnabled=false
browserhistoryEnabled=false
shellEnabled=true
unitconverterEnabled=false

[General]
FreeFloating=true
HistoryEnabled=false
EOF
chown "$REAL_USER:$REAL_USER" "$USER_CONFIG_DIR/krunnerrc"

# ----------------------------------------------------
# 3. Streamlined KDE Application & Service Purge
# ----------------------------------------------------
echo -e "\e[34m[INFO]\e[0m Running targeted DNF debloat transaction..."
KDE_DEBLOAT_LIST=(
    # Core background infrastructure items that run background engines
    "akonadi-server"
    "akregator"
    "kaddressbook"
    "kmail"
    "kontact"
    "korganizer"
    "ktnef"
    "neochat"
    "kleopatra"
    "plasma-discover"
    "plasma-discover-notifier"
    
    # First-boot onboarding utility (No longer needed)
    "plasma-welcome"

    # Confirmed heavy pre-installed desktop utilities
    "dragon"
    "elisa-player"
    "kcharselect"
    "kfind"
    "khelpcenter"
    "kmouth"
    "kolourpaint"
    "krfb"
    "krdc"
    "kamoso"
    "qrca"
    "filelight"
    "skanpage"
)

# Filter the list down to only packages that are actually installed
INSTALLED_DEBLOAT=()
for pkg in "${KDE_DEBLOAT_LIST[@]}"; do
    if rpm -q "$pkg" &>/dev/null; then
        INSTALLED_DEBLOAT+=("$pkg")
    fi
done

if [ ${#INSTALLED_DEBLOAT[@]} -gt 0 ]; then
    dnf remove -y "${INSTALLED_DEBLOAT[@]}"
else
    echo -e "\e[34m[INFO]\e[0m No target packages found for removal. Skipping step."
fi

dnf autoremove -y
dnf clean all

# ----------------------------------------------------
# 4. Telemetry Lockout
# ----------------------------------------------------
echo -e "\e[34m[INFO]\e[0m Shutting down system analytics reporting..."
if [ -f /etc/xdg/UserFeedbackConsole.conf ]; then
    rm -f /etc/xdg/UserFeedbackConsole.conf
fi
sudo -u "$REAL_USER" kwriteconfig6 --file "$USER_CONFIG_DIR/plasma-user-feedback" --group "UserFeedback" --key "SubmissionLevel" "0"

echo -e "\e[32m[OK]\e[0m KDE cleanup pipeline complete. Please trigger a full system reboot."
