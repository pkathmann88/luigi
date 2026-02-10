#!/bin/bash
################################################################################
# System Optimization - Setup Script
#
# This script installs the system optimization module and configures
# performance optimizations for Raspberry Pi Zero W.
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
PYTHON_SCRIPT="optimize.py"
CONFIG_EXAMPLE="optimize.conf.example"

INSTALL_BIN="/usr/local/bin/optimize.py"
INSTALL_CONFIG_DIR="/etc/luigi/system/optimization"
INSTALL_CONFIG="/etc/luigi/system/optimization/optimize.conf"
LOG_FILE="/var/log/system-optimization.log"

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
        echo "Please run: sudo $0"
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
    
    if [ ! -f "$SCRIPT_DIR/$CONFIG_EXAMPLE" ]; then
        log_error "Missing: $CONFIG_EXAMPLE"
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
    log_step "Checking dependencies..."
    
    # Check for Python 3
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 is not installed"
        log_info "Installing Python 3..."
        apt-get update
        apt-get install -y python3
    else
        log_info "Python 3 is already installed"
    fi
    
    log_info "All dependencies satisfied"
}

# Install configuration file
install_config() {
    log_step "Installing configuration..."
    
    # Create config directory
    if [ ! -d "$INSTALL_CONFIG_DIR" ]; then
        mkdir -p "$INSTALL_CONFIG_DIR"
        log_info "Created config directory: $INSTALL_CONFIG_DIR"
    fi
    
    # Install config file if it doesn't exist
    if [ ! -f "$INSTALL_CONFIG" ]; then
        cp "$SCRIPT_DIR/$CONFIG_EXAMPLE" "$INSTALL_CONFIG"
        chmod 644 "$INSTALL_CONFIG"
        log_info "Installed config file: $INSTALL_CONFIG"
        log_warn "Please review and customize the config file before running optimizations"
    else
        log_info "Config file already exists: $INSTALL_CONFIG"
        log_warn "Existing config preserved. Example config: $CONFIG_EXAMPLE"
    fi
}

# Install Python script
install_script() {
    log_step "Installing optimization script..."
    
    cp "$SCRIPT_DIR/$PYTHON_SCRIPT" "$INSTALL_BIN"
    chmod 755 "$INSTALL_BIN"
    
    log_info "Installed: $INSTALL_BIN"
}

# Run optimization
run_optimization() {
    log_step "Running system optimization..."
    
    # Ask user if they want to run optimization now
    echo ""
    echo -e "${YELLOW}Do you want to run system optimization now?${NC}"
    echo "This will apply the settings from $INSTALL_CONFIG"
    echo "You can review the config file first and run 'sudo optimize.py' later if preferred."
    echo ""
    read -p "Run optimization now? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Running optimization (dry-run first)..."
        
        # Run dry-run first to show what will be done
        "$INSTALL_BIN" --dry-run
        
        echo ""
        read -p "Proceed with actual optimization? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            "$INSTALL_BIN"
            
            echo ""
            log_warn "Optimization complete. A system reboot is recommended."
            read -p "Reboot now? (y/N): " -n 1 -r
            echo ""
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log_info "Rebooting system..."
                reboot
            else
                log_info "Please reboot manually when ready: sudo reboot"
            fi
        else
            log_info "Optimization cancelled. Run 'sudo optimize.py' when ready."
        fi
    else
        log_info "Optimization skipped. Run 'sudo optimize.py' when ready."
    fi
}

# Verify installation
verify_installation() {
    log_step "Verifying installation..."
    
    local errors=0
    
    # Check if script is installed
    if [ ! -f "$INSTALL_BIN" ]; then
        log_error "Script not found: $INSTALL_BIN"
        errors=$((errors + 1))
    else
        log_info "Script installed: $INSTALL_BIN"
    fi
    
    # Check if config directory exists
    if [ ! -d "$INSTALL_CONFIG_DIR" ]; then
        log_error "Config directory not found: $INSTALL_CONFIG_DIR"
        errors=$((errors + 1))
    else
        log_info "Config directory exists: $INSTALL_CONFIG_DIR"
    fi
    
    # Check if config file exists
    if [ ! -f "$INSTALL_CONFIG" ]; then
        log_warn "Config file not found: $INSTALL_CONFIG"
    else
        log_info "Config file exists: $INSTALL_CONFIG"
    fi
    
    if [ $errors -eq 0 ]; then
        log_info "Installation verification passed"
        return 0
    else
        log_error "Installation verification failed with $errors errors"
        return 1
    fi
}

