#!/bin/bash
#
# MQTT Helper Library for iot/ha-mqtt Module
#
# Purpose: Provide reusable MQTT operations for Luigi modules
# Why: Centralizes MQTT logic, reduces code duplication, enforces standards
# How: Source this file in scripts: source /usr/local/lib/luigi/mqtt_helpers.sh
# Who: Used by luigi-publish, luigi-discover, luigi-mqtt-status
#
# Key Responsibilities:
# 1. Load and validate ha-mqtt.conf configuration
# 2. Validate sensor IDs for security (prevent path traversal)
# 3. Build MQTT topic strings following Luigi conventions
# 4. Wrap mosquitto_pub with authentication and error handling
#
# Part of Phase 2: Core Implementation

# Default configuration values
DEFAULT_HOST="homeassistant.local"
DEFAULT_PORT="1883"
DEFAULT_TLS="no"
DEFAULT_USERNAME="luigi"
DEFAULT_CLIENT_ID="luigi_\$(hostname)"
DEFAULT_KEEPALIVE="60"
DEFAULT_QOS="1"
DEFAULT_CLEAN_SESSION="yes"
DEFAULT_BASE_TOPIC="homeassistant"
DEFAULT_DISCOVERY_PREFIX="homeassistant"
DEFAULT_DEVICE_PREFIX="luigi"
DEFAULT_DEVICE_NAME="Luigi \$(hostname)"
DEFAULT_DEVICE_MODEL="Raspberry Pi Zero W"
DEFAULT_MANUFACTURER="Luigi Project"
DEFAULT_SW_VERSION="1.0"
DEFAULT_SENSORS_DIR="/etc/luigi/iot/ha-mqtt/sensors.d"
DEFAULT_SCAN_INTERVAL="300"
DEFAULT_RECONNECT_DELAY_MIN="5"
DEFAULT_RECONNECT_DELAY_MAX="300"
DEFAULT_CONNECTION_TIMEOUT="10"
DEFAULT_LOG_FILE="/var/log/ha-mqtt.log"
DEFAULT_LOG_LEVEL="INFO"

# Configuration file location
CONFIG_FILE="/etc/luigi/iot/ha-mqtt/ha-mqtt.conf"

