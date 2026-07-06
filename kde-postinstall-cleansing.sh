#!/usr/bin/env bash
#
# KDE Plasma 6 Complete Workstation Cleansing & Optimization Script
# Drops deep resource-heavy background processes while keeping total visual fidelity.
#
set -euo pipefail
IFS=$'\n\t'

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
# 3. Comprehensive KDE Application & Service Purge
# ----------------------------------------------------
echo -e "\e[34m[INFO]\e[0m Running targeted DNF debloat transaction..."
KDE_DEBLOAT_LIST=(
    # KDE Personal Information Management (PIM) Suite (Kills hidden background SQL database)
    "akonadi-server" "akregator" "kaddressbook" "kmail" "knotes"
    "kontact" "korganizer" "ktnef" "neochat" "pim" "kleopatra"

    # Frontend Storefronts & Background Update Check Loops
    "plasma-discover" "plasma-discover-notifier"

    # KDE Games & Toy Packages
    "kbrickbuster" "kblocks" "kbounce" "kdiamond" "kfourinline" "kgoldrunner"
    "killbots" "kiriki" "klickety" "klines" "kmines" "knetwalk" "kolf" "kpat"
    "kreversi" "kshisen" "kspaceduel" "ksquares" "ksudoku" "kmahjongg"
    "ktuberling" "kubrick" "lskat" "palapeli" "picmi"

    # KDE Supplemental Applications & Media Clutter
    "dragon" "elisa-player" "juk" "kcharselect" "kfind" "kfloppy" "kget"
    "khelpcenter" "kmag" "kmousetool" "kmouth" "kolourpaint" "konversation"
    "krecorder" "krdp" "kteatime" "ktimer" "ktrip" "ktorrent" "kweather"
    "skanpage" "krfb" "krdc" "kamoso" "qrca" "filelight" "kcalc"
)

dnf remove -y "${KDE_DEBLOAT_LIST[@]}"
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
