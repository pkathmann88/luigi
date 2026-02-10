# Design Analysis: [Module Name]

**Module:** [category]/[module-name]  
**Feature Request:** [Brief description or link to issue]  
**Analyst:** [Name]  
**Date:** [Date]  
**Status:** Analysis | Design Approved | Implementation Plan Created

---

## Purpose

This document captures the initial analysis performed when a feature request is received. The results of this analysis will inform the creation of the IMPLEMENTATION_PLAN.md.

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
[Summarize the feature request and what needs to be built]

**Module Purpose:**
[One clear sentence describing what this module does and why it exists]

**Example:** "Provide a generic MQTT bridge enabling any Luigi module to publish sensor data to Home Assistant without understanding MQTT protocols or broker details."

**Key Features:**
- Feature 1: [Description - include WHY this feature is important]
- Feature 2: [Description - include HOW it solves a problem]
- Feature 3: [Description - include WHO will use this]

**Use Cases:**
1. Use case 1: [Concrete scenario showing when/how this module is used]
2. Use case 2: [Include actor (who) and goal (what they achieve)]

**Success Criteria:**
- [ ] Criterion 1: [Measurable, testable criterion]
- [ ] Criterion 2: [Include acceptance test]
- [ ] Criterion 3: [Define "done"]

**Requirements Clarity Checklist:**
- [ ] Module purpose answers: What, Why, How, Who
- [ ] Each feature explains its value/rationale
- [ ] Use cases are concrete and realistic
- [ ] Success criteria are measurable and testable
- [ ] Requirements are clear enough for someone unfamiliar to understand

### 1.2 Hardware Component Analysis

**Required Components:**
| Component | Part Number | Voltage | Current | Qty | Purpose | Availability |
|-----------|-------------|---------|---------|-----|---------|--------------|
| Example: PIR Sensor | HC-SR501 | 5V | 50mA | 1 | Motion detection | In stock |
|  |  |  |  |  |  |  |

**Reference:** See `.github/skills/module-design/SKILL.md` (Component Selection)

**Component Verification:**
- [ ] All components compatible with 3.3V GPIO (or have level shifters planned)
- [ ] Datasheets reviewed
- [ ] Components available for purchase
- [ ] Estimated cost: $______

### 1.3 GPIO Pin Strategy

**Pin Requirements:**
| Function | Type | Special Requirements | Proposed Pin |
|----------|------|---------------------|--------------|
| Example: Sensor input | Input | Rising edge detection | GPIO23 |
|  |  |  |  |

**Reference:** See `.github/skills/raspi-zero-w/gpio-pinout.md`

**Pin Assignment Priority:**
1. General purpose pins (GPIO23, 24, 25) ✓
2. PWM pins (GPIO18, 12, 13) - if PWM needed
3. Special function (I2C, SPI, UART) - only if required

**GPIO Verification:**
- [ ] Pin selections follow Luigi priority system
- [ ] No conflicts with existing modules
- [ ] All pins documented with BCM and physical numbers

### 1.4 Wiring Design

**Wiring Diagram:**
```
Component Name       Raspberry Pi Zero W
--------------       -------------------
VCC          ------>  [5V (Pin 2) or 3.3V (Pin 1)]
GND          ------>  Ground (Pin [X])
Signal/Data  ------>  GPIO[##] (Pin [##])

Notes:
- [Inline components: resistors, diodes, etc.]
- [Safety warnings]
- [Component orientation]
```

**Reference:** See `.github/skills/module-design/hardware-design-checklist.md`

### 1.5 Power Budget

**Power Calculations:**
| Component | Voltage | Current | Notes |
|-----------|---------|---------|-------|
| Raspberry Pi Zero W | 5V | 150mA | Base |
| GPIO Outputs | 3.3V | ___mA | Calculate per pin |
| Component 1 | ___V | ___mA |  |
| Component 2 | ___V | ___mA |  |
| **TOTAL** |  | **___mA** |  |

**Power Supply:**
- Minimum required: ___A
- Recommended: ___A (2A+ recommended)
- External power needed: Yes / No

### 1.6 Safety Analysis

**Critical Safety Checks:**
- [ ] No 5V signals directly to GPIO inputs
- [ ] Current limiting resistors calculated (e.g., 220Ω for LEDs)
- [ ] Total GPIO current under 50mA
- [ ] Each pin under 16mA
- [ ] Polarity protection planned for inductive loads
- [ ] ESD protection considered for sensitive components

**Safety Concerns:**
1. [Any specific safety concerns identified]

**Mitigations:**
1. [How concerns will be addressed]

### 1.7 Hardware Analysis Summary

**Hardware Approach:**
[Brief summary of the hardware design approach]

**Key Hardware Decisions:**
1. Decision: [Why this approach]
2. Decision: [Why this approach]

**Hardware Risks:**
| Risk | Severity | Mitigation |
|------|----------|------------|
|  | Low/Med/High |  |

**Phase 1 Sign-off:**
- [ ] Requirements clearly defined
- [ ] Hardware components selected
- [ ] GPIO pins assigned
- [ ] Wiring diagram created
- [ ] Safety verified
- [ ] Ready for Phase 2

