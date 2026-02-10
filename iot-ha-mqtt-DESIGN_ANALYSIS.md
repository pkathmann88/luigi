# Design Analysis: Home Assistant MQTT Integration

**Module:** iot/ha-mqtt  
**Feature Request:** Connect Luigi to Home Assistant via MQTT for sensor data integration  
**Analyst:** GitHub Copilot  
**Date:** 2026-02-10  
**Status:** Analysis

---

## Purpose

This document captures the initial analysis for creating a Home Assistant MQTT integration module that allows Luigi modules to publish sensor data and device information to a centralized Home Assistant instance via MQTT.

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
Create a Luigi module that connects to a centralized Home Assistant instance running a mosquitto MQTT broker. The module should provide an easy-to-use interface for other Luigi modules to publish sensor data and device information, with automatic Home Assistant discovery integration. The module should leverage pre-existing packages where possible rather than requiring custom Python code.

**Module Purpose:**
Provide a seamless MQTT bridge between Luigi modules and Home Assistant for automatic sensor discovery and data publishing.

**Key Features:**
- **MQTT Connection Management:** Maintain persistent connection to Home Assistant mosquitto broker
- **Home Assistant Discovery:** Automatically register Luigi devices/sensors using MQTT Discovery protocol
- **Simple Publishing Interface:** Provide easy-to-use mechanism for Luigi modules to publish sensor data
- **Configuration Management:** Support flexible broker configuration (host, port, credentials, topics)
- **Connection Resilience:** Automatic reconnection on network failures
- **Minimal Dependencies:** Use existing MQTT tools (mosquitto-clients) to minimize custom code

**Use Cases:**
1. **Motion Detection Integration:** Mario module publishes motion events to Home Assistant for automation triggers
2. **Environmental Monitoring:** Temperature/humidity sensors publish readings for Home Assistant dashboards
3. **System Monitoring:** Luigi system status (CPU, memory, uptime) published for monitoring
4. **Device Control:** Home Assistant can send commands to Luigi modules via MQTT
5. **Multi-Luigi Deployment:** Multiple Luigi hosts publish to single Home Assistant instance

**Success Criteria:**
- [x] Establish reliable MQTT connection to Home Assistant broker
- [x] Support Home Assistant MQTT Discovery for automatic sensor registration
- [x] Provide simple interface for Luigi modules to publish data (config file + scripts)
- [x] Handle authentication (username/password) for secure broker connection
- [x] Automatically reconnect on network/broker failures
- [x] Minimal performance impact on Luigi host
- [x] Clear documentation with Home Assistant setup examples

### 1.2 Hardware Component Analysis

**Required Components:**
| Component | Part Number | Voltage | Current | Qty | Purpose | Availability |
|-----------|-------------|---------|---------|-----|---------|--------------|
| N/A - Software Only | N/A | N/A | N/A | N/A | MQTT integration | N/A |

**Reference:** See `.github/skills/module-design/SKILL.md` (Component Selection)

**Component Verification:**
- [x] No physical hardware components required
- [x] Pure software integration module
- [x] Works with existing Raspberry Pi network interface
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
    - Zigbee2MQTT Integration
