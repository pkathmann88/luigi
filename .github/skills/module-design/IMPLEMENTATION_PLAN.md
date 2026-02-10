# Implementation Plan: [Module Name]

**Module:** [category]/[module-name]  
**Created:** [Date]  
**Designer:** [Name]  
**Status:** Planning | In Progress | Complete

---

## Overview

### Module Purpose
[One-sentence description of what this module does]

### Key Features
- Feature 1
- Feature 2
- Feature 3

### Use Cases
1. Use case 1
2. Use case 2

---

## Phase 1: Hardware Design & Safety Verification

**Goal:** Design safe hardware connections and verify electrical specifications.

**Skills Used:** `module-design`, `raspi-zero-w`

### 1.1 Component Selection
**Task:** Select and document all hardware components.

**Components:**
| Component | Part Number | Voltage | Current | Qty | Notes |
|-----------|-------------|---------|---------|-----|-------|
| Example: PIR Sensor | HC-SR501 | 5V | 50mA | 1 | Motion detection |
|  |  |  |  |  |  |

**Verification:**
- [ ] All components are 3.3V GPIO compatible or have level shifters
- [ ] Total current draw is within limits (16mA/pin, 50mA total GPIO)
- [ ] Datasheets reviewed and available
- [ ] Components sourced or on hand

### 1.2 GPIO Pin Assignment
**Task:** Assign GPIO pins following Luigi priority system.

**Pin Assignments:**
| Function | BCM Pin | Physical Pin | Direction | Notes |
|----------|---------|--------------|-----------|-------|
| Example: PIR Data | GPIO23 | Pin 16 | Input | Rising edge detection |
|  |  |  |  |  |

**Reference:** See `.github/skills/raspi-zero-w/gpio-pinout.md`

**Verification:**
- [ ] Pins follow priority (general purpose → PWM → special function)
- [ ] No conflicts with other modules
- [ ] Both BCM and physical pin numbers documented

### 1.3 Wiring Diagram
**Task:** Create clear wiring diagram with safety notes.

```
Component Name       Raspberry Pi Zero W
--------------       -------------------
VCC          ------>  5V (Pin 2) or 3.3V (Pin 1)
GND          ------>  Ground (Pin 6)
Signal/Data  ------>  GPIO## (Pin ##)

Notes:
- [Any inline components: resistors, diodes]
- [Safety warnings]
- [Component orientation]
```

**Reference:** See `.github/skills/module-design/hardware-design-checklist.md`

**Safety Verification:**
- [ ] No 5V signals directly to GPIO inputs
- [ ] Current limiting resistors calculated and added
- [ ] Polarity verified for all components
- [ ] Power budget calculated (total: ___ mA)
- [ ] Pre-power continuity test planned

### 1.4 Hardware Design Review
**Task:** Complete hardware design checklist.

- [ ] Complete `.github/skills/module-design/hardware-design-checklist.md`
- [ ] Peer review completed
- [ ] All safety concerns addressed
- [ ] Ready for Phase 2

**Sign-off:** ____________ Date: __________

---

## Phase 2: Software Architecture Design

**Goal:** Design software structure, configuration, and security.

**Skills Used:** `module-design`, `python-development`

### 2.1 Module Structure
**Task:** Design file structure and class architecture.

**File Structure:**
```
{category}/{module-name}/
├── README.md
├── setup.sh
├── {module-name}.py
├── {module-name}.service
├── {module-name}.conf.example
└── resources/ (if needed)
```

**Class Architecture:**
- `Config` - Configuration management
- `GPIOManager` - GPIO abstraction
- `[Device]Sensor/Controller` - Hardware interface
- `[Module]App` - Main application logic

**Reference:** See `.github/skills/python-development/SKILL.md`

### 2.2 Configuration Design
**Task:** Design configuration file structure.

**Configuration File:** `/etc/luigi/{category}/{module-name}/{module-name}.conf`

```ini
[Hardware]
INPUT_PIN=23

[Timing]
POLL_INTERVAL=1
COOLDOWN=1800

[Files]
DATA_DIR=/usr/share/{module-name}/
LOG_FILE=/var/log/{module-name}.log

[Logging]
LOG_LEVEL=INFO
LOG_MAX_BYTES=10485760
LOG_BACKUP_COUNT=5
```

**Configurable Parameters:**
| Parameter | Type | Default | Valid Range | Description |
|-----------|------|---------|-------------|-------------|
|  |  |  |  |  |

