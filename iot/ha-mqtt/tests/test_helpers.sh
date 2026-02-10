#!/bin/bash
# Test Helper Functions
# Provides common utilities for functional testing

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    GREEN=''
    RED=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Test environment setup
TEST_DIR="${TEST_DIR:-/tmp/ha-mqtt-test-$$}"
TEST_CONFIG_DIR="${TEST_DIR}/config"
TEST_SENSORS_DIR="${TEST_DIR}/sensors.d"
TEST_LIB_DIR="${TEST_DIR}/lib"
TEST_BIN_DIR="${TEST_DIR}/bin"

# Initialize test environment
init_test_env() {
    mkdir -p "${TEST_DIR}"
    mkdir -p "${TEST_CONFIG_DIR}"
    mkdir -p "${TEST_SENSORS_DIR}"
    mkdir -p "${TEST_LIB_DIR}"
    mkdir -p "${TEST_BIN_DIR}"
    
    # Copy libraries to test environment
    if [[ -f "${SCRIPT_DIR}/../lib/mqtt_helpers.sh" ]]; then
        cp "${SCRIPT_DIR}/../lib/mqtt_helpers.sh" "${TEST_LIB_DIR}/"
    fi
    if [[ -f "${SCRIPT_DIR}/../lib/ha_discovery_generator.sh" ]]; then
        cp "${SCRIPT_DIR}/../lib/ha_discovery_generator.sh" "${TEST_LIB_DIR}/"
    fi
}

# Clean up test environment
cleanup_test_env() {
    if [[ -d "${TEST_DIR}" ]]; then
        rm -rf "${TEST_DIR}"
    fi
}

# Create test configuration file
create_test_config() {
    local config_file="${TEST_CONFIG_DIR}/ha-mqtt.conf"
    cat > "${config_file}" <<'EOF'
[Broker]
HOST=test-broker.local
PORT=1883
TLS_ENABLED=false

[Authentication]
USERNAME=testuser
PASSWORD=testpass

[Client]
CLIENT_ID=test-client
KEEPALIVE=60
QOS=1

[Topics]
BASE_TOPIC=luigi
DISCOVERY_PREFIX=homeassistant
DEVICE_PREFIX=luigi

[Device]
DEVICE_NAME=TestPi
DEVICE_MODEL=Raspberry Pi Zero W
MANUFACTURER=Raspberry Pi Foundation
SW_VERSION=1.0.0

[Connection]
CONNECTION_TIMEOUT=10

[Discovery]
SENSORS_DIR=${TEST_SENSORS_DIR}
SCAN_INTERVAL=300

[Logging]
LOG_LEVEL=INFO
EOF
    echo "${config_file}"
}

# Create test sensor descriptor
create_test_descriptor() {
    local sensor_id="$1"
    local sensor_type="${2:-sensor}"
    local descriptor_file="${TEST_SENSORS_DIR}/${sensor_id}.json"
    
    if [[ "${sensor_type}" == "binary_sensor" ]]; then
        cat > "${descriptor_file}" <<EOF
{
  "sensor_id": "${sensor_id}",
  "name": "Test ${sensor_id}",
  "device_class": "motion",
  "module": "test/module"
}
EOF
    else
        cat > "${descriptor_file}" <<EOF
{
  "sensor_id": "${sensor_id}",
  "name": "Test ${sensor_id}",
  "device_class": "temperature",
  "unit_of_measurement": "°C",
  "icon": "mdi:thermometer",
  "state_class": "measurement",
  "module": "test/module"
}
EOF
    fi
    echo "${descriptor_file}"
}

# Create mock mosquitto_pub command
create_mock_mosquitto_pub() {
    local mock_script="${TEST_BIN_DIR}/mosquitto_pub"
    cat > "${mock_script}" <<'EOF'
#!/bin/bash
# Mock mosquitto_pub for testing
# Logs all calls to a file instead of actually publishing

MOCK_LOG="${MOCK_LOG:-/tmp/mosquitto_pub_mock.log}"
echo "$(date '+%Y-%m-%d %H:%M:%S') mosquitto_pub $*" >> "${MOCK_LOG}"

# Parse arguments to extract topic and message
TOPIC=""
MESSAGE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -t) TOPIC="$2"; shift 2 ;;
        -m) MESSAGE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# Write to separate file for easy parsing
if [[ -n "${TOPIC}" ]]; then
    echo "${TOPIC}|${MESSAGE}" >> "${MOCK_LOG}.data"
fi

# Always succeed for testing
exit 0
EOF
    chmod +x "${mock_script}"
    export PATH="${TEST_BIN_DIR}:${PATH}"
    export MOCK_LOG="${TEST_DIR}/mosquitto_pub_mock.log"
    echo "${mock_script}"
}

# Assert functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [[ "${expected}" == "${actual}" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} ${message:-Assertion passed}"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}✗${NC} ${message:-Assertion failed}"
        echo "  Expected: ${expected}"
        echo "  Actual:   ${actual}"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [[ "${haystack}" == *"${needle}"* ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} ${message:-Contains assertion passed}"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}✗${NC} ${message:-Contains assertion failed}"
        echo "  Haystack: ${haystack}"
        echo "  Needle:   ${needle}"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [[ -f "${file}" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} ${message:-File exists}"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}✗${NC} ${message:-File does not exist}"
        echo "  File: ${file}"
        return 1
    fi
}

assert_exit_code() {
    local expected_code="$1"
    local actual_code="$2"
    local message="${3:-}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [[ "${expected_code}" -eq "${actual_code}" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} ${message:-Exit code correct}"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}✗${NC} ${message:-Exit code incorrect}"
        echo "  Expected: ${expected_code}"
        echo "  Actual:   ${actual_code}"
        return 1
    fi
}

# Print test summary
print_test_summary() {
    echo ""
    echo "========================================="
    echo "Test Summary"
    echo "========================================="
    echo "Total tests:  ${TESTS_RUN}"
    echo -e "Passed:       ${GREEN}${TESTS_PASSED}${NC}"
    echo -e "Failed:       ${RED}${TESTS_FAILED}${NC}"
    echo ""
    
    if [[ ${TESTS_FAILED} -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        return 1
    fi
}
