#!/bin/bash
# Real Integration Tests with Docker Mosquitto Broker
# Tests actual MQTT publishing and discovery with a real broker

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Get directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEST_DIR="/tmp/ha-mqtt-integration-test-$$"

# Broker configuration
BROKER_HOST="localhost"
BROKER_PORT="1883"
TEST_TOPIC_PREFIX="luigi-test-$$"

echo "========================================="
echo "iot/ha-mqtt Real Integration Tests"
echo "========================================="
echo ""
echo "Using real Mosquitto broker via Docker"
echo ""

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    local missing=0
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}✗${NC} docker not found"
        missing=1
    else
        echo -e "${GREEN}✓${NC} docker found"
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${RED}✗${NC} docker-compose not found"
        missing=1
    else
        echo -e "${GREEN}✓${NC} docker-compose found"
    fi
    
    if ! command -v mosquitto_pub &> /dev/null; then
        echo -e "${RED}✗${NC} mosquitto_pub not found (install mosquitto-clients)"
        missing=1
    else
        echo -e "${GREEN}✓${NC} mosquitto_pub found"
    fi
    
    if ! command -v mosquitto_sub &> /dev/null; then
        echo -e "${RED}✗${NC} mosquitto_sub not found (install mosquitto-clients)"
        missing=1
    else
        echo -e "${GREEN}✓${NC} mosquitto_sub found"
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}✗${NC} jq not found"
        missing=1
    else
        echo -e "${GREEN}✓${NC} jq found"
    fi
    
    if [[ $missing -eq 1 ]]; then
        echo ""
        echo "Missing prerequisites. Please install:"
        echo "  sudo apt-get install docker.io docker-compose mosquitto-clients jq"
        exit 1
    fi
    
    echo ""
}

# Start Docker broker
start_broker() {
    echo "Starting Mosquitto broker in Docker..."
    
    cd "${SCRIPT_DIR}"
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        echo -e "${RED}✗${NC} Docker daemon not running"
        echo "Please start Docker: sudo systemctl start docker"
        exit 1
    fi
    
    # Stop any existing test broker
    docker-compose down 2>/dev/null || true
    
    # Start broker
    if docker compose version &> /dev/null 2>&1; then
        docker compose up -d
    else
        docker-compose up -d
    fi
    
    # Wait for broker to be healthy
    echo "Waiting for broker to be ready..."
    local max_wait=30
    local waited=0
    
    while [[ $waited -lt $max_wait ]]; do
        # Check if container is running
        if docker ps | grep -q ha-mqtt-test-broker; then
            # Try to connect
            if timeout 2 bash -c "echo -n > /dev/tcp/localhost/1883" 2>/dev/null; then
                # Give it a moment to fully initialize
                sleep 2
                echo -e "${GREEN}✓${NC} Broker is ready"
                echo ""
                return 0
            fi
        fi
        sleep 1
        waited=$((waited + 1))
        echo -n "."
    done
    
    echo ""
    echo -e "${RED}✗${NC} Broker failed to start within ${max_wait} seconds"
    if docker compose version &> /dev/null 2>&1; then
        docker compose logs
    else
        docker-compose logs 2>/dev/null || docker logs ha-mqtt-test-broker
    fi
    exit 1
}

# Stop Docker broker
stop_broker() {
    echo ""
    echo "Stopping Mosquitto broker..."
    cd "${SCRIPT_DIR}"
    
    if docker compose version &> /dev/null 2>&1; then
        docker compose down
    else
        docker-compose down
    fi
    
    echo -e "${GREEN}✓${NC} Broker stopped"
}

# Setup test environment
setup_test_env() {
    echo "Setting up test environment..."
    
    mkdir -p "${TEST_DIR}/config"
    mkdir -p "${TEST_DIR}/sensors.d"
    
    # Create test configuration
    cat > "${TEST_DIR}/config/ha-mqtt.conf" <<EOF
[Broker]
HOST=${BROKER_HOST}
PORT=${BROKER_PORT}
TLS_ENABLED=false

[Authentication]
USERNAME=
PASSWORD=

[Client]
CLIENT_ID=test-client-$$
KEEPALIVE=60
QOS=1
CLEAN_SESSION=true

[Topics]
BASE_TOPIC=${TEST_TOPIC_PREFIX}
DISCOVERY_PREFIX=homeassistant
DEVICE_PREFIX=${TEST_TOPIC_PREFIX}

[Device]
DEVICE_NAME=TestDevice
DEVICE_MODEL=Test Model
MANUFACTURER=Test Manufacturer
SW_VERSION=1.0.0-test

[Connection]
CONNECTION_TIMEOUT=10

[Discovery]
SENSORS_DIR=${TEST_DIR}/sensors.d
SCAN_INTERVAL=300

[Logging]
LOG_LEVEL=INFO
EOF
    
    echo -e "${GREEN}✓${NC} Test environment created at ${TEST_DIR}"
    echo ""
}