**Verification:**
- [ ] All user-configurable settings identified
- [ ] Defaults chosen for all parameters
- [ ] Config location follows Luigi standard

### 2.3 Error Handling & Logging
**Task:** Design error handling and logging strategy.

**Error Handling:**
- GPIO operations: [Strategy]
- File operations: [Strategy]
- Subprocess calls: [Strategy]
- Hardware failures: [Strategy]

**Logging:**
- Log file: `/var/log/{module-name}.log`
- Log rotation: 10MB max, 5 backups
- Log levels: DEBUG, INFO, WARNING, ERROR
- Sanitization: [Describe approach]

**Reference:** See `.github/skills/python-development/SKILL.md` (Logging section)

### 2.4 Security Hardening
**Task:** Plan security measures.

**Security Checklist:**
- [ ] subprocess.run() with list arguments (no shell=True)
- [ ] Path validation using os.path.commonpath()
- [ ] Log sanitization (length limits, no sensitive data)
- [ ] Subprocess timeouts (10s default)
- [ ] File permissions (644 configs, 755 executables)

**Reference:** See `.github/skills/module-design/SKILL.md` (Security section)

### 2.5 Software Design Review
**Task:** Review software architecture.

- [ ] Class architecture reviewed
- [ ] Configuration design reviewed
- [ ] Error handling comprehensive
- [ ] Security measures planned
- [ ] Ready for Phase 3

**Sign-off:** ____________ Date: __________

---

## Phase 3: Service Integration Design

**Goal:** Design systemd service and graceful shutdown.

**Skills Used:** `module-design`, `system-setup`

### 3.1 systemd Service Unit
**Task:** Design service file.

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

[Install]
WantedBy=multi-user.target
```

**Reference:** See `.github/skills/module-design/SKILL.md` (Service Integration)

**Verification:**
- [ ] Service type appropriate (simple for foreground apps)
- [ ] Restart policy configured (on-failure)
- [ ] Logging configured (file + journalctl)
- [ ] Security hardening enabled

### 3.2 Shutdown Mechanism
**Task:** Design graceful shutdown.

**Shutdown Handlers:**
- SIGTERM: [Cleanup steps]
- SIGINT: [Cleanup steps]

**Cleanup Steps:**
1. Stop monitoring/operation
2. GPIO cleanup
3. Close log files
4. Remove temporary files

**Reference:** See `.github/skills/python-development/SKILL.md` (Signal handlers)

**Verification:**
- [ ] Signal handlers planned
- [ ] Cleanup steps identified
- [ ] Resources released properly

### 3.3 Service Design Review
**Task:** Review service integration.

- [ ] Service file reviewed
- [ ] Shutdown mechanism planned
- [ ] Restart behavior appropriate
- [ ] Ready for Phase 4

**Sign-off:** ____________ Date: __________

---

## Phase 4: Setup Script & Deployment

**Goal:** Design installation automation.

**Skills Used:** `module-design`, `system-setup`

### 4.1 Setup Script Design
**Task:** Design setup.sh with install/uninstall/status.

**Installation Steps:**
1. Check prerequisites
2. Install dependencies (apt-get install ...)
3. Create directories
4. Deploy configuration file
5. Deploy Python script
6. Deploy service file
7. Enable and start service
8. Verify installation

**Uninstallation Steps:**
1. Stop service
2. Disable service
3. Remove service file
4. Remove application files
5. Ask about config/data removal
6. Verify removal

**Reference:** See `.github/skills/system-setup/SKILL.md`

**Verification:**
- [ ] Install function designed
- [ ] Uninstall function designed
- [ ] Status function designed
- [ ] Error handling planned

### 4.2 File Deployment
**Task:** Define file locations and permissions.

**File Locations:**
| File | Destination | Permissions | Owner |
|------|-------------|-------------|-------|
| {module-name}.py | /usr/local/bin/ | 755 | root |
| {module-name}.service | /etc/systemd/system/ | 644 | root |
| {module-name}.conf | /etc/luigi/{category}/{module}/ | 644 | root |
| Resources | /usr/share/{module-name}/ | 644 | root |

**Verification:**
- [ ] All file destinations defined
- [ ] Permissions appropriate
- [ ] Backup strategy planned (if overwriting)

### 4.3 Deployment Review
**Task:** Review deployment design.

- [ ] Setup script designed
- [ ] File deployment planned
- [ ] Verification steps identified
- [ ] Ready for Phase 5

**Sign-off:** ____________ Date: __________

---

## Phase 5: Testing Strategy

**Goal:** Plan comprehensive testing approach.

**Skills Used:** `python-development`, `raspi-zero-w`

### 5.1 Syntax Validation (No Hardware)
**Task:** Plan syntax testing.

**Tests:**
```bash
# Python syntax
python3 -m py_compile {module-name}.py

