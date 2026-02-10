#!/bin/bash
#
# Python Syntax Validation Script for iot/ha-mqtt Module
# 
# Purpose: Validates Python syntax for optional ha-mqtt-bridge service
# Usage: ./validate-python.sh
# Exit codes: 0 = all valid, 1 = validation failures
#
# Part of Phase 1: Testing Strategy Implementation

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Base directory (iot/ha-mqtt)
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "========================================="
echo "iot/ha-mqtt Python Syntax Validation"
echo "========================================="
echo ""

PYTHON_SERVICE="$MODULE_DIR/bin/ha-mqtt-bridge.py"

if [ ! -f "$PYTHON_SERVICE" ]; then
    echo -e "${YELLOW}SKIP${NC} ha-mqtt-bridge.py (optional service not yet created)"
    echo ""
    echo "Note: Python service is optional. This test will pass when the service is implemented."
    exit 0
fi

echo "Validating ha-mqtt-bridge.py... "

if python3 -m py_compile "$PYTHON_SERVICE" 2>/dev/null; then
    echo -e "${GREEN}PASS${NC}"
    echo ""
    echo -e "${GREEN}✓ Python syntax validation passed${NC}"
    exit 0
else
    echo -e "${RED}FAIL${NC}"
    echo ""
    echo "Errors:"
    python3 -m py_compile "$PYTHON_SERVICE" 2>&1 | sed 's/^/  /'
    echo ""
    echo -e "${RED}✗ Python syntax validation failed${NC}"
    exit 1
fi