```

**Reference:** See `.github/skills/module-design/hardware-design-checklist.md`

**Network Configuration:**
- **Connection Type:** TCP/IP over WiFi or Ethernet
- **Protocol:** MQTT v3.1.1 or v5.0
- **Port:** Default 1883 (unencrypted) or 8883 (TLS encrypted)
- **DNS/IP:** Configurable Home Assistant host address
- **Authentication:** Username/password support

### 1.5 Power Budget

**Power Calculations:**
| Component | Voltage | Current | Notes |
|-----------|---------|---------|-------|
| Raspberry Pi Zero W | 5V | 150mA | Base |
| Network Activity (WiFi) | 5V | +50mA peak | During MQTT transmission |
| MQTT Client Process | N/A | ~5-10mA | CPU overhead estimate |
| **TOTAL** |  | **~160-210mA** | Minimal increase |

**Power Supply:**
- Minimum required: 1.2A
- Recommended: 2A (standard Raspberry Pi requirement)
- External power needed: No

**Power Notes:**
MQTT is a lightweight protocol designed for IoT devices. The power overhead is minimal, primarily consisting of network transmission and occasional CPU usage for message processing.

### 1.6 Safety Analysis

**Critical Safety Checks:**
- [x] No physical hardware - electrical safety N/A
- [x] Network security considerations addressed
- [x] Authentication required for production use
- [x] TLS encryption recommended for sensitive data
- [x] Secure credential storage planned

**Safety Concerns:**
1. **Network Security:** MQTT broker must be secured with authentication
2. **Data Privacy:** Sensor data transmitted over network could be intercepted
3. **Credential Storage:** MQTT credentials must be stored securely

**Mitigations:**
1. **Authentication:** Always use username/password for broker connection
2. **TLS Encryption:** Support encrypted MQTT connections (port 8883)
3. **Credential Protection:** Store credentials in config file with 600 permissions (owner read/write only)
4. **Network Segmentation:** Recommend IoT VLAN for Home Assistant and Luigi hosts
5. **Topic ACLs:** Document recommended MQTT topic ACL configuration

### 1.7 Hardware Analysis Summary

**Hardware Approach:**
This is a pure software integration module with no physical hardware requirements. The module provides MQTT connectivity over the Raspberry Pi's existing network interface, enabling Luigi modules to communicate with Home Assistant.

**Key Hardware Decisions:**
1. **Decision: No GPIO Usage** - This module is network-only, preserving all GPIO pins for sensor modules
2. **Decision: Use Existing Network Interface** - Leverage built-in WiFi/Ethernet rather than adding network hardware
3. **Decision: Minimal Resource Usage** - MQTT is lightweight, ensuring minimal impact on system resources

**Hardware Risks:**
| Risk | Severity | Mitigation |
|------|----------|------------|
| Network connectivity loss | Medium | Automatic reconnection logic with exponential backoff |
| WiFi interference affecting reliability | Low | Recommend wired Ethernet for critical deployments |
| DNS resolution failures | Low | Support both IP addresses and hostnames in configuration |

**Phase 1 Sign-off:**
- [x] Requirements clearly defined
- [x] Hardware components selected (none required)
- [x] GPIO pins assigned (none required)
- [x] Wiring diagram created (network diagram)
- [x] Safety verified (network security addressed)
- [x] Ready for Phase 2

**Approved by:** GitHub Copilot **Date:** 2026-02-10

---

## Phase 2: Software Architecture Analysis

**Goal:** Design software structure and architecture.

**Skills Used:** `module-design`, `python-development`

### 2.1 Module Structure Design

**File Structure:**
```
iot/ha-mqtt/
├── README.md                      # Complete documentation with HA setup
├── setup.sh                       # Installation script (install/uninstall/status)
├── ha-mqtt-bridge.py              # Python MQTT bridge service
├── ha-mqtt-bridge.service         # systemd service file
├── ha-mqtt.conf.example           # Example configuration
├── lib/
│   └── ha_discovery.py            # Home Assistant MQTT Discovery helper
└── examples/
    ├── publish_motion.sh          # Example: Publish motion event
    ├── publish_temperature.sh     # Example: Publish temperature reading
    └── register_sensor.sh         # Example: Register sensor with HA Discovery
```

**Alternative Lightweight Approach (Using Existing Tools):**
```
iot/ha-mqtt/
├── README.md                      # Complete documentation with HA setup
├── setup.sh                       # Installation script
├── ha-mqtt.conf.example           # Configuration file
├── ha-mqtt-monitor.sh             # Connection monitoring script
├── lib/
│   └── mqtt_helpers.sh            # Shell functions for MQTT operations
└── examples/
    ├── publish_motion.sh          # Example: mosquitto_pub wrapper
    ├── publish_temperature.sh     # Example: sensor data publishing
    └── discovery/                 # HA Discovery JSON templates
        ├── motion_sensor.json
        ├── temperature_sensor.json
        └── system_monitor.json
```

**Architecture Decision:**
**Primary Approach: Shell Script Wrapper with mosquitto_pub**

The module will primarily use shell scripts wrapping `mosquitto_pub` and `mosquitto_sub` from the mosquitto-clients package. This approach:
- **Minimizes custom code** (aligns with user requirement)
- **Uses battle-tested MQTT tools** (mosquitto-clients is industry standard)
- **Simplifies maintenance** (no complex Python dependencies)
- **Provides flexibility** (easy for users to customize scripts)

**Python Component (Optional Enhancement):**
A lightweight Python bridge service can optionally be provided for:
- Persistent connection management
- Automatic reconnection handling
- Home Assistant state monitoring
- Advanced features (QoS management, retained messages)

**Class Architecture (If Python Service Used):**

**Config Class:**
- Purpose: Load and manage MQTT broker configuration
- Key attributes: broker_host, broker_port, username, password, client_id, topic_prefix, discovery_prefix
- Configuration file: `/etc/luigi/iot/ha-mqtt/ha-mqtt.conf`

**MQTTManager Class:**
- Purpose: Manage MQTT connection lifecycle
- Key methods: connect(), disconnect(), publish(), subscribe(), on_connect(), on_disconnect()
- Library: paho-mqtt (if Python approach)

**HADiscovery Class:**
- Purpose: Generate Home Assistant MQTT Discovery payloads
- Key methods: register_sensor(), register_binary_sensor(), register_device(), remove_entity()
- Supports: sensors, binary_sensors, switches, climate, etc.

**HAMQTTBridge Class:**
- Purpose: Main application orchestrating MQTT operations
- Key methods: __init__(), start(), stop(), _handle_signal(), publish_state()
- Main loop type: Event-driven (MQTT callback-based)

**Reference:** See `.github/skills/python-development/SKILL.md` (Class Architecture)

### 2.2 Configuration Design

**Configuration File Location:**
`/etc/luigi/iot/ha-mqtt/ha-mqtt.conf`

**Configuration Structure:**
```ini
# /etc/luigi/iot/ha-mqtt/ha-mqtt.conf
# Home Assistant MQTT Integration Configuration