# Cleanup test environment
cleanup_test_env() {
    if [[ -d "${TEST_DIR}" ]]; then
        rm -rf "${TEST_DIR}"
    fi
}

# Assert functions
assert_message_received() {
    local topic="$1"
    local expected_content="$2"
    local timeout="${3:-5}"
    local description="$4"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    echo -n "  Testing: ${description}... "
    
    # Subscribe and wait for message
    local message=$(mosquitto_sub -h "${BROKER_HOST}" -p "${BROKER_PORT}" \
        -t "${topic}" -C 1 -W "${timeout}" 2>/dev/null || echo "")
    
    if [[ -n "${message}" ]] && [[ "${message}" == *"${expected_content}"* ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}PASS${NC}"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}FAIL${NC}"
        echo "    Expected content: ${expected_content}"
        echo "    Received: ${message}"
        return 1
    fi
}

assert_json_field() {
    local topic="$1"
    local field="$2"
    local expected_value="$3"
    local timeout="${4:-5}"
    local description="$5"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    echo -n "  Testing: ${description}... "
    
    # Subscribe and get message
    local message=$(mosquitto_sub -h "${BROKER_HOST}" -p "${BROKER_PORT}" \
        -t "${topic}" -C 1 -W "${timeout}" 2>/dev/null || echo "")
    
    if [[ -z "${message}" ]]; then
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}FAIL${NC} (no message received)"
        return 1
    fi
    
    # Parse JSON field
    local actual_value=$(echo "${message}" | jq -r ".${field}" 2>/dev/null || echo "")
    
    if [[ "${actual_value}" == "${expected_value}" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}PASS${NC}"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}FAIL${NC}"
        echo "    Field: ${field}"
        echo "    Expected: ${expected_value}"
        echo "    Actual: ${actual_value}"
        return 1
    fi
}

# ============================================
# Test Suite 1: MQTT Connection Tests
# ============================================

test_mqtt_connection() {
    echo "========================================="
    echo "Test Suite 1: MQTT Connection"
    echo "========================================="
    echo ""
    
    # Test 1.1: Basic connectivity
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "  Test 1.1: Basic MQTT connectivity... "
    
    if mosquitto_pub -h "${BROKER_HOST}" -p "${BROKER_PORT}" \
        -t "test/connection" -m "test" &> /dev/null; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}PASS${NC}"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}FAIL${NC}"
    fi
    
    # Test 1.2: luigi-mqtt-status with real broker
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "  Test 1.2: luigi-mqtt-status with real broker... "
    
    export MQTT_CONFIG_FILE="${TEST_DIR}/config/ha-mqtt.conf"
    local status_output=$("${PROJECT_DIR}/bin/luigi-mqtt-status" 2>&1)
    unset MQTT_CONFIG_FILE
    
    if [[ "${status_output}" == *"✓"* ]] || [[ "${status_output}" == *"PASS"* ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}PASS${NC}"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}FAIL${NC}"
        echo "    Output: ${status_output}"
    fi
    
    echo ""
}

# ============================================
# Test Suite 2: Sensor Publishing Tests
# ============================================

test_sensor_publishing() {
    echo "========================================="
    echo "Test Suite 2: Sensor Publishing"
    echo "========================================="
    echo ""
    
    # Test 2.1: Publish numeric sensor value
    echo "Test 2.1: Publish numeric sensor value"
    
    # Start subscriber in background
    local test_topic="${TEST_TOPIC_PREFIX}/sensor/temperature/state"
    mosquitto_sub -h "${BROKER_HOST}" -p "${BROKER_PORT}" \
        -t "${test_topic}" -C 1 > "${TEST_DIR}/received.txt" &
    local sub_pid=$!
    
    sleep 1
    
    # Publish using luigi-publish
    export MQTT_CONFIG_FILE="${TEST_DIR}/config/ha-mqtt.conf"
    "${PROJECT_DIR}/bin/luigi-publish" \
        --sensor temperature \
        --value 23.5 &> /dev/null || true
    unset MQTT_CONFIG_FILE
    
    sleep 2
    
    # Check received message
    if [[ -f "${TEST_DIR}/received.txt" ]]; then
        local received=$(cat "${TEST_DIR}/received.txt")
        TESTS_RUN=$((TESTS_RUN + 1))
        
        if [[ "${received}" == "23.5" ]]; then
            TESTS_PASSED=$((TESTS_PASSED + 1))
            echo -e "  ${GREEN}PASS${NC} - Received correct value: ${received}"
        else
            TESTS_FAILED=$((TESTS_FAILED + 1))
            echo -e "  ${RED}FAIL${NC} - Expected: 23.5, Got: ${received}"
        fi
    else
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "  ${RED}FAIL${NC} - No message received"
    fi
    
    # Cleanup
    kill $sub_pid 2>/dev/null || true
    rm -f "${TEST_DIR}/received.txt"
    
    echo ""
    
    # Test 2.2: Publish binary sensor
    echo "Test 2.2: Publish binary sensor"
    
    local binary_topic="${TEST_TOPIC_PREFIX}/binary_sensor/motion/state"
    mosquitto_sub -h "${BROKER_HOST}" -p "${BROKER_PORT}" \
        -t "${binary_topic}" -C 1 > "${TEST_DIR}/received.txt" &
    sub_pid=$!
    
    sleep 1
    
    export MQTT_CONFIG_FILE="${TEST_DIR}/config/ha-mqtt.conf"
    "${PROJECT_DIR}/bin/luigi-publish" \
        --sensor motion \
        --value ON \
        --binary &> /dev/null || true
    unset MQTT_CONFIG_FILE
    
    sleep 2
    
    if [[ -f "${TEST_DIR}/received.txt" ]]; then
        received=$(cat "${TEST_DIR}/received.txt")
        TESTS_RUN=$((TESTS_RUN + 1))
        
        if [[ "${received}" == "ON" ]]; then
            TESTS_PASSED=$((TESTS_PASSED + 1))
            echo -e "  ${GREEN}PASS${NC} - Received correct binary value: ${received}"
        else
            TESTS_FAILED=$((TESTS_FAILED + 1))
            echo -e "  ${RED}FAIL${NC} - Expected: ON, Got: ${received}"
        fi
    else
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "  ${RED}FAIL${NC} - No message received"
    fi
    
    kill $sub_pid 2>/dev/null || true
    rm -f "${TEST_DIR}/received.txt"
    
    echo ""
}

# ============================================
# Test Suite 3: Discovery Protocol Tests
# ============================================

test_discovery_protocol() {
    echo "========================================="
    echo "Test Suite 3: MQTT Discovery Protocol"
    echo "========================================="
    echo ""
    
    # Create test sensor descriptor
    cat > "${TEST_DIR}/sensors.d/test_sensor.json" <<EOF
{
  "sensor_id": "test_temperature",
  "name": "Test Temperature Sensor",
  "device_class": "temperature",
  "unit_of_measurement": "°C",
  "icon": "mdi:thermometer",
  "state_class": "measurement",
  "module": "test/module"
}
EOF
    
    echo "Test 3.1: Discovery message publishing"
    
    # Subscribe to discovery topic
    local discovery_topic="homeassistant/sensor/${TEST_TOPIC_PREFIX}_test_temperature/config"
    mosquitto_sub -h "${BROKER_HOST}" -p "${BROKER_PORT}" \
        -t "${discovery_topic}" -C 1 > "${TEST_DIR}/discovery.txt" &
    local sub_pid=$!
    
    sleep 1
    
    # Run luigi-discover
    export MQTT_CONFIG_FILE="${TEST_DIR}/config/ha-mqtt.conf"
    "${PROJECT_DIR}/bin/luigi-discover" &> /dev/null || true
    unset MQTT_CONFIG_FILE
    
    sleep 2
    
    # Check discovery message
    if [[ -f "${TEST_DIR}/discovery.txt" ]]; then
        local discovery=$(cat "${TEST_DIR}/discovery.txt")
        TESTS_RUN=$((TESTS_RUN + 1))
        
        if [[ -n "${discovery}" ]] && echo "${discovery}" | jq . &> /dev/null; then
            TESTS_PASSED=$((TESTS_PASSED + 1))
            echo -e "  ${GREEN}PASS${NC} - Discovery message is valid JSON"
            
            # Verify required fields
            local name=$(echo "${discovery}" | jq -r '.name')
            local device_class=$(echo "${discovery}" | jq -r '.device_class')
            local state_topic=$(echo "${discovery}" | jq -r '.state_topic')
            
            echo "    Name: ${name}"
            echo "    Device class: ${device_class}"
            echo "    State topic: ${state_topic}"
            
            # Validate fields
            TESTS_RUN=$((TESTS_RUN + 1))
            if [[ "${name}" == "Test Temperature Sensor" ]]; then
                TESTS_PASSED=$((TESTS_PASSED + 1))
                echo -e "    ${GREEN}✓${NC} Correct name"
            else
                TESTS_FAILED=$((TESTS_FAILED + 1))
                echo -e "    ${RED}✗${NC} Incorrect name"
            fi
            
            TESTS_RUN=$((TESTS_RUN + 1))
            if [[ "${device_class}" == "temperature" ]]; then
                TESTS_PASSED=$((TESTS_PASSED + 1))
                echo -e "    ${GREEN}✓${NC} Correct device class"
            else
                TESTS_FAILED=$((TESTS_FAILED + 1))
                echo -e "    ${RED}✗${NC} Incorrect device class"
            fi
            
            TESTS_RUN=$((TESTS_RUN + 1))
            if [[ "${state_topic}" == *"test_temperature"* ]]; then
                TESTS_PASSED=$((TESTS_PASSED + 1))
                echo -e "    ${GREEN}✓${NC} Valid state topic"
            else
                TESTS_FAILED=$((TESTS_FAILED + 1))
                echo -e "    ${RED}✗${NC} Invalid state topic"
            fi
        else
            TESTS_FAILED=$((TESTS_FAILED + 1))
            echo -e "  ${RED}FAIL${NC} - Discovery message not valid JSON"
            echo "    Received: ${discovery}"
        fi
    else
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "  ${RED}FAIL${NC} - No discovery message received"
    fi
    
    kill $sub_pid 2>/dev/null || true
    
    echo ""
}

# ============================================
# Test Suite 4: End-to-End Workflow
# ============================================

test_end_to_end() {
    echo "========================================="
    echo "Test Suite 4: End-to-End Workflow"
    echo "========================================="
    echo ""
    
    echo "Test 4.1: Complete sensor integration workflow"
    
    # Step 1: Create descriptor
    cat > "${TEST_DIR}/sensors.d/e2e_sensor.json" <<EOF
{
  "sensor_id": "e2e_test",
  "name": "End to End Test Sensor",
  "device_class": "humidity",
  "unit_of_measurement": "%",
  "state_class": "measurement",
  "module": "test/e2e"
}
EOF
    
    echo "  Step 1: Created descriptor"
    
    # Step 2: Run discovery
    export MQTT_CONFIG_FILE="${TEST_DIR}/config/ha-mqtt.conf"
    "${PROJECT_DIR}/bin/luigi-discover" &> /dev/null || true
    unset MQTT_CONFIG_FILE
    
    echo "  Step 2: Ran discovery"
    sleep 1
    
    # Step 3: Subscribe to state topic
    local state_topic="${TEST_TOPIC_PREFIX}/sensor/e2e_test/state"
    mosquitto_sub -h "${BROKER_HOST}" -p "${BROKER_PORT}" \
        -t "${state_topic}" -C 1 > "${TEST_DIR}/e2e.txt" &
    local sub_pid=$!
    
    sleep 1
    
    # Step 4: Publish value
    export MQTT_CONFIG_FILE="${TEST_DIR}/config/ha-mqtt.conf"
    "${PROJECT_DIR}/bin/luigi-publish" \
        --sensor e2e_test \
        --value 65.5 &> /dev/null || true
    unset MQTT_CONFIG_FILE
    
    echo "  Step 3: Published value"
    sleep 2
    
    # Step 5: Verify
    if [[ -f "${TEST_DIR}/e2e.txt" ]]; then
        local received=$(cat "${TEST_DIR}/e2e.txt")
        TESTS_RUN=$((TESTS_RUN + 1))
        
        if [[ "${received}" == "65.5" ]]; then
            TESTS_PASSED=$((TESTS_PASSED + 1))
            echo -e "  ${GREEN}PASS${NC} - End-to-end workflow successful"
            echo "    Descriptor → Discovery → Publish → Receive: ALL OK"
        else
            TESTS_FAILED=$((TESTS_FAILED + 1))
            echo -e "  ${RED}FAIL${NC} - Expected: 65.5, Got: ${received}"
        fi
    else
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "  ${RED}FAIL${NC} - No message received in e2e test"
    fi
    
    kill $sub_pid 2>/dev/null || true
    
    echo ""
}

# ============================================
# Main Test Execution
# ============================================

main() {
    # Check prerequisites
    check_prerequisites
    
    # Start broker
    start_broker
    
    # Setup test environment
    setup_test_env
    
    # Run test suites
    test_mqtt_connection
    test_sensor_publishing
    test_discovery_protocol
    test_end_to_end
    
    # Summary
    echo "========================================="
    echo "Test Summary"
    echo "========================================="
    echo "Total tests:  ${TESTS_RUN}"
    echo -e "Passed:       ${GREEN}${TESTS_PASSED}${NC}"
    echo -e "Failed:       ${RED}${TESTS_FAILED}${NC}"
    echo ""
    
    # Cleanup
    cleanup_test_env
    stop_broker
    
    # Exit code
    if [[ ${TESTS_FAILED} -eq 0 ]]; then
        echo -e "${GREEN}✓ All integration tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Some integration tests failed${NC}"
        return 1
    fi
}

# Trap to ensure cleanup
trap 'stop_broker; cleanup_test_env' EXIT INT TERM

# Run main
main
exit $?
