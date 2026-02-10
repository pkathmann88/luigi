# Implementation Plan: Home Assistant MQTT Integration

**Module:** iot/ha-mqtt  
**Based on:** DESIGN_ANALYSIS.md (completed 2026-02-10)  
**Implementation Lead:** Development Team  
**Start Date:** 2026-02-10  
**Target Completion:** TBD  
**Status:** Planning

---

## Overview

This implementation plan is created **AFTER** completing the DESIGN_ANALYSIS.md. It translates the approved design into actionable implementation tasks.

**Prerequisite:** DESIGN_ANALYSIS.md Phases 1-3 must be complete and approved. ✓

**Workflow:**
```
Feature Request → DESIGN_ANALYSIS.md (Approved) → IMPLEMENTATION_PLAN.md (This document)
```

---

## Design Summary (from DESIGN_ANALYSIS.md)

### Module Purpose

Provide a fully generic, decoupled MQTT bridge between Luigi sensor modules and a centralized Home Assistant instance. Any Luigi module can integrate without modifying ha-mqtt code or configuration through a parameter-driven generic interface and convention-based self-service registration.

### Hardware Approach

- **Components:** None - pure software/network integration
- **GPIO Pins:** None - network-only module preserving all GPIO pins for sensor modules
- **Safety measures:** Network security (TLS support, authentication, credential protection)
- **Power:** Minimal overhead (~5-10mA CPU, network transmission peaks)

### Software Architecture

- **Primary Interface:** Generic shell scripts using mosquitto-clients
  - `luigi-publish` - Universal sensor data publisher (parameter-driven)
  - `luigi-discover` - Sensor registration via MQTT Discovery
  - `luigi-mqtt-status` - Connection health diagnostics
- **Library Scripts:** 
  - `mqtt_helpers.sh` - Reusable MQTT operations
  - `ha_discovery_generator.sh` - Discovery payload generation
- **Optional Python Service:** `ha-mqtt-bridge.py` for persistent connections
- **Configuration:** `/etc/luigi/iot/ha-mqtt/ha-mqtt.conf` (600 permissions)
- **Discovery Directory:** `/etc/luigi/iot/ha-mqtt/sensors.d/` (drop-in descriptors)
- **Architecture pattern:** Generic interface with convention-based discovery

### Service & Deployment

- **Service type:** Optional systemd service (ha-mqtt-bridge.service)
- **Service user:** luigi (non-root)
- **Dependencies:** mosquitto-clients (required), python3-paho-mqtt (optional)
- **File locations:**
  - Scripts: `/usr/local/bin/` (luigi-publish, luigi-discover, luigi-mqtt-status)
  - Libraries: `/usr/local/lib/luigi/` (mqtt_helpers.sh, ha_discovery_generator.sh)
  - Config: `/etc/luigi/iot/ha-mqtt/`
  - Descriptors: `/etc/luigi/iot/ha-mqtt/sensors.d/`
  - Examples: `/usr/share/luigi/ha-mqtt/examples/`

---

## Phase 1: Testing Strategy Implementation

**Goal:** Implement testing approach for the module.

**Skills Used:** `python-development`, `system-setup`

**Based on:** DESIGN_ANALYSIS.md Phases 2 & 3

### 2.1 Syntax Validation

- [ ] Document shell script validation: `shellcheck setup.sh`
- [ ] Document shell script validation: `shellcheck bin/luigi-publish`
- [ ] Document shell script validation: `shellcheck bin/luigi-discover`
- [ ] Document shell script validation: `shellcheck bin/luigi-mqtt-status`
- [ ] Document shell script validation: `shellcheck lib/mqtt_helpers.sh`
- [ ] Document shell script validation: `shellcheck lib/ha_discovery_generator.sh`
- [ ] Document Python validation (if using service): `python3 -m py_compile ha-mqtt-bridge.py`

### 2.2 Functional Testing (No Hardware Required)

Since this is a network-only module, testing focuses on:

- [ ] **Configuration Loading Test:**
  - [ ] Test config file parsing
  - [ ] Test defaults when config missing
  - [ ] Test validation of required parameters
  - [ ] Test 600 permissions enforcement

