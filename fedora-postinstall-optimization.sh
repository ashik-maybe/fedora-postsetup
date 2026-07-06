#!/usr/bin/env bash
#
# Fedora Workstation Post installation Script
#
# This script applies optimizations for a cleaner OS.
#
set -euo pipefail
IFS=$'\n\t'

SCRIPT_NAME="$(basename "$0")"
DRY_RUN=false
ORIGINAL_ARGS=("$@")

if [ -t 1 ]; then
  RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; BLUE=$'\e[34m'; BOLD=$'\e[1m'; NORMAL=$'\e[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NORMAL=''
fi

err_handler() {
  local exit_code=$?
  error "Script failed at line ${1} (exit code: ${exit_code})"
  error "Command: ${2}"
  exit "$exit_code"
}
trap 'err_handler $LINENO "$BASH_COMMAND"' ERR

info() { printf '%b %s\n' "${BLUE}[INFO]${NORMAL} $*"; }
success() { printf '%b %s\n' "${GREEN}[OK]${NORMAL} $*"; }
warn() { printf '%b %s\n' "${YELLOW}[WARN]${NORMAL} $*"; }
error() { printf '%b %s\n' "${RED}[ERROR]${NORMAL} $*"; }

ensure_root() {
  if [ "$(id -u)" -ne 0 ]; then
    info "This script requires root privileges. Attempting to re-run with sudo..."
    export FEDORA_SETUP_CONFIRMED=1
    exec sudo env FEDORA_SETUP_CONFIRMED="$FEDORA_SETUP_CONFIRMED" "$0" "$@"
  fi
}

safe_eval() {
  if $DRY_RUN; then
    info "[dry-run] $*"
    return 0
  fi
  info "Running: $*"
  eval "$@"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --help|-h)
      echo "Usage: $SCRIPT_NAME [--dry-run]"
      exit 0 ;;
    *) warn "Unknown option: $1"; exit 1 ;;
  esac
done

if [ -z "${FEDORA_SETUP_CONFIRMED:-}" ]; then
  echo "${BOLD}Fedora Lean Setup${NORMAL}"
  echo "This script will perform the following actions automatically:"
  # echo "  - Clean up specific repositories"
  echo "  - Optimize DNF configuration"
  echo "  - Add RPM Fusion repositories"
  echo "  - Install baseline multimedia codecs (ffmpeg swap, gstreamer plugins, openh264)"
  echo "  - Upgrade the system"
  echo "  - Remove a list of default packages (firefox*, libreoffice-*, gnome-*, etc.)"
  echo "  - Perform post-install cleanup"
  echo ""

  if [ "$(id -u)" -ne 0 ]; then
    echo "It requires root privileges via 'sudo'."
  else
    echo "Running with root privileges."
  fi

  read -p "Do you wish to proceed? (y/N): " -n 1 -r REPLY
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      info "User aborted."
      exit 0
  fi
fi

ensure_root "${ORIGINAL_ARGS[@]}"

REPOS_TO_REMOVE=(
  "_copr:copr.fedorainfracloud.org:phracek:PyCharm"
  "google-chrome"
  "rpmfusion-nonfree-nvidia-driver"
  "rpmfusion-nonfree-steam"
)

PACKAGES_TO_REMOVE=(
"baobab"
"evolution"
"firefox*"
"gnome-abrt"
"gnome-backgrounds"
"gnome-boxes"
"gnome-calendar"
"gnome-calculator"
"gnome-characters"
"gnome-clocks"
"gnome-connections"
"gnome-contacts"
"gnome-disk-utility"
"gnome-font-viewer"
"gnome-maps"
"gnome-shell-extension-apps-menu"
"gnome-shell-extension-background-logo"
"gnome-shell-extension-launch-new-instance"
"gnome-shell-extension-places-menu"
"gnome-shell-extension-window-list"
"gnome-software"
"gnome-tour"
"gnome-user-docs"
"gnome-weather"
"libreoffice-*"
"mediawriter"
"rhythmbox"
"seahorse"
"showtime"
"simple-scan"
"totem"
"yelp"
"decibels"
"snapshot"
"gnome-logs"
# for KDE Plasma
"akregator"
"dragon"
"elisa-player"
"juk"
"kaddressbook"
"kbrickbuster"
"kblocks"
"kbounce"
"kcharselect"
"kdiamond"
"kfind"
"kfloppy"
"kfourinline"
"kget"
"kgoldrunner"
"khelpcenter"
"killbots"
"kiriki"
"klickety"
"klines"
"kmag"
"kmail"
"kmines"
"kmousetool"
"kmouth"
"knetwalk"
"knotes"
"kolf"
"kolourpaint"
"kontact"
"konversation"
"korganizer"
"kpat"
"krecorder"
"krdp"
"kreversi"
"kshisen"
"kspaceduel"
"ksquares"
"ksudoku"
"kmahjongg"
"kteatime"
"ktimer"
"ktrip"
"ktorrent"
"ktuberling"
"kubrick"
"kweather"
"lskat"
"palapeli"
"picmi"
"plasma-welcome"
"kde-connect"
"skanpage"
"neochat"
"krfb"
"krdc"
"kamoso"
"qrca"
"kleopatra"
"kwalletmanager5"
"filelight"
"kcalc"
"okular"
"ark"
"akonadi-server"
"plasma-discover"
"plasma-discover-notifier"
"PackageKit"
"PackageKit-glib"
# XFCE
"asunder"
"catfish"
"claws-mail"
"dnfdragora"
"evince"
"geany"
"gigolo"
"hexchat"
"parole"
"pidgin"
"pragha"
"simple-scan"
"transmission-gtk"
"xfce4-dict"
"xfburn"
)

