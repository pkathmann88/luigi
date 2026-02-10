#!/bin/bash
################################################################################
# Mario Motion Detection - Setup Script
#
# This script installs the Mario motion detection service and all resources
# on the current system.
#
# Usage: sudo ./setup.sh [install|uninstall|status]
#
# Author: Luigi Project
# License: MIT
################################################################################

set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="mario.py"
SERVICE_FILE="mario.service"
SOUNDS_ARCHIVE="mario-sounds.tar.gz"

INSTALL_BIN="/usr/local/bin/mario.py"
INSTALL_SERVICE="/etc/systemd/system/mario.service"
INSTALL_SOUNDS="/usr/share/sounds/mario"
LOG_FILE="/var/log/motion.log"

# Logging functions
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

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        echo "Please run: sudo $0 $*"
        exit 1
    fi
}

# Check if files exist
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
    
    if [ ! -f "$SCRIPT_DIR/$SOUNDS_ARCHIVE" ]; then
        log_error "Missing: $SOUNDS_ARCHIVE"
        missing_files=1
    fi
    
    if [ $missing_files -eq 1 ]; then
        log_error "Required files not found in $SCRIPT_DIR"
        exit 1
    fi
    
    log_info "All required files found"
}

# Install dependencies
install_dependencies() {
    log_step "Installing dependencies..."
    
    # Update package list
    log_info "Updating package list..."
    apt-get update -qq || {
        log_error "Failed to update package list"
        exit 1
    }
    
    # Install Python GPIO library
    log_info "Installing python3-rpi.gpio..."
    apt-get install -y python3-rpi.gpio || {
        log_error "Failed to install python3-rpi.gpio"
        exit 1
    }
    
    # Install ALSA utilities
    log_info "Installing alsa-utils..."
    apt-get install -y alsa-utils || {
        log_error "Failed to install alsa-utils"
        exit 1
    }
    
    log_info "Dependencies installed successfully"
}

