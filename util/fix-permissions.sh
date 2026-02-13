#!/bin/bash
################################################################################
# Luigi Permission Fix Script
#
# This script resets permissions on all Luigi log files and config directories
# to ensure the management-api service can read them.
#
# The management-api service runs as 'luigi-api' user and needs read access to:
# - Log files in /var/log/luigi/
# - Config directories and files in /etc/luigi/
#
# This script scans the module registry and fixes permissions for all installed
# modules.
#
# Usage: sudo ./fix-permissions.sh
#
# Author: Luigi Project
# License: MIT
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Constants
LUIGI_REGISTRY_PATH="${LUIGI_REGISTRY_PATH:-/etc/luigi/modules}"
LOG_DIR="/var/log/luigi"
CONFIG_BASE="/etc/luigi"

# Ensure luigi-api group exists
ensure_luigi_api_group() {
    if ! getent group luigi-api >/dev/null 2>&1; then
        log_info "Creating luigi-api group"
        if groupadd --system luigi-api; then
            log_info "Created luigi-api group"
        else
            log_error "Failed to create luigi-api group"
            return 1
        fi
    fi
    return 0
}

# Fix base directory permissions
fix_base_directories() {
    log_step "Fixing base directory permissions..."
    
    # /etc/luigi
    if [ -d "$CONFIG_BASE" ]; then
        chown root:luigi-api "$CONFIG_BASE"
        chmod 755 "$CONFIG_BASE"
        log_info "Fixed: $CONFIG_BASE (root:luigi-api, 755)"
    fi
    
    # /var/log/luigi
    if [ -d "$LOG_DIR" ]; then
        chown root:luigi-api "$LOG_DIR"
        chmod 755 "$LOG_DIR"
        log_info "Fixed: $LOG_DIR (root:luigi-api, 755)"
    fi
    
    # Registry directory
    if [ -d "$LUIGI_REGISTRY_PATH" ]; then
        chown -R root:luigi-api "$LUIGI_REGISTRY_PATH"
        chmod 755 "$LUIGI_REGISTRY_PATH"
        find "$LUIGI_REGISTRY_PATH" -type f -exec chmod 644 {} \;
        log_info "Fixed: $LUIGI_REGISTRY_PATH (root:luigi-api)"
    fi
}

# Fix log file permissions
fix_log_permissions() {
    log_step "Fixing log file permissions..."
    
    if [ ! -d "$LOG_DIR" ]; then
        log_warn "Log directory does not exist: $LOG_DIR"
        return 0
    fi
    
    local fixed_count=0
    
    # Find all .log files
    while IFS= read -r -d '' log_file; do
        # Set ownership and permissions
        # Files owned by their module user, group luigi-api, mode 640
        chown "$(stat -c '%U' "$log_file"):luigi-api" "$log_file" 2>/dev/null || chown "root:luigi-api" "$log_file"
        chmod 640 "$log_file"
        log_info "Fixed: $log_file ($(stat -c '%U' "$log_file"):luigi-api, 640)"
        ((fixed_count++))
    done < <(find "$LOG_DIR" -type f -name "*.log" -print0 2>/dev/null)
    
    if [ $fixed_count -eq 0 ]; then
        log_info "No log files found in $LOG_DIR"
    else
        log_info "Fixed permissions on $fixed_count log file(s)"
    fi
}

# Fix config directory and file permissions
fix_config_permissions() {
    log_step "Fixing config directory permissions..."
    
    if [ ! -d "$CONFIG_BASE" ]; then
        log_warn "Config base directory does not exist: $CONFIG_BASE"
        return 0
    fi
    
    local fixed_dirs=0
    local fixed_files=0
    
    # Find all subdirectories
    while IFS= read -r -d '' config_dir; do
        # Skip the base directory itself
        if [ "$config_dir" = "$CONFIG_BASE" ]; then
            continue
        fi
        
        # Set directory permissions
        chown root:luigi-api "$config_dir"
        chmod 755 "$config_dir"
        ((fixed_dirs++))
        
        # Set file permissions in this directory
        while IFS= read -r -d '' config_file; do
            chown root:luigi-api "$config_file"
            chmod 644 "$config_file"
            ((fixed_files++))
        done < <(find "$config_dir" -maxdepth 1 -type f -print0 2>/dev/null)
        
        log_info "Fixed: $config_dir (root:luigi-api)"
    done < <(find "$CONFIG_BASE" -type d -print0 2>/dev/null)
    
    log_info "Fixed permissions on $fixed_dirs directories and $fixed_files files"
}

# Fix permissions based on registry entries
fix_from_registry() {
    log_step "Fixing permissions from registry entries..."
    
    if [ ! -d "$LUIGI_REGISTRY_PATH" ]; then
        log_warn "Registry directory not found: $LUIGI_REGISTRY_PATH"
        return 0
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        log_warn "jq not available, skipping registry-based fixes"
        return 0
    fi
    
    local fixed_count=0
    
    # Process each registry file
    for registry_file in "$LUIGI_REGISTRY_PATH"/*.json; do
        if [ ! -f "$registry_file" ]; then
            continue
        fi
        
        # Extract paths from registry
        local module_name
        module_name=$(jq -r '.name // empty' "$registry_file" 2>/dev/null)
        local config_path
        config_path=$(jq -r '.config_path // empty' "$registry_file" 2>/dev/null)
        local log_path
        log_path=$(jq -r '.log_path // empty' "$registry_file" 2>/dev/null)
        
        if [ -z "$module_name" ]; then
            continue
        fi
        
        log_info "Processing module: $module_name"
        
        # Fix config path
        if [ -n "$config_path" ] && [ "$config_path" != "null" ]; then
            if [ -f "$config_path" ]; then
                chown root:luigi-api "$config_path"
                chmod 644 "$config_path"
                log_info "  Config file: $config_path"
            elif [ -d "$config_path" ]; then
                chown root:luigi-api "$config_path"
                chmod 755 "$config_path"
                find "$config_path" -type f -exec chown root:luigi-api {} \;
                find "$config_path" -type f -exec chmod 644 {} \;
                log_info "  Config directory: $config_path"
            fi
        fi
        
        # Fix log path
        if [ -n "$log_path" ] && [ "$log_path" != "null" ]; then
            if [ -f "$log_path" ]; then
                chown "$(stat -c '%U' "$log_path"):luigi-api" "$log_path" 2>/dev/null || chown "root:luigi-api" "$log_path"
                chmod 640 "$log_path"
                log_info "  Log file: $log_path"
            fi
        fi
        
        ((fixed_count++))
    done
    
    if [ $fixed_count -eq 0 ]; then
        log_info "No modules found in registry"
    else
        log_info "Processed $fixed_count module(s) from registry"
    fi
}

# Main execution
main() {
    echo "========================================================================"
    echo "  Luigi Permission Fix Script"
    echo "========================================================================"
    echo ""
    
    log_info "Starting permission fixes..."
    
    # Ensure luigi-api group exists
    ensure_luigi_api_group || exit 1
    
    # Fix permissions
    fix_base_directories
    fix_log_permissions
    fix_config_permissions
    fix_from_registry
    
    echo ""
    log_info "Permission fixes complete!"
    echo ""
    echo "Summary:"
    echo "  - Base directories: fixed"
    echo "  - Log files: checked and fixed"
    echo "  - Config directories: checked and fixed"
    echo "  - Registry entries: processed"
    echo ""
    log_info "The management-api service can now read all log files and configs"
}

main
