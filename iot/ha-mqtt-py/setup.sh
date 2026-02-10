#!/bin/bash
# setup.sh - Luigi Home Assistant MQTT Integration (Python) installation

set -euo pipefail

# Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly MODULE_NAME="ha-mqtt-py"
readonly MODULE_CATEGORY="iot"
readonly CONFIG_DIR="/etc/luigi/${MODULE_CATEGORY}/${MODULE_NAME}"
readonly BIN_DIR="/usr/local/bin"
readonly SERVICE_DIR="/etc/systemd/system"
readonly LOG_FILE="/var/log/${MODULE_NAME}.log"

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check root privileges
require_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Install function
install() {
    require_root
    log_info "Installing ${MODULE_NAME}..."
    echo
    
    # Step 1: Check prerequisites
    log_step "Checking prerequisites..."
    if ! command -v python3 &> /dev/null; then
        log_error "python3 not found. Please install python3 first."
        exit 1
    fi
    log_info "✓ python3 found: $(python3 --version)"
    
    # Step 2: Install dependencies
    log_step "Installing Python dependencies..."
    apt-get update -qq
    
    # Try to install via apt first (recommended for system integration)
    if apt-get install -y python3-paho-mqtt &> /dev/null; then
        log_info "✓ Installed python3-paho-mqtt via apt"
    else
        log_warn "Failed to install via apt, trying pip3..."
        apt-get install -y python3-pip
        pip3 install paho-mqtt
        log_info "✓ Installed paho-mqtt via pip3"
    fi
    
    # Step 3: Create directories
    log_step "Creating configuration directory..."
    mkdir -p "${CONFIG_DIR}"
    log_info "✓ Created ${CONFIG_DIR}"
    
    # Step 4: Deploy configuration example
    log_step "Deploying configuration files..."
    cp "${SCRIPT_DIR}/${MODULE_NAME}.conf.example" "${CONFIG_DIR}/"
    chmod 644 "${CONFIG_DIR}/${MODULE_NAME}.conf.example"
    log_info "✓ Deployed config example"
    
    # Copy config if it doesn't exist (preserve existing config)
    if [ ! -f "${CONFIG_DIR}/${MODULE_NAME}.conf" ]; then
        cp "${SCRIPT_DIR}/${MODULE_NAME}.conf.example" "${CONFIG_DIR}/${MODULE_NAME}.conf"
        chmod 600 "${CONFIG_DIR}/${MODULE_NAME}.conf"
        log_info "✓ Created initial config file"
        log_warn "⚠ Please edit ${CONFIG_DIR}/${MODULE_NAME}.conf with your MQTT broker details"
    else
        log_info "✓ Existing config preserved"
    fi
    
    # Step 5: Deploy Python script
    log_step "Deploying application script..."
    cp "${SCRIPT_DIR}/${MODULE_NAME}.py" "${BIN_DIR}/${MODULE_NAME}.py"
    chmod 755 "${BIN_DIR}/${MODULE_NAME}.py"
    log_info "✓ Deployed ${BIN_DIR}/${MODULE_NAME}.py"
    
    # Step 6: Deploy service file
    log_step "Deploying systemd service..."
    cp "${SCRIPT_DIR}/${MODULE_NAME}.service" "${SERVICE_DIR}/${MODULE_NAME}.service"
    chmod 644 "${SERVICE_DIR}/${MODULE_NAME}.service"
    log_info "✓ Deployed service file"
    
    # Step 7: Reload systemd
    log_step "Reloading systemd daemon..."
    systemctl daemon-reload
    log_info "✓ Systemd reloaded"
    
    # Step 8: Enable service (auto-start on boot)
    log_step "Enabling service..."
    systemctl enable "${MODULE_NAME}.service"
    log_info "✓ Service enabled (will start on boot)"
    
    # Step 9: Start service
    log_step "Starting service..."
    if systemctl start "${MODULE_NAME}.service"; then
        log_info "✓ Service started successfully"
    else
        log_error "Failed to start service. Check logs with: journalctl -u ${MODULE_NAME} -n 50"
        exit 1
    fi
    
    # Step 10: Verify installation
    echo
    log_info "═══════════════════════════════════════════════════════════"
    log_info "Installation Complete!"
    log_info "═══════════════════════════════════════════════════════════"
    echo
    log_info "Configuration: ${CONFIG_DIR}/${MODULE_NAME}.conf"
    log_info "Log file: ${LOG_FILE}"
    echo
    log_info "Next steps:"
    echo "  1. Edit config: sudo nano ${CONFIG_DIR}/${MODULE_NAME}.conf"
    echo "  2. Restart service: sudo systemctl restart ${MODULE_NAME}"
    echo "  3. Check status: systemctl status ${MODULE_NAME}"
    echo "  4. View logs: journalctl -u ${MODULE_NAME} -f"
    echo
}

