# Module Design Skill - Quick Reference

This is a quick reference guide for using the Luigi Module Design Skill effectively.

## What is the Module Design Skill?

The module-design skill provides comprehensive guidance for **designing Luigi modules BEFORE implementation**. It ensures hardware safety, proper architecture, and maintainability through a **two-stage workflow**:

1. **Stage 1:** Design Analysis (3 analysis phases)
2. **Stage 2:** Implementation Plan (5 implementation phases)

## When to Use This Skill

Use this skill when you receive a feature request:

✅ **Use module-design skill when:**
- Receiving a feature request for a new module
- Analyzing hardware requirements
- Designing software architecture
- Planning service integration
- Creating implementation plans

❌ **Don't use this skill for:**
- Writing Python code (use `python-development` skill)
- Implementing hardware connections (use `raspi-zero-w` skill)
- Writing deployment scripts (use `system-setup` skill)
- These are implementation tasks in Stage 2

## Skill Files

The module-design skill includes six files:

### 1. SKILL.md (Main Skill)
**Purpose:** Comprehensive design guidance and two-stage process overview  
**Size:** ~1,200 lines  
**Use for:** Understanding the complete design workflow

**Key Sections:**
- Two-stage workflow explanation
- Hardware design guidelines (safety, GPIO, wiring, power)
- Software architecture design
- Service integration design
- Testing strategy design
- Documentation design
- Security considerations
- Design patterns and examples

### 2. DESIGN_ANALYSIS.md (Stage 1 Template)
**Purpose:** Initial analysis template when feature request received  
**Size:** ~400 lines  
**Use for:** Analyzing and designing before implementation

**3 Analysis Phases:**
1. Requirements & Hardware Analysis
2. Software Architecture Analysis
3. Service & Deployment Analysis

**Each phase includes:**
- Clear goals and skills to reference
- Analysis tasks with checklists
- Design decision documentation
- Risk identification
- Sign-off sections

**Use this FIRST when you receive a feature request.**

### 3. IMPLEMENTATION_PLAN.md (Stage 2 Template)
**Purpose:** Implementation plan created from approved design analysis  
**Size:** ~520 lines  
**Use for:** Executing implementation after analysis is approved

**5 Implementation Phases:**
1. Setup & Deployment Implementation
2. Testing Strategy Implementation
3. Documentation Implementation
4. Core Implementation
5. Final Verification & Integration

**Each phase includes:**
- Implementation tasks with checklists
- References to DESIGN_ANALYSIS decisions
- Verification steps
- Sign-off sections

**Use this AFTER DESIGN_ANALYSIS.md is approved.**

### 4. hardware-design-checklist.md
**Purpose:** Hardware safety and design verification  
**Size:** 227 lines  
**Use for:** DESIGN_ANALYSIS Phase 1

**Key Sections:**
- Component selection verification
- GPIO pin selection checklist
- Wiring safety verification
- Power supply design
- Pre-power testing checklist
- Documentation requirements

### 5. design-review-checklist.md
**Purpose:** Complete design review  
**Size:** 389 lines  
**Use for:** IMPLEMENTATION_PLAN Phase 5

**Key Sections:**
- Requirements analysis verification
- Hardware design review
- Software architecture review
- Security review
- Service integration review
- Setup script review
- Documentation review
- Risk assessment

### 6. README.md (This File)
**Purpose:** Quick reference guide  
**Use for:** Quick overview and workflow guidance

## Design Process Workflow

The Luigi module design process uses a **two-stage workflow**:

```
Feature Request Received
    ↓
STAGE 1: Design Analysis
    ↓
Step 1: Copy DESIGN_ANALYSIS.md template
    ↓
Step 2: Complete Analysis Phases 1-3
    ↓
    Phase 1: Requirements & Hardware Analysis
        ↓ (use module-design + raspi-zero-w skills)
    Phase 2: Software Architecture Analysis
        ↓ (use module-design + python-development skills)
    Phase 3: Service & Deployment Analysis
        ↓ (use module-design + system-setup skills)
    ↓
Step 3: Get peer review on analysis
    ↓
Step 4: Address feedback and get approval
    ↓
STAGE 2: Implementation
    ↓
Step 5: Create IMPLEMENTATION_PLAN.md from approved analysis
    ↓
Step 6: Execute Implementation Phases 1-5
    ↓
    Phase 1: Setup & Deployment (use system-setup)
    Phase 2: Testing Strategy (use python-development + raspi-zero-w)
    Phase 3: Documentation (use module-design)
    Phase 4: Core Implementation (use all skills)
    Phase 5: Final Verification (use module-design)
    ↓
Step 7: Final approval and production deployment
    ↓
✓ Module Complete
```

### Two-Stage Workflow Details

**STAGE 1: Design Analysis (DESIGN_ANALYSIS.md)**
- **When:** Upon receiving feature request
- **Purpose:** Analyze and design before implementation
- **Output:** Approved design document
- **Phases:** 3 analysis phases
  1. Requirements & Hardware Analysis
  2. Software Architecture Analysis
  3. Service & Deployment Analysis

**STAGE 2: Implementation (IMPLEMENTATION_PLAN.md)**
- **When:** After DESIGN_ANALYSIS.md is approved
- **Purpose:** Execute the implementation
- **Input:** Results from DESIGN_ANALYSIS.md
- **Phases:** 5 implementation phases
  1. Setup & Deployment Implementation
  2. Testing Strategy Implementation
  3. Documentation Implementation
  4. Core Implementation
  5. Final Verification & Integration

### Why Two Stages?

**Benefits:**
- **Safety**: Hardware design verified before building
- **Quality**: Software architecture validated before coding
- **Efficiency**: Avoid rework by catching issues in analysis
- **Traceability**: Implementation directly references design decisions

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
