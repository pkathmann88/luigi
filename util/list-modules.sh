#!/bin/bash
################################################################################
# List Modules - Display all installed Luigi modules
#
# Reads the centralized module registry and displays module information
#
# Usage: ./list-modules.sh [--format json|table|simple]
#
# Formats:
#   table  - Formatted table with columns (default)
#   json   - JSON array of all registry entries
#   simple - Simple list of module paths only
#
# Author: Luigi Project
# License: MIT
################################################################################

set -e

REGISTRY_PATH="/etc/luigi/modules"

# Parse arguments
FORMAT="${1:-table}"

# Validate format
case "$FORMAT" in
    --format)
        FORMAT="${2:-table}"
        ;;
    table|json|simple)
        # Valid format
        ;;
    *)
        echo "Error: Invalid format '$FORMAT'. Use 'json', 'table', or 'simple'."
        echo "Usage: $0 [--format json|table|simple]"
        exit 1
        ;;
esac

# Check if registry directory exists
if [ ! -d "$REGISTRY_PATH" ]; then
    echo "Error: Module registry not found at $REGISTRY_PATH"
    echo "No modules are currently registered."
    exit 1
fi

# Check if jq is available
if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: sudo apt-get install jq"
    exit 1
fi

# List modules in JSON format
list_modules_json() {
    echo "["
    local first=true
    for file in "$REGISTRY_PATH"/*.json; do
        [ -f "$file" ] || continue
        
        # Skip removed modules in simple listing
        local status=$(jq -r '.status' "$file" 2>/dev/null)
        
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi
        cat "$file"
    done
    echo "]"
}

# List modules in table format
list_modules_table() {
    printf "%-40s %-15s %-12s\n" "MODULE PATH" "VERSION" "STATUS"
    printf "%-40s %-15s %-12s\n" "----------------------------------------" "---------------" "------------"
    
    local count=0
    for file in "$REGISTRY_PATH"/*.json; do
        [ -f "$file" ] || continue
        
        local module_path=$(jq -r '.module_path' "$file" 2>/dev/null)
        local version=$(jq -r '.version' "$file" 2>/dev/null)
        local status=$(jq -r '.status' "$file" 2>/dev/null)
        
        # Skip removed modules in simple listing
        [ "$status" = "removed" ] && continue
        
        printf "%-40s %-15s %-12s\n" "$module_path" "$version" "$status"
        count=$((count + 1))
    done
    
    echo ""
    echo "Total: $count modules"
}

# List modules in simple format (just paths)
list_modules_simple() {
    for file in "$REGISTRY_PATH"/*.json; do
        [ -f "$file" ] || continue
        
        local module_path=$(jq -r '.module_path' "$file" 2>/dev/null)
        local status=$(jq -r '.status' "$file" 2>/dev/null)
        
        # Skip removed modules
        [ "$status" = "removed" ] && continue
        
        echo "$module_path"
    done
}

# Execute based on format
case "$FORMAT" in
    json)
        list_modules_json
        ;;
    table)
        list_modules_table
        ;;
    simple)
        list_modules_simple
        ;;
esac
