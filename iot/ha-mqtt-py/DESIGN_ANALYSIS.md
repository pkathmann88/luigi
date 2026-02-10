# Design Analysis: Home Assistant MQTT Integration (Python Edition)

**Module:** iot/ha-mqtt-py  
**Feature Request:** Create a Python-based equivalent of iot/ha-mqtt that follows the mario.py pattern instead of relying on shell scripts  
**Analyst:** GitHub Copilot  
**Date:** 2026-02-10  
**Status:** Analysis

---

## Purpose

This document captures the initial analysis for creating a Python-based Home Assistant MQTT integration module. Unlike the existing shell-script-based iot/ha-mqtt, this module will follow the Python architecture pattern established by motion-detection/mario, providing better structure, error handling, and maintainability.

**Workflow:**
```
Feature Request → DESIGN_ANALYSIS.md (Phases 1-3) → IMPLEMENTATION_PLAN.md (Phases 1-5)
```

---

## Phase 1: Requirements & Hardware Analysis

**Goal:** Understand requirements and design hardware approach.

**Skills Used:** `module-design`, `raspi-zero-w`

### 1.1 Requirements Definition

**Feature Request Summary:**
Create a Python-based Luigi module equivalent to iot/ha-mqtt that connects to a centralized Home Assistant instance via MQTT. The module should provide a clean Python API for other Luigi modules to publish sensor data and automatically register devices in Home Assistant using MQTT Discovery. This implementation should follow the mario.py pattern with proper OOP structure, configuration management, logging, and signal handling.

**Module Purpose:**
Provide a Python-based MQTT bridge enabling Luigi modules to publish sensor data to Home Assistant with automatic discovery, featuring robust error handling, structured configuration, and seamless integration following Luigi's Python module patterns.

**Key Features:**
- **Python-Based Architecture:** Clean OOP design with Config, MQTTClient, DiscoveryManager, and Application classes (WHY: Better maintainability, error handling, and testability than shell scripts)
- **MQTT Connection Management:** Maintain persistent connection to Home Assistant mosquitto broker with automatic reconnection (WHY: Ensures reliable data delivery even with network interruptions)
- **Home Assistant Discovery:** Automatically register Luigi devices/sensors using MQTT Discovery protocol (WHY: Eliminates manual YAML configuration in Home Assistant)
- **Configuration File Support:** INI-style config at `/etc/luigi/iot/ha-mqtt-py/ha-mqtt-py.conf` (WHY: Consistent with Luigi module patterns, easy for users to customize)
- **Structured Logging:** Rotating log files and console output with configurable levels (WHY: Essential for debugging and monitoring in production)
- **Graceful Shutdown:** Signal handlers for SIGTERM/SIGINT with proper resource cleanup (WHY: Required for systemd integration and safe service management)
- **Python API:** Programmatic interface for other Luigi modules to publish data (WHO: Other Python modules like mario.py can import and use)
- **Mock MQTT Support:** Development mode without requiring MQTT broker (WHY: Enables development and testing without infrastructure setup)

**Use Cases:**
1. **Motion Detection Integration:** Mario module imports ha-mqtt-py library to publish motion events to Home Assistant, triggering automations (e.g., turn on lights when motion detected)
2. **Environmental Monitoring:** Temperature/humidity sensor modules use ha-mqtt-py API to publish readings every minute, displaying in Home Assistant dashboards with history graphs
3. **System Monitoring:** System optimization module publishes CPU/memory metrics to Home Assistant for monitoring Raspberry Pi health across multiple devices
4. **Multi-Module Publishing:** Multiple Luigi modules on the same host share one ha-mqtt-py service, reducing resource usage and connection overhead
5. **Standalone Service:** ha-mqtt-py runs as a background service, other modules communicate via IPC (files, sockets) or shared library imports

