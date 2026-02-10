# Hardware Design Checklist for Luigi Modules

Use this checklist when designing the hardware aspects of a Luigi module. Complete each section before moving to implementation.

## Component Selection

### Electrical Specifications
- [ ] Component voltage: 3.3V compatible or level-shifted
- [ ] Component current draw: Within GPIO limits (16mA per pin, 50mA total)
- [ ] Component power requirements: Documented with specific values
- [ ] Operating temperature range: Suitable for deployment environment
- [ ] Input/output characteristics: Match GPIO specifications

### Practical Considerations
- [ ] Component availability: Easily sourced from common suppliers
- [ ] Component cost: Within project budget
- [ ] Component size: Fits in planned enclosure/mounting
- [ ] Component reliability: Known good track record or tested
- [ ] Datasheet available: Complete specifications accessible
- [ ] Alternative components: Backup options identified

## GPIO Pin Selection

### Pin Assignment
- [ ] Pin number documented: Both BCM and physical numbers
- [ ] Pin function verified: Input, output, PWM, special function
- [ ] Pin availability checked: Not used by other active modules
- [ ] Pin conflicts avoided: No overlap with system reservations
- [ ] Pin grouping logical: Related signals near each other

### Pin Requirements
- [ ] Input pins: Pull-up/pull-down requirements identified
- [ ] Output pins: Drive strength requirements verified
- [ ] PWM pins: Frequency and duty cycle requirements defined
- [ ] Special function pins: I2C, SPI, UART usage justified
- [ ] Ground pins: Adequate ground connections planned

## Wiring Design

### Connection Planning
- [ ] Wiring diagram created: Clear ASCII art or image
- [ ] Pin-to-pin mapping: Complete list of all connections
- [ ] Wire lengths estimated: Keep signal wires short
- [ ] Wire gauge selected: Appropriate for current
- [ ] Connector types chosen: Reliable and appropriate

### Safety Verification

#### Voltage Safety
- [ ] All GPIO inputs: 3.3V max verified
- [ ] 5V signals: Level shifters or voltage dividers added
- [ ] Power rail connections: Correct voltage to each component
- [ ] Voltage tolerance: All components within spec

#### Current Safety
- [ ] LED current limiting: Resistors calculated and added
- [ ] Total GPIO current: Sum of all pins under 50mA limit
- [ ] Individual pin current: Each pin under 16mA limit
- [ ] Inrush current: Considered for capacitive loads

#### Polarity Safety
- [ ] VCC/GND connections: Double-checked before power-on
- [ ] Polarized components: Orientation clearly marked
- [ ] Diode protection: Added for inductive loads (relays, motors)
- [ ] Reverse polarity: Protection diodes or blocking diodes added

#### Short Circuit Prevention
- [ ] Adjacent pin spacing: Verified on breadboard/PCB
- [ ] Solder bridges: Inspected before power-on
- [ ] Wire routing: Checked for potential shorts
- [ ] Continuity testing: Plan for pre-power-on verification

### Protection Components

#### ESD Protection
- [ ] Sensitive components: ESD protection considered
- [ ] Input clamping: Diodes to 3.3V and GND if needed
- [ ] TVS diodes: Added for exposed connections

#### Overcurrent Protection
- [ ] Fuses: Added for external power connections
- [ ] Current limiting resistors: Added where needed
- [ ] Thermal considerations: Heat dissipation planned

#### Isolation
- [ ] High voltage circuits: Optoisolators added
- [ ] Ground loops: Avoided or broken
- [ ] Noise sources: Isolated from sensitive circuits

## Power Supply Design

### Power Budget
- [ ] Raspberry Pi: Base 150mA accounted for
- [ ] GPIO outputs: Calculated per pin (8-10mA typical)
- [ ] USB devices: Individual current draws listed
- [ ] External components: All current requirements summed
- [ ] Total power: Within supply capacity with margin

### Power Supply Specification
- [ ] Voltage: 5V for Raspberry Pi via micro-USB
- [ ] Current capacity: Minimum 2A, more if needed
- [ ] Regulation: Quality supply with stable output
- [ ] Connector: Micro-USB or appropriate for model

### External Power
- [ ] Separate supply needed: Yes/No decision made
- [ ] External voltage: Specified (5V, 12V, etc.)
- [ ] Ground connection: Shared with Raspberry Pi
- [ ] Switching/control: GPIO control circuit designed
- [ ] Isolation: Optoisolation if required