- [ ] **luigi-publish Script Test:**
  - [ ] Test parameter validation (--sensor, --value required)
  - [ ] Test optional parameters (--unit, --device-class)
  - [ ] Test error handling for missing config
  - [ ] Test topic construction from sensor ID
  - [ ] Test return codes (0 for success, non-zero for errors)

- [ ] **luigi-discover Script Test:**
  - [ ] Test descriptor scanning from sensors.d/
  - [ ] Test JSON parsing and validation
  - [ ] Test discovery payload generation
  - [ ] Test handling of malformed descriptors

- [ ] **luigi-mqtt-status Script Test:**
  - [ ] Test connection check logic
  - [ ] Test error message generation
  - [ ] Test return codes for different failure modes

### 2.3 Integration Tests (Requires MQTT Broker)

- [ ] **MQTT Connection Test:**
  - [ ] Test successful connection to broker
  - [ ] Test authentication with credentials
  - [ ] Test connection failure handling
  - [ ] Test TLS encryption (if configured)

- [ ] **Publish Test:**
  - [ ] Publish test message with luigi-publish
  - [ ] Verify message received by broker
  - [ ] Test QoS 0, 1, 2 settings
  - [ ] Test retained message flag

- [ ] **Discovery Test:**
  - [ ] Register test sensor with luigi-discover
  - [ ] Verify discovery message format
  - [ ] Verify sensor appears in Home Assistant
  - [ ] Test re-registration after descriptor change

- [ ] **Service Test (if using Python service):**
  - [ ] Test service start/stop
  - [ ] Test automatic reconnection on network loss
  - [ ] Test periodic descriptor scanning
  - [ ] Test log rotation

### 2.4 End-to-End Scenario Tests

- [ ] **Scenario 1: New Module Integration**
  - [ ] Create test sensor descriptor
  - [ ] Install descriptor to sensors.d/
  - [ ] Run luigi-discover
  - [ ] Publish test value with luigi-publish
  - [ ] Verify in Home Assistant

- [ ] **Scenario 2: Module Update**
  - [ ] Modify existing descriptor
  - [ ] Re-run discovery
  - [ ] Verify changes reflected in HA

- [ ] **Scenario 3: Module Removal**
  - [ ] Remove descriptor from sensors.d/
  - [ ] Verify sensor still in HA (manual cleanup required)
  - [ ] Document removal process in README

**Phase 1 Complete:** ____________ Date: __________

---

## Phase 2: Core Implementation

**Goal:** Implement the module following the design.

**Skills Used:** `system-setup`, `python-development` (optional)

**Based on:** DESIGN_ANALYSIS.md (all phases)

### 4.1 No Hardware Assembly Required

✓ This is a network-only module - no physical hardware to assemble.

### 4.2 Shell Script Implementation

**4.2.1 Implement mqtt_helpers.sh Library**

- [ ] Function: load_config()
  - [ ] Parse ha-mqtt.conf INI format
  - [ ] Export variables for script use
  - [ ] Validate required parameters present
  - [ ] Return error if config invalid

- [ ] Function: build_topic()
  - [ ] Construct MQTT topic from sensor ID and type
  - [ ] Follow pattern: {BASE_TOPIC}/{type}/{DEVICE_PREFIX}-{HOSTNAME}/{sensor_id}/state
  - [ ] Support discovery topics
  - [ ] Return constructed topic string

- [ ] Function: mqtt_publish()
  - [ ] Wrapper around mosquitto_pub
  - [ ] Handle authentication (-u, -P)
  - [ ] Handle TLS (--cafile if configured)
  - [ ] Apply QoS setting
  - [ ] Timeout handling
  - [ ] Return status code

- [ ] Function: validate_sensor_id()
  - [ ] Check format (alphanumeric, underscore, hyphen)
  - [ ] Prevent path traversal attempts
  - [ ] Return validation result

- [ ] Validate: `shellcheck lib/mqtt_helpers.sh`

**4.2.2 Implement luigi-publish Script**

