#!/usr/bin/env bash
#
# KDE Plasma 6 Complete Workstation Cleansing & Optimization Script
# Drops deep resource-heavy background processes while keeping total visual fidelity.
# Idempotent: Safely skips steps if already applied.
#
set -euo pipefail
IFS=$'\n\t'

REAL_USER="${SUDO_USER:-$USER}"
USER_CONFIG_DIR="/home/$REAL_USER/.config"

if [ "$(id -u)" -ne 0 ]; then
    echo -e "\e[31m[ERROR] This script must be run with sudo.\e[0m" >&2
    exit 1
fi

echo -e "\e[34m[INFO]\e[0m Commencing background workspace checks for: $REAL_USER"

# ----------------------------------------------------
# 1. Kill & Hard-Mask Deep Disk Indexing (Baloo)
# ----------------------------------------------------
if [ "$REAL_USER" != "root" ] && ! systemctl --user --machine="${REAL_USER}@" is-enabled kde-baloo.service 2>&1 | grep -q 'masked'; then
    echo -e "\e[34m[INFO]\e[0m Eliminating background file content indexing..."
    if command -v balooctl6 &>/dev/null; then
        sudo -u "$REAL_USER" balooctl6 purge || true
        sudo -u "$REAL_USER" balooctl6 disable || true
    fi
    sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$REAL_USER")" \
         DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" \
         systemctl --user mask kde-baloo.service || true
else
    echo -e "\e[32m[OK]\e[0m Baloo file indexing is already hard-masked."
fi

# ----------------------------------------------------
# 2. Balanced App Launcher Search (GNOME Style)
# ----------------------------------------------------
KRUNNER_FILE="$USER_CONFIG_DIR/krunnerrc"
if [ ! -f "$KRUNNER_FILE" ] || ! grep -q "shellEnabled=true" "$KRUNNER_FILE" || ! grep -q "HistoryEnabled=false" "$KRUNNER_FILE"; then
    echo -e "\e[34m[INFO]\e[0m Setting up instant application and settings lookups..."
    mkdir -p "$USER_CONFIG_DIR"
    cat << 'EOF' > "$KRUNNER_FILE"
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
    chown "$REAL_USER:$REAL_USER" "$KRUNNER_FILE"
else
    echo -e "\e[32m[OK]\e[0m KRunner configurations match target state."
fi

# ----------------------------------------------------
# 3. Streamlined KDE Application & Service Purge
# ----------------------------------------------------
KDE_DEBLOAT_LIST=(
    # Core background infrastructure engines
    "akonadi-server" "akregator" "kaddressbook" "kmail" "kontact" 
    "korganizer" "ktnef" "neochat" "kleopatra" "plasma-discover" 
    "plasma-discover-notifier" "plasma-welcome"

    # Games
    "kmahjongg" "kmines" "kpat"

    # Confirmed heavy pre-installed desktop utilities
    "dragon" "elisa-player" "kcharselect" "kfind" "khelpcenter" 
    "kmouth" "kolourpaint" "krfb" "krdc" "kamoso" "qrca" "filelight" "skanpage"

    # Redundant GUI Crash & Diagnostics Frameworks
    "drkonqi" "drkonqi-coredump-gui" "kuserfeedback"
)

INSTALLED_DEBLOAT=()
for pkg in "${KDE_DEBLOAT_LIST[@]}"; do
    if rpm -q "$pkg" &>/dev/null; then
        INSTALLED_DEBLOAT+=("$pkg")
    fi
done

if [ ${#INSTALLED_DEBLOAT[@]} -gt 0 ]; then
    echo -e "\e[34m[INFO]\e[0m Running targeted DNF debloat transaction..."
    dnf remove -y "${INSTALLED_DEBLOAT[@]}"
    dnf autoremove -y
    dnf clean all
else
    echo -e "\e[32m[OK]\e[0m Target applications are already purged from the system."
fi

# ----------------------------------------------------
# 4. Telemetry Lockout
# ----------------------------------------------------
FEEDBACK_FILE="$USER_CONFIG_DIR/plasma-user-feedback"
if [ -f /etc/xdg/UserFeedbackConsole.conf ] || [ ! -f "$FEEDBACK_FILE" ] || ! grep -q "SubmissionLevel=0" "$FEEDBACK_FILE"; then
    echo -e "\e[34m[INFO]\e[0m Shutting down system analytics reporting..."
    rm -f /etc/xdg/UserFeedbackConsole.conf || true
    sudo -u "$REAL_USER" kwriteconfig6 --file "$FEEDBACK_FILE" --group "UserFeedback" --key "SubmissionLevel" "0"
else
    echo -e "\e[32m[OK]\e[0m Telemetry data locks are already active."
fi

# ----------------------------------------------------
# 5. Lock Down Activity Tracking & Recent Files Loops
# ----------------------------------------------------
ACTIVITY_FILE="$USER_CONFIG_DIR/kactivitymanagerd-pluginsrc"
GLOBALS_FILE="$USER_CONFIG_DIR/kdeglobals"

NEED_TRACKING_LOCK=false
if [ ! -f "$ACTIVITY_FILE" ] || ! grep -q "enabled=false" "$ACTIVITY_FILE"; then NEED_TRACKING_LOCK=true; fi
if [ ! -f "$GLOBALS_FILE" ] || ! grep -q "MaxEntries=0" "$GLOBALS_FILE"; then NEED_TRACKING_LOCK=true; fi

if [ "$NEED_TRACKING_LOCK" = true ]; then
    echo -e "\e[34m[INFO]\e[0m Disabling background activity tracking loops..."
    sudo -u "$REAL_USER" kwriteconfig6 --file "$ACTIVITY_FILE" --group "Plugin-org.kde.ActivityManager.Resources.Scoring" --key "enabled" "false"
    sudo -u "$REAL_USER" kwriteconfig6 --file "$GLOBALS_FILE" --group "RecentDocuments" --key "MaxEntries" "0"
else
    echo -e "\e[32m[OK]\e[0m Activity tracking and shortcut logs are already locked down."
fi

# ----------------------------------------------------
# 6. Silence Background Crash Reporters (DrKonqi)
# ----------------------------------------------------
DRKONQI_FILE="$USER_CONFIG_DIR/drkonqirc"
if [ ! -f "$DRKONQI_FILE" ] || ! grep -q "Enabled=false" "$DRKONQI_FILE"; then
    echo -e "\e[34m[INFO]\e[0m Disabling background crash diagnostics..."
    sudo -u "$REAL_USER" kwriteconfig6 --file "$DRKONQI_FILE" --group "DrKonqi" --key "Enabled" "false"
else
    echo -e "\e[32m[OK]\e[0m Background crash diagnostics are already silenced."
fi

echo -e "\e[32m[OK]\e[0m Optimization state verified. Processing complete."
