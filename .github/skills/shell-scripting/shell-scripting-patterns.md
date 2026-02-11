# Advanced Shell Scripting Patterns for Luigi

This document covers advanced shell scripting patterns used in the Luigi repository, including JSON parsing, array operations, library sourcing, and testing frameworks.

## JSON Parsing with jq

### Reading JSON Arrays

**Parse apt_packages from module.json:**
```bash
# Read array values into bash array
get_apt_packages() {
    local module_json="$1"
    local packages=()
    
    if [ -f "$module_json" ] && command -v jq >/dev/null 2>&1; then
        while IFS= read -r pkg; do
            packages+=("$pkg")
        done < <(jq -r '.apt_packages[]? // empty' "$module_json" 2>/dev/null)
    fi
    
    echo "${packages[@]}"
}

# Usage
packages=($(get_apt_packages "$MODULE_JSON"))
```

### Reading JSON Objects

**Parse nested configuration:**
```bash
# Read sensor descriptor
parse_sensor_descriptor() {
    local descriptor_file="$1"
    
    if [ ! -f "$descriptor_file" ]; then
        return 1
    fi
    
    # Extract fields
    SENSOR_ID=$(jq -r '.sensor_id // empty' "$descriptor_file")
    SENSOR_NAME=$(jq -r '.name // empty' "$descriptor_file")
    DEVICE_CLASS=$(jq -r '.device_class // empty' "$descriptor_file")
    UNIT=$(jq -r '.unit_of_measurement // empty' "$descriptor_file")
    ICON=$(jq -r '.icon // empty' "$descriptor_file")
}
```

### Generating JSON

**Create JSON output:**
```bash
# Generate discovery message
generate_discovery_json() {
    local sensor_id="$1"
    local sensor_name="$2"
    local device_class="$3"
    
    cat <<EOF
{
  "name": "$sensor_name",
  "unique_id": "${sensor_id}",
  "device_class": "$device_class",
  "state_topic": "luigi/sensor/${sensor_id}/state",
  "availability_topic": "luigi/status",
  "device": {
    "identifiers": ["luigi_$(hostname)"],
    "name": "Luigi $(hostname)",
    "model": "Raspberry Pi Zero W",
    "manufacturer": "Luigi Project"
  }
}
EOF
}

# Use jq to validate and format
json=$(generate_discovery_json "$id" "$name" "$class")
echo "$json" | jq -c '.'  # Compact output
```

### Validating JSON

**Check JSON syntax:**
```bash
validate_json() {
    local json_file="$1"
    
    if ! jq empty "$json_file" 2>/dev/null; then
        log_error "Invalid JSON in file: $json_file"
        return 1
    fi
    
    return 0
}
```

## Array Operations

### Creating and Populating Arrays

**Multiple methods:**
```bash
# Literal array
files=("file1.txt" "file2.txt" "file3.txt")

# From command output
packages=($(get_apt_packages))

# From file (one item per line)
mapfile -t lines < file.txt

# Using while loop
items=()
while IFS= read -r line; do
    items+=("$line")
done < file.txt
```

### Iterating Arrays

**Standard iteration:**
```bash
# Iterate over values
for item in "${array[@]}"; do
    echo "Processing: $item"
done

# Iterate with indices
for i in "${!array[@]}"; do
    echo "Index $i: ${array[$i]}"
done
```

### Array Length and Checking

**Common operations:**
```bash
# Get array length
length=${#array[@]}

# Check if array is empty
if [ ${#array[@]} -eq 0 ]; then
    echo "Array is empty"
fi

# Check if element exists
if [[ " ${array[*]} " =~ " ${search_item} " ]]; then
    echo "Found: $search_item"
fi
```

### Joining Array Elements

**Convert array to string:**
```bash
# Join with spaces
echo "${array[*]}"

# Join with custom delimiter
IFS=','
joined="${array[*]}"
IFS=' '  # Reset IFS

# Using printf
printf '%s, ' "${array[@]}" | sed 's/, $//'
```

