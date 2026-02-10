# Example Sensor Descriptors for iot/ha-mqtt

This directory contains example sensor descriptor files that demonstrate the format and structure required for Home Assistant MQTT Discovery integration.

## Descriptor Format

Sensor descriptors are JSON files that define how Luigi sensors appear in Home Assistant. Each descriptor follows this structure:

```json
{
  "sensor_id": "unique_sensor_identifier",
  "name": "Human-Readable Sensor Name",
  "device_class": "home_assistant_device_class",
  "unit_of_measurement": "unit",
  "icon": "mdi:icon-name",
  "state_class": "measurement",
  "module": "source-module-name"
}
```

## Field Reference

### Required Fields

| Field | Description | Example |
|-------|-------------|---------|
| `sensor_id` | Unique identifier for the sensor. Must be alphanumeric with underscores/hyphens only. Used in MQTT topics. | `"mario_motion_sensor"` |
| `name` | Human-readable name displayed in Home Assistant | `"Mario Motion Detector"` |
| `module` | Name of the Luigi module that owns this sensor | `"motion-detection/mario"` |

### Optional Fields

| Field | Description | Example | Default |
|-------|-------------|---------|---------|
| `device_class` | Home Assistant device class. Affects icon and grouping. | `"temperature"`, `"motion"`, `"humidity"` | None |
| `unit_of_measurement` | Unit of measurement for sensor values | `"°C"`, `"%"`, `"lux"` | None |
| `icon` | Material Design icon to display | `"mdi:thermometer"` | Auto from device_class |
| `state_class` | How HA should treat state history | `"measurement"`, `"total"`, `"total_increasing"` | None |

## Device Classes

### Sensor (sensor)

Numerical sensors with continuous values:

- `temperature` - Temperature sensors (°C, °F, K)
- `humidity` - Humidity sensors (%)
- `illuminance` - Light sensors (lx)
- `pressure` - Pressure sensors (hPa, mbar)
- `power` - Power consumption (W)
- `energy` - Energy usage (kWh)
- `voltage` - Voltage (V)
- `current` - Current (A)
- `battery` - Battery level (%)

### Binary Sensor (binary_sensor)

On/off sensors:

- `motion` - Motion detectors
- `door` - Door sensors (open/closed)
- `window` - Window sensors (open/closed)
- `occupancy` - Occupancy detection
- `smoke` - Smoke detectors
- `moisture` - Moisture/leak sensors
- `light` - Light detection (on/off)
- `sound` - Sound detection

## Example Files

### Temperature Sensor

**File:** `example_temperature.json`

```json
{
  "sensor_id": "example_temperature",
  "name": "Example Temperature Sensor",
  "device_class": "temperature",
  "unit_of_measurement": "°C",
  "icon": "mdi:thermometer",
  "state_class": "measurement",
  "module": "example-module"
}
```

**Usage:**
```bash
luigi-publish --sensor example_temperature --value 23.5
```

### Humidity Sensor

**File:** `example_humidity.json`

```json
{
  "sensor_id": "example_humidity",
  "name": "Example Humidity Sensor",
  "device_class": "humidity",
  "unit_of_measurement": "%",
  "icon": "mdi:water-percent",
  "state_class": "measurement",
  "module": "example-module"
}
```

**Usage:**
```bash
luigi-publish --sensor example_humidity --value 65
```

### Motion Sensor (Binary)

**File:** `example_binary_sensor_motion.json`

```json
{
  "sensor_id": "example_motion",
  "name": "Example Motion Detector",
  "device_class": "motion",
  "icon": "mdi:motion-sensor",
  "module": "example-module"
}
```

**Usage:**
```bash
luigi-publish --sensor example_motion --value ON
luigi-publish --sensor example_motion --value OFF
```

## Creating Your Own Descriptors

### Step 1: Choose sensor_id

Pick a unique identifier:
- Use lowercase letters, numbers, underscores, hyphens
- Make it descriptive but concise
- Examples: `bedroom_temp`, `garage_door`, `cpu_temperature`

### Step 2: Select device_class

Choose the most appropriate device class from the lists above. This affects:
- Default icon in Home Assistant
- Grouping with similar sensors
- Compatible value types

