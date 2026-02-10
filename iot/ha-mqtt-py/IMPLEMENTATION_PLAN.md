# Implementation Plan: Home Assistant MQTT Integration (Python Edition)

**Module:** iot/ha-mqtt-py  
**Based on:** DESIGN_ANALYSIS.md (completed 2026-02-10)  
**Implementation Lead:** GitHub Copilot  
**Start Date:** 2026-02-10  
**Target Completion:** 2026-02-10  
**Status:** In Progress

---

## Overview

This implementation plan is created **AFTER** completing the DESIGN_ANALYSIS.md. It translates the approved design into actionable implementation tasks.

**Prerequisite:** DESIGN_ANALYSIS.md Phases 1-3 complete and approved ✓

**Workflow:**
```
Feature Request → DESIGN_ANALYSIS.md (Approved) → IMPLEMENTATION_PLAN.md (This document)
```

---

## Design Summary (from DESIGN_ANALYSIS.md)

### Module Purpose

Provide a Python-based MQTT bridge enabling Luigi modules to publish sensor data to Home Assistant with automatic discovery, featuring robust error handling, structured configuration, and seamless integration following Luigi's Python module patterns.

### Hardware Approach

**Software-only module - no physical hardware required**
- Components: None (network-only service)
- GPIO Pins: None required
- Safety measures: Network security (TLS, authentication, input validation)
- Power overhead: ~10-15mA for Python process, ~50mA peak WiFi

### Software Architecture

**Classes:**
- `Config`: Configuration management with INI file loading from `/etc/luigi/iot/ha-mqtt-py/ha-mqtt-py.conf`
- `MQTTClientManager`: MQTT connection management using paho-mqtt library
- `DiscoveryManager`: Home Assistant MQTT Discovery integration
- `HAMQTTApplication`: Main application orchestrating all components
- `MockMQTTClient`: Mock for development without broker

**Configuration:** `/etc/luigi/iot/ha-mqtt-py/ha-mqtt-py.conf`

**Architecture pattern:** Event-driven with paho-mqtt callbacks

**API Library:** Optional `luigi_mqtt.py` for other modules to import

### Service & Deployment

**Service type:** systemd with simple Type, auto-restart on failure
**Dependencies:** 
- python3 (pre-installed)
- python3-paho-mqtt (via apt)

**File locations:**
- Script: `/usr/local/bin/ha-mqtt-py.py` (755)
- Service: `/etc/systemd/system/ha-mqtt-py.service` (644)
- Config: `/etc/luigi/iot/ha-mqtt-py/ha-mqtt-py.conf` (600)
- Library: `/usr/local/lib/python3/dist-packages/luigi_mqtt.py` (644, optional)
- Logs: `/var/log/ha-mqtt-py.log` (with rotation)

---

## Implementation Phases

### Phase 1: Core Implementation

**Goal:** Implement the Python module following the design.

**Estimated Time:** 3-4 hours

**Skills Used:** `python-development`, `module-design`

**Based on:** DESIGN_ANALYSIS.md (all phases)

#### 1.1 Configuration Class Implementation
- [ ] Create ha-mqtt-py.py with header/docstring
- [ ] Implement Config class with INI file parsing
- [ ] Support sections: Broker, Authentication, Client, Topics, Discovery, Logging
- [ ] Variable expansion for {HOSTNAME}
- [ ] Fallback to defaults when config missing
- [ ] Log configuration source (file or defaults)
- [ ] Validate: `python3 -m py_compile ha-mqtt-py.py`

#### 1.2 MQTT Client Manager Implementation
- [ ] Import paho.mqtt.client (with try/except for mock)
- [ ] Implement MQTTClientManager class
- [ ] `connect()` method with authentication and TLS support
- [ ] `disconnect()` method
- [ ] `publish()` method with QoS and retain options
- [ ] `subscribe()` method (optional, for future use)
- [ ] `is_connected()` status check
- [ ] Connection callbacks: on_connect, on_disconnect, on_publish
- [ ] Automatic reconnection logic
- [ ] Validate syntax

#### 1.3 Discovery Manager Implementation
- [ ] Implement DiscoveryManager class
- [ ] `register_sensor()` method generating HA Discovery JSON
- [ ] `register_binary_sensor()` method for ON/OFF sensors
- [ ] `unregister_sensor()` method
- [ ] Support device_class, unit_of_measurement, icon, state_class
- [ ] Build discovery topics: `homeassistant/{component}/{node_id}/{object_id}/config`
- [ ] Track registered sensors (avoid duplicates)
- [ ] Validate syntax