- [ ] Parse command-line arguments (--sensor, --value, --unit, --device-class, --attributes)
- [ ] Validate required parameters
- [ ] Load configuration via mqtt_helpers.sh
- [ ] Build topic for sensor state
- [ ] Publish value to MQTT broker
- [ ] Handle errors with helpful messages
- [ ] Return appropriate exit codes
- [ ] Add usage help (-h, --help)
- [ ] Validate: `shellcheck bin/luigi-publish`

**4.2.3 Implement ha_discovery_generator.sh Library**

- [ ] Function: generate_sensor_discovery()
  - [ ] Accept descriptor JSON as input
  - [ ] Generate Home Assistant sensor discovery payload
  - [ ] Include device information
  - [ ] Include sensor metadata (unit, class, icon)
  - [ ] Return JSON discovery payload

- [ ] Function: generate_binary_sensor_discovery()
  - [ ] Generate binary_sensor discovery payload
  - [ ] Support ON/OFF, motion, door, etc.

- [ ] Function: validate_descriptor()
  - [ ] Check required fields present
  - [ ] Validate JSON syntax
  - [ ] Return validation errors

- [ ] Validate: `shellcheck lib/ha_discovery_generator.sh`

**4.2.4 Implement luigi-discover Script**

- [ ] Scan sensors.d/ directory for *.json files
- [ ] Parse each descriptor
- [ ] Validate descriptor format
- [ ] Generate discovery payload using ha_discovery_generator.sh
- [ ] Publish discovery to HA discovery topic
- [ ] Use retained flag for discovery messages
- [ ] Handle errors gracefully (skip invalid descriptors)
- [ ] Report summary (X sensors registered, Y failed)
- [ ] Support --force flag to re-register all sensors
- [ ] Add usage help
- [ ] Validate: `shellcheck bin/luigi-discover`

**4.2.5 Implement luigi-mqtt-status Script**

- [ ] Load configuration
- [ ] Attempt test connection to broker
- [ ] Check DNS resolution of broker host
- [ ] Test authentication
- [ ] Publish test message
- [ ] Report connection status with colors
- [ ] Report detailed error for failures (DNS, auth, network, firewall)
- [ ] Return machine-readable exit codes
- [ ] Add usage help
- [ ] Validate: `shellcheck bin/luigi-mqtt-status`

### 4.3 Python Service Implementation (Optional)

**Only implement if persistent connection desired:**

- [ ] **Config Class:**
  - [ ] Load ha-mqtt.conf INI file
  - [ ] Provide defaults for all settings
  - [ ] Validate configuration values
  - [ ] Log configuration source

- [ ] **MQTTManager Class:**
  - [ ] Initialize paho-mqtt client
  - [ ] Connect with authentication
  - [ ] Handle connection callbacks (on_connect, on_disconnect)
  - [ ] Implement reconnection logic with exponential backoff
  - [ ] Publish message with QoS
  - [ ] Subscribe to topics (for future command support)

- [ ] **HADiscovery Class:**
  - [ ] Load descriptors from sensors.d/
  - [ ] Generate discovery payloads
  - [ ] Register sensors on startup
  - [ ] Periodic scan for new/changed descriptors
  - [ ] Handle descriptor removal

- [ ] **HAMQTTBridge Class:**
  - [ ] Initialize all components
  - [ ] Start MQTT connection
  - [ ] Register initial sensors
  - [ ] Periodic descriptor scanning loop
  - [ ] Handle signals (SIGTERM/SIGINT) for graceful shutdown
  - [ ] Cleanup on exit

- [ ] **main() function:**
  - [ ] Parse command-line arguments
  - [ ] Load configuration
  - [ ] Setup logging
  - [ ] Create and start bridge
  - [ ] Handle exceptions

- [ ] Validate: `python3 -m py_compile ha-mqtt-bridge.py`

### 4.4 Service File Implementation (Optional)

- [ ] Create ha-mqtt-bridge.service
- [ ] Set Type=simple
- [ ] Set User=luigi (create user if needed)
- [ ] Set ExecStart=/usr/bin/python3 /usr/local/bin/ha-mqtt-bridge.py
- [ ] Set Restart=on-failure, RestartSec=10
- [ ] Configure logging to file and journalctl
- [ ] Add security hardening (PrivateTmp, NoNewPrivileges, ProtectSystem, etc.)
- [ ] Set After=network-online.target, Wants=network-online.target
- [ ] Add WantedBy=multi-user.target