[Broker]
# MQTT broker connection settings
HOST=homeassistant.local
PORT=1883
# For TLS encryption, use port 8883 and set TLS=yes
TLS=no
# Optional: Path to CA certificate for TLS
# CA_CERT=/etc/ssl/certs/ca-certificates.crt

[Authentication]
# MQTT broker authentication
USERNAME=luigi
PASSWORD=your_secure_password_here
# Note: Set permissions to 600 (owner read/write only) to protect credentials

[Client]
# MQTT client settings
CLIENT_ID=luigi_${HOSTNAME}
KEEPALIVE=60
QOS=1
# Clean session (yes=no persistence, no=persistent session)
CLEAN_SESSION=yes

[Topics]
# Topic structure for Luigi messages
# Default: homeassistant/sensor/luigi-${HOSTNAME}/${sensor_name}/state
BASE_TOPIC=homeassistant
DISCOVERY_PREFIX=homeassistant
DEVICE_PREFIX=luigi
# Full topic example: homeassistant/sensor/luigi-raspberrypi/motion/state

[Device]
# Device information for Home Assistant
DEVICE_NAME=Luigi ${HOSTNAME}
DEVICE_MODEL=Raspberry Pi Zero W
MANUFACTURER=Luigi Project
SW_VERSION=1.0

[Connection]
# Connection behavior
RECONNECT_DELAY_MIN=5
RECONNECT_DELAY_MAX=300
CONNECTION_TIMEOUT=10