## String Manipulation

### Substring Operations

**Extract and replace:**
```bash
string="motion-detection/mario"

# Extract substring
category="${string%%/*}"        # "motion-detection"
module="${string##*/}"          # "mario"

# Remove prefix/suffix
without_prefix="${string#motion-}"    # "detection/mario"
without_suffix="${string%/*}"         # "motion-detection"

# Replace substring
new_string="${string/detection/sensor}"  # "motion-sensor/mario"
```

### Pattern Matching

**Check if string matches pattern:**
```bash
# Check if string contains substring
if [[ "$string" == *"detection"* ]]; then
    echo "Contains 'detection'"
fi

# Regex matching
if [[ "$string" =~ ^[a-z0-9_-]+$ ]]; then
    echo "Valid identifier"
fi

# Case-insensitive matching
shopt -s nocasematch
if [[ "$string" == *"MARIO"* ]]; then
    echo "Found (case-insensitive)"
fi
shopt -u nocasematch
```

### Trimming Whitespace

**Remove leading/trailing spaces:**
```bash
# Using parameter expansion
trimmed="${string#"${string%%[![:space:]]*}"}"
trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"

# Using sed
trimmed=$(echo "$string" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

# Using xargs (simple method)
trimmed=$(echo "$string" | xargs)
```

## Library Sourcing Patterns

### Creating Reusable Libraries

**Library file structure (mqtt_helpers.sh):**
```bash
#!/bin/bash
# mqtt_helpers.sh - MQTT helper functions
# Do NOT use set -e in library files

# Library functions
load_config() {
    # Function implementation
    :
}

publish_message() {
    # Function implementation
    :
}

# Export functions if needed
export -f load_config
export -f publish_message
```

### Sourcing Libraries

**Standard sourcing pattern:**
```bash
# Define library location
LIB_DIR="/usr/local/lib/luigi"
if [ ! -d "$LIB_DIR" ]; then
    # Development fallback
    LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)"
fi

# Source library with error checking
# shellcheck source=../lib/mqtt_helpers.sh
if [ -f "$LIB_DIR/mqtt_helpers.sh" ]; then
    source "$LIB_DIR/mqtt_helpers.sh"
else
    >&2 echo "Error: Cannot find mqtt_helpers.sh library"
    >&2 echo "Expected location: $LIB_DIR/mqtt_helpers.sh"
    exit 2
fi
```

### Library Dependencies

**Check library availability:**
```bash
# Verify library functions are available
if ! declare -f load_config >/dev/null; then
    echo "Error: load_config function not found"
    echo "mqtt_helpers.sh may not be sourced correctly"
    exit 2
fi
```

## Subprocess Management

### Background Processes

**Run command in background:**
```bash
# Start background process
long_running_command &
pid=$!

# Wait for background process
wait $pid
if [ $? -eq 0 ]; then
    echo "Background process succeeded"
fi

# Kill background process if needed
kill $pid 2>/dev/null || true
```

### Process Monitoring

**Check if process is running:**
```bash
# Check by PID
if kill -0 $pid 2>/dev/null; then
    echo "Process $pid is running"
else
    echo "Process $pid is not running"
fi

# Check by name (use with caution)
if pgrep -x "mario.py" >/dev/null; then
    echo "mario.py is running"
fi
```

### Timeouts

**Run command with timeout:**
```bash
# Using timeout command
if timeout 30s long_running_command; then
    echo "Command completed within timeout"
else
    exit_code=$?
    if [ $exit_code -eq 124 ]; then
        echo "Command timed out"
    else
        echo "Command failed with exit code: $exit_code"
    fi
fi
```

## Signal Handling

### Trap for Cleanup

**Cleanup on exit:**
```bash
# Cleanup function
cleanup() {
    local exit_code=$?
    echo "Cleaning up..."
    
    # Remove temporary files
    rm -f /tmp/tempfile.$$
    
    # Stop background processes
    if [ -n "$background_pid" ]; then
        kill $background_pid 2>/dev/null || true
    fi
    
    exit $exit_code
}

# Set trap
trap cleanup EXIT INT TERM

# Script continues...
# cleanup() will be called automatically on exit
```

