# Documentation Patterns and Examples

This document provides detailed examples and patterns for common documentation scenarios in Luigi modules.

## Table of Contents

1. [Hardware Documentation Patterns](#hardware-documentation-patterns)
2. [Configuration Documentation](#configuration-documentation)
3. [Installation Documentation](#installation-documentation)
4. [Troubleshooting Documentation](#troubleshooting-documentation)
5. [Integration Documentation](#integration-documentation)
6. [API Documentation Patterns](#api-documentation-patterns)
7. [Wiring Diagrams](#wiring-diagrams)
8. [Service Management Documentation](#service-management-documentation)

---

## Hardware Documentation Patterns

### Pattern 1: Simple Sensor Module

**Example from motion-detection/mario:**

```markdown
## Hardware Requirements

### Components

- **PIR Motion Sensor** (HC-SR501 or similar)
  - 3 pins: VCC, GND, OUT
  - Operating voltage: 5V
  - Detection range: Up to 7 meters
  - Detection angle: ~110 degrees

- **Speakers or Headphones**
  - 3.5mm audio jack or HDMI audio output
  - Recommended: Active speakers with separate power supply

### GPIO Pin Configuration

**PIR Sensor Connection:**
- **VCC** → Pin 2 (5V Power)
- **GND** → Pin 6 (Ground)
- **OUT** → Pin 16 (GPIO 23) - BCM numbering

**GPIO Summary:**
| Function | BCM Pin | Physical Pin | Direction |
|----------|---------|--------------|-----------|
| PIR Motion Input | GPIO 23 | Pin 16 | Input (Pull-down) |

**Pin Configuration:**
- GPIO 23 configured with PULL-DOWN resistor
- Detects RISING edge (LOW → HIGH transition)
```

### Pattern 2: Complex Multi-Sensor Module

**Example pattern:**

```markdown
## Hardware Requirements

### Required Components

1. **DHT22 Temperature/Humidity Sensor**
   - Operating Voltage: 3.3V - 5V
   - Temperature Range: -40°C to 80°C
   - Humidity Range: 0-100% RH
   - Communication: Single-wire digital protocol
   - [Purchase Link](https://www.adafruit.com/product/385)

2. **Light Sensor (LDR with voltage divider)**
   - Photoresistor (5mm CdS cell)
   - 10kΩ resistor for voltage divider
   - Operating voltage: 3.3V

3. **Additional Components**
   - Breadboard or PCB for connections
   - Jumper wires (male-to-female)
   - 10kΩ resistor (for LDR voltage divider)

### GPIO Pin Assignments

| Sensor | Function | BCM Pin | Physical Pin | Notes |
|--------|----------|---------|--------------|-------|
| DHT22 | Data | GPIO 4 | Pin 7 | Pull-up resistor included |
| LDR | Analog Read | GPIO 17 | Pin 11 | Via capacitor timing circuit |
| Status LED | Output | GPIO 27 | Pin 13 | Active high (optional) |

**Total GPIO Usage:** 3 pins (GPIO 4, 17, 27)

### Power Requirements

- Total current draw: ~50mA (all sensors active)
- Power from Pi sufficient for all components
- No external power supply required

### Wiring Safety Notes

⚠️ **Important Safety Considerations:**
- DHT22 operates at 3.3V or 5V - verify your model
- Never connect 5V directly to a 3.3V-only pin
- Use breadboard for testing before permanent installation
- Double-check polarity before powering on
```

### Pattern 3: Minimal Hardware (Software-Only Module)

**Example for system modules:**

```markdown
## Hardware Requirements

This module is **software-only** and requires no additional hardware components beyond the Raspberry Pi itself.

**System Requirements:**
- Raspberry Pi Zero W (or any Raspberry Pi model)
- Active network connection (for MQTT features)
- 512MB+ RAM recommended
- 50MB free disk space

**No GPIO pins used.**
```

---

## Configuration Documentation

### Pattern 1: INI-Style Configuration

**Example configuration documentation:**

```markdown
## Configuration

The module is configured via a configuration file located at:

**Configuration File:** `/etc/luigi/motion-detection/mario/mario.conf`

### Configuration Format

The configuration file uses INI-style key=value format:

```ini
# GPIO Configuration
GPIO_PIN=23

# Timing Configuration
COOLDOWN_SECONDS=1800
DEBOUNCE_TIME_MS=200

# Audio Configuration
SOUND_DIR=/usr/share/sounds/mario
ALSA_DEVICE=default

# MQTT Integration (optional)
MQTT_ENABLED=true
MQTT_SENSOR_ID=mario_motion
MQTT_OFF_DELAY=5
```

### Configuration Options Reference

#### GPIO Configuration

- **`GPIO_PIN`** (integer, required)
  - GPIO pin number in BCM numbering
  - Default: `23`
  - Range: Any valid BCM GPIO pin (0-27)
  - Example: `GPIO_PIN=23`

- **`GPIO_PULL_UP_DOWN`** (string, required)
  - Internal pull resistor configuration
  - Default: `DOWN`
  - Options: `UP`, `DOWN`, `OFF`
  - Example: `GPIO_PULL_UP_DOWN=DOWN`

#### Timing Configuration

- **`COOLDOWN_SECONDS`** (integer, required)
  - Seconds to wait between motion detections
  - Default: `1800` (30 minutes)
  - Range: 0-86400 (0 = disabled)
  - Example: `COOLDOWN_SECONDS=1800`
  
- **`DEBOUNCE_TIME_MS`** (integer, required)
  - Milliseconds to ignore rapid triggers
  - Default: `200`
  - Range: 0-1000
  - Example: `DEBOUNCE_TIME_MS=200`

#### Audio Configuration

- **`SOUND_DIR`** (path, required)
  - Directory containing sound files
  - Default: `/usr/share/sounds/mario`
  - Must contain .wav files
  - Example: `SOUND_DIR=/usr/share/sounds/mario`

- **`ALSA_DEVICE`** (string, required)
  - ALSA audio device name
  - Default: `default`
  - Find devices: `aplay -L`
  - Example: `ALSA_DEVICE=plughw:0,0`

#### MQTT Integration (Optional)

- **`MQTT_ENABLED`** (boolean, optional)
  - Enable Home Assistant MQTT integration
  - Default: `false`
  - Options: `true`, `false`
  - Requires: iot/ha-mqtt module installed
  - Example: `MQTT_ENABLED=true`

- **`MQTT_SENSOR_ID`** (string, optional)
  - Sensor identifier for MQTT messages
  - Default: `mario_motion`
  - Must match sensor descriptor filename
  - Example: `MQTT_SENSOR_ID=mario_motion`

- **`MQTT_OFF_DELAY`** (integer, optional)
  - Seconds delay before sending OFF state
  - Default: `5`
  - Range: 0-3600
  - Example: `MQTT_OFF_DELAY=5`

### Applying Configuration Changes

After modifying the configuration file:

```bash
# Restart the service to apply changes
sudo systemctl restart mario

# Verify service started successfully
sudo systemctl status mario

# Check logs for configuration errors
journalctl -u mario -n 50
```

### Configuration Validation

The module validates configuration on startup. Check logs if service fails to start:

```bash
# View recent errors
journalctl -u mario -p err -n 20
```

Common validation errors:
- Invalid GPIO pin number
- Missing sound directory
- Invalid ALSA device
- File permission issues
```

### Pattern 2: JSON Configuration

**Example for complex modules:**

```markdown
## Configuration

**Configuration File:** `/etc/luigi/module-name/config.json`

### Configuration Format

```json
{
  "hardware": {
    "gpio_pins": {
      "sensor": 4,
      "led": 27
    },
    "sample_interval": 60
  },
  "mqtt": {
    "enabled": true,
    "broker": "localhost",
    "port": 1883,
    "topic_prefix": "luigi/sensors"
  },
  "logging": {
    "level": "INFO",
    "file": "/var/log/luigi/module-name.log",
    "max_size_mb": 10,
    "backup_count": 3
  }
}
```

### Configuration Schema

#### hardware object

- `gpio_pins` (object) - GPIO pin assignments
  - `sensor` (integer) - BCM pin for sensor
  - `led` (integer) - BCM pin for status LED
- `sample_interval` (integer) - Seconds between readings

#### mqtt object

- `enabled` (boolean) - Enable MQTT integration
- `broker` (string) - MQTT broker hostname
- `port` (integer) - MQTT broker port (default: 1883)
- `topic_prefix` (string) - Base topic for messages

#### logging object

- `level` (string) - Log level: DEBUG, INFO, WARNING, ERROR
- `file` (string) - Log file path
- `max_size_mb` (integer) - Max log file size before rotation
- `backup_count` (integer) - Number of backup logs to keep

### Validating Configuration

```bash
# Test configuration validity
python3 -c "import json; json.load(open('/etc/luigi/module-name/config.json'))"

# If valid, no output is shown
# If invalid, error message indicates the problem
```
```

---

## Installation Documentation

### Pattern 1: Standard Module Installation

```markdown
## Installation

### Prerequisites

Before installing, ensure your Raspberry Pi is up to date:

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

### Automatic Installation (Recommended)

Install from the Luigi repository root:

```bash
# Clone repository if not already present
git clone https://github.com/pkathmann88/luigi.git
cd luigi

# Install the module
sudo ./setup.sh install motion-detection/mario

# Verify installation
./setup.sh status motion-detection/mario
```

The setup script automatically:
- Installs system dependencies
- Creates required directories
- Deploys configuration files
- Installs and enables systemd service
- Starts the service

### Manual Installation

Only use manual installation if automatic installation fails or for custom deployments.

#### 1. Install System Dependencies

```bash
sudo apt-get install -y python3-rpi.gpio alsa-utils
```

#### 2. Create Directories

```bash
sudo mkdir -p /etc/luigi/motion-detection/mario
sudo mkdir -p /var/log/luigi
sudo mkdir -p /usr/share/sounds/mario
```

#### 3. Deploy Files

```bash
# Copy Python script
sudo cp motion-detection/mario/mario.py /usr/local/bin/mario
sudo chmod +x /usr/local/bin/mario

# Extract and deploy sounds
tar -xzf motion-detection/mario/mario-sounds.tar.gz
sudo cp mario-sounds/*.wav /usr/share/sounds/mario/
sudo chmod 644 /usr/share/sounds/mario/*.wav

# Deploy configuration
sudo cp motion-detection/mario/mario.conf.example /etc/luigi/motion-detection/mario/mario.conf
sudo chmod 640 /etc/luigi/motion-detection/mario/mario.conf

# Deploy service file
sudo cp motion-detection/mario/mario.service /etc/systemd/system/
sudo chmod 644 /etc/systemd/system/mario.service
```

#### 4. Enable and Start Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service (start on boot)
sudo systemctl enable mario

# Start service now
sudo systemctl start mario

# Verify service is running
sudo systemctl status mario
```

### Verification

After installation, verify the module is working:

```bash
# Check service status
sudo systemctl status mario

# View recent logs
journalctl -u mario -n 20

# Test motion detection
# Wave your hand in front of the PIR sensor
# Sound should play and appear in logs
```

Expected log output:
```
Jan 15 10:23:45 raspberrypi mario[1234]: INFO: Motion detected! Playing sound: /usr/share/sounds/mario/callingmario3.wav
Jan 15 10:23:48 raspberrypi mario[1234]: INFO: Sound playback completed
```
```

### Pattern 2: Installation with Dependencies

```markdown
## Installation

This module depends on the **ha-mqtt** module for Home Assistant integration.

### Installation Order

The setup script automatically handles dependencies:

```bash
# Install from repository root
# Dependencies are installed automatically
sudo ./setup.sh install system/system-info
```

The setup will:
1. Detect that ha-mqtt is required
2. Install ha-mqtt first (if not already installed)
3. Install system-info
4. Configure integration between modules

### Manual Dependency Installation

If installing manually, install dependencies first:

```bash
# 1. Install dependency (ha-mqtt)
sudo ./setup.sh install iot/ha-mqtt

# 2. Configure ha-mqtt
sudo nano /etc/luigi/iot/ha-mqtt/mqtt.conf

# 3. Install this module
sudo ./setup.sh install system/system-info
```

### Verifying Dependencies

Check that required modules are installed:

```bash
# Check module registry
ls /etc/luigi/modules/

# Should show:
# iot__ha-mqtt.json
# system__system-info.json
```
```

---

## Troubleshooting Documentation

### Pattern 1: Comprehensive Troubleshooting Section

```markdown
## Troubleshooting

### Service Won't Start

**Symptom:** Service fails to start or immediately stops after starting

```bash
sudo systemctl status mario
# Shows: "failed" or "inactive (dead)"
```

**Diagnosis:**

1. Check for configuration errors:
```bash
journalctl -u mario -n 50 | grep -i error
```

2. Verify configuration file exists and is readable:
```bash
ls -l /etc/luigi/motion-detection/mario/mario.conf
# Should show: -rw-r----- 1 root root
```

3. Check GPIO permissions:
```bash
# Service must run as root for GPIO access
sudo systemctl cat mario | grep User
# Should NOT show "User=" line (runs as root)
```

**Solutions:**

- **If config file missing:** Run `sudo ./setup.sh install motion-detection/mario` again
- **If config invalid:** Check syntax in `/etc/luigi/motion-detection/mario/mario.conf`
- **If permission denied:** Ensure service runs as root (no User= in service file)

---

### No Sound Playback

**Symptom:** Motion detected but no sound plays

```bash
journalctl -u mario -f
# Shows: Motion detected, but no sound playback message
```

**Diagnosis:**

1. Test ALSA audio manually:
```bash
aplay /usr/share/sounds/mario/callingmario1.wav
```

2. Check sound files exist:
```bash
ls -l /usr/share/sounds/mario/
# Should show multiple .wav files
```

3. Check ALSA device configuration:
```bash
aplay -L  # List available devices
```

**Solutions:**

- **If "command not found":** Install alsa-utils: `sudo apt-get install alsa-utils`
- **If "No such file":** Re-extract sounds: `tar -xzf mario-sounds.tar.gz`
- **If "Device not found":** Update `ALSA_DEVICE` in config to valid device from `aplay -L`
- **If audio plays manually but not from service:** Check service journal for aplay errors

**Audio Configuration Help:**

```bash
# List audio devices
aplay -L

# Test specific device
aplay -D plughw:0,0 /usr/share/sounds/mario/callingmario1.wav

# Update configuration
sudo nano /etc/luigi/motion-detection/mario/mario.conf
# Change: ALSA_DEVICE=plughw:0,0

# Restart service
sudo systemctl restart mario
```

---

### Motion Not Detected

**Symptom:** PIR sensor doesn't trigger motion detection

**Diagnosis:**

1. Check GPIO pin configuration:
```bash
# View config
cat /etc/luigi/motion-detection/mario/mario.conf | grep GPIO_PIN
```

2. Check service logs:
```bash
journalctl -u mario -f
# Wave hand in front of sensor - should see log entries
```

3. Test PIR sensor manually:
```bash
# Install GPIO monitoring tool
sudo apt-get install gpiomon

# Monitor GPIO 23 for changes (use your configured pin)
gpiomon -r -f --edge=rising gpiochip0 23
# Wave hand - should show events
```

**Solutions:**

- **If GPIO wrong in config:** Update `GPIO_PIN` in `/etc/luigi/motion-detection/mario/mario.conf`
- **If wiring issue:** Verify connections match wiring diagram above
- **If sensor faulty:** Replace PIR sensor
- **If cooldown active:** Wait for cooldown period to expire (default: 30 minutes)

**PIR Sensor Adjustment:**

Most PIR sensors have two potentiometers:
- **Sensitivity (S or SENS):** Adjust detection range
- **Time Delay (T):** Hardware trigger duration (set to minimum, software handles timing)

Turn sensitivity clockwise to increase range.

---

### MQTT Integration Not Working

**Symptom:** Motion detected but not appearing in Home Assistant

**Diagnosis:**

1. Verify MQTT is enabled in config:
```bash
grep MQTT_ENABLED /etc/luigi/motion-detection/mario/mario.conf
# Should show: MQTT_ENABLED=true
```

2. Check ha-mqtt module is installed:
```bash
systemctl status ha-mqtt
# Should show: active (running)
```

3. Test MQTT manually:
```bash
/usr/local/bin/luigi-publish --sensor mario_motion --value ON --binary
```

4. Monitor MQTT messages:
```bash
mosquitto_sub -h localhost -t 'homeassistant/#' -v
```

**Solutions:**

- **If MQTT_ENABLED=false:** Enable in config and restart service
- **If ha-mqtt not installed:** Install with `sudo ./setup.sh install iot/ha-mqtt`
- **If sensor not registered:** Create sensor descriptor at `/etc/luigi/iot/ha-mqtt/sensors.d/mario_motion.json`
- **If MQTT broker unreachable:** Check network and broker status

See **iot/ha-mqtt README** for complete MQTT troubleshooting.

---

### High CPU Usage

**Symptom:** Mario service using excessive CPU

**Diagnosis:**

```bash
# Check CPU usage
top -p $(pgrep -f mario)

# Check for rapid triggering
journalctl -u mario -n 100 | grep "Motion detected" | wc -l
# If count is very high, sensor may be triggering too frequently
```

**Solutions:**

- **Increase DEBOUNCE_TIME_MS:** Edit config, increase from 200 to 500+
- **Adjust PIR sensitivity:** Turn sensitivity potentiometer counter-clockwise
- **Check for interference:** Ensure sensor not near heat sources, moving objects
- **Verify PIR sensor quality:** Cheap sensors can trigger falsely

---

### Service Logs Growing Too Large

**Symptom:** Log file consuming disk space

**Diagnosis:**

```bash
# Check log size
ls -lh /var/log/luigi/mario.log
```

**Solution:**

The service uses systemd journal with automatic rotation. Old logs are automatically removed. If concerned about disk space:

```bash
# View journal disk usage
journalctl --disk-usage

# Clean old journal entries
sudo journalctl --vacuum-time=7d  # Keep 7 days
sudo journalctl --vacuum-size=100M  # Keep 100MB max
```

---

### General Debugging Steps

When encountering any issue:

1. **Check service status**
   ```bash
   sudo systemctl status mario
   ```

2. **View recent logs**
   ```bash
   journalctl -u mario -n 50
   ```

3. **View errors only**
   ```bash
   journalctl -u mario -p err -n 20
   ```

4. **Follow logs in real-time**
   ```bash
   journalctl -u mario -f
   ```

5. **Restart service**
   ```bash
   sudo systemctl restart mario
   ```

6. **Verify configuration**
   ```bash
   cat /etc/luigi/motion-detection/mario/mario.conf
   ```

7. **Check file permissions**
   ```bash
   ls -l /etc/luigi/motion-detection/mario/
   ls -l /usr/share/sounds/mario/
   ```

If problems persist after trying solutions above, check the [Luigi GitHub Issues](https://github.com/pkathmann88/luigi/issues) or open a new issue with:
- Service status output
- Recent log entries
- Configuration file contents
- Hardware setup description
```

---

## Integration Documentation

### Pattern 1: Home Assistant MQTT Integration

```markdown
## Home Assistant Integration

This module supports integration with Home Assistant via MQTT, allowing you to:
- View motion detection status in Home Assistant dashboard
- Create automations based on motion events
- Track motion history and statistics

### Prerequisites

- Home Assistant installed and running
- MQTT broker configured in Home Assistant
- Luigi ha-mqtt module installed on Raspberry Pi

### Setup Instructions

#### 1. Install ha-mqtt Module

If not already installed:

```bash
sudo ./setup.sh install iot/ha-mqtt
```

Configure MQTT broker connection in `/etc/luigi/iot/ha-mqtt/mqtt.conf`.

#### 2. Create Sensor Descriptor

Create `/etc/luigi/iot/ha-mqtt/sensors.d/mario_motion.json`:

```json
{
  "sensor_id": "mario_motion",
  "name": "Mario Motion Sensor",
  "module": "motion-detection/mario",
  "device_class": "motion",
  "icon": "mdi:motion-sensor",
  "location": "Living Room"
}
```

#### 3. Run Discovery

Register the sensor with Home Assistant:

```bash
sudo /usr/local/bin/luigi-discover
```

The sensor will automatically appear in Home Assistant within 1 minute.

#### 4. Enable MQTT in Mario Configuration

Edit `/etc/luigi/motion-detection/mario/mario.conf`:

```ini
MQTT_ENABLED=true
MQTT_SENSOR_ID=mario_motion
MQTT_OFF_DELAY=5
```

#### 5. Restart Service

```bash
sudo systemctl restart mario
```

### Verification

1. Check Home Assistant:
   - Go to **Settings** → **Devices & Services**
   - Click **MQTT** integration
   - Find **Luigi - Mario Motion Sensor** device
   - Verify entity: `binary_sensor.mario_motion`

2. Trigger motion and verify state change in Home Assistant

3. Check MQTT messages:
```bash
mosquitto_sub -h localhost -t 'homeassistant/#' -v
```

### Example Automations

#### Automation 1: Turn on Lights on Motion

```yaml
automation:
  - alias: "Living Room Motion Lights"
    trigger:
      - platform: state
        entity_id: binary_sensor.mario_motion
        to: "on"
    action:
      - service: light.turn_on
        target:
          entity_id: light.living_room
```

#### Automation 2: Send Notification

```yaml
automation:
  - alias: "Motion Detected Notification"
    trigger:
      - platform: state
        entity_id: binary_sensor.mario_motion
        to: "on"
    action:
      - service: notify.mobile_app
        data:
          message: "Motion detected in living room"
          title: "Luigi Motion Alert"
```

### Troubleshooting Integration

See [Troubleshooting](#troubleshooting) section above and `iot/ha-mqtt/README.md` for detailed MQTT troubleshooting.
```

---

## API Documentation Patterns

### Pattern 1: REST Endpoint Documentation

```markdown
### GET /api/modules/:name

Get detailed information about a specific module.

**Authentication:** Required

**Parameters:**
- `name` (string, path) - Module name (e.g., "mario", "ha-mqtt")

**Response Schema (TypeScript):**
```typescript
interface ModuleDetail {
  success: boolean;
  data: {
    name: string;              // Module name
    path: string;              // Full module path
    status: 'active' | 'inactive' | 'failed' | 'installed' | 'unknown';
    version: string;           // Module version
    description: string;       // Module description
    category: string;          // Module category
    
    // Service information (if has 'service' capability)
    service?: {
      name: string;            // Systemd service name
      enabled: boolean;        // Starts on boot
      pid?: number;            // Process ID if running
      uptime?: string;         // How long service has been running
      memory?: string;         // Memory usage (e.g., "15.2 MB")
    };
    
    // Hardware configuration
    hardware?: {
      gpio_pins: Array<{
        pin: number;           // BCM pin number
        mode: 'input' | 'output';
        purpose: string;       // What the pin is used for
      }>;
      sensors?: string[];      // Connected sensors
    };
    
    // Dependencies
    dependencies: string[];    // Module paths this depends on
    dependents: string[];      // Modules that depend on this one
    
    // Capabilities
    capabilities: string[];    // e.g., ['service', 'gpio', 'mqtt']
    
    // Timestamps
    installed_at: string;      // ISO 8601 timestamp
    updated_at: string;        // ISO 8601 timestamp
  };
}
```

**Example Request (curl):**
```bash
curl -u admin:password \
  http://localhost:3000/api/modules/mario
```

**Example Request (JavaScript):**
```javascript
const response = await fetch('http://localhost:3000/api/modules/mario', {
  headers: {
    'Authorization': 'Basic ' + btoa('admin:password')
  }
});
const data = await response.json();
console.log(data.data.status);  // 'active'
```

**Example Success Response:**
```json
{
  "success": true,
  "data": {
    "name": "mario",
    "path": "motion-detection/mario",
    "status": "active",
    "version": "1.0.0",
    "description": "Motion detection with Mario sounds",
    "category": "motion-detection",
    "service": {
      "name": "mario",
      "enabled": true,
      "pid": 1234,
      "uptime": "2 days, 5 hours",
      "memory": "15.2 MB"
    },
    "hardware": {
      "gpio_pins": [
        {
          "pin": 23,
          "mode": "input",
          "purpose": "PIR motion sensor"
        }
      ]
    },
    "dependencies": ["iot/ha-mqtt"],
    "dependents": [],
    "capabilities": ["service", "gpio", "mqtt"],
    "installed_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-20T14:22:00Z"
  }
}
```

**Error Responses:**

*Module Not Found (404):*
```json
{
  "success": false,
  "error": "MODULE_NOT_FOUND",
  "message": "Module 'invalid-name' not found"
}
```

*Unauthorized (401):*
```json
{
  "success": false,
  "error": "AUTHENTICATION_FAILED",
  "message": "Invalid credentials"
}
```

**Status Codes:**
- `200 OK` - Module found and returned
- `401 Unauthorized` - Authentication failed
- `404 Not Found` - Module doesn't exist
- `500 Internal Server Error` - Server error
```

---

## Wiring Diagrams

### Pattern 1: Simple Text-Based Wiring

```markdown
## Wiring

Connect the PIR sensor to your Raspberry Pi:

```
PIR Sensor          Raspberry Pi Zero W
──────────         ────────────────────
VCC      ─────────> Pin 2  (5V Power)
GND      ─────────> Pin 6  (Ground)
OUT      ─────────> Pin 16 (GPIO 23)
```

**Important:** Double-check connections before powering on.
```

### Pattern 2: Detailed Table Format

```markdown
## Wiring Diagram

### GPIO Connections

| Component | Pin Name | Raspberry Pi Pin | Raspberry Pi Function | Notes |
|-----------|----------|------------------|----------------------|-------|
| PIR Sensor | VCC | Pin 2 | 5V Power | Red wire typically |
| PIR Sensor | GND | Pin 6 | Ground | Black wire typically |
| PIR Sensor | OUT | Pin 16 | GPIO 23 (BCM) | Yellow/White wire |
| Status LED (Optional) | + (Anode) | Pin 13 | GPIO 27 (BCM) | Via 220Ω resistor |
| Status LED (Optional) | - (Cathode) | Pin 14 | Ground | Connect to ground rail |

### Visual Reference

```
Raspberry Pi Zero W (Top View)
                           
    3.3V [ 1] [ 2] 5V      ◄── PIR VCC
     GP2 [ 3] [ 4] 5V
     GP3 [ 5] [ 6] GND     ◄── PIR GND
     GP4 [ 7] [ 8] GP14
     GND [ 9] [10] GP15
    GP17 [11] [12] GP18
    GP27 [13] [14] GND
    GP22 [15] [16] GP23    ◄── PIR OUT
    3.3V [17] [18] GP24
    GP10 [19] [20] GND
     GP9 [21] [22] GP25
    GP11 [23] [24] GP8
     GND [25] [26] GP7
     ...
```
```

### Pattern 3: Step-by-Step Wiring Instructions

```markdown
## Step-by-Step Wiring

**⚠️ Power off your Raspberry Pi before making connections!**

### Step 1: Prepare Components

Gather:
- Raspberry Pi Zero W (powered off!)
- PIR sensor (HC-SR501)
- 3x female-to-female jumper wires
- Breadboard (optional, for testing)

### Step 2: Identify PIR Sensor Pins

Your PIR sensor has 3 pins, usually labeled:
- **VCC** or **+** - Power (often red wire)
- **GND** or **-** - Ground (often black wire)
- **OUT** or **Signal** - Data output (often yellow wire)

Some sensors have pins in different orders - check your datasheet!

### Step 3: Connect Power (VCC)

- Take a jumper wire (red if possible)
- Connect one end to PIR **VCC** pin
- Connect other end to Raspberry Pi **Pin 2** (5V, top right)

### Step 4: Connect Ground (GND)

- Take a jumper wire (black if possible)
- Connect one end to PIR **GND** pin
- Connect other end to Raspberry Pi **Pin 6** (Ground, third from top right)

### Step 5: Connect Signal (OUT)

- Take a jumper wire (yellow or white)
- Connect one end to PIR **OUT** pin
- Connect other end to Raspberry Pi **Pin 16** (GPIO 23, eighth from top left)

### Step 6: Verify Connections

Double-check all connections:
- [ ] PIR VCC → Pi Pin 2 (5V)
- [ ] PIR GND → Pi Pin 6 (Ground)
- [ ] PIR OUT → Pi Pin 16 (GPIO 23)
- [ ] No loose connections
- [ ] No wires touching each other

### Step 7: Power On

- Power on your Raspberry Pi
- PIR sensor LED should light up (warm-up period: ~60 seconds)
- Wait for PIR to stabilize before testing

### Testing Connection

After software installation, test the connection:

```bash
# Monitor GPIO pin for changes
gpiomon --rising --falling gpiochip0 23

# Wave hand in front of sensor
# Should see events printed
```

If no events appear, double-check wiring and GPIO pin number in configuration.
```

---

## Service Management Documentation

### Pattern: Standard Service Management

```markdown
## Service Management

The module runs as a systemd service for reliable operation and automatic startup.

### Basic Commands

```bash
# Start the service
sudo systemctl start mario

# Stop the service
sudo systemctl stop mario

# Restart the service (apply config changes)
sudo systemctl restart mario

# View service status
sudo systemctl status mario

# Enable autostart on boot
sudo systemctl enable mario

# Disable autostart
sudo systemctl disable mario
```

### Viewing Logs

```bash
# View recent logs (last 50 lines)
journalctl -u mario -n 50

# Follow logs in real-time
journalctl -u mario -f

# View errors only
journalctl -u mario -p err

# View logs from today
journalctl -u mario --since today

# View logs from specific time
journalctl -u mario --since "2024-01-15 10:00:00"

# View logs with more detail
journalctl -u mario -o verbose
```

### Service Information

```bash
# Show detailed service properties
systemctl show mario

# Check if service is enabled (autostart)
systemctl is-enabled mario

# Check if service is currently active
systemctl is-active mario

# View service file location
systemctl cat mario
```

### Performance Monitoring

```bash
# Check CPU and memory usage
systemctl status mario
# Look for "Memory:" and CPU in output

# View detailed process information
ps aux | grep mario

# Monitor resource usage in real-time
top -p $(pgrep -f mario)
```

### Troubleshooting Service Issues

**Service won't start:**
```bash
# View failure reason
systemctl status mario -l

# Check for config errors
journalctl -u mario -n 20

# Validate service file
systemd-analyze verify /etc/systemd/system/mario.service
```

**Service crashes repeatedly:**
```bash
# View crash logs
journalctl -u mario -p err --since "1 hour ago"

# Check restart count
systemctl show mario | grep NRestarts

# Disable auto-restart temporarily for debugging
sudo systemctl edit mario
# Add:
[Service]
Restart=no
```

**Service uses too much CPU/memory:**
```bash
# Check resource limits
systemctl show mario | grep -E "CPU|Memory"

# Add resource limits in service file
sudo systemctl edit mario
# Add:
[Service]
CPUQuota=50%
MemoryMax=100M
```

### Advanced Service Management

**Reloading systemd after changes:**
```bash
# After editing service files
sudo systemctl daemon-reload
```

**Masking a service (prevent it from starting):**
```bash
sudo systemctl mask mario    # Prevent starting
sudo systemctl unmask mario  # Allow starting again
```

**Service dependency tree:**
```bash
systemctl list-dependencies mario
```
```

---

## Additional Pattern Examples

For more examples, see:
- **Main README:** `/README.md` - Project overview structure
- **Mario Module:** `motion-detection/mario/README.md` - Complete module documentation
- **ha-mqtt Module:** `iot/ha-mqtt/README.md` - Integration module patterns
- **Management API:** `system/management-api/docs/API.md` - API documentation reference

## Documentation Template

For a blank module README template, see: `module-readme-template.md`