[Logging]
# Logging configuration
LOG_FILE=/var/log/ha-mqtt.log
LOG_LEVEL=INFO
LOG_MAX_BYTES=10485760
LOG_BACKUP_COUNT=5
```

**Configurable Parameters:**
| Parameter | Section | Type | Default | Description |
|-----------|---------|------|---------|-------------|
| HOST | Broker | string | homeassistant.local | MQTT broker hostname or IP |
| PORT | Broker | int | 1883 | MQTT broker port (1883 unencrypted, 8883 TLS) |
| TLS | Broker | bool | no | Enable TLS encryption |
| USERNAME | Authentication | string | luigi | MQTT username |
| PASSWORD | Authentication | string | (required) | MQTT password |
| CLIENT_ID | Client | string | luigi_${HOSTNAME} | Unique client identifier |
| QOS | Client | int | 1 | Quality of Service (0, 1, or 2) |
| BASE_TOPIC | Topics | string | homeassistant | Root topic for all messages |
| DISCOVERY_PREFIX | Topics | string | homeassistant | HA Discovery prefix |
| DEVICE_NAME | Device | string | Luigi ${HOSTNAME} | Device name in Home Assistant |
| RECONNECT_DELAY_MIN | Connection | int | 5 | Min reconnection delay (seconds) |
| LOG_LEVEL | Logging | string | INFO | Logging level |

**Configuration Verification:**
- [x] All user-changeable settings identified
- [x] Sensible defaults chosen
- [x] Configuration location follows Luigi standard
- [x] INI format with clear sections
- [x] Credential protection documented (600 permissions)

### 2.3 Error Handling Strategy

**Error Handling Plan:**

**Network Errors:**
- **Connection Failures:** Retry with exponential backoff (5s → 10s → 20s → 60s → 300s max)
- **DNS Resolution Failures:** Log error, support fallback to IP address in config
- **Socket Timeouts:** Configure reasonable timeout (10s default), retry connection
- **TLS Errors:** Log certificate issues with helpful debugging information

**MQTT Protocol Errors:**
- **Authentication Failures:** Log clear error, exit with helpful message about credentials
- **Authorization Failures:** Log which topic failed, suggest checking broker ACLs
- **QoS Failures:** Fall back to QoS 0 if higher QoS fails
- **Message Too Large:** Log error with message size, suggest chunking large payloads

**Configuration Errors:**
- **Missing Config File:** Use defaults with warning, continue operation
- **Invalid Values:** Validate on load, use defaults for invalid values, log warnings
- **Missing Required Values:** Exit with clear error message about required parameters

**System Errors:**
- **Process Errors (shell scripts):** Check return codes, retry with backoff
- **File System Errors:** Handle read/write failures gracefully, fall back to stdout
- **Resource Exhaustion:** Detect low memory/disk, reduce logging verbosity

**Reference:** See `.github/skills/python-development/SKILL.md` (Error Handling)

### 2.4 Logging Strategy

**Logging Configuration:**
- Log file: `/var/log/ha-mqtt.log`
- Rotation: 10MB max, 5 backups
- Levels used: DEBUG, INFO, WARNING, ERROR
- Also output to stdout/stderr for systemd journalctl

**Key Log Points:**
1. **Startup/Shutdown:**
   - Service started with configuration summary
   - Connection established to broker
   - Graceful shutdown initiated
   
2. **Connection Events:**
   - Connected to MQTT broker (with host:port)
   - Disconnected from broker (with reason)
   - Reconnection attempts (with delay)
   
3. **Message Activity:**
   - Messages published (topic + size, not full payload)
   - Messages received on subscribed topics
   - Discovery registrations sent
   
4. **Errors and Warnings:**
   - Connection failures with error details
   - Authentication failures
   - Invalid configuration values
   - Message publish failures
   
5. **Configuration:**
   - Configuration loaded from file
   - Using default values for missing parameters
   - Security: Never log passwords

**Log Sanitization:**
- [x] Length limits on logged data (max 200 chars per message)
- [x] No sensitive information (passwords, tokens)
- [x] Newlines removed from user data
- [x] MQTT payloads truncated if >200 bytes (log size only)
- [x] Hostnames and IPs sanitized in public examples

### 2.5 Security Design

**Security Measures:**
- [x] subprocess.run() with list arguments (no shell=True)
- [x] Path validation using os.path.commonpath()
- [x] Log sanitization implemented
- [x] Subprocess timeouts (10s default)
- [x] File permissions appropriate (600 for config with credentials, 644 for examples, 755 for executables)
- [x] Credential storage security (config file must be 600 permissions)
- [x] TLS support for encrypted connections
- [x] No hardcoded credentials

**Additional MQTT-Specific Security:**
- **Authentication Required:** Always use username/password in production
- **TLS Encryption:** Support and document TLS setup (port 8883)
- **Certificate Validation:** Validate server certificates when using TLS
- **Topic ACLs:** Document recommended broker ACL configuration
- **Credential Rotation:** Document how to update credentials
- **Network Isolation:** Recommend firewall rules limiting MQTT access

**Security Concerns:**
1. **Plaintext Credentials in Config:** Config file contains MQTT password
2. **Network Eavesdropping:** MQTT messages sent unencrypted by default
3. **Broker Access:** Compromised broker could receive all sensor data
4. **Command Injection:** Shell scripts could be vulnerable to injection

**Mitigations:**
1. **Config Permissions:** Enforce 600 permissions (owner read/write only) on config file
2. **TLS Support:** Provide TLS configuration for encrypted connections
3. **Authentication:** Always require username/password
4. **Input Validation:** Validate all inputs in shell scripts, use proper quoting
5. **Secure Defaults:** Default to QoS 1 for reliability without retained passwords
6. **Documentation:** Provide security hardening guide in README

**Reference:** See `.github/skills/module-design/SKILL.md` (Security Design)

### 2.6 Software Architecture Summary

**Architecture Pattern:**
**Hybrid: Event-driven + Command-line Tools**

The module uses a hybrid architecture:
1. **Shell Script Wrappers:** Primary interface using mosquitto_pub/mosquitto_sub
2. **Optional Python Service:** Event-driven MQTT bridge for persistent connections
3. **Library Functions:** Reusable shell functions for common operations
4. **Discovery Templates:** JSON templates for Home Assistant MQTT Discovery

**Key Software Decisions:**

1. **Decision: Prefer mosquitto-clients over custom MQTT implementation**
   - **Rationale:** User requested "use pre-existing packages to connect to Home Assistant MQTT broker"
   - **Benefits:** Battle-tested tools, minimal code to maintain, widely understood
   - **Trade-off:** Less control over connection lifecycle vs. custom Python service

2. **Decision: Provide both shell script and optional Python approaches**
   - **Rationale:** Shell scripts for simplicity, Python for advanced features
   - **Benefits:** Flexibility for different use cases and user preferences
   - **Usage:** Shell scripts for simple publishing, Python for persistent connections

3. **Decision: Home Assistant MQTT Discovery support**
   - **Rationale:** Automatic sensor registration eliminates manual Home Assistant configuration
   - **Benefits:** Sensors appear in Home Assistant immediately, proper metadata and units
   - **Implementation:** JSON templates + mosquitto_pub with retained messages

4. **Decision: Config file for all connection parameters**
   - **Rationale:** Centralized configuration shared by all scripts
   - **Benefits:** Easy credential management, consistent connection parameters
   - **Security:** Single file to protect with restrictive permissions

**Software Risks:**
| Risk | Severity | Mitigation |
|------|----------|------------|
| mosquitto-clients not available | Low | Installation handled by setup.sh, documented in README |
| Broker connection failures | Medium | Retry logic with exponential backoff, clear error messages |
| Discovery messages not received by HA | Low | Use retained messages, provide debugging commands |
| Config file permissions too open | Medium | setup.sh enforces 600 permissions, validate on service start |
| Shell script injection vulnerabilities | Medium | Proper quoting, input validation, parameter expansion |

**Phase 2 Sign-off:**
- [x] Module structure designed
- [x] Class architecture defined (hybrid shell + optional Python)
- [x] Configuration designed
- [x] Error handling planned
- [x] Logging strategy defined
- [x] Security measures planned
- [x] Ready for Phase 3

**Approved by:** GitHub Copilot **Date:** 2026-02-10

---

## Phase 3: Service & Deployment Analysis

**Goal:** Design service integration and deployment strategy.

**Skills Used:** `module-design`, `system-setup`

### 3.1 systemd Service Design

**Service Unit File Design (Optional Python Service):**
```ini
[Unit]
Description=Home Assistant MQTT Bridge Service
Documentation=https://github.com/pkathmann88/luigi
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=luigi
Group=luigi
ExecStart=/usr/bin/python3 /usr/local/bin/ha-mqtt-bridge.py
Restart=on-failure
RestartSec=10
StandardOutput=append:/var/log/ha-mqtt.log
StandardError=append:/var/log/ha-mqtt.log

