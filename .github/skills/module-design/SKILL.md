---
name: module-design
description: Comprehensive guide for designing Luigi modules. Use this skill when designing new modules BEFORE implementation to ensure proper hardware integration, wiring safety, configuration structure, and deployment strategy.
license: MIT
---

# Luigi Module Design Skill

This skill provides comprehensive guidance for **designing Luigi modules before implementation**. Use this skill during the planning and design phase to ensure proper hardware integration, safe wiring, appropriate configuration, and maintainable code structure.

## When to Use This Skill

Use this skill when:
- Designing a new Luigi module from scratch
- Planning hardware integration for a new project
- Evaluating GPIO pin assignments and wiring
- Architecting module structure and configuration
- Designing setup and deployment strategies
- Creating module documentation structure
- Planning testing strategies for hardware projects

**IMPORTANT:** This is a design-phase skill. Use it to plan and validate design decisions before writing code. For implementation details, see:
- `.github/skills/python-development/` - Python coding patterns
- `.github/skills/raspi-zero-w/` - Hardware wiring and GPIO details
- `.github/skills/system-setup/` - Deployment automation scripts

## Luigi Module Design Philosophy

### Core Principles

1. **Safety First** - Hardware connections must be safe for both components and users
2. **Modularity** - Each module should be self-contained and independently deployable
3. **Configuration Over Code** - Use config files for settings that users might change
4. **Graceful Degradation** - Handle errors without crashing or damaging hardware
5. **Documentation** - Provide clear setup instructions with wiring diagrams
6. **Testability** - Design for testing without requiring full hardware setup
7. **Maintainability** - Follow consistent patterns across all modules

### Module Types

Luigi supports various module types across different categories:

