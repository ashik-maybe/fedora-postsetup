#!/usr/bin/env bash
#
# Fedora Post Setup Script
# Target: Fedora Workstation (and other mutable Fedora flavors)
#
# This script applies optimizations for a cleaner OS.
#
# Usage:
#   sudo ./fedora-ultimate-setup.sh
#   sudo ./fedora-ultimate-setup.sh --yes   # auto-confirm everything
#   ./fedora-ultimate-setup.sh --dry-run   # preview without changes
#
set -euo pipefail
IFS=$'\n\t'

SCRIPT_NAME="$(basename "$0")"
DRY_RUN=false
AUTO_YES=false

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
    error "This script requires root privileges. Re-run with sudo."
    exit 1
  fi
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
    --yes|-y|--assume-yes) AUTO_YES=true; shift ;;
    --help|-h)
      echo "Usage: sudo $SCRIPT_NAME [--dry-run] [--yes]"
      exit 0 ;;
    *) warn "Unknown option: $1"; shift ;;
  esac
done

ensure_root # Ensure root privileges early

### Configuration ###
REPOS_TO_REMOVE=(
  "copr:copr.fedorainfracloud.org/phracek/PyCharm"
  "rpmfusion-nonfree-nvidia-driver"
  "rpmfusion-nonfree-steam"
  "fedora-cisco-openh264"
  "google-chrome"
)

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

pkg_installed() {
  dnf list installed "$1" &>/dev/null
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
  info "Checking packages to remove..."
  declare -a to_remove=()
  for pkg in "${PACKAGES_TO_REMOVE[@]}"; do
    if pkg_installed "$pkg"; then
      to_remove+=("$pkg")
    fi
  done
  if [ ${#to_remove[@]} -eq 0 ]; then
    info "No target packages installed."
    return
  fi
  echo "Packages to remove:"
  for p in "${to_remove[@]}"; do echo "  - $p"; done
  confirm_or_exit "Remove these packages? (y/N): "
  safe_eval "dnf remove -y ${to_remove[*]}"
  success "Package removal done."
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
    safe_eval "dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-\$(rpm -E %fedora).noarch.rpm"
  fi
  if ! repo_file_matches "rpmfusion-nonfree" >/dev/null; then
    safe_eval "dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-\$(rpm -E %fedora).noarch.rpm"
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

### Interactive menu ###
echo "${BOLD}Fedora Lean Setup${NORMAL}"
echo "Target: Fedora Workstation (also works on other Fedora editions)."
echo
echo "Available actions:"
echo " 1) Repository cleanup"
echo " 2) Package removal"
echo " 3) Optimize DNF config"
echo " 4) Add RPM Fusion repos"
echo " 5) Swap ffmpeg-free -> ffmpeg"
echo " 6) System upgrade"
echo " 7) Enable fstrim.timer"
echo " 8) Post-install cleanup"
echo " 9) Clean dnf cache"
echo

declare -A ACTIONS=(
  [repo_cleanup]=false
  [package_removal]=false
  [optimize_dnf_conf]=false
  [add_third_party_repos]=false
  [swap_ffmpeg]=false
  [upgrade_system]=false
  [enable_fstrim]=false
  [post_cleanup]=false
  [clean_dnf_cache]=false
)

if ! $AUTO_YES && ! $DRY_RUN; then
  printf "Select actions (e.g. '1 3 6' or 'all'): "
  read -r selection
  if [[ "$selection" =~ ^[Aa]ll$ ]]; then
    for k in "${!ACTIONS[@]}"; do ACTIONS[$k]=true; done
  else
    for num in $selection; do
      case "$num" in
        1) ACTIONS[repo_cleanup]=true ;;
        2) ACTIONS[package_removal]=true ;;
        3) ACTIONS[optimize_dnf_conf]=true ;;
        4) ACTIONS[add_third_party_repos]=true ;;
        5) ACTIONS[swap_ffmpeg]=true ;;
        6) ACTIONS[upgrade_system]=true ;;
        7) ACTIONS[enable_fstrim]=true ;;
        8) ACTIONS[post_cleanup]=true ;;
        9) ACTIONS[clean_dnf_cache]=true ;;
      esac
    done
  fi
else
  for k in "${!ACTIONS[@]}"; do ACTIONS[$k]=true; done
fi

echo
info "Summary of selected actions:"
for k in "${!ACTIONS[@]}"; do printf "  %-20s : %s\n" "$k" "${ACTIONS[$k]}"; done
echo

confirm_or_exit "Proceed with these actions? (y/N): "

start=$(date +%s)

${ACTIONS[repo_cleanup]}      && action_repo_cleanup
${ACTIONS[package_removal]}   && action_package_removal
${ACTIONS[optimize_dnf_conf]} && action_optimize_dnf_conf
${ACTIONS[add_third_party_repos]} && action_add_third_party_repos
${ACTIONS[swap_ffmpeg]}       && action_swap_ffmpeg
${ACTIONS[upgrade_system]}    && action_system_upgrade
${ACTIONS[enable_fstrim]}     && action_enable_fstrim
${ACTIONS[post_cleanup]}      && action_post_cleanup
${ACTIONS[clean_dnf_cache]}   && action_clean_dnf_cache

end=$(date +%s)
elapsed=$((end-start))
success "Fedora Lean Setup completed in ${elapsed}s."