**Success Criteria:**
- [x] Establish reliable MQTT connection to Home Assistant broker with automatic reconnection
- [x] Implement Home Assistant MQTT Discovery for automatic sensor registration
- [x] Provide Python API that other Luigi modules can import and use
- [x] Support configuration file at `/etc/luigi/iot/ha-mqtt-py/ha-mqtt-py.conf`
- [x] Handle authentication (username/password) for secure broker connection
- [x] Implement structured logging with rotation (similar to mario.py)
- [x] Support graceful shutdown via SIGTERM/SIGINT signals
- [x] Include mock MQTT support for development without broker
- [x] Deploy as systemd service with auto-restart capability
- [x] Minimal external dependencies (use paho-mqtt Python library)
- [x] Clear documentation with integration examples for Python modules
- [x] Follow Luigi Python module patterns (Config, GPIOManager equivalent, Application class)

**Requirements Clarity Checklist:**
- [x] Module purpose answers: What (Python MQTT bridge), Why (better structure than shell), How (OOP design), Who (other Luigi Python modules)
- [x] Each feature explains its value/rationale
- [x] Use cases are concrete and realistic
- [x] Success criteria are measurable and testable
- [x] Requirements are clear enough for someone unfamiliar to understand

### 1.2 Hardware Component Analysis

**Required Components:**
| Component | Part Number | Voltage | Current | Qty | Purpose | Availability |
|-----------|-------------|---------|---------|-----|---------|--------------|
| N/A - Software Only | N/A | N/A | N/A | N/A | MQTT integration | N/A |

**Reference:** See `.github/skills/module-design/SKILL.md` (Component Selection)

**Component Verification:**
- [x] No physical hardware components required
- [x] Pure software integration module
- [x] Works with existing Raspberry Pi network interface (WiFi/Ethernet)
- [x] Estimated cost: $0 (open source software only)

**Hardware Notes:**
This is a software-only integration module. It does not require any physical sensors or GPIO connections. The module operates over the network using the Raspberry Pi's built-in WiFi/Ethernet interface.

### 1.3 GPIO Pin Strategy

**Pin Requirements:**
| Function | Type | Special Requirements | Proposed Pin |
|----------|------|---------------------|--------------|
| N/A | N/A | N/A | N/A |

**Reference:** See `.github/skills/raspi-zero-w/gpio-pinout.md`

**GPIO Verification:**
- [x] No GPIO pins required (network-only module)
- [x] No conflicts with existing modules
- [x] Frees up all GPIO for sensor modules

**GPIO Notes:**
This module does not interact with GPIO pins. It is purely a network service that provides MQTT connectivity for other Luigi modules.

### 1.4 Wiring Design

**Wiring Diagram:**
```
N/A - No physical wiring required

Network Connectivity:
  Raspberry Pi Zero W (WiFi/Ethernet)
         |
         | Network (TCP/IP)
         |
         v
  Home Assistant Host
    - Mosquitto MQTT Broker (Port 1883 or 8883)
    - Home Assistant Core
```

**Reference:** See `.github/skills/module-design/hardware-design-checklist.md`

**Network Configuration:**
- **Connection Type:** TCP/IP over WiFi or Ethernet
- **Protocol:** MQTT v3.1.1 (via paho-mqtt library)
- **Port:** Default 1883 (unencrypted) or 8883 (TLS encrypted)
- **DNS/IP:** Configurable Home Assistant host address
- **Authentication:** Username/password support
- **QoS:** Configurable Quality of Service (0, 1, or 2)

### 1.5 Power Budget

**Power Calculations:**
| Component | Voltage | Current | Notes |
|-----------|---------|---------|-------|
| Raspberry Pi Zero W | 5V | 150mA | Base |
| Network Activity (WiFi) | 5V | +50mA peak | During MQTT transmission |
| Python Process (MQTT Client) | N/A | ~10-15mA | CPU overhead estimate |
| **TOTAL** |  | **~160-215mA** | Minimal increase |

**Power Supply:**
- Minimum required: 1.2A
- Recommended: 2A (standard Raspberry Pi requirement)
- External power needed: No

**Power Notes:**
MQTT is a lightweight protocol designed for IoT devices. The paho-mqtt Python library is efficient, and power overhead is minimal, primarily consisting of network transmission and occasional CPU usage for message processing.