### Signal Handling

**Handle specific signals:**
```bash
# Handle SIGINT (Ctrl+C)
handle_interrupt() {
    echo ""
    echo "Interrupted by user"
    cleanup
    exit 130
}

trap handle_interrupt INT

# Handle SIGTERM
handle_terminate() {
    echo "Received termination signal"
    cleanup
    exit 143
}

trap handle_terminate TERM
```

## Logging to Files

### Basic File Logging

**Log to file and console:**
```bash
LOG_FILE="/var/log/luigi/module.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Log function
log_to_file() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Also log to console
    case $level in
        INFO)
            log_info "$message"
            ;;
        WARN)
            log_warn "$message"
            ;;
        ERROR)
            log_error "$message"
            ;;
    esac
}

# Usage
log_to_file INFO "Starting installation"
log_to_file ERROR "Failed to install package"
```

### Log Rotation

**Rotate logs manually:**
```bash
rotate_log() {
    local log_file="$1"
    local max_size=$((10 * 1024 * 1024))  # 10 MB
    
    if [ ! -f "$log_file" ]; then
        return 0
    fi
    
    local size=$(stat -c%s "$log_file" 2>/dev/null || echo 0)
    
    if [ $size -gt $max_size ]; then
        # Rotate logs
        mv "$log_file" "${log_file}.1"
        [ -f "${log_file}.1" ] && gzip "${log_file}.1"
        touch "$log_file"
        log_info "Log file rotated"
    fi
}
```

## Testing Frameworks

### Test Helper Functions

**Standard test helpers:**
```bash
#!/bin/bash
# test_helpers.sh

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for test output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Assert functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$expected" = "$actual" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}✗${NC} $message"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist: $file}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ -f "$file" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}✗${NC} $message"
        return 1
    fi
}

assert_command_succeeds() {
    local message="$1"
    shift
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if "$@" >/dev/null 2>&1; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}✗${NC} $message"
        echo "  Command: $*"
        return 1
    fi
}

# Print test summary
print_test_summary() {
    echo ""
    echo "====================================="
    echo "Test Summary"
    echo "====================================="
    echo "Tests run:    $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed${NC}"
        return 1
    fi
}
```

### Functional Test Example

**Test script structure:**
```bash
#!/bin/bash
# functional-test.sh

# Source test helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Setup test environment
setup() {
    TEST_DIR="/tmp/test-$$"
    mkdir -p "$TEST_DIR"
}

# Teardown test environment
teardown() {
    rm -rf "$TEST_DIR"
}

# Test cases
test_configuration_loading() {
    local config_file="$TEST_DIR/test.conf"
    
    # Create test config
    cat > "$config_file" <<EOF
[Section]
KEY=value
EOF
    
    # Test loading
    assert_file_exists "$config_file" "Config file created"
    
    # Load config
    source load_config.sh
    load_config "$config_file"
    
    assert_equals "value" "$Section_KEY" "Config value loaded correctly"
}

test_json_parsing() {
    local json_file="$TEST_DIR/test.json"
    
    # Create test JSON
    echo '{"name": "test", "value": 123}' > "$json_file"
    
    # Parse JSON
    name=$(jq -r '.name' "$json_file")
    value=$(jq -r '.value' "$json_file")
    
    assert_equals "test" "$name" "JSON name parsed correctly"
    assert_equals "123" "$value" "JSON value parsed correctly"
}

# Main test runner
main() {
    setup
    
    echo "Running functional tests..."
    echo ""
    
    test_configuration_loading
    test_json_parsing
    
    teardown
    
    print_test_summary
}

main "$@"
```

### Integration Test with Docker

