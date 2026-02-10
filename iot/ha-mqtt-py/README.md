# Home Assistant MQTT Integration (Python Edition)

**Module:** iot/ha-mqtt-py  
**Category:** IoT Integration  
**Status:** Production Ready  
**Version:** 1.0.0  
**Language:** Python 3

Connect Luigi modules to Home Assistant via MQTT for centralized monitoring, automation, and dashboards using a clean Python architecture.

---

## Contents

```
iot/ha-mqtt-py/
├── README.md                      # This file
├── DESIGN_ANALYSIS.md             # Design documentation
├── IMPLEMENTATION_PLAN.md         # Implementation phases
├── ha-mqtt-py.py                  # Main Python application
├── ha-mqtt-py.service             # systemd service unit
├── ha-mqtt-py.conf.example        # Configuration template
└── setup.sh                       # Installation script
```

---

## Overview

The ha-mqtt-py module provides a **Python-based MQTT bridge** between Luigi modules and Home Assistant. Unlike the shell-script-based iot/ha-mqtt module, this implementation follows the modern Luigi Python architecture pattern (similar to motion-detection/mario), providing:

- **Object-Oriented Design:** Clean class architecture for maintainability
- **Robust Error Handling:** Comprehensive exception handling and logging
- **Configuration Management:** INI-style config files with fallback defaults
- **Automatic Reconnection:** Network resilience with exponential backoff
- **Mock Mode Support:** Development without MQTT broker
- **Graceful Shutdown:** Signal handlers for clean service termination

### What It Does

- **Maintains MQTT Connection:** Persistent connection to Home Assistant mosquitto broker
- **Publishes Sensor Data:** API for Luigi modules to publish sensor values
- **Auto-Registration:** Home Assistant MQTT Discovery for automatic sensor setup
- **Connection Monitoring:** Availability tracking and diagnostics
- **Structured Logging:** Rotating logs with configurable levels

### Why It Exists

- **Modern Architecture:** Follows Luigi's Python best practices
- **Better Maintainability:** OOP design easier to extend and debug
- **Error Resilience:** Comprehensive error handling prevents crashes
- **Development Friendly:** Mock mode enables testing without infrastructure
- **Integration Pattern:** Can be imported as library or run as standalone service

---

## Features

### Core Features

✅ **MQTT Client Management**
- Persistent broker connection with automatic reconnection
- Support for authentication (username/password)
- TLS encryption support for secure connections
- Configurable QoS levels and keepalive

✅ **Home Assistant Discovery**
- Automatic sensor registration via MQTT Discovery protocol
- Support for sensor types: sensor, binary_sensor
- Device class support (temperature, humidity, motion, etc.)
- Unique IDs and device grouping

✅ **Configuration**
- INI-style config file at `/etc/luigi/iot/ha-mqtt-py/ha-mqtt-py.conf`
- Variable substitution ({HOSTNAME})
- Sensible defaults for all settings
- Example configurations for common scenarios

✅ **Logging**
- Rotating log files (10MB max, 5 backups)
- Console and file output
- Configurable log levels (DEBUG, INFO, WARNING, ERROR)
- Sanitized output (no credential leaks)

✅ **Service Management**
- systemd integration with auto-restart
- Graceful shutdown via signals (SIGTERM/SIGINT)
- Security hardening (PrivateTmp, NoNewPrivileges, ProtectSystem)
- Availability status publishing

✅ **Development Support**
- Mock MQTT mode for testing without broker
- Comprehensive error messages
- Syntax validation support

---

## Hardware Requirements

**Raspberry Pi:**
- Raspberry Pi Zero W (or any model with network)
- Network connectivity (WiFi or Ethernet)

**Home Assistant:**
- Home Assistant instance (any version with MQTT integration)
- Mosquitto MQTT broker (built-in or addon)
- Network accessible from Raspberry Pi

**No GPIO Required:** This is a software-only, network-based module.

---

## Dependencies

**Runtime Dependencies:**
- `python3` (pre-installed on Raspberry Pi OS)
- `python3-paho-mqtt` (MQTT client library)

**Installation:**
```bash
# Installed automatically by setup.sh
sudo apt-get install python3-paho-mqtt
```

---

## Installation

### Automated Installation (Recommended)

```bash
# Navigate to module directory
cd /path/to/luigi/iot/ha-mqtt-py

# Install module (requires root for system integration)
sudo ./setup.sh install
```

The setup script will:
1. Install Python dependencies (python3-paho-mqtt)
2. Create configuration directory
3. Deploy configuration files
4. Install Python application
5. Install systemd service
6. Enable and start service

### Manual Installation

If you prefer manual installation:

```bash
# 1. Install dependencies
sudo apt-get update
sudo apt-get install -y python3-paho-mqtt

# 2. Create configuration directory
sudo mkdir -p /etc/luigi/iot/ha-mqtt-py

# 3. Copy configuration
sudo cp ha-mqtt-py.conf.example /etc/luigi/iot/ha-mqtt-py/ha-mqtt-py.conf
sudo chmod 600 /etc/luigi/iot/ha-mqtt-py/ha-mqtt-py.conf

# 4. Copy Python script
sudo cp ha-mqtt-py.py /usr/local/bin/
sudo chmod 755 /usr/local/bin/ha-mqtt-py.py

# 5. Install service
sudo cp ha-mqtt-py.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable ha-mqtt-py
sudo systemctl start ha-mqtt-py
```

---

## Configuration

### Configuration File

**Location:** `/etc/luigi/iot/ha-mqtt-py/ha-mqtt-py.conf`

**Format:** INI-style with sections

**Permissions:** `600` (readable only by owner) for security

### Configuration Sections

#### [Broker] - MQTT Broker Settings

```ini
[Broker]
HOST=localhost                    # MQTT broker hostname or IP
PORT=1883                         # MQTT port (1883=plain, 8883=TLS)
TLS_ENABLED=no                    # Enable TLS encryption (yes/no)
# TLS_CA_CERT=/path/to/ca.crt    # CA certificate for TLS
# TLS_CERT=/path/to/client.crt   # Client certificate for TLS
# TLS_KEY=/path/to/client.key    # Client key for TLS
```

#### [Authentication] - Broker Authentication

```ini
[Authentication]
USERNAME=                         # MQTT username (empty = anonymous)
PASSWORD=                         # MQTT password
```

#### [Client] - MQTT Client Settings

```ini
[Client]
CLIENT_ID=luigi-{HOSTNAME}        # Client ID ({HOSTNAME} auto-replaced)
KEEPALIVE=60                      # Keepalive interval in seconds
QOS=1                             # Quality of Service (0, 1, or 2)
RECONNECT_DELAY=5                 # Delay between reconnect attempts
```

#### [Topics] - MQTT Topic Structure

```ini
[Topics]
TOPIC_PREFIX=homeassistant        # HA discovery topic prefix
STATE_TOPIC=luigi/{HOSTNAME}      # Base topic for sensor states
AVAILABILITY_TOPIC=luigi/{HOSTNAME}/availability  # Availability status
```

#### [Discovery] - Home Assistant Discovery

```ini
[Discovery]
DEVICE_NAME=Luigi-{HOSTNAME}      # Device name in Home Assistant
DEVICE_MANUFACTURER=Luigi Project # Manufacturer shown in HA
DEVICE_MODEL=Raspberry Pi Zero W  # Model shown in HA
```

#### [Logging] - Logging Configuration

```ini
[Logging]
LOG_FILE=/var/log/ha-mqtt-py.log # Log file location
LOG_LEVEL=INFO                    # Log level (DEBUG/INFO/WARNING/ERROR)
LOG_MAX_BYTES=10485760            # Max log file size (10MB)
LOG_BACKUP_COUNT=5                # Number of rotated log backups
```

### Common Configuration Scenarios

**Scenario 1: Local Home Assistant (Default)**
```ini
[Broker]
HOST=homeassistant.local
PORT=1883
```

**Scenario 2: Remote HA with Authentication**
```ini
[Broker]
HOST=192.168.1.100
PORT=1883

[Authentication]
USERNAME=luigi
PASSWORD=your_secure_password
```

**Scenario 3: Secure TLS Connection**
```ini
[Broker]
HOST=homeassistant.example.com
PORT=8883
TLS_ENABLED=yes
TLS_CA_CERT=/etc/ssl/certs/ca.crt

[Authentication]
USERNAME=luigi
PASSWORD=your_secure_password
```

---

## Usage

### Service Management

```bash
# Start service
sudo systemctl start ha-mqtt-py

# Stop service
sudo systemctl stop ha-mqtt-py

# Restart service
sudo systemctl restart ha-mqtt-py

# Check status
sudo systemctl status ha-mqtt-py

# Enable auto-start on boot
sudo systemctl enable ha-mqtt-py

# Disable auto-start
sudo systemctl disable ha-mqtt-py

# View real-time logs
sudo journalctl -u ha-mqtt-py -f

# View recent logs
tail -f /var/log/ha-mqtt-py.log
```

### Manual Operation (For Testing)

```bash
# Run interactively (Ctrl+C to stop)
python3 /usr/local/bin/ha-mqtt-py.py

# Run in mock mode (no broker required)
# Automatically enabled if paho-mqtt not available
MOCK_MODE=1 python3 ha-mqtt-py.py
```

### Module Status Check