### 1.6 Safety Analysis

**Critical Safety Checks:**
- [x] No physical hardware - electrical safety N/A
- [x] Network security considerations addressed
- [x] Authentication required for production use
- [x] TLS encryption supported for sensitive data
- [x] Input validation to prevent MQTT injection attacks
- [x] No GPIO operations - no hardware damage risk

**Safety Notes:**
As a software-only module, traditional electrical safety concerns don't apply. Security focuses on:
- Secure MQTT broker authentication
- TLS encryption for network traffic
- Input validation to prevent malicious topic/payload injection
- Safe credential storage (600 permissions on config file)
- Rate limiting to prevent broker flooding

---

## Phase 2: Software Architecture Analysis

**Goal:** Design software structure, configuration, and error handling.

**Skills Used:** `module-design`, `python-development`

### 2.1 Module Structure

**Directory Structure:**
```
iot/ha-mqtt-py/
├── README.md                      # Complete module documentation
├── DESIGN_ANALYSIS.md             # This file
├── IMPLEMENTATION_PLAN.md         # Implementation phases (created after this)
├── setup.sh                       # Installation automation (install/uninstall/status)
├── ha-mqtt-py.py                  # Main Python application
├── ha-mqtt-py.service             # systemd service unit file
├── ha-mqtt-py.conf.example        # Example configuration file
└── lib/                           # Optional: shared library for other modules
    └── luigi_mqtt.py              # Python API for other modules to import
```

**File Naming:**
- Module name: `ha-mqtt-py` (hyphenated for consistency)
- Python script: `ha-mqtt-py.py` (executable script)
- Service: `ha-mqtt-py.service`
- Config: `/etc/luigi/iot/ha-mqtt-py/ha-mqtt-py.conf`

### 2.2 Class Architecture

**Following mario.py Pattern:**

