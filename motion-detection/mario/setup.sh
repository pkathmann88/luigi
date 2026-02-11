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
CONFIG_EXAMPLE="mario.conf.example"
SENSOR_DESCRIPTOR="mario_motion_descriptor.json"
RESET_SCRIPT="reset-cooldown.sh"

INSTALL_BIN="/usr/local/bin/mario.py"
INSTALL_SERVICE="/etc/systemd/system/mario.service"
INSTALL_SOUNDS="/usr/share/sounds/mario"
INSTALL_CONFIG_DIR="/etc/luigi/motion-detection/mario"
INSTALL_CONFIG="/etc/luigi/motion-detection/mario/mario.conf"
INSTALL_RESET_SCRIPT="/usr/local/bin/mario-reset-cooldown"
LOG_FILE="/var/log/luigi/mario.log"

# ha-mqtt integration paths
HA_MQTT_SENSORS_DIR="/etc/luigi/iot/ha-mqtt/sensors.d"
HA_MQTT_DESCRIPTOR="$HA_MQTT_SENSORS_DIR/mario_motion.json"

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
    
    if [ ! -f "$SCRIPT_DIR/$CONFIG_EXAMPLE" ]; then
        log_error "Missing: $CONFIG_EXAMPLE"
        missing_files=1
    fi
    
    if [ ! -f "$SCRIPT_DIR/$SENSOR_DESCRIPTOR" ]; then
        log_error "Missing: $SENSOR_DESCRIPTOR"
        missing_files=1
    fi
    
    if [ ! -f "$SCRIPT_DIR/$RESET_SCRIPT" ]; then
        log_error "Missing: $RESET_SCRIPT"
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
    
    # Read packages from module.json
    local module_json="$SCRIPT_DIR/module.json"
    local packages=()
    
    if [ -f "$module_json" ] && command -v jq >/dev/null 2>&1; then
        # Parse apt_packages array from JSON
        while IFS= read -r pkg; do
            packages+=("$pkg")
        done < <(jq -r '.apt_packages[]? // empty' "$module_json" 2>/dev/null)
    else
        # Fallback to hardcoded packages if module.json or jq not available
        log_warn "module.json or jq not found, using fallback package list"
        packages=("python3-rpi-lgpio" "alsa-utils")
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

