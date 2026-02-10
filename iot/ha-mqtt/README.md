# Home Assistant MQTT Integration

**Module:** iot/ha-mqtt  
**Category:** IoT Integration  
**Status:** Production Ready  
**Version:** 1.0.0

Connect Luigi sensor modules to Home Assistant via MQTT for centralized monitoring, automation, and dashboards.

---

## Overview

The ha-mqtt module provides a **zero-touch MQTT bridge** between Luigi modules and Home Assistant. Any Luigi sensor can publish data and automatically appear in Home Assistant without modifying ha-mqtt code or configuration.

**Key Innovation:** Generic interface pattern eliminates tight coupling. Modules self-register by dropping JSON descriptors in a directory—no code changes required in ha-mqtt.

### What It Does

- **Publishes sensor data** to MQTT broker for Home Assistant consumption
- **Automatically registers sensors** in Home Assistant via MQTT Discovery protocol
- **Provides connection diagnostics** for troubleshooting MQTT issues
- **Supports any sensor type** through generic parameter-based interface

### Why It Exists

- **Eliminates manual HA configuration** - Sensors auto-register via MQTT Discovery
- **Zero-coupling design** - New modules integrate without ha-mqtt modifications
- **Centralized monitoring** - View all Luigi sensors in one Home Assistant instance
- **Enables automation** - Use HA automations with Luigi sensor data

---

## Contents

```
iot/ha-mqtt/
├── README.md                    # This file
├── setup.sh                     # Installation and deployment
├── bin/                         # Command-line scripts
│   ├── luigi-publish            # Universal sensor publisher
│   ├── luigi-discover           # Sensor registration tool
│   └── luigi-mqtt-status        # Connection diagnostics
├── lib/                         # Reusable libraries
│   ├── mqtt_helpers.sh          # MQTT operations
│   └── ha_discovery_generator.sh # Discovery payload generation
├── config/                      # Configuration
│   └── ha-mqtt.conf.example     # Configuration template
├── examples/                    # Examples and guides
│   ├── integration-guide.md     # Integration walkthrough
│   └── sensors.d/               # Example sensor descriptors
└── tests/                       # Test infrastructure
    ├── README.md                # Testing documentation
    ├── run-all-tests.sh         # Master test runner
    ├── syntax/                  # Syntax validation
    ├── functional/              # Functional tests
    └── integration/             # Integration tests
```

---

## Key Features

### 🎯 Generic Interface
Single `luigi-publish` command handles **all sensor types** via parameters. No sensor-specific code.

```bash
luigi-publish --sensor temp_sensor --value 23.5
luigi-publish --sensor motion --value ON --binary
```

### 🔌 Zero-Touch Integration
Modules integrate in 4 simple steps—no ha-mqtt modifications needed:

1. Create sensor descriptor JSON
2. Install to `sensors.d/` directory
3. Run `luigi-discover` once
4. Call `luigi-publish` from module code

### 🏠 Home Assistant MQTT Discovery
Sensors automatically appear in Home Assistant with correct types, units, and icons. No manual YAML configuration.

### 🔒 Security Built-In
- Credential protection (600 file permissions)
- Input validation (path traversal prevention)
- TLS encryption support
- Non-root operation recommended

---

## Architecture

```
┌─────────────────┐
│ Luigi Modules   │
│ (mario, temp,   │
│  system, etc.)  │
└────────┬────────┘
         │
         │ luigi-publish --sensor X --value Y
         │
┌────────▼────────┐
│   ha-mqtt       │
│   Bridge        │
│                 │
│ • luigi-publish │
│ • luigi-discover│
│ • mqtt_helpers  │
└────────┬────────┘
         │
         │ MQTT Protocol
         │
┌────────▼────────┐
│ MQTT Broker     │
│ (mosquitto)     │
└────────┬────────┘
         │
         │ MQTT Discovery
         │
┌────────▼────────┐
│ Home Assistant  │
│                 │
│ • Sensors       │
│ • Dashboards    │
│ • Automations   │
└─────────────────┘
```

