#!/bin/bash
################################################################################
# Luigi Setup Helpers - Common Functions for Setup Scripts
#
# This file contains shared functions used by all Luigi module setup scripts.
# Source this file at the beginning of your setup script to use these utilities.
#
# Usage:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"  # Adjust path as needed
#   source "$REPO_ROOT/util/setup-helpers.sh"
#
# Author: Luigi Project
# License: MIT
################################################################################

# Do NOT use set -e in library files
# This is a library that will be sourced by other scripts

################################################################################
# Color Output Definitions
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Success message with checkmark (for success confirmation)
log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

################################################################################
# Permission Checking
################################################################################

# Check if running as root
# Usage: check_root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        echo "Please run: sudo $0 $*"
        exit 1
    fi
}

################################################################################
# Package Management Helpers
################################################################################

# Read apt_packages array from module.json
# Usage: packages=($(read_apt_packages "$MODULE_JSON"))
# Returns: Space-separated list of package names
read_apt_packages() {
    local module_json="$1"
    local packages=()
    
    if [ -f "$module_json" ] && command -v jq >/dev/null 2>&1; then
        # Parse apt_packages array from JSON
        while IFS= read -r pkg; do
            packages+=("$pkg")
        done < <(jq -r '.apt_packages[]? // empty' "$module_json" 2>/dev/null)
    fi
    
    echo "${packages[@]}"
}

# Check if SKIP_PACKAGES flag is set
# Usage: if should_skip_packages; then return 0; fi
# Returns: 0 if packages should be skipped, 1 otherwise
should_skip_packages() {
    if [ "${SKIP_PACKAGES:-}" = "1" ]; then
        return 0
    else
        return 1
    fi
}

# Check if in purge mode (LUIGI_PURGE_MODE set by root setup.sh)
# Usage: if is_purge_mode; then ... fi
# Returns: 0 if in purge mode, 1 otherwise
is_purge_mode() {
    if [ "${LUIGI_PURGE_MODE:-}" = "1" ]; then
        return 0
    else
        return 1
    fi
}

################################################################################
# Command Availability Checking
################################################################################

# Check if a command is available
# Usage: if command_exists "jq"; then ... fi
# Returns: 0 if command exists, 1 otherwise
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if multiple commands are available
# Usage: check_required_commands "jq" "mosquitto_pub" "python3"
# Returns: 0 if all commands exist, 1 if any are missing
check_required_commands() {
    local missing=0
    
    for cmd in "$@"; do
        if ! command_exists "$cmd"; then
            log_error "Required command not found: $cmd"
            missing=1
        fi
    done
    
    return $missing
}

################################################################################
# File and Directory Operations
################################################################################

# Check if file exists with error message
# Usage: if ! check_file_exists "$file" "Config file"; then return 1; fi
# Returns: 0 if file exists, 1 otherwise
check_file_exists() {
    local file="$1"
    local description="${2:-File}"
    
    if [ ! -f "$file" ]; then
        log_error "$description not found: $file"
        return 1
    fi
    return 0
}

# Check if directory exists with error message
# Usage: if ! check_dir_exists "$dir" "Config directory"; then return 1; fi
# Returns: 0 if directory exists, 1 otherwise
check_dir_exists() {
    local dir="$1"
    local description="${2:-Directory}"
    
    if [ ! -d "$dir" ]; then
        log_error "$description not found: $dir"
        return 1
    fi
    return 0
}

# Create directory with parent directories and error handling
# Usage: if ! create_directory "$dir" "Config directory"; then return 1; fi
# Returns: 0 on success, 1 on failure
create_directory() {
    local dir="$1"
    local description="${2:-Directory}"
    
    if [ -d "$dir" ]; then
        return 0
    fi
    
    if mkdir -p "$dir"; then
        log_info "Created $description: $dir"
        return 0
    else
        log_error "Failed to create $description: $dir"
        return 1
    fi
}

# Safe file removal with error handling
# Usage: remove_file "$file" "Config file"
# Returns: 0 on success, 1 on failure (but doesn't stop on missing file)
remove_file() {
    local file="$1"
    local description="${2:-File}"
    
    if [ ! -f "$file" ]; then
        return 0
    fi
    
    if rm "$file" 2>/dev/null; then
        log_info "Removed $description: $file"
        return 0
    else
        log_warn "Failed to remove $description: $file"
        return 1
    fi
}

# Safe directory removal with error handling
# Usage: remove_directory "$dir" "Config directory"
# Returns: 0 on success, 1 on failure (but doesn't stop on missing directory)
remove_directory() {
    local dir="$1"
    local description="${2:-Directory}"
    
    if [ ! -d "$dir" ]; then
        return 0
    fi
    
    if rm -rf "$dir" 2>/dev/null; then
        log_info "Removed $description: $dir"
        return 0
    else
        log_warn "Failed to remove $description: $dir"
        return 1
    fi
}

################################################################################
# User Input Helpers
################################################################################

# Prompt user for yes/no confirmation
# Usage: if prompt_yes_no "Continue with installation?"; then ... fi
# Returns: 0 if user confirms (y/Y), 1 otherwise
prompt_yes_no() {
    local prompt="$1"
    local default="${2:-N}"
    
    if [ "$default" = "Y" ]; then
        read -p "$prompt (Y/n): " -n 1 -r
    else
        read -p "$prompt (y/N): " -n 1 -r
    fi
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

################################################################################
# Systemd Service Helpers
################################################################################

# Check if a systemd service is active
# Usage: if service_is_active "mario"; then ... fi
# Returns: 0 if service is active, 1 otherwise
service_is_active() {
    local service_name="$1"
    systemctl is-active --quiet "$service_name" 2>/dev/null
}

# Check if a systemd service is enabled
# Usage: if service_is_enabled "mario"; then ... fi
# Returns: 0 if service is enabled, 1 otherwise
service_is_enabled() {
    local service_name="$1"
    systemctl is-enabled --quiet "$service_name" 2>/dev/null
}

# Stop a systemd service safely
# Usage: stop_service "mario" "Mario Motion Detection"
# Returns: Always returns 0 (non-fatal)
stop_service() {
    local service_name="$1"
    local description="${2:-Service}"
    
    if service_is_active "$service_name"; then
        if systemctl stop "$service_name" 2>/dev/null; then
            log_info "$description stopped"
        else
            log_warn "Failed to stop $description"
        fi
    fi
    return 0
}

# Disable a systemd service safely
# Usage: disable_service "mario" "Mario Motion Detection"
# Returns: Always returns 0 (non-fatal)
disable_service() {
    local service_name="$1"
    local description="${2:-Service}"
    
    if service_is_enabled "$service_name"; then
        if systemctl disable "$service_name" 2>/dev/null; then
            log_info "$description disabled"
        else
            log_warn "Failed to disable $description"
        fi
    fi
    return 0
}

################################################################################
# Validation Helpers
################################################################################

# Validate that all required files exist
# Usage: validate_required_files "$SCRIPT_DIR/file1" "$SCRIPT_DIR/file2"
# Returns: 0 if all files exist, 1 if any are missing
validate_required_files() {
    local missing=0
    
    for file in "$@"; do
        if [ ! -f "$file" ]; then
            log_error "Required file not found: $file"
            missing=1
        fi
    done
    
    if [ $missing -eq 1 ]; then
        return 1
    fi
    
    return 0
}

################################################################################
# Export functions if needed for subshells
################################################################################

# Note: Functions are available when this file is sourced
# No need to export for typical usage in setup scripts