### 4.5 Integration Testing

- [ ] **Installation Test:**
  - [ ] Run: `sudo ./setup.sh install`
  - [ ] Verify all files deployed
  - [ ] Verify permissions correct (especially config 600)
  - [ ] Verify examples installed

- [ ] **Configuration Test:**
  - [ ] Edit ha-mqtt.conf with test broker settings
  - [ ] Test invalid config handled gracefully
  - [ ] Test missing config uses defaults where appropriate

- [ ] **Basic Functionality Test:**
  - [ ] Run: `luigi-mqtt-status`
  - [ ] Verify connection succeeds or reports clear error
  - [ ] Create test descriptor in sensors.d/
  - [ ] Run: `luigi-discover`
  - [ ] Verify sensor registered in Home Assistant
  - [ ] Run: `luigi-publish --sensor test_sensor --value 42`
  - [ ] Verify value appears in Home Assistant

- [ ] **Service Test (if installed):**
  - [ ] Start service: `sudo systemctl start ha-mqtt-bridge`
  - [ ] Check status: `sudo systemctl status ha-mqtt-bridge`
  - [ ] Verify logs: `sudo journalctl -u ha-mqtt-bridge -f`
  - [ ] Add new descriptor while service running
  - [ ] Wait for SCAN_INTERVAL, verify auto-discovery
  - [ ] Stop service: `sudo systemctl stop ha-mqtt-bridge`

- [ ] **Error Handling Test:**
  - [ ] Test with invalid broker host
  - [ ] Test with wrong credentials
  - [ ] Test with malformed descriptor
  - [ ] Verify helpful error messages

- [ ] **Uninstallation Test:**
  - [ ] Run: `sudo ./setup.sh uninstall`
  - [ ] Verify files removed
  - [ ] Verify config preserved (if user chose)
  - [ ] Verify clean removal

**Phase 2 Complete:** ____________ Date: __________

---

## Phase 3: Documentation Implementation

**Goal:** Create comprehensive documentation for the module.

**Skills Used:** `module-design`

**Based on:** DESIGN_ANALYSIS.md (all phases)

### 3.1 README.md Creation

Create complete module README with all required sections:

- [ ] **Overview** - What ha-mqtt does, why it exists
- [ ] **Contents** - List of files in directory
- [ ] **Key Features** - Generic interface, zero-coupling, convention-based discovery
- [ ] **Use Cases** - Motion detection, temperature monitoring, system monitoring examples
- [ ] **Architecture** - Diagram showing Luigi modules → ha-mqtt → Home Assistant flow
- [ ] **Hardware Requirements** - Network connectivity only (no GPIO)
- [ ] **Dependencies** - mosquitto-clients (required), python3-paho-mqtt (optional)
- [ ] **Installation** - Automated and manual installation steps
- [ ] **Configuration** - Complete parameter documentation with examples
- [ ] **Usage** - How to integrate any Luigi module:
  - [ ] Document 4-step integration pattern
  - [ ] Document luigi-publish usage with examples
  - [ ] Document descriptor format with all fields
  - [ ] Document luigi-discover for troubleshooting
- [ ] **How It Works** - Explain generic interface, descriptor discovery, MQTT topics
- [ ] **Troubleshooting** - Common issues and solutions:
  - [ ] Connection failures
  - [ ] Authentication errors
  - [ ] Sensor not appearing in HA
  - [ ] Permission issues
- [ ] **Home Assistant Setup** - Guide for configuring HA side:
  - [ ] MQTT broker setup
  - [ ] User/password creation
  - [ ] ACL configuration recommendations
- [ ] **Security** - Credential protection, TLS setup, network isolation
- [ ] **Integration Examples** - Complete examples for different sensor types
- [ ] **Notes** - Important operational notes
- [ ] **Future Enhancements** - Potential improvements

### 3.2 Integration Guide

Create examples/integration-guide.md:

- [ ] Document generic interface pattern
- [ ] Show complete integration example (temperature sensor)
- [ ] Document descriptor format specification
- [ ] Include descriptor field reference table
- [ ] Show multiple sensor type examples (binary_sensor, sensor, etc.)

### 3.3 Descriptor Format Documentation

Create examples/sensors.d/README.md:

- [ ] Document JSON schema for descriptors
- [ ] Document required vs optional fields
- [ ] Document supported sensor types (sensor, binary_sensor, etc.)
- [ ] Document device_class values for each type
- [ ] Include validation rules
- [ ] Show complete examples for common sensor types

### 3.4 Code Documentation

- [ ] Add comprehensive comments to all shell scripts
- [ ] Document function purposes, parameters, return values
- [ ] Add usage examples in script headers
- [ ] Document library function signatures
- [ ] Add Python docstrings (if implementing service)

### 3.5 Configuration Documentation

- [ ] Ensure ha-mqtt.conf.example has detailed comments
- [ ] Document default values and valid ranges
- [ ] Include security notes for sensitive parameters
- [ ] Document ${HOSTNAME} variable expansion

**Phase 3 Complete:** ____________ Date: __________

---

## Phase 4: Setup & Deployment Implementation

**Goal:** Create installation automation and deployment scripts.

**Skills Used:** `system-setup`

**Based on:** DESIGN_ANALYSIS.md Phase 3

### 1.1 Create setup.sh Script

- [ ] Implement install() function:
  - [ ] Check prerequisites (bash, systemd, network)
  - [ ] Install mosquitto-clients with apt-get
  - [ ] Create directory structure (/etc/luigi/iot/ha-mqtt/, sensors.d/, /usr/local/bin/, /usr/local/lib/luigi/)
  - [ ] Deploy configuration file with 600 permissions
  - [ ] Deploy bin/ scripts (luigi-publish, luigi-discover, luigi-mqtt-status) to /usr/local/bin/ with 755
  - [ ] Deploy lib/ scripts (mqtt_helpers.sh, ha_discovery_generator.sh) to /usr/local/lib/luigi/ with 644
  - [ ] Deploy example descriptors to /usr/share/luigi/ha-mqtt/examples/sensors.d/
  - [ ] Optional: Deploy Python service and systemd unit if user wants persistent connection
  - [ ] Prompt user to configure broker settings
  - [ ] Test MQTT connection with luigi-mqtt-status
  - [ ] Verify installation with status checks

- [ ] Implement uninstall() function:
  - [ ] Stop and disable service (if installed)
  - [ ] Remove service file from /etc/systemd/system/
  - [ ] Remove scripts from /usr/local/bin/
  - [ ] Remove libraries from /usr/local/lib/luigi/
  - [ ] Remove examples from /usr/share/luigi/ha-mqtt/
  - [ ] Interactive: Ask about removing config and sensor descriptors
  - [ ] Optional: Ask about removing mosquitto-clients package
  - [ ] Verify removal

- [ ] Implement status() function:
  - [ ] Check if scripts are installed
  - [ ] Check if config file exists
  - [ ] Check MQTT connectivity with luigi-mqtt-status
  - [ ] Show service status (if installed)
  - [ ] Display sensor descriptor count
  - [ ] Show configuration summary (broker host, connection status)

- [ ] Add error handling and root privilege checking
- [ ] Add colored output (GREEN/YELLOW/RED/BLUE)
- [ ] Validate with: `shellcheck setup.sh`

### 1.2 Create Configuration Example

- [ ] Create ha-mqtt.conf.example with all sections:
  - [ ] [Broker] - HOST, PORT, TLS, CA_CERT
  - [ ] [Authentication] - USERNAME, PASSWORD (with security note)
  - [ ] [Client] - CLIENT_ID, KEEPALIVE, QOS, CLEAN_SESSION
  - [ ] [Topics] - BASE_TOPIC, DISCOVERY_PREFIX, DEVICE_PREFIX
  - [ ] [Device] - DEVICE_NAME, DEVICE_MODEL, MANUFACTURER, SW_VERSION
  - [ ] [Discovery] - SENSORS_DIR, SCAN_INTERVAL
  - [ ] [Connection] - RECONNECT_DELAY_MIN, RECONNECT_DELAY_MAX, CONNECTION_TIMEOUT
  - [ ] [Logging] - LOG_FILE, LOG_LEVEL, LOG_MAX_BYTES, LOG_BACKUP_COUNT