**Data Flow:**
1. Module calls `luigi-publish --sensor temp --value 23.5`
2. ha-mqtt constructs MQTT topic and publishes to broker
3. Broker routes message to Home Assistant
4. HA updates sensor value and triggers automations

**Discovery Flow:**
1. Module installs descriptor to `sensors.d/`
2. Run `luigi-discover` (one-time)
3. ha-mqtt generates HA Discovery payload
4. Broker retains discovery message
5. HA automatically creates sensor entity

---

## Hardware Requirements

### Physical Hardware
- **None** - This is a software-only integration module
- No GPIO pins required
- No sensors or components needed

### Network Infrastructure
- **Raspberry Pi** with WiFi or Ethernet connectivity
- **MQTT Broker** accessible over network (e.g., mosquitto)
- **Home Assistant** instance with MQTT integration enabled

### Performance Impact
- **CPU:** < 1% during normal operation
- **Memory:** < 20MB for shell scripts
- **Network:** Minimal bandwidth (~1KB per sensor update)

---

## Dependencies

### Required
- **mosquitto-clients** - MQTT command-line tools (`mosquitto_pub`)
  ```bash
  sudo apt-get install mosquitto-clients
  ```

### Optional
- **jq** - JSON processor for descriptor validation
  ```bash
  sudo apt-get install jq
  ```

- **python3-paho-mqtt** - For optional Python service (future enhancement)
  ```bash
  sudo apt-get install python3-paho-mqtt
  ```

---

## Installation

### Prerequisites
1. MQTT broker running (mosquitto on Home Assistant)
2. Home Assistant MQTT integration configured
3. Luigi repository cloned to Raspberry Pi

### Automated Installation (Recommended)
```bash
cd /path/to/luigi
sudo ./setup.sh install iot/ha-mqtt
```

The setup script will:
- Install mosquitto-clients package
- Deploy scripts to `/usr/local/bin/`
- Deploy libraries to `/usr/local/lib/luigi/`
- Create config directory at `/etc/luigi/iot/ha-mqtt/`
- Install example config with 600 permissions
- Test MQTT connectivity

### Manual Installation
```bash
# 1. Install dependencies
sudo apt-get update
sudo apt-get install mosquitto-clients jq

# 2. Create directories
sudo mkdir -p /etc/luigi/iot/ha-mqtt/sensors.d
sudo mkdir -p /usr/local/lib/luigi
sudo mkdir -p /usr/share/luigi/ha-mqtt/examples

# 3. Deploy scripts
sudo cp bin/* /usr/local/bin/
sudo chmod 755 /usr/local/bin/luigi-*

# 4. Deploy libraries
sudo cp lib/* /usr/local/lib/luigi/
sudo chmod 644 /usr/local/lib/luigi/*.sh

# 5. Deploy configuration
sudo cp config/ha-mqtt.conf.example /etc/luigi/iot/ha-mqtt/ha-mqtt.conf
sudo chmod 600 /etc/luigi/iot/ha-mqtt/ha-mqtt.conf

# 6. Deploy examples
sudo cp -r examples/* /usr/share/luigi/ha-mqtt/examples/
```

---

## Configuration

### Configuration File
Edit `/etc/luigi/iot/ha-mqtt/ha-mqtt.conf`:

```ini
[Broker]
HOST=homeassistant.local
PORT=1883
TLS=no

[Authentication]
USERNAME=luigi
PASSWORD=your_secure_password

[Client]
CLIENT_ID=luigi_${HOSTNAME}
QOS=1

[Topics]
BASE_TOPIC=homeassistant
DISCOVERY_PREFIX=homeassistant
DEVICE_PREFIX=luigi
```