#### 1.4 Main Application Class Implementation
- [ ] Implement HAMQTTApplication class
- [ ] `__init__()` initializing components
- [ ] `initialize()` setting up Config, MQTTClient, DiscoveryManager
- [ ] `run()` main event loop (keep alive while connected)
- [ ] `stop()` cleanup and disconnection
- [ ] Handle exceptions gracefully
- [ ] Validate syntax

#### 1.5 Logging Setup Implementation
- [ ] Implement setup_logging() function
- [ ] Console handler (INFO and above)
- [ ] RotatingFileHandler with rotation settings
- [ ] Log format with timestamp, level, message
- [ ] Create log directory if needed
- [ ] Handle permission errors gracefully

#### 1.6 Signal Handlers Implementation
- [ ] Implement signal_handler() function
- [ ] Register SIGTERM and SIGINT handlers
- [ ] Call app_instance.stop() on signal
- [ ] Exit with code 0
- [ ] Test with Ctrl+C

#### 1.7 Mock MQTT Support Implementation
- [ ] Implement MockMQTTClient class
- [ ] Mock methods: connect, disconnect, publish, subscribe
- [ ] Log operations instead of sending to broker
- [ ] Enable with try/except on paho import
- [ ] Set MOCK_MODE flag

#### 1.8 Main Entry Point Implementation
- [ ] Implement main() function
- [ ] Load config
- [ ] Setup logging
- [ ] Check permissions (optional: non-root works)
- [ ] Register signal handlers
- [ ] Create and initialize application
- [ ] Run main loop
- [ ] Handle exceptions and exit

#### 1.9 Complete Python Script Validation
- [ ] Run: `python3 -m py_compile ha-mqtt-py.py`
- [ ] Exit code 0, no errors
- [ ] Test in mock mode (no broker): `python3 ha-mqtt-py.py`
- [ ] Verify logging output
- [ ] Verify graceful shutdown with Ctrl+C

**Phase 1 Complete:** ____________ Date: __________

---

### Phase 2: Service Integration

**Goal:** Create systemd service and configuration files.

**Estimated Time:** 1 hour

**Skills Used:** `system-setup`, `module-design`

**Based on:** DESIGN_ANALYSIS.md Phase 3

#### 2.1 Service File Creation
- [ ] Create ha-mqtt-py.service
- [ ] Set Description, Documentation, After=network-online.target
- [ ] Configure Type=simple, User=root
- [ ] Set ExecStart=/usr/bin/python3 /usr/local/bin/ha-mqtt-py.py
- [ ] Configure Restart=on-failure, RestartSec=10
- [ ] Set StandardOutput/StandardError to log file
- [ ] Add security hardening: PrivateTmp, NoNewPrivileges, ProtectSystem
- [ ] Add ReadWritePaths for /var/log, /tmp, /etc/luigi

#### 2.2 Configuration Example Creation
- [ ] Create ha-mqtt-py.conf.example
- [ ] Add all sections: Broker, Authentication, Client, Topics, Discovery, Logging
- [ ] Include comments explaining each option
- [ ] Document default values
- [ ] Include examples for common scenarios
- [ ] Note about 600 permissions for security

**Phase 2 Complete:** ____________ Date: __________

---

### Phase 3: Setup Script Implementation

**Goal:** Create installation automation script.

**Estimated Time:** 2 hours

**Skills Used:** `system-setup`

**Based on:** DESIGN_ANALYSIS.md Phase 3

#### 3.1 Setup Script Structure
- [ ] Create setup.sh with shebang and error handling
- [ ] Set constants: MODULE_NAME, MODULE_CATEGORY, CONFIG_DIR
- [ ] Implement color output functions: log_info, log_error, log_warn
- [ ] Implement require_root() function
- [ ] Create main case statement for install/uninstall/status

#### 3.2 Install Function Implementation
- [ ] Check root privileges
- [ ] Install dependencies: apt-get install python3-pip python3-paho-mqtt
- [ ] Create config directory: /etc/luigi/iot/ha-mqtt-py/
- [ ] Copy ha-mqtt-py.conf.example to config dir
- [ ] Copy config if not exists (preserve existing)
- [ ] Set config permissions to 600
- [ ] Copy ha-mqtt-py.py to /usr/local/bin/ with 755 permissions
- [ ] Copy ha-mqtt-py.service to /etc/systemd/system/
- [ ] Reload systemd daemon
- [ ] Enable service (auto-start)
- [ ] Start service
- [ ] Show status and next steps

