#!/bin/bash
################################################################################
# System Info Monitor - Setup Script
#
# This script installs the system-info service and all resources
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
PYTHON_SCRIPT="system-info.py"
SERVICE_FILE="system-info.service"
CONFIG_EXAMPLE="system-info.conf.example"

# Sensor descriptor files
SENSOR_UPTIME="system_uptime_descriptor.json"
SENSOR_CPU_TEMP="system_cpu_temp_descriptor.json"
SENSOR_MEMORY="system_memory_usage_descriptor.json"
SENSOR_DISK="system_disk_usage_descriptor.json"
SENSOR_CPU_USAGE="system_cpu_usage_descriptor.json"

INSTALL_BIN="/usr/local/bin/system-info.py"
INSTALL_SERVICE="/etc/systemd/system/system-info.service"
INSTALL_CONFIG_DIR="/etc/luigi/system/system-info"
INSTALL_CONFIG="/etc/luigi/system/system-info/system-info.conf"
LOG_FILE="/var/log/luigi/system-info.log"

# ha-mqtt integration paths
HA_MQTT_SENSORS_DIR="/etc/luigi/iot/ha-mqtt/sensors.d"

# Check if files exist
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
    
    if [ ! -f "$SCRIPT_DIR/$CONFIG_EXAMPLE" ]; then
        log_error "Missing: $CONFIG_EXAMPLE"
        missing_files=1
    fi
    
    # Check sensor descriptors
    for sensor_file in "$SENSOR_UPTIME" "$SENSOR_CPU_TEMP" "$SENSOR_MEMORY" "$SENSOR_DISK" "$SENSOR_CPU_USAGE"; do
        if [ ! -f "$SCRIPT_DIR/$sensor_file" ]; then
            log_error "Missing: $sensor_file"
            missing_files=1
        fi
    done
    
    if [ $missing_files -eq 1 ]; then
        log_error "Required files not found in $SCRIPT_DIR"
        exit 1
    fi
    
    log_info "All required files found"
}

