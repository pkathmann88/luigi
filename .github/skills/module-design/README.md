# Module Design Skill - Quick Reference

This is a quick reference guide for using the Luigi Module Design Skill effectively.

## What is the Module Design Skill?

The module-design skill provides comprehensive guidance for **designing Luigi modules BEFORE implementation**. It ensures hardware safety, proper architecture, and maintainability through a structured design process.

## When to Use This Skill

Use this skill at the **design phase** before writing any code:

✅ **Use module-design skill when:**
- Planning a new Luigi module
- Selecting hardware components
- Designing wiring connections
- Planning GPIO pin assignments
- Architecting software structure
- Defining configuration options
- Creating documentation structure

❌ **Don't use this skill for:**
- Writing Python code (use `python-development` skill)
- Implementing hardware connections (use `raspi-zero-w` skill)
- Writing deployment scripts (use `system-setup` skill)
- These are implementation tasks, not design tasks

## Skill Files

The module-design skill includes four files:

### 1. SKILL.md (Main Skill)
**Purpose:** Comprehensive design guidance  
**Size:** 1,085 lines  
**Use for:** Understanding design principles, patterns, and best practices

**Key Sections:**
- Design philosophy and principles
- Hardware design guidelines (safety, GPIO, wiring, power)
- Software architecture design
- Service integration design
- Testing strategy design
- Documentation design
- Security considerations
- Design patterns and examples

### 2. hardware-design-checklist.md
**Purpose:** Hardware safety and design verification  
**Size:** 227 lines  
**Use for:** Verifying electrical safety, GPIO assignments, and wiring

**Key Sections:**
- Component selection verification
- GPIO pin selection checklist
- Wiring safety verification
- Power supply design
- Pre-power testing checklist
- Documentation requirements

### 3. design-review-checklist.md
**Purpose:** Complete design review before implementation  
**Size:** 389 lines  
**Use for:** Comprehensive review of all design aspects

**Key Sections:**
- Requirements analysis verification
- Hardware design review
- Software architecture review
- Security review
- Service integration review
- Setup script review
- Documentation review
- Risk assessment

### 4. module-design-template.md
**Purpose:** Fillable design document template  
**Size:** 595 lines  
**Use for:** Documenting your module design systematically

**Key Sections:**
- Module information and overview
- Hardware design (components, wiring, power)
- Software architecture (classes, config, logging)
- Service integration
- Setup script design
- Testing strategy
- Documentation plan
- Security review
- Timeline and milestones
- Sign-off section

## Design Process Workflow

Follow this workflow when designing a new module:

```
1. Read SKILL.md
   ↓
2. Fill out module-design-template.md
   ↓
3. Complete hardware-design-checklist.md
   ↓
4. Complete design-review-checklist.md
   ↓
5. Get peer review
   ↓
6. Address feedback
   ↓
7. Design approved → Ready for implementation
```

## Key Design Principles

### 1. Safety First
- Verify all voltage levels (3.3V GPIO safe)
- Check current requirements
- Validate polarity before power-on
- Use protection components (resistors, diodes)

### 2. Follow Luigi Patterns
- Module structure: `category/module-name/`
- Configuration: `/etc/luigi/{category}/{module-name}/`
- Service: systemd with auto-restart
- Setup: `setup.sh` with install/uninstall/status

### 3. Design for Safety
- No 5V directly to GPIO inputs
- Current limiting resistors for LEDs
- Diode protection for inductive loads
- Clear wiring diagrams with pin numbers

### 4. Design for Security
- No shell injection (use subprocess with list)
- Path traversal prevention
- Log sanitization
- Subprocess timeouts

### 5. Design for Testing
- Mock GPIO support
- Syntax validation without hardware
- Clear test strategy (unit, integration, hardware)

## Common Design Tasks

### Selecting GPIO Pins

**Priority:**
1. General purpose pins (GPIO23, GPIO24, GPIO25) - Use these first
2. PWM pins (GPIO18, GPIO12, GPIO13) - If you need PWM
3. Special pins (I2C, SPI, UART) - Only if you need these interfaces

**Document both:**
- BCM number (e.g., GPIO23)
- Physical pin number (e.g., Pin 16)

### Creating Wiring Diagrams

**Include:**
- Component pin names
- Raspberry Pi pins (BCM and physical)
- Connection arrows
- Inline components (resistors, diodes)
- Power connections (VCC, GND)
- Safety notes

**Format:**
```
Component        Raspberry Pi Zero W
---------        -------------------
VCC      ------> 5V (Pin 2 or 4)
GND      ------> Ground (Pin 6)
Data     ------> GPIO23 (Pin 16)
```

