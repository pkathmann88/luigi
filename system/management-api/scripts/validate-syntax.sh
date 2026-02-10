#!/bin/bash
# validate-syntax.sh - Validate all JavaScript and shell scripts

set -e

echo "Luigi Management API - Syntax Validation"
echo "========================================="
echo ""

# Change to module directory
cd "$(dirname "$0")/.."

# Validate JavaScript files
echo "Validating JavaScript files..."
JS_FILES=$(find . -name "*.js" -not -path "*/node_modules/*" -not -path "*/tests/*")
JS_COUNT=0
for file in $JS_FILES; do
    echo "  Checking: $file"
    node --check "$file"
    ((JS_COUNT++))
done
echo "✓ $JS_COUNT JavaScript files passed"
echo ""

# Validate shell scripts
echo "Validating shell scripts..."
SHELL_COUNT=0

# Check scripts directory
if [ -d "scripts" ]; then
    while IFS= read -r -d '' file; do
        echo "  Checking: $file"
        shellcheck "$file" || true
        ((SHELL_COUNT++))
    done < <(find scripts -name "*.sh" -print0 2>/dev/null)
fi

# Check setup.sh
if [ -f "setup.sh" ]; then
    echo "  Checking: setup.sh"
    shellcheck setup.sh || true
    ((SHELL_COUNT++))
fi

echo "✓ $SHELL_COUNT shell scripts checked"
echo ""

# Run npm audit
if [ -f "package.json" ]; then
    echo "Running npm audit..."
    npm audit --audit-level=moderate || echo "⚠ Some vulnerabilities found"
    echo ""
fi

echo "✓ Syntax validation complete!"