#### 3.3 Uninstall Function Implementation
- [ ] Check root privileges
- [ ] Stop service
- [ ] Disable service
- [ ] Remove service file
- [ ] Remove Python script
- [ ] Ask about config/log removal (preserve by default)
- [ ] Remove directories if empty
- [ ] Show uninstall summary

#### 3.4 Status Function Implementation
- [ ] Check if service file exists
- [ ] Show systemctl status
- [ ] Check if Python script exists
- [ ] Check if config exists
- [ ] Show config location
- [ ] Test MQTT connectivity if service running (optional)
- [ ] Display summary

#### 3.5 Setup Script Validation
- [ ] Run: `shellcheck setup.sh`
- [ ] Exit code 0, no errors
- [ ] Test syntax with: `bash -n setup.sh`

**Phase 3 Complete:** ____________ Date: __________

---

### Phase 4: Documentation Implementation

**Goal:** Create comprehensive documentation for the module.

**Estimated Time:** 2 hours

**Skills Used:** `module-design`

**Based on:** DESIGN_ANALYSIS.md (all phases)

#### 4.1 README.md Creation
- [ ] Create README.md with title and brief description
- [ ] Add **Contents** section listing directory files
- [ ] Add **Overview** section explaining functionality
- [ ] Add **Features** section with bullet points
- [ ] Add **Hardware Requirements** section (note: software-only)
- [ ] Add **Dependencies** section listing paho-mqtt
- [ ] Add **Installation** section with automated and manual steps
- [ ] Add **Configuration** section documenting all options
- [ ] Add **Usage** section with service management commands
- [ ] Add **How It Works** explaining operation flow
- [ ] Add **Integration Examples** showing how other modules use it
- [ ] Add **Troubleshooting** section with common issues
- [ ] Add **Architecture** section explaining class design
- [ ] Add **API Reference** if luigi_mqtt.py library included

#### 4.2 Code Documentation
- [ ] Add module-level docstring to ha-mqtt-py.py
- [ ] Add class docstrings with What/Why/How/Who format
- [ ] Add method docstrings with Args/Returns
- [ ] Add inline comments for complex logic
- [ ] Document signal handler behavior

#### 4.3 Configuration Documentation
- [ ] Ensure all config parameters have comments in example file
- [ ] Document default values and valid ranges
- [ ] Add usage examples in comments
- [ ] Document security considerations (600 permissions)

**Phase 4 Complete:** ____________ Date: __________

---

### Phase 5: Testing & Validation

**Goal:** Validate all components and integration.

**Estimated Time:** 1-2 hours

**Skills Used:** `python-development`, `system-setup`

#### 5.1 Syntax Validation
- [ ] Python: `python3 -m py_compile ha-mqtt-py.py` ✓
- [ ] Shell: `shellcheck setup.sh` ✓
- [ ] All files: No syntax errors

#### 5.2 Mock Mode Testing
- [ ] Run in mock mode without broker
- [ ] Verify configuration loading
- [ ] Verify logging output
- [ ] Verify signal handling (Ctrl+C)
- [ ] Verify graceful shutdown

#### 5.3 Installation Testing
- [ ] Run: `sudo ./setup.sh install`
- [ ] Verify all files deployed correctly
- [ ] Verify permissions correct (600 for config)
- [ ] Verify service enabled and started
- [ ] Check: `systemctl status ha-mqtt-py`

#### 5.4 Service Testing
- [ ] Test start: `systemctl start ha-mqtt-py`
- [ ] Test stop: `systemctl stop ha-mqtt-py`
- [ ] Test restart: `systemctl restart ha-mqtt-py`
- [ ] Test auto-restart: kill process, verify restart
- [ ] Test logs: `journalctl -u ha-mqtt-py -n 50`
- [ ] Test log file: `tail /var/log/ha-mqtt-py.log`

#### 5.5 Configuration Testing
- [ ] Edit config file
- [ ] Change broker host, port, credentials
- [ ] Restart service
- [ ] Verify new config applied
- [ ] Check logs for config loading messages

