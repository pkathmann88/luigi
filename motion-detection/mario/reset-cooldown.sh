#!/bin/bash
################################################################################
# Mario Motion Detection - Cooldown Reset Script
#
# This script resets the sound playback cooldown timer by removing the
# timer file. After running this script, the next motion detection will
# trigger sound playback regardless of when the last sound was played.
#
# Note: This only affects sound playback cooldown. MQTT publishing to
# Home Assistant happens on every motion event regardless of cooldown.
#
# Usage: ./reset-cooldown.sh [--help]
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

# Default paths
DEFAULT_CONFIG="/etc/luigi/motion-detection/mario/mario.conf"
DEFAULT_TIMER_FILE="/tmp/mario_timer"

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

# Show help message
show_help() {
    cat << EOF
Mario Motion Detection - Cooldown Reset Script

DESCRIPTION:
    Resets the sound playback cooldown timer, allowing the next motion
    detection to trigger sound immediately.
    
    Note: This only affects sound playback. MQTT events are always
    published to Home Assistant regardless of cooldown status.

USAGE:
    $(basename "$0") [OPTIONS]

OPTIONS:
    -h, --help          Show this help message and exit
    -f, --file PATH     Specify custom timer file path
    -c, --config PATH   Specify custom config file path

EXAMPLES:
    # Reset using default timer file location
    ./reset-cooldown.sh
    
    # Reset with custom timer file
    ./reset-cooldown.sh --file /custom/path/mario_timer
    
    # Reset using timer file from custom config
    ./reset-cooldown.sh --config /custom/mario.conf

DEFAULT LOCATIONS:
    Config:     $DEFAULT_CONFIG
    Timer File: $DEFAULT_TIMER_FILE

EOF
}

# Parse timer file from config
get_timer_file_from_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        echo "$DEFAULT_TIMER_FILE"
        return
    fi
    
    # Parse INI-style config to find TIMER_FILE under [Files] section
    local in_files_section=0
    local timer_file=""
    
    while IFS= read -r line; do
        # Remove leading/trailing whitespace
        line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^# ]]; then
            continue
        fi
        
        # Check for section headers
        if [[ "$line" =~ ^\[.*\]$ ]]; then
            if [[ "$line" == "[Files]" ]]; then
                in_files_section=1
            else
                in_files_section=0
            fi
            continue
        fi
        
        # Parse key=value in Files section
        if [[ $in_files_section -eq 1 && "$line" =~ ^TIMER_FILE= ]]; then
            timer_file=$(echo "$line" | cut -d'=' -f2-)
            break
        fi
    done < "$config_file"
    
    # Return found value or default
    if [ -n "$timer_file" ]; then
        echo "$timer_file"
    else
        echo "$DEFAULT_TIMER_FILE"
    fi
}

# Reset cooldown by deleting timer file
reset_cooldown() {
    local timer_file="$1"
    
    log_step "Resetting sound playback cooldown..."
    
    # Check if timer file exists
    if [ ! -f "$timer_file" ]; then
        log_info "Timer file does not exist: $timer_file"
        log_info "Cooldown is already reset (no active cooldown)"
        return 0
    fi
    
    # Display timer file info before deletion
    if [ -r "$timer_file" ]; then
        local last_trigger
        last_trigger=$(cat "$timer_file" 2>/dev/null || echo "unknown")
        local current_time
        current_time=$(date +%s)
        
        if [[ "$last_trigger" =~ ^[0-9]+$ ]] && [[ "$current_time" =~ ^[0-9]+$ ]]; then
            local elapsed=$((current_time - last_trigger))
            log_info "Last sound played: $elapsed seconds ago"
        fi
    fi
    
    # Remove timer file
    if rm -f "$timer_file"; then
        log_info "Timer file removed: $timer_file"
        log_info "✓ Cooldown reset successfully"
        log_info "Next motion detection will trigger sound playback"
        return 0
    else
        log_error "Failed to remove timer file: $timer_file"
        log_error "Check file permissions or run with appropriate privileges"
        return 1
    fi
}

# Main function
main() {
    local timer_file=""
    local config_file="$DEFAULT_CONFIG"
    local custom_timer_specified=0
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--file)
                if [ -z "$2" ]; then
                    log_error "Missing argument for $1"
                    echo "Use --help for usage information"
                    exit 1
                fi
                timer_file="$2"
                custom_timer_specified=1
                shift 2
                ;;
            -c|--config)
                if [ -z "$2" ]; then
                    log_error "Missing argument for $1"
                    echo "Use --help for usage information"
                    exit 1
                fi
                config_file="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Determine timer file location
    if [ $custom_timer_specified -eq 0 ]; then
        # Try to read from config
        timer_file=$(get_timer_file_from_config "$config_file")
        
        if [ "$config_file" != "$DEFAULT_CONFIG" ]; then
            log_info "Using config file: $config_file"
        fi
    fi
    
    log_info "Timer file: $timer_file"
    echo ""
    
    # Reset cooldown
    reset_cooldown "$timer_file"
}

# Run main function
main "$@"