```bash
# Check installation and service status
./setup.sh status
```

---

## How It Works

### Application Lifecycle

1. **Startup:**
   - Load configuration from `/etc/luigi/iot/ha-mqtt-py/ha-mqtt-py.conf` or use defaults
   - Initialize logging (console + rotating file)
   - Register signal handlers (SIGTERM, SIGINT)
   - Create MQTT client with authentication/TLS if configured

2. **Connection:**
   - Connect to MQTT broker
   - Publish online status to availability topic
   - Start background network loop for async operations

3. **Main Loop:**
   - Monitor connection status
   - Attempt reconnection on disconnect
   - Sleep between status checks (10 second intervals)
   - Handle signals for graceful shutdown

4. **Shutdown:**
   - Publish offline status to availability topic
   - Disconnect MQTT client gracefully
   - Stop network loop
   - Cleanup and exit

### Class Architecture

```
Config
├── Load configuration from INI file
├── Provide defaults for all settings
└── Variable substitution ({HOSTNAME})

MQTTClientManager
├── paho.mqtt.client wrapper
├── Connection management
├── Auto-reconnection logic
├── Publish/subscribe methods
└── Connection callbacks

DiscoveryManager
├── Generate HA Discovery JSON payloads
├── Register sensors (sensor, binary_sensor)
├── Support device classes and units
└── Track registered sensors

HAMQTTApplication
├── Main application orchestration
├── Initialize all components
├── Run main event loop
└── Handle graceful shutdown

MockMQTTClient
├── Mock paho.mqtt.client for development
└── Enabled when paho-mqtt unavailable
```

---

## Integration Examples

### Example 1: Integrate Mario Motion Detector

**Step 1:** Modify mario.py to use ha-mqtt-py

```python
# At top of mario.py, import the MQTT components
import sys
sys.path.insert(0, '/usr/local/bin')
from ha_mqtt_py import Config, MQTTClientManager, DiscoveryManager

class MotionDetectionApp:
    def __init__(self, config):
        self.config = config
        # Initialize MQTT
        self.mqtt_config = Config(module_path="iot/ha-mqtt-py")
        self.mqtt_client = MQTTClientManager(self.mqtt_config)
        self.mqtt_client.connect()
        self.discovery = DiscoveryManager(self.mqtt_client, self.mqtt_config)
    
    def initialize(self):
        # ... existing initialization ...
        
        # Register motion sensor with Home Assistant
        self.discovery.register_binary_sensor(
            sensor_id="mario_motion",
            name="Mario Motion Detector",
            device_class="motion"
        )
    
    def handle_motion(self):
        # ... existing motion handling ...
        
        # Publish motion event to Home Assistant
        topic = f"{self.mqtt_config.STATE_TOPIC}/mario_motion"
        self.mqtt_client.publish(topic, "ON")
        
        # Reset to OFF after cooldown
        # (or use retain=False and let HA timeout handle it)
```

**Step 2:** Restart mario service

```bash
sudo systemctl restart mario
```

**Step 3:** Motion sensor automatically appears in Home Assistant!

### Example 2: Standalone Sensor Publishing

Create a simple temperature publisher:

```python
#!/usr/bin/env python3
"""Simple temperature sensor publisher"""
import time
import sys
sys.path.insert(0, '/usr/local/bin')
from ha_mqtt_py import Config, MQTTClientManager, DiscoveryManager

# Initialize
config = Config(module_path="iot/ha-mqtt-py")
mqtt_client = MQTTClientManager(config)
mqtt_client.connect()
discovery = DiscoveryManager(mqtt_client, config)

# Register sensor
discovery.register_sensor(
    sensor_id="room_temperature",
    name="Room Temperature",
    device_class="temperature",
    unit="°C",
    state_class="measurement"
)

# Publish data
while True:
    temp = read_temperature()  # Your sensor reading function
    topic = f"{config.STATE_TOPIC}/room_temperature"
    mqtt_client.publish(topic, str(temp))
    time.sleep(60)  # Update every minute
```

---

## Troubleshooting

### Service Won't Start

**Problem:** `systemctl start ha-mqtt-py` fails

**Solutions:**
1. Check service status: `systemctl status ha-mqtt-py`
2. View logs: `journalctl -u ha-mqtt-py -n 50`
3. Test manually: `python3 /usr/local/bin/ha-mqtt-py.py`
4. Verify paho-mqtt installed: `python3 -c "import paho.mqtt.client"`

### Cannot Connect to Broker

**Problem:** Logs show "Failed to connect to MQTT broker"

**Solutions:**
1. Verify broker is running: `mosquitto_sub -h localhost -t '#' -v`
2. Check broker address in config: `/etc/luigi/iot/ha-mqtt-py/ha-mqtt-py.conf`
3. Test network connectivity: `ping homeassistant.local`
4. Verify firewall allows port 1883
5. Check broker logs for connection attempts

