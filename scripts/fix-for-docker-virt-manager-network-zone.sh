#!/bin/bash
set -euo pipefail

# ==============================
# Docker & Virt-Manager Network Zone Fix
# Purpose: Allow docker0 and virbr0 to share networking without firewall conflicts.
# Usage:
#   ./docker-virt-manager-network-fix-ux.sh       # interactive mode
#   ./docker-virt-manager-network-fix-ux.sh --apply   # apply fix directly
#   ./docker-virt-manager-network-fix-ux.sh --reverse # reverse fix directly
#   ./docker-virt-manager-network-fix-ux.sh --status  # show trusted zone status
# ==============================

CYAN="\033[0;36m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

log_info()    { echo -e "${CYAN}[INFO]${RESET}    $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET}    $1"; }
log_success() { echo -e "${GREEN}[OK]${RESET}      $1"; }
log_error()   { echo -e "${RED}[ERROR]${RESET}   $1"; }

check_interface() {
    ip link show "$1" >/dev/null 2>&1
}

check_interfaces_exist() {
    if check_interface docker0 && check_interface virbr0; then
        return 0
    else
        return 1
    fi
}

check_requirements() {
    log_info "Checking for docker0 and virbr0 interfaces..."
    if check_interfaces_exist; then
        log_success "Both docker0 and virbr0 exist."
    else
        log_error "docker0 and/or virbr0 not found."
        log_warn "Ensure Docker and Virt-Manager are running."
        exit 1
    fi
}

apply_fix() {
    check_requirements
    log_info "Purpose: Allow Docker & Virt-Manager to share networking without firewall conflicts."
    confirm_action "Add docker0 and virbr0 to trusted zone?"
    sudo firewall-cmd --permanent --zone=trusted --add-interface=virbr0 || log_warn "virbr0 already in trusted zone."
    sudo firewall-cmd --permanent --zone=trusted --add-interface=docker0 || log_warn "docker0 already in trusted zone."
    sudo firewall-cmd --reload
    log_success "Fix applied successfully."
    show_status
}

reverse_fix() {
    check_requirements
    log_info "Purpose: Reverse Docker & Virt-Manager firewall fix."
    confirm_action "Remove docker0 and virbr0 from trusted zone?"
    sudo firewall-cmd --permanent --zone=trusted --remove-interface=virbr0 || log_warn "virbr0 not in trusted zone."
    sudo firewall-cmd --permanent --zone=trusted --remove-interface=docker0 || log_warn "docker0 not in trusted zone."
    sudo firewall-cmd --reload
    log_success "Fix reversed successfully."
    show_status
}

show_status() {
    log_info "Current trusted zone interfaces:"
    sudo firewall-cmd --zone=trusted --list-interfaces || echo "No interfaces found in trusted zone."
}

confirm_action() {
    read -rp "$1 (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        return 0
    else
        log_warn "Operation cancelled."
        exit 0
    fi
}

interactive_menu() {
    echo "------------------------------------------"
    echo -e "${CYAN}Docker & Virt-Manager Network Zone Fix${RESET}"
    echo "Purpose: Let docker0 and virbr0 share networking without firewall conflicts."
    echo "Goal: Make your Windows VM (Virt-Manager) and Docker containers work side-by-side."
    echo "------------------------------------------"

    check_requirements

    while true; do
        echo ""
        echo "Choose an action:"
        echo "1) Apply fix (add docker0 & virbr0 to trusted zone)"
        echo "2) Reverse fix (remove docker0 & virbr0 from trusted zone)"
        echo "3) Show network interfaces"
        echo "4) Show trusted zone status"
        echo "5) Quit"
        read -rp "Choice: " choice

        case "$choice" in
            1) apply_fix ;;
            2) reverse_fix ;;
            3) ip link show ;;
            4) show_status ;;
            5) exit 0 ;;
            *) log_warn "Invalid choice." ;;
        esac
    done
}

print_help() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  --apply    Apply the Docker & Virt-Manager network fix"
    echo "  --reverse  Reverse the Docker & Virt-Manager network fix"
    echo "  --status   Show trusted zone status"
    echo "  --help     Show this help message"
}

main() {
    if [[ $# -gt 1 ]]; then
        print_help
        exit 1
    fi

    case "${1:-}" in
        --apply) apply_fix ;;
        --reverse) reverse_fix ;;
        --status) show_status ;;
        --help) print_help ;;
        "") interactive_menu ;;
        *) print_help ;;
    esac
}

main "$@"