**Docker-based integration test:**
```bash
#!/bin/bash
# integration-test.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check Docker availability
if ! command -v docker >/dev/null 2>&1; then
    echo "Error: Docker not found"
    exit 1
fi

# Start test container
start_container() {
    echo "Starting MQTT broker container..."
    
    docker run -d \
        --name test-mqtt-broker \
        -p 1883:1883 \
        eclipse-mosquitto:latest
    
    # Wait for broker to be ready
    sleep 2
}

# Stop and remove container
stop_container() {
    echo "Stopping MQTT broker container..."
    docker stop test-mqtt-broker 2>/dev/null || true
    docker rm test-mqtt-broker 2>/dev/null || true
}

# Run integration tests
run_tests() {
    echo "Running integration tests..."
    
    # Test MQTT publish
    if mosquitto_pub -h localhost -p 1883 -t "test/topic" -m "test message"; then
        echo "✓ MQTT publish test passed"
    else
        echo "✗ MQTT publish test failed"
        return 1
    fi
    
    # Test MQTT subscribe (with timeout)
    if timeout 5s mosquitto_sub -h localhost -p 1883 -t "test/topic" -C 1 | grep -q "test message"; then
        echo "✓ MQTT subscribe test passed"
    else
        echo "✗ MQTT subscribe test failed"
        return 1
    fi
}

# Cleanup on exit
trap stop_container EXIT

# Main
start_container
run_tests
exit_code=$?

exit $exit_code
```

## Multi-Script Architectures

### Script Organization

**Directory structure for complex modules:**
```
module/
├── setup.sh              # Main installation script
├── bin/                  # Command-line tools
│   ├── module-cli        # Main CLI
│   ├── module-publish    # Publishing tool
│   └── module-status     # Status checker
├── lib/                  # Shared libraries
│   ├── common.sh         # Common functions
│   ├── config.sh         # Config parsing
│   └── helpers.sh        # Helper functions
├── tests/                # Test infrastructure
│   ├── syntax/           # Syntax validation
│   ├── functional/       # Functional tests
│   └── integration/      # Integration tests
└── config/               # Configuration templates
    └── module.conf.example
```

### Shared Function Library

**Common functions library:**
```bash
#!/bin/bash
# lib/common.sh - Shared functions

# Check if running as root
require_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Error: This command must be run as root"
        echo "Please run: sudo $0 $*"
        exit 1
    fi
}

# Check command availability
require_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: Required command not found: $cmd"
        return 1
    fi
}

# Safe file removal
safe_remove() {
    local path="$1"
    if [ -e "$path" ]; then
        rm -rf "$path" 2>/dev/null || {
            echo "Warning: Failed to remove: $path"
            return 1
        }
    fi
    return 0
}
```

## Performance Optimization

### Avoiding Subshells

**Inefficient:**
```bash
# Creates subshell for each iteration
for file in $(ls *.txt); do
    process "$file"
done
```

**Efficient:**
```bash
# No subshell created
for file in *.txt; do
    process "$file"
done
```

### Using Built-in Commands

**Prefer built-ins over external commands:**
```bash
# Slow - external command
length=$(echo "$string" | wc -c)

# Fast - built-in
length=${#string}

# Slow - external command
uppercase=$(echo "$string" | tr '[:lower:]' '[:upper:]')

# Fast - bash 4+ built-in
uppercase="${string^^}"
```

### Efficient File Reading

**Read files efficiently:**
```bash
# Inefficient - reads file multiple times
while read -r line; do
    process "$line"
done < <(cat file.txt | grep pattern)

# Efficient - single file read
while IFS= read -r line; do
    if [[ "$line" =~ pattern ]]; then
        process "$line"
    fi
done < file.txt
```

## References

- Advanced Bash-Scripting Guide: https://tldp.org/LDP/abs/html/
- Bash Reference Manual: https://www.gnu.org/software/bash/manual/
- Google Shell Style Guide: https://google.github.io/styleguide/shellguide.html
- jq Manual: https://stedolan.github.io/jq/manual/
- shellcheck Wiki: https://github.com/koalaman/shellcheck/wiki