**motion-detection/**
- PIR motion sensors with actions (sounds, alerts, automation)
- Camera-based motion detection
- Combined sensor approaches

**sensors/**
- Environmental monitoring (temperature, humidity, pressure, light)
- Distance/proximity sensors (ultrasonic, infrared)
- Air quality sensors
- Multi-sensor integrations

**automation/**
- Relay control (lights, appliances, pumps)
- Motor control (servos, steppers, DC motors)
- LED controllers (patterns, RGB, strips)
- Actuator control

**security/**
- Door/window sensors with notifications
- Camera systems with detection
- Alarm systems
- Access control

**iot/**
- MQTT integration
- Cloud service connectors
- Home automation bridges (Home Assistant, OpenHAB)
- API servers and webhooks

**system/**
- Performance optimization
- Monitoring and diagnostics
- Backup and maintenance
- System configuration

## Design Process Overview

The Luigi module design process is a **two-stage workflow**:

1. **Stage 1: Design Analysis** (when feature request received)
2. **Stage 2: Implementation Plan** (created from approved analysis)

### Stage 1: Design Analysis (DESIGN_ANALYSIS.md)

When a feature request is received, **first** complete a design analysis document with **3 phases**:

**Phase 1: Requirements & Hardware Analysis**
- Define requirements and success criteria
- Select and document hardware components
- Assign GPIO pins following priority system
- Create wiring diagrams with safety verification
- Calculate power budget
- Complete safety analysis
- **Skills:** `module-design`, `raspi-zero-w`

**Phase 2: Software Architecture Analysis**
- Design module structure and class architecture
- Define configuration file format and location
- Plan error handling and logging strategy
- Design security hardening measures
- **Skills:** `module-design`, `python-development`

**Phase 3: Service & Deployment Analysis**
- Design systemd service integration
- Plan graceful shutdown mechanisms
- Design setup script strategy
- Plan file deployment and dependencies
- **Skills:** `module-design`, `system-setup`

**Output:** DESIGN_ANALYSIS.md with approved hardware, software, and service designs.

### Stage 2: Implementation Plan (IMPLEMENTATION_PLAN.md)

After DESIGN_ANALYSIS.md is approved, **create** an implementation plan with **5 phases**:

**Phase 1: Setup & Deployment Implementation**
- Create setup.sh (install/uninstall/status)
- Create configuration example file
- Implement file deployment
- **Skills:** `system-setup`
- **Based on:** DESIGN_ANALYSIS Phase 3

**Phase 2: Testing Strategy Implementation**
- Set up syntax validation
- Implement mock GPIO testing
- Define hardware integration tests
- **Skills:** `python-development`, `raspi-zero-w`
- **Based on:** DESIGN_ANALYSIS Phases 1 & 2

**Phase 3: Documentation Implementation**
- Write README.md with all required sections
- Add inline code documentation
- Document configuration parameters
- **Skills:** `module-design`
- **Based on:** DESIGN_ANALYSIS all phases

**Phase 4: Core Implementation**
- Assemble hardware per design
- Implement Python code (Config, GPIOManager, Device, App classes)
- Create service file
- Integration testing
- **Skills:** `python-development`, `raspi-zero-w`, `system-setup`
- **Based on:** DESIGN_ANALYSIS all phases

**Phase 5: Final Verification & Integration**
- Complete design review checklist
- Luigi system integration testing
- Performance and security verification
- Final approval
- **Skills:** `module-design`
- **Based on:** Complete implementation

### Complete Workflow

```
Feature Request Received
    ↓
DESIGN_ANALYSIS.md (Stage 1)
    ↓
    Phase 1: Requirements & Hardware Analysis
        ↓ (use module-design + raspi-zero-w)
    Phase 2: Software Architecture Analysis
        ↓ (use module-design + python-development)
    Phase 3: Service & Deployment Analysis
        ↓ (use module-design + system-setup)
    ↓
Design Review & Approval
    ↓
IMPLEMENTATION_PLAN.md (Stage 2)
    ↓
    Phase 1: Setup & Deployment
        ↓ (use system-setup)
    Phase 2: Testing Strategy
        ↓ (use python-development + raspi-zero-w)
    Phase 3: Documentation
        ↓ (use module-design)
    Phase 4: Core Implementation
        ↓ (use all skills)
    Phase 5: Final Verification
        ↓ (use module-design)
    ↓
✓ Complete Module
```

### How to Use the Process

**When you receive a feature request:**

1. **Start DESIGN_ANALYSIS.md**
   - Copy template from `.github/skills/module-design/DESIGN_ANALYSIS.md`
   - Fill in Phases 1-3 (analysis phases)
   - Reference appropriate skills for detailed guidance
   - Complete checklists and get sign-offs

2. **Get Design Approval**
   - Peer review the analysis
   - Address feedback
   - Get final approval to proceed

3. **Create IMPLEMENTATION_PLAN.md**
   - Copy template from `.github/skills/module-design/IMPLEMENTATION_PLAN.md`
   - Summarize design decisions from DESIGN_ANALYSIS
   - Fill in implementation phases (Phases 1-5)
   - Reference the completed DESIGN_ANALYSIS for details

4. **Execute Implementation**
   - Follow the implementation plan
   - Use referenced skills for guidance
   - Complete checklists as you progress
   - Get sign-offs at each phase

5. **Final Verification**
   - Complete Phase 5 verification
   - Get final approval
   - Deploy to production

## Hardware Design Guidelines

### Component Selection

**Criteria for Selecting Components:**
- **Voltage Compatibility**: Must work with 3.3V GPIO or have level shifters
- **Current Requirements**: Total GPIO current must not exceed 50mA
- **Availability**: Commonly available components preferred
- **Reliability**: Components with known good track record
- **Documentation**: Well-documented components with datasheets

**Common Component Categories:**

| Category | Examples | Typical Voltage | Notes |
|----------|----------|----------------|-------|
| Sensors (Input) | PIR, ultrasonic, DHT22 | 3.3V-5V | Usually safe for GPIO input |
| Actuators (Output) | Relays, servos, motors | 5V-12V | Often require external power |
| Indicators | LEDs, buzzers | 3.3V-5V | Need current limiting resistors |
| Communication | I2C, SPI, UART devices | 3.3V | Use dedicated pins when possible |

### GPIO Pin Assignment Strategy

**Pin Selection Priority:**

1. **First Choice - General Purpose Pins:**
   - GPIO23, GPIO24, GPIO25 (no special functions)
   - GPIO16, GPIO20, GPIO21
   - Good for sensors, buttons, general I/O

2. **Second Choice - PWM Capable (if needed):**
   - GPIO18 (hardware PWM0)
   - GPIO12, GPIO13 (hardware PWM)
   - GPIO19 (PWM1)
   - Use for LEDs, servos, motor control

3. **Reserved - Avoid Unless Specifically Needed:**
   - GPIO2, GPIO3 (I2C - SDA, SCL)
   - GPIO9, GPIO10, GPIO11 (SPI)
   - GPIO14, GPIO15 (UART - TX, RX)
   - Only use if you need these interfaces

**Pin Assignment Checklist:**
- [ ] Pin available (not used by other active modules)
- [ ] Pin suitable for use case (input/output, PWM, etc.)
- [ ] Pin not reserved for system functions unless required
- [ ] Documented in module README with both BCM and physical numbers
- [ ] Wiring diagram shows correct pin connections

### Wiring Design and Safety

**Safety Requirements (CRITICAL):**

1. **Voltage Protection:**
   - Never connect 5V signals directly to GPIO inputs
   - Use voltage dividers or level shifters for 5V signals
   - Verify all connections are 3.3V logic compatible

2. **Current Protection:**
   - Use current-limiting resistors for LEDs (220Ω typical)
   - Calculate total current draw (max 16mA per pin)
   - Add fuses for external power connections

3. **Polarity Protection:**
   - Double-check VCC/GND connections before powering
   - Use diode protection for inductive loads (relays, motors)
   - Document polarity clearly in wiring diagrams

4. **Short Circuit Prevention:**
   - Verify no adjacent pins are shorted
   - Use proper spacing on breadboards
   - Test continuity before applying power

5. **Component Protection:**
   - Add ESD protection for sensitive components
   - Use optoisolators for high-voltage circuits
   - Protect against reverse voltage on inputs

**Wiring Diagram Requirements:**

Create clear ASCII art or image diagrams showing:
```
Component Name       Raspberry Pi Zero W
--------------       -------------------
VCC/Power    ------>  5V (Pin 2 or 4) or 3.3V (Pin 1 or 17)
GND          ------>  Ground (Pin 6, 9, 14, 20, 25, 30, 34, 39)
Signal/Data  ------>  GPIO## (Pin XX) - BCM numbering
```

Include in diagram:
- Component pin names
- Raspberry Pi pin numbers (both physical and BCM)
- Wire colors if standardized
- Any resistors, diodes, or other components in line
- Power supply requirements and connections
- Notes about orientation (for polarized components)

### Power Design

**Power Budget Analysis:**

1. **Raspberry Pi Zero W Base:** ~150mA
2. **Each GPIO Output (high):** Up to 16mA (typically 8-10mA)
3. **USB Peripherals:** Variable (check specs)
4. **External Components:** Calculate individually

**Power Supply Requirements:**
- **Minimum:** 1.2A power supply (5V micro-USB)
- **Recommended:** 2A power supply for stability
- **With External Components:** 2.5A+ or separate power supply

**External Power Considerations:**

When components need more power than GPIO can provide:
- Use separate power supply (5V, 12V, etc.)
- **Critical:** Share ground between Pi and external supply
- Use transistors or MOSFETs for GPIO control of high-power loads
- Document external power requirements clearly

Example circuit for high-power control:
```
GPIO Pin ----> [Resistor] ----> Transistor Base
                                Transistor Collector ----> Load (+)
                                Transistor Emitter -------> GND
External Power (+) -------------> Load (-)
```

## Software Architecture Design

### Module Structure Template

Every Luigi module should follow this structure:

```
category/module-name/
├── README.md                    # Complete module documentation
├── setup.sh                     # Installation automation (install/uninstall/status)
├── module-name.py               # Main Python application
├── module-name.service          # systemd service unit file
├── module-name.conf.example     # Example configuration file
└── resources/                   # Optional: additional files
    ├── sounds/                  # Audio files (if applicable)
    ├── data/                    # Data files
    └── scripts/                 # Helper scripts
```

**File Naming Convention:**
- Use module name consistently across all files
- Use lowercase with hyphens for directories
- Use underscores in Python if needed for imports
- Example: `motion-detection/pir-detector/pir_detector.py`

### Configuration Design

**Configuration File Location:**

MUST follow this pattern: `/etc/luigi/{category}/{module-name}/`

Examples:
- `motion-detection/mario/` → `/etc/luigi/motion-detection/mario/mario.conf`
- `sensors/temperature/` → `/etc/luigi/sensors/temperature/temperature.conf`
- `automation/relay/` → `/etc/luigi/automation/relay/relay.conf`

**Configuration File Format:**

Use INI-style format with clear sections:

```ini
# /etc/luigi/{category}/{module-name}/{module-name}.conf
# {Module Name} Configuration

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

[Network]
# Network settings (if applicable)
MQTT_BROKER=localhost
MQTT_PORT=1883
```

**Configuration Design Principles:**
1. Group related settings into logical sections
2. Use descriptive, uppercase names for settings
3. Include comments explaining each setting
4. Provide sensible defaults in code
5. Document all options in README
6. Make file optional with fallback to defaults

### Python Application Structure

**Recommended Class Architecture:**

```python
#!/usr/bin/env python3
"""
{Module Name} - Brief description
Part of the Luigi project
"""

class Config:
    """Configuration management with file loading and defaults"""
    pass

class GPIOManager:
    """Hardware abstraction for GPIO operations"""
    pass

class {SensorOrDevice}:
    """Hardware-specific interface (PIR, relay, LED, etc.)"""
    pass

class {ModuleName}App:
    """Main application orchestrating all components"""
    pass

def main():
    """Application entry point"""
    pass

if __name__ == '__main__':
    main()
```

**Key Design Elements:**

1. **Config Class:**
   - Load from `/etc/luigi/{category}/{module}/config.conf`
   - Provide defaults for all settings
   - Validate configuration values
   - Log configuration source (file or defaults)

2. **GPIOManager Class:**
   - Initialize GPIO mode (BCM)
   - Setup input/output pins
   - Cleanup GPIO on exit
   - Handle GPIO errors gracefully

3. **Device-Specific Classes:**
   - Encapsulate hardware interactions
   - Abstract hardware details from main logic
   - Provide clean interface (start, stop, read, write)
   - Handle hardware-specific errors

4. **Main App Class:**
   - Orchestrate all components
   - Implement main application logic
   - Handle signals (SIGTERM, SIGINT)
   - Manage application state
   - Coordinate shutdown

**Error Handling Strategy:**
- Try/except on all GPIO operations
- Try/except on all file operations
- Try/except on all subprocess calls
- Log errors with context
- Graceful degradation when possible
- Clean shutdown on fatal errors

**Logging Strategy:**
- Use Python logging module with RotatingFileHandler
- Log to `/var/log/{module-name}.log`
- Also output to stdout/stderr for systemd journaling
- Log levels: DEBUG, INFO, WARNING, ERROR
- Include timestamps, module name, and context
- Sanitize all logged data (remove sensitive info, limit length)

### Security Design

**Security Hardening Checklist:**

- [ ] Use `subprocess.run()` with list arguments (not shell=True)
- [ ] Validate all file paths using `os.path.commonpath()`
- [ ] Sanitize all log output (limit length, remove newlines)
- [ ] Add timeouts to all subprocess calls (10s typical)
- [ ] Validate configuration values before use
- [ ] Use appropriate file permissions (644 for configs, 755 for executables)
- [ ] Run with minimum required privileges
- [ ] Avoid hardcoded credentials or secrets
- [ ] Use secure defaults for network services
- [ ] Document security requirements in README

**Command Injection Prevention:**
```python
# Bad - Shell injection vulnerability
os.system(f"aplay {filename}")

# Good - Safe subprocess call
subprocess.run(['aplay', filename], timeout=10, check=True)
```

**Path Traversal Prevention:**
```python
import os

def safe_file_path(base_dir, filename):
    """Validate file is within base directory"""
    full_path = os.path.join(base_dir, filename)
    real_path = os.path.realpath(full_path)
    
    if not real_path.startswith(os.path.realpath(base_dir)):
        raise ValueError("Path traversal attempt detected")
    
    return real_path
```

## Service Integration Design

### systemd Service Design (Recommended)

**Service Unit File Template:**

```ini
# /etc/systemd/system/{module-name}.service
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

**Service Design Principles:**
1. Use `Type=simple` for foreground applications
2. Run as `root` only if GPIO access required (document alternative with gpio group)
3. `Restart=on-failure` for automatic recovery
4. Output to both log file and journalctl
5. Enable security hardening options
6. Set reasonable restart delay (10s default)
7. Use `KillSignal=SIGTERM` for graceful shutdown (default)
8. Document service management commands in README

### Setup Script Design

**Setup Script Requirements:**

Every module MUST include a `setup.sh` script with these functions:
- `install` - Install module with dependencies
- `uninstall` - Remove module cleanly
- `status` - Show installation and service status

**Setup Script Template Structure:**

```bash
#!/bin/bash
# setup.sh - {Module Name} installation script

set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MODULE_NAME="{module-name}"
readonly MODULE_CATEGORY="{category}"
readonly CONFIG_DIR="/etc/luigi/${MODULE_CATEGORY}/${MODULE_NAME}"

# Color output functions
log_info() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }

# Check root
require_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Install function
install() {
    require_root
    log_info "Installing ${MODULE_NAME}..."
    
    # 1. Check prerequisites
    # 2. Install dependencies
    # 3. Create directories
    # 4. Deploy configuration file
    # 5. Deploy application files
    # 6. Deploy service
    # 7. Enable and start service
    # 8. Verify installation
    
    log_info "Installation complete!"
}

# Uninstall function
uninstall() {
    require_root
    log_info "Uninstalling ${MODULE_NAME}..."
    
    # 1. Stop service
    # 2. Disable service
    # 3. Remove service files
    # 4. Remove application files
    # 5. Ask about config/data removal
    # 6. Verify removal
    
    log_info "Uninstall complete!"
}

# Status function
status() {
    log_info "Checking ${MODULE_NAME} status..."
    
    # Check service status
    # Check file installations
    # Check configuration
    # Display summary
}

# Main
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

**Setup Script Best Practices:**
- Use `set -euo pipefail` for error handling
- Check for root privileges when needed
- Provide colored output for clarity
- Validate prerequisites before installation
- Create backups before overwriting files
- Ask for confirmation on destructive operations
- Verify installation success
- Provide clear error messages
- Support idempotent operations (safe to run multiple times)

## Testing Strategy Design

### Test Categories

Design tests for three levels:

**1. Syntax Validation (No Hardware Required):**
```bash
# Python syntax check
python3 -m py_compile module-name.py

# Shell script check
shellcheck setup.sh

# Config file validation
# Test config parser handles example config
```

**2. Logic Testing (Mock GPIO):**
```python
# Test application logic without hardware
# Use mock GPIO class
# Test configuration loading
# Test error handling
# Test state management
```

**3. Integration Testing (Requires Hardware):**
```python
# Test GPIO operations
# Test sensor reading
# Test actuator control
# Test full workflow
```

**4. Service Testing:**
```bash
# Test service installation
# Test service start/stop
# Test service auto-start on boot
# Test service recovery from failures
```

### Mock GPIO Pattern

Design modules to support mock GPIO for testing:

```python
try:
    import RPi.GPIO as GPIO
    USING_MOCK_GPIO = False
except (ImportError, RuntimeError):
    from mock_gpio import MockGPIO as GPIO
    USING_MOCK_GPIO = True
    print("Warning: Using mock GPIO (no hardware)")
```

Include mock GPIO class or reference shared mock library.

## Documentation Design

### README Structure

Every module README should include these sections:

```markdown
# {Module Name}

Brief description (1-2 sentences)

## Contents

List of files in this directory

## Overview

Detailed description of functionality
- Key features (bullet list)
- Use cases

## Hardware Requirements

- Raspberry Pi model(s)
- Required sensors/components with part numbers
- Optional components
- Required accessories (wires, resistors, etc.)

## GPIO Configuration

- Pin assignments with both BCM and physical numbers
- Any special pin requirements (PWM, I2C, etc.)

### Wiring Diagram

```
Component        Raspberry Pi
---------        ------------
Detailed ASCII art or reference to image
```

## Installation

### Automated Installation (Recommended)

```bash
# Commands using setup.sh
```

### Manual Installation

Detailed steps for manual installation

## Configuration

Configuration file location and format
- All configuration options documented
- Default values listed
- How to modify settings

## Usage

### Service Management

Standard systemd commands

### Manual Operation

How to run manually for testing

## How It Works

Explanation of operation
- Initialization steps
- Main loop behavior
- Event handling
- Shutdown process

## Troubleshooting

Common issues and solutions
- Problem: description
  - Solution: step-by-step fix

## Architecture

Code structure overview
- Classes and their responsibilities
- Key design patterns used

## Dependencies

List of all dependencies with installation commands

## Notes

Important operational notes
- GPIO numbering mode
- Power requirements
- Safety warnings
- Performance characteristics

## Future Enhancements

Ideas for improvements
```

### Wiring Diagram Best Practices

**ASCII Art Diagrams:**
- Use clear alignment and spacing
- Include component names and pin numbers
- Show connection direction with arrows
- Note any components in-line (resistors, diodes)
- Include power and ground connections

**Image Diagrams (Optional):**
- Use tools like Fritzing for breadboard diagrams
- Include both breadboard and schematic views
- Label all connections clearly
- Show wire colors if standardized
- Include legend for symbols

**Safety Notes:**
- Highlight voltage requirements
- Warn about polarity-sensitive components
- Note maximum current ratings
- Indicate any hazards

## Design Review Checklist

Before implementing a new module, verify your design:

### Hardware Design Review
- [ ] All components compatible with 3.3V GPIO
- [ ] Total current draw within limits (50mA across all pins)
- [ ] GPIO pins selected appropriately (no conflicts)
- [ ] Wiring diagram complete and verified
- [ ] Safety considerations addressed
- [ ] Power supply adequate for all components
- [ ] Polarity and voltage verified
- [ ] Protection components added where needed

### Software Design Review
- [ ] Module structure follows Luigi patterns
- [ ] Configuration file location correct
- [ ] All config options documented
- [ ] Hardware abstraction layer designed
- [ ] Error handling comprehensive
- [ ] Logging strategy defined
- [ ] Security hardening planned
- [ ] Testing strategy defined
- [ ] Mock GPIO support planned

### Service Design Review
- [ ] Service file follows systemd best practices
- [ ] Service runs with appropriate user
- [ ] Restart policy appropriate
- [ ] Logging configured correctly
- [ ] Security hardening enabled
- [ ] Shutdown handled gracefully

### Setup Script Review
- [ ] Install function complete
- [ ] Uninstall function complete
- [ ] Status function complete
- [ ] Root checking implemented
- [ ] Error handling robust
- [ ] User feedback clear
- [ ] Verification checks included

### Documentation Review
- [ ] README complete with all sections
- [ ] Wiring diagram clear and accurate
- [ ] Configuration documented
- [ ] Troubleshooting section included
- [ ] Usage examples provided
- [ ] Safety warnings prominent
- [ ] Dependencies listed

### Security Review
- [ ] No shell injection vulnerabilities
- [ ] Path traversal prevention implemented
- [ ] Log sanitization planned
- [ ] Subprocess timeouts added
- [ ] File permissions appropriate
- [ ] No hardcoded secrets

## Module Design Examples

### Example 1: Simple Input Module (PIR Motion Sensor)

**Design Summary:**
- **Purpose**: Detect motion and trigger action
- **Hardware**: PIR sensor (HC-SR501)
- **GPIO**: 1 input pin (GPIO23)
- **Configuration**: Cooldown period, action type
- **Service**: systemd with auto-restart
- **Complexity**: Low

**Key Design Decisions:**
- Use event detection (efficient, not polling)
- Configurable cooldown to prevent spam
- Action is pluggable (sound, MQTT, script)
- Configuration file for all settings

### Example 2: Environmental Monitor (Temperature/Humidity)

**Design Summary:**
- **Purpose**: Read and log environmental data
- **Hardware**: DHT22 sensor
- **GPIO**: 1 input pin with pull-up
- **Configuration**: Poll interval, thresholds, logging
- **Service**: systemd with continuous operation
- **Complexity**: Medium

**Key Design Decisions:**
- Periodic polling (sensor limitation)
- Local logging with rotation
- Optional MQTT publishing
- Threshold alerts configurable
- Retry logic for sensor errors

### Example 3: Relay Controller (Automation)

**Design Summary:**
- **Purpose**: Control high-power devices
- **Hardware**: Relay module, transistor driver
- **GPIO**: Multiple output pins
- **Configuration**: Relay assignments, schedules, triggers
- **Service**: systemd with network interface
- **Complexity**: High

**Key Design Decisions:**
- Safe shutdown (all relays off)
- State persistence across restarts
- Web interface for control
- Schedule support (cron-like)
- Multiple control methods (GPIO, MQTT, HTTP)
- Safety interlocks to prevent conflicts

## Multi-Module Integration

### Designing for Integration

When modules need to interact:

**Option 1: File-Based Communication**
- Module A writes to `/tmp/module-a-state`
- Module B reads from `/tmp/module-a-state`
- Simple but limited

**Option 2: MQTT Messaging**
- Both modules publish/subscribe to topics
- Decoupled, scalable
- Requires MQTT broker

**Option 3: Shared Library**
- Create `luigi-common` library
- Shared classes and utilities
- Located in `/usr/local/lib/python3/dist-packages/luigi_common/`

**Option 4: REST API**
- One module provides HTTP API
- Other modules make HTTP requests
- Good for complex interactions

### Module Compatibility

Design modules to coexist:
- **No GPIO conflicts**: Document pin usage clearly
- **Shared resources**: Coordinate access to shared hardware
- **Service naming**: Use descriptive, unique names
- **Port allocation**: Use non-conflicting ports for network services
- **Log files**: Use separate log files per module
- **Configuration**: Separate config directories per module

## Common Design Patterns

### Pattern 1: Event-Driven Sensor

```
Sensor detects event → Callback triggered → Check conditions → Perform action
```

**Best For:** PIR sensors, buttons, switches
**Advantages:** Efficient, responsive, low CPU usage
**Example:** Mario motion detection module

### Pattern 2: Polling Sensor

```
Main loop → Read sensor → Process data → Wait → Repeat
```

**Best For:** Environmental sensors, analog inputs
**Advantages:** Predictable timing, simple logic
**Example:** Temperature monitoring

### Pattern 3: State Machine

```
Initialize → State A → Condition → State B → Condition → State C → ...
```

**Best For:** Complex behaviors, multi-step operations
**Advantages:** Clear logic flow, easy to extend
**Example:** Security system with arm/disarm/alarm states

### Pattern 4: Command-Response

```
Listen for command → Validate → Execute → Respond with status
```

**Best For:** Controllable devices, automation
**Advantages:** Interactive, testable, networkable
**Example:** Relay controller with HTTP interface

## Performance Considerations

### CPU Usage
- Use event detection over polling when possible
- Sleep appropriately in main loops (1-100s typical)
- Avoid busy-waiting
- Profile CPU usage: `top` or `htop`

### Memory Usage
- Limit log file sizes (10MB typical, with rotation)
- Clean up resources properly
- Avoid memory leaks in long-running processes
- Monitor with: `free -h`

### Storage
- Rotate logs to prevent disk fill
- Clean up temporary files
- Consider SD card wear for frequent writes
- Monitor disk usage: `df -h`

### Network
- Implement connection timeouts
- Handle network failures gracefully
- Rate-limit API calls if applicable
- Monitor with: `iftop` or `nethogs`

## Common Pitfalls and Solutions

### Pitfall 1: Hardcoded Configuration
**Problem:** Settings hardcoded in Python
**Solution:** Use config file at `/etc/luigi/{category}/{module}/`

### Pitfall 2: No Error Handling
**Problem:** Module crashes on hardware error
**Solution:** Wrap all GPIO/hardware operations in try/except

### Pitfall 3: No Cleanup
**Problem:** GPIO pins left in use after exit
**Solution:** Use try/finally and signal handlers

### Pitfall 4: Unsafe Wiring
**Problem:** 5V connected to GPIO input
**Solution:** Always verify voltage levels, use level shifters

### Pitfall 5: No Testing Without Hardware
**Problem:** Can't develop without Raspberry Pi
**Solution:** Implement mock GPIO support

### Pitfall 6: Poor Documentation
**Problem:** Users can't wire hardware correctly
**Solution:** Include detailed wiring diagram with pin numbers

### Pitfall 7: Service Doesn't Restart
**Problem:** Service dies and doesn't recover
**Solution:** Use systemd with `Restart=on-failure`

### Pitfall 8: Logs Fill Disk
**Problem:** Log files grow unbounded
**Solution:** Use RotatingFileHandler with size limits

## Design Templates and Tools

### Two-Stage Template System

Luigi uses a two-stage template system for module development:

**Stage 1: DESIGN_ANALYSIS.md** (Analysis phases - done first)
**Stage 2: IMPLEMENTATION_PLAN.md** (Implementation phases - created from analysis)

### DESIGN_ANALYSIS.md Template

**Purpose:** Initial analysis when feature request is received  
**Location:** `.github/skills/module-design/DESIGN_ANALYSIS.md`

This template captures:
- **Phase 1:** Requirements & Hardware Analysis
- **Phase 2:** Software Architecture Analysis
- **Phase 3:** Service & Deployment Analysis

**When to Use:**
- Upon receiving a feature request
- Before any implementation begins
- To analyze and design the approach

**How to Use:**
1. Copy `DESIGN_ANALYSIS.md` to project planning directory
2. Rename (e.g., `temp-sensor-DESIGN_ANALYSIS.md`)
3. Fill in all 3 analysis phases
4. Use referenced skills for detailed guidance
5. Get peer review and approval
6. Use results to create IMPLEMENTATION_PLAN.md

### IMPLEMENTATION_PLAN.md Template

**Purpose:** Implementation plan created from approved design analysis  
**Location:** `.github/skills/module-design/IMPLEMENTATION_PLAN.md`

This template contains:
- **Phase 1:** Setup & Deployment Implementation
- **Phase 2:** Testing Strategy Implementation
- **Phase 3:** Documentation Implementation
- **Phase 4:** Core Implementation
- **Phase 5:** Final Verification & Integration

**When to Use:**
- After DESIGN_ANALYSIS.md is complete and approved
- As the guide for implementation work

**How to Use:**
1. Copy `IMPLEMENTATION_PLAN.md` to project directory
2. Rename (e.g., `temp-sensor-IMPLEMENTATION_PLAN.md`)
3. Summarize key decisions from DESIGN_ANALYSIS.md
4. Fill in implementation tasks
5. Execute phases sequentially
6. Get sign-offs as you complete each phase

### Supporting Tools

**Hardware Design Checklist** (`hardware-design-checklist.md`)
- Component selection verification
- GPIO pin assignment checks
- Safety verification (voltage, current, polarity)
- Pre-power testing procedures
- **Use during:** DESIGN_ANALYSIS Phase 1

**Design Review Checklist** (`design-review-checklist.md`)
- Complete design review process
- Requirements through documentation
- Risk assessment
- Approval sign-offs
- **Use during:** IMPLEMENTATION_PLAN Phase 5

## Additional Resources

See also:
- `DESIGN_ANALYSIS.md` - **Analysis template (Stage 1 - use first)**
- `IMPLEMENTATION_PLAN.md` - **Implementation template (Stage 2 - use after analysis)**
- `hardware-design-checklist.md` - Hardware safety verification
- `design-review-checklist.md` - Complete design review
- `.github/skills/python-development/` - Implementation patterns
- `.github/skills/raspi-zero-w/` - Hardware and GPIO reference
- `.github/skills/system-setup/` - Deployment automation patterns

## Summary

Successful Luigi module design requires a **two-stage approach**:

**Stage 1: Design Analysis (DESIGN_ANALYSIS.md)**
1. **Safety First** - Analyze hardware and verify electrical safety
2. **Architecture Design** - Plan software structure and configuration
3. **Service Planning** - Design deployment and integration

**Stage 2: Implementation (IMPLEMENTATION_PLAN.md)**  
1. **Follow the Plan** - Execute based on approved analysis
2. **Test Thoroughly** - Validate at each phase
3. **Document Completely** - Ensure users can replicate setup
4. **Verify Integration** - Test with Luigi system
5. **Get Approval** - Final review before production

By separating analysis from implementation, you ensure that:
- Hardware safety is verified before building
- Software architecture is sound before coding
- Service integration is planned before deployment
- Implementation follows a proven design
7. **Integration** - Use systemd services with auto-restart
8. **Cleanup** - Always cleanup GPIO and resources on exit

By following these design guidelines, you'll create reliable, maintainable, and safe Luigi modules that integrate seamlessly with the platform.
