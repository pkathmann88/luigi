#!/bin/bash
################################################################################
# Climate Module - Setup Script
#
# This script installs the Climate monitoring service and all resources
# on the current system.
#
# Usage: sudo ./setup.sh [install|uninstall|status]
#
# Author: Luigi Project
# License: MIT
################################################################################

set -e  # Exit on error

# Script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source shared setup helpers
# shellcheck source=../../util/setup-helpers.sh
if [ -f "$REPO_ROOT/util/setup-helpers.sh" ]; then
    source "$REPO_ROOT/util/setup-helpers.sh"
else
    echo "Error: Cannot find setup-helpers.sh"
    echo "Expected location: $REPO_ROOT/util/setup-helpers.sh"
    exit 1
fi

# Installation paths
MODULE_DIR="$SCRIPT_DIR"
SERVICE_FILE="climate.service"
CONFIG_EXAMPLE="config/climate.conf.example"
REQUIREMENTS_FILE="requirements.txt"
TEMP_DESCRIPTOR="climate_temperature_descriptor.json"
HUMIDITY_DESCRIPTOR="climate_humidity_descriptor.json"

# System paths
INSTALL_LIB="/usr/local/lib/climate"
INSTALL_SERVICE="/etc/systemd/system/climate.service"
INSTALL_CONFIG_DIR="/etc/luigi/sensors/climate"
INSTALL_CONFIG="$INSTALL_CONFIG_DIR/climate.conf"
INSTALL_SOUNDS="/usr/share/sounds/climate"
LOG_FILE="/var/log/luigi/climate.log"
DATA_DIR="/var/lib/luigi"
DB_FILE="$DATA_DIR/climate.db"

# ha-mqtt integration paths
HA_MQTT_SENSORS_DIR="/etc/luigi/iot/ha-mqtt/sensors.d"
HA_MQTT_TEMP_DESCRIPTOR="$HA_MQTT_SENSORS_DIR/climate_temperature.json"
HA_MQTT_HUMIDITY_DESCRIPTOR="$HA_MQTT_SENSORS_DIR/climate_humidity.json"

# Module registry
MODULE_PATH="sensors/climate"

################################################################################
# Helper Functions
################################################################################

check_files() {
    log_step "Checking required files..."
    
    local missing_files=0
    
    if [ ! -f "$MODULE_DIR/climate_module.py" ]; then
        log_error "Missing: climate_module.py"
        missing_files=1
    fi
    
    if [ ! -f "$MODULE_DIR/$SERVICE_FILE" ]; then
        log_error "Missing: $SERVICE_FILE"
        missing_files=1
    fi
    
    if [ ! -f "$MODULE_DIR/$CONFIG_EXAMPLE" ]; then
        log_error "Missing: $CONFIG_EXAMPLE"
        missing_files=1
    fi
    
    if [ ! -f "$MODULE_DIR/$REQUIREMENTS_FILE" ]; then
        log_error "Missing: $REQUIREMENTS_FILE"
        missing_files=1
    fi
    
    if [ $missing_files -eq 1 ]; then
        log_error "Required files not found in $MODULE_DIR"
        exit 1
    fi
    
    log_info "All required files found"
}

