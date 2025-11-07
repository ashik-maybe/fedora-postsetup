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
AUTO_YES=true

if [ -t 1 ]; then
  RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; BLUE=$'\e[34m'; BOLD=$'\e[1m'; NORMAL=$'\e[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NORMAL=''
fi

info() { printf '%b %s\n' "${BLUE}[INFO]${NORMAL} $*"; }
success() { printf '%b %s\n' "${GREEN}[OK]${NORMAL} $*"; }
warn() { printf '%b %s\n' "${YELLOW}[WARN]${NORMAL} $*"; }
error() { printf '%b %s\n' "${RED}[ERROR]${NORMAL} $*"; }

confirm_or_exit() {
  local prompt="${1:-Proceed? (y/N): }"
  if $AUTO_YES; then
    info "Auto-confirm enabled; proceeding."
    return 0
  fi
  printf "%s" "$prompt"
  read -r -n1 REPLY
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    error "User aborted."
    exit 1
  fi
}

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
  eval "$@"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --help|-h)
      echo "Usage: $SCRIPT_NAME [--dry-run]"
      exit 0 ;;
    *) warn "Unknown option: $1"; shift ;;
  esac
done

if [ -z "${FEDORA_SETUP_CONFIRMED:-}" ]; then
  echo "${BOLD}Fedora Lean Setup${NORMAL}"
  echo "This script will perform the following actions automatically:"
  echo "  - Clean up specific repositories"
  echo "  - Remove a list of default packages (firefox*, libreoffice-*, gnome-*, etc.)"
  echo "  - Optimize DNF configuration"
  echo "  - Add RPM Fusion repositories"
  echo "  - Swap ffmpeg-free for ffmpeg"
  echo "  - Upgrade the system"
  echo "  - Enable fstrim.timer"
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

ensure_root "$@"

REPOS_TO_REMOVE=(
  "_copr:copr.fedorainfracloud.org:phracek:PyCharm"
  "fedora-cisco-openh264"
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
)

DNF_CONF_CONTENT=$(cat <<'EOF'
[main]
gpgcheck=True
installonly_limit=3
clean_requirements_on_remove=True
fastestmirror=True
max_parallel_downloads=10
timeout=15
retries=2
skip_if_unavailable=True
best=True
keepcache=False
color=auto
errorlevel=1
EOF
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
  echo "Packages to remove (or already removed):"
  for p in "${PACKAGES_TO_REMOVE[@]}"; do echo "  - $p"; done
  local cmd="dnf remove -y"
  for pkg in "${PACKAGES_TO_REMOVE[@]}"; do
    cmd+=" $pkg"
  done
  safe_eval "$cmd"
  success "Package removal attempt completed."
}

action_optimize_dnf_conf() {
  info "Overwriting /etc/dnf/dnf.conf with optimized config."
  if $DRY_RUN; then
    info "[dry-run] would overwrite /etc/dnf/dnf.conf"
    printf '%s\n' "$DNF_CONF_CONTENT" | sed 's/^/    /'
    return
  fi
  echo "$DNF_CONF_CONTENT" > /etc/dnf/dnf.conf
  chmod 644 /etc/dnf/dnf.conf
  success "dnf.conf updated."
  # safe_eval "dnf clean all"
  # success "DNF cache cleared after config update."
}

action_add_third_party_repos() {
  info "Adding RPM Fusion repos using official commands..."
  local fedora_ver
  fedora_ver=$(rpm -E %fedora)
  safe_eval "dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_ver}.noarch.rpm"
  safe_eval "dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_ver}.noarch.rpm"
  success "RPM Fusion repos added."
}

action_swap_ffmpeg() {
  info "Swapping ffmpeg-free -> ffmpeg..."
  safe_eval "dnf swap -y ffmpeg-free ffmpeg --allowerasing" || warn "Swap failed or unnecessary."
}

action_system_upgrade() {
  info "Upgrading system..."
  safe_eval "dnf upgrade -y"
  success "System upgraded."
}

action_enable_fstrim() {
  info "Enabling fstrim.timer..."
  if systemctl is-enabled fstrim.timer &>/dev/null; then
    info "Already enabled."
  else
    safe_eval "systemctl enable --now fstrim.timer"
    success "fstrim.timer enabled."
  fi
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

action_repo_cleanup
action_package_removal
action_optimize_dnf_conf
action_add_third_party_repos
action_swap_ffmpeg
action_system_upgrade
action_enable_fstrim
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