### Key Parameters

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| HOST | MQTT broker hostname or IP | homeassistant.local | mqtt.example.com |
| PORT | MQTT broker port | 1883 | 8883 (TLS) |
| USERNAME | MQTT authentication username | luigi | sensor_user |
| PASSWORD | MQTT authentication password | (required) | your_password |
| QOS | Quality of Service (0, 1, or 2) | 1 | 1 |
| BASE_TOPIC | Root topic for messages | homeassistant | luigi/sensors |

### Security Recommendations
```bash
# Set secure permissions on config file
sudo chmod 600 /etc/luigi/iot/ha-mqtt/ha-mqtt.conf

# Only owner (root or luigi user) can read credentials
```

### Variable Expansion
The configuration supports `${HOSTNAME}` variable expansion:
```ini
CLIENT_ID=luigi_${HOSTNAME}
DEVICE_NAME=Luigi ${HOSTNAME}
```
Automatically expands to: `luigi_raspberrypi`, `Luigi raspberrypi`

---

## Usage

### Integration Pattern (4 Steps)

#### Step 1: Create Sensor Descriptor
Create a JSON file describing your sensor:

```json
{
  "sensor_id": "bedroom_temperature",
  "name": "Bedroom Temperature",
  "device_class": "temperature",
  "unit_of_measurement": "°C",
  "icon": "mdi:thermometer",
  "state_class": "measurement",
  "module": "sensors/dht22"
}
```

**Required Fields:**
- `sensor_id` - Unique identifier (alphanumeric, underscore, hyphen)
- `name` - Human-readable name
- `module` - Source module name

**Optional Fields:**
- `device_class` - Home Assistant device class (temperature, humidity, motion, etc.)
- `unit_of_measurement` - Unit symbol (°C, %, lux, etc.)
- `icon` - Material Design Icon (mdi:thermometer)
- `state_class` - Measurement type (measurement, total, total_increasing)

#### Step 2: Install Descriptor
```bash
sudo cp my_sensor.json /etc/luigi/iot/ha-mqtt/sensors.d/
```

#### Step 3: Register with Home Assistant
```bash
sudo luigi-discover
```

Output:
```
=========================================
Luigi Sensor Discovery
=========================================

Scanning: /etc/luigi/iot/ha-mqtt/sensors.d/
Broker: homeassistant.local:1883

Found 1 descriptor(s)

✓ Bedroom Temperature (sensor)

=========================================
Summary
=========================================
Total descriptors: 1
Successfully registered: 1
Failed: 0

✓ All sensors registered successfully
```

#### Step 4: Publish Values
From your module code:

```bash
luigi-publish --sensor bedroom_temperature --value 23.5
```

Or with additional parameters:
```bash
luigi-publish --sensor bedroom_temperature \
  --value 23.5 \
  --unit "°C" \
  --device-class temperature
```

### Command Reference

#### luigi-publish
Publish sensor values to MQTT broker.

```bash
# Numeric sensor
luigi-publish --sensor temp_sensor --value 23.5

# Binary sensor (motion, door, etc.)
luigi-publish --sensor motion_detector --value ON --binary

# With attributes
luigi-publish --sensor temp_sensor --value 23.5 \
  --attributes '{"location": "bedroom", "battery": 95}'

# Retained message (persists on broker)
luigi-publish --sensor system_status --value "online" --retain
```

**Exit Codes:**
- `0` - Success
- `1` - Error (connection, validation, etc.)
- `2` - Missing dependencies

#### luigi-discover
Register sensors with Home Assistant via MQTT Discovery.

```bash
# Discover all sensors
sudo luigi-discover

# Force re-registration (after descriptor changes)
sudo luigi-discover --force

# Quiet mode (errors only, for cron jobs)
sudo luigi-discover --quiet

# Verbose debugging output
sudo luigi-discover --verbose
```

**Exit Codes:**
- `0` - All sensors registered
- `1` - Partial failure (some sensors failed)
- `2` - Complete failure (no sensors registered)

#### luigi-mqtt-status
Test and diagnose MQTT connectivity.

```bash
# Quick status check
luigi-mqtt-status

# Detailed diagnostics
luigi-mqtt-status --verbose
```