## Wiring Diagram Quality

### Diagram Completeness
- [ ] All components shown: Nothing omitted
- [ ] All connections shown: Every wire documented
- [ ] Pin numbers included: BCM and physical both shown
- [ ] Component values: Resistor values, capacitor values noted
- [ ] Power connections: VCC and GND clearly shown

### Diagram Clarity
- [ ] ASCII art readable: Clear alignment and spacing
- [ ] Connection direction: Arrows or clear left-to-right
- [ ] Component orientation: Polarity indicators shown
- [ ] Notes and labels: Important details annotated
- [ ] Color coding: Wire colors noted if standardized

### Safety Documentation
- [ ] Voltage warnings: Highlighted in diagram
- [ ] Polarity warnings: Clearly marked
- [ ] Component orientation: Polarity shown for LEDs, diodes, etc.
- [ ] External power: Clearly indicated and labeled
- [ ] Test points: Marked for verification

## Physical Assembly

### Breadboard Layout
- [ ] Component placement: Logical and accessible
- [ ] Wire routing: Clean and organized
- [ ] Strain relief: Connectors secured
- [ ] Access: Adjustment pots and switches accessible
- [ ] Inspection: Easy to verify connections

### Permanent Installation
- [ ] PCB design: Layout planned if applicable
- [ ] Enclosure: Suitable case selected
- [ ] Mounting: Secure attachment method
- [ ] Cooling: Airflow if components run hot
- [ ] Access panels: For maintenance and adjustment

## Testing Plan

### Pre-Power Testing
- [ ] Visual inspection: All connections verified
- [ ] Continuity test: Connections verified with multimeter
- [ ] Resistance check: No shorts between power rails
- [ ] Polarity check: VCC/GND connections verified
- [ ] Component orientation: All polarized parts checked

### Initial Power-On
- [ ] Power supply voltage: Measured before connecting
- [ ] Low power test: Power on with minimal load first
- [ ] Voltage rails: Verify 5V and 3.3V correct
- [ ] Component power: Each component receiving correct voltage
- [ ] No smoke test: Watch for overheating or smoke

### Functional Testing
- [ ] Input testing: Verify GPIO inputs read correctly
- [ ] Output testing: Verify GPIO outputs work
- [ ] Sensor testing: Verify sensor readings
- [ ] Actuator testing: Verify control functions
- [ ] Integration testing: Test complete system

## Documentation

### Wiring Documentation
- [ ] Schematic diagram: Complete circuit diagram
- [ ] Breadboard layout: Physical layout shown
- [ ] Pin mapping table: All connections in table form
- [ ] Component list: BOM with part numbers
- [ ] Assembly instructions: Step-by-step guide

### Safety Documentation
- [ ] Voltage warnings: Documented in README
- [ ] Current limitations: Clearly stated
- [ ] Proper shutdown: Procedure documented
- [ ] Emergency stop: Method documented
- [ ] Hazards identified: All risks noted

### Troubleshooting Documentation
- [ ] Common issues: Listed with solutions
- [ ] Test procedures: Verification steps documented
- [ ] Measurement points: Where to probe with multimeter
- [ ] LED indicators: Meaning of status lights
- [ ] Error conditions: How to identify and fix

## Pre-Implementation Sign-Off

### Design Review Complete
- [ ] All checklist items reviewed
- [ ] Design peer-reviewed: Second person verified
- [ ] Safety analysis complete: All hazards addressed
- [ ] Bill of materials: All parts identified
- [ ] Budget approved: Costs within limits

### Ready for Implementation
- [ ] Wiring diagram finalized: No changes expected
- [ ] Components ordered: Parts on hand or ordered
- [ ] Tools available: All necessary equipment ready
- [ ] Test plan ready: Know how to verify design
- [ ] Documentation started: README template prepared

## Notes

- Complete this checklist **before** building hardware
- Review each section carefully
- Document any deviations from standards
- Update checklist if issues found during implementation
- Keep checklist with project documentation

## Approval

**Design Completed By:** _____________________ **Date:** __________

**Design Reviewed By:** _____________________ **Date:** __________

**Safety Review By:** _____________________ **Date:** __________