# Uninstall function
uninstall() {
    require_root
    log_info "Uninstalling ${MODULE_NAME}..."
    echo
    
    # Step 1: Stop service
    log_step "Stopping service..."
    if systemctl is-active --quiet "${MODULE_NAME}.service"; then
        systemctl stop "${MODULE_NAME}.service"
        log_info "✓ Service stopped"
    else
        log_info "✓ Service not running"
    fi
    
    # Step 2: Disable service
    log_step "Disabling service..."
    if systemctl is-enabled --quiet "${MODULE_NAME}.service" 2>/dev/null; then
        systemctl disable "${MODULE_NAME}.service"
        log_info "✓ Service disabled"
    else
        log_info "✓ Service not enabled"
    fi
    
    # Step 3: Remove service file
    log_step "Removing service file..."
    if [ -f "${SERVICE_DIR}/${MODULE_NAME}.service" ]; then
        rm -f "${SERVICE_DIR}/${MODULE_NAME}.service"
        log_info "✓ Service file removed"
    fi
    
    # Step 4: Remove Python script
    log_step "Removing application script..."
    if [ -f "${BIN_DIR}/${MODULE_NAME}.py" ]; then
        rm -f "${BIN_DIR}/${MODULE_NAME}.py"
        log_info "✓ Application script removed"
    fi
    
    # Step 5: Reload systemd
    log_step "Reloading systemd daemon..."
    systemctl daemon-reload
    log_info "✓ Systemd reloaded"
    
    # Step 6: Ask about config removal
    echo
    log_warn "Configuration and logs:"
    echo "  Config: ${CONFIG_DIR}"
    echo "  Logs: ${LOG_FILE}"
    echo
    read -p "Remove configuration and logs? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -d "${CONFIG_DIR}" ]; then
            rm -rf "${CONFIG_DIR}"
            log_info "✓ Configuration directory removed"
        fi
        if [ -f "${LOG_FILE}" ]; then
            rm -f "${LOG_FILE}"*  # Also remove rotated logs
            log_info "✓ Log files removed"
        fi
    else
        log_info "✓ Configuration and logs preserved"
    fi
    
    # Step 7: Summary
    echo
    log_info "═══════════════════════════════════════════════════════════"
    log_info "Uninstall Complete!"
    log_info "═══════════════════════════════════════════════════════════"
    echo
}

# Status function
status() {
    log_info "Checking ${MODULE_NAME} status..."
    echo
    
    # Check service file
    if [ -f "${SERVICE_DIR}/${MODULE_NAME}.service" ]; then
        log_info "✓ Service file installed"
    else
        log_error "✗ Service file not found"
        echo "  Run: sudo ./setup.sh install"
        exit 1
    fi
    
    # Check Python script
    if [ -f "${BIN_DIR}/${MODULE_NAME}.py" ]; then
        log_info "✓ Application script installed"
    else
        log_error "✗ Application script not found"
    fi
    
    # Check config file
    if [ -f "${CONFIG_DIR}/${MODULE_NAME}.conf" ]; then
        log_info "✓ Configuration file exists"
        echo "  Location: ${CONFIG_DIR}/${MODULE_NAME}.conf"
    else
        log_warn "⚠ Configuration file not found"
        echo "  Expected: ${CONFIG_DIR}/${MODULE_NAME}.conf"
    fi
    
    # Check service status
    echo
    log_info "Service Status:"
    systemctl status "${MODULE_NAME}.service" --no-pager || true
    
    # Show recent logs
    echo
    log_info "Recent Logs (last 10 lines):"
    if [ -f "${LOG_FILE}" ]; then
        tail -n 10 "${LOG_FILE}" || true
    else
        log_warn "Log file not found: ${LOG_FILE}"
    fi
    
    # Summary
    echo
    log_info "═══════════════════════════════════════════════════════════"
    log_info "Commands:"
    echo "  Start:   sudo systemctl start ${MODULE_NAME}"
    echo "  Stop:    sudo systemctl stop ${MODULE_NAME}"
    echo "  Restart: sudo systemctl restart ${MODULE_NAME}"
    echo "  Logs:    journalctl -u ${MODULE_NAME} -f"
    echo "  Config:  sudo nano ${CONFIG_DIR}/${MODULE_NAME}.conf"
    log_info "═══════════════════════════════════════════════════════════"
    echo
}

# Main
case "${1:-}" in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {install|uninstall|status}"
        echo
        echo "Commands:"
        echo "  install    - Install ${MODULE_NAME} module"
        echo "  uninstall  - Remove ${MODULE_NAME} module"
        echo "  status     - Show installation and service status"
        echo
        exit 1
        ;;
esac