# Install sound files
install_sounds() {
    log_step "Installing sound files..."
    
    # Create sound directory
    mkdir -p "$INSTALL_SOUNDS" || {
        log_error "Failed to create sound directory"
        exit 1
    }
    
    # Extract sound files (strip leading 'luigi/' directory from archive)
    log_info "Extracting sound files to $INSTALL_SOUNDS..."
    tar -xzf "$SCRIPT_DIR/$SOUNDS_ARCHIVE" -C "$INSTALL_SOUNDS" --strip-components=1 || {
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

# Install reset cooldown script
install_reset_script() {
    log_step "Installing reset cooldown utility script..."
    
    # Copy script
    cp "$SCRIPT_DIR/$RESET_SCRIPT" "$INSTALL_RESET_SCRIPT" || {
        log_error "Failed to copy reset script"
        exit 1
    }
    
    # Set permissions
    chmod 755 "$INSTALL_RESET_SCRIPT" || {
        log_error "Failed to set reset script permissions"
        exit 1
    }
    
    # Validate shell script syntax
    log_info "Validating shell script syntax..."
    if command -v shellcheck >/dev/null 2>&1; then
        shellcheck "$INSTALL_RESET_SCRIPT" || {
            log_warn "Shellcheck validation reported warnings (non-fatal)"
        }
    fi
    
    log_info "Reset script installed to $INSTALL_RESET_SCRIPT"
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

# Deploy ha-mqtt sensor descriptor (optional)
deploy_ha_mqtt_descriptor() {
    log_step "Deploying ha-mqtt sensor descriptor..."
    
    # Check if ha-mqtt is installed
    if [ ! -x /usr/local/bin/luigi-publish ]; then
        log_info "ha-mqtt not installed, skipping MQTT integration"
        log_info "Motion detection will work standalone without MQTT"
        return 0
    fi
    
    # Check if sensors.d directory exists
    if [ ! -d "$HA_MQTT_SENSORS_DIR" ]; then
        log_warn "ha-mqtt sensors.d directory not found"
        log_info "Skipping MQTT integration"
        return 0
    fi
    
    # Copy sensor descriptor
    log_info "Installing sensor descriptor..."
    if ! cp "$SCRIPT_DIR/$SENSOR_DESCRIPTOR" "$HA_MQTT_DESCRIPTOR" 2>/dev/null; then
        log_warn "Failed to copy sensor descriptor"
        log_info "MQTT integration skipped - motion detection will work standalone"
        return 0
    fi
    
    # Set permissions
    if ! chmod 644 "$HA_MQTT_DESCRIPTOR" 2>/dev/null; then
        log_warn "Failed to set descriptor permissions"
        log_info "MQTT integration skipped - motion detection will work standalone"
        return 0
    fi
    
    log_info "Sensor descriptor installed to $HA_MQTT_DESCRIPTOR"
    
    # Run luigi-discover to register sensor with Home Assistant
    log_info "Registering sensor with Home Assistant..."
    if /usr/local/bin/luigi-discover; then
        log_info "Sensor registered successfully"
        log_info "Motion events will be published to Home Assistant via MQTT"
    else
        log_warn "Failed to register sensor with Home Assistant"
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
    
    # Check reset script
    if [ -f "$INSTALL_RESET_SCRIPT" ]; then
        log_info "✓ Reset script: $INSTALL_RESET_SCRIPT"
    else
        log_warn "✗ Reset script not found"
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
    
    # Check config file
    if [ -f "$INSTALL_CONFIG" ]; then
        log_info "✓ Config file: $INSTALL_CONFIG"
    else
        log_warn "✗ Config file not found (will use defaults)"
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
    
    # Check if purge mode is enabled
    local purge_mode="${LUIGI_PURGE_MODE:-}"
    local remove_sounds="N"
    local remove_log="N"
    local remove_config="N"
    local remove_packages="N"
    
    if [ "$purge_mode" = "purge" ]; then
        log_warn "PURGE MODE: Removing all files, configs, and packages"
        remove_sounds="y"
        remove_log="y"
        remove_config="y"
        remove_packages="y"
    fi
    
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
    
    # Remove reset cooldown script
    if [ -f "$INSTALL_RESET_SCRIPT" ]; then
        log_info "Removing reset cooldown script..."
        rm -f "$INSTALL_RESET_SCRIPT"
    fi
    
    # Remove ha-mqtt sensor descriptor
    if [ -f "$HA_MQTT_DESCRIPTOR" ]; then
        log_info "Removing ha-mqtt sensor descriptor..."
        rm -f "$HA_MQTT_DESCRIPTOR"
    fi
    
    # Remove timer file
    if [ -f "$TIMER_FILE" ]; then
        log_info "Removing timer file..."
        rm -f "$TIMER_FILE"
    fi
    
    # Handle sound files
    if [ "$purge_mode" != "purge" ]; then
        log_warn "Sound files exist in $INSTALL_SOUNDS"
        read -p "Remove sound files? (y/N): " -n 1 -r
        echo
        remove_sounds=$REPLY
    fi
    
    if [[ "$remove_sounds" =~ ^[Yy]$ ]]; then
        if [ -d "$INSTALL_SOUNDS" ]; then
            log_info "Removing sound files..."
            rm -rf "$INSTALL_SOUNDS"
        fi
    else
        log_info "Keeping sound files"
    fi
    
    # Handle log file
    if [ "$purge_mode" != "purge" ]; then
        log_warn "Log file: $LOG_FILE"
        read -p "Remove log file? (y/N): " -n 1 -r
        echo
        remove_log=$REPLY
    fi
    
    if [[ "$remove_log" =~ ^[Yy]$ ]]; then
        if [ -f "$LOG_FILE" ]; then
            log_info "Removing log file..."
            rm -f "$LOG_FILE"
        fi
    else
        log_info "Keeping log file"
    fi
    
    # Handle config file
    if [ "$purge_mode" != "purge" ]; then
        log_warn "Configuration file: $INSTALL_CONFIG"
        read -p "Remove configuration? (y/N): " -n 1 -r
        echo
        remove_config=$REPLY
    fi
    
    if [[ "$remove_config" =~ ^[Yy]$ ]]; then
        if [ -f "$INSTALL_CONFIG" ]; then
            log_info "Removing config file..."
            rm -f "$INSTALL_CONFIG"
        fi
        # Remove config directory if empty
        if [ -d "$INSTALL_CONFIG_DIR" ]; then
            if rmdir "$INSTALL_CONFIG_DIR" 2>/dev/null; then
                log_info "Removed empty config directory"
            fi
            # Try to remove parent directories if empty
            local parent_dir
            parent_dir=$(dirname "$INSTALL_CONFIG_DIR")
            rmdir "$parent_dir" 2>/dev/null || true
            parent_dir=$(dirname "$parent_dir")
            rmdir "$parent_dir" 2>/dev/null || true
        fi
    else
        log_info "Keeping config file"
    fi
    
    # Remove packages if in purge mode or requested
    if [ "$purge_mode" != "purge" ]; then
        echo ""
        # Read packages from module.json for display
        local package_list="python3-rpi-lgpio, alsa-utils"
        if [ -f "$SCRIPT_DIR/module.json" ] && command -v jq >/dev/null 2>&1; then
            local packages_json
            packages_json=$(jq -r '.apt_packages | join(", ")' "$SCRIPT_DIR/module.json" 2>/dev/null)
            [ -n "$packages_json" ] && package_list="$packages_json"
        fi
        read -p "Remove installed packages ($package_list)? (y/N): " -n 1 -r
        echo
        remove_packages=$REPLY
    fi
    
    if [[ "$remove_packages" =~ ^[Yy]$ ]]; then
        log_info "Removing packages..."
        
        # Read packages from module.json
        local packages=()
        if [ -f "$SCRIPT_DIR/module.json" ] && command -v jq >/dev/null 2>&1; then
            while IFS= read -r pkg; do
                packages+=("$pkg")
            done < <(jq -r '.apt_packages[]? // empty' "$SCRIPT_DIR/module.json" 2>/dev/null)
        else
            # Fallback to hardcoded packages
            packages=("python3-rpi-lgpio" "alsa-utils")
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
    [ -f "$INSTALL_RESET_SCRIPT" ] && echo "  ✓ Reset script: $INSTALL_RESET_SCRIPT" || echo "  ✗ Reset script not installed"
    [ -f "$INSTALL_SERVICE" ] && echo "  ✓ Service file: $INSTALL_SERVICE" || echo "  ✗ Service file not installed"
    [ -d "$INSTALL_SOUNDS" ] && echo "  ✓ Sound directory: $INSTALL_SOUNDS" || echo "  ✗ Sound directory not found"
    [ -f "$INSTALL_CONFIG" ] && echo "  ✓ Config file: $INSTALL_CONFIG" || echo "  ✗ Config file not found (using defaults)"
    echo ""
    
    # Check ha-mqtt integration
    echo "Home Assistant MQTT Integration:"
    if [ -x /usr/local/bin/luigi-publish ]; then
        echo "  ✓ ha-mqtt module installed"
        [ -f "$HA_MQTT_DESCRIPTOR" ] && echo "  ✓ Sensor descriptor: $HA_MQTT_DESCRIPTOR" || echo "  ✗ Sensor descriptor not installed"
    else
        echo "  ✗ ha-mqtt module not installed (motion detection works standalone)"
    fi
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
    install_reset_script
    install_config
    deploy_ha_mqtt_descriptor
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