### Designing Configuration

**Location:** `/etc/luigi/{category}/{module-name}/{module-name}.conf`

**Format:** INI-style with sections
```ini
[Hardware]
INPUT_PIN=23

[Timing]
COOLDOWN=1800

[Files]
LOG_FILE=/var/log/module.log

[Logging]
LOG_LEVEL=INFO
```

### Planning Testing

**Three levels:**
1. **Syntax:** `python3 -m py_compile module.py`
2. **Logic:** Mock GPIO tests without hardware
3. **Integration:** Hardware tests on actual Raspberry Pi

## Example: Designing a Temperature Monitor

### 1. Requirements
- Read temperature from DHT22 sensor
- Log readings every 5 minutes
- Alert if temperature exceeds threshold
- Web dashboard to view data

### 2. Hardware Design
- Component: DHT22 sensor (3.3V compatible)
- GPIO: GPIO4 (Pin 7) - supports DHT22 protocol
- Wiring: VCC to 3.3V, GND to GND, Data to GPIO4
- Power: Within Raspberry Pi capacity

### 3. Software Design
- Config class: Load settings
- GPIOManager: Initialize GPIO
- DHT22Sensor: Read temperature/humidity
- TempMonitorApp: Main logic with threshold checks
- Configuration: Poll interval, thresholds, alerting

### 4. Safety Checks
- DHT22 is 3.3V compatible ✅
- Current draw ~2.5mA (well within limits) ✅
- No special protection needed ✅
- Wiring diagram created ✅

### 5. Ready for Implementation
- Design documented in template ✅
- Hardware checklist complete ✅
- Design review complete ✅
- Approved → Start implementation

## Integration with Other Skills

The four Luigi skills work together:

```
module-design (DESIGN PHASE)
    ↓
    Use raspi-zero-w for hardware details
    Use python-development for code patterns
    ↓
python-development (IMPLEMENTATION PHASE)
    ↓
system-setup (DEPLOYMENT PHASE)
```

**Design Phase (module-design):**
- What to build
- How to connect hardware safely
- Software architecture plan
- Configuration structure

**Implementation Phase (python-development, raspi-zero-w):**
- Write Python code
- Connect hardware
- Test components
- Implement planned design

**Deployment Phase (system-setup):**
- Create setup script
- Package for distribution
- Deploy to Raspberry Pi
- Verify installation

## Tips for Effective Design

### DO:
✅ Complete design before writing code  
✅ Document all hardware connections  
✅ Verify safety with checklists  
✅ Get peer review before implementation  
✅ Use the design template systematically  
✅ Reference the SKILL.md for patterns  
✅ Plan for testing without hardware  

### DON'T:
❌ Skip safety verification  
❌ Start coding before design is complete  
❌ Forget to document GPIO pins  
❌ Ignore power calculations  
❌ Skip the design review checklist  
❌ Connect hardware without wiring diagram  
❌ Forget Mock GPIO support  

## Getting Help

### Questions About Design
- Read SKILL.md relevant sections
- Check design examples in SKILL.md
- Review Mario module as reference
- Use the design template as guide

### Hardware Safety Questions
- Review hardware-design-checklist.md
- Check voltage compatibility
- Verify current requirements
- Consult datasheets

### Complete Design Review
- Use design-review-checklist.md
- Complete all sections
- Get peer review
- Address all concerns before implementation

## Quick Checklist

Before starting implementation, verify:

- [ ] Design documented in template
- [ ] Hardware components selected and verified
- [ ] GPIO pins assigned and documented
- [ ] Wiring diagram created with safety notes
- [ ] Power budget calculated
- [ ] Software architecture defined
- [ ] Configuration structure planned
- [ ] Security considerations addressed
- [ ] Testing strategy defined
- [ ] Documentation structure planned
- [ ] Hardware checklist complete
- [ ] Design review checklist complete
- [ ] Peer review completed
- [ ] All risks identified and mitigated
- [ ] Design approved for implementation

## Summary

The module-design skill ensures:
1. **Safe hardware connections** - No damage to Raspberry Pi or components
2. **Proper architecture** - Maintainable, testable, secure code
3. **Complete documentation** - Clear instructions for users
4. **Successful implementation** - Design issues caught early

**Remember:** Time spent in design saves debugging time during implementation!

---

**Version:** 1.0  
**Last Updated:** 2024-02-10  
**Related Skills:** python-development, raspi-zero-w, system-setup
