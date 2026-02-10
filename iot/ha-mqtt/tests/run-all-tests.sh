#!/bin/bash
#
# Master Test Runner for iot/ha-mqtt Module
#
# Purpose: Run all test layers in sequence
# Usage: ./run-all-tests.sh [--broker BROKER_HOST] [--skip-integration]
# Exit codes: 0 = all tests passed, 1 = test failures
#
# Part of Phase 1: Testing Strategy Implementation

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Base directory (iot/ha-mqtt)
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Parse command-line arguments
BROKER_HOST="${BROKER_HOST:-localhost}"
SKIP_INTEGRATION=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --broker)
            BROKER_HOST="$2"
            shift 2
            ;;
        --skip-integration)
            SKIP_INTEGRATION=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--broker BROKER_HOST] [--skip-integration]"
            echo ""
            echo "Options:"
            echo "  --broker BROKER_HOST   MQTT broker for integration tests (default: localhost)"
            echo "  --skip-integration     Skip integration tests (useful if no broker available)"
            echo "  --help, -h             Show this help message"
            echo ""
            echo "This script runs all test layers in sequence:"
            echo "  1. Syntax validation (shell + Python)"
            echo "  2. Functional tests"
            echo "  3. Integration tests (requires MQTT broker)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "========================================="
echo "iot/ha-mqtt Master Test Runner"
echo "========================================="
echo ""

# Track overall status
ALL_PASSED=true

# ============================================================================
# Layer 1: Syntax Validation
# ============================================================================

echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}Layer 1: Syntax Validation${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

echo "Running shell script syntax validation..."
if "$MODULE_DIR/tests/syntax/validate-all.sh"; then
    echo -e "${GREEN}✓ Shell syntax validation passed${NC}"
else
    echo -e "${RED}✗ Shell syntax validation failed${NC}"
    ALL_PASSED=false
fi
echo ""

echo "Running Python syntax validation..."
if "$MODULE_DIR/tests/syntax/validate-python.sh"; then
    echo -e "${GREEN}✓ Python syntax validation passed${NC}"
else
    echo -e "${RED}✗ Python syntax validation failed${NC}"
    ALL_PASSED=false
fi
echo ""

# ============================================================================
# Layer 2: Functional Testing
# ============================================================================

echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${BLUE}Layer 2: Functional Testing${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

if "$MODULE_DIR/tests/functional/run-functional-tests.sh"; then
    echo -e "${GREEN}✓ Functional tests passed${NC}"
else
    echo -e "${RED}✗ Functional tests failed${NC}"
    ALL_PASSED=false
fi
echo ""

# ============================================================================
# Layer 3: Integration Testing
# ============================================================================

if [ "$SKIP_INTEGRATION" = true ]; then
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}Layer 3: Integration Testing${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Integration tests skipped (--skip-integration flag)${NC}"
    echo ""
else
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}Layer 3: Integration Testing${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo ""
    
    if "$MODULE_DIR/tests/integration/run-integration-tests.sh" --broker "$BROKER_HOST"; then
        echo -e "${GREEN}✓ Integration tests passed${NC}"
    else
        echo -e "${RED}✗ Integration tests failed${NC}"
        ALL_PASSED=false
    fi
    echo ""
fi

# ============================================================================
# Summary
# ============================================================================

echo "========================================="
echo "Test Summary"
echo "========================================="
echo ""

if [ "$ALL_PASSED" = true ]; then
    echo -e "${GREEN}✓✓✓ ALL TESTS PASSED ✓✓✓${NC}"
    echo ""
    echo "Next steps:"
    echo "  - Proceed with code review"
    echo "  - Run security scans"
    echo "  - Execute end-to-end scenarios (see tests/E2E_SCENARIOS.md)"
    exit 0
else
    echo -e "${RED}✗✗✗ SOME TESTS FAILED ✗✗✗${NC}"
    echo ""
    echo "Please fix failing tests before proceeding."
    echo "Review test output above for details."
    exit 1
fi