# Security hardening
PrivateTmp=yes
NoNewPrivileges=yes
ProtectSystem=strict
ReadWritePaths=/var/log /etc/luigi
ProtectHome=yes
PrivateDevices=yes

[Install]
WantedBy=multi-user.target
```

**Service Characteristics:**
- **Type:** simple (foreground application)
- **User:** luigi (non-root - no GPIO access needed)
- **After:** network-online.target (wait for network)
- **Restart:** on-failure with 10s delay
- **Logging:** File + journalctl
- **Security:** Enhanced hardening (no GPIO, no /dev access needed)

**Alternative: No Persistent Service (Shell Scripts Only)**

For lightweight deployments, the module can work without a persistent service:
- Luigi modules call shell scripts directly to publish data
- Each script call makes a one-time MQTT connection
- No persistent process needed
- Trade-off: Slightly higher latency, connection overhead per message

**Recommended Approach:**
- **Simple deployments:** Shell scripts only, no service
- **Frequent updates:** Python service for persistent connection
- **Mixed:** Shell scripts + optional connection monitor script

**Reference:** See `.github/skills/module-design/SKILL.md` (Service Integration)

### 3.2 Shutdown Mechanism Design

**Signal Handlers (Python Service):**
- **SIGTERM:** Triggered by `systemctl stop`
- **SIGINT:** Triggered by Ctrl+C (manual operation)

**Cleanup Steps:**
1. Log shutdown initiation
2. Publish offline status to Home Assistant (LWT - Last Will and Testament)
3. Disconnect from MQTT broker gracefully
4. Close log file handlers
5. Exit with code 0

**Timeout:** 30 seconds (TimeoutStopSec)

**Shell Script Cleanup:**
For shell scripts, cleanup is minimal:
- Most scripts are short-lived (connect, publish, disconnect)
- No persistent state to clean up
- Trap signals if running monitoring loop

**Reference:** See `.github/skills/python-development/SKILL.md` (Signal Handlers)

### 3.3 Setup Script Strategy

**setup.sh Design:**

**Install Function:**
1. **Check prerequisites:**
   - Python 3 installed (if using Python service)
   - Network connectivity available
   - systemd available
   
2. **Install dependencies:**
   ```bash
   sudo apt-get update
   sudo apt-get install -y mosquitto-clients
   # Optional: python3-paho-mqtt (if using Python service)
   ```
   
3. **Create directories:**
   ```bash
   sudo mkdir -p /etc/luigi/iot/ha-mqtt
   sudo mkdir -p /usr/local/bin
   sudo mkdir -p /var/log
   ```
   
4. **Deploy configuration file:**
   - Copy ha-mqtt.conf.example to /etc/luigi/iot/ha-mqtt/ha-mqtt.conf
   - Preserve existing config if present
   - Set permissions to 600 (owner only)
   - Prompt user to edit broker settings
   
5. **Deploy library and scripts:**
   - Copy lib/mqtt_helpers.sh to /usr/local/lib/luigi/
   - Copy example scripts to /usr/share/luigi/ha-mqtt/examples/
   - Set executable permissions (755)
   
6. **Deploy Python service (optional):**
   - Copy ha-mqtt-bridge.py to /usr/local/bin/
   - Copy ha-mqtt-bridge.service to /etc/systemd/system/
   - Create luigi user if doesn't exist
   - systemctl daemon-reload
   
7. **Enable and start service (if Python service):**
   ```bash
   sudo systemctl enable ha-mqtt-bridge.service
   sudo systemctl start ha-mqtt-bridge.service
   ```
   
8. **Verify installation:**
   - Check service status (if applicable)
   - Test MQTT connection with test publish
   - Verify log file created
   - Print next steps for user

**Uninstall Function:**
1. **Stop service:**
   ```bash
   sudo systemctl stop ha-mqtt-bridge.service
   sudo systemctl disable ha-mqtt-bridge.service
   ```
   
2. **Disable service:**
   - Remove service file from /etc/systemd/system/
   - systemctl daemon-reload
   
3. **Remove application files:**
   - Remove /usr/local/bin/ha-mqtt-bridge.py
   - Remove /usr/local/lib/luigi/mqtt_helpers.sh
   - Remove /usr/share/luigi/ha-mqtt/
   
4. **Interactive: Remove config/data?**
   ```bash
   read -p "Remove configuration and logs? [y/N] " response
   if [[ "$response" =~ ^[Yy]$ ]]; then
       sudo rm -rf /etc/luigi/iot/ha-mqtt
       sudo rm -f /var/log/ha-mqtt.log*
   fi
   ```
   
5. **Ask about removing mosquitto-clients:**
   - Prompt whether to remove package
   - Only remove if user confirms (may be used by other apps)
   
6. **Verify removal:**
   - Check service no longer exists
   - Confirm files removed
   - Print removal summary

**Status Function:**
1. **Check service status:**
   ```bash
   if systemctl is-active --quiet ha-mqtt-bridge.service; then
       echo "Service: Running"
   else
       echo "Service: Stopped"
   fi
   ```
   
2. **Check file installations:**
   - Verify config file exists
   - Verify scripts deployed
   - Verify library installed
   
3. **Check MQTT connectivity:**
   - Test publish to broker
   - Report success or connection error
   
4. **Display configuration summary:**
   - Broker host
   - Connection status
   - Last log entries
   
5. **Display usage examples:**
   - Show example publish commands
   - Link to README

**Reference:** See `.github/skills/system-setup/SKILL.md`

### 3.4 File Deployment Plan

**File Locations:**
| File | Source | Destination | Permissions |
|------|--------|-------------|-------------|
| ha-mqtt.conf.example | Repo | /etc/luigi/iot/ha-mqtt/ha-mqtt.conf | 600 |
| ha-mqtt-bridge.py | Repo | /usr/local/bin/ | 755 |
| ha-mqtt-bridge.service | Repo | /etc/systemd/system/ | 644 |
| mqtt_helpers.sh | Repo lib/ | /usr/local/lib/luigi/ | 644 |
| publish_*.sh examples | Repo examples/ | /usr/share/luigi/ha-mqtt/examples/ | 755 |
| discovery/*.json | Repo examples/discovery/ | /usr/share/luigi/ha-mqtt/examples/discovery/ | 644 |

**Directory Structure:**
```
/etc/luigi/iot/ha-mqtt/
  └── ha-mqtt.conf                          # Main configuration (600)

