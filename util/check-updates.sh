#!/bin/bash
################################################################################
# Check Updates - Check for available module updates
#
# Compares registry versions with source versions
#
# Usage: ./check-updates.sh [module-path]
#   No args: Check all modules
#   With arg: Check specific module
#
# Author: Luigi Project
# License: MIT
################################################################################

set -e

REGISTRY_PATH="/etc/luigi/modules"
SOURCE_ROOT="/home/pi/luigi"

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if jq is available
if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: sudo apt-get install jq"
    exit 1
fi

# Check single module
check_module_update() {
    local registry_file="$1"
    
    local module_path=$(jq -r '.module_path' "$registry_file" 2>/dev/null)
    local current_version=$(jq -r '.version' "$registry_file" 2>/dev/null)
    local status=$(jq -r '.status' "$registry_file" 2>/dev/null)
    
    # Skip removed modules
    [ "$status" = "removed" ] && return 0
    
    local source_dir="$SOURCE_ROOT/$module_path"
    local source_json="$source_dir/module.json"
    
    if [ ! -f "$source_json" ]; then
        echo -e "${YELLOW}⚠️  $module_path${NC} - No source metadata (current: v$current_version)"
        return 0
    fi
    
    local source_version=$(jq -r '.version' "$source_json" 2>/dev/null)
    
    if [ "$source_version" != "$current_version" ]; then
        echo -e "${BLUE}🔄 $module_path${NC} - Update available: ${YELLOW}v$current_version → v$source_version${NC}"
    else
        echo -e "${GREEN}✅ $module_path${NC} - Up to date (v$current_version)"
    fi
}

# Main execution
if [ $# -eq 1 ]; then
    # Check specific module
    MODULE_PATH="$1"
    REGISTRY_FILE="$REGISTRY_PATH/${MODULE_PATH/\//__}.json"
    
    if [ ! -f "$REGISTRY_FILE" ]; then
        echo -e "${RED}Error: Module '$MODULE_PATH' is not installed${NC}"
        exit 1
    fi
    
    check_module_update "$REGISTRY_FILE"
else
    # Check all modules
    echo "Checking for module updates..."
    echo ""
    
    if [ ! -d "$REGISTRY_PATH" ]; then
        echo -e "${RED}Error: Module registry not found at $REGISTRY_PATH${NC}"
        exit 1
    fi
    
    update_count=0
    uptodate_count=0
    missing_count=0
    
    for file in "$REGISTRY_PATH"/*.json; do
        [ -f "$file" ] || continue
        
        module_path=$(jq -r '.module_path' "$file" 2>/dev/null)
        current_version=$(jq -r '.version' "$file" 2>/dev/null)
        status=$(jq -r '.status' "$file" 2>/dev/null)
        
        # Skip removed modules
        [ "$status" = "removed" ] && continue
        
        source_json="$SOURCE_ROOT/$module_path/module.json"
        
        if [ ! -f "$source_json" ]; then
            echo -e "${YELLOW}⚠️  $module_path${NC} - No source metadata (current: v$current_version)"
            missing_count=$((missing_count + 1))
            continue
        fi
        
        source_version=$(jq -r '.version' "$source_json" 2>/dev/null)
        
        if [ "$source_version" != "$current_version" ]; then
            echo -e "${BLUE}🔄 $module_path${NC} - Update available: ${YELLOW}v$current_version → v$source_version${NC}"
            update_count=$((update_count + 1))
        else
            echo -e "${GREEN}✅ $module_path${NC} - Up to date (v$current_version)"
            uptodate_count=$((uptodate_count + 1))
        fi
    done
    
    echo ""
    echo "Summary:"
    echo "--------"
    echo "Up to date:         $uptodate_count"
    echo "Updates available:  $update_count"
    echo "Missing source:     $missing_count"
    
    if [ $update_count -gt 0 ]; then
        echo ""
        echo -e "${BLUE}To update modules, run their setup.sh scripts:${NC}"
        echo "  cd /home/pi/luigi/<module-path>"
        echo "  sudo ./setup.sh install"
    fi
fi
