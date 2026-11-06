#!/usr/bin/env bash

# setup-bangla-fonts.sh — Install Noto Bengali fonts (Fedora 44+)
#
# Usage:
#   ./setup-bangla-fonts.sh [--dry-run] [--yes] [--help]
#
# Exit codes: 0 ok, 1 error, 2 aborted.
# Safe to re-run. Writes conf.d/99-bangla.conf. Fonts only, no input method.

set -euo pipefail
IFS=$'\n\t'

# 0. Config
readonly FONT_PACKAGES=(
    google-noto-sans-bengali-fonts
    google-noto-serif-bengali-fonts
)
readonly FONTCONF_DIR="$HOME/.config/fontconfig/conf.d"
readonly FONTCONF_FILE="$FONTCONF_DIR/99-bangla.conf"

DRY_RUN=false
ASSUME_YES=false

# 1. Helpers
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'
log()     { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()      { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
die()     { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }

run() {
    local IFS=' '
    log "→ $*"
    if $DRY_RUN; then return 0; fi
    "$@"
}

usage() {
    sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
    echo ""
    echo "Options:"
    echo "  --dry-run   Print steps without changing the system"
    echo "  --yes, -y   Skip confirmation prompts"
    echo "  --help, -h  Show this help"
    exit 0
}

# 2. Pre-flight guards
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run) DRY_RUN=true ;;
            --yes|-y)  ASSUME_YES=true ;;
            --help|-h) usage ;;
            *) die "Unknown argument: $1 (try --help)" ;;
        esac
        shift
    done
}

# 3. Steps
step_fonts() {
    log "Installing Noto Bengali packages..."
    run sudo dnf install -y "${FONT_PACKAGES[@]}"
}

step_fontconfig() {
    log "Writing fontconfig snippet ($FONTCONF_FILE)..."
    if $DRY_RUN; then
        run mkdir -p "$FONTCONF_DIR"
        return 0
    fi
    mkdir -p "$FONTCONF_DIR"
    cat > "$FONTCONF_FILE" <<'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
    <match>
        <test name="lang" compare="contains"><string>bn</string></test>
        <test name="family"><string>sans-serif</string></test>
        <edit name="family" mode="prepend"><string>Noto Sans Bengali</string></edit>
    </match>
    <match>
        <test name="lang" compare="contains"><string>bn</string></test>
        <test name="family"><string>serif</string></test>
        <edit name="family" mode="prepend"><string>Noto Serif Bengali</string></edit>
    </match>
    <match>
        <test name="lang" compare="contains"><string>bn</string></test>
        <test name="family"><string>monospace</string></test>
        <edit name="family" mode="prepend"><string>Noto Sans Bengali</string></edit>
    </match>
</fontconfig>
EOF
    ok "fontconfig snippet written"
}

step_cache() {
    log "Rebuilding font cache..."
    run fc-cache -f
}

step_verify() {
    log "Verifying Bengali fonts..."
    if $DRY_RUN; then
        run fc-list :lang=bn family
        return 0
    fi
    fc-list :lang=bn family | sort -u | sed 's/^/  /'
    local match
    match="$(fc-match 'sans-serif:lang=bn' 2>/dev/null || true)"
    echo "  fc-match sans-serif:lang=bn -> $match"
}

# 4. Main
main() {
    parse_args "$@"
    log "Installing Bangla fonts..."
    step_fonts
    step_fontconfig
    step_cache
    step_verify
    ok "Setup complete. Restart the browser."
    log "For typing Bangla, install IBus Avro or OpenBangla."
}

main "$@"