#
# Function: load_config
#
# Purpose: Load and parse ha-mqtt.conf INI file, export as environment variables
# Parameters: None
# Returns: 0 on success, 1 on critical error
# Exports: MQTT_* variables for broker connection
#
load_config() {
    # Apply defaults first
    MQTT_HOST="${DEFAULT_HOST}"
    MQTT_PORT="${DEFAULT_PORT}"
    MQTT_TLS="${DEFAULT_TLS}"
    MQTT_USERNAME="${DEFAULT_USERNAME}"
    MQTT_PASSWORD=""
    MQTT_CLIENT_ID="${DEFAULT_CLIENT_ID}"
    MQTT_KEEPALIVE="${DEFAULT_KEEPALIVE}"
    MQTT_QOS="${DEFAULT_QOS}"
    MQTT_CLEAN_SESSION="${DEFAULT_CLEAN_SESSION}"
    MQTT_BASE_TOPIC="${DEFAULT_BASE_TOPIC}"
    MQTT_DISCOVERY_PREFIX="${DEFAULT_DISCOVERY_PREFIX}"
    MQTT_DEVICE_PREFIX="${DEFAULT_DEVICE_PREFIX}"
    MQTT_DEVICE_NAME="${DEFAULT_DEVICE_NAME}"
    MQTT_DEVICE_MODEL="${DEFAULT_DEVICE_MODEL}"
    MQTT_MANUFACTURER="${DEFAULT_MANUFACTURER}"
    MQTT_SW_VERSION="${DEFAULT_SW_VERSION}"
    MQTT_SENSORS_DIR="${DEFAULT_SENSORS_DIR}"
    MQTT_SCAN_INTERVAL="${DEFAULT_SCAN_INTERVAL}"
    MQTT_RECONNECT_DELAY_MIN="${DEFAULT_RECONNECT_DELAY_MIN}"
    MQTT_RECONNECT_DELAY_MAX="${DEFAULT_RECONNECT_DELAY_MAX}"
    MQTT_CONNECTION_TIMEOUT="${DEFAULT_CONNECTION_TIMEOUT}"
    MQTT_LOG_FILE="${DEFAULT_LOG_FILE}"
    MQTT_LOG_LEVEL="${DEFAULT_LOG_LEVEL}"
    
    # Check if config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        # Config file missing - use defaults
        return 0
    fi
    
    # Check config file permissions (should be 600 for security)
    local perms
    perms=$(stat -c "%a" "$CONFIG_FILE" 2>/dev/null)
    if [ "$perms" != "600" ] && [ "$perms" != "400" ]; then
        >&2 echo "Warning: Config file $CONFIG_FILE has insecure permissions ($perms)"
        >&2 echo "         Should be 600 (owner read/write only)"
        >&2 echo "         Run: sudo chmod 600 $CONFIG_FILE"
    fi
    
    # Parse INI file
    local section=""
    while IFS= read -r line || [ -n "$line" ]; do
        # Remove leading/trailing whitespace
        line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        
        # Check for section headers
        if [[ "$line" =~ ^\[(.+)\]$ ]]; then
            section="${BASH_REMATCH[1]}"
            continue
        fi
        
        # Parse key=value pairs
        if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            
            # Remove quotes from value if present
            value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
            
            # Expand ${HOSTNAME} variable
            local hostname_val
            hostname_val=$(hostname)
            value="${value//\$\{HOSTNAME\}/$hostname_val}"
            
            # Map to MQTT_* variables based on section and key
            case "$section" in
                "Broker")
                    case "$key" in
                        "HOST") MQTT_HOST="$value" ;;
                        "PORT") MQTT_PORT="$value" ;;
                        "TLS") MQTT_TLS="$value" ;;
                        "CA_CERT") MQTT_CA_CERT="$value" ;;
                    esac
                    ;;
                "Authentication")
                    case "$key" in
                        "USERNAME") MQTT_USERNAME="$value" ;;
                        "PASSWORD") MQTT_PASSWORD="$value" ;;
                    esac
                    ;;
                "Client")
                    case "$key" in
                        "CLIENT_ID") MQTT_CLIENT_ID="$value" ;;
                        "KEEPALIVE") MQTT_KEEPALIVE="$value" ;;
                        "QOS") MQTT_QOS="$value" ;;
                        "CLEAN_SESSION") MQTT_CLEAN_SESSION="$value" ;;
                    esac
                    ;;
                "Topics")
                    case "$key" in
                        "BASE_TOPIC") MQTT_BASE_TOPIC="$value" ;;
                        "DISCOVERY_PREFIX") MQTT_DISCOVERY_PREFIX="$value" ;;
                        "DEVICE_PREFIX") MQTT_DEVICE_PREFIX="$value" ;;
                    esac
                    ;;
                "Device")
                    case "$key" in
                        "DEVICE_NAME") MQTT_DEVICE_NAME="$value" ;;
                        "DEVICE_MODEL") MQTT_DEVICE_MODEL="$value" ;;
                        "MANUFACTURER") MQTT_MANUFACTURER="$value" ;;
                        "SW_VERSION") MQTT_SW_VERSION="$value" ;;
                    esac
                    ;;
                "Connection")
                    case "$key" in
                        "RECONNECT_DELAY_MIN") MQTT_RECONNECT_DELAY_MIN="$value" ;;
                        "RECONNECT_DELAY_MAX") MQTT_RECONNECT_DELAY_MAX="$value" ;;
                        "CONNECTION_TIMEOUT") MQTT_CONNECTION_TIMEOUT="$value" ;;
                    esac
                    ;;
                "Discovery")
                    case "$key" in
                        "SENSORS_DIR") MQTT_SENSORS_DIR="$value" ;;
                        "SCAN_INTERVAL") MQTT_SCAN_INTERVAL="$value" ;;
                    esac
                    ;;
                "Logging")
                    case "$key" in
                        "LOG_FILE") MQTT_LOG_FILE="$value" ;;
                        "LOG_LEVEL") MQTT_LOG_LEVEL="$value" ;;
                    esac
                    ;;
            esac
        fi
    done < "$CONFIG_FILE"
    
    # Validate required parameters
    if [ -z "$MQTT_HOST" ]; then
        >&2 echo "Error: MQTT_HOST not configured"
        return 1
    fi
    
    # Export variables for child processes
    export MQTT_HOST MQTT_PORT MQTT_TLS MQTT_CA_CERT
    export MQTT_USERNAME MQTT_PASSWORD
    export MQTT_CLIENT_ID MQTT_KEEPALIVE MQTT_QOS MQTT_CLEAN_SESSION
    export MQTT_BASE_TOPIC MQTT_DISCOVERY_PREFIX MQTT_DEVICE_PREFIX
    export MQTT_DEVICE_NAME MQTT_DEVICE_MODEL MQTT_MANUFACTURER MQTT_SW_VERSION
    export MQTT_SENSORS_DIR MQTT_SCAN_INTERVAL
    export MQTT_RECONNECT_DELAY_MIN MQTT_RECONNECT_DELAY_MAX MQTT_CONNECTION_TIMEOUT
    export MQTT_LOG_FILE MQTT_LOG_LEVEL
    
    return 0
}

