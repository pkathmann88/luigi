# Wiring Diagrams for Raspberry Pi Zero W Projects

## Current Project: PIR Motion Sensor with Audio Playback

### Component List
- Raspberry Pi Zero W
- HC-SR501 PIR Motion Sensor (or compatible)
- Speakers or headphones (3.5mm jack or HDMI audio)
- Female-to-female jumper wires (3 minimum)
- 5V 2A+ micro-USB power supply

### Wiring Diagram (Text)

```
┌─────────────────────────────────────────────────┐
│         Raspberry Pi Zero W (Top View)         │
│                                                 │
│  3V3  [1] [2]  5V  ←───────────────┐           │
│ GPIO2 [3] [4]  5V                  │           │
│ GPIO3 [5] [6]  GND ←────────┐      │           │
│ GPIO4 [7] [8]  GPIO14       │      │           │
│   GND [9] [10] GPIO15       │      │           │
│GPIO17 [11][12] GPIO18       │      │           │
│GPIO27 [13][14] GND          │      │           │
│GPIO22 [15][16] GPIO23 ←──┐  │      │           │
│  3V3  [17][18] GPIO24    │  │      │           │
│GPIO10 [19][20] GND       │  │      │           │
│ GPIO9 [21][22] GPIO25    │  │      │           │
│GPIO11 [23][24] GPIO8     │  │      │           │
│   GND [25][26] GPIO7     │  │      │           │
│ GPIO0 [27][28] GPIO1     │  │      │           │
│ GPIO5 [29][30] GND       │  │      │           │
│ GPIO6 [31][32] GPIO12    │  │      │           │
│GPIO13 [33][34] GND       │  │      │           │
│GPIO19 [35][36] GPIO16    │  │      │           │
│GPIO26 [37][38] GPIO20    │  │      │           │
│   GND [39][40] GPIO21    │  │      │           │
│                           │  │      │           │
│  ┌─────────────────┐     │  │      │           │
│  │  3.5mm Audio    │     │  │      │           │
│  │  Jack Output    │◄────┼──┼──┐   │           │
│  └─────────────────┘     │  │  │   │           │
│                           │  │  │   │           │
│  ┌─────────────────┐     │  │  │   │           │
│  │  Micro USB      │     │  │  │   │           │
│  │  Power Input    │     │  │  │   │           │
│  └─────────────────┘     │  │  │   │           │
└───────────────────────────┼──┼──┼───┼───────────┘
                            │  │  │   │
                            │  │  │   │
         ┌──────────────────┘  │  │   │
         │  ┌──────────────────┘  │   │
         │  │  ┌──────────────────┘   │
         │  │  │                      │
         │  │  │                      │
    ┌────▼──▼──▼────┐                │
    │  PIR Sensor   │                │
    │   HC-SR501    │                │
    ├───────────────┤                │
    │ VCC  OUT  GND │                │
    │  │    │    │  │                │
    └──┼────┼────┼──┘                │
       │    │    └───────────────────┘
       │    └── OUT Signal (3.3V)
       └── 5V Power
            (PIR sensor requires 5V,
             but OUT signal is 3.3V compatible)

Connection Summary:
PIR VCC (Red)    → Raspberry Pi Pin 2 (5V)
PIR OUT (Yellow) → Raspberry Pi Pin 16 (GPIO23)
PIR GND (Black)  → Raspberry Pi Pin 6 (GND)

Audio Output → 3.5mm speakers/headphones plugged into Pi audio jack
```

### Step-by-Step Wiring Instructions

**⚠️ IMPORTANT: Disconnect power from Raspberry Pi before wiring!**

1. **Identify PIR Sensor Pins**
   - Most HC-SR501 sensors have 3 pins labeled:
     - VCC (or +, or V+) - Power input
     - OUT (or Signal, or Data) - Output signal
     - GND (or -, or G) - Ground

2. **Connect PIR VCC to 5V**
   - Color: Red wire (recommended)
   - From: PIR sensor VCC pin
   - To: Raspberry Pi Pin 2 (5V) or Pin 4 (5V)
   - Note: Either 5V pin works; Pin 2 is closer to the corner

3. **Connect PIR GND to Ground**
   - Color: Black wire (recommended)
   - From: PIR sensor GND pin
   - To: Raspberry Pi Pin 6 (GND)
   - Note: Any GND pin works; Pin 6 is convenient

