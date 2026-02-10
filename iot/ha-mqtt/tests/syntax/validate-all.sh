#!/bin/bash
#
# Syntax Validation Script for iot/ha-mqtt Module
# 
# Purpose: Validates shell script syntax for all ha-mqtt scripts
# Usage: ./validate-all.sh
# Exit codes: 0 = all valid, 1 = validation failures
#
# Part of Phase 1: Testing Strategy Implementation

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL=0
PASSED=0
FAILED=0

# Base directory (iot/ha-mqtt)
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "========================================="
echo "iot/ha-mqtt Syntax Validation"
echo "========================================="
echo ""

# Function to validate a shell script
validate_shell_script() {
    local script_path="$1"
    local script_name
    script_name="$(basename "$script_path")"
    
    TOTAL=$((TOTAL + 1))
    
    if [ ! -f "$script_path" ]; then
        echo -e "${YELLOW}SKIP${NC} $script_name (file not yet created)"
        return 0
    fi
    
    echo -n "Validating $script_name... "
    
    # Check for errors only (-S error), allow warnings and info
    if shellcheck -S error "$script_path" 2>/dev/null; then
        echo -e "${GREEN}PASS${NC}"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        FAILED=$((FAILED + 1))
        # Show shellcheck output for failures
        echo "  Errors:"
        shellcheck "$script_path" 2>&1 | sed 's/^/    /'
        echo ""
        return 1
    fi
}

echo "Phase 1.1: Shell Script Validation"
echo "-----------------------------------"
echo ""

# Validate setup.sh
validate_shell_script "$MODULE_DIR/setup.sh"

# Validate bin/ scripts
validate_shell_script "$MODULE_DIR/bin/luigi-publish"
validate_shell_script "$MODULE_DIR/bin/luigi-discover"
validate_shell_script "$MODULE_DIR/bin/luigi-mqtt-status"

# Validate lib/ scripts
validate_shell_script "$MODULE_DIR/lib/mqtt_helpers.sh"
validate_shell_script "$MODULE_DIR/lib/ha_discovery_generator.sh"

echo ""
echo "========================================="
echo "Summary"
echo "========================================="
echo "Total scripts: $TOTAL"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All syntax validation passed${NC}"
    exit 0
else
    echo -e "${RED}✗ Some scripts failed validation${NC}"
    exit 1
fi