repo_file_matches() {
  local pattern="$1"
  for repofile in /etc/yum.repos.d/*.repo; do
    [ -e "$repofile" ] || continue
    if [[ $(basename "$repofile") =~ $pattern ]] || grep -qiE "$pattern" "$repofile"; then
      echo "$repofile"
    fi
  done
}

action_repo_cleanup() {
  info "Cleaning up repositories..."
  for pattern in "${REPOS_TO_REMOVE[@]}"; do
    matches=$(repo_file_matches "$pattern" || true)
    if [ -z "$matches" ]; then
      info "No repo match for '$pattern'"
      continue
    fi
    for file in $matches; do
      if $DRY_RUN; then
        info "[dry-run] rm '$file'"
      else
        rm -f "$file" && success "Removed $file"
      fi
    done
  done
  success "Repository cleanup done."
}

action_package_removal() {
  info "Attempting to remove packages..."
  local cmd="dnf remove -y"
  for pkg in "${PACKAGES_TO_REMOVE[@]}"; do
    cmd+=" $pkg"
  done
  # Appended || true so missing DE desktop environment packages won't crash execution
  safe_eval "$cmd" || warn "Some packages weren't present or skipped."
  success "Package removal attempt completed."
}

action_optimize_dnf_conf() {
  info "Optimizing DNF configuration..."
  
  # Determine target destination (Fallback gracefully if modern DNF5 directory isn't present)
  local config_file="/etc/dnf/dnf.conf"
  if [ -d "/etc/dnf/libdnf5.conf.d" ]; then
    config_file="/etc/dnf/libdnf5.conf.d/99-performance.conf"
  fi

  if $DRY_RUN; then
    info "[dry-run] would optimize performance flags in $config_file"
    return
  fi

  # Ensure target directory structure exists
  mkdir -p "$(dirname "$config_file")"

  # Initialize drop-in files with standard [main] identifier section if needed
  if [ ! -f "$config_file" ] || ! grep -q "^\[main\]" "$config_file"; then
    echo "[main]" > "$config_file"
  fi

  # Optimized properties configurations
  local options=(
    "max_parallel_downloads=10"
    "fastestmirror=True"
    "metadata_expire=48h"
    "deltarpm=True"
    "installonly_limit=3"
    "clean_requirements_on_remove=True"
  )

  for option in "${options[@]}"; do
    local key="${option%=*}"
    # Safely swap out lines matching standard property definitions or push new updates
    if grep -q "^$key=" "$config_file"; then
      sed -i "s|^$key=.*|$option|" "$config_file"
    else
      echo "$option" >> "$config_file"
    fi
  done

  # Clear local cache states so changes get indexed properly
  dnf clean all &>/dev/null || true

  success "dnf.conf performance flags updated in $config_file and cache refreshed."
}

action_add_third_party_repos() {
  info "Adding RPM Fusion repos using official commands..."
  local fedora_ver
  fedora_ver=$(rpm -E %fedora)
  safe_eval "dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_ver}.noarch.rpm"
  safe_eval "dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_ver}.noarch.rpm"
  success "RPM Fusion repos added."
}

action_install_base_codecs() {
  info "Installing baseline multimedia codecs..."
  
  # Enable OpenH264 & install WebRTC compatibility components
  safe_eval "dnf config-manager setopt fedora-cisco-openh264.enabled=1"
  safe_eval "dnf install -y gstreamer1-plugin-openh264 mozilla-openh264"
  
  # Complete ffmpeg-free to full ffmpeg migration
  safe_eval "dnf swap -y ffmpeg-free ffmpeg --allowerasing" || warn "FFmpeg swap unnecessary or already handled."
  
  # Comprehensive multimedia complements group installation
  safe_eval "dnf update -y @multimedia --setopt=\"install_weak_deps=False\" --exclude=PackageKit-gstreamer-plugin"
  success "Baseline codecs configuration finished."
}

action_system_upgrade() {
  info "Upgrading system..."
  safe_eval "dnf upgrade -y"
  success "System upgraded."
}

action_post_cleanup() {
  info "Cleaning unused packages and flatpaks..."
  safe_eval "dnf autoremove -y"
  if command -v flatpak &>/dev/null; then
    safe_eval "flatpak uninstall --unused -y"
  fi
  success "Cleanup done."
}

start=$(date +%s)

action_optimize_dnf_conf
action_add_third_party_repos
action_install_base_codecs
action_package_removal
action_system_upgrade
action_post_cleanup

end=$(date +%s)
elapsed=$((end-start))

hours=$((elapsed / 3600))
minutes=$(( (elapsed % 3600) / 60 ))
seconds=$((elapsed % 60))

time_str=""
if [ $hours -gt 0 ]; then
    time_str="${hours}h "
fi
if [ $minutes -gt 0 ]; then
    time_str="${time_str}${minutes}m "
fi
time_str="${time_str}${seconds}s"

success "Fedora Workstation optimizations completed in ${time_str}."
info "Script finished. Reboot recommended."
