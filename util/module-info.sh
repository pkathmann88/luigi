#!/bin/bash
################################################################################
# Module Info - Display detailed module information
#
# Shows both source and registry information for a module
#
# Usage: ./module-info.sh <module-path>
#   Example: ./module-info.sh motion-detection/mario
#
# Author: Luigi Project
# License: MIT
################################################################################

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <module-path>"
    echo "Example: $0 motion-detection/mario"
    exit 1
fi

MODULE_PATH="$1"
REGISTRY_FILE="/etc/luigi/modules/${MODULE_PATH/\//__}.json"
SOURCE_DIR="/home/pi/luigi/$MODULE_PATH"

# Check if jq is available
if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: sudo apt-get install jq"
    exit 1
fi

echo "Module: $MODULE_PATH"
echo "========================================"

# Check if installed
if [ -f "$REGISTRY_FILE" ]; then
    echo ""
    echo "INSTALLATION STATUS: Installed"
    echo ""
    echo "Registry Information:"
    echo "---------------------"
    jq '.' "$REGISTRY_FILE" 2>/dev/null || echo "Error reading registry file"
    
    # Get installed version
    INSTALLED_VERSION=$(jq -r '.version' "$REGISTRY_FILE" 2>/dev/null)
else
    echo ""
    echo "INSTALLATION STATUS: Not Installed"
    INSTALLED_VERSION="N/A"
fi

# Check if source exists
if [ -d "$SOURCE_DIR" ]; then
    echo ""
    echo "Source Information:"
    echo "-------------------"
    if [ -f "$SOURCE_DIR/module.json" ]; then
        jq '.' "$SOURCE_DIR/module.json" 2>/dev/null || echo "Error reading module.json"
        
        # Check for version mismatch
        SOURCE_VERSION=$(jq -r '.version' "$SOURCE_DIR/module.json" 2>/dev/null)
        if [ "$INSTALLED_VERSION" != "N/A" ] && [ "$SOURCE_VERSION" != "$INSTALLED_VERSION" ]; then
            echo ""
            echo "⚠️  Version Mismatch Detected!"
            echo "   Installed: v$INSTALLED_VERSION"
            echo "   Source:    v$SOURCE_VERSION"
            echo "   Run setup.sh to update to latest version."
        fi
    else
        echo "No module.json found in source"
    fi
    
    # Check for setup.sh
    if [ -f "$SOURCE_DIR/setup.sh" ]; then
        echo ""
        echo "Setup Script: $SOURCE_DIR/setup.sh (exists)"
    fi
else
    echo ""
    echo "Source directory not found: $SOURCE_DIR"
    if [ "$INSTALLED_VERSION" != "N/A" ]; then
        echo "⚠️  Module is installed but source is missing."
        echo "   This may indicate the repository is not present or module was moved."
    fi
fi

# Check service status if installed
if [ -f "$REGISTRY_FILE" ]; then
    SERVICE_NAME=$(jq -r '.service_name // empty' "$REGISTRY_FILE" 2>/dev/null)
    if [ -n "$SERVICE_NAME" ]; then
        echo ""
        echo "Service Status:"
        echo "---------------"
        if systemctl status "$SERVICE_NAME" --no-pager 2>/dev/null; then
            :
        else
            echo "Service not found or not running"
        fi
    fi
    
    # Show configuration path
    CONFIG_PATH=$(jq -r '.config_path // empty' "$REGISTRY_FILE" 2>/dev/null)
    if [ -n "$CONFIG_PATH" ]; then
        echo ""
        echo "Configuration:"
        echo "--------------"
        echo "Path: $CONFIG_PATH"
        if [ -d "$CONFIG_PATH" ]; then
            echo "Files:"
            ls -lh "$CONFIG_PATH" 2>/dev/null || echo "  (empty or inaccessible)"
        else
            echo "Configuration directory not found"
        fi
    fi
    
    # Show log file
    LOG_PATH=$(jq -r '.log_path // empty' "$REGISTRY_FILE" 2>/dev/null)
    if [ -n "$LOG_PATH" ]; then
        echo ""
        echo "Log File:"
        echo "---------"
        echo "Path: $LOG_PATH"
        if [ -f "$LOG_PATH" ]; then
            LOG_SIZE=$(du -h "$LOG_PATH" | cut -f1)
            LOG_LINES=$(wc -l < "$LOG_PATH")
            echo "Size: $LOG_SIZE ($LOG_LINES lines)"
            echo ""
            echo "Last 10 lines:"
            tail -n 10 "$LOG_PATH" 2>/dev/null | sed 's/^/  /'
        else
            echo "Log file not found"
        fi
    fi
fi

echo ""
