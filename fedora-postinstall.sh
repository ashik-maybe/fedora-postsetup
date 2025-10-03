#!/usr/bin/env bash
#
# Fedora Post Setup Script
# Target: Fedora Workstation (and other mutable Fedora flavors)
#
# This script applies optimizations for a cleaner OS.
# This version runs ALL tasks automatically after gaining root privileges.
#
set -euo pipefail
IFS=$'\n\t'

SCRIPT_NAME="$(basename "$0")"
DRY_RUN=false
AUTO_YES=true # Always auto-confirm everything

### Colors / UX ###
if [ -t 1 ]; then
  RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; BLUE=$'\e[34m'; BOLD=$'\e[1m'; NORMAL=$'\e[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NORMAL=''
fi

# Removed logging functions
info() { printf '%b %s\n' "${BLUE}[INFO]${NORMAL} $*"; }
success() { printf '%b %s\n' "${GREEN}[OK]${NORMAL} $*"; }
warn() { printf '%b %s\n' "${YELLOW}[WARN]${NORMAL} $*"; }
error() { printf '%b %s\n' "${RED}[ERROR]${NORMAL} $*"; }

# Always proceed if AUTO_YES is true, otherwise prompt
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
    exec sudo "$0" "$@"
  fi
  # If we get here, we are root
}

safe_eval() {
  if $DRY_RUN; then
    info "[dry-run] $*"
    return 0
  fi
  eval "$@"
}

### CLI parsing ###
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --help|-h)
      echo "Usage: $SCRIPT_NAME [--dry-run]"
      exit 0 ;;
    *) warn "Unknown option: $1"; shift ;;
  esac
done

# Ensure root privileges early, passing original arguments
ensure_root "$@"

### Configuration ###
REPOS_TO_REMOVE=(
  "_copr:copr.fedorainfracloud.org:phracek:PyCharm"
  "rpmfusion-nonfree-nvidia-driver"
  "rpmfusion-nonfree-steam"
  "fedora-cisco-openh264"
  "google-chrome"
)

# List of packages to remove
PACKAGES_TO_REMOVE=(
  "firefox*"
  "libreoffice-*"
  "gnome-boxes"
  "gnome-contacts"
  "gnome-maps"
  "gnome-weather"
  "evolution"
  "rhythmbox"
  "totem"
  "gnome-characters"
  "gnome-calendar"
  "mediawriter"
  "simple-scan"
  "gnome-connections"
  "gnome-backgrounds"
  "gnome-tour"
  "baobab"
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

### Helpers ###
repo_file_matches() {
  local pattern="$1"
  for repofile in /etc/yum.repos.d/*.repo; do
    [ -e "$repofile" ] || continue
    if [[ $(basename "$repofile") =~ $pattern ]] || grep -qiE "$pattern" "$repofile"; then
      echo "$repofile"
    fi
  done
}

### Actions ###
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
  # No confirmation prompt anymore, as AUTO_YES is true
  safe_eval "dnf remove -y ${PACKAGES_TO_REMOVE[*]}"
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
}

action_add_third_party_repos() {
  info "Adding RPM Fusion repos if missing..."
  local fedora_ver
  fedora_ver=$(rpm -E %fedora)

  if ! repo_file_matches "rpmfusion-free" >/dev/null; then
    safe_eval "dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_ver}.noarch.rpm"
  fi
  if ! repo_file_matches "rpmfusion-nonfree" >/dev/null; then
    safe_eval "dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_ver}.noarch.rpm"
  fi
  success "RPM Fusion repos ready."
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

action_clean_dnf_cache() {
  info "Cleaning dnf cache..."
  safe_eval "dnf clean all"
  success "Cache cleaned."
}

### Run ALL actions automatically ###
info "Starting Fedora Lean Setup with ALL actions enabled."
info "No further input required. This will run all tasks."

start=$(date +%s)

action_repo_cleanup
action_package_removal
action_optimize_dnf_conf
action_add_third_party_repos
action_swap_ffmpeg
action_system_upgrade
action_enable_fstrim
action_post_cleanup
action_clean_dnf_cache

end=$(date +%s)
elapsed=$((end-start))
success "Fedora Lean Setup completed in ${elapsed}s."
info "Script finished. Reboot recommended."
