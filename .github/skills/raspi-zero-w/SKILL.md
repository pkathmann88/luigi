---
name: raspi-zero-w
description: Comprehensive guide for working with Raspberry Pi Zero W hardware, GPIO programming, and hardware setup. Use this skill when working with Raspberry Pi GPIO, hardware wiring, sensor integration, or Raspberry Pi specific code.
license: MIT
---

# Raspberry Pi Zero W Hardware Skill

This skill provides comprehensive guidance for working with Raspberry Pi Zero W hardware, including GPIO programming, hardware setup, wiring instructions, and troubleshooting.

## When to Use This Skill

Use this skill when:
- Setting up or configuring Raspberry Pi Zero W hardware
- Working with GPIO pins and sensors
- Implementing hardware interfaces (PIR sensors, buttons, LEDs, etc.)
- Debugging hardware connectivity issues
- Writing Python code that interacts with Raspberry Pi GPIO
- Planning hardware wiring and connections

## Hardware Overview

### Raspberry Pi Zero W Specifications

- **CPU**: 1GHz single-core ARM1176JZF-S
- **RAM**: 512MB
- **Wireless**: 802.11 b/g/n Wi-Fi, Bluetooth 4.1 LE
- **GPIO**: 40-pin header (same layout as Raspberry Pi 3/4)
- **Power**: 5V via micro-USB (minimum 1.2A recommended, 2A for stability)
- **Storage**: microSD card (minimum 8GB recommended, 16GB+ preferred)
- **OS**: Raspberry Pi OS (formerly Raspbian)

### GPIO Header Pinout

The Raspberry Pi Zero W has a 40-pin GPIO header. Pin numbering can be referenced in two ways:
- **Physical numbering**: Pins 1-40 (board position)
- **BCM (Broadcom) numbering**: GPIO0-GPIO27 (chip-specific)

**Always verify which numbering system your code uses!** This project uses **BCM numbering**.

See `gpio-pinout.md` in this directory for complete pinout reference.

## GPIO Programming with RPi.GPIO

### Basic GPIO Setup Pattern

```python
import RPi.GPIO as GPIO
import time

# Set numbering mode (BCM or BOARD)
GPIO.setmode(GPIO.BCM)  # Use BCM GPIO numbering

# Configure pin as input or output
GPIO.setup(23, GPIO.IN)   # Configure GPIO23 as input
GPIO.setup(18, GPIO.OUT)  # Configure GPIO18 as output

# Always clean up when done
try:
    # Your code here
    pass
finally:
    GPIO.cleanup()  # Reset GPIO pins to default state
```

### GPIO Modes

**BCM Mode** (`GPIO.BCM`):
- Uses Broadcom SOC channel numbers
- Example: GPIO23, GPIO24, GPIO25
- **Used in this project**
- More portable across Raspberry Pi models

**BOARD Mode** (`GPIO.BOARD`):
- Uses physical pin numbers (1-40)
- Example: Pin 16, Pin 18, Pin 22
- Position-based, easier for beginners

### Input Configuration

For sensors and buttons:

```python
# Basic input
GPIO.setup(23, GPIO.IN)

# Input with pull-up/pull-down resistor
GPIO.setup(23, GPIO.IN, pull_up_down=GPIO.PUD_UP)    # Pull-up
GPIO.setup(23, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)  # Pull-down

# Read input
state = GPIO.input(23)  # Returns True (HIGH) or False (LOW)
```

### Event Detection

For efficient sensor monitoring (recommended for motion sensors):

```python
# Detect rising edge (LOW to HIGH transition)
GPIO.add_event_detect(23, GPIO.RISING, callback=my_callback)

# Detect falling edge (HIGH to LOW transition)
GPIO.add_event_detect(23, GPIO.FALLING, callback=my_callback)

# Detect both edges
GPIO.add_event_detect(23, GPIO.BOTH, callback=my_callback)

# Callback function
def my_callback(channel):
    print(f"Event detected on GPIO{channel}")
```

### Output Configuration

For LEDs, relays, buzzers:

```python
GPIO.setup(18, GPIO.OUT)

# Set output state
GPIO.output(18, GPIO.HIGH)  # Turn on
GPIO.output(18, GPIO.LOW)   # Turn off

# Toggle
GPIO.output(18, not GPIO.input(18))
```

## Hardware Wiring Guidelines

### General Safety Rules

1. **Always power off before wiring**: Disconnect power from Raspberry Pi before connecting/disconnecting components
2. **Verify voltage levels**: Raspberry Pi GPIO operates at **3.3V logic levels** (5V will damage GPIO pins)
3. **Check polarity**: Ensure correct VCC/GND connections (reversed polarity can damage components)
4. **Use current limiting**: Add appropriate resistors for LEDs and other components
5. **Avoid short circuits**: Double-check connections before applying power

### Power Specifications

- **GPIO Output**: 3.3V, maximum 16mA per pin
- **Total GPIO Current**: Maximum 50mA across all pins
- **5V Rail**: Available on Pin 2 and Pin 4 (directly from power supply)
- **3.3V Rail**: Available on Pin 1 and Pin 17 (limited current, ~500mA total)