4. **Connect PIR OUT to GPIO23**
   - Color: Yellow, white, or green wire
   - From: PIR sensor OUT pin
   - To: Raspberry Pi Pin 16 (GPIO23 in BCM mode)
   - Note: This is the signal pin that detects motion

5. **Connect Audio Output**
   - Plug speakers or headphones into the 3.5mm audio jack
   - Or use HDMI audio if connected to HDMI monitor with speakers

6. **Connect Power Supply**
   - Connect 5V 2A+ micro-USB power supply to Raspberry Pi
   - Power LED should light up
   - Wait 30-60 seconds for PIR sensor to calibrate

### Physical Layout Diagram

```
Top-down view showing physical placement:

        ┌─────────────────┐
        │  Speakers/      │
        │  Headphones     │
        └────────┬────────┘
                 │ (3.5mm audio)
                 ↓
    ┌────────────────────────┐
    │                        │◄── 3.5mm jack
    │   Raspberry Pi Zero W  │
    │   ┌──────────────────┐ │
    │   │ 40-pin GPIO      │ │
    │   │ Header          │ │
    │   └──────────────────┘ │
    │                        │
    └────────────────────────┘
            │ │ │
            │ │ └── Black wire (GND)
            │ └──── Red wire (5V)
            └────── Yellow wire (GPIO23)
            │ │ │
    ┌───────┴─┴─┴──────┐
    │   PIR Sensor      │
    │   HC-SR501        │
    │  [Dome on top]    │
    │                   │
    │  ┌─┐ ┌─┐         │
    │  │S│ │D│  ←─── Adjustment potentiometers
    │  └─┘ └─┘         │
    └───────────────────┘
    
S = Sensitivity adjustment
D = Delay time adjustment
```

### Wire Color Coding (Recommended)

| Connection | Recommended Color | Notes                           |
|------------|-------------------|---------------------------------|
| 5V Power   | Red               | Standard for positive power     |
| Ground     | Black             | Standard for ground/negative    |
| GPIO23     | Yellow/Green      | Signal wire, any color but      |
|            |                   | avoid red/black for clarity     |

### PIR Sensor Potentiometer Adjustments

Most HC-SR501 sensors have two potentiometers on the back:

1. **Sensitivity (S or Sx)**
   - Clockwise: Increase detection range (up to ~7 meters)
   - Counter-clockwise: Decrease detection range
   - Start: Middle position, adjust based on testing

2. **Delay Time (D or Tx)**
   - Clockwise: Longer output pulse (up to ~300 seconds)
   - Counter-clockwise: Shorter output pulse (~0.3 seconds)
   - Start: Minimum (counter-clockwise) for this project
   - Note: Project uses software cooldown, not sensor delay

3. **Trigger Mode (Jumper)**
   - Some sensors have a jumper for trigger mode:
     - H: Repeatable trigger (motion extends output)
     - L: Single trigger (fixed pulse duration)
   - Set to L (single trigger) for this project

### Troubleshooting Wiring

#### Visual Inspection Checklist
- [ ] Red wire connects PIR VCC to Pi 5V (Pin 2 or 4)
- [ ] Black wire connects PIR GND to Pi GND (Pin 6 recommended)
- [ ] Signal wire connects PIR OUT to Pi Pin 16 (GPIO23)
- [ ] No wires touching adjacent pins (risk of short circuit)
- [ ] All connections secure (push firmly into GPIO header)
- [ ] PIR sensor facing outward (dome/lens not obstructed)

#### Multimeter Verification
With Raspberry Pi powered ON:

1. **Check 5V Power**
   - Measure between PIR VCC and PIR GND
   - Should read ~5V (4.75V-5.25V acceptable)
   - If low: Check power supply and connections

2. **Check Ground**
   - Measure between Pi GND pin and PIR GND
   - Should read 0V (continuity)
   - If not: Check GND wire connection

3. **Check Signal Output**
   - Measure PIR OUT to GND with motion
   - Should toggle between 0V (no motion) and 3.3V (motion detected)
   - If always 0V: Check PIR power, wait for calibration
   - If always 3.3V: Adjust sensitivity potentiometer

## Alternative Wiring: External Power Supply for Sensors

For projects with multiple sensors or higher current needs:

```
External 5V Power Supply
    │
    ├─────► PIR Sensor VCC
    │
    └─────► Raspberry Pi 5V Pin (optional, if not USB powered)
    
Common Ground:
    External PSU GND ────┬──── PIR Sensor GND
                         │
                         └──── Raspberry Pi GND

Signal:
    PIR Sensor OUT ──────────► Raspberry Pi GPIO23
```

**Important**: When using external power, **always connect grounds together** (common ground). Never power Raspberry Pi from GPIO 5V pin and USB simultaneously.

## Safety Warnings

### Critical Safety Rules

⚠️ **Voltage Limits**
- Never connect 5V signals directly to GPIO pins (maximum 3.3V)
- 5V power sensors with 3.3V output signals are safe (like HC-SR501)
- Use level shifters for 5V logic devices

⚠️ **Current Limits**
- Each GPIO pin: Maximum 16mA
- All GPIO pins combined: Maximum 50mA
- Use external transistors/MOSFETs for high-current loads

⚠️ **Polarity**
- Reversed polarity can permanently damage components
- Double-check VCC and GND before powering on
- Use colored wires consistently (Red=5V, Black=GND)

⚠️ **Power Supply**
- Use adequate power supply (minimum 2A for Pi Zero W)
- Poor power causes random crashes, SD card corruption
- Measure voltage under load (should not drop below 4.75V)

⚠️ **ESD Protection**
- Touch grounded metal before handling Raspberry Pi
- Static electricity can damage GPIO pins
- Use ESD wrist strap when assembling

## Testing the Wiring

### Pre-Power Checklist
1. Visual inspection: All connections correct
2. Polarity check: VCC to 5V, GND to GND
3. No short circuits: Adjacent pins not touching
4. Secure connections: Wires firmly in place

### Post-Power Verification
1. Power LED on Raspberry Pi should illuminate
2. Wait 30-60 seconds for PIR sensor to calibrate
3. PIR sensor LED (if present) should blink during calibration
4. Test with hand motion in front of sensor (within 2-3 meters)
5. Check logs: `tail -f /var/log/motion.log`

### Quick Test Script

```python
#!/usr/bin/python3
import RPi.GPIO as GPIO
import time

SENSOR_PIN = 23

GPIO.setmode(GPIO.BCM)
GPIO.setup(SENSOR_PIN, GPIO.IN)

print("PIR Sensor Test - Press Ctrl+C to exit")
print("Wave hand in front of sensor to test...")

try:
    while True:
        if GPIO.input(SENSOR_PIN):
            print("MOTION DETECTED!")
        time.sleep(0.1)
except KeyboardInterrupt:
    print("\nTest complete")
finally:
    GPIO.cleanup()
```

Save as `test_pir.py`, run with `sudo python3 test_pir.py`

## Additional Wiring Examples

### LED Status Indicator

Add visual feedback for motion detection:

```
GPIO18 (Pin 12) → [220Ω Resistor] → LED Anode (+) → LED Cathode (-) → GND (Pin 14)
```

Update code to control LED:
```python
GPIO.setup(18, GPIO.OUT)
GPIO.output(18, GPIO.HIGH)  # LED on when motion detected
```

### Multiple PIR Sensors

For coverage of multiple areas:

```
PIR Sensor 1:
  VCC → 5V (Pin 2)
  OUT → GPIO23 (Pin 16)
  GND → GND (Pin 6)

PIR Sensor 2:
  VCC → 5V (Pin 4)
  OUT → GPIO24 (Pin 18)
  GND → GND (Pin 9)
```

Both sensors share power rails, each has its own GPIO pin.

## Resources

- HC-SR501 PIR Sensor Datasheet: [Search for "HC-SR501 datasheet" for specifications]
- Raspberry Pi GPIO Pinout: https://pinout.xyz
- RPi.GPIO Documentation: https://sourceforge.net/p/raspberry-gpio-python/wiki/Home/
- Fritzing Software (for creating circuit diagrams): https://fritzing.org/

## Summary

**Key Points for Successful Wiring:**
1. Always power off before connecting/disconnecting
2. Use BCM GPIO23 (Physical Pin 16) for PIR signal
3. PIR requires 5V power, outputs 3.3V signal (safe)
4. Color-code wires: Red=5V, Black=GND, Other=Signal
5. Allow 30-60 seconds for PIR calibration
6. Test with multimeter before running software
7. Verify connections match code pin numbers
8. Use 2A+ power supply for stability
