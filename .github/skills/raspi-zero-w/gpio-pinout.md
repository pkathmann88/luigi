# Raspberry Pi Zero W GPIO Pinout Reference

## 40-Pin GPIO Header Layout

```
                    Raspberry Pi Zero W
                    3V3  (1) (2)  5V
       (BCM 2)  SDA1/GPIO2  (3) (4)  5V
       (BCM 3)  SCL1/GPIO3  (5) (6)  GND
       (BCM 4)       GPIO4  (7) (8)  GPIO14 (BCM 14) TXD0
                       GND  (9) (10) GPIO15 (BCM 15) RXD0
      (BCM 17)      GPIO17 (11) (12) GPIO18 (BCM 18) PCM_CLK
      (BCM 27)      GPIO27 (13) (14) GND
      (BCM 22)      GPIO22 (15) (16) GPIO23 (BCM 23) ← PIR Sensor
                       3V3 (17) (18) GPIO24 (BCM 24)
      (BCM 10)  MOSI/GPIO10 (19) (20) GND
      (BCM 9)   MISO/GPIO9  (21) (22) GPIO25 (BCM 25)
      (BCM 11)  SCLK/GPIO11 (23) (24) GPIO8  (BCM 8)  CE0
                       GND (25) (26) GPIO7  (BCM 7)  CE1
      (BCM 0)   ID_SD/GPIO0 (27) (28) GPIO1  (BCM 1)  ID_SC
      (BCM 5)        GPIO5 (29) (30) GND
      (BCM 6)        GPIO6 (31) (32) GPIO12 (BCM 12) PWM0
      (BCM 13)      GPIO13 (33) (34) GND
      (BCM 19) PCM_FS/GPIO19 (35) (36) GPIO16 (BCM 16)
      (BCM 26)      GPIO26 (37) (38) GPIO20 (BCM 20) PCM_DIN
                       GND (39) (40) GPIO21 (BCM 21) PCM_DOUT
```

## Pin Reference Table

### Power Pins
| Physical Pin | Function    | Notes                              |
|--------------|-------------|------------------------------------|
| 1            | 3.3V Power  | Max ~500mA total for 3.3V rail     |
| 2            | 5V Power    | Directly from power supply         |
| 4            | 5V Power    | Directly from power supply         |
| 17           | 3.3V Power  | Max ~500mA total for 3.3V rail     |

### Ground Pins
| Physical Pin | Function | Notes                     |
|--------------|----------|---------------------------|
| 6            | GND      | Ground reference          |
| 9            | GND      | Ground reference          |
| 14           | GND      | Ground reference          |
| 20           | GND      | Ground reference          |
| 25           | GND      | Ground reference          |
| 30           | GND      | Ground reference          |
| 34           | GND      | Ground reference          |
| 39           | GND      | Ground reference          |

### GPIO Pins (BCM Numbering)

| BCM GPIO | Physical Pin | Alt Functions                | Notes                        |
|----------|--------------|------------------------------|------------------------------|
| GPIO2    | 3            | SDA1 (I2C)                   | I2C Data, 1.8kΩ pull-up      |
| GPIO3    | 5            | SCL1 (I2C)                   | I2C Clock, 1.8kΩ pull-up     |
| GPIO4    | 7            | GPCLK0                       | General purpose              |
| GPIO5    | 29           | GPCLK1                       | General purpose              |
| GPIO6    | 31           | GPCLK2                       | General purpose              |
| GPIO7    | 26           | SPI0_CE1_N                   | SPI Chip Enable 1            |
| GPIO8    | 24           | SPI0_CE0_N                   | SPI Chip Enable 0            |
| GPIO9    | 21           | SPI0_MISO                    | SPI Master In Slave Out      |
| GPIO10   | 19           | SPI0_MOSI                    | SPI Master Out Slave In      |
| GPIO11   | 23           | SPI0_SCLK                    | SPI Clock                    |
| GPIO12   | 32           | PWM0                         | Hardware PWM                 |
| GPIO13   | 33           | PWM1                         | Hardware PWM                 |
| GPIO14   | 8            | TXD0 (UART)                  | UART Transmit                |
| GPIO15   | 10           | RXD0 (UART)                  | UART Receive                 |
| GPIO16   | 36           | -                            | General purpose              |
| GPIO17   | 11           | -                            | General purpose              |
| GPIO18   | 12           | PCM_CLK, PWM0                | Audio, Hardware PWM          |
| GPIO19   | 35           | PCM_FS, SPI1_MISO            | Audio Frame Sync             |
| GPIO20   | 38           | PCM_DIN, SPI1_MOSI           | Audio Data In                |
| GPIO21   | 40           | PCM_DOUT, SPI1_SCLK          | Audio Data Out               |
| GPIO22   | 15           | -                            | General purpose              |
| GPIO23   | 16           | -                            | **Used for PIR sensor**      |
| GPIO24   | 18           | -                            | General purpose              |
| GPIO25   | 22           | -                            | General purpose              |
| GPIO26   | 37           | -                            | General purpose              |
| GPIO27   | 13           | -                            | General purpose              |