- [ ] Document each parameter with clear comments
- [ ] Include examples and security warnings

### 1.3 File Deployment Checklist

- [ ] luigi-publish → /usr/local/bin/ (755)
- [ ] luigi-discover → /usr/local/bin/ (755)
- [ ] luigi-mqtt-status → /usr/local/bin/ (755)
- [ ] mqtt_helpers.sh → /usr/local/lib/luigi/ (644)
- [ ] ha_discovery_generator.sh → /usr/local/lib/luigi/ (644)
- [ ] ha-mqtt.conf.example → /etc/luigi/iot/ha-mqtt/ha-mqtt.conf (600)
- [ ] ha-mqtt-bridge.py → /usr/local/bin/ (755, optional)
- [ ] ha-mqtt-bridge.service → /etc/systemd/system/ (644, optional)
- [ ] Example descriptors → /usr/share/luigi/ha-mqtt/examples/sensors.d/ (644)

**Phase 4 Complete:** ____________ Date: __________

---

## Phase 5: Final Verification & Integration

**Goal:** Complete final review and integrate with Luigi system.

**Skills Used:** `module-design`

**Based on:** Complete module implementation

### 5.1 Design Review Checklist

Complete `.github/skills/module-design/design-review-checklist.md`:

- [ ] **Requirements Review:**
  - [ ] All features from DESIGN_ANALYSIS implemented
  - [ ] All success criteria met
  - [ ] Use cases validated

