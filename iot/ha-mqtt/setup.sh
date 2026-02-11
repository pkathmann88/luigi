#!/bin/bash
#
# setup.sh - Installation script for iot/ha-mqtt module
#
# Purpose: Automate installation, configuration, and removal of ha-mqtt module
# Usage: sudo ./setup.sh [install|uninstall|status]
#
# Part of Phase 4: Setup & Deployment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation paths
INSTALL_BIN_DIR="/usr/local/bin"
INSTALL_LIB_DIR="/usr/local/lib/luigi"
INSTALL_CONFIG_DIR="/etc/luigi/iot/ha-mqtt"
INSTALL_EXAMPLES_DIR="/usr/share/luigi/ha-mqtt/examples"
SENSORS_DIR="${INSTALL_CONFIG_DIR}/sensors.d"

# Source directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Version
VERSION="1.0.0"

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    local missing=0
    
    print_info "Checking prerequisites..."
    
    # Check bash version
    if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
        print_warning "Bash 4.0 or higher recommended (found: $BASH_VERSION)"
    fi
    
    # Check for required commands
    local commands=("mosquitto_pub" "jq")
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            print_warning "$cmd not found - will attempt to install"
            missing=1
        else
            print_success "$cmd found"
        fi
    done
    
    return $missing
}

