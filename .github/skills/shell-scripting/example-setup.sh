#!/bin/bash
################################################################################
# Example Module Setup Script
#
# This script demonstrates Luigi shell scripting best practices for module
# installation scripts. Use this as a template when creating new modules.
#
# Usage: sudo ./setup.sh [install|uninstall|status] [--skip-packages]
#
# Author: Luigi Project
# License: MIT
################################################################################

set -e  # Exit on error

# Color output definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Installation paths
MODULE_NAME="example-module"
PYTHON_SCRIPT="example.py"
SERVICE_FILE="example.service"
CONFIG_EXAMPLE="example.conf.example"

INSTALL_BIN="/usr/local/bin/example.py"
INSTALL_SERVICE="/etc/systemd/system/example.service"
INSTALL_CONFIG_DIR="/etc/luigi/sensors/example"
INSTALL_CONFIG="/etc/luigi/sensors/example/example.conf"
LOG_FILE="/var/log/luigi/example.log"

# Module metadata
MODULE_JSON="$SCRIPT_DIR/module.json"

################################################################################
# Logging Functions
################################################################################

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_header() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

################################################################################
# Utility Functions
################################################################################

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        echo "Please run: sudo $0 $*"
        exit 1
    fi
}

# Check required files exist
check_files() {
    log_step "Checking required files..."
    
    local missing_files=0
    
    if [ ! -f "$SCRIPT_DIR/$PYTHON_SCRIPT" ]; then
        log_error "Missing: $PYTHON_SCRIPT"
        missing_files=1
    fi
    
    if [ ! -f "$SCRIPT_DIR/$SERVICE_FILE" ]; then
        log_error "Missing: $SERVICE_FILE"
        missing_files=1
    fi
    
    if [ ! -f "$SCRIPT_DIR/$CONFIG_EXAMPLE" ]; then
        log_error "Missing: $CONFIG_EXAMPLE"
        missing_files=1
    fi
    
    if [ $missing_files -eq 1 ]; then
        log_error "Missing required files"
        return 1
    fi
    
    log_info "All required files present"
    return 0
}

# Get apt packages from module.json
get_apt_packages() {
    local packages=()
    
    if [ -f "$MODULE_JSON" ] && command -v jq >/dev/null 2>&1; then
        # Parse apt_packages array from JSON
        while IFS= read -r pkg; do
            packages+=("$pkg")
        done < <(jq -r '.apt_packages[]? // empty' "$MODULE_JSON" 2>/dev/null)
    fi
    
    echo "${packages[@]}"
}

################################################################################
# Package Management
################################################################################