- [ ] **Software Architecture Review:**
  - [ ] Generic interface works for any sensor type
  - [ ] Convention-based discovery functions properly
  - [ ] Zero-coupling verified (new sensors don't require ha-mqtt changes)
  - [ ] Configuration follows Luigi standards
  - [ ] Error handling comprehensive
  - [ ] Logging strategy implemented
  - [ ] Security measures in place

- [ ] **Service Review:**
  - [ ] Service file follows systemd best practices (if used)
  - [ ] Runs as non-root user
  - [ ] Security hardening enabled
  - [ ] Graceful shutdown implemented
  - [ ] Restart policy appropriate

- [ ] **Setup Script Review:**
  - [ ] Install function complete and tested
  - [ ] Uninstall function complete and tested
  - [ ] Status function accurate
  - [ ] Error handling robust
  - [ ] User feedback clear

- [ ] **Documentation Review:**
  - [ ] README complete with all sections
  - [ ] Integration guide clear and accurate
  - [ ] Descriptor format well-documented
  - [ ] Configuration parameters documented
  - [ ] Troubleshooting section helpful
  - [ ] Examples functional

- [ ] **Security Review:**
  - [ ] No shell injection vulnerabilities
  - [ ] Path traversal prevention implemented
  - [ ] Log sanitization in place
  - [ ] Subprocess timeouts added
  - [ ] File permissions appropriate (especially config 600)
  - [ ] No hardcoded secrets
  - [ ] TLS configuration secure

### 5.2 Luigi System Integration

- [ ] **Central Setup Integration:**
  - [ ] Test: `sudo ./setup.sh install iot/ha-mqtt` from repository root
  - [ ] Verify module discovered by central setup script
  - [ ] Test: `sudo ./setup.sh status` shows ha-mqtt status

- [ ] **No GPIO Conflicts:**
  - [ ] Verify: Network-only module has no GPIO requirements
  - [ ] Verify: No conflicts with other modules possible

- [ ] **Service Management:**
  - [ ] Verify: Service starts on boot (if installed)
  - [ ] Verify: Service recovers from failures
  - [ ] Verify: Service stops cleanly on shutdown

- [ ] **Cross-Module Integration:**
  - [ ] Test: Create descriptor for Mario module
  - [ ] Test: Mario module can call luigi-publish
  - [ ] Test: Sensor appears in Home Assistant
  - [ ] Test: Mario events publish successfully

### 5.3 Performance & Security Verification

- [ ] **Performance:**
  - [ ] CPU usage: < 5% during normal operation
  - [ ] Memory usage: < 50MB for service (if running)
  - [ ] Network usage: Minimal (only during publishes)
  - [ ] No memory leaks over 24-hour test

- [ ] **Security:**
  - [ ] Config file has 600 permissions enforced
  - [ ] No credentials in logs
  - [ ] No vulnerabilities in shellcheck output
  - [ ] Input validation prevents injection
  - [ ] TLS works when configured

- [ ] **Reliability:**
  - [ ] Handles broker outages gracefully
  - [ ] Reconnects automatically
  - [ ] Log rotation working (if service)
  - [ ] Handles network interruptions

### 5.4 Final Approval Checklist

- [ ] **All Phases Complete:**
  - [x] Phase 1: Setup & Deployment ✓
  - [x] Phase 2: Testing Strategy ✓
  - [x] Phase 3: Documentation ✓
  - [x] Phase 4: Core Implementation ✓
  - [x] Phase 5: Final Verification ✓

- [ ] **Quality Gates:**
  - [ ] All tests passed ✓
  - [ ] Documentation complete ✓
  - [ ] Security review passed ✓
  - [ ] Performance acceptable ✓
  - [ ] Peer review complete ✓

- [ ] **Integration Verified:**
  - [ ] Works with Luigi central setup ✓
  - [ ] Other modules can integrate ✓
  - [ ] No breaking changes ✓

**Approved for Production:** ____________ Date: __________

---

## Implementation Timeline

| Phase | Description | Estimated | Actual | Status |
|-------|-------------|-----------|--------|--------|
| 1 | Testing Strategy | 6 hours |  | ⬜ Not Started |
| 2 | Core Implementation | 16 hours |  | ⬜ Not Started |
| 3 | Documentation | 10 hours |  | ⬜ Not Started |
| 4 | Setup & Deployment | 8 hours |  | ⬜ Not Started |
| 5 | Final Verification | 6 hours |  | ⬜ Not Started |
| **Total** | | **46 hours** | | |

**Breakdown:**
- Shell scripts (luigi-publish, luigi-discover, luigi-mqtt-status): 8 hours
- Library scripts (mqtt_helpers.sh, ha_discovery_generator.sh): 4 hours
- Optional Python service: 4 hours
- Setup script: 6 hours
- Configuration and examples: 2 hours
- Testing: 6 hours
- Documentation: 10 hours
- Integration and verification: 6 hours

---

## Issues and Resolutions

| Date | Issue | Resolution | Status |
|------|-------|------------|--------|
| | | | Open/Resolved |

---

## Changes from Design

| Section | Change Made | Reason | Approved By |
|---------|-------------|--------|-------------|
| | | | |

**Note:** Any significant deviations from DESIGN_ANALYSIS.md must be documented here with rationale and approval.

---

## Lessons Learned

[Document insights gained during implementation - update as work progresses]

**To be completed during implementation:**
- Shell script patterns that worked well
- MQTT client tool quirks discovered
- Home Assistant MQTT Discovery gotchas
- Descriptor format challenges
- Integration patterns that emerged
- Testing approaches that proved valuable

---

## References

- **Design Analysis:** `DESIGN_ANALYSIS.md` (prerequisite - approved 2026-02-10)
- **Module Design Skill:** `.github/skills/module-design/SKILL.md`
- **Python Development:** `.github/skills/python-development/SKILL.md`
- **System Setup:** `.github/skills/system-setup/SKILL.md`
- **Design Review:** `.github/skills/module-design/design-review-checklist.md`

**External References:**
- **Home Assistant MQTT Discovery:** https://www.home-assistant.io/integrations/mqtt/#mqtt-discovery
- **Mosquitto Client Tools:** https://mosquitto.org/man/mosquitto_pub-1.html
- **Paho MQTT Python:** https://pypi.org/project/paho-mqtt/
- **MQTT Protocol Specification:** https://mqtt.org/mqtt-specification/

---

**Document Version:** 1.0  
**Created:** 2026-02-10  
**Last Updated:** 2026-02-10