```python
#!/usr/bin/env python3
"""
Home Assistant MQTT Integration (Python Edition)
Part of the Luigi project
"""

class Config:
    """
    Configuration management with INI file loading and defaults.
    
    What: Loads and validates configuration from file or provides defaults
    Why: Centralizes all configuration logic, makes settings easy to modify
    How: Reads /etc/luigi/iot/ha-mqtt-py/ha-mqtt-py.conf on initialization
    Who: Used by MQTTClient and Application classes
    """
    
    # Sections: [Broker], [Authentication], [Client], [Topics], [Discovery], [Logging]
    DEFAULT_BROKER_HOST = "localhost"
    DEFAULT_BROKER_PORT = 1883
    DEFAULT_QOS = 1
    DEFAULT_CLIENT_ID = "luigi-{HOSTNAME}"
    DEFAULT_TOPIC_PREFIX = "homeassistant"
    DEFAULT_STATE_TOPIC = "luigi/{HOSTNAME}"
    DEFAULT_LOG_FILE = "/var/log/ha-mqtt-py.log"
    DEFAULT_LOG_LEVEL = "INFO"
    DEFAULT_RECONNECT_DELAY = 5
    DEFAULT_KEEPALIVE = 60

class MQTTClientManager:
    """
    MQTT connection management with paho-mqtt library.
    
    What: Manages MQTT broker connection, publishing, and callbacks
    Why: Abstracts MQTT complexity from application logic
    How: Uses paho-mqtt.Client with automatic reconnection
    Who: Used by Application class to publish data and handle events
    Responsibilities:
      - Connect to broker with authentication
      - Publish messages with QoS
      - Subscribe to topics
      - Handle connection events (connect, disconnect, error)
      - Automatic reconnection on failures
    """
    
    def __init__(self, config):
        """Initialize with config"""
        
    def connect(self):
        """Connect to MQTT broker"""
        
    def disconnect(self):
        """Disconnect from broker"""
        
    def publish(self, topic, payload, qos=1, retain=False):
        """Publish message to topic"""
        
    def subscribe(self, topic, callback):
        """Subscribe to topic with callback"""
        
    def is_connected(self):
        """Check connection status"""

class DiscoveryManager:
    """
    Home Assistant MQTT Discovery integration.
    
    What: Generates and publishes HA Discovery configuration messages
    Why: Enables automatic sensor registration without manual YAML config
    How: Constructs JSON payloads following HA Discovery spec, publishes to discovery topics
    Who: Used by Application and external modules to register sensors
    Responsibilities:
      - Generate discovery config JSON for sensor types (binary_sensor, sensor, etc.)
      - Publish discovery configs to homeassistant/{component}/{node_id}/{object_id}/config
      - Support all HA sensor device classes (temperature, humidity, motion, etc.)
      - Track registered sensors to avoid duplicates
    """
    
    def __init__(self, mqtt_client, config):
        """Initialize with MQTT client and config"""
        
    def register_sensor(self, sensor_id, name, device_class=None, 
                       unit=None, icon=None, state_topic=None):
        """Register sensor with Home Assistant Discovery"""
        
    def register_binary_sensor(self, sensor_id, name, device_class="motion"):
        """Register binary sensor (ON/OFF)"""
        
    def unregister_sensor(self, sensor_id):
        """Remove sensor from Home Assistant"""

class HAMQTTApplication:
    """
    Main application orchestrating MQTT integration.
    
    What: Main entry point coordinating all components
    Why: Provides clean application lifecycle management
    How: Initializes components, runs main loop, handles shutdown
    Who: Called by main() function, managed by systemd
    Responsibilities:
      - Initialize Config, MQTTClient, DiscoveryManager
      - Set up signal handlers for graceful shutdown
      - Run main event loop
      - Handle errors and recovery
      - Cleanup resources on exit
    """
    
    def __init__(self):
        """Initialize application"""
        
    def initialize(self):
        """Initialize all components"""
        
    def run(self):
        """Main application loop"""
        
    def stop(self):
        """Stop application and cleanup"""

# Mock MQTT Client for development
class MockMQTTClient:
    """
    Mock MQTT client for development without broker.
    
    What: Simulates MQTT operations for testing
    Why: Enables development and testing without MQTT infrastructure
    How: Logs operations instead of sending to broker
    Who: Used when paho-mqtt unavailable or MOCK_MODE enabled
    """
    pass
```

**Design Principles:**
- **Separation of Concerns:** Each class has single responsibility
- **Hardware Abstraction:** MQTTClientManager abstracts paho-mqtt details
- **Configuration Driven:** All settings in config file, not hardcoded
- **Testability:** Mock support for development without broker
- **Error Handling:** Try/except on all network operations
- **Logging:** Comprehensive logging at all levels

### 2.3 Configuration Design

**Configuration File Location:**
`/etc/luigi/iot/ha-mqtt-py/ha-mqtt-py.conf`

**Configuration Format (INI-style):**

```ini
# /etc/luigi/iot/ha-mqtt-py/ha-mqtt-py.conf
# Home Assistant MQTT Integration Configuration

[Broker]
# MQTT broker connection settings
HOST=localhost
PORT=1883
# TLS: Set to 'yes' to enable TLS encryption
TLS_ENABLED=no
# TLS_CA_CERT=/etc/ssl/certs/ca.crt
# TLS_CERT=/etc/ssl/certs/client.crt
# TLS_KEY=/etc/ssl/private/client.key

[Authentication]
# MQTT broker authentication
# Leave empty for anonymous access
USERNAME=
PASSWORD=

[Client]
# MQTT client configuration
CLIENT_ID=luigi-{HOSTNAME}
KEEPALIVE=60
QOS=1
RECONNECT_DELAY=5

[Topics]
# MQTT topic structure
TOPIC_PREFIX=homeassistant
STATE_TOPIC=luigi/{HOSTNAME}
AVAILABILITY_TOPIC=luigi/{HOSTNAME}/availability

[Discovery]
# Home Assistant Discovery settings
DEVICE_NAME=Luigi-{HOSTNAME}
DEVICE_MANUFACTURER=Luigi Project
DEVICE_MODEL=Raspberry Pi Zero W

[Logging]
# Logging configuration
LOG_FILE=/var/log/ha-mqtt-py.log
LOG_LEVEL=INFO
LOG_MAX_BYTES=10485760
LOG_BACKUP_COUNT=5
```