# Function to install packages
install_packages() {
    # Check if --skip-packages flag is set
    if [ "${SKIP_PACKAGES:-}" = "1" ]; then
        print_info "Skipping package installation (managed centrally)"
        return 0
    fi
    
    print_info "Installing required packages..."
    
    # Read packages from module.json
    local module_json="$SCRIPT_DIR/module.json"
    local packages=()
    
    if [ -f "$module_json" ] && command -v jq >/dev/null 2>&1; then
        # Parse apt_packages array from JSON
        while IFS= read -r pkg; do
            packages+=("$pkg")
        done < <(jq -r '.apt_packages[]? // empty' "$module_json" 2>/dev/null)
    else
        # Fallback to hardcoded packages if module.json not available
        # Note: jq is required to parse module.json, so it must be in the list
        print_warning "module.json not found or jq not available, using fallback package list"
        packages=("mosquitto-clients" "jq")
    fi
    
    # Check if packages are needed
    local to_install=()
    for pkg in "${packages[@]}"; do
        if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
            print_success "$pkg already installed"
        else
            to_install+=("$pkg")
        fi
    done
    
    # Install packages if needed
    if [ ${#to_install[@]} -gt 0 ]; then
        # Update package list
        if ! apt-get update >/dev/null 2>&1; then
            print_error "Failed to update package list"
            return 1
        fi
        
        # Install each package
        for pkg in "${to_install[@]}"; do
            print_info "Installing $pkg..."
            if apt-get install -y "$pkg" >/dev/null 2>&1; then
                print_success "$pkg installed"
            else
                print_error "Failed to install $pkg"
                return 1
            fi
        done
    fi
    
    return 0
}

# Function to create directory structure
create_directories() {
    print_info "Creating directory structure..."
    
    local directories=(
        "$INSTALL_LIB_DIR"
        "$INSTALL_CONFIG_DIR"
        "$SENSORS_DIR"
        "$INSTALL_EXAMPLES_DIR/sensors.d"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            if mkdir -p "$dir"; then
                print_success "Created: $dir"
            else
                print_error "Failed to create: $dir"
                return 1
            fi
        else
            print_success "Exists: $dir"
        fi
    done
    
    return 0
}

# Function to deploy scripts
deploy_scripts() {
    print_info "Deploying scripts..."
    
    # Deploy bin scripts
    local bin_scripts=("luigi-publish" "luigi-discover" "luigi-mqtt-status")
    for script in "${bin_scripts[@]}"; do
        local src="${SCRIPT_DIR}/bin/$script"
        local dst="${INSTALL_BIN_DIR}/$script"
        
        if [ ! -f "$src" ]; then
            print_error "Source file not found: $src"
            return 1
        fi
        
        if cp "$src" "$dst" && chmod 755 "$dst"; then
            print_success "Deployed: $script (755)"
        else
            print_error "Failed to deploy: $script"
            return 1
        fi
    done
    
    return 0
}

# Function to deploy libraries
deploy_libraries() {
    print_info "Deploying libraries..."
    
    # Deploy lib scripts
    local lib_scripts=("mqtt_helpers.sh" "ha_discovery_generator.sh")
    for script in "${lib_scripts[@]}"; do
        local src="${SCRIPT_DIR}/lib/$script"
        local dst="${INSTALL_LIB_DIR}/$script"
        
        if [ ! -f "$src" ]; then
            print_error "Source file not found: $src"
            return 1
        fi
        
        if cp "$src" "$dst" && chmod 644 "$dst"; then
            print_success "Deployed: $script (644)"
        else
            print_error "Failed to deploy: $script"
            return 1
        fi
    done
    
    return 0
}

# Function to deploy configuration
deploy_configuration() {
    print_info "Deploying configuration..."
    
    local config_src="${SCRIPT_DIR}/config/ha-mqtt.conf.example"
    local config_dst="${INSTALL_CONFIG_DIR}/ha-mqtt.conf"
    
    if [ ! -f "$config_src" ]; then
        print_error "Config example not found: $config_src"
        return 1
    fi
    
    # Only copy if config doesn't exist (don't overwrite existing)
    if [ -f "$config_dst" ]; then
        print_warning "Config already exists, not overwriting: $config_dst"
    else
        if cp "$config_src" "$config_dst" && chmod 600 "$config_dst"; then
            print_success "Deployed: ha-mqtt.conf (600)"
            print_warning "Remember to edit $config_dst with your broker settings"
        else
            print_error "Failed to deploy config"
            return 1
        fi
    fi
    
    return 0
}

# Function to deploy examples
deploy_examples() {
    print_info "Deploying examples..."
    
    # Deploy example descriptors
    if [ -d "${SCRIPT_DIR}/examples/sensors.d" ]; then
        if cp -r "${SCRIPT_DIR}/examples/sensors.d"/* "${INSTALL_EXAMPLES_DIR}/sensors.d/" 2>/dev/null; then
            chmod 644 "${INSTALL_EXAMPLES_DIR}/sensors.d"/* 2>/dev/null || true
            print_success "Deployed example sensor descriptors"
        else
            print_warning "No example descriptors to deploy"
        fi
    fi
    
    # Deploy integration guide
    if [ -f "${SCRIPT_DIR}/examples/integration-guide.md" ]; then
        cp "${SCRIPT_DIR}/examples/integration-guide.md" "${INSTALL_EXAMPLES_DIR}/" 2>/dev/null || true
        print_success "Deployed integration guide"
    fi
    
    return 0
}

# Function to test installation
test_installation() {
    print_info "Testing installation..."
    
    # Test that scripts are executable
    local scripts=("luigi-publish" "luigi-discover" "luigi-mqtt-status")
    for script in "${scripts[@]}"; do
        if command -v "$script" >/dev/null 2>&1; then
            print_success "$script is in PATH"
        else
            print_error "$script not found in PATH"
            return 1
        fi
    done
    
    # Test that libraries can be sourced
    if bash -c "source ${INSTALL_LIB_DIR}/mqtt_helpers.sh" 2>/dev/null; then
        print_success "mqtt_helpers.sh loads successfully"
    else
        print_error "mqtt_helpers.sh failed to load"
        return 1
    fi
    
    if bash -c "source ${INSTALL_LIB_DIR}/ha_discovery_generator.sh" 2>/dev/null; then
        print_success "ha_discovery_generator.sh loads successfully"
    else
        print_error "ha_discovery_generator.sh failed to load"
        return 1
    fi
    
    return 0
}

# Function to install module
install_module() {
    echo "========================================="
    echo "Luigi ha-mqtt Module Installation"
    echo "Version: $VERSION"
    echo "========================================="
    echo ""
    
    check_root
    
    # Check prerequisites
    if ! check_prerequisites; then
        if ! install_packages; then
            print_error "Failed to install required packages"
            exit 1
        fi
    fi
    
    # Create directories
    if ! create_directories; then
        print_error "Failed to create directory structure"
        exit 1
    fi
    
    # Deploy files
    if ! deploy_scripts; then
        print_error "Failed to deploy scripts"
        exit 1
    fi
    
    if ! deploy_libraries; then
        print_error "Failed to deploy libraries"
        exit 1
    fi
    
    if ! deploy_configuration; then
        print_error "Failed to deploy configuration"
        exit 1
    fi
    
    if ! deploy_examples; then
        print_error "Failed to deploy examples"
        exit 1
    fi
    
    # Test installation
    if ! test_installation; then
        print_warning "Some installation tests failed"
    fi
    
    echo ""
    echo "========================================="
    print_success "Installation complete!"
    echo "========================================="
    echo ""
    print_info "Next steps:"
    echo "  1. Edit configuration: sudo nano ${INSTALL_CONFIG_DIR}/ha-mqtt.conf"
    echo "  2. Test connectivity: luigi-mqtt-status"
    echo "  3. Add sensor descriptors to: ${SENSORS_DIR}/"
    echo "  4. Register sensors: sudo luigi-discover"
    echo "  5. Publish test value: luigi-publish --sensor test --value 42"
    echo ""
    print_info "Documentation:"
    echo "  - Module README: ${SCRIPT_DIR}/README.md"
    echo "  - Integration guide: ${INSTALL_EXAMPLES_DIR}/integration-guide.md"
    echo "  - Example descriptors: ${INSTALL_EXAMPLES_DIR}/sensors.d/"
    echo ""
}

# Function to uninstall module
uninstall_module() {
    echo "========================================="
    echo "Luigi ha-mqtt Module Uninstallation"
    echo "========================================="
    echo ""
    
    check_root
    
    # Check if purge mode is enabled
    local purge_mode="${LUIGI_PURGE_MODE:-}"
    local remove_config="N"
    local remove_packages="N"
    
    if [ "$purge_mode" = "purge" ]; then
        print_warning "PURGE MODE: Removing all files, configs, and packages"
        remove_config="y"
        remove_packages="y"
    else
        print_warning "This will remove all installed ha-mqtt files"
        echo ""
        
        # Interactive prompts for config and sensors
        read -p "Remove configuration and sensor descriptors? [y/N] " -n 1 -r
        echo ""
        remove_config=$REPLY
        
        # Only ask about packages if not skipping
        if [ "${SKIP_PACKAGES:-}" != "1" ]; then
            # Read packages from module.json for display
            local package_list="mosquitto-clients, jq"
            if [ -f "$SCRIPT_DIR/module.json" ] && command -v jq >/dev/null 2>&1; then
                local packages_json
                packages_json=$(jq -r '.apt_packages | join(", ")' "$SCRIPT_DIR/module.json" 2>/dev/null)
                [ -n "$packages_json" ] && package_list="$packages_json"
            fi
            
            read -p "Remove installed packages ($package_list)? [y/N] " -n 1 -r
            echo ""
            remove_packages=$REPLY
        fi
    fi
    
    echo ""
    print_info "Removing installed files..."
    
    # Remove scripts
    local scripts=("luigi-publish" "luigi-discover" "luigi-mqtt-status")
    for script in "${scripts[@]}"; do
        if [ -f "${INSTALL_BIN_DIR}/$script" ]; then
            if rm -f "${INSTALL_BIN_DIR}/$script"; then
                print_success "Removed: $script"
            fi
        fi
    done
    
    # Remove libraries
    if [ -d "$INSTALL_LIB_DIR" ]; then
        if rm -rf "$INSTALL_LIB_DIR"; then
            print_success "Removed: library directory"
        fi
    fi
    
    # Remove examples
    if [ -d "$INSTALL_EXAMPLES_DIR" ]; then
        if rm -rf "$INSTALL_EXAMPLES_DIR"; then
            print_success "Removed: examples directory"
        fi
    fi
    
    # Remove config if requested
    if [[ $remove_config =~ ^[Yy]$ ]]; then
        if [ -d "$INSTALL_CONFIG_DIR" ]; then
            if rm -rf "$INSTALL_CONFIG_DIR"; then
                print_success "Removed: configuration directory"
            fi
        fi
    else
        print_info "Preserved: configuration directory"
    fi
    
    # Remove packages if requested
    if [ "${SKIP_PACKAGES:-}" = "1" ]; then
        print_info "Skipping package removal (managed centrally)"
    elif [[ $remove_packages =~ ^[Yy]$ ]]; then
        echo ""
        print_info "Removing packages..."
        
        # Read packages from module.json
        local packages=()
        if [ -f "$SCRIPT_DIR/module.json" ] && command -v jq >/dev/null 2>&1; then
            while IFS= read -r pkg; do
                packages+=("$pkg")
            done < <(jq -r '.apt_packages[]? // empty' "$SCRIPT_DIR/module.json" 2>/dev/null)
        else
            # Fallback to hardcoded packages
            packages=("mosquitto-clients" "jq")
        fi
        
        for pkg in "${packages[@]}"; do
            if dpkg -l | grep -q "^ii  $pkg "; then
                print_info "Removing $pkg..."
                if apt-get remove -y "$pkg" >/dev/null 2>&1; then
                    print_success "$pkg removed"
                else
                    print_warning "Failed to remove $pkg"
                fi
            fi
        done
        
        # Clean up unused dependencies
        print_info "Removing unused dependencies..."
        apt-get autoremove -y >/dev/null 2>&1
    fi
    
    echo ""
    print_success "Uninstallation complete!"
    echo ""
}

# Function to show status
show_status() {
    echo "========================================="
    echo "Luigi ha-mqtt Module Status"
    echo "========================================="
    echo ""
    
    # Check installation
    print_info "Installation Status:"
    
    local scripts=("luigi-publish" "luigi-discover" "luigi-mqtt-status")
    local installed=0
    for script in "${scripts[@]}"; do
        if [ -f "${INSTALL_BIN_DIR}/$script" ]; then
            print_success "$script installed"
            installed=$((installed + 1))
        else
            print_error "$script not installed"
        fi
    done
    
    if [ $installed -eq 3 ]; then
        print_success "All scripts installed"
    elif [ $installed -eq 0 ]; then
        print_error "Module not installed"
        echo ""
        echo "Run: sudo ./setup.sh install"
        exit 1
    else
        print_warning "Partial installation detected"
    fi
    
    echo ""
    
    # Check configuration
    print_info "Configuration:"
    if [ -f "${INSTALL_CONFIG_DIR}/ha-mqtt.conf" ]; then
        print_success "Config file exists"
        
        # Show broker host
        if [ -r "${INSTALL_CONFIG_DIR}/ha-mqtt.conf" ]; then
            local host
            host=$(grep "^HOST=" "${INSTALL_CONFIG_DIR}/ha-mqtt.conf" | cut -d'=' -f2)
            if [ -n "$host" ]; then
                echo "  Broker: $host"
            fi
        fi
    else
        print_error "Config file missing"
    fi
    
    echo ""
    
    # Check sensor descriptors
    print_info "Sensor Descriptors:"
    if [ -d "$SENSORS_DIR" ]; then
        local count
        count=$(find "$SENSORS_DIR" -name "*.json" 2>/dev/null | wc -l)
        if [ "$count" -gt 0 ]; then
            print_success "$count descriptor(s) found"
            find "$SENSORS_DIR" -name "*.json" -exec basename {} \; 2>/dev/null | sed 's/^/  - /'
        else
            print_warning "No descriptors found"
        fi
    else
        print_error "Sensors directory missing"
    fi
    
    echo ""
    
    # Test MQTT connectivity if installed
    if [ $installed -eq 3 ]; then
        print_info "MQTT Connectivity:"
        if command -v luigi-mqtt-status >/dev/null 2>&1; then
            if luigi-mqtt-status >/dev/null 2>&1; then
                print_success "MQTT broker reachable"
            else
                print_error "Cannot connect to MQTT broker"
                echo "  Run 'luigi-mqtt-status' for details"
            fi
        fi
    fi
    
    echo ""
}

# Main function
main() {
    # Parse command and flags
    local action="${1:-}"
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
            install_module
            ;;
        uninstall)
            uninstall_module
            ;;
        status)
            show_status
            ;;
        --version|-v)
            echo "Luigi ha-mqtt setup.sh version $VERSION"
            ;;
        --help|-h|*)
            echo "Usage: sudo ./setup.sh [command] [--skip-packages]"
            echo ""
            echo "Commands:"
            echo "  install     Install the ha-mqtt module"
            echo "  uninstall   Remove the ha-mqtt module"
            echo "  status      Show installation status"
            echo "  --version   Show version information"
            echo "  --help      Show this help message"
            echo ""
            echo "Options:"
            echo "  --skip-packages  Skip apt package installation/removal (for centralized management)"
            echo ""
            echo "Examples:"
            echo "  sudo ./setup.sh install"
            echo "  sudo ./setup.sh status"
            echo "  sudo ./setup.sh uninstall"
            echo ""
            ;;
    esac
}

# Run main function
main "$@"