# Shell script
shellcheck setup.sh
```

**Verification:**
- [ ] Python syntax validation command identified
- [ ] Shell script validation command identified

### 5.2 Logic Testing (Mock GPIO)
**Task:** Plan logic testing without hardware.

**Mock GPIO Approach:**
```python
try:
    import RPi.GPIO as GPIO
except (ImportError, RuntimeError):
    from mock_gpio import MockGPIO as GPIO
    print("Using mock GPIO")
```

**Test Cases:**
- Configuration loading
- Error handling
- State management
- Shutdown procedures

**Reference:** See `.github/skills/python-development/SKILL.md` (Mock GPIO)

**Verification:**
- [ ] Mock GPIO support planned
- [ ] Test cases identified
- [ ] Can test without hardware

### 5.3 Integration Testing (Hardware)
**Task:** Plan hardware integration tests.

**Test Procedures:**
1. GPIO initialization test
2. Sensor/actuator operation test
3. Full workflow test
4. Service lifecycle test

**Reference:** See `.github/skills/raspi-zero-w/SKILL.md` (Testing)

**Verification:**
- [ ] Hardware test procedures defined
- [ ] Test equipment identified
- [ ] Success criteria defined

### 5.4 Testing Review
**Task:** Review testing strategy.

- [ ] Syntax validation planned
- [ ] Mock GPIO testing planned
- [ ] Hardware testing planned
- [ ] Ready for Phase 6

**Sign-off:** ____________ Date: __________

---

## Phase 6: Documentation

**Goal:** Plan comprehensive documentation.

**Skills Used:** `module-design`

### 6.1 README Structure
**Task:** Plan README.md content.

**Required Sections:**
1. Module Name & Description
2. Contents
3. Overview
4. Hardware Requirements
5. GPIO Configuration
6. Wiring Diagram
7. Installation
8. Configuration
9. Usage
10. How It Works
11. Troubleshooting
12. Architecture
13. Dependencies
14. Notes

**Reference:** See `.github/skills/module-design/SKILL.md` (Documentation Design)

**Verification:**
- [ ] All required sections identified
- [ ] Content outline created

### 6.2 Wiring Diagram
**Task:** Finalize wiring diagram for README.

- [ ] Diagram created (ASCII art or image)
- [ ] All connections labeled
- [ ] Pin numbers included (BCM and physical)
- [ ] Safety warnings added

### 6.3 Configuration Documentation
**Task:** Document all configuration options.

- [ ] All parameters documented
- [ ] Default values listed
- [ ] Valid ranges specified
- [ ] Modification instructions clear

### 6.4 Troubleshooting Section
**Task:** Document common issues and solutions.

**Common Issues:**
1. Issue: [Description]
   - Solution: [Steps]

### 6.5 Documentation Review
**Task:** Review documentation plan.

- [ ] README structure complete
- [ ] Wiring diagram ready
- [ ] Configuration documented
- [ ] Troubleshooting included
- [ ] Ready for Phase 7

**Sign-off:** ____________ Date: __________

---

## Phase 7: Implementation

**Goal:** Implement the module following the plan.

**Skills Used:** `python-development`, `raspi-zero-w`, `system-setup`

### 7.1 Hardware Assembly
**Task:** Assemble hardware according to wiring diagram.

**Reference:** See Phase 1.3 wiring diagram and `.github/skills/raspi-zero-w/`

**Steps:**
1. Verify components
2. Follow wiring diagram
3. Check connections
4. Power-on testing

**Verification:**
- [ ] Hardware assembled
- [ ] Connections verified
- [ ] Pre-power checks complete
- [ ] Hardware functional

### 7.2 Python Implementation
**Task:** Implement Python application.

**Reference:** See Phase 2 design and `.github/skills/python-development/`

**Implementation Order:**
1. Config class
2. GPIOManager class
3. Device-specific class(es)
4. Main App class
5. Signal handlers
6. Main function

**Verification:**
- [ ] All classes implemented
- [ ] Error handling added
- [ ] Logging configured
- [ ] Security measures implemented
- [ ] Syntax validated: `python3 -m py_compile {module-name}.py`

### 7.3 Service Integration
**Task:** Implement service and setup script.

**Reference:** See Phase 3 & 4 design and `.github/skills/system-setup/`

**Files to Create:**
1. {module-name}.service
2. setup.sh
3. {module-name}.conf.example

**Verification:**
- [ ] Service file created
- [ ] Setup script created
- [ ] Configuration example created
- [ ] Shell script validated: `shellcheck setup.sh`

### 7.4 Testing
**Task:** Execute testing strategy from Phase 5.

**Tests to Run:**
1. Syntax validation ✓
2. Mock GPIO testing
3. Hardware integration testing
4. Service lifecycle testing

**Verification:**
- [ ] All syntax tests pass
- [ ] Logic tests pass (mock GPIO)
- [ ] Hardware tests pass
- [ ] Service tests pass

### 7.5 Documentation
**Task:** Write documentation from Phase 6 plan.

**Documents to Create:**
1. README.md
2. Inline code comments
3. Configuration comments

**Verification:**
- [ ] README complete
- [ ] Code documented
- [ ] Configuration documented

### 7.6 Implementation Review
**Task:** Final review before completion.

- [ ] All phases complete
- [ ] Hardware working
- [ ] Software working
- [ ] Service working
- [ ] Documentation complete
- [ ] Testing complete

**Sign-off:** ____________ Date: __________

---

## Phase 8: Final Verification

**Goal:** Verify complete module integration.

### 8.1 Complete Design Review
**Task:** Complete comprehensive design review.

**Reference:** `.github/skills/module-design/design-review-checklist.md`

- [ ] Complete design-review-checklist.md
- [ ] All items verified
- [ ] Peer review completed
- [ ] Issues addressed

### 8.2 Integration Testing
**Task:** Test module with full Luigi system.

**Tests:**
1. Standalone operation
2. Integration with centralized setup.sh
3. Multi-module compatibility
4. Boot persistence

**Verification:**
- [ ] Module installs via central setup.sh
- [ ] Module uninstalls cleanly
- [ ] No GPIO conflicts
- [ ] Service starts on boot

### 8.3 Final Sign-off
**Task:** Approve module for production.

**Final Checks:**
- [ ] All phases complete ✓
- [ ] All verifications passed ✓
- [ ] Documentation complete ✓
- [ ] Testing complete ✓
- [ ] Peer review complete ✓

**Approved for Production:** ____________ Date: __________

---

## Implementation Timeline

| Phase | Estimated Time | Start Date | End Date | Status |
|-------|----------------|------------|----------|--------|
| 1. Hardware Design | ___ hours/days |  |  | ⬜ Not Started |
| 2. Software Architecture | ___ hours/days |  |  | ⬜ Not Started |
| 3. Service Integration | ___ hours/days |  |  | ⬜ Not Started |
| 4. Setup & Deployment | ___ hours/days |  |  | ⬜ Not Started |
| 5. Testing Strategy | ___ hours/days |  |  | ⬜ Not Started |
| 6. Documentation | ___ hours/days |  |  | ⬜ Not Started |
| 7. Implementation | ___ hours/days |  |  | ⬜ Not Started |
| 8. Final Verification | ___ hours/days |  |  | ⬜ Not Started |
| **Total** | **___ hours/days** |  |  |  |

---

## Risk Assessment

### Identified Risks

1. **Risk:** [Description]
   - **Severity:** Low | Medium | High
   - **Likelihood:** Low | Medium | High
   - **Mitigation:** [Strategy]
   - **Status:** Open | Mitigated

2. **Risk:** [Description]
   - **Severity:** Low | Medium | High
   - **Likelihood:** Low | Medium | High
   - **Mitigation:** [Strategy]
   - **Status:** Open | Mitigated

---

## Notes and Updates

### Design Changes
[Document any changes made during implementation]

### Lessons Learned
[Document insights gained during development]

### Future Enhancements
[Ideas for future improvements]

---

## References

- **Module Design Skill:** `.github/skills/module-design/SKILL.md`
- **Python Development:** `.github/skills/python-development/SKILL.md`
- **Raspberry Pi Hardware:** `.github/skills/raspi-zero-w/SKILL.md`
- **System Setup:** `.github/skills/system-setup/SKILL.md`
- **Hardware Checklist:** `.github/skills/module-design/hardware-design-checklist.md`
- **Design Review:** `.github/skills/module-design/design-review-checklist.md`

---

**Plan Version:** 1.0  
**Last Updated:** [Date]