#
# Function: validate_sensor_id
#
# Purpose: Validate sensor ID format for security and correctness
# Parameters: $1 = sensor_id to validate
# Returns: 0 if valid, 1 if invalid
#
# Security: Prevents path traversal attacks and ensures MQTT topic compatibility
#
validate_sensor_id() {
    local sensor_id="$1"
    
    # Check if empty
    if [ -z "$sensor_id" ]; then
        >&2 echo "Error: Sensor ID cannot be empty"
        return 1
    fi
    
    # Check length (reasonable limit)
    if [ ${#sensor_id} -gt 64 ]; then
        >&2 echo "Error: Sensor ID too long (max 64 characters)"
        return 1
    fi
    
    # Check for path traversal attempts
    if [[ "$sensor_id" == *".."* ]] || [[ "$sensor_id" == *"/"* ]] || [[ "$sensor_id" == *"\\"* ]]; then
        >&2 echo "Error: Sensor ID contains invalid characters (path traversal attempt?)"
        return 1
    fi
    
    # Check format: alphanumeric, underscore, hyphen only
    if ! [[ "$sensor_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        >&2 echo "Error: Sensor ID must contain only alphanumeric characters, underscore, and hyphen"
        return 1
    fi
    
    return 0
}

#
# Function: build_topic
#
# Purpose: Construct MQTT topic following Luigi conventions
# Parameters: $1 = sensor_type (sensor, binary_sensor, etc.)
#             $2 = sensor_id
#             $3 = topic_suffix (state, config, attributes)
# Returns: 0 on success, prints topic to stdout
#
# Topic Pattern: {BASE_TOPIC}/{sensor_type}/{DEVICE_PREFIX}-{HOSTNAME}/{sensor_id}/{suffix}
# Example: homeassistant/sensor/luigi-raspberrypi/temperature/state
#
build_topic() {
    local sensor_type="$1"
    local sensor_id="$2"
    local topic_suffix="$3"
    
    # Validate inputs
    if [ -z "$sensor_type" ] || [ -z "$sensor_id" ] || [ -z "$topic_suffix" ]; then
        >&2 echo "Error: build_topic requires 3 arguments"
        return 1
    fi
    
    # Validate sensor_id
    if ! validate_sensor_id "$sensor_id"; then
        return 1
    fi
    
    # Construct device ID
    local device_id
    device_id="${MQTT_DEVICE_PREFIX}-$(hostname)"
    
    # Build topic
    local topic="${MQTT_BASE_TOPIC}/${sensor_type}/${device_id}/${sensor_id}/${topic_suffix}"
    
    # Output topic
    echo "$topic"
    return 0
}

#
# Function: mqtt_publish
#
# Purpose: Publish message to MQTT broker with authentication and error handling
# Parameters: $1 = topic
#             $2 = message
#             $3 = retain flag (optional: "retain" or empty)
# Returns: 0 on success, 1 on failure
#
# Wraps mosquitto_pub with proper authentication, QoS, and timeout handling
#
mqtt_publish() {
    local topic="$1"
    local message="$2"
    local retain_flag="$3"
    
    # Validate inputs
    if [ -z "$topic" ]; then
        >&2 echo "Error: mqtt_publish requires topic argument"
        return 1
    fi
    
    # Check if mosquitto_pub is available
    if ! command -v mosquitto_pub >/dev/null 2>&1; then
        >&2 echo "Error: mosquitto_pub not found. Install mosquitto-clients package."
        return 1
    fi
    
    # Build mosquitto_pub command
    local cmd=(
        mosquitto_pub
        -h "$MQTT_HOST"
        -p "$MQTT_PORT"
        -t "$topic"
        -m "$message"
        -q "$MQTT_QOS"
        -i "$MQTT_CLIENT_ID"
    )
    
    # Add authentication if username is set
    if [ -n "$MQTT_USERNAME" ]; then
        cmd+=(-u "$MQTT_USERNAME")
        if [ -n "$MQTT_PASSWORD" ]; then
            cmd+=(-P "$MQTT_PASSWORD")
        fi
    fi
    
    # Add retain flag if requested
    if [ "$retain_flag" = "retain" ]; then
        cmd+=(-r)
    fi
    
    # Add TLS if enabled
    if [ "$MQTT_TLS" = "yes" ] && [ -n "$MQTT_CA_CERT" ]; then
        cmd+=(--cafile "$MQTT_CA_CERT")
    fi
    
    # Execute publish with timeout
    if timeout "$MQTT_CONNECTION_TIMEOUT" "${cmd[@]}" 2>&1; then
        return 0
    else
        local exit_code=$?
        >&2 echo "Error: Failed to publish to $topic (exit code: $exit_code)"
        return 1
    fi
}

# Library loaded successfully
# Note: return 0 allows sourcing this file; true is no-op fallback
return 0 2>/dev/null || true