**Approved by:** ____________ **Date:** __________

---

## Phase 2: Software Architecture Analysis

**Goal:** Design software structure and architecture.

**Skills Used:** `module-design`, `python-development`

### 2.1 Module Structure Design

**File Structure:**
```
{category}/{module-name}/
├── README.md
├── setup.sh
├── {module-name}.py
├── {module-name}.service
├── {module-name}.conf.example
└── resources/ (if needed)
    └── ...
```

**Component Purpose Documentation:**

For each script, class, or significant component, document:
- **What:** Clear one-sentence description of what it does
- **Why:** Rationale - why does this component exist? What problem does it solve?
- **How:** Usage pattern - when and how is it used?
- **Who:** Intended users - which modules/users interact with it?
- **Key Responsibilities:** List 3-5 primary responsibilities

**Example:**
```
Script: sensor_monitor.py
- What: Main application monitoring DHT22 temperature sensor
- Why: Provides continuous temperature monitoring for home automation
- How: Runs as systemd service, polls sensor every 5 minutes
- Who: System (systemd), administrators (journalctl logs)
- Key Responsibilities:
  1. Initialize GPIO and DHT22 sensor
  2. Read temperature/humidity every poll interval
  3. Publish readings via luigi-publish
  4. Handle sensor errors gracefully with retry logic
  5. Respond to SIGTERM for graceful shutdown
```

**Class Architecture:**

**Config Class:**
- Purpose: Load and manage configuration
- Why: Centralize all configurable parameters, provide defaults
- Key attributes: [List main config parameters]
- Configuration file: `/etc/luigi/{category}/{module-name}/{module-name}.conf`

**GPIOManager Class:**
- Purpose: Abstract GPIO operations
- Why: Isolate GPIO library dependencies, enable mock testing
- Key methods: initialize(), setup_input(), setup_output(), cleanup()

**[Device]Sensor/Controller Class:**
- Purpose: Hardware-specific interface
- Why: Encapsulate device protocol, separate concerns from app logic
- Key methods: start(), stop(), read()/write()
- Device type: [Sensor/Actuator/Controller]

**[Module]App Class:**
- Purpose: Main application logic
- Why: Orchestrate all components, manage application lifecycle
- Key methods: __init__(), start(), stop(), _handle_signal()
- Main loop type: [Event-driven / Polling / State machine]

**Reference:** See `.github/skills/python-development/SKILL.md` (Class Architecture)

### 2.2 Configuration Design

**Configuration File Location:**
`/etc/luigi/{category}/{module-name}/{module-name}.conf`

**Configuration Structure:**
```ini
[Hardware]
# GPIO pin assignments (BCM numbering)
INPUT_PIN=23
OUTPUT_PIN=18

[Timing]
# Timing parameters in seconds
POLL_INTERVAL=1
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
| Parameter | Section | Type | Default | Description |
|-----------|---------|------|---------|-------------|
| INPUT_PIN | Hardware | int | 23 | Input sensor pin |
|  |  |  |  |  |

**Configuration Verification:**
- [ ] All user-changeable settings identified
- [ ] Sensible defaults chosen
- [ ] Configuration location follows Luigi standard
- [ ] INI format with clear sections

### 2.3 Error Handling Strategy

**Error Handling Plan:**

**GPIO Errors:**
- Approach: [Wrap in try/except, log and retry/exit]

**File Errors:**
- Approach: [Handle missing files, create directories as needed]

**Hardware Failures:**
- Approach: [Detection method, recovery strategy]

**Subprocess Errors:**
- Approach: [Timeout protection, return code checking]

**Reference:** See `.github/skills/python-development/SKILL.md` (Error Handling)

### 2.4 Logging Strategy

**Logging Configuration:**
- Log file: `/var/log/{module-name}.log`
- Rotation: 10MB max, 5 backups
- Levels used: DEBUG, INFO, WARNING, ERROR

**Key Log Points:**
1. Startup/shutdown
2. Hardware initialization
3. Main events (e.g., motion detected)
4. Errors and warnings
5. Configuration loaded

**Log Sanitization:**
- [ ] Length limits on logged data
- [ ] No sensitive information
- [ ] Newlines removed from user data

### 2.5 Security Design

**Security Measures:**
- [ ] subprocess.run() with list arguments (no shell=True)
- [ ] Path validation using os.path.commonpath()
- [ ] Log sanitization implemented
- [ ] Subprocess timeouts (10s default)
- [ ] File permissions appropriate (644 configs, 755 executables)
- [ ] Minimal privileges (root only if GPIO requires)

**Security Concerns:**
[Any specific security concerns]

**Reference:** See `.github/skills/module-design/SKILL.md` (Security Design)

### 2.6 Software Architecture Summary

**Architecture Pattern:**
[Event-driven / Polling / State machine / Command-response]

**Key Software Decisions:**
1. Decision: [Rationale]
2. Decision: [Rationale]

**Software Risks:**
| Risk | Severity | Mitigation |
|------|----------|------------|
|  | Low/Med/High |  |

**Phase 2 Sign-off:**
- [ ] Module structure designed
- [ ] Class architecture defined
- [ ] Configuration designed
- [ ] Error handling planned
- [ ] Logging strategy defined
- [ ] Security measures planned
- [ ] Ready for Phase 3

**Approved by:** ____________ **Date:** __________

---

## Phase 3: Service & Deployment Analysis

**Goal:** Design service integration and deployment strategy.

**Skills Used:** `module-design`, `system-setup`

### 3.1 systemd Service Design

**Service Unit File Design:**
```ini
[Unit]
Description={Module Name} Service
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

