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

################################################################################
# Module Registry Helpers
################################################################################

# Registry path constant
LUIGI_REGISTRY_PATH="/etc/luigi/modules"

# Update module registry entry
# Usage: update_module_registry "motion-detection/mario" "1.0.0" "installed"
# Returns: 0 on success, 1 on failure
update_module_registry() {
    local module_path="$1"
    local version="$2"
    local status="${3:-installed}"
    
    if [ -z "$module_path" ] || [ -z "$version" ]; then
        log_error "update_module_registry: module_path and version are required"
        return 1
    fi
    
    local name
    name=$(basename "$module_path")
    local category
    category=$(dirname "$module_path")
    local registry_file="$LUIGI_REGISTRY_PATH/${module_path/\//__}.json"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    # Preserve installed_at if exists
    local installed_at="$timestamp"
    if [ -f "$registry_file" ]; then
        if command_exists jq; then
            installed_at=$(jq -r '.installed_at' "$registry_file" 2>/dev/null || echo "$timestamp")
        fi
    fi
    
    # Create registry directory if needed
    if ! create_directory "$LUIGI_REGISTRY_PATH" "Registry directory"; then
        return 1
    fi
    
    # Create registry entry
    cat > "$registry_file" <<EOF
{
  "module_path": "$module_path",
  "name": "$name",
  "version": "$version",
  "category": "$category",
  "installed_at": "$installed_at",
  "updated_at": "$timestamp",
  "installed_by": "setup.sh",
  "install_method": "manual",
  "status": "$status"
}
EOF
    
    if [ $? -eq 0 ]; then
        log_info "Updated module registry: $registry_file"
        return 0
    else
        log_error "Failed to update module registry: $registry_file"
        return 1
    fi
}

# Update full module registry entry with metadata from module.json
# Usage: update_module_registry_full "motion-detection/mario" "$SCRIPT_DIR/module.json" "active"
# Returns: 0 on success, 1 on failure
update_module_registry_full() {
    local module_path="$1"
    local module_json_file="$2"
    local status="${3:-installed}"
    
    if [ -z "$module_path" ] || [ ! -f "$module_json_file" ]; then
        log_error "update_module_registry_full: module_path and module.json file are required"
        return 1
    fi
    
    if ! command_exists jq; then
        log_warn "jq not available, falling back to basic registry update"
        local version
        version=$(grep -oP '"version"\s*:\s*"\K[^"]+' "$module_json_file" 2>/dev/null || echo "0.0.0")
        update_module_registry "$module_path" "$version" "$status"
        return $?
    fi
    
    local name
    name=$(basename "$module_path")
    local category
    category=$(dirname "$module_path")
    local registry_file="$LUIGI_REGISTRY_PATH/${module_path/\//__}.json"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    # Preserve installed_at if exists
    local installed_at="$timestamp"
    if [ -f "$registry_file" ]; then
        installed_at=$(jq -r '.installed_at' "$registry_file" 2>/dev/null || echo "$timestamp")
    fi
    
    # Create registry directory if needed
    if ! create_directory "$LUIGI_REGISTRY_PATH" "Registry directory"; then
        return 1
    fi
    
    # Read metadata from module.json
    local metadata
    metadata=$(cat "$module_json_file")
    
    # Extract fields with jq
    local version
    version=$(echo "$metadata" | jq -r '.version // "0.0.0"')
    local description
    description=$(echo "$metadata" | jq -r '.description // ""' | jq -R .)
    local author
    author=$(echo "$metadata" | jq -r '.author // ""' | jq -R .)
    local capabilities
    capabilities=$(echo "$metadata" | jq -c '.capabilities // []')
    local dependencies
    dependencies=$(echo "$metadata" | jq -c '.dependencies // []')
    local apt_packages
    apt_packages=$(echo "$metadata" | jq -c '.apt_packages // []')
    local hardware
    hardware=$(echo "$metadata" | jq -c '.hardware // null')
    local provides
    provides=$(echo "$metadata" | jq -c '.provides // []')
    
    # Create full registry entry
    # Note: config_path should always point to the actual config file, not a directory
    # Standard format: /etc/luigi/<module-path>/<module-name>.conf
    cat > "$registry_file" <<EOF
{
  "module_path": "$module_path",
  "name": "$name",
  "version": "$version",
  "category": "$category",
  "description": $description,
  "installed_at": "$installed_at",
  "updated_at": "$timestamp",
  "installed_by": "setup.sh",
  "install_method": "manual",
  "status": "$status",
  "capabilities": $capabilities,
  "dependencies": $dependencies,
  "apt_packages": $apt_packages,
  "author": $author,
  "hardware": $hardware,
  "provides": $provides,
  "service_name": "$name.service",
  "config_path": "/etc/luigi/$module_path/$name.conf",
  "log_path": "/var/log/luigi/$name.log"
}
EOF
    
    if [ $? -eq 0 ]; then
        log_info "Updated module registry with full metadata: $registry_file"
        return 0
    else
        log_error "Failed to update module registry: $registry_file"
        return 1
    fi
}

