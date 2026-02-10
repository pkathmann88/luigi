# Luigi MQTT Integration Guide

**Comprehensive guide for integrating Luigi modules with Home Assistant via MQTT**

---

## Table of Contents

1. [Generic Interface Pattern](#generic-interface-pattern)
2. [Integration Walkthrough](#integration-walkthrough)
3. [Sensor Types & Examples](#sensor-types--examples)
4. [Descriptor Field Reference](#descriptor-field-reference)
5. [Best Practices](#best-practices)
6. [Advanced Scenarios](#advanced-scenarios)

---

## Generic Interface Pattern

### The Problem

Traditional MQTT integration requires sensor-specific code:

```python
# Old approach - sensor-specific functions
def publish_temperature(value):
    mqtt.publish("sensors/temperature", value)

def publish_motion(state):
    mqtt.publish("sensors/motion", "ON" if state else "OFF")

def publish_humidity(value):
    mqtt.publish("sensors/humidity", value)
```

**Issues:**
- New sensor types require code changes
- Tight coupling between sensors and MQTT module
- Difficult to test and maintain
- No standardization

### The Solution

Luigi uses a **generic interface** with parameters:

```bash
# New approach - one command for everything
luigi-publish --sensor temperature --value 23.5
luigi-publish --sensor motion --value ON --binary
luigi-publish --sensor humidity --value 65
```

**Benefits:**
- ✅ Zero coupling - no code changes for new sensors
- ✅ Consistent interface across all modules
- ✅ Easy to test (just validate parameters)
- ✅ Self-documenting (parameters describe data)

### How It Works

```
┌─────────────────────┐
│   Your Module       │
│                     │
│ Reads sensor data   │
└──────────┬──────────┘
           │
           │ Calls generic command
           │
           ▼
    luigi-publish --sensor X --value Y
           │
           │ Generic parameters
           │
┌──────────▼──────────┐
│   ha-mqtt Bridge    │
│                     │
│ 1. Validates params │
│ 2. Builds topic     │
│ 3. Publishes MQTT   │
└──────────┬──────────┘
           │
           ▼
    MQTT Broker → Home Assistant
```

**Key Insight:** Parameters carry all necessary information. No sensor-specific logic needed.

---

## Integration Walkthrough

### Complete Example: Temperature Sensor

This walkthrough shows every step to integrate a DHT22 temperature sensor.

#### Step 1: Understand Your Sensor

**Sensor Details:**
- Type: DHT22 temperature/humidity sensor
- Values: Temperature (float), Humidity (int)
- Update Frequency: Every 5 minutes
- Module Location: `sensors/dht22/`

#### Step 2: Create Sensor Descriptors

**Temperature Descriptor:** `temp_descriptor.json`
```json
{
  "sensor_id": "dht22_temperature",
  "name": "DHT22 Temperature",
  "device_class": "temperature",
  "unit_of_measurement": "°C",
  "icon": "mdi:thermometer",
  "state_class": "measurement",
  "module": "sensors/dht22"
}
```

**Humidity Descriptor:** `humidity_descriptor.json`
```json
{
  "sensor_id": "dht22_humidity",
  "name": "DHT22 Humidity",
  "device_class": "humidity",
  "unit_of_measurement": "%",
  "icon": "mdi:water-percent",
  "state_class": "measurement",
  "module": "sensors/dht22"
}
```

**Design Decisions:**
- `sensor_id`: Must be unique, alphanumeric + underscore/hyphen
- `device_class`: Use Home Assistant standard classes
- `state_class`: "measurement" for values that fluctuate
- `module`: Identifies source for troubleshooting

#### Step 3: Install Descriptors

```bash
# Copy to sensors.d directory
sudo cp temp_descriptor.json /etc/luigi/iot/ha-mqtt/sensors.d/
sudo cp humidity_descriptor.json /etc/luigi/iot/ha-mqtt/sensors.d/

# Verify
ls /etc/luigi/iot/ha-mqtt/sensors.d/
```

#### Step 4: Register with Home Assistant

```bash
# Run discovery (one-time setup)
sudo luigi-discover
```

**Expected Output:**
```
=========================================
Luigi Sensor Discovery
=========================================

Scanning: /etc/luigi/iot/ha-mqtt/sensors.d/
Broker: homeassistant.local:1883

Found 2 descriptor(s)

✓ DHT22 Temperature (sensor)
✓ DHT22 Humidity (sensor)

=========================================
Summary
=========================================
Total descriptors: 2
Successfully registered: 2
Failed: 0

✓ All sensors registered successfully
```

**What Happened:**
1. luigi-discover scanned `sensors.d/`
2. Generated MQTT Discovery payloads
3. Published to Home Assistant discovery topics
4. Messages retained on broker (persist across restarts)

#### Step 5: Verify in Home Assistant

1. Navigate to: **Configuration → Devices & Services**
2. Find device: **Luigi raspberrypi** (or your hostname)
3. Should see 2 entities:
   - `sensor.dht22_temperature`
   - `sensor.dht22_humidity`

#### Step 6: Implement Module Code

**Reading Sensor (Python):** `sensors/dht22/read_sensor.py`
```python
#!/usr/bin/env python3
"""
DHT22 Temperature/Humidity Sensor Reader
Publishes to Home Assistant via luigi-publish
"""

import Adafruit_DHT
import subprocess
import time
import sys

# Sensor configuration
SENSOR_TYPE = Adafruit_DHT.DHT22
GPIO_PIN = 4

def read_sensor():
    """Read temperature and humidity from DHT22"""
    humidity, temperature = Adafruit_DHT.read_retry(SENSOR_TYPE, GPIO_PIN)
    
    if humidity is not None and temperature is not None:
        return temperature, humidity
    else:
        return None, None

def publish_temperature(temp):
    """Publish temperature to Home Assistant"""
    try:
        subprocess.run([
            'luigi-publish',
            '--sensor', 'dht22_temperature',
            '--value', str(temp)
        ], check=True, capture_output=True, text=True)
        print(f"Published temperature: {temp}°C")
    except subprocess.CalledProcessError as e:
        print(f"Error publishing temperature: {e.stderr}", file=sys.stderr)
        return False
    return True

def publish_humidity(humidity):
    """Publish humidity to Home Assistant"""
    try:
        subprocess.run([
            'luigi-publish',
            '--sensor', 'dht22_humidity',
            '--value', str(humidity)
        ], check=True, capture_output=True, text=True)
        print(f"Published humidity: {humidity}%")
    except subprocess.CalledProcessError as e:
        print(f"Error publishing humidity: {e.stderr}", file=sys.stderr)
        return False
    return True

def main():
    """Main loop - read and publish sensor data"""
    while True:
        # Read sensor
        temp, humidity = read_sensor()
        
        if temp is not None and humidity is not None:
            # Publish to Home Assistant
            publish_temperature(round(temp, 1))
            publish_humidity(round(humidity, 0))
        else:
            print("Failed to read sensor", file=sys.stderr)
        
        # Wait 5 minutes before next reading
        time.sleep(300)

if __name__ == '__main__':
    main()
```

**Alternative (Shell Script):** `sensors/dht22/read_sensor.sh`
```bash
#!/bin/bash
#
# DHT22 Temperature/Humidity Sensor Reader
# Publishes to Home Assistant via luigi-publish
#

# Read sensor (assumes python script returns "temp,humidity")
read_dht22() {
    python3 -c "
import Adafruit_DHT
humidity, temp = Adafruit_DHT.read_retry(Adafruit_DHT.DHT22, 4)
if humidity is not None and temp is not None:
    print(f'{temp:.1f},{humidity:.0f}')
"
}

# Read sensor
sensor_data=$(read_dht22)

if [ -z "$sensor_data" ]; then
    echo "Error: Failed to read sensor" >&2
    exit 1
fi

# Parse values
temp=$(echo "$sensor_data" | cut -d',' -f1)
humidity=$(echo "$sensor_data" | cut -d',' -f2)

# Publish to Home Assistant
luigi-publish --sensor dht22_temperature --value "$temp"
luigi-publish --sensor dht22_humidity --value "$humidity"

echo "Published: Temperature=${temp}°C, Humidity=${humidity}%"
```

#### Step 7: Automate with Cron

```bash
# Edit crontab
crontab -e

# Add entry (every 5 minutes)
*/5 * * * * /usr/local/bin/sensors/dht22/read_sensor.sh >> /var/log/dht22.log 2>&1
```

#### Step 8: Verify Data Flow

**Check Home Assistant:**
1. Navigate to: **Developer Tools → States**
2. Find: `sensor.dht22_temperature`
3. Should see current value updating every 5 minutes

**Check Logs:**
```bash
tail -f /var/log/dht22.log
```

**Test Manually:**
```bash
# Run script once
/usr/local/bin/sensors/dht22/read_sensor.sh
```

#### Step 9: Create Home Assistant Dashboard

```yaml
# configuration.yaml or dashboard
type: entities
entities:
  - entity: sensor.dht22_temperature
    name: Temperature
  - entity: sensor.dht22_humidity
    name: Humidity
```

**Result:** Temperature and humidity cards appear in dashboard.

#### Step 10: Add Automations (Optional)

**Temperature Alert:**
```yaml
automation:
  - alias: "High Temperature Alert"
    trigger:
      - platform: numeric_state
        entity_id: sensor.dht22_temperature
        above: 30
    action:
      - service: notify.mobile_app
        data:
          message: "Temperature is high: {{ states('sensor.dht22_temperature') }}°C"
```

---

## Sensor Types & Examples

### Numeric Sensors

For sensors with numeric values (temperature, humidity, light, etc.)

**Device Classes:**
- `temperature` - Temperature sensors
- `humidity` - Humidity sensors
- `illuminance` - Light sensors
- `pressure` - Pressure sensors
- `power` - Power consumption
- `voltage` - Voltage sensors
- `current` - Current sensors
- `battery` - Battery level
- `signal_strength` - WiFi/signal strength
- `pm25` - Air quality (PM2.5)

**Example: Light Sensor**
```json
{
  "sensor_id": "ambient_light",
  "name": "Ambient Light Level",
  "device_class": "illuminance",
  "unit_of_measurement": "lx",
  "icon": "mdi:brightness-6",
  "state_class": "measurement",
  "module": "sensors/light"
}
```

```bash
# Publish light level
luigi-publish --sensor ambient_light --value 450
```

**Example: Power Consumption**
```json
{
  "sensor_id": "power_consumption",
  "name": "Power Consumption",
  "device_class": "power",
  "unit_of_measurement": "W",
  "icon": "mdi:flash",
  "state_class": "measurement",
  "module": "sensors/power"
}
```

```bash
# Publish power usage
luigi-publish --sensor power_consumption --value 125.5
```

### Binary Sensors

For on/off, open/closed, detected/clear sensors

**Device Classes:**
- `motion` - Motion detectors (PIR sensors)
- `door` - Door sensors
- `window` - Window sensors
- `occupancy` - Room occupancy
- `opening` - Generic opening sensor
- `smoke` - Smoke detectors
- `moisture` - Water/moisture sensors
- `sound` - Sound detection
- `vibration` - Vibration detection
- `presence` - Presence detection

**Example: Motion Detector**
```json
{
  "sensor_id": "pir_motion",
  "name": "PIR Motion Sensor",
  "device_class": "motion",
  "icon": "mdi:motion-sensor",
  "module": "motion-detection/pir"
}
```

```bash
# Motion detected
luigi-publish --sensor pir_motion --value ON --binary

# Motion cleared
luigi-publish --sensor pir_motion --value OFF --binary
```

**Example: Door Sensor**
```json
{
  "sensor_id": "front_door",
  "name": "Front Door",
  "device_class": "door",
  "icon": "mdi:door",
  "module": "sensors/door"
}
```

```bash
# Door opened
luigi-publish --sensor front_door --value ON --binary

# Door closed
luigi-publish --sensor front_door --value OFF --binary
```

### System Monitoring

**CPU Temperature:**
```json
{
  "sensor_id": "cpu_temp",
  "name": "CPU Temperature",
  "device_class": "temperature",
  "unit_of_measurement": "°C",
  "icon": "mdi:chip",
  "state_class": "measurement",
  "module": "system/monitor"
}
```

```bash
# Get CPU temp
cpu_temp=$(vcgencmd measure_temp | grep -oP '\d+\.\d+')
luigi-publish --sensor cpu_temp --value "$cpu_temp"
```

**Memory Usage:**
```json
{
  "sensor_id": "memory_usage",
  "name": "Memory Usage",
  "unit_of_measurement": "%",
  "icon": "mdi:memory",
  "state_class": "measurement",
  "module": "system/monitor"
}
```

```bash
# Get memory usage percentage
mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
luigi-publish --sensor memory_usage --value "$mem_usage"
```

**Uptime:**
```json
{
  "sensor_id": "system_uptime",
  "name": "System Uptime",
  "unit_of_measurement": "hours",
  "icon": "mdi:clock-outline",
  "state_class": "total_increasing",
  "module": "system/monitor"
}
```

```bash
# Get uptime in hours
uptime_hours=$(awk '{print int($1/3600)}' /proc/uptime)
luigi-publish --sensor system_uptime --value "$uptime_hours"
```

---

## Descriptor Field Reference

### Required Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `sensor_id` | string | Unique identifier (alphanumeric + `_` `-`) | `"bedroom_temp"` |
| `name` | string | Human-readable name for Home Assistant | `"Bedroom Temperature"` |
| `module` | string | Source module identifier | `"sensors/dht22"` |

### Optional Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `device_class` | string | Home Assistant device class | `"temperature"` |
| `unit_of_measurement` | string | Unit symbol | `"°C"`, `"%"`, `"lx"` |
| `icon` | string | Material Design Icon | `"mdi:thermometer"` |
| `state_class` | string | How HA treats history | `"measurement"` |

### device_class Values

**Numeric Sensors:**
- `temperature` - Temperature (°C, °F, K)
- `humidity` - Humidity (%)
- `illuminance` - Light level (lx)
- `pressure` - Pressure (hPa, mbar)
- `power` - Power (W, kW)
- `energy` - Energy (Wh, kWh)
- `voltage` - Voltage (V)
- `current` - Current (A)
- `battery` - Battery level (%)
- `signal_strength` - Signal (dBm, %)
- `pm25` - Particulate matter
- `pm10` - Particulate matter

**Binary Sensors:**
- `motion` - Motion detection
- `door` - Door state
- `window` - Window state
- `opening` - Generic opening
- `occupancy` - Occupancy
- `presence` - Presence
- `smoke` - Smoke detection
- `moisture` - Moisture/water
- `sound` - Sound detection
- `vibration` - Vibration
- `light` - Light presence

### state_class Values

| Value | Description | Use Case |
|-------|-------------|----------|
| `measurement` | Instantaneous value | Temperature, humidity, light |
| `total` | Cumulative value (can reset) | Water usage, daily energy |
| `total_increasing` | Ever-increasing value | Electricity meter, uptime |

**Examples:**
```json
// Measurement (value goes up and down)
"state_class": "measurement"
// Temperature: 20°C → 25°C → 18°C

// Total (cumulative, can reset)
"state_class": "total"
// Daily energy: 0 → 5.2 kWh → 0 (next day)

// Total Increasing (never decreases)
"state_class": "total_increasing"
// Lifetime energy: 1000 kWh → 1005 kWh → 1010 kWh
```

### Icon Selection

Browse icons at: https://materialdesignicons.com/

**Common Icons:**
- `mdi:thermometer` - Temperature
- `mdi:water-percent` - Humidity
- `mdi:brightness-6` - Light
- `mdi:motion-sensor` - Motion
- `mdi:door` - Door
- `mdi:gauge` - Pressure
- `mdi:flash` - Power/electricity
- `mdi:battery` - Battery
- `mdi:chip` - CPU/processor
- `mdi:memory` - RAM
- `mdi:harddisk` - Storage

---

## Best Practices

### Naming Conventions

**sensor_id:**
- Use lowercase
- Use underscores for spaces
- Include location or function
- Be specific

```
✓ Good: bedroom_temperature, front_door, cpu_temp
✗ Bad: temp1, sensor, data
```

**name:**
- Use Title Case
- Include location
- Be descriptive

```
✓ Good: "Bedroom Temperature", "Front Door Sensor"
✗ Bad: "Temp", "Sensor 1"
```

### Module Organization

**One Module = Multiple Descriptors:**
```
sensors/dht22/
├── dht22_temp.json       # Temperature descriptor
├── dht22_humidity.json   # Humidity descriptor
└── read_sensor.py        # Reads both sensors
```

**Separate Modules = Separate Descriptors:**
```
motion-detection/mario/
└── mario_motion.json     # Motion descriptor

sensors/light/
└── light_sensor.json     # Light descriptor
```

### Error Handling

**Always Check Return Codes:**
```python
result = subprocess.run(['luigi-publish', ...], capture_output=True)
if result.returncode != 0:
    logger.error(f"Failed to publish: {result.stderr}")
    # Take corrective action
```

**Use Try-Except:**
```python
try:
    subprocess.run(['luigi-publish', ...], check=True)
except subprocess.CalledProcessError as e:
    logger.error(f"Publish failed: {e}")
    # Implement retry logic or alert
```

### Value Formatting

**Round Floating Point:**
```python
# Don't: Too many decimals
luigi-publish --sensor temp --value 23.456789

# Do: Round appropriately
temp = round(23.456789, 1)  # 23.5
luigi-publish --sensor temp --value temp
```

**Validate Ranges:**
```python
# Ensure values are reasonable
if 0 <= humidity <= 100:
    luigi-publish --sensor humidity --value humidity
else:
    logger.warning(f"Invalid humidity: {humidity}")
```

### Update Frequency

**Guidelines:**
- **Motion sensors:** Immediate (event-driven)
- **Temperature:** 5-15 minutes
- **Humidity:** 5-15 minutes  
- **System stats:** 1-5 minutes
- **Light sensors:** 1-5 minutes
- **Power monitoring:** 10-60 seconds

**Why:** Balance responsiveness vs. MQTT load.

### Logging

**Log Publish Events:**
```python
import logging

logging.basicConfig(
    filename='/var/log/sensor.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

logger.info(f"Publishing: {sensor_id} = {value}")
```

**Monitor Logs:**
```bash
tail -f /var/log/sensor.log
```

---

## Advanced Scenarios

### Batching Multiple Sensors

For modules that read multiple sensors simultaneously:

```python
def publish_all_sensors():
    """Read and publish multiple sensors efficiently"""
    
    # Read all sensors
    temp, humidity, pressure = read_bme280()
    
    # Publish in sequence
    sensors = [
        ('bme280_temperature', temp),
        ('bme280_humidity', humidity),
        ('bme280_pressure', pressure)
    ]
    
    for sensor_id, value in sensors:
        luigi-publish --sensor sensor_id --value value
```

### Conditional Publishing

Only publish when value changes significantly:

```python
class SensorPublisher:
    def __init__(self, sensor_id, threshold=0.5):
        self.sensor_id = sensor_id
        self.last_value = None
        self.threshold = threshold
    
    def publish_if_changed(self, value):
        """Only publish if value changed significantly"""
        if self.last_value is None:
            # First reading, always publish
            self.publish(value)
            self.last_value = value
            return True
        
        # Check if change exceeds threshold
        if abs(value - self.last_value) >= self.threshold:
            self.publish(value)
            self.last_value = value
            return True
        
        return False  # No significant change
    
    def publish(self, value):
        subprocess.run([
            'luigi-publish',
            '--sensor', self.sensor_id,
            '--value', str(value)
        ], check=True)
```

### Retry Logic

Implement retry for unreliable networks:

```python
import time

def publish_with_retry(sensor_id, value, max_retries=3):
    """Publish with exponential backoff retry"""
    for attempt in range(max_retries):
        try:
            subprocess.run([
                'luigi-publish',
                '--sensor', sensor_id,
                '--value', str(value)
            ], check=True, timeout=10)
            return True
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            if attempt < max_retries - 1:
                wait_time = 2 ** attempt  # Exponential backoff
                logger.warning(f"Publish failed, retrying in {wait_time}s...")
                time.sleep(wait_time)
            else:
                logger.error(f"Publish failed after {max_retries} attempts")
                return False
```

### Multi-Attribute Publishing

Publish complex data with attributes:

```python
# Sensor descriptor
{
  "sensor_id": "system_status",
  "name": "System Status",
  "icon": "mdi:information",
  "module": "system/monitor"
}

# Publish with attributes
import json

attributes = {
    "cpu_temp": 45.2,
    "memory_usage": 35.8,
    "disk_usage": 67.3,
    "uptime_hours": 120
}

subprocess.run([
    'luigi-publish',
    '--sensor', 'system_status',
    '--value', 'online',
    '--attributes', json.dumps(attributes)
], check=True)
```

Result in Home Assistant:
```
State: online
Attributes:
  cpu_temp: 45.2
  memory_usage: 35.8
  disk_usage: 67.3
  uptime_hours: 120
```

---

## Troubleshooting Integration

### Descriptor Not Found

**Symptom:** `luigi-discover` reports "No sensor descriptors found"

**Solution:**
```bash
# Check directory exists
ls -la /etc/luigi/iot/ha-mqtt/sensors.d/

# Check file permissions
sudo chmod 644 /etc/luigi/iot/ha-mqtt/sensors.d/*.json

# Verify JSON files
ls /etc/luigi/iot/ha-mqtt/sensors.d/*.json
```

### Invalid JSON

**Symptom:** `luigi-discover` reports "Invalid JSON"

**Solution:**
```bash
# Validate JSON syntax
cat descriptor.json | jq .

# Common issues:
# - Missing comma
# - Trailing comma (invalid in JSON)
# - Unquoted strings
# - Single quotes (use double quotes)
```

### Sensor Not Updating

**Symptom:** Sensor appears in HA but value doesn't update

**Solution:**
1. **Test publish manually:**
   ```bash
   luigi-publish --sensor your_sensor --value test_value
   ```

2. **Check script execution:**
   ```bash
   # Add debug output
   echo "Publishing value: $value" >> /var/log/debug.log
   luigi-publish --sensor sensor_id --value "$value"
   ```

3. **Verify cron job running:**
   ```bash
   # Check cron logs
   grep CRON /var/log/syslog
   ```

4. **Check Home Assistant entity:**
   - Developer Tools → States
   - Find your sensor
   - Check "Last Updated" timestamp

---

## Summary

### Integration Checklist

- [ ] Create sensor descriptor JSON
- [ ] Install to `/etc/luigi/iot/ha-mqtt/sensors.d/`
- [ ] Run `sudo luigi-discover`
- [ ] Verify sensor appears in Home Assistant
- [ ] Implement module code with `luigi-publish`
- [ ] Test manually
- [ ] Automate (cron, systemd, etc.)
- [ ] Monitor logs
- [ ] Create Home Assistant dashboard
- [ ] Add automations (optional)

### Key Takeaways

1. **Generic interface = zero coupling**
2. **Parameters carry all information**
3. **Descriptors enable self-service registration**
4. **One command for all sensor types**
5. **MQTT Discovery eliminates manual HA config**

### Getting Help

- **Test connectivity:** `luigi-mqtt-status`
- **Check discovery:** `sudo luigi-discover --verbose`
- **View logs:** `tail -f /var/log/ha-mqtt.log`
- **Home Assistant logs:** Configuration → Logs
- **MQTT broker logs:** `docker logs homeassistant_mqtt`

---

**Document Version:** 1.0  
**Created:** 2026-02-10  
**Last Updated:** 2026-02-10