**Configuration Principles:**
- Sensible defaults for all settings
- Variable expansion: `{HOSTNAME}` replaced at runtime
- Comments explaining each option
- Grouped by functional area
- Optional authentication (empty = anonymous)
- File should have 600 permissions for security

### 2.4 API Design for Other Modules

**Python API (luigi_mqtt.py library):**

```python
# lib/luigi_mqtt.py - Shared library for other modules

from ha_mqtt_py import Config, MQTTClientManager, DiscoveryManager

class LuigiMQTT:
    """
    Simplified API for Luigi modules to publish to Home Assistant.
    
    What: High-level API abstracting MQTT/HA complexity
    Why: Makes it trivial for modules to publish without understanding MQTT
    How: Provides simple methods like publish_sensor(), register_sensor()
    Who: Other Luigi Python modules (mario.py, temperature sensors, etc.)
    
    Usage Example:
        from luigi_mqtt import LuigiMQTT
        
        mqtt = LuigiMQTT()
        mqtt.register_sensor("motion", "Mario Motion", device_class="motion")
        mqtt.publish_sensor("motion", "ON")
    """
    
    def __init__(self, config_path=None):
        """Initialize with optional custom config path"""
        
    def connect(self):
        """Connect to MQTT broker"""
        
    def register_sensor(self, sensor_id, name, device_class=None, unit=None):
        """Register sensor with Home Assistant"""
        
    def publish_sensor(self, sensor_id, value):
        """Publish sensor value"""
        
    def publish_binary_sensor(self, sensor_id, state):
        """Publish binary sensor state (ON/OFF, True/False)"""
        
    def disconnect(self):
        """Disconnect from broker"""
```

**Integration Example (mario.py using API):**

```python
# In mario.py
from luigi_mqtt import LuigiMQTT

class MotionDetectionApp:
    def __init__(self, config):
        self.config = config
        self.mqtt = LuigiMQTT()  # Use shared MQTT library
        
    def initialize(self):
        # Register motion sensor with Home Assistant
        self.mqtt.register_sensor(
            sensor_id="mario_motion",
            name="Mario Motion Detector",
            device_class="motion"
        )
        
    def handle_motion(self):
        # Publish motion event
        self.mqtt.publish_binary_sensor("mario_motion", "ON")
        # ... rest of motion handling
```

### 2.5 Error Handling Strategy

**Error Categories and Handling:**