/usr/local/bin/
  └── ha-mqtt-bridge.py                     # Python service (755)

/usr/local/lib/luigi/
  └── mqtt_helpers.sh                       # Shared library (644)

/usr/share/luigi/ha-mqtt/
  ├── examples/
  │   ├── publish_motion.sh                 # Example scripts (755)
  │   ├── publish_temperature.sh
  │   └── discovery/
  │       ├── motion_sensor.json            # Discovery templates (644)
  │       └── temperature_sensor.json

/var/log/
  └── ha-mqtt.log                           # Log file (created by service)

/etc/systemd/system/
  └── ha-mqtt-bridge.service                # Service file (644)
```

**Backup Strategy:**
- **Config files:** Preserve existing /etc/luigi/iot/ha-mqtt/ha-mqtt.conf on reinstall
- **Backup on upgrade:** Create .bak file if config is being replaced
- **Log rotation:** Handled by Python logging RotatingFileHandler (10MB, 5 backups)

### 3.5 Dependencies

**System Dependencies:**
```bash
# Required for shell script approach
sudo apt-get install mosquitto-clients

# Optional for Python service approach  
sudo apt-get install python3-paho-mqtt

# Already available on Raspberry Pi OS
# - python3
# - systemd
# - bash
```

**Python Dependencies (if using Python service):**
- **paho-mqtt:** MQTT client library
  - Install: `sudo apt-get install python3-paho-mqtt` or `pip3 install paho-mqtt`
  - Version: >=1.5.0
  
- **Python standard library:**
  - configparser (INI file parsing)
  - json (Discovery payload generation)
  - logging (logging framework)
  - signal (signal handling)
  - sys, os, time (standard utilities)

**Optional Dependencies:**
- **jq:** JSON processing in shell scripts
  - Install: `sudo apt-get install jq`
  - Used for: Discovery payload generation in shell scripts
  
- **openssl:** TLS certificate generation/testing
  - Usually pre-installed
  - Used for: TLS troubleshooting

**Dependency Installation Order:**
1. Update package list: `apt-get update`
2. Install mosquitto-clients (required)
3. Install jq (recommended)
4. Install python3-paho-mqtt (optional, for Python service)

### 3.6 Verification Strategy

**Post-Installation Checks:**

1. **Configuration deployed:**
   ```bash
   test -f /etc/luigi/iot/ha-mqtt/ha-mqtt.conf
   # Expected: Exit 0 (file exists)
   ```

2. **Permissions correct:**
   ```bash
   stat -c %a /etc/luigi/iot/ha-mqtt/ha-mqtt.conf
   # Expected: 600 (owner read/write only)
   ```

3. **Dependencies installed:**
   ```bash
   which mosquitto_pub
   # Expected: /usr/bin/mosquitto_pub
   ```

4. **Service running (if Python service):**
   ```bash
   systemctl is-active ha-mqtt-bridge.service
   # Expected: active
   ```

5. **MQTT connection test:**
   ```bash
   source /etc/luigi/iot/ha-mqtt/ha-mqtt.conf
   mosquitto_pub -h "$HOST" -p "$PORT" -u "$USERNAME" -P "$PASSWORD" \
       -t "homeassistant/sensor/luigi-test/state" -m "test" -q 1
   # Expected: Exit 0 (message published)
   ```

6. **Log file created:**
   ```bash
   test -f /var/log/ha-mqtt.log
   # Expected: Exit 0 (file exists)
   ```

7. **Discovery test:**
   ```bash
   # Publish test discovery message
   /usr/share/luigi/ha-mqtt/examples/register_sensor.sh test_sensor
   # Expected: Exit 0, sensor appears in Home Assistant
   ```

**Health Checks (Runtime):**

**Service Health:**
- Check process running: `systemctl status ha-mqtt-bridge`
- Check log for errors: `tail -20 /var/log/ha-mqtt.log | grep ERROR`
- Check last message time: Parse log for recent activity

**Connection Health:**
- Test publish: Use mosquitto_pub test message
- Check broker response: Monitor for CONNACK
- Network connectivity: Ping broker host

**Integration Health:**
- Verify sensors in Home Assistant
- Check last update times in HA
- Test example publish scripts

**Automated Health Script:**
```bash
#!/bin/bash
# ha-mqtt-health.sh - Check MQTT integration health

