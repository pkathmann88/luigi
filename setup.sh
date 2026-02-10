#!/bin/bash
################################################################################
# Luigi - Centralized Setup Script
#
# This script discovers and executes setup scripts for all Luigi modules.
# Each module in a category directory (e.g., motion-detection/, sensors/, etc.)
# can have its own setup.sh script. This centralized script orchestrates the
# execution of all module setup scripts.
#
# Usage: sudo ./setup.sh [install|uninstall|status] [module]
#
# Arguments:
#   install   - Install all modules or a specific module (default)
#   uninstall - Uninstall all modules or a specific module
#   status    - Show status of all modules or a specific module
#   [module]  - Optional: specific module path (e.g., motion-detection/mario)
#
# Examples:
#   sudo ./setup.sh install                    # Install all modules
#   sudo ./setup.sh install motion-detection/mario  # Install specific module
#   sudo ./setup.sh status                     # Show status of all modules
#   sudo ./setup.sh uninstall                  # Uninstall all modules
#
# Author: Luigi Project
# License: MIT
################################################################################

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Category directories to search for modules
CATEGORIES=("motion-detection" "sensors" "automation" "security" "iot")

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

log_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Check if running as root (only for install/uninstall)
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root for install/uninstall operations"
        echo "Please run: sudo $0 $*"
        exit 1
    fi
}

# Discover all module setup scripts
discover_modules() {
    local modules=()
    
    # Search in all category directories
    for category in "${CATEGORIES[@]}"; do
        local category_path="$SCRIPT_DIR/$category"
        
        # Check if category directory exists
        if [ -d "$category_path" ]; then
            # Find all setup.sh scripts in subdirectories
            while IFS= read -r -d '' setup_script; do
                # Get module path relative to project root
                local module_dir
                local module_path
                module_dir=$(dirname "$setup_script")
                module_path=$(realpath --relative-to="$SCRIPT_DIR" "$module_dir")
                modules+=("$module_path")
            done < <(find "$category_path" -mindepth 2 -maxdepth 2 -name "setup.sh" -type f -print0)
        fi
    done
    
    echo "${modules[@]}"
}

# Execute a command on a specific module
execute_module_command() {
    local module_path="$1"
    local command="$2"
    local module_setup="$SCRIPT_DIR/$module_path/setup.sh"
    
    if [ ! -f "$module_setup" ]; then
        log_error "Setup script not found: $module_setup"
        return 1
    fi
    
    if [ ! -x "$module_setup" ]; then
        log_warn "Setup script not executable, adding execute permission: $module_setup"
        chmod +x "$module_setup"
    fi
    
    log_header "Module: $module_path"
    
    # Execute the module setup script with the command
    if ! "$module_setup" "$command"; then
        log_error "Failed to execute '$command' for module: $module_path"
        return 1
    fi
    
    echo ""
    return 0
}

# Install all modules or a specific module
install_modules() {
    local specific_module="$1"
    local modules
    local failed_modules=()
    local success_count=0
    
    if [ -n "$specific_module" ]; then
        # Install specific module
        modules=("$specific_module")
        log_info "Installing specific module: $specific_module"
    else
        # Discover and install all modules
        read -r -a modules <<< "$(discover_modules)"
        
        if [ ${#modules[@]} -eq 0 ]; then
            log_warn "No modules found to install"
            echo ""
            echo "Place module directories with setup.sh scripts in:"
            for category in "${CATEGORIES[@]}"; do
                echo "  - $category/"
            done
            echo ""
            return 0
        fi
        
        log_info "Found ${#modules[@]} module(s) to install"
    fi
    
    echo ""
    
    # Execute install command for each module
    for module in "${modules[@]}"; do
        if execute_module_command "$module" "install"; then
            ((success_count++))
        else
            failed_modules+=("$module")
        fi
    done
    
    # Summary
    log_header "Installation Summary"
    log_info "Successfully installed: $success_count module(s)"
    
    if [ ${#failed_modules[@]} -gt 0 ]; then
        log_error "Failed to install ${#failed_modules[@]} module(s):"
        for module in "${failed_modules[@]}"; do
            echo "  - $module"
        done
        return 1
    fi
    
    echo ""
}

# Uninstall all modules or a specific module
uninstall_modules() {
    local specific_module="$1"
    local modules
    local failed_modules=()
    local success_count=0
    
    if [ -n "$specific_module" ]; then
        # Uninstall specific module
        modules=("$specific_module")
        log_info "Uninstalling specific module: $specific_module"
    else
        # Discover and uninstall all modules
        read -r -a modules <<< "$(discover_modules)"
        
        if [ ${#modules[@]} -eq 0 ]; then
            log_warn "No modules found to uninstall"
            return 0
        fi
        
        log_info "Found ${#modules[@]} module(s) to uninstall"
    fi
    
    echo ""
    
    # Execute uninstall command for each module
    for module in "${modules[@]}"; do
        if execute_module_command "$module" "uninstall"; then
            ((success_count++))
        else
            failed_modules+=("$module")
        fi
    done
    
    # Summary
    log_header "Uninstallation Summary"
    log_info "Successfully uninstalled: $success_count module(s)"
    
    if [ ${#failed_modules[@]} -gt 0 ]; then
        log_error "Failed to uninstall ${#failed_modules[@]} module(s):"
        for module in "${failed_modules[@]}"; do
            echo "  - $module"
        done
        return 1
    fi
    
    echo ""
}

# Show status of all modules or a specific module
show_status() {
    local specific_module="$1"
    local modules
    
    if [ -n "$specific_module" ]; then
        # Show status of specific module
        modules=("$specific_module")
    else
        # Discover and show status of all modules
        read -r -a modules <<< "$(discover_modules)"
        
        if [ ${#modules[@]} -eq 0 ]; then
            log_warn "No modules found"
            echo ""
            echo "Place module directories with setup.sh scripts in:"
            for category in "${CATEGORIES[@]}"; do
                echo "  - $category/"
            done
            echo ""
            return 0
        fi
        
        log_info "Found ${#modules[@]} module(s)"
    fi
    
    echo ""
    
    # Execute status command for each module
    for module in "${modules[@]}"; do
        execute_module_command "$module" "status" || true
    done
}

# Show usage information
show_usage() {
    echo "Usage: $0 [install|uninstall|status] [module]"
    echo ""
    echo "Commands:"
    echo "  install   - Install all modules or a specific module (default)"
    echo "  uninstall - Remove all modules or a specific module"
    echo "  status    - Show installation status of all modules or a specific module"
    echo ""
    echo "Arguments:"
    echo "  [module]  - Optional: specific module path (e.g., motion-detection/mario)"
    echo ""
    echo "Examples:"
    echo "  sudo $0 install                         # Install all modules"
    echo "  sudo $0 install motion-detection/mario  # Install specific module"
    echo "  sudo $0 status                          # Show status of all modules"
    echo "  sudo $0 uninstall                       # Uninstall all modules"
    echo ""
    echo "Supported categories:"
    for category in "${CATEGORIES[@]}"; do
        echo "  - $category/"
    done
    echo ""
}

# Main script
main() {
    local action="${1:-install}"
    local module="${2:-}"
    
    case "$action" in
        install)
            check_root "$@"
            install_modules "$module"
            ;;
        uninstall)
            check_root "$@"
            uninstall_modules "$module"
            ;;
        status)
            show_status "$module"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $action"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
