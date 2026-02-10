#!/bin/bash
#
# Home Assistant Discovery Generator Library for iot/ha-mqtt Module
#
# Purpose: Generate MQTT Discovery payloads for Home Assistant
# Why: Automates sensor registration in Home Assistant via MQTT Discovery
# How: Source this file: source /usr/local/lib/luigi/ha_discovery_generator.sh
# Who: Used by luigi-discover script
#
# Key Responsibilities:
# 1. Validate sensor descriptor JSON files
# 2. Generate sensor discovery payloads for Home Assistant
# 3. Generate binary_sensor discovery payloads
# 4. Build discovery topics following HA MQTT Discovery protocol
#
# Part of Phase 2: Core Implementation

# Ensure jq is available for JSON operations
if ! command -v jq >/dev/null 2>&1; then
    >&2 echo "Error: jq not found. Install jq package for JSON processing."
    return 1 2>/dev/null || exit 1
fi

#
# Function: validate_descriptor
#
# Purpose: Validate sensor descriptor JSON file format and required fields
# Parameters: $1 = path to descriptor JSON file
# Returns: 0 if valid, 1 if invalid
#
# Checks:
# - Valid JSON syntax
# - Required fields present (sensor_id, name, module)
# - sensor_id format is valid
#
validate_descriptor() {
    local descriptor_file="$1"
    
    # Check file exists
    if [ ! -f "$descriptor_file" ]; then
        >&2 echo "Error: Descriptor file not found: $descriptor_file"
        return 1
    fi
    
    # Validate JSON syntax
    if ! jq empty "$descriptor_file" 2>/dev/null; then
        >&2 echo "Error: Invalid JSON in descriptor: $descriptor_file"
        return 1
    fi
    
    # Check required fields
    local sensor_id
    local name
    local module
    
    sensor_id=$(jq -r '.sensor_id // empty' "$descriptor_file")
    name=$(jq -r '.name // empty' "$descriptor_file")
    module=$(jq -r '.module // empty' "$descriptor_file")
    
    if [ -z "$sensor_id" ]; then
        >&2 echo "Error: Missing required field 'sensor_id' in $descriptor_file"
        return 1
    fi
    
    if [ -z "$name" ]; then
        >&2 echo "Error: Missing required field 'name' in $descriptor_file"
        return 1
    fi
    
    if [ -z "$module" ]; then
        >&2 echo "Error: Missing required field 'module' in $descriptor_file"
        return 1
    fi
    
    # Validate sensor_id format (alphanumeric, underscore, hyphen only)
    if ! [[ "$sensor_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        >&2 echo "Error: Invalid sensor_id format in $descriptor_file"
        >&2 echo "       Must contain only alphanumeric characters, underscore, and hyphen"
        return 1
    fi
    
    return 0
}

#
# Function: generate_sensor_discovery
#
# Purpose: Generate Home Assistant sensor discovery payload
# Parameters: $1 = path to descriptor JSON file
# Returns: 0 on success, prints discovery JSON to stdout
#
# Generates complete MQTT Discovery payload following HA specification
# Includes device information, sensor metadata, and topic structure
#
generate_sensor_discovery() {
    local descriptor_file="$1"
    
    # Validate descriptor first
    if ! validate_descriptor "$descriptor_file"; then
        return 1
    fi
    
    # Load mqtt_helpers if not already loaded (for topic construction)
    if ! declare -f build_topic >/dev/null 2>&1; then
        local lib_dir
        lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        # shellcheck source=/dev/null
        source "$lib_dir/mqtt_helpers.sh" || return 1
        load_config || return 1
    fi
    
    # Extract descriptor fields
    local sensor_id
    local name
    local device_class
    local unit_of_measurement
    local icon
    local state_class
    local module
    
    sensor_id=$(jq -r '.sensor_id' "$descriptor_file")
    name=$(jq -r '.name' "$descriptor_file")
    device_class=$(jq -r '.device_class // empty' "$descriptor_file")
    unit_of_measurement=$(jq -r '.unit_of_measurement // empty' "$descriptor_file")
    icon=$(jq -r '.icon // empty' "$descriptor_file")
    state_class=$(jq -r '.state_class // empty' "$descriptor_file")
    module=$(jq -r '.module' "$descriptor_file")
    
    # Build topic for state updates
    local state_topic
    state_topic=$(build_topic "sensor" "$sensor_id" "state")
    
    # Build unique_id for Home Assistant
    local unique_id
    unique_id="${MQTT_DEVICE_PREFIX}_$(hostname)_${sensor_id}"
    
    # Build device identifier
    local device_id
    device_id="${MQTT_DEVICE_PREFIX}-$(hostname)"
    
    # Start building discovery JSON
    local discovery_json
    discovery_json=$(jq -n \
        --arg name "$name" \
        --arg unique_id "$unique_id" \
        --arg state_topic "$state_topic" \
        '{
            name: $name,
            unique_id: $unique_id,
            state_topic: $state_topic
        }')
    
    # Add optional fields if present
    if [ -n "$device_class" ]; then
        discovery_json=$(echo "$discovery_json" | jq --arg dc "$device_class" '. + {device_class: $dc}')
    fi
    
    if [ -n "$unit_of_measurement" ]; then
        discovery_json=$(echo "$discovery_json" | jq --arg unit "$unit_of_measurement" '. + {unit_of_measurement: $unit}')
    fi
    
    if [ -n "$icon" ]; then
        discovery_json=$(echo "$discovery_json" | jq --arg icon "$icon" '. + {icon: $icon}')
    fi
    
    if [ -n "$state_class" ]; then
        discovery_json=$(echo "$discovery_json" | jq --arg sc "$state_class" '. + {state_class: $sc}')
    fi
    
    # Add device information
    discovery_json=$(echo "$discovery_json" | jq \
        --arg dev_id "$device_id" \
        --arg dev_name "$MQTT_DEVICE_NAME" \
        --arg dev_model "$MQTT_DEVICE_MODEL" \
        --arg manufacturer "$MQTT_MANUFACTURER" \
        --arg sw_version "$MQTT_SW_VERSION" \
        --arg module "$module" \
        '. + {
            device: {
                identifiers: [$dev_id],
                name: $dev_name,
                model: $dev_model,
                manufacturer: $manufacturer,
                sw_version: $sw_version,
                suggested_area: "Luigi"
            },
            origin: {
                name: "Luigi MQTT Bridge",
                sw_version: $sw_version,
                support_url: "https://github.com/pkathmann88/luigi"
            }
        }')
    
    # Output discovery JSON
    echo "$discovery_json"
    return 0
}

#
# Function: generate_binary_sensor_discovery
#
# Purpose: Generate Home Assistant binary_sensor discovery payload
# Parameters: $1 = path to descriptor JSON file
# Returns: 0 on success, prints discovery JSON to stdout
#
# Generates MQTT Discovery payload for binary sensors (motion, door, etc.)
# Binary sensors have ON/OFF states rather than numeric values
#
generate_binary_sensor_discovery() {
    local descriptor_file="$1"
    
    # Validate descriptor first
    if ! validate_descriptor "$descriptor_file"; then
        return 1
    fi
    
    # Load mqtt_helpers if not already loaded
    if ! declare -f build_topic >/dev/null 2>&1; then
        local lib_dir
        lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        # shellcheck source=/dev/null
        source "$lib_dir/mqtt_helpers.sh" || return 1
        load_config || return 1
    fi
    
    # Extract descriptor fields
    local sensor_id
    local name
    local device_class
    local icon
    local module
    
    sensor_id=$(jq -r '.sensor_id' "$descriptor_file")
    name=$(jq -r '.name' "$descriptor_file")
    device_class=$(jq -r '.device_class // empty' "$descriptor_file")
    icon=$(jq -r '.icon // empty' "$descriptor_file")
    module=$(jq -r '.module' "$descriptor_file")
    
    # Build topic for state updates (binary_sensor instead of sensor)
    local state_topic
    state_topic=$(build_topic "binary_sensor" "$sensor_id" "state")
    
    # Build unique_id
    local unique_id
    unique_id="${MQTT_DEVICE_PREFIX}_$(hostname)_${sensor_id}"
    
    # Build device identifier
    local device_id
    device_id="${MQTT_DEVICE_PREFIX}-$(hostname)"
    
    # Build discovery JSON
    local discovery_json
    discovery_json=$(jq -n \
        --arg name "$name" \
        --arg unique_id "$unique_id" \
        --arg state_topic "$state_topic" \
        '{
            name: $name,
            unique_id: $unique_id,
            state_topic: $state_topic,
            payload_on: "ON",
            payload_off: "OFF"
        }')
    
    # Add optional fields
    if [ -n "$device_class" ]; then
        discovery_json=$(echo "$discovery_json" | jq --arg dc "$device_class" '. + {device_class: $dc}')
    fi
    
    if [ -n "$icon" ]; then
        discovery_json=$(echo "$discovery_json" | jq --arg icon "$icon" '. + {icon: $icon}')
    fi
    
    # Add device information
    discovery_json=$(echo "$discovery_json" | jq \
        --arg dev_id "$device_id" \
        --arg dev_name "$MQTT_DEVICE_NAME" \
        --arg dev_model "$MQTT_DEVICE_MODEL" \
        --arg manufacturer "$MQTT_MANUFACTURER" \
        --arg sw_version "$MQTT_SW_VERSION" \
        --arg module "$module" \
        '. + {
            device: {
                identifiers: [$dev_id],
                name: $dev_name,
                model: $dev_model,
                manufacturer: $manufacturer,
                sw_version: $sw_version,
                suggested_area: "Luigi"
            },
            origin: {
                name: "Luigi MQTT Bridge",
                sw_version: $sw_version,
                support_url: "https://github.com/pkathmann88/luigi"
            }
        }')
    
    # Output discovery JSON
    echo "$discovery_json"
    return 0
}

#
# Function: get_discovery_topic
#
# Purpose: Build MQTT Discovery config topic for a sensor
# Parameters: $1 = sensor_type (sensor or binary_sensor)
#             $2 = sensor_id
# Returns: 0 on success, prints discovery topic to stdout
#
# Topic Pattern: {DISCOVERY_PREFIX}/{sensor_type}/{device_id}/{sensor_id}/config
# Example: homeassistant/sensor/luigi-raspberrypi/temperature/config
#
get_discovery_topic() {
    local sensor_type="$1"
    local sensor_id="$2"
    
    if [ -z "$sensor_type" ] || [ -z "$sensor_id" ]; then
        >&2 echo "Error: get_discovery_topic requires 2 arguments"
        return 1
    fi
    
    # Load mqtt_helpers if not already loaded
    if ! declare -f load_config >/dev/null 2>&1; then
        local lib_dir
        lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        # shellcheck source=/dev/null
        source "$lib_dir/mqtt_helpers.sh" || return 1
        load_config || return 1
    fi
    
    # Build device identifier
    local device_id
    device_id="${MQTT_DEVICE_PREFIX}-$(hostname)"
    
    # Build discovery topic
    local topic="${MQTT_DISCOVERY_PREFIX}/${sensor_type}/${device_id}/${sensor_id}/config"
    
    echo "$topic"
    return 0
}

# Library loaded successfully
return 0 2>/dev/null || true