install_packages() {
    if [ "${SKIP_PACKAGES:-}" = "1" ]; then
        log_info "Skipping package installation (--skip-packages)"
        return 0
    fi
    
    local packages=($(get_apt_packages))
    
    if [ ${#packages[@]} -eq 0 ]; then
        log_info "No packages to install"
        return 0
    fi
    
    log_step "Installing packages: ${packages[*]}"
    
    if apt-get update && apt-get install -y "${packages[@]}"; then
        log_info "Packages installed successfully"
    else
        log_error "Failed to install packages"
        return 1
    fi
}

remove_packages() {
    if [ "${SKIP_PACKAGES:-}" = "1" ]; then
        log_info "Skipping package removal (--skip-packages)"
        return 0
    fi
    
    # Check if purge mode (set by root setup.sh)
    if [ "${LUIGI_PURGE_MODE:-}" = "1" ]; then
        local packages=($(get_apt_packages))
        if [ ${#packages[@]} -gt 0 ]; then
            log_step "Removing packages: ${packages[*]}"
            apt-get purge -y "${packages[@]}" 2>/dev/null || true
            apt-get autoremove -y 2>/dev/null || true
        fi
        return 0
    fi
    
    # Normal uninstall: prompt user
    local packages=($(get_apt_packages))
    
    if [ ${#packages[@]} -eq 0 ]; then
        return 0
    fi
    
    log_warn "The following packages can be removed:"
    for pkg in "${packages[@]}"; do
        echo "  - $pkg"
    done
    
    read -p "Remove these packages? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_step "Removing packages..."
        apt-get purge -y "${packages[@]}" 2>/dev/null || true
        apt-get autoremove -y 2>/dev/null || true
        log_info "Packages removed"
    else
        log_info "Skipping package removal"
    fi
}

################################################################################
# Installation Functions
################################################################################

install_python_script() {
    log_step "Installing Python script..."
    
    if ! cp "$SCRIPT_DIR/$PYTHON_SCRIPT" "$INSTALL_BIN"; then
        log_error "Failed to copy Python script"
        return 1
    fi
    
    if ! chmod 755 "$INSTALL_BIN"; then
        log_error "Failed to set permissions"
        return 1
    fi
    
    log_info "Python script installed: $INSTALL_BIN"
    return 0
}

install_config() {
    log_step "Installing configuration..."
    
    # Create config directory (including parent directories)
    local parent_dir
    parent_dir=$(dirname "$INSTALL_CONFIG_DIR")
    if [ ! -d "$parent_dir" ]; then
        mkdir -p "$parent_dir"
    fi
    
    if [ ! -d "$INSTALL_CONFIG_DIR" ]; then
        if mkdir -p "$INSTALL_CONFIG_DIR"; then
            log_info "Created config directory: $INSTALL_CONFIG_DIR"
        else
            log_error "Failed to create config directory"
            return 1
        fi
    fi
    
    # Check if config already exists
    if [ -f "$INSTALL_CONFIG" ]; then
        log_warn "Config file already exists: $INSTALL_CONFIG"
        read -p "Overwrite existing config? (y/N): " -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping existing config"
            return 0
        fi
    fi
    
    # Copy example config
    if cp "$SCRIPT_DIR/$CONFIG_EXAMPLE" "$INSTALL_CONFIG"; then
        chmod 644 "$INSTALL_CONFIG"
        log_info "Config installed: $INSTALL_CONFIG"
    else
        log_error "Failed to install config"
        return 1
    fi
    
    return 0
}

install_service() {
    log_step "Installing systemd service..."
    
    # Copy service file
    if ! cp "$SCRIPT_DIR/$SERVICE_FILE" "$INSTALL_SERVICE"; then
        log_error "Failed to copy service file"
        return 1
    fi
    
    chmod 644 "$INSTALL_SERVICE"
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable service
    if systemctl enable "$MODULE_NAME"; then
        log_info "Service enabled"
    else
        log_error "Failed to enable service"
        return 1
    fi
    
    # Start service
    if systemctl start "$MODULE_NAME"; then
        log_info "Service started successfully"
    else
        log_error "Failed to start service"
        log_info "Check logs with: journalctl -u $MODULE_NAME -n 50"
        return 1
    fi
    
    return 0
}

################################################################################
# Uninstallation Functions
################################################################################

uninstall_service() {
    log_step "Removing systemd service..."
    
    # Stop service
    if systemctl is-active --quiet "$MODULE_NAME"; then
        systemctl stop "$MODULE_NAME" 2>/dev/null || true
        log_info "Service stopped"
    fi
    
    # Disable service
    if systemctl is-enabled --quiet "$MODULE_NAME" 2>/dev/null; then
        systemctl disable "$MODULE_NAME" 2>/dev/null || true
        log_info "Service disabled"
    fi
    
    # Remove service file
    if [ -f "$INSTALL_SERVICE" ]; then
        rm "$INSTALL_SERVICE"
        log_info "Service file removed"
    fi
    
    # Reload systemd
    systemctl daemon-reload
}

uninstall_python_script() {
    log_step "Removing Python script..."
    
    if [ -f "$INSTALL_BIN" ]; then
        rm "$INSTALL_BIN"
        log_info "Python script removed: $INSTALL_BIN"
    fi
}

uninstall_config() {
    log_step "Removing configuration..."
    
    # Check if purge mode
    if [ "${LUIGI_PURGE_MODE:-}" = "1" ]; then
        # Purge mode: remove config without prompting
        if [ -f "$INSTALL_CONFIG" ]; then
            rm "$INSTALL_CONFIG"
            log_info "Config removed: $INSTALL_CONFIG"
        fi
        
        if [ -d "$INSTALL_CONFIG_DIR" ] && [ -z "$(ls -A "$INSTALL_CONFIG_DIR")" ]; then
            rmdir "$INSTALL_CONFIG_DIR"
            log_info "Config directory removed: $INSTALL_CONFIG_DIR"
        fi
        return 0
    fi
    
    # Normal uninstall: prompt user
    if [ -f "$INSTALL_CONFIG" ]; then
        log_warn "Configuration file exists: $INSTALL_CONFIG"
        read -p "Remove configuration? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm "$INSTALL_CONFIG"
            log_info "Config removed: $INSTALL_CONFIG"
            
            # Remove directory if empty
            if [ -d "$INSTALL_CONFIG_DIR" ] && [ -z "$(ls -A "$INSTALL_CONFIG_DIR")" ]; then
                rmdir "$INSTALL_CONFIG_DIR"
                log_info "Config directory removed: $INSTALL_CONFIG_DIR"
            fi
        else
            log_info "Keeping configuration"
        fi
    fi
}

################################################################################
# Status Function
################################################################################

show_status() {
    log_header "Module Status: $MODULE_NAME"
    
    # Check Python script
    if [ -f "$INSTALL_BIN" ]; then
        log_info "Python script: Installed"
        echo "  Location: $INSTALL_BIN"
    else
        log_warn "Python script: Not installed"
    fi
    
    echo ""
    
    # Check configuration
    if [ -f "$INSTALL_CONFIG" ]; then
        log_info "Configuration: Installed"
        echo "  Location: $INSTALL_CONFIG"
    else
        log_warn "Configuration: Not installed"
    fi
    
    echo ""
    
    # Check service
    if systemctl is-enabled --quiet "$MODULE_NAME" 2>/dev/null; then
        log_info "Service: Enabled"
    else
        log_warn "Service: Not enabled"
    fi
    
    if systemctl is-active --quiet "$MODULE_NAME"; then
        log_info "Service: Running"
        echo "  View logs: journalctl -u $MODULE_NAME -f"
    else
        log_warn "Service: Not running"
        if systemctl is-failed --quiet "$MODULE_NAME" 2>/dev/null; then
            log_error "Service: Failed"
            echo "  View logs: journalctl -u $MODULE_NAME -n 50"
        fi
    fi
    
    echo ""
    
    # Check packages
    local packages=($(get_apt_packages))
    if [ ${#packages[@]} -gt 0 ]; then
        log_info "Required packages:"
        for pkg in "${packages[@]}"; do
            if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
                echo "  ✓ $pkg (installed)"
            else
                echo "  ✗ $pkg (not installed)"
            fi
        done
    fi
    
    echo ""
}

################################################################################
# Main Functions
################################################################################

do_install() {
    log_header "Installing $MODULE_NAME"
    
    check_files || return 1
    
    install_packages || return 1
    install_python_script || return 1
    install_config || return 1
    install_service || return 1
    
    log_header "Installation Complete!"
    log_info "Check status with: sudo $0 status"
    log_info "View logs with: journalctl -u $MODULE_NAME -f"
}

do_uninstall() {
    log_header "Uninstalling $MODULE_NAME"
    
    uninstall_service
    uninstall_python_script
    uninstall_config
    remove_packages
    
    log_header "Uninstallation Complete!"
}

################################################################################
# Main Script
################################################################################

main() {
    # Parse arguments
    ACTION="${1:-install}"
    SKIP_PACKAGES=0
    
    # Parse flags
    shift || true
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-packages)
                SKIP_PACKAGES=1
                export SKIP_PACKAGES
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Usage: sudo $0 [install|uninstall|status] [--skip-packages]"
                exit 1
                ;;
        esac
    done
    
    # Check root permission (except for status)
    if [ "$ACTION" != "status" ]; then
        check_root
    fi
    
    # Execute action
    case $ACTION in
        install)
            do_install
            ;;
        uninstall)
            do_uninstall
            ;;
        status)
            show_status
            ;;
        *)
            log_error "Unknown action: $ACTION"
            echo "Usage: sudo $0 [install|uninstall|status] [--skip-packages]"
            exit 1
            ;;
    esac
}

# Execute main
main "$@"
