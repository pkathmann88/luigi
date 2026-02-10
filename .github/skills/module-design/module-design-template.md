# Luigi Module Design Template

Use this template to document your module design before implementation. Fill in all sections to ensure a complete design.

---

## Module Information

**Module Name:** ___________________________

**Category:** ___________________________ (motion-detection, sensors, automation, security, iot, system)

**Repository Path:** `{category}/{module-name}/`

**Designer:** ___________________________ **Date:** __________

---

## 1. Purpose and Overview

### Module Purpose
(One-sentence description)

___________________________________________

### Detailed Description
(2-3 paragraphs explaining what the module does and why it's useful)

___________________________________________

___________________________________________

___________________________________________

### Key Features
- Feature 1: Description
- Feature 2: Description
- Feature 3: Description

### Use Cases
1. Use case 1: Description
2. Use case 2: Description
3. Use case 3: Description

---

## 2. Hardware Design

### Required Components

| Component | Part Number | Quantity | Voltage | Current | Notes |
|-----------|-------------|----------|---------|---------|-------|
| Example: PIR Sensor | HC-SR501 | 1 | 5V | 50mA | Motion detection |
| | | | | | |
| | | | | | |

### GPIO Pin Assignment

| Function | BCM Pin | Physical Pin | Direction | Pull-Up/Down | Notes |
|----------|---------|--------------|-----------|--------------|-------|
| Example: PIR Data | GPIO23 | Pin 16 | Input | None | Rising edge detection |
| | | | | | |

### Wiring Diagram

```
Component Name       Raspberry Pi Zero W
--------------       -------------------
VCC          ------>  5V (Pin 2 or 4) or 3.3V (Pin 1 or 17)
GND          ------>  Ground (Pin 6, 9, 14, 20, 25, 30, 34, 39)
Signal/Data  ------>  GPIO## (Pin ##) - [BCM numbering]

Additional connections:
[Resistors, capacitors, other components]
```

### Power Budget

| Component | Voltage | Current | Notes |
|-----------|---------|---------|-------|
| Raspberry Pi Zero W | 5V | 150mA | Base consumption |
| GPIO Outputs (total) | 3.3V | ___mA | Calculate per pin |
| Component 1 | ___V | ___mA | |
| Component 2 | ___V | ___mA | |
| **TOTAL** | | **___mA** | |

**Power Supply Requirements:**
- Minimum: ___ A
- Recommended: ___ A
- External power needed: Yes / No

### Safety Considerations

**Voltage Safety:**
- [ ] All GPIO inputs are 3.3V compatible
- [ ] Level shifters added for 5V signals (if any)
- [ ] Voltage levels verified with multimeter

**Current Safety:**
- [ ] Current limiting resistors calculated and added
- [ ] Total GPIO current under 50mA
- [ ] Each pin under 16mA

**Polarity Safety:**
- [ ] VCC/GND connections verified
- [ ] Polarity of components marked in diagram
- [ ] Diode protection for inductive loads (if any)

**Other Safety:**
- [ ] No adjacent pin shorts
- [ ] Proper spacing on breadboard
- [ ] Pre-power continuity test planned

---

## 3. Software Architecture

### Module Structure

```
{category}/{module-name}/
├── README.md
├── setup.sh
├── {module-name}.py
├── {module-name}.service
├── {module-name}.conf.example
└── resources/                    (if needed)
    └── ...
```

### Class Design

**Config Class:**
- Purpose: Load and manage configuration
- Key methods:
  - `__init__(module_path)`: Initialize with module path
  - `_load_config()`: Load from `/etc/luigi/{category}/{module}/`
  - `_use_defaults()`: Fall back to default values

**GPIOManager Class:**
- Purpose: Abstract GPIO operations
- Key methods:
  - `initialize()`: Set GPIO mode (BCM)
  - `setup_input(pin)`: Configure input pin
  - `setup_output(pin)`: Configure output pin
  - `cleanup()`: Clean up GPIO resources

**{Device} Class(es):**
- Purpose: Hardware-specific interfaces
- Key methods:
  - `start()`: Begin operation
  - `stop()`: Stop operation
  - `read()` / `write()`: I/O operations
  - Device-specific methods

**{ModuleName}App Class:**
- Purpose: Main application logic
- Key methods:
  - `__init__(config)`: Initialize with configuration
  - `start()`: Start application
  - `stop()`: Graceful shutdown
  - `_handle_signal(sig, frame)`: Signal handler

### Configuration Design

**Configuration File Location:**
`/etc/luigi/{category}/{module-name}/{module-name}.conf`

**Configuration Format:**
```ini
[Hardware]
# GPIO pin assignments (BCM numbering)
INPUT_PIN=23
OUTPUT_PIN=18

[Timing]
# Timing parameters in seconds
POLL_INTERVAL=1
TIMEOUT=30
COOLDOWN=1800

[Files]
# File paths
DATA_DIR=/usr/share/{module-name}/
LOG_FILE=/var/log/{module-name}.log

[Logging]
# Logging configuration
LOG_LEVEL=INFO
LOG_MAX_BYTES=10485760
LOG_BACKUP_COUNT=5
```

**Configurable Parameters:**

| Parameter | Section | Type | Default | Valid Range | Description |
|-----------|---------|------|---------|-------------|-------------|
| INPUT_PIN | Hardware | int | 23 | GPIO pins | Input sensor pin |
| | | | | | |

### Error Handling Strategy

**GPIO Errors:**
- Wrap all GPIO operations in try/except
- Log error with context
- Graceful degradation or exit

**File Errors:**
- Handle missing files gracefully
- Create directories as needed
- Validate paths before use

**Subprocess Errors:**
- Use subprocess.run() with timeout
- Check return codes
- Log stderr output

### Logging Strategy

**Log File:** `/var/log/{module-name}.log`

**Log Rotation:** RotatingFileHandler with 10MB max, 5 backups

**Log Levels:**
- DEBUG: Detailed diagnostic information
- INFO: General informational messages
- WARNING: Warning messages
- ERROR: Error messages

**Log Sanitization:**
- Limit logged data length
- Remove newlines from user data
- No sensitive information (passwords, keys)

---

## 4. Service Integration

### systemd Service File

```ini
[Unit]
Description={Module Name} Service
Documentation=https://github.com/pkathmann88/luigi
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /usr/local/bin/{module-name}.py
Restart=on-failure
RestartSec=10
StandardOutput=append:/var/log/{module-name}.log
StandardError=append:/var/log/{module-name}.log

# Security hardening
PrivateTmp=yes
NoNewPrivileges=yes
ProtectSystem=strict
ReadWritePaths=/var/log /tmp /etc/luigi

[Install]
WantedBy=multi-user.target
```

### Service Management Commands

```bash
# Start service
sudo systemctl start {module-name}.service

# Stop service
sudo systemctl stop {module-name}.service

# Restart service
sudo systemctl restart {module-name}.service

# Check status
sudo systemctl status {module-name}.service

# Enable on boot
sudo systemctl enable {module-name}.service
```

### Shutdown Mechanism

- SIGTERM handler: Graceful shutdown on systemctl stop
- SIGINT handler: Graceful shutdown on Ctrl+C
- Cleanup steps:
  1. Stop monitoring/operation
  2. GPIO cleanup
  3. Close log files
  4. Remove temporary files

---

## 5. Setup Script Design

### Installation Steps

1. **Prerequisites Check**
   - Python 3 installed
   - Required system packages available

2. **Install Dependencies**
   - `sudo apt-get install python3-rpi.gpio`
   - (Other dependencies)

3. **Create Directories**
   - `/etc/luigi/{category}/{module-name}/`
   - `/usr/share/{module-name}/` (if resources needed)

4. **Deploy Configuration**
   - Copy `.conf.example` to `/etc/luigi/{category}/{module-name}/`
   - Set permissions: 644

5. **Deploy Application**
   - Copy Python script to `/usr/local/bin/`
   - Set permissions: 755
   - Deploy resources (if any)

6. **Deploy Service**
   - Copy service file to `/etc/systemd/system/`
   - systemctl daemon-reload
   - systemctl enable {module-name}

7. **Start Service**
   - systemctl start {module-name}

8. **Verify Installation**
   - Check service status
   - Check log file creation
   - Verify file permissions

### Uninstallation Steps

1. Stop service
2. Disable service
3. Remove service file
4. Remove application files
5. Ask about config/data removal
6. Remove config and data if confirmed
7. Verify removal

---

## 6. Testing Strategy

### Syntax Validation
```bash
# Python syntax
python3 -m py_compile {module-name}.py

# Shell script
shellcheck setup.sh
```

### Logic Testing (Mock GPIO)
- Test configuration loading
- Test error handling
- Test state management
- Test shutdown procedures

### Integration Testing (Hardware)
- Test GPIO initialization
- Test sensor/actuator operation
- Test full workflow
- Test service lifecycle

### Service Testing
- Test installation
- Test start/stop
- Test auto-start on boot
- Test recovery from failures

---

## 7. Documentation Plan

### README Sections

1. **Module Name and Description**
2. **Contents** - File list
3. **Overview** - Features and use cases
4. **Hardware Requirements** - Components list
5. **GPIO Configuration** - Pin assignments
6. **Wiring Diagram** - Connection diagram
7. **Installation** - Automated and manual
8. **Configuration** - Config file documentation
9. **Usage** - Service management commands
10. **How It Works** - Operation explanation
11. **Troubleshooting** - Common issues
12. **Architecture** - Code structure
13. **Dependencies** - Installation commands
14. **Notes** - Important information

### Wiring Diagram Content
- Component pin names
- Raspberry Pi pin numbers (BCM and physical)
- Wire connections with direction arrows
- Any inline components (resistors, diodes)
- Power supply connections
- Safety warnings

### Configuration Documentation
- All parameters explained
- Default values listed
- Valid ranges specified
- Modification instructions
- Restart requirements noted

---

## 8. Security Review

### Command Injection Prevention
- [ ] Use subprocess.run() with list arguments
- [ ] Never use os.system() or shell=True
- [ ] Validate all user inputs

### Path Traversal Prevention
- [ ] Use os.path.commonpath() for path validation
- [ ] Validate file paths before use
- [ ] No unchecked user-supplied paths

### Log Sanitization
- [ ] Limit logged data length
- [ ] Remove newlines from logged data
- [ ] No sensitive data in logs

### Subprocess Security
- [ ] Add timeouts to all subprocess calls
- [ ] Check return codes
- [ ] Capture and log stderr

### File Permissions
- [ ] Configs: 644
- [ ] Executables: 755
- [ ] Service files: 644
- [ ] No world-writable files

---

## 9. Integration and Compatibility

### GPIO Pin Conflicts
- [ ] No conflicts with existing modules
- [ ] Pin usage documented
- [ ] Alternative pins identified if needed

### Service Naming
- [ ] Unique service name
- [ ] Descriptive name
- [ ] No conflicts with system services

### Network Ports (if applicable)
- [ ] Ports documented
- [ ] No port conflicts
- [ ] Firewall requirements noted

### Module Independence
- [ ] Can install/uninstall independently
- [ ] Doesn't break other modules
- [ ] Shared dependencies noted

---

## 10. Performance Considerations

### CPU Usage
- Event-driven preferred: Yes / No
- Main loop sleep interval: ___ seconds
- Expected CPU usage: < ____%

### Memory Usage
- Expected RAM usage: ___ MB
- Log file max size: 10 MB (default)
- Resources cleaned up: Yes

### Storage Usage
- Log rotation: Enabled
- Temp file cleanup: Implemented
- SD card wear considered: Yes

### Network Usage (if applicable)
- Connection timeouts: ___ seconds
- Rate limiting: Yes / No
- Bandwidth estimate: ___ KB/s

---

## 11. Risks and Mitigations

### Risk 1: ___________________________
**Severity:** Low / Medium / High  
**Probability:** Low / Medium / High  
**Mitigation:** ___________________________

### Risk 2: ___________________________
**Severity:** Low / Medium / High  
**Probability:** Low / Medium / High  
**Mitigation:** ___________________________

### Risk 3: ___________________________
**Severity:** Low / Medium / High  
**Probability:** Low / Medium / High  
**Mitigation:** ___________________________

---

## 12. Open Questions

1. Question: ___________________________  
   Status: Open / Resolved  
   Answer: ___________________________

2. Question: ___________________________  
   Status: Open / Resolved  
   Answer: ___________________________

3. Question: ___________________________  
   Status: Open / Resolved  
   Answer: ___________________________

---

## 13. Timeline and Milestones

### Development Timeline
- Design: ___ days (Complete: ____ )
- Hardware assembly: ___ days
- Software implementation: ___ days
- Testing: ___ days
- Documentation: ___ days
- **Total:** ___ days

### Milestones
- [ ] Design complete and reviewed
- [ ] Hardware assembled and tested
- [ ] Python application implemented
- [ ] Service integration complete
- [ ] Setup script working
- [ ] Documentation complete
- [ ] Testing complete
- [ ] Deployed to production

---

## 14. Design Sign-Off

**Design Complete:**

Name: ___________________ Signature: ___________ Date: __________

**Technical Review:**

Name: ___________________ Signature: ___________ Date: __________

**Safety Review:**

Name: ___________________ Signature: ___________ Date: __________

**Approved for Implementation:**

Name: ___________________ Signature: ___________ Date: __________

---

## 15. Post-Implementation Notes

(To be filled in after implementation)

### Design Changes Made
- Change 1: ___________________________
- Change 2: ___________________________

### Issues Encountered
- Issue 1: ___________________________
  Resolution: ___________________________
- Issue 2: ___________________________
  Resolution: ___________________________

### Lessons Learned
- Lesson 1: ___________________________
- Lesson 2: ___________________________

### Final Test Results
- All tests passed: Yes / No
- Known issues: ___________________________
- Performance metrics: ___________________________

---

**Template Version:** 1.0  
**Last Updated:** 2024-02-10