#### 5.6 Integration Testing (Optional - requires MQTT broker)
- [ ] Connect to real MQTT broker
- [ ] Publish test message
- [ ] Verify message received in broker
- [ ] Register test sensor via discovery
- [ ] Verify sensor appears in Home Assistant
- [ ] Test reconnection on network interruption

#### 5.7 Uninstallation Testing
- [ ] Run: `sudo ./setup.sh uninstall`
- [ ] Verify service stopped and removed
- [ ] Verify files removed (except config if preserved)
- [ ] Verify clean removal

**Phase 5 Complete:** ____________ Date: __________

---

### Phase 6: Final Verification

**Goal:** Complete integration verification and approval.

**Estimated Time:** 1 hour

**Skills Used:** `module-design`

#### 6.1 Design Review Checklist
- [ ] Review against hardware-design-checklist.md (N/A for software-only)
- [ ] Review against design-review-checklist.md
- [ ] Verify all design decisions implemented
- [ ] Verify all success criteria met

#### 6.2 Luigi System Integration
- [ ] Test discovery by root setup.sh
- [ ] Test: `./setup.sh status` shows ha-mqtt-py
- [ ] Test: `sudo ./setup.sh install iot/ha-mqtt-py` works
- [ ] Verify no conflicts with other modules

#### 6.3 Documentation Review
- [ ] README.md complete and accurate
- [ ] All sections present
- [ ] Examples work as documented
- [ ] Troubleshooting covers common issues

#### 6.4 Security Review
- [ ] No command injection vulnerabilities
- [ ] Input validation present
- [ ] Log sanitization implemented
- [ ] Config file permissions enforced
- [ ] No hardcoded secrets

#### 6.5 Performance Verification
- [ ] CPU usage acceptable (<5% idle)
- [ ] Memory usage reasonable (<50MB)
- [ ] No memory leaks in 24h test
- [ ] Log rotation working

#### 6.6 Final Approval
- [ ] All phases complete
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Ready for production use

**Phase 6 Complete:** ____________ Date: __________

---

## Implementation Timeline

| Phase | Description | Estimated Time | Status |
|-------|-------------|----------------|--------|
| Phase 1 | Core Implementation | 3-4 hours | 🔄 In Progress |
| Phase 2 | Service Integration | 1 hour | ⏳ Pending |
| Phase 3 | Setup Script | 2 hours | ⏳ Pending |
| Phase 4 | Documentation | 2 hours | ⏳ Pending |
| Phase 5 | Testing & Validation | 1-2 hours | ⏳ Pending |
| Phase 6 | Final Verification | 1 hour | ⏳ Pending |
| **Total** | | **10-12 hours** | |

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| paho-mqtt not available via apt | Low | Medium | Fallback to pip install, document both methods |
| Network connectivity issues | Medium | Medium | Implement automatic reconnection with exponential backoff |
| MQTT broker authentication issues | Medium | Low | Clear error messages, config validation, documentation |
| Log file permissions | Low | Low | Handle permission errors gracefully, fallback to console |
| Service restart loops | Low | High | RestartSec=10 in service file, comprehensive error handling |

---

## Success Criteria

Implementation is complete when:
- [x] All 6 phases complete with sign-offs
- [ ] Python syntax validates without errors
- [ ] Shell script passes shellcheck
- [ ] Service installs, starts, and runs reliably
- [ ] Configuration loading works correctly
- [ ] Logging functional with rotation
- [ ] Signal handling works (graceful shutdown)
- [ ] Documentation complete and accurate
- [ ] Integration examples provided
- [ ] Mock mode works without broker
- [ ] (Optional) Real MQTT connection and publishing verified

---

## Notes

**Design Approach:**
This module follows the mario.py pattern exactly:
- Config class for configuration management
- Manager class for external service (MQTT instead of GPIO)
- Application class for main logic
- Signal handlers for graceful shutdown
- Structured logging with rotation
- Mock support for development

**Differences from iot/ha-mqtt:**
- Python instead of shell scripts
- OOP design instead of procedural
- paho-mqtt library instead of mosquitto_pub command
- Integrated into single application instead of multiple CLI tools
- Can be used as library (luigi_mqtt.py) or standalone service

**Optional Enhancements (Future):**
- Luigi_mqtt.py shared library for other modules to import
- Web interface for monitoring/configuration
- Statistics and metrics collection
- Multiple broker support
- MQTT 5.0 support
- Advanced features (retained messages, last will, etc.)

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-10  
**Status:** Implementation Plan Created - Ready to Execute