# Install dependencies
install_dependencies() {
    # Check if --skip-packages flag is set (use helper function)
    if should_skip_packages; then
        log_info "Skipping package installation (managed centrally)"
        return 0
    fi
    
    log_step "Installing dependencies..."
    
    # Read packages from module.json using helper function
    local module_json="$SCRIPT_DIR/module.json"
    local packages=($(read_apt_packages "$module_json"))
    
    if [ ${#packages[@]} -eq 0 ]; then
        # Fallback to hardcoded packages if module.json or jq not available
        log_warn "module.json or jq not found, using fallback package list"
        packages=("python3-psutil")
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
        # Update package list
        log_info "Updating package list..."
        apt-get update -qq || {
            log_error "Failed to update package list"
            exit 1
        }
        
        # Install each package
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

# Install configuration file
install_config() {
    log_step "Installing configuration file..."
    
    # Create config directory
    mkdir -p "$INSTALL_CONFIG_DIR" || {
        log_error "Failed to create config directory"
        exit 1
    }
    
    # Check if config already exists
    if [ -f "$INSTALL_CONFIG" ]; then
        log_warn "Config file already exists at $INSTALL_CONFIG"
        log_info "Keeping existing configuration"
        return 0
    fi
    
    # Copy example config as the default config
    cp "$SCRIPT_DIR/$CONFIG_EXAMPLE" "$INSTALL_CONFIG" || {
        log_error "Failed to copy configuration file"
        exit 1
    }
    
    # Set permissions
    chmod 644 "$INSTALL_CONFIG" || {
        log_error "Failed to set config permissions"
        exit 1
    }
    
    log_info "Configuration file installed to $INSTALL_CONFIG"
    log_info "Edit $INSTALL_CONFIG to customize settings"
}

# Deploy ha-mqtt sensor descriptors (optional)
deploy_ha_mqtt_descriptors() {
    log_step "Deploying ha-mqtt sensor descriptors..."
    
    # Check if ha-mqtt is installed
    if [ ! -x /usr/local/bin/luigi-publish ]; then
        log_info "ha-mqtt not installed, skipping MQTT integration"
        log_info "System monitoring will work standalone without MQTT"
        return 0
    fi
    
    # Check if sensors.d directory exists
    if [ ! -d "$HA_MQTT_SENSORS_DIR" ]; then
        log_warn "ha-mqtt sensors.d directory not found"
        log_info "Skipping MQTT integration"
        return 0
    fi
    
    # Copy all sensor descriptors
    local descriptor_count=0
    for sensor_file in "$SENSOR_UPTIME" "$SENSOR_CPU_TEMP" "$SENSOR_MEMORY" "$SENSOR_DISK" "$SENSOR_CPU_USAGE"; do
        local sensor_id
        sensor_id=$(basename "$sensor_file" "_descriptor.json")
        local dest="$HA_MQTT_SENSORS_DIR/${sensor_id}.json"
        
        log_info "Installing sensor descriptor: $sensor_id..."
        if ! cp "$SCRIPT_DIR/$sensor_file" "$dest" 2>/dev/null; then
            log_warn "Failed to copy sensor descriptor: $sensor_file"
            log_info "MQTT integration skipped - system monitoring will work standalone"
            return 0
        fi
        
        if ! chmod 644 "$dest" 2>/dev/null; then
            log_warn "Failed to set descriptor permissions: $dest"
            log_info "MQTT integration skipped - system monitoring will work standalone"
            return 0
        fi
        
        descriptor_count=$((descriptor_count + 1))
    done
    
    log_info "Installed $descriptor_count sensor descriptors to $HA_MQTT_SENSORS_DIR"
    
    # Run luigi-discover to register sensors with Home Assistant
    log_info "Registering sensors with Home Assistant..."
    if /usr/local/bin/luigi-discover; then
        log_info "Sensors registered successfully"
        log_info "System metrics will be published to Home Assistant via MQTT"
    else
        log_warn "Failed to register sensors with Home Assistant"
        log_info "This may be due to MQTT broker connectivity, permissions, or configuration"
        log_info "You can manually run: sudo /usr/local/bin/luigi-discover"
    fi
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
    
    log_info "Service installed to $INSTALL_SERVICE"
}

# Enable and start service
start_service() {
    log_step "Enabling and starting service..."
    
    # Enable service
    log_info "Enabling system-info service..."
    systemctl enable system-info.service || {
        log_error "Failed to enable service"
        exit 1
    }
    
    # Start service
    log_info "Starting system-info service..."
    systemctl start system-info.service || {
        log_error "Failed to start service"
        exit 1
    }
    
    # Wait a moment for service to start
    sleep 2
    
    # Check service status
    if systemctl is-active --quiet system-info.service; then
        log_info "Service started successfully"
    else
        log_error "Service failed to start"
        log_info "Check logs with: sudo journalctl -u system-info.service -n 50"
        exit 1
    fi
}

# Main install function
install() {
    log_info "=== System Info Module Installation ==="
    
    check_root "$@"
    check_files
    install_dependencies
    install_script
    install_config
    deploy_ha_mqtt_descriptors
    install_service
    start_service
    
    echo ""
    log_info "=== Installation Complete ==="
    log_info "Service: system-info.service"
    log_info "Status: sudo systemctl status system-info"
    log_info "Logs: sudo journalctl -u system-info -f"
    log_info "Config: $INSTALL_CONFIG"
    echo ""
}

# Uninstall function
uninstall() {
    log_info "=== System Info Module Uninstallation ==="
    
    check_root "$@"
    
    # Check if purge mode is enabled
    local purge_mode="${LUIGI_PURGE_MODE:-}"
    local remove_config="N"
    local remove_log="N"
    local remove_packages="N"
    
    if [ "$purge_mode" = "purge" ]; then
        log_warn "PURGE MODE: Removing all files, configs, and packages"
        remove_config="y"
        remove_log="y"
        remove_packages="y"
    fi
    
    # Stop and disable service
    log_step "Stopping and disabling service..."
    if systemctl is-active --quiet system-info.service; then
        systemctl stop system-info.service || true
    fi
    
    if systemctl is-enabled --quiet system-info.service 2>/dev/null; then
        systemctl disable system-info.service || true
    fi
    
    log_info "Service stopped and disabled"
    
    # Remove service file
    if [ -f "$INSTALL_SERVICE" ]; then
        log_step "Removing service file..."
        rm -f "$INSTALL_SERVICE"
        systemctl daemon-reload
        log_info "Service file removed"
    fi
    
    # Remove Python script
    if [ -f "$INSTALL_BIN" ]; then
        log_step "Removing Python script..."
        rm -f "$INSTALL_BIN"
        log_info "Python script removed"
    fi
    
    # Remove ha-mqtt descriptors
    if [ -d "$HA_MQTT_SENSORS_DIR" ]; then
        log_step "Removing ha-mqtt sensor descriptors..."
        local removed_count=0
        for sensor_id in "system_uptime" "system_cpu_temp" "system_memory_usage" "system_disk_usage" "system_cpu_usage"; do
            local descriptor="$HA_MQTT_SENSORS_DIR/${sensor_id}.json"
            if [ -f "$descriptor" ]; then
                rm -f "$descriptor"
                removed_count=$((removed_count + 1))
            fi
        done
        if [ $removed_count -gt 0 ]; then
            log_info "Removed $removed_count sensor descriptors"
        fi
    fi
    
    # Handle config removal
    if [ "$purge_mode" != "purge" ]; then
        echo ""
        log_warn "Configuration directory: $INSTALL_CONFIG_DIR"
        read -p "Remove configuration? (y/N): " -n 1 -r
        echo
        remove_config=$REPLY
    fi
    
    if [[ $remove_config =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_CONFIG_DIR"
        log_info "Configuration removed"
    else
        log_info "Configuration preserved"
    fi
    
    # Handle log removal
    if [ "$purge_mode" != "purge" ]; then
        if [ -f "$LOG_FILE" ]; then
            log_warn "Log file: $LOG_FILE"
            read -p "Remove log file? (y/N): " -n 1 -r
            echo
            remove_log=$REPLY
        fi
    fi
    
    if [[ $remove_log =~ ^[Yy]$ ]]; then
        if [ -f "$LOG_FILE" ]; then
            rm -f "$LOG_FILE"*
            log_info "Log file removed"
        fi
    else
        [ -f "$LOG_FILE" ] && log_info "Log file preserved"
    fi
    
    # Remove packages if in purge mode or requested
    if [ "$purge_mode" != "purge" ] && [ "${SKIP_PACKAGES:-}" != "1" ]; then
        echo ""
        # Read packages from module.json for display
        local package_list="python3-psutil"
        if [ -f "$SCRIPT_DIR/module.json" ] && command -v jq >/dev/null 2>&1; then
            local packages_json
            packages_json=$(jq -r '.apt_packages | join(", ")' "$SCRIPT_DIR/module.json" 2>/dev/null)
            [ -n "$packages_json" ] && package_list="$packages_json"
        fi
        read -p "Remove installed packages ($package_list)? (y/N): " -n 1 -r
        echo
        remove_packages=$REPLY
    fi
    
    if should_skip_packages; then
        log_info "Skipping package removal (managed centrally)"
    elif [[ $remove_packages =~ ^[Yy]$ ]]; then
        log_step "Removing packages..."
        
        # Read packages from module.json using helper function
        local packages=($(read_apt_packages "$SCRIPT_DIR/module.json"))
        if [ ${#packages[@]} -eq 0 ]; then
            # Fallback to hardcoded packages
            packages=("python3-psutil")
        fi
        
        for pkg in "${packages[@]}"; do
            if dpkg -l | grep -q "^ii  $pkg "; then
                log_info "Removing $pkg..."
                apt-get remove -y "$pkg" >/dev/null 2>&1 || log_warn "Failed to remove $pkg"
            fi
        done
        
        # Clean up unused dependencies
        log_info "Removing unused dependencies..."
        apt-get autoremove -y >/dev/null 2>&1
    fi
    
    echo ""
    log_info "=== Uninstallation Complete ==="
    echo ""
}

# Status function
status() {
    log_info "=== System Info Module Status ==="
    echo ""
    
    # Check if service file exists
    if [ ! -f "$INSTALL_SERVICE" ]; then
        log_error "Service not installed"
        exit 1
    fi
    
    # Check service status
    log_step "Service Status:"
    systemctl status system-info.service --no-pager || true
    echo ""
    
    # Check if Python script exists
    log_step "Installation Status:"
    if [ -f "$INSTALL_BIN" ]; then
        log_info "Python script: $INSTALL_BIN ✓"
    else
        log_error "Python script: $INSTALL_BIN ✗"
    fi
    
    if [ -f "$INSTALL_CONFIG" ]; then
        log_info "Configuration: $INSTALL_CONFIG ✓"
    else
        log_warn "Configuration: $INSTALL_CONFIG ✗"
    fi
    
    if [ -f "$LOG_FILE" ]; then
        log_info "Log file: $LOG_FILE ✓"
    else
        log_warn "Log file: $LOG_FILE ✗"
    fi
    echo ""
    
    # Check ha-mqtt integration
    log_step "MQTT Integration:"
    if [ -x /usr/local/bin/luigi-publish ]; then
        log_info "ha-mqtt installed ✓"
        
        # Count installed descriptors
        local descriptor_count=0
        for sensor_id in "system_uptime" "system_cpu_temp" "system_memory_usage" "system_disk_usage" "system_cpu_usage"; do
            if [ -f "$HA_MQTT_SENSORS_DIR/${sensor_id}.json" ]; then
                descriptor_count=$((descriptor_count + 1))
            fi
        done
        log_info "Sensor descriptors: $descriptor_count/5"
    else
        log_info "ha-mqtt not installed (standalone mode)"
    fi
    echo ""
    
    # Show recent log entries
    log_step "Recent Log Entries:"
    if [ -f "$LOG_FILE" ]; then
        tail -n 10 "$LOG_FILE"
    else
        log_warn "No log file found"
    fi
    echo ""
}

# Main script
# Parse command and flags
action="${1:-}"
shift || true

# Parse flags
while [ $# -gt 0 ]; do
    case "$1" in
        --skip-packages)
            export SKIP_PACKAGES=1
            shift
            ;;
        *)
            shift
            ;;
    esac
done

case "$action" in
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
        echo "Usage: sudo $0 {install|uninstall|status} [--skip-packages]"
        echo ""
        echo "Commands:"
        echo "  install   - Install system-info module"
        echo "  uninstall - Remove system-info module"
        echo "  status    - Show installation and service status"
        echo ""
        echo "Options:"
        echo "  --skip-packages  - Skip apt package installation/removal (for centralized management)"
        exit 1
        ;;
esac