**Tests Performed:**
1. ✓ mosquitto_pub availability
2. ✓ DNS resolution
3. ✓ Network connectivity (ping)
4. ✓ Port connectivity
5. ✓ MQTT publish test

**Exit Codes:**
- `0` - Connection successful
- `1` - Connection failed
- `2` - Configuration error

---

## How It Works

### Generic Interface Pattern

Traditional approach (sensor-specific):
```bash
# Each sensor needs custom code
mqtt_publish_temperature $value
mqtt_publish_motion $state
mqtt_publish_humidity $value
```

Luigi approach (generic):
```bash
# One command for all sensors
luigi-publish --sensor temp --value $value
luigi-publish --sensor motion --value $state
luigi-publish --sensor humidity --value $value
```

**Benefits:**
- No ha-mqtt code changes for new sensors
- Consistent interface across all modules
- Easy to test and debug
- Clear separation of concerns

### Convention-Based Discovery

Modules register themselves by following conventions:

1. **Drop descriptor in standard location** (`sensors.d/`)
2. **Run discovery command** (`luigi-discover`)
3. **Discovery message retained** on broker
4. **Home Assistant auto-detects** sensor

No manual HA configuration files. No editing ha-mqtt code.

### MQTT Topic Structure

**State Topics:**
```
homeassistant/sensor/luigi-{HOSTNAME}/{sensor_id}/state
```

Example:
```
homeassistant/sensor/luigi-raspberrypi/bedroom_temp/state
```

**Discovery Topics:**
```
homeassistant/sensor/luigi-{HOSTNAME}/{sensor_id}/config
```

Example:
```
homeassistant/sensor/luigi-raspberrypi/bedroom_temp/config
```

**Payload Example:**
```json
{
  "name": "Bedroom Temperature",
  "unique_id": "luigi_raspberrypi_bedroom_temp",
  "state_topic": "homeassistant/sensor/luigi-raspberrypi/bedroom_temp/state",
  "device_class": "temperature",
  "unit_of_measurement": "°C",
  "state_class": "measurement",
  "device": {
    "identifiers": ["luigi-raspberrypi"],
    "name": "Luigi raspberrypi",
    "model": "Raspberry Pi Zero W",
    "manufacturer": "Luigi Project"
  }
}
```

---

## Troubleshooting

### Connection Failures

**Symptom:** `luigi-mqtt-status` reports connection failures

**Solutions:**
1. **Check broker is running:**
   ```bash
   ping homeassistant.local
   telnet homeassistant.local 1883
   ```

2. **Verify DNS resolution:**
   ```bash
   host homeassistant.local
   # Or use IP address in ha-mqtt.conf
   ```

3. **Test with mosquitto_pub directly:**
   ```bash
   mosquitto_pub -h homeassistant.local -t test -m "hello"
   ```

4. **Check firewall rules:**
   ```bash
   sudo iptables -L
   # Port 1883 should be open
   ```

### Authentication Errors

**Symptom:** "Connection refused" or "Not authorized"

**Solutions:**
1. **Verify credentials:**
   ```bash
   # Check config file
   sudo cat /etc/luigi/iot/ha-mqtt/ha-mqtt.conf
   ```

2. **Test authentication:**
   ```bash
   mosquitto_pub -h homeassistant.local \
     -u luigi -P your_password \
     -t test -m "hello"
   ```

3. **Check broker logs:**
   ```bash
   # On Home Assistant
   docker logs homeassistant_mqtt
   ```

4. **Verify user exists in broker:**
   - Home Assistant → Configuration → Integrations → MQTT → Configure
   - Add user: `luigi` with password

### Sensor Not Appearing in HA

**Symptom:** `luigi-discover` succeeds but sensor not in HA

**Solutions:**
1. **Wait 30 seconds** - HA polls discovery topics periodically

2. **Check MQTT integration enabled:**
   - Home Assistant → Configuration → Integrations
   - Should see "MQTT" integration

