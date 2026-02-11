# System Info Module

**System monitoring with MQTT integration for Home Assistant**

Collects and publishes Raspberry Pi system metrics to Home Assistant via MQTT every 5 minutes.

## Features

- **System Uptime** - Track how long the system has been running (hours)
- **CPU Temperature** - Monitor processor temperature (°C)
- **Memory Usage** - Track RAM utilization (%)
- **Disk Usage** - Monitor root filesystem space (%)
- **CPU Usage** - Track processor load (%)
- **Configurable Intervals** - Adjust publish frequency
- **MQTT Integration** - Optional Home Assistant integration via ha-mqtt module
- **Standalone Operation** - Works without MQTT broker
- **Systemd Service** - Automatic startup and management
- **Structured Logging** - Rotating logs with configurable levels

## Hardware Requirements

- Raspberry Pi Zero W (or compatible)
- Network connectivity for MQTT (optional)

## Dependencies

### Runtime Dependencies

- `python3-psutil` - System metrics collection
- `mosquitto-clients` - MQTT publishing (optional, via ha-mqtt module)
- `jq` - JSON processing (optional, via ha-mqtt module)

### Module Dependencies

- `iot/ha-mqtt` - MQTT integration (optional)

## Installation

### Quick Install

```bash
# From repository root
sudo system/system-info/setup.sh install
```

### Manual Steps

```bash
# 1. Install dependencies
sudo apt-get update
sudo apt-get install -y python3-psutil

# 2. Copy Python script
sudo cp system-info.py /usr/local/bin/system-info.py
sudo chmod 755 /usr/local/bin/system-info.py

# 3. Create configuration directory
sudo mkdir -p /etc/luigi/system/system-info

# 4. Copy configuration file
sudo cp system-info.conf.example /etc/luigi/system/system-info/system-info.conf
sudo chmod 644 /etc/luigi/system/system-info/system-info.conf

# 5. Install systemd service
sudo cp system-info.service /etc/systemd/system/system-info.service
sudo chmod 644 /etc/systemd/system/system-info.service
sudo systemctl daemon-reload

# 6. Enable and start service
sudo systemctl enable system-info.service
sudo systemctl start system-info.service

# 7. (Optional) Setup MQTT integration
# If ha-mqtt module is installed:
sudo cp *_descriptor.json /etc/luigi/iot/ha-mqtt/sensors.d/
sudo /usr/local/bin/luigi-discover
```

## Configuration

Configuration file: `/etc/luigi/system/system-info/system-info.conf`

```ini
[Logging]
log_file = /var/log/luigi/system-info.log
log_level = INFO
log_max_bytes = 10485760
log_backup_count = 5

[Timing]
# Publish interval in seconds (default: 300 = 5 minutes)
publish_interval_seconds = 300

# Main loop check interval (default: 60 = 1 minute)
main_loop_sleep_seconds = 60
```

### Configuration Options

| Section | Option | Default | Description |
|---------|--------|---------|-------------|
| Logging | `log_file` | `/var/log/luigi/system-info.log` | Log file location |
| Logging | `log_level` | `INFO` | Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL) |
| Logging | `log_max_bytes` | `10485760` | Maximum log file size before rotation (10MB) |
| Logging | `log_backup_count` | `5` | Number of rotated log files to keep |
| Timing | `publish_interval_seconds` | `300` | Interval between metric collection/publishing (5 minutes) |
| Timing | `main_loop_sleep_seconds` | `60` | Sleep interval for main loop check (1 minute) |

### Adjusting Publish Interval

To change the publish interval from 5 minutes to 10 minutes:

```bash
sudo nano /etc/luigi/system/system-info/system-info.conf
# Change: publish_interval_seconds = 600
sudo systemctl restart system-info
```

## MQTT Integration

The system-info module integrates with Home Assistant via the Luigi ha-mqtt module using zero-coupling sensor descriptors.

### Sensor Descriptors

Five sensors are published to Home Assistant:

| Sensor ID | Name | Unit | Device Class | Icon |
|-----------|------|------|--------------|------|
| `system_uptime` | System Uptime | h | - | `mdi:clock-outline` |
| `system_cpu_temp` | CPU Temperature | °C | temperature | `mdi:chip` |
| `system_memory_usage` | Memory Usage | % | - | `mdi:memory` |
| `system_disk_usage` | Disk Usage | % | - | `mdi:harddisk` |
| `system_cpu_usage` | CPU Usage | % | - | `mdi:cpu-64-bit` |

### MQTT Topics

```
homeassistant/sensor/luigi_{hostname}_system_uptime/config
homeassistant/sensor/luigi_{hostname}_system_uptime/state

homeassistant/sensor/luigi_{hostname}_system_cpu_temp/config
homeassistant/sensor/luigi_{hostname}_system_cpu_temp/state

... (similar for all 5 sensors)
```