1. **Connection Errors (MQTT broker unreachable):**
   - Log error with details
   - Retry with exponential backoff
   - Continue application (don't crash)
   - Report status via logs

2. **Authentication Errors:**
   - Log error with hint to check credentials
   - Don't retry immediately (prevent account lockout)
   - Exit with clear error message

3. **Configuration Errors:**
   - Validate on load
   - Log specific issue (missing file, invalid value)
   - Fall back to defaults where possible
   - Exit if critical config missing

4. **Publish Errors:**
   - Log warning (not fatal)
   - Queue message for retry if connection lost
   - Continue application

5. **Discovery Errors:**
   - Log warning
   - Retry discovery registration on reconnect
   - Continue application

**Error Handling Pattern:**
```python
try:
    client.connect(host, port)
    logging.info(f"Connected to MQTT broker at {host}:{port}")
except Exception as e:
    logging.error(f"Failed to connect to broker: {e}")
    # Schedule retry
    time.sleep(config.RECONNECT_DELAY)
```

### 2.6 Logging Strategy

**Log Configuration:**
- **File:** `/var/log/ha-mqtt-py.log`
- **Rotation:** 10MB max, 5 backups
- **Format:** `%(asctime)s - %(levelname)s - %(message)s`
- **Levels:** DEBUG, INFO, WARNING, ERROR, CRITICAL
- **Console:** INFO and above to stdout (for systemd journal)

**What to Log:**

- **INFO:** Connection events, sensor registration, successful publishes
- **WARNING:** Retry attempts, temporary failures, configuration fallbacks
- **ERROR:** Connection failures, authentication errors, critical issues
- **DEBUG:** Detailed MQTT messages, payload contents, state changes

**Log Sanitization:**
- Never log passwords
- Truncate long payloads (200 chars max)
- Remove newlines from logged strings
- Limit frequency of repeated messages

### 2.7 Security Hardening

**Security Measures:**

1. **Input Validation:**
   ```python
   def validate_topic(topic):
       """Validate MQTT topic to prevent injection"""
       if not re.match(r'^[a-zA-Z0-9/_-]+$', topic):
           raise ValueError("Invalid topic format")
       return topic
   ```

2. **Credential Protection:**
   - Config file must be 600 permissions
   - Warn if permissions too open
   - Never log passwords
   - Support TLS for encrypted connections

3. **Resource Limits:**
   - Timeout on connect (10s)
   - Max message size (1MB)
   - Rate limiting on publishes (prevent flooding)
   - Connection retry limit (max attempts before backoff)

4. **Safe Defaults:**
   - TLS disabled by default (user must enable)
   - Authentication required if username set
   - QoS 1 by default (balance reliability/performance)

**Security Checklist:**
- [x] No shell injection vulnerabilities (using paho-mqtt library, not subprocess)
- [x] Topic/payload validation
- [x] Log sanitization
- [x] Connection timeouts
- [x] File permissions checking
- [x] No hardcoded secrets
- [x] TLS support for encryption

---

## Phase 3: Service & Deployment Analysis

**Goal:** Design systemd integration and deployment strategy.

**Skills Used:** `module-design`, `system-setup`

### 3.1 systemd Service Design

**Service Unit File:** `/etc/systemd/system/ha-mqtt-py.service`

```ini
[Unit]
Description=Luigi Home Assistant MQTT Integration (Python)
Documentation=https://github.com/pkathmann88/luigi
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /usr/local/bin/ha-mqtt-py.py
Restart=on-failure
RestartSec=10
StandardOutput=append:/var/log/ha-mqtt-py.log
StandardError=append:/var/log/ha-mqtt-py.log

# Security hardening
PrivateTmp=yes
NoNewPrivileges=yes
ProtectSystem=strict
ReadWritePaths=/var/log /tmp /etc/luigi

[Install]
WantedBy=multi-user.target
```

**Service Design Decisions:**

- **Type=simple:** Foreground process (main loop)
- **User=root:** Network access doesn't require root, but consistent with other Luigi modules
- **After=network-online.target:** Wait for network before starting
- **Restart=on-failure:** Automatic recovery from crashes
- **RestartSec=10:** Wait 10s before restart (prevent rapid restart loops)
- **Security hardening:** PrivateTmp, NoNewPrivileges, ProtectSystem
- **Logging:** Both stdout and stderr to log file, also available via journalctl

### 3.2 Graceful Shutdown Design

**Signal Handling:**

```python
import signal
import sys

def signal_handler(signum, frame):
    """Handle shutdown signals gracefully"""
    signal_name = signal.Signals(signum).name
    logging.info(f"Received signal: {signal_name}")
    
    if app_instance:
        app_instance.stop()  # Disconnect MQTT, cleanup
    
    sys.exit(0)

# Register handlers
signal.signal(signal.SIGINT, signal_handler)   # Ctrl+C
signal.signal(signal.SIGTERM, signal_handler)  # systemctl stop
```

**Cleanup Steps on Shutdown:**
1. Log shutdown initiation
2. Publish offline status to availability topic
3. Disconnect MQTT client gracefully
4. Close log file handlers
5. Exit with code 0

**Shutdown Methods:**
- **SIGTERM** (recommended): `systemctl stop ha-mqtt-py`
- **SIGINT**: Ctrl+C during manual run
- **SIGKILL** (emergency only): `systemctl kill -s KILL ha-mqtt-py`

### 3.3 Setup Script Design

**Setup Script:** `setup.sh`

**Functions:**
1. **install()**
   - Check root privileges
   - Install dependencies: `python3-pip`, `python3-paho-mqtt`
   - Create config directory: `/etc/luigi/iot/ha-mqtt-py/`
   - Deploy config example: `/etc/luigi/iot/ha-mqtt-py/ha-mqtt-py.conf.example`
   - Copy config if not exists (preserves existing config)
   - Deploy Python script: `/usr/local/bin/ha-mqtt-py.py` (755)
   - Deploy service file: `/etc/systemd/system/ha-mqtt-py.service`
   - Deploy library: `/usr/local/lib/python3/dist-packages/luigi_mqtt.py` (optional)
   - Reload systemd daemon
   - Enable service (auto-start on boot)
   - Start service
   - Show status and next steps

2. **uninstall()**
   - Check root privileges
   - Stop service
   - Disable service
   - Remove service file
   - Remove Python script
   - Remove library
   - Ask about config removal (preserve user data by default)
   - Show uninstall summary

3. **status()**
   - Check service status (running/stopped/failed)
   - Check file installations
   - Show config location
   - Test MQTT connectivity (if running)
   - Display connection info

**Setup Script Template:**

```bash
#!/bin/bash
# setup.sh - Luigi Home Assistant MQTT Integration (Python) installation

set -euo pipefail

readonly MODULE_NAME="ha-mqtt-py"
readonly MODULE_CATEGORY="iot"
readonly CONFIG_DIR="/etc/luigi/${MODULE_CATEGORY}/${MODULE_NAME}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

require_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

install() {
    require_root
    log_info "Installing ${MODULE_NAME}..."
    
    # Install dependencies
    log_info "Installing Python dependencies..."
    apt-get update
    apt-get install -y python3-pip python3-paho-mqtt
    
    # Create config directory
    mkdir -p "${CONFIG_DIR}"
    
    # Deploy files
    # ... implementation details
    
    log_info "Installation complete!"
    log_info "Edit config: ${CONFIG_DIR}/${MODULE_NAME}.conf"
    log_info "Start service: systemctl start ${MODULE_NAME}"
}

uninstall() {
    require_root
    log_info "Uninstalling ${MODULE_NAME}..."
    # ... implementation details
}

status() {
    log_info "Checking ${MODULE_NAME} status..."
    # ... implementation details
}

case "${1:-}" in
    install)   install ;;
    uninstall) uninstall ;;
    status)    status ;;
    *)
        echo "Usage: $0 {install|uninstall|status}"
        exit 1
        ;;
esac
```

### 3.4 File Deployment Strategy

**Installation Locations:**

| File | Source | Destination | Permissions | Owner |
|------|--------|-------------|-------------|-------|
| ha-mqtt-py.py | ./ha-mqtt-py.py | /usr/local/bin/ha-mqtt-py.py | 755 | root:root |
| ha-mqtt-py.service | ./ha-mqtt-py.service | /etc/systemd/system/ha-mqtt-py.service | 644 | root:root |
| ha-mqtt-py.conf.example | ./ha-mqtt-py.conf.example | /etc/luigi/iot/ha-mqtt-py/ha-mqtt-py.conf.example | 644 | root:root |
| ha-mqtt-py.conf (initial) | ./ha-mqtt-py.conf.example | /etc/luigi/iot/ha-mqtt-py/ha-mqtt-py.conf | 600 | root:root |
| luigi_mqtt.py (optional) | ./lib/luigi_mqtt.py | /usr/local/lib/python3/dist-packages/luigi_mqtt.py | 644 | root:root |

**Deployment Notes:**
- Only copy `ha-mqtt-py.conf` if it doesn't exist (preserve user config)
- Always copy `ha-mqtt-py.conf.example` (for reference)
- Make Python script executable (755)
- Secure config file (600) to protect credentials
- systemd reload required after service file deployment

### 3.5 Dependency Management

**Runtime Dependencies:**

1. **Python 3:** Already available on Raspberry Pi OS
2. **paho-mqtt:** MQTT client library
   ```bash
   apt-get install python3-paho-mqtt
   # OR
   pip3 install paho-mqtt
   ```

**Optional Dependencies:**

1. **python3-gi (for system tray - future enhancement)**
2. **python3-cryptography (for TLS cert validation)**

**Dependency Installation:**
```bash
# In setup.sh install()
apt-get update
apt-get install -y python3-pip python3-paho-mqtt

# Verify installation
python3 -c "import paho.mqtt.client" || {
    log_error "Failed to install paho-mqtt"
    exit 1
}
```

### 3.6 Integration with Luigi System

**Luigi Root setup.sh Integration:**

The ha-mqtt-py module will be automatically discovered by `/home/runner/work/luigi/luigi/setup.sh`:

```bash
# Luigi root setup.sh discovers modules in iot/ directory
sudo ./setup.sh install         # Installs all modules including iot/ha-mqtt-py
sudo ./setup.sh install iot/ha-mqtt-py  # Install only ha-mqtt-py
./setup.sh status               # Shows status of all modules
```

**Module Discovery:**
- Luigi root setup.sh scans all category directories
- Finds setup.sh in each module directory
- Calls module setup.sh with appropriate command

**Service Management:**
```bash
# Standard systemd commands
systemctl start ha-mqtt-py
systemctl stop ha-mqtt-py
systemctl restart ha-mqtt-py
systemctl status ha-mqtt-py
systemctl enable ha-mqtt-py   # Auto-start on boot
systemctl disable ha-mqtt-py

# View logs
journalctl -u ha-mqtt-py -f   # Follow logs
tail -f /var/log/ha-mqtt-py.log
```

### 3.7 Testing Strategy

**Testing Levels:**

1. **Syntax Validation (No Dependencies):**
   ```bash
   python3 -m py_compile ha-mqtt-py.py
   python3 -m py_compile lib/luigi_mqtt.py
   shellcheck setup.sh
   ```

2. **Unit Testing (Mock MQTT):**
   ```python
   # Test with mock MQTT client
   MOCK_MODE=1 python3 ha-mqtt-py.py
   
   # Test configuration loading
   # Test discovery payload generation
   # Test topic validation
   ```

3. **Integration Testing (Real MQTT Broker):**
   ```bash
   # Requires mosquitto broker running
   # Test actual connection
   # Test publishing
   # Test discovery registration
   # Test reconnection on failure
   ```

4. **Service Testing:**
   ```bash
   # Test service installation
   # Test service start/stop
   # Test service restart after failure
   # Test log rotation
   ```

**Test Checklist:**
- [ ] Python syntax validates
- [ ] Shell script passes shellcheck
- [ ] Runs in mock mode without broker
- [ ] Connects to real MQTT broker
- [ ] Publishes messages successfully
- [ ] Registers sensors via discovery
- [ ] Handles connection failures gracefully
- [ ] Responds to signals correctly
- [ ] Service installs and starts
- [ ] Logs rotate properly

---

## Phase 3 Completion Checklist

- [x] systemd service file designed
- [x] Graceful shutdown strategy defined
- [x] Setup script structure planned
- [x] File deployment locations specified
- [x] Dependencies identified
- [x] Luigi system integration planned
- [x] Testing strategy defined

---

## Design Approval

**Hardware Design:** ✓ Approved (Software-only, no hardware required)  
**Software Architecture:** ✓ Approved (Clean OOP design following mario.py pattern)  
**Service Integration:** ✓ Approved (systemd with auto-restart, security hardening)  
**Deployment Strategy:** ✓ Approved (Automated setup.sh, proper file locations)

**Next Steps:**
1. Create IMPLEMENTATION_PLAN.md based on this analysis
2. Execute implementation phases:
   - Phase 1: Testing Strategy
   - Phase 2: Core Implementation
   - Phase 3: Documentation
   - Phase 4: Setup & Deployment
   - Phase 5: Final Verification

**Status:** Ready for Implementation Plan Creation

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-10  
**Sign-off:** Design Analysis Complete