3. **Verify discovery message sent:**
   ```bash
   # Subscribe to discovery topic
   mosquitto_sub -h homeassistant.local \
     -t "homeassistant/#" -v
   ```

4. **Check Home Assistant logs:**
   - Home Assistant → Configuration → Logs
   - Look for MQTT-related errors

5. **Force re-discovery:**
   ```bash
   sudo luigi-discover --force
   ```

### Permission Issues

**Symptom:** "Permission denied" errors

**Solutions:**
1. **Config file permissions:**
   ```bash
   sudo chmod 600 /etc/luigi/iot/ha-mqtt/ha-mqtt.conf
   ```

2. **Script permissions:**
   ```bash
   sudo chmod 755 /usr/local/bin/luigi-*
   ```

3. **Run with sudo for system operations:**
   ```bash
   sudo luigi-discover  # Needs root to read config
   ```

### Invalid Descriptor Errors

**Symptom:** `luigi-discover` reports "Invalid descriptor"

**Solutions:**
1. **Validate JSON syntax:**
   ```bash
   cat descriptor.json | jq .
   ```

2. **Check required fields present:**
   ```json
   {
     "sensor_id": "required",
     "name": "required",
     "module": "required"
   }
   ```

3. **Verify sensor_id format:**
   - Only alphanumeric, underscore, hyphen
   - No spaces or special characters
   - No path traversal (../, //, \\)

---

## Home Assistant Setup

### MQTT Broker Installation

#### Option 1: Home Assistant Mosquitto Add-On (Recommended)
1. Navigate to: **Supervisor → Add-on Store**
2. Install: **Mosquitto broker**
3. Configure:
   ```yaml
   logins:
     - username: luigi
       password: your_secure_password
   ```
4. Start the add-on

#### Option 2: Standalone Mosquitto
```bash
sudo apt-get install mosquitto mosquitto-clients

# Create user
sudo mosquitto_passwd -c /etc/mosquitto/passwd luigi

# Configure /etc/mosquitto/mosquitto.conf
listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd

# Restart
sudo systemctl restart mosquitto
```

### Home Assistant MQTT Integration

1. **Enable MQTT Integration:**
   - Configuration → Integrations → Add Integration
   - Search for "MQTT"
   - Configure:
     - Broker: `localhost` (or IP if remote)
     - Port: `1883`
     - Username: (leave blank if using add-on)
     - Check "Enable discovery"

2. **Verify Integration:**
   - Configuration → Integrations
   - Should see "MQTT" with "configured" status

### User Creation

Create dedicated MQTT user for Luigi:

1. **In Mosquitto add-on config:**
   ```yaml
   logins:
     - username: luigi
       password: luigi_secure_password_here
   ```

2. **Set permissions (ACL - optional):**
   ```
   user luigi
   topic readwrite homeassistant/#
   topic readwrite luigi/#
   ```

### Network Configuration

1. **Find Home Assistant IP:**
   ```bash
   ping homeassistant.local
   # Or: Configuration → System → Network
   ```

2. **Test connectivity from Luigi:**
   ```bash
   ping homeassistant.local
   telnet homeassistant.local 1883
   ```

3. **Update Luigi config:**
   ```ini
   [Broker]
   HOST=homeassistant.local  # or use IP: 192.168.1.100
   ```

---

## Security

### Credential Protection

**Config File Permissions:**
```bash
# Set to 600 (owner read/write only)
sudo chmod 600 /etc/luigi/iot/ha-mqtt/ha-mqtt.conf

# Verify
ls -la /etc/luigi/iot/ha-mqtt/ha-mqtt.conf
# Should show: -rw------- (600)
```

**Why:** Prevents other users from reading MQTT password.

### TLS Encryption

For encrypted communication over untrusted networks:

```ini
[Broker]
HOST=mqtt.example.com
PORT=8883
TLS=yes
CA_CERT=/etc/ssl/certs/ca-certificates.crt
```

**Certificate Setup:**
1. Obtain broker's CA certificate
2. Copy to Raspberry Pi: `/etc/ssl/certs/`
3. Update config with path
4. Test: `luigi-mqtt-status`

### Input Validation

Built-in security measures:
- ✓ Sensor ID validation (alphanumeric + underscore/hyphen only)
- ✓ Path traversal prevention (no `../`, `/`, `\\`)
- ✓ Command timeout (10s default)
- ✓ Config permission checks

### Network Isolation

**Recommendations:**
1. **Use dedicated VLAN** for IoT devices
2. **Firewall rules** restrict access to MQTT port
3. **No internet exposure** for MQTT broker
4. **Strong passwords** (16+ characters)
5. **Regular updates** of mosquitto package

### Non-Root Operation

**Create luigi user (recommended):**
```bash
sudo useradd -r -s /bin/false luigi
sudo usermod -aG gpio luigi  # If needed for sensor modules

# Adjust permissions
sudo chown luigi:luigi /etc/luigi/iot/ha-mqtt/ha-mqtt.conf
sudo chmod 600 /etc/luigi/iot/ha-mqtt/ha-mqtt.conf
```

**Run as luigi user:**
```bash
sudo -u luigi luigi-publish --sensor test --value 42
```

---

## Integration Examples

### Example 1: Motion Detection (Mario Module)

**Descriptor:** `/etc/luigi/iot/ha-mqtt/sensors.d/mario_motion.json`
```json
{
  "sensor_id": "mario_motion_detector",
  "name": "Mario Motion Detector",
  "device_class": "motion",
  "icon": "mdi:run",
  "module": "motion-detection/mario"
}
```

**Module Code:** `motion-detection/mario/mario.py`
```python
import subprocess

def on_motion_detected():
    # Play sound
    play_mario_sound()
    
    # Publish to Home Assistant
    subprocess.run([
        'luigi-publish',
        '--sensor', 'mario_motion_detector',
        '--value', 'ON',
        '--binary'
    ])
    
    # Clear after cooldown
    time.sleep(1800)  # 30 minutes
    subprocess.run([
        'luigi-publish',
        '--sensor', 'mario_motion_detector',
        '--value', 'OFF',
        '--binary'
    ])
```

**Home Assistant Automation:**
```yaml
automation:
  - alias: "Mario Motion Alert"
    trigger:
      - platform: state
        entity_id: binary_sensor.mario_motion_detector
        to: "on"
    action:
      - service: notify.mobile_app
        data:
          message: "Motion detected in Mario zone!"
```

### Example 2: Temperature Monitoring

**Descriptor:** `/etc/luigi/iot/ha-mqtt/sensors.d/bedroom_temp.json`
```json
{
  "sensor_id": "bedroom_temperature",
  "name": "Bedroom Temperature",
  "device_class": "temperature",
  "unit_of_measurement": "°C",
  "icon": "mdi:thermometer",
  "state_class": "measurement",
  "module": "sensors/dht22"
}
```

**Module Code:** `sensors/dht22/temp_monitor.sh`
```bash
#!/bin/bash

# Read temperature from sensor
temp=$(read_dht22_temperature)

# Publish to Home Assistant
luigi-publish --sensor bedroom_temperature --value "$temp"

# Log locally
echo "$(date): Temperature = ${temp}°C" >> /var/log/temperature.log
```

**Cron Job:**
```cron
# Update every 5 minutes
*/5 * * * * /usr/local/bin/sensors/temp_monitor.sh
```

### Example 3: System Monitoring

**Descriptor:** `/etc/luigi/iot/ha-mqtt/sensors.d/cpu_temp.json`
```json
{
  "sensor_id": "cpu_temperature",
  "name": "CPU Temperature",
  "device_class": "temperature",
  "unit_of_measurement": "°C",
  "icon": "mdi:chip",
  "state_class": "measurement",
  "module": "system/monitor"
}
```

**Module Code:** `system/monitor/monitor.sh`
```bash
#!/bin/bash

# Get CPU temperature
cpu_temp=$(vcgencmd measure_temp | grep -oP '\d+\.\d+')

# Get CPU usage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)

# Publish both metrics
luigi-publish --sensor cpu_temperature --value "$cpu_temp"
luigi-publish --sensor cpu_usage --value "$cpu_usage" \
  --device-class "power_factor" --unit "%"
```

---

## Notes

### Important Operational Notes

1. **Discovery Messages are Retained**
   - Discovery messages persist on broker
   - Sensors reappear in HA after HA restarts
   - Manual cleanup required if removing sensors permanently

2. **Sensor Removal Process**
   ```bash
   # 1. Remove descriptor
   sudo rm /etc/luigi/iot/ha-mqtt/sensors.d/sensor_name.json
   
   # 2. Remove from Home Assistant (manual)
   # Configuration → Entities → Delete sensor
   
   # 3. Clear retained message (optional)
   mosquitto_pub -h broker -t "discovery/topic" -r -n
   ```

3. **Multiple Luigi Instances**
   - Each Luigi host has unique device ID: `luigi-{HOSTNAME}`
   - All sensors from one host grouped under one device in HA
   - Multiple hosts supported on same broker

4. **QoS Recommendations**
   - QoS 0: Best for high-frequency updates (system stats)
   - QoS 1: Recommended for important events (motion, alerts)
   - QoS 2: Overkill for most home automation use cases

5. **Performance Considerations**
   - Each `luigi-publish` call spawns mosquitto_pub process
   - For high-frequency updates, consider batching
   - Python service (future) will maintain persistent connection

### Limitations

- **No command support** (HA → Luigi) in current version
- **No automatic descriptor removal** from HA
- **No built-in retry logic** (future enhancement)
- **Shell script overhead** for each publish (~50ms)

---

## Future Enhancements

### Planned Features

1. **Python Service (Optional)**
   - Persistent MQTT connection
   - Automatic reconnection with exponential backoff
   - Periodic descriptor scanning
   - Lower overhead for frequent updates

2. **Command Support**
   - Subscribe to command topics
   - Enable HA → Luigi control
   - Support switches, buttons, select entities

3. **Advanced Discovery**
   - Automatic binary_sensor vs sensor detection
   - Device triggers for automation
   - Configuration via MQTT

4. **Monitoring & Metrics**
   - Publish bridge health metrics
   - Connection uptime tracking
   - Message throughput statistics

5. **Enhanced Security**
   - Client certificate authentication
   - Per-sensor ACL support
   - Credential rotation helpers

### Contributing

Want to add features? See:
- `DESIGN_ANALYSIS.md` - Module design specifications
- `IMPLEMENTATION_PLAN.md` - Development phases
- `.github/skills/module-design/` - Design guidelines

---

## References

### External Documentation

- **Home Assistant MQTT Discovery:** https://www.home-assistant.io/integrations/mqtt/#mqtt-discovery
- **Mosquitto Documentation:** https://mosquitto.org/documentation/
- **MQTT Protocol Specification:** https://mqtt.org/mqtt-specification/
- **Paho MQTT Python:** https://pypi.org/project/paho-mqtt/

### Luigi Documentation

- **Module Design Skill:** `.github/skills/module-design/SKILL.md`
- **Python Development:** `.github/skills/python-development/SKILL.md`
- **System Setup:** `.github/skills/system-setup/SKILL.md`
- **Raspberry Pi GPIO:** `.github/skills/raspi-zero-w/SKILL.md`

### Support

- **Repository:** https://github.com/pkathmann88/luigi
- **Issues:** https://github.com/pkathmann88/luigi/issues
- **Discussions:** https://github.com/pkathmann88/luigi/discussions

---

**Document Version:** 1.0  
**Created:** 2026-02-10  
**Last Updated:** 2026-02-10  
**Status:** Complete