### Authentication Fails

**Problem:** Connection refused with authentication error

**Solutions:**
1. Verify credentials in config file
2. Check config file permissions: `ls -l /etc/luigi/iot/ha-mqtt-py/ha-mqtt-py.conf`
3. Test credentials with mosquitto_pub:
   ```bash
   mosquitto_pub -h localhost -u username -P password -t test -m "hello"
   ```
4. Check broker authentication configuration

### Sensors Not Appearing in Home Assistant

**Problem:** MQTT connected but sensors don't show in HA

**Solutions:**
1. Verify MQTT integration enabled in HA
2. Check HA discovery prefix matches config (default: `homeassistant`)
3. View MQTT messages in HA: Developer Tools → MQTT → Listen to `#`
4. Check HA logs for discovery messages
5. Restart Home Assistant: Settings → System → Restart

### Log File Permission Denied

**Problem:** "Cannot write to /var/log/ha-mqtt-py.log"

**Solutions:**
1. Service runs as root, should have permissions
2. Check directory exists: `ls -ld /var/log`
3. Create log file manually: `sudo touch /var/log/ha-mqtt-py.log && sudo chmod 644 /var/log/ha-mqtt-py.log`
4. Logs also available via journalctl

### Service Restarts Frequently

**Problem:** Service keeps restarting

**Solutions:**
1. Check logs for errors: `journalctl -u ha-mqtt-py -n 100`
2. Common causes:
   - Network connectivity issues (auto-reconnect is normal)
   - Broker not accessible
   - Configuration errors
   - Python exceptions (check logs)
3. Increase RestartSec if network is unstable
4. Fix underlying issue shown in logs

---

## Architecture

### Design Principles

- **Separation of Concerns:** Each class has single responsibility
- **Hardware Abstraction:** MQTTClientManager abstracts paho-mqtt
- **Configuration Driven:** All settings externalized to config file
- **Error Resilience:** Comprehensive exception handling
- **Mock Support:** Development without infrastructure dependencies
- **Graceful Degradation:** Continues operation despite transient failures

### Security Features

✅ Input validation (topic format, sensor IDs)  
✅ Credential protection (600 permissions on config)  
✅ TLS encryption support  
✅ Log sanitization (no credential leaks)  
✅ Connection timeouts  
✅ systemd security hardening  

---

## Notes

### Network Requirements

- Raspberry Pi must be able to reach MQTT broker on network
- Default port 1883 (unencrypted) or 8883 (TLS)
- Consider firewall rules if broker is remote
- Recommend static IP or reserved DHCP for Raspberry Pi

### Performance

- CPU Usage: <2% idle, ~5% peak during publishing
- Memory: ~30-50MB (Python interpreter + libraries)
- Network: Minimal (keepalive every 60s, ~100 bytes)
- Disk: Log rotation prevents unbounded growth

### Best Practices

1. **Use TLS for production:** Enable TLS_ENABLED=yes with certificates
2. **Strong passwords:** Use unique, strong passwords for MQTT authentication
3. **Monitor logs:** Regularly check logs for errors or warnings
4. **Test configuration:** Use mock mode to test config changes
5. **Backup config:** Keep backup of working configuration

### Known Limitations

- Requires network connectivity (will reconnect when available)
- TLS certificate validation requires properly configured certificates
- QoS 2 may cause delays on slow networks
- Large payloads (>1MB) not recommended for MQTT

---

## Future Enhancements

Potential improvements for future versions:

- [ ] Shared Python library (`luigi_mqtt.py`) for easier integration
- [ ] Web interface for configuration and monitoring
- [ ] Statistics dashboard (messages sent, uptime, errors)
- [ ] MQTT 5.0 support (enhanced features)
- [ ] Multiple broker support (failover)
- [ ] Command-line tools for testing (luigi-mqtt-publish, etc.)
- [ ] Integration templates for common sensor types
- [ ] Automatic sensor discovery from other Luigi modules

---

## Support

**Documentation:**
- Module README: This file
- Design Documentation: `DESIGN_ANALYSIS.md`
- Implementation Plan: `IMPLEMENTATION_PLAN.md`

**Logging:**
- Service logs: `journalctl -u ha-mqtt-py -f`
- File logs: `/var/log/ha-mqtt-py.log`

**Commands:**
- Installation: `sudo ./setup.sh install`
- Status check: `./setup.sh status`
- Uninstall: `sudo ./setup.sh uninstall`

---

**Optimized for Raspberry Pi Zero W** - Compatible with other Raspberry Pi models  
**Part of the Luigi Project** - https://github.com/pkathmann88/luigi