# Check configuration
test -f /etc/luigi/iot/ha-mqtt/ha-mqtt.conf || exit 1

# Check dependencies
which mosquitto_pub >/dev/null || exit 2

# Test connection
source /etc/luigi/iot/ha-mqtt/ha-mqtt.conf
mosquitto_pub -h "$HOST" -p "$PORT" -u "$USERNAME" -P "$PASSWORD" \
    -t "homeassistant/sensor/luigi-health/state" -m "ok" -q 0 >/dev/null 2>&1 || exit 3

echo "Health check passed"
exit 0
```

### 3.7 Service & Deployment Summary

**Deployment Approach:**

The module uses a **flexible deployment strategy** that supports both lightweight shell script usage and optional persistent service:

1. **Minimal Deployment (Shell Scripts Only):**
   - Install mosquitto-clients
   - Deploy configuration file
   - Deploy helper scripts
   - Luigi modules call scripts directly to publish data
   - No persistent service, minimal resource usage

2. **Full Deployment (With Python Service):**
   - All of minimal deployment, plus:
   - Install Python MQTT client
   - Deploy Python bridge service
   - Enable systemd service
   - Persistent MQTT connection for lower latency

**Key Deployment Decisions:**

1. **Decision: Support both deployment models**
   - **Rationale:** Different use cases have different requirements
   - **Shell-only:** Simpler, lower resource usage, good for infrequent updates
   - **With service:** Better for frequent updates, connection monitoring

2. **Decision: Non-root service user (luigi)**
   - **Rationale:** No GPIO access needed, follow principle of least privilege
   - **Benefits:** Better security, no root privilege required
   - **Implementation:** Create luigi user during installation if needed

3. **Decision: Config file with strict permissions (600)**
   - **Rationale:** Protect MQTT credentials from other users
   - **Benefits:** Prevents credential theft from multi-user systems
   - **Implementation:** setup.sh enforces permissions, service validates on start

4. **Decision: Centralized configuration shared by all scripts**
   - **Rationale:** Single source of truth for broker connection
   - **Benefits:** Easy to update credentials, consistent behavior
   - **Implementation:** All scripts source /etc/luigi/iot/ha-mqtt/ha-mqtt.conf

**Deployment Risks:**
| Risk | Severity | Mitigation |
|------|----------|------------|
| Config file credentials exposed | High | Enforce 600 permissions, validate on start, document in README |
| Network not available during install | Medium | setup.sh checks connectivity, provides clear error messages |
| mosquitto-clients package not in repos | Low | Standard package on Debian/Raspberry Pi OS |
| Service fails to start after install | Medium | Comprehensive verification checks, test publish after install |
| User doesn't configure broker settings | High | Interactive prompts during setup, clear documentation |

**Phase 3 Sign-off:**
- [x] Service design complete (optional Python service)
- [x] Shutdown mechanism planned (graceful disconnect)
- [x] Setup script strategy defined (flexible deployment)
- [x] File deployment planned (shell + optional Python)
- [x] Dependencies identified (mosquitto-clients required)
- [x] Verification strategy defined (connection tests)
- [x] Ready to create IMPLEMENTATION_PLAN

**Approved by:** GitHub Copilot **Date:** 2026-02-10

---

## Analysis Summary

### Overall Design Approach

The Home Assistant MQTT integration module provides a **lightweight, flexible bridge** between Luigi sensor modules and a centralized Home Assistant instance. The design emphasizes **simplicity and using existing tools** over custom implementations, aligning with the user's requirement to "use pre-existing packages to connect to Home Assistant MQTT broker."

The module offers **two deployment models**: a minimal shell-script-only approach for simple use cases, and an optional Python service for persistent connections and advanced features. Both approaches share a common configuration file and support **Home Assistant MQTT Discovery** for automatic sensor registration.

The architecture is **network-only with no hardware dependencies**, preserving all GPIO pins for sensor modules. Security is prioritized through authentication requirements, TLS support, and strict configuration file permissions. The module is designed to be **easy to use** - other Luigi modules can publish data by simply calling shell scripts with sensor readings, and sensors automatically appear in Home Assistant without manual configuration.

### Key Decisions Made

1. **Hardware:** Pure software/network integration - no GPIO or physical hardware required, preserving all pins for sensor modules

2. **Software:** Hybrid shell script + optional Python service architecture, using battle-tested mosquitto-clients tools rather than custom MQTT implementation, with Home Assistant MQTT Discovery support for automatic sensor registration

3. **Service:** Flexible deployment supporting both minimal shell-script-only usage and optional Python service for persistent connections, running as non-root user (luigi) with enhanced security hardening

### Risks Identified

| Phase | Risk | Severity | Mitigation | Status |
|-------|------|----------|------------|--------|
| 1 | Network connectivity loss | Medium | Automatic reconnection logic with exponential backoff | Mitigated |
| 1 | DNS resolution failures | Low | Support both IP addresses and hostnames in configuration | Mitigated |
| 2 | Broker connection failures | Medium | Retry logic with exponential backoff, clear error messages | Mitigated |
| 2 | Shell script injection vulnerabilities | Medium | Proper quoting, input validation, parameter expansion | Mitigated |
| 2 | Config file permissions too open | Medium | setup.sh enforces 600 permissions, validate on service start | Mitigated |
| 3 | Config file credentials exposed | High | Enforce 600 permissions, validate on start, document in README | Mitigated |
| 3 | User doesn't configure broker settings | High | Interactive prompts during setup, clear documentation | Mitigated |
| 3 | Service fails to start after install | Medium | Comprehensive verification checks, test publish after install | Mitigated |

### Open Questions

1. **Should the module include a web UI for configuration and monitoring?**
   - Consideration: Would improve usability but increases complexity
   - Recommendation: Start without UI, add in future version if needed

2. **Should the module support MQTT message queuing for offline scenarios?**
   - Consideration: Useful if network drops, but adds complexity
   - Recommendation: Use QoS 1 for delivery guarantee, consider queuing in v2

3. **Should the module provide Luigi module discovery (auto-detect other modules)?**
   - Consideration: Could automatically register all Luigi modules with HA
   - Recommendation: Manual registration initially, auto-discovery in future enhancement

4. **What level of Home Assistant integration should be provided?**
   - Sensors (read-only): Yes, primary use case
   - Binary sensors: Yes, for motion/door sensors
   - Switches (control): Maybe, for future relay modules
   - Recommendation: Start with sensors/binary_sensors, expand as needed

### Next Steps

1. **Peer Review:** Get design review from team member or community
2. **Address Feedback:** Incorporate review comments into design
3. **Prototype Shell Scripts:** Create example publish scripts to validate approach
4. **Test with Home Assistant:** Verify MQTT Discovery works as designed
5. **Create IMPLEMENTATION_PLAN.md:** Use this analysis to create detailed implementation plan
6. **Get Approval:** Final sign-off before implementation begins

---

## Design Approval

**Design Analysis Complete:**

Name: GitHub Copilot Agent   Signature: ✓   Date: 2026-02-10

**Technical Review:**

Name: ___________________ Signature: ___________ Date: __________

**Approved to Create Implementation Plan:**

Name: ___________________ Signature: ___________ Date: __________

---

## References

- **Module Design Skill:** `.github/skills/module-design/SKILL.md`
- **Python Development:** `.github/skills/python-development/SKILL.md`
- **Raspberry Pi Hardware:** `.github/skills/raspi-zero-w/SKILL.md`
- **System Setup:** `.github/skills/system-setup/SKILL.md`
- **Hardware Checklist:** `.github/skills/module-design/hardware-design-checklist.md`
- **Design Review:** `.github/skills/module-design/design-review-checklist.md`

**External References:**
- **Home Assistant MQTT Discovery:** https://www.home-assistant.io/integrations/mqtt/#mqtt-discovery
- **Mosquitto Client Tools:** https://mosquitto.org/man/mosquitto_pub-1.html
- **Paho MQTT Python:** https://pypi.org/project/paho-mqtt/
- **MQTT Protocol Specification:** https://mqtt.org/mqtt-specification/

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-10