### Common Component Connections

#### PIR Motion Sensor (HC-SR501 or similar)

Standard 3-pin PIR sensors:
```
PIR Sensor          Raspberry Pi Zero W
----------          -------------------
VCC       -------->  5V (Pin 2 or 4)
GND       -------->  Ground (Pin 6, 9, 14, 20, 25, 30, 34, or 39)
OUT       -------->  GPIO Pin (e.g., GPIO23 = Pin 16)
```

**Notes**:
- PIR sensors typically require 5V power
- Output signal is 3.3V compatible (safe for GPIO)
- Most PIR sensors have adjustable sensitivity and delay potentiometers
- Allow 30-60 seconds for sensor calibration after power-on

#### LED Connection

Always use current-limiting resistor:
```
GPIO Pin ---> [220Ω Resistor] ---> LED Anode (+) ---> LED Cathode (-) ---> GND
```

**Resistor values**:
- Red LED: 220Ω (for 20mA at 3.3V)
- Green/Yellow LED: 220Ω
- Blue/White LED: 150Ω (higher forward voltage)

#### Button/Switch Connection

With internal pull-up:
```
GPIO Pin (with pull_up_down=GPIO.PUD_UP) ---> Button ---> GND
```

With internal pull-down:
```
3.3V ---> Button ---> GPIO Pin (with pull_up_down=GPIO.PUD_DOWN)
```

## Hardware Setup Process

### 1. Prepare Raspberry Pi Zero W

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Python GPIO library
sudo apt-get install python3-rpi.gpio python-rpi.gpio

# Install additional useful tools
sudo apt-get install i2c-tools python3-smbus
```

### 2. Enable Required Interfaces

For I2C, SPI, or other interfaces:
```bash
sudo raspi-config
# Navigate to: Interfacing Options
# Enable: SSH, I2C, SPI as needed
```

### 3. Test GPIO

Create a test script to verify GPIO functionality:

```python
#!/usr/bin/python3
import RPi.GPIO as GPIO
import time

GPIO.setmode(GPIO.BCM)
GPIO.setup(23, GPIO.IN)

try:
    print("Testing GPIO23 - Press Ctrl+C to exit")
    while True:
        state = GPIO.input(23)
        print(f"GPIO23 state: {'HIGH' if state else 'LOW'}")
        time.sleep(0.5)
except KeyboardInterrupt:
    print("\nExiting...")
finally:
    GPIO.cleanup()
```

Save as `test_gpio.py`, run with `sudo python3 test_gpio.py`

## Audio Setup (for sound playback projects)

### Configure Audio Output

```bash
# List audio devices
aplay -l

# Test audio output (3.5mm jack or HDMI)
speaker-test -t wav -c 2

# Adjust volume
alsamixer
# Use arrow keys to adjust, ESC to exit

# Install ALSA utilities
sudo apt-get install alsa-utils
```

### Select Audio Output

```bash
# Force 3.5mm jack
sudo raspi-config
# Navigate to: Advanced Options > Audio > Force 3.5mm jack