# Install sound files
install_sounds() {
    log_step "Installing sound files..."
    
    # Create sound directory
    mkdir -p "$INSTALL_SOUNDS" || {
        log_error "Failed to create sound directory"
        exit 1
    }
    
    # Extract sound files
    log_info "Extracting sound files to $INSTALL_SOUNDS..."
    tar -xzf "$SCRIPT_DIR/$SOUNDS_ARCHIVE" -C "$INSTALL_SOUNDS/" || {
        log_error "Failed to extract sound files"
        exit 1
    }
    
    # Set permissions
    chmod 644 "$INSTALL_SOUNDS"/*.wav 2>/dev/null || true
    
    # Count sound files
    local sound_count
    sound_count=$(find "$INSTALL_SOUNDS" -name "*.wav" | wc -l)
    log_info "Installed $sound_count sound file(s)"
}

# Install Python script
install_script() {
    log_step "Installing Python script..."
    
    # Copy script
    cp "$SCRIPT_DIR/$PYTHON_SCRIPT" "$INSTALL_BIN" || {
        log_error "Failed to copy Python script"
        exit 1
    }
    
    # Set permissions
    chmod 755 "$INSTALL_BIN" || {
        log_error "Failed to set script permissions"
        exit 1
    }
    
    # Validate Python syntax
    log_info "Validating Python syntax..."
    python3 -m py_compile "$INSTALL_BIN" || {
        log_error "Python syntax validation failed"
        exit 1
    }
    
    log_info "Python script installed to $INSTALL_BIN"
}

# Install systemd service
install_service() {
    log_step "Installing systemd service..."
    
    # Copy service file
    cp "$SCRIPT_DIR/$SERVICE_FILE" "$INSTALL_SERVICE" || {
        log_error "Failed to copy service file"
        exit 1
    }
    
    # Set permissions
    chmod 644 "$INSTALL_SERVICE" || {
        log_error "Failed to set service permissions"
        exit 1
    }
    
    # Reload systemd
    log_info "Reloading systemd daemon..."
    systemctl daemon-reload || {
        log_error "Failed to reload systemd"
        exit 1
    }
    
    # Enable service
    log_info "Enabling mario.service..."
    systemctl enable mario.service || {
        log_error "Failed to enable service"
        exit 1
    }
    
    log_info "systemd service installed and enabled"
}

# Start the service
start_service() {
    log_step "Starting mario.service..."
    
    systemctl start mario.service || {
        log_error "Failed to start service"
        log_info "Check status with: systemctl status mario.service"
        log_info "Check logs with: journalctl -u mario.service -n 50"
        exit 1
    }
    
    # Wait a moment for service to start
    sleep 2
    
    # Check if service is running
    if systemctl is-active --quiet mario.service; then
        log_info "Service started successfully"
    else
        log_error "Service failed to start"
        systemctl status mario.service --no-pager
        exit 1
    fi
}

# Verify installation
verify_installation() {
    log_step "Verifying installation..."
    
    local errors=0
    
    # Check Python script
    if [ -f "$INSTALL_BIN" ]; then
        log_info "✓ Python script: $INSTALL_BIN"
    else
        log_error "✗ Python script not found"
        errors=1
    fi
    
    # Check service file
    if [ -f "$INSTALL_SERVICE" ]; then
        log_info "✓ Service file: $INSTALL_SERVICE"
    else
        log_error "✗ Service file not found"
        errors=1
    fi
    
    # Check sound directory
    if [ -d "$INSTALL_SOUNDS" ]; then
        local sound_count
        sound_count=$(find "$INSTALL_SOUNDS" -name "*.wav" | wc -l)
        log_info "✓ Sound directory: $INSTALL_SOUNDS ($sound_count files)"
    else
        log_error "✗ Sound directory not found"
        errors=1
    fi
    
    # Check service status
    if systemctl is-enabled --quiet mario.service; then
        log_info "✓ Service enabled"
    else
        log_warn "✗ Service not enabled"
        errors=1
    fi
    
    if systemctl is-active --quiet mario.service; then
        log_info "✓ Service running"
    else
        log_warn "✗ Service not running"
        errors=1
    fi
    
    if [ $errors -eq 0 ]; then
        log_info "All checks passed"
        return 0
    else
        log_warn "Some checks failed"
        return 1
    fi
}

# Uninstall function
uninstall() {
    log_step "Uninstalling mario motion detection service..."
    
    # Stop service if running
    if systemctl is-active --quiet mario.service 2>/dev/null; then
        log_info "Stopping service..."
        systemctl stop mario.service || true
    fi
    
    # Disable service if enabled
    if systemctl is-enabled --quiet mario.service 2>/dev/null; then
        log_info "Disabling service..."
        systemctl disable mario.service || true
    fi
    
    # Remove service file
    if [ -f "$INSTALL_SERVICE" ]; then
        log_info "Removing service file..."
        rm -f "$INSTALL_SERVICE"
    fi
    
    # Reload systemd
    systemctl daemon-reload 2>/dev/null || true
    
    # Remove Python script
    if [ -f "$INSTALL_BIN" ]; then
        log_info "Removing Python script..."
        rm -f "$INSTALL_BIN"
    fi
    
    # Ask about sound files
    echo -e "${YELLOW}Remove sound files from $INSTALL_SOUNDS? [y/N]${NC} "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        if [ -d "$INSTALL_SOUNDS" ]; then
            log_info "Removing sound files..."
            rm -rf "$INSTALL_SOUNDS"
        fi
    else
        log_info "Keeping sound files"
    fi
    
    # Ask about log file
    echo -e "${YELLOW}Remove log file $LOG_FILE? [y/N]${NC} "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        if [ -f "$LOG_FILE" ]; then
            log_info "Removing log file..."
            rm -f "$LOG_FILE"
        fi
    else
        log_info "Keeping log file"
    fi
    
    log_info "Uninstall completed"
}

# Show status
show_status() {
    echo "====================================="
    echo "Mario Motion Detection - Status"
    echo "====================================="
    echo ""
    
    # Check files
    echo "Files:"
    [ -f "$INSTALL_BIN" ] && echo "  ✓ Python script: $INSTALL_BIN" || echo "  ✗ Python script not installed"
    [ -f "$INSTALL_SERVICE" ] && echo "  ✓ Service file: $INSTALL_SERVICE" || echo "  ✗ Service file not installed"
    [ -d "$INSTALL_SOUNDS" ] && echo "  ✓ Sound directory: $INSTALL_SOUNDS" || echo "  ✗ Sound directory not found"
    echo ""
    
    # Check service
    echo "Service Status:"
    if systemctl list-unit-files | grep -q "mario.service"; then
        systemctl status mario.service --no-pager || true
    else
        echo "  ✗ Service not installed"
    fi
}

# Main installation function
install() {
    echo "====================================="
    echo "Mario Motion Detection - Installation"
    echo "====================================="
    echo ""
    
    check_root "$@"
    check_files
    install_dependencies
    install_sounds
    install_script
    install_service
    start_service
    
    echo ""
    echo "====================================="
    verify_installation
    echo "====================================="
    echo ""
    
    log_info "Installation completed successfully!"
    echo ""
    echo "Service Management Commands:"
    echo "  Start:   sudo systemctl start mario.service"
    echo "  Stop:    sudo systemctl stop mario.service"
    echo "  Restart: sudo systemctl restart mario.service"
    echo "  Status:  sudo systemctl status mario.service"
    echo "  Logs:    sudo journalctl -u mario.service -f"
    echo ""
}

# Main script
main() {
    local action="${1:-install}"
    
    case "$action" in
        install)
            install "$@"
            ;;
        uninstall)
            check_root "$@"
            uninstall
            ;;
        status)
            show_status
            ;;
        *)
            echo "Usage: $0 [install|uninstall|status]"
            echo ""
            echo "Commands:"
            echo "  install   - Install mario motion detection service (default)"
            echo "  uninstall - Remove mario motion detection service"
            echo "  status    - Show installation status"
            echo ""
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