## Pin Selection Guidelines

### Best Pins for General Input/Output
These pins have no alternate functions and are safe for general use:
- **GPIO17** (Pin 11)
- **GPIO22** (Pin 15)
- **GPIO23** (Pin 16) ← **Currently used for PIR sensor**
- **GPIO24** (Pin 18)
- **GPIO25** (Pin 22)
- **GPIO27** (Pin 13)

### Pins with PWM Capability
Use these for PWM applications (LED dimming, servo control):
- **GPIO12** (Pin 32) - PWM0
- **GPIO13** (Pin 33) - PWM1
- **GPIO18** (Pin 12) - PWM0 (also used for audio)
- **GPIO19** (Pin 35) - PWM1 (also used for audio)

### Reserved Pins (Avoid Unless Needed)
- **GPIO0, GPIO1** (Pins 27, 28) - EEPROM ID pins
- **GPIO2, GPIO3** (Pins 3, 5) - I2C (if using I2C devices)
- **GPIO7-11** (Pins 19, 21, 23, 24, 26) - SPI (if using SPI devices)
- **GPIO14, GPIO15** (Pins 8, 10) - UART (if using serial console)
- **GPIO18-21** (Pins 12, 35, 38, 40) - PCM Audio (if using I2S audio)

## Current Project Pin Usage

### Motion Detection Project
```
Component         GPIO (BCM)    Physical Pin    Function
---------         ----------    ------------    --------
PIR Sensor OUT    GPIO23        Pin 16          Motion detection input
PIR Sensor VCC    5V            Pin 2 or 4      Power supply
PIR Sensor GND    GND           Pin 6           Ground reference
```

## Voltage and Current Specifications

### Safe Operating Limits
- **GPIO Input Voltage**: 0V to 3.3V (exceeding 3.3V will damage the pin)
- **GPIO Output Voltage**: 3.3V (HIGH), 0V (LOW)
- **GPIO Current per Pin**: 16mA maximum
- **GPIO Total Current**: 50mA maximum across all pins
- **3.3V Rail Current**: ~500mA available (shared with on-board components)
- **5V Rail Current**: Limited only by power supply rating

### Important Voltage Rules
- ✅ Safe: 3.3V logic devices connected directly to GPIO
- ✅ Safe: 5V powered sensors with 3.3V logic outputs (like HC-SR501 PIR)
- ❌ Dangerous: 5V logic outputs connected to GPIO (use level shifter)
- ❌ Dangerous: Connecting 5V directly to any GPIO pin (will damage Pi)

## Quick Reference for Common Components

### PIR Motion Sensor (HC-SR501)
```
PIR VCC  →  5V (Pin 2 or 4)
PIR GND  →  GND (any ground pin)
PIR OUT  →  GPIO23 (Pin 16) - 3.3V compatible output
```

### LED with Resistor
```
GPIO Pin → [220Ω Resistor] → LED Anode (+) → LED Cathode (-) → GND
```

### Push Button (Pull-up configuration)
```
GPIO Pin (configured with pull_up_down=GPIO.PUD_UP) → Button → GND
```

### Push Button (Pull-down configuration)
```
3.3V (Pin 1 or 17) → Button → GPIO Pin (configured with pull_up_down=GPIO.PUD_DOWN)
```

## BCM vs BOARD Numbering

### BCM (Broadcom) Numbering
- Based on Broadcom SOC GPIO numbers
- Example: `GPIO.setmode(GPIO.BCM)` then `GPIO.setup(23, GPIO.IN)`
- Pin reference: GPIO23
- **Used in this project**

### BOARD (Physical) Numbering
- Based on physical pin position (1-40)
- Example: `GPIO.setmode(GPIO.BOARD)` then `GPIO.setup(16, GPIO.IN)`
- Pin reference: Pin 16
- More intuitive but less portable

**Same Physical Location, Different Numbers:**
- BCM GPIO23 = BOARD Pin 16
- Always check which mode your code uses!

## Verification Checklist

Before connecting hardware:
- [ ] Identified correct physical pin number
- [ ] Verified BCM GPIO number if using BCM mode
- [ ] Confirmed pin is not reserved for I2C/SPI/UART (unless needed)
- [ ] Checked voltage compatibility (3.3V for GPIO)
- [ ] Planned ground connection (multiple GND pins available)
- [ ] Identified power source (3.3V or 5V based on component needs)

## Additional Resources

- Interactive pinout: https://pinout.xyz
- Official GPIO documentation: https://www.raspberrypi.com/documentation/computers/raspberry-pi.html
- RPi.GPIO library documentation: https://sourceforge.net/p/raspberry-gpio-python/wiki/Home/