# Check if module is installed
# Usage: if is_module_installed "motion-detection/mario"; then ... fi
# Returns: 0 if module is installed, 1 otherwise
is_module_installed() {
    local module_path="$1"
    local registry_file="$LUIGI_REGISTRY_PATH/${module_path/\//__}.json"
    
    if [ ! -f "$registry_file" ]; then
        return 1
    fi
    
    if command_exists jq; then
        local status
        status=$(jq -r '.status' "$registry_file" 2>/dev/null)
        [ "$status" != "removed" ]
    else
        # If jq not available, assume installed if file exists
        return 0
    fi
}

# Get installed module version
# Usage: version=$(get_installed_version "motion-detection/mario")
# Returns: Version string or "0.0.0" if not installed
get_installed_version() {
    local module_path="$1"
    local registry_file="$LUIGI_REGISTRY_PATH/${module_path/\//__}.json"
    
    if [ ! -f "$registry_file" ]; then
        echo "0.0.0"
        return
    fi
    
    if command_exists jq; then
        jq -r '.version' "$registry_file" 2>/dev/null || echo "0.0.0"
    else
        # Try to extract version without jq
        grep -oP '"version"\s*:\s*"\K[^"]+' "$registry_file" 2>/dev/null || echo "0.0.0"
    fi
}

# Mark module as removed in registry
# Usage: mark_module_removed "motion-detection/mario"
# Returns: 0 on success, 1 on failure
mark_module_removed() {
    local module_path="$1"
    local registry_file="$LUIGI_REGISTRY_PATH/${module_path/\//__}.json"
    
    if [ ! -f "$registry_file" ]; then
        log_warn "Registry entry not found for $module_path"
        return 1
    fi
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    if command_exists jq; then
        jq ".status = \"removed\" | .updated_at = \"$timestamp\" | .service_enabled = false" \
            "$registry_file" > /tmp/registry.json
        if mv /tmp/registry.json "$registry_file"; then
            log_info "Marked module as removed in registry: $module_path"
            return 0
        else
            log_error "Failed to update registry for $module_path"
            return 1
        fi
    else
        log_warn "jq not available, cannot update registry"
        return 1
    fi
}

# Update registry service status
# Usage: update_registry_service_status "motion-detection/mario" "active" true
# Returns: 0 on success, 1 on failure
update_registry_service_status() {
    local module_path="$1"
    local status="$2"
    local enabled="${3:-false}"
    local registry_file="$LUIGI_REGISTRY_PATH/${module_path/\//__}.json"
    
    if [ ! -f "$registry_file" ]; then
        log_warn "Registry entry not found for $module_path"
        return 1
    fi
    
    if ! command_exists jq; then
        log_warn "jq not available, cannot update service status"
        return 1
    fi
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    jq ".status = \"$status\" | .service_enabled = $enabled | .updated_at = \"$timestamp\"" \
        "$registry_file" > /tmp/registry.json
    
    if mv /tmp/registry.json "$registry_file"; then
        log_info "Updated service status in registry: $module_path ($status)"
        return 0
    else
        log_error "Failed to update registry for $module_path"
        return 1
    fi
}

# Get registry file path for a module
# Usage: registry_file=$(get_registry_file "motion-detection/mario")
# Returns: Path to registry file
get_registry_file() {
    local module_path="$1"
    echo "$LUIGI_REGISTRY_PATH/${module_path/\//__}.json"
}