### Step 3: Define metadata

Add name, unit, and icon:
- **name:** Descriptive label users will see
- **unit_of_measurement:** Include if sensor has units
- **icon:** Browse [Material Design Icons](https://materialdesignicons.com/)

### Step 4: Set state_class (optional)

For sensors that should show in graphs and statistics:
- `measurement` - Current value that can go up or down (temperature, humidity)
- `total` - Cumulative value (can reset)
- `total_increasing` - Ever-increasing cumulative value (energy usage)

### Step 5: Save descriptor

```bash
sudo nano /etc/luigi/iot/ha-mqtt/sensors.d/YOUR_SENSOR_ID.json
```

### Step 6: Register with Home Assistant

```bash
sudo luigi-discover
```

## Descriptor Validation

Valid descriptors must:
- ✓ Be valid JSON format
- ✓ Have required fields: sensor_id, name, module
- ✓ Use alphanumeric characters in sensor_id (plus `_` and `-`)
- ✓ Not have path traversal characters (`..`, `/`, `\`)
- ✓ Have device_class from supported list (if specified)
- ✓ Have matching file name and sensor_id (recommended)

## Deployment

### Development/Testing

Copy examples to test directory:
```bash
sudo mkdir -p /etc/luigi/iot/ha-mqtt/sensors.d/
sudo cp examples/sensors.d/*.json /etc/luigi/iot/ha-mqtt/sensors.d/
```

### Production

Create descriptors as part of module installation:
```bash
# In your module's setup.sh
sudo cp descriptors/my_sensor.json /etc/luigi/iot/ha-mqtt/sensors.d/
sudo luigi-discover
```

## Troubleshooting

### Descriptor Not Recognized

1. Check JSON syntax:
   ```bash
   cat /etc/luigi/iot/ha-mqtt/sensors.d/my_sensor.json | jq .
   ```

2. Verify required fields present
3. Check sensor_id format (alphanumeric, underscore, hyphen only)
4. Run discovery manually:
   ```bash
   sudo luigi-discover
   ```

### Sensor Not Appearing in Home Assistant

1. Check MQTT connection:
   ```bash
   luigi-mqtt-status
   ```

2. Verify discovery message published:
   ```bash
   mosquitto_sub -h BROKER -t "homeassistant/#" -v
   ```

3. Check Home Assistant MQTT integration enabled
4. Review Home Assistant logs

### Wrong Icon or Metadata

1. Verify descriptor fields correct
2. Re-run discovery with --force:
   ```bash
   sudo luigi-discover --force
   ```

3. Restart Home Assistant if changes not visible

## Best Practices

1. **Naming Convention:** Use clear, descriptive sensor_ids
2. **File Names:** Match descriptor filename to sensor_id
3. **Documentation:** Comment complex sensors in module README
4. **Validation:** Test descriptors before deploying to production
5. **Cleanup:** Remove descriptors when uninstalling modules

## Integration Examples

### Motion Detection Module (Mario)

```json
{
  "sensor_id": "mario_motion_detector",
  "name": "Mario Motion Detector",
  "device_class": "motion",
  "icon": "mdi:mario",
  "module": "motion-detection/mario"
}
```

### Temperature Monitor Module

```json
{
  "sensor_id": "cpu_temperature",
  "name": "CPU Temperature",
  "device_class": "temperature",
  "unit_of_measurement": "°C",
  "icon": "mdi:chip",
  "state_class": "measurement",
  "module": "sensors/system-monitor"
}
```

### Door Sensor Module

```json
{
  "sensor_id": "front_door",
  "name": "Front Door Sensor",
  "device_class": "door",
  "icon": "mdi:door",
  "module": "sensors/door-monitor"
}
```

## References

- **Home Assistant MQTT Discovery:** https://www.home-assistant.io/integrations/mqtt/#mqtt-discovery
- **Device Classes:** https://www.home-assistant.io/integrations/sensor/#device-class
- **Binary Sensor Classes:** https://www.home-assistant.io/integrations/binary_sensor/#device-class
- **Material Design Icons:** https://materialdesignicons.com/

---

**Created:** 2026-02-10  
**Part of:** Phase 1 Testing Strategy Implementation