install_dependencies() {
    # Check if --skip-packages flag is set
    if should_skip_packages; then
        log_info "Skipping package installation (managed centrally)"
        return 0
    fi
    
    log_step "Installing dependencies..."
    
    # Read packages from module.json using helper function
    local module_json="$MODULE_DIR/module.json"
    local packages
    read -r -a packages <<< "$(read_apt_packages "$module_json")"
    
    if [ ${#packages[@]} -eq 0 ]; then
        # Fallback to hardcoded packages if module.json or jq not available
        log_warn "module.json or jq not found, using fallback package list"
        packages=("python3-pip" "python3-venv" "sqlite3" "python3-yaml" "alsa-utils")
    fi
    
    # Check if packages are needed
    local to_install=()
    for pkg in "${packages[@]}"; do
        if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
            log_info "✓ $pkg (already installed)"
        else
            to_install+=("$pkg")
        fi
    done
    
    # Install packages if needed
    if [ ${#to_install[@]} -gt 0 ]; then
        log_info "Updating package list..."
        apt-get update -qq || {
            log_error "Failed to update package list"
            exit 1
        }
        
        for pkg in "${to_install[@]}"; do
            log_info "Installing $pkg..."
            apt-get install -y "$pkg" || {
                log_error "Failed to install $pkg"
                exit 1
            }
        done
        
        log_info "Dependencies installed successfully"
    else
        log_info "All dependencies are already installed"
    fi
}

install_python_packages() {
    log_step "Installing Python packages..."
    
    # Install Python dependencies via pip
    if [ -f "$MODULE_DIR/$REQUIREMENTS_FILE" ]; then
        log_info "Installing Python packages from requirements.txt..."
        pip3 install --break-system-packages -q -r "$MODULE_DIR/$REQUIREMENTS_FILE" || {
            log_warn "Failed to install some Python packages (continuing anyway)"
            log_info "You can manually install with: pip3 install -r $MODULE_DIR/$REQUIREMENTS_FILE"
        }
        log_info "Python packages installed"
    else
        log_warn "requirements.txt not found, skipping Python package installation"
    fi
}

install_module_files() {
    log_step "Installing module files..."
    
    # Create installation directory
    mkdir -p "$INSTALL_LIB"
    
    # Copy Python modules
    cp -r "$MODULE_DIR/climate_module.py" "$INSTALL_LIB/"
    cp -r "$MODULE_DIR/sensors" "$INSTALL_LIB/"
    cp -r "$MODULE_DIR/database" "$INSTALL_LIB/"
    
    # Set permissions
    chmod 755 "$INSTALL_LIB/climate_module.py"
    
    log_info "Module files installed to $INSTALL_LIB"
}

install_config() {
    log_step "Installing configuration..."
    
    # Create config directory
    mkdir -p "$INSTALL_CONFIG_DIR"
    
    # Copy config if it doesn't exist
    if [ ! -f "$INSTALL_CONFIG" ]; then
        cp "$MODULE_DIR/$CONFIG_EXAMPLE" "$INSTALL_CONFIG"
        log_info "Configuration installed to $INSTALL_CONFIG"
    else
        log_info "Configuration already exists at $INSTALL_CONFIG (not overwriting)"
    fi
}

install_sounds() {
    log_step "Setting up alert sounds directory..."
    
    # Create sounds directory
    mkdir -p "$INSTALL_SOUNDS"
    
    # Copy README
    if [ -f "$MODULE_DIR/sounds/README.md" ]; then
        cp "$MODULE_DIR/sounds/README.md" "$INSTALL_SOUNDS/"
    fi
    
    log_info "Sounds directory created at $INSTALL_SOUNDS"
    log_warn "NOTE: You need to provide your own WAV alert sound files"
    log_info "See $INSTALL_SOUNDS/README.md for instructions"
}

create_data_directories() {
    log_step "Creating data directories..."
    
    # Create data directory
    mkdir -p "$DATA_DIR"
    
    # Create log directory
    mkdir -p "$(dirname "$LOG_FILE")"
    
    log_info "Data directories created"
}

install_service() {
    log_step "Installing systemd service..."
    
    # Copy service file
    cp "$MODULE_DIR/$SERVICE_FILE" "$INSTALL_SERVICE"
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable service
    systemctl enable climate.service
    
    log_info "Service installed and enabled"
}

install_ha_mqtt_integration() {
    log_step "Setting up Home Assistant MQTT integration..."
    
    # Check if ha-mqtt is installed
    if [ ! -d "$HA_MQTT_SENSORS_DIR" ]; then
        log_warn "ha-mqtt module not installed, skipping sensor registration"
        log_info "Install ha-mqtt module first to enable Home Assistant integration"
        return 0
    fi
    
    # Install sensor descriptors
    if [ -f "$MODULE_DIR/$TEMP_DESCRIPTOR" ]; then
        cp "$MODULE_DIR/$TEMP_DESCRIPTOR" "$HA_MQTT_TEMP_DESCRIPTOR"
        log_info "Temperature sensor descriptor installed"
    fi
    
    if [ -f "$MODULE_DIR/$HUMIDITY_DESCRIPTOR" ]; then
        cp "$MODULE_DIR/$HUMIDITY_DESCRIPTOR" "$HA_MQTT_HUMIDITY_DESCRIPTOR"
        log_info "Humidity sensor descriptor installed"
    fi
    
    # Run discovery if luigi-discover exists
    if command -v luigi-discover >/dev/null 2>&1; then
        log_info "Running MQTT discovery..."
        luigi-discover || log_warn "MQTT discovery failed (continuing anyway)"
    fi
    
    log_info "Home Assistant MQTT integration configured"
}

start_service() {
    log_step "Starting climate service..."
    
    systemctl start climate.service || {
        log_error "Failed to start service"
        log_info "Check logs with: journalctl -u climate.service -n 50"
        exit 1
    }
    
    # Wait a moment for service to start
    sleep 2
    
    # Check status
    if systemctl is-active --quiet climate.service; then
        log_success "Climate service started successfully"
    else
        log_error "Service failed to start"
        log_info "Check logs with: journalctl -u climate.service -n 50"
        exit 1
    fi
}

update_module_registry() {
    log_step "Updating module registry..."
    
    # Use shared helper to update registry
    local module_json="$MODULE_DIR/module.json"
    
    if declare -f update_module_registry_full >/dev/null 2>&1; then
        update_module_registry_full "$MODULE_PATH" "$module_json" "installed"
        log_info "Module registry updated"
    else
        log_warn "Registry update function not available, skipping"
    fi
}

################################################################################
# Installation
################################################################################

install_module() {
    log_header "Installing Climate Module"
    
    check_files
    install_dependencies
    install_python_packages
    install_module_files
    install_config
    install_sounds
    create_data_directories
    install_service
    install_ha_mqtt_integration
    update_module_registry
    start_service
    
    log_header "Installation Complete"
    log_success "Climate module installed successfully"
    echo ""
    log_info "Service status: systemctl status climate.service"
    log_info "View logs: journalctl -u climate.service -f"
    log_info "Configuration: $INSTALL_CONFIG"
    log_info "Database: $DB_FILE"
    echo ""
    log_warn "IMPORTANT: Add alert sound files to $INSTALL_SOUNDS"
    log_info "See $INSTALL_SOUNDS/README.md for instructions"
}

################################################################################
# Uninstallation
################################################################################

uninstall_module() {
    log_header "Uninstalling Climate Module"
    
    # Stop and disable service
    log_step "Stopping climate service..."
    if systemctl is-active --quiet climate.service; then
        systemctl stop climate.service || log_warn "Failed to stop service"
    fi
    systemctl disable climate.service 2>/dev/null || true
    
    # Remove service file
    if [ -f "$INSTALL_SERVICE" ]; then
        rm -f "$INSTALL_SERVICE"
        log_info "Service file removed"
    fi
    
    # Reload systemd
    systemctl daemon-reload
    
    # Remove module files
    if [ -d "$INSTALL_LIB" ]; then
        rm -rf "$INSTALL_LIB"
        log_info "Module files removed"
    fi
    
    # Remove sounds directory
    if [ -d "$INSTALL_SOUNDS" ]; then
        rm -rf "$INSTALL_SOUNDS"
        log_info "Sounds directory removed"
    fi
    
    # Remove ha-mqtt integration
    if [ -f "$HA_MQTT_TEMP_DESCRIPTOR" ]; then
        rm -f "$HA_MQTT_TEMP_DESCRIPTOR"
        log_info "Temperature sensor descriptor removed"
    fi
    
    if [ -f "$HA_MQTT_HUMIDITY_DESCRIPTOR" ]; then
        rm -f "$HA_MQTT_HUMIDITY_DESCRIPTOR"
        log_info "Humidity sensor descriptor removed"
    fi
    
    # Update module registry
    log_step "Updating module registry..."
    if declare -f update_module_registry_full >/dev/null 2>&1; then
        update_module_registry_full "$MODULE_PATH" "$MODULE_DIR/module.json" "removed"
        log_info "Module registry updated"
    fi
    
    log_header "Uninstallation Complete"
    log_success "Climate module uninstalled"
    echo ""
    log_info "Configuration preserved: $INSTALL_CONFIG"
    log_info "Database preserved: $DB_FILE"
    log_info "To remove config: sudo rm -rf $INSTALL_CONFIG_DIR"
    log_info "To remove database: sudo rm -f $DB_FILE"
}

################################################################################
# Status
################################################################################

show_status() {
    log_header "Climate Module Status"
    
    # Check if installed
    if [ ! -f "$INSTALL_SERVICE" ]; then
        log_warn "Climate module is NOT installed"
        return 1
    fi
    
    log_info "Climate module is installed"
    echo ""
    
    # Service status
    log_step "Service Status:"
    if systemctl is-active --quiet climate.service; then
        log_success "Service is running"
    else
        log_error "Service is NOT running"
    fi
    
    if systemctl is-enabled --quiet climate.service; then
        log_info "Service is enabled (starts on boot)"
    else
        log_warn "Service is disabled"
    fi
    
    echo ""
    
    # Configuration
    log_step "Configuration:"
    if [ -f "$INSTALL_CONFIG" ]; then
        log_info "Config file: $INSTALL_CONFIG"
    else
        log_warn "Config file not found"
    fi
    
    echo ""
    
    # Database
    log_step "Database:"
    if [ -f "$DB_FILE" ]; then
        local db_size
        db_size=$(du -h "$DB_FILE" | cut -f1)
        local record_count
        record_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM climate_readings;" 2>/dev/null || echo "N/A")
        log_info "Database: $DB_FILE ($db_size)"
        log_info "Records: $record_count"
    else
        log_warn "Database not found"
    fi
    
    echo ""
    
    # Recent logs
    log_step "Recent logs (last 10 lines):"
    journalctl -u climate.service -n 10 --no-pager 2>/dev/null || log_warn "No logs available"
}

################################################################################
# Main
################################################################################

main() {
    # Check for root
    check_root
    
    # Parse command
    local command="${1:-install}"
    
    case "$command" in
        install)
            install_module
            ;;
        uninstall)
            uninstall_module
            ;;
        status)
            show_status
            ;;
        *)
            echo "Usage: $0 {install|uninstall|status}"
            exit 1
            ;;
    esac
}

main "$@"