# Install function
install() {
    log_info "Installing System Optimization Module..."
    echo ""
    
    check_files
    install_dependencies
    install_config
    install_script
    
    echo ""
    log_info "============================================"
    log_info "System Optimization Module Installed"
    log_info "============================================"
    echo ""
    log_info "Next steps:"
    log_info "1. Review configuration: $INSTALL_CONFIG"
    log_info "2. Run optimization: sudo optimize.py"
    log_info "3. View logs: $LOG_FILE"
    echo ""
    log_warn "Note: Optimizations will disable services and modify boot config"
    log_warn "Review the config carefully before running!"
    echo ""
    
    # Offer to run optimization now
    run_optimization
}

# Uninstall function
uninstall() {
    log_info "Uninstalling System Optimization Module..."
    echo ""
    
    log_warn "This will remove the optimization script and config"
    log_warn "It will NOT revert optimizations that have been applied"
    echo ""
    read -p "Are you sure you want to uninstall? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Uninstall cancelled"
        exit 0
    fi
    
    log_step "Removing installed files..."
    
    # Remove script
    if [ -f "$INSTALL_BIN" ]; then
        rm -f "$INSTALL_BIN"
        log_info "Removed: $INSTALL_BIN"
    fi
    
    # Ask about config directory
    if [ -d "$INSTALL_CONFIG_DIR" ]; then
        echo ""
        read -p "Remove config directory? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$INSTALL_CONFIG_DIR"
            log_info "Removed: $INSTALL_CONFIG_DIR"
        else
            log_info "Preserved: $INSTALL_CONFIG_DIR"
        fi
    fi
    
    # Ask about log file
    if [ -f "$LOG_FILE" ]; then
        echo ""
        read -p "Remove log file? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -f "$LOG_FILE"
            log_info "Removed: $LOG_FILE"
        else
            log_info "Preserved: $LOG_FILE"
        fi
    fi
    
    echo ""
    log_info "Uninstall complete"
    log_warn "Note: Applied optimizations (disabled services, boot config) remain active"
    log_warn "To revert optimizations, manually re-enable services and edit boot config"
}

# Status function
status() {
    log_info "System Optimization Module Status"
    echo ""
    
    # Check script installation
    if [ -f "$INSTALL_BIN" ]; then
        log_info "Script: Installed at $INSTALL_BIN"
    else
        log_error "Script: Not installed"
    fi
    
    # Check config
    if [ -f "$INSTALL_CONFIG" ]; then
        log_info "Config: $INSTALL_CONFIG"
    else
        log_warn "Config: Not found at $INSTALL_CONFIG"
    fi
    
    # Check log file
    if [ -f "$LOG_FILE" ]; then
        log_info "Log file: $LOG_FILE"
        log_info "Last 5 log entries:"
        echo ""
        tail -n 5 "$LOG_FILE" 2>/dev/null || log_warn "Could not read log file"
    else
        log_info "Log file: Not found (no optimizations run yet)"
    fi
    
    echo ""
    log_info "To run optimization: sudo optimize.py"
    log_info "For dry-run: sudo optimize.py --dry-run"
}

# Main script logic
main() {
    local command="${1:-install}"
    
    case "$command" in
        install)
            check_root
            install
            verify_installation
            ;;
        uninstall)
            check_root
            uninstall
            ;;
        status)
            status
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            echo "Usage: sudo $0 [install|uninstall|status]"
            echo ""
            echo "Commands:"
            echo "  install   - Install the system optimization module (default)"
            echo "  uninstall - Remove the system optimization module"
            echo "  status    - Show installation status"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
