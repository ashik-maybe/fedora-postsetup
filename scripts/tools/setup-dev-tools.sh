#!/usr/bin/env bash

# setup-dev-tools.sh — Install developer CLI tools on Fedora 44+ (pure dnf).
#
# Three tiers, all from the official Fedora repositories:
#   core    The everyday modern CLI core (installed by default)
#   power   Web/API, YAML, benchmarks, docs, better diffs (--power)
#   build   Compilers, build systems, debuggers, language runtimes (--build)
#
# Usage:
#   ./setup-dev-tools.sh [--power] [--build] [--all] [--dry-run] [--yes] [--help]
#
# Exit codes: 0 ok · 1 error · 2 aborted
# Idempotent: dnf skips already-installed packages; safe to re-run.

set -euo pipefail
IFS=$'\n\t'

# 0. Config
# Package names are the real Fedora ones (du-dust, wget2, fd-find, git-delta,
# plocate, rust), not the upstream tool names.
readonly CORE_TOOLS=(
    gh git jq ripgrep bat fd-find fzf eza zoxide
    duf du-dust btop tmux curl wget2 fastfetch tldr gum
)
readonly POWER_TOOLS=(
    httpie yq hyperfine tokei tree ncdu htop plocate git-delta vhs
)
readonly BUILD_TOOLS=(
    gcc gcc-c++ make cmake ninja-build meson pkgconf-pkg-config
    gdb lldb rust cargo golang nodejs python3-pip sqlite
)

# Package → binary to verify after install. Binaries that differ from the
# package name are listed; "git" and friends are checked by command name only.
declare -A BIN=(
    [gh]=gh [git]=git [jq]=jq [ripgrep]=rg [bat]=bat [fd-find]=fd [fzf]=fzf
    [eza]=eza [zoxide]=zoxide [duf]=duf [du-dust]=dust [btop]=btop [tmux]=tmux
    [curl]=curl [wget2]=wget2 [fastfetch]=fastfetch [tldr]=tldr [gum]=gum
    [httpie]=http [yq]=yq [hyperfine]=hyperfine [tokei]=tokei [tree]=tree
    [ncdu]=ncdu [htop]=htop [plocate]=locate [git-delta]=delta [vhs]=vhs
    [gcc]=gcc [gcc-c++]=g++ [make]=make [cmake]=cmake [ninja-build]=ninja
    [meson]=meson [pkgconf-pkg-config]=pkg-config [gdb]=gdb [lldb]=lldb
    [rust]=rustc [cargo]=cargo [golang]=go [nodejs]=node [python3-pip]=pip
    [sqlite]=sqlite3
)

POWER=false
BUILD=false
ALL=false
DRY_RUN=false
ASSUME_YES=false

# 1. Helpers
GREEN="\e[32m"
BLUE="\e[34m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"
banner() { echo -e "\n${BLUE}==> $1${RESET}"; }
ok() { echo -e "${GREEN}[OK]${RESET} $1"; }
info() { echo -e "${YELLOW}[INFO]${RESET} $1"; }
warn() { echo -e "${YELLOW}[!]${RESET} $1"; }
die() {
    echo -e "${RED}[ERROR]${RESET} $1" >&2
    exit 1
}

run() {
    local IFS=' '
    info "→ $*"
    if $DRY_RUN; then return 0; fi
    "$@"
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install developer CLI tools from the official Fedora repositories.

Options:
  --power     Add the power tier (httpie, yq, hyperfine, git-delta, ...)
  --build     Add the build tier (gcc, cmake, rust, golang, nodejs, ...)
  --all       Install every tier
  --dry-run   Print the packages without changing the system
  --yes, -y   Skip the confirmation prompt
  --help, -h  Show this help

The default installs the core tier only.
EOF
    exit 0
}

confirm_or_abort() {
    local reply
    read -p "$1 [Y/n]: " -n 1 -r reply || true
    echo
    [[ "$reply" =~ ^[Nn]$ ]] && {
        info "Aborted."
        exit 2
    }
    return 0
}

# 2. Pre-flight guards
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --power) POWER=true ;;
        --build) BUILD=true ;;
        --all) ALL=true ;;
        --dry-run) DRY_RUN=true ;;
        --yes | -y) ASSUME_YES=true ;;
        --help | -h) usage ;;
        *) die "Unknown argument: $1 (try --help)" ;;
        esac
        shift
    done
}

require_fedora() {
    [[ -f /etc/fedora-release ]] ||
        warn "Not Fedora (/etc/fedora-release missing) — packages may not resolve."
}

require_sudo() {
    $DRY_RUN && return 0
    command -v sudo >/dev/null ||
        die "sudo is required (this script installs packages)"
}

# 3. Steps
step_plan() {
    local IFS=' '
    banner "Selection"
    local -a tools=("${CORE_TOOLS[@]}")
    if $ALL || $POWER; then tools+=("${POWER_TOOLS[@]}"); fi
    if $ALL || $BUILD; then tools+=("${BUILD_TOOLS[@]}"); fi
    echo "  core tier:  ${CORE_TOOLS[*]}"
    if $ALL || $POWER; then echo "  power tier: ${POWER_TOOLS[*]}"; fi
    if $ALL || $BUILD; then echo "  build tier: ${BUILD_TOOLS[*]}"; fi
    echo ""
    echo "  total: ${#tools[@]} packages"
    SELECTED=("${tools[@]}")
}

step_install() {
    banner "Install"
    if ! $ASSUME_YES && ! $DRY_RUN; then
        confirm_or_abort "Install ${#SELECTED[@]} packages with dnf?"
    fi
    local -a sudo=()
    if [[ $EUID -ne 0 ]]; then sudo=(sudo); fi
    run "${sudo[@]}" dnf install -y "${SELECTED[@]}"
    $DRY_RUN && {
        info "Dry-run: nothing installed"
        return 0
    }
    ok "dnf finished for ${#SELECTED[@]} packages"
}

step_verify() {
    banner "Verify"
    $DRY_RUN && {
        info "Dry-run: verify skipped"
        return 0
    }
    local pkg bin missing=0
    for pkg in "${SELECTED[@]}"; do
        bin="${BIN[$pkg]:-}"
        if [[ -z "$bin" ]]; then continue; fi
        if command -v "$bin" >/dev/null 2>&1; then
            ok "$bin"
        else
            warn "$pkg installed, but '$bin' is not on PATH"
            missing=$((missing + 1))
        fi
    done
    echo ""
    if ((missing > 0)); then
        die "$missing binary check(s) failed — a package did not install its command"
    fi
    ok "All ${#SELECTED[@]} packages verified"
}

step_done() {
    banner "Done"
    echo "  Fedora uses podman, not docker. To get the docker CLI shim:"
    echo "    sudo dnf install -y podman-docker"
    echo "  Nothing else to do. Re-run this script any time to top up."
}

# 4. Main
main() {
    parse_args "$@"
    require_fedora
    require_sudo
    step_plan
    step_install
    step_verify
    step_done
}

main "$@"