**Service Characteristics:**
- Type: simple (foreground application)
- User: root (GPIO access required)
- Restart: on-failure with 10s delay
- Logging: File + journalctl

**Reference:** See `.github/skills/module-design/SKILL.md` (Service Integration)

### 3.2 Shutdown Mechanism Design

**Signal Handlers:**
- SIGTERM: Triggered by `systemctl stop`
- SIGINT: Triggered by Ctrl+C (manual operation)

**Cleanup Steps:**
1. Stop main operation
2. GPIO.cleanup()
3. Close log files
4. Remove temporary files
5. Exit gracefully

**Timeout:** 30 seconds (TimeoutStopSec)

**Reference:** See `.github/skills/python-development/SKILL.md` (Signal Handlers)

### 3.3 Setup Script Strategy

**setup.sh Design:**

**Install Function:**
1. Check prerequisites
2. Install dependencies: [List dependencies]
3. Create directories
4. Deploy configuration file
5. Deploy Python script
6. Deploy service file
7. Enable and start service
8. Verify installation

**Uninstall Function:**
1. Stop service
2. Disable service
3. Remove service file
4. Remove application files
5. Interactive: Remove config/data?
6. Verify removal

**Status Function:**
1. Check service status
2. Check file installations
3. Display summary

**Reference:** See `.github/skills/system-setup/SKILL.md`

### 3.4 File Deployment Plan

**File Locations:**
| File | Source | Destination | Permissions |
|------|--------|-------------|-------------|
| {module-name}.py | Repo | /usr/local/bin/ | 755 |
| {module-name}.service | Repo | /etc/systemd/system/ | 644 |
| {module-name}.conf | Repo (example) | /etc/luigi/{category}/{module}/ | 644 |
| Resources | Repo | /usr/share/{module-name}/ | 644 |

**Backup Strategy:**
- Preserve existing config on reinstall
- Backup before overwriting (if applicable)

### 3.5 Dependencies

**System Dependencies:**
```bash
sudo apt-get install python3-rpi.gpio alsa-utils
```

**Python Dependencies:**
[Any additional Python packages needed]

**Optional Dependencies:**
[Any optional packages for enhanced features]

### 3.6 Verification Strategy

**Post-Installation Checks:**
1. Service running: `systemctl status {module-name}`
2. Files deployed: Check all destination files exist
3. Permissions correct: Verify file permissions
4. Log file created: Check `/var/log/{module-name}.log`
5. Configuration loaded: Verify config file read

**Health Checks:**
[Any ongoing health checks needed]

### 3.7 Service & Deployment Summary

**Deployment Approach:**
[Brief summary of deployment strategy]

**Key Deployment Decisions:**
1. Decision: [Rationale]
2. Decision: [Rationale]

**Deployment Risks:**
| Risk | Severity | Mitigation |
|------|----------|------------|
|  | Low/Med/High |  |

**Phase 3 Sign-off:**
- [ ] Service design complete
- [ ] Shutdown mechanism planned
- [ ] Setup script strategy defined
- [ ] File deployment planned
- [ ] Dependencies identified
- [ ] Verification strategy defined
- [ ] Ready to create IMPLEMENTATION_PLAN

**Approved by:** ____________ **Date:** __________

---

## Analysis Summary

### Overall Design Approach

**Summary:**
[2-3 paragraph summary of the overall design approach based on Phases 1-3]

### Key Decisions Made

1. **Hardware:** [Key hardware decision and rationale]
2. **Software:** [Key software decision and rationale]
3. **Service:** [Key service decision and rationale]

### Risks Identified

| Phase | Risk | Severity | Mitigation | Status |
|-------|------|----------|------------|--------|
| 1 | [Hardware risk] | High/Med/Low | [How to mitigate] | Open/Mitigated |
| 2 | [Software risk] | High/Med/Low | [How to mitigate] | Open/Mitigated |
| 3 | [Deployment risk] | High/Med/Low | [How to mitigate] | Open/Mitigated |

### Open Questions

1. [Question that needs resolution before implementation]
2. [Question that needs resolution before implementation]

### Next Steps

1. **Peer Review:** Get design review from team member
2. **Address Feedback:** Incorporate review comments
3. **Create IMPLEMENTATION_PLAN.md:** Use this analysis to create implementation plan
4. **Get Approval:** Final sign-off before implementation begins

---

## Design Approval

**Design Analysis Complete:**

Name: ___________________ Signature: ___________ Date: __________

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

---

**Document Version:** 1.0  
**Last Updated:** [Date]