### Home Assistant Dashboard

After installation, sensors will appear in Home Assistant under the Luigi device. Example dashboard card:

```yaml
type: entities
title: System Monitor
entities:
  - entity: sensor.luigi_raspberrypi_system_uptime
  - entity: sensor.luigi_raspberrypi_system_cpu_temp
  - entity: sensor.luigi_raspberrypi_system_memory_usage
  - entity: sensor.luigi_raspberrypi_system_disk_usage
  - entity: sensor.luigi_raspberrypi_system_cpu_usage
```

## Service Management

### Start/Stop/Restart

```bash
# Start service
sudo systemctl start system-info

# Stop service
sudo systemctl stop system-info

# Restart service
sudo systemctl restart system-info

# Check status
sudo systemctl status system-info
```

### Enable/Disable Auto-start

```bash
# Enable auto-start on boot
sudo systemctl enable system-info

# Disable auto-start
sudo systemctl disable system-info
```

### View Logs

```bash
# View service logs (journalctl)
sudo journalctl -u system-info -f

# View log file
sudo tail -f /var/log/luigi/system-info.log

# View recent errors
sudo journalctl -u system-info -p err
```

## Metrics Collected

### System Uptime

- **Source**: `/proc/uptime`
- **Unit**: Hours (decimal)
- **State Class**: `total_increasing`
- **Example**: `24.5` (system running for 24.5 hours)

### CPU Temperature

- **Source**: `vcgencmd measure_temp` (fallback to `/sys/class/thermal/thermal_zone0/temp`)
- **Unit**: Celsius (°C)
- **Device Class**: `temperature`
- **Example**: `45.2` (CPU temperature is 45.2°C)

### Memory Usage

- **Source**: `psutil.virtual_memory()`
- **Unit**: Percentage (%)
- **State Class**: `measurement`
- **Example**: `35.8` (35.8% of RAM in use)

### Disk Usage

- **Source**: `psutil.disk_usage('/')`
- **Unit**: Percentage (%)
- **State Class**: `measurement`
- **Example**: `42.1` (42.1% of root filesystem in use)

### CPU Usage

- **Source**: `psutil.cpu_percent(interval=1)`
- **Unit**: Percentage (%)
- **State Class**: `measurement`
- **Example**: `12.5` (CPU at 12.5% load)

## Troubleshooting

### Service won't start

```bash
# Check service status
sudo systemctl status system-info

# View recent logs
sudo journalctl -u system-info -n 50

# Test Python script manually
sudo python3 /usr/local/bin/system-info.py
```

### MQTT not working

```bash
# Check if ha-mqtt is installed
which luigi-publish

# Test MQTT publishing manually
sudo /usr/local/bin/luigi-publish --sensor system_uptime --value 1.0 --unit h

# Check MQTT broker connectivity
sudo /usr/local/bin/luigi-mqtt-status
```

### Metrics not updating

1. Check publish interval in configuration
2. Verify service is running: `sudo systemctl status system-info`
3. Check logs for errors: `sudo journalctl -u system-info -f`
4. Verify MQTT broker is accessible (if using MQTT)

### High CPU usage reading

The CPU usage metric measures load over a 1-second interval. Brief spikes are normal. For persistent high usage:

1. Check running processes: `top` or `htop`
2. Review systemd services: `systemctl list-units --type=service --state=running`
3. Check for I/O wait: `iostat -x 1`

## Uninstallation

```bash
# From repository root
sudo system/system-info/setup.sh uninstall
```

This will:
1. Stop and disable the service
2. Remove service file and Python script
3. Remove MQTT sensor descriptors
4. Prompt for configuration/log removal

## Module Information

- **Category**: system
- **Module Path**: `system/system-info`
- **Dependencies**: `iot/ha-mqtt` (optional)
- **Service Name**: `system-info.service`
- **Configuration**: `/etc/luigi/system/system-info/system-info.conf`
- **Log File**: `/var/log/luigi/system-info.log`

## Development

### Testing

```bash
# Validate Python syntax
python3 -m py_compile system-info.py

# Validate shell script
shellcheck setup.sh

# Run manually (for testing)
sudo python3 system-info.py
```

### Standalone Mode

The module works without MQTT integration:

```bash
# Run without ha-mqtt installed
sudo python3 /usr/local/bin/system-info.py

# Metrics will be logged but not published to MQTT
```

## Related Modules

- **iot/ha-mqtt** - MQTT integration for Home Assistant
- **system/optimization** - System performance optimization

## License

MIT License - See repository root for details

## Author

Luigi Project - https://github.com/pkathmann88/luigi