# Or via command line
amixer cset numid=3 1  # 3.5mm jack
amixer cset numid=3 2  # HDMI
amixer cset numid=3 0  # Auto
```

## Troubleshooting Guide

### GPIO Not Working

**Problem**: `RuntimeError: No access to /dev/mem`
**Solution**: Run script with `sudo python3 script.py`

**Problem**: `RuntimeError: GPIO already in use`
**Solution**: Call `GPIO.cleanup()` in previous script, or add at script start:
```python
GPIO.setwarnings(False)  # Suppress warnings
GPIO.cleanup()           # Reset all pins
```

**Problem**: Sensor not detecting
**Solutions**:
1. Verify wiring connections (VCC, GND, OUT)
2. Check sensor power (5V for most PIR sensors)
3. Allow calibration time (30-60 seconds after power-on)
4. Test sensor with multimeter (output should toggle 0V/3.3V)
5. Verify GPIO pin number matches code (BCM vs. BOARD)
6. Check sensor sensitivity adjustment (potentiometers)

### Audio Issues

**Problem**: No sound output
**Solutions**:
1. Check volume: `alsamixer`
2. Verify audio device: `aplay -l`
3. Test audio: `speaker-test -t wav -c 2`
4. Check file format (WAV recommended)
5. Verify permissions: `ls -l /path/to/sound/files`

**Problem**: Audio plays but distorted
**Solutions**:
1. Increase power supply current (use 2A+ adapter)
2. Check audio file sample rate (44.1kHz recommended)
3. Reduce system load

### Power Issues

**Problem**: Raspberry Pi randomly reboots or freezes
**Solutions**:
1. Use adequate power supply (minimum 2A for Raspberry Pi Zero W)
2. Check for loose micro-USB connection
3. Reduce connected peripherals
4. Check for undervoltage: Rainbow square icon on screen indicates low voltage

**Problem**: GPIO peripherals not working reliably
**Solutions**:
1. Verify power supply provides stable 5V
2. Measure voltage at 5V pin (should be 4.75V-5.25V)
3. Check for voltage drops with multimeter
4. Use powered USB hub for high-current USB devices

## Best Practices for Hardware Projects

### Code Best Practices

1. **Always use try/finally for GPIO cleanup**:
   ```python
   try:
       # Your code
   finally:
       GPIO.cleanup()
   ```

2. **Use event detection instead of polling** for sensors:
   ```python
   # Good: Event-driven (efficient)
   GPIO.add_event_detect(23, GPIO.RISING, callback=handler)
   
   # Avoid: Polling (wastes CPU)
   while True:
       if GPIO.input(23):
           handler()
       time.sleep(0.1)
   ```

3. **Add debouncing for buttons**:
   ```python
   GPIO.add_event_detect(23, GPIO.RISING, callback=handler, bouncetime=200)
   ```

4. **Handle errors gracefully**:
   ```python
   try:
       GPIO.setup(23, GPIO.IN)
   except RuntimeError as e:
       print(f"GPIO setup failed: {e}")
       sys.exit(1)
   ```

### Hardware Best Practices

1. **Use breadboard for prototyping** before soldering
2. **Color-code wires**: Red (5V/3.3V), Black (GND), others for signals
3. **Document pin assignments** in code comments and README
4. **Test incrementally**: Verify each component works individually
5. **Use female-to-female jumpers** for easy Raspberry Pi connections
6. **Keep wires short** to reduce interference
7. **Add external pull-up/pull-down resistors** for critical signals (10kΩ typical)

### Safety Checklist

Before powering on:
- [ ] All connections verified against pinout diagram
- [ ] No GPIO pins connected to 5V (except 5V rail pins)
- [ ] Polarity correct for all components (VCC/GND)
- [ ] No short circuits between adjacent pins
- [ ] Power supply adequate (2A+ recommended)
- [ ] Components rated for correct voltage (3.3V logic, 5V power)

## Project-Specific Implementation

### Current Project: Motion Detection

**Hardware Configuration**:
- **PIR Sensor**: GPIO23 (BCM), Physical Pin 16
- **Power**: 5V from Pin 2 or 4
- **Ground**: Any GND pin (Pin 6, 9, 14, 20, 25, 30, 34, 39)
- **Audio**: 3.5mm jack or HDMI output

**Code Pattern Used**:
```python
GPIO.setmode(GPIO.BCM)
GPIO.setup(SENSOR_PIN, GPIO.IN)
GPIO.add_event_detect(SENSOR_PIN, GPIO.RISING, callback=check)
```

**Key Implementation Details**:
- Uses BCM numbering (GPIO.BCM)
- Rising edge detection for motion events
- Event-driven callback pattern
- No pull-up/pull-down (PIR sensor provides clean signal)

### Testing Hardware Setup

1. **Visual inspection**: Check all connections match wiring diagram
2. **Power test**: Measure 5V and 3.3V rails with multimeter
3. **GPIO test**: Run test script to verify sensor input
4. **Audio test**: Play test sound with `aplay`
5. **Integration test**: Run full application

## Additional Resources

- **GPIO Pinout Reference**: See `gpio-pinout.md` in this directory
- **Wiring Diagram**: See `wiring-diagram.md` in this directory
- **Official Documentation**: https://www.raspberrypi.com/documentation/computers/raspberry-pi.html
- **RPi.GPIO Documentation**: https://sourceforge.net/p/raspberry-gpio-python/wiki/Home/
- **Pinout Interactive**: https://pinout.xyz

## Common GPIO Pin Assignments (BCM)

Suggested pins for different purposes:

**Input Sensors** (with event detection):
- GPIO23, GPIO24, GPIO25 (no overlapping functions)

**Output Control** (LEDs, relays):
- GPIO18 (PWM capable)
- GPIO12, GPIO13 (PWM capable)
- GPIO16, GPIO20, GPIO21 (general purpose)

**Reserved/Special Purpose** (avoid unless needed):
- GPIO2, GPIO3 (I2C - SDA, SCL)
- GPIO9, GPIO10, GPIO11 (SPI)
- GPIO14, GPIO15 (UART - TX, RX)

## Development Workflow

1. **Plan hardware connections**: Create wiring diagram
2. **Document pin assignments**: Update code comments and README
3. **Test on breadboard**: Verify each component individually
4. **Write and test code**: Start with simple GPIO test scripts
5. **Integrate components**: Combine working modules
6. **Deploy to production**: Transfer to permanent connections if needed
7. **Document setup**: Update documentation with final configuration

## Important Reminders

- **RPi.GPIO requires sudo**: Always run GPIO scripts with `sudo python3 script.py`
- **Cleanup is essential**: Always call `GPIO.cleanup()` to prevent conflicts
- **BCM vs. BOARD**: Verify numbering mode matches your pin references
- **3.3V logic only**: Never connect 5V signals directly to GPIO inputs
- **Power supply matters**: Use quality 2A+ power supply for stability
- **Allow sensor calibration**: PIR sensors need 30-60 seconds after power-on
- **Test audio separately**: Verify audio works before integrating with GPIO
