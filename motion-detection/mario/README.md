# Mario Motion Detection Component

A modern motion detection system that plays random Mario-themed sound effects when motion is detected via a PIR sensor.

## Contents

- `setup.sh` - Automated installation script for easy deployment
- `mario.py` - Refactored Python application with modern architecture
- `mario.service` - systemd service unit for system integration
- `mario.conf.example` - Sample configuration file with default settings
- `mario-sounds.tar.gz` - Archive containing Mario-themed sound files (10 WAV files)

## Overview

This component uses a PIR (Passive Infrared) motion sensor to detect movement and responds by playing a random sound effect from a collection of audio files. The system features:

- **Modern Python Architecture**: Object-oriented design with hardware abstraction
- **Configuration File Support**: INI-style config file at `/etc/luigi/motion-detection/mario/mario.conf`
- **Intelligent Cooldown**: 30-minute cooldown to prevent excessive triggering
- **Security Hardened**: Command injection prevention, path validation, log sanitization
- **Structured Logging**: Rotating logs with proper error handling
- **Graceful Shutdown**: Signal handler-based shutdown (SIGTERM/SIGINT)
- **Mock GPIO Support**: Can run without hardware for development/testing
- **Home Assistant Integration**: Optional MQTT integration for motion event publishing

## Hardware Requirements

- Raspberry Pi Zero W (or compatible)
- PIR motion sensor (HC-SR501 or similar)
- Audio output device (speakers, headphones, or USB audio)
- Jumper wires for GPIO connections

## GPIO Configuration

- **GPIO Pin 23** (Physical Pin 16) - PIR sensor data/output pin

### Wiring Diagram

```
PIR Sensor          Raspberry Pi Zero W
----------          -------------------
VCC       -------->  5V (Pin 2 or 4)
GND       -------->  Ground (Pin 6, 9, 14, etc.)
OUT       -------->  GPIO 23 (Pin 16)
```

## Quick Start

The easiest way to install the mario motion detection service is using the provided setup script:

```bash
# Clone or download the repository
cd motion-detection/mario

# Run the setup script
sudo ./setup.sh install
```

This will automatically:
- Install dependencies (python3-rpi-lgpio, alsa-utils)
- Extract and install sound files
- Install the Python application
- Install and enable the systemd service
- Start the service

**Audio Configuration:**
Audio is configured during the root setup process (`sudo ./setup.sh install`):
1. Optionally installs the Adafruit Sound Bonnet
2. Detects all available audio devices (using `aplay -l`)
3. Prompts you to select the audio device to use
4. Creates `/etc/asound.conf` with automatic format conversion (16-bit → 32-bit)
5. Tests audio playback to verify configuration

If you install the mario module directly (not through root setup.sh), audio configuration will be skipped if `/etc/asound.conf` already exists.

### Other Setup Commands

```bash
# Check installation status
./setup.sh status

# Uninstall the service
sudo ./setup.sh uninstall
```

## Manual Installation

If you prefer to install manually, follow these steps:

### 1. Install Dependencies

```bash
sudo apt-get update
sudo apt-get install python3-rpi-lgpio alsa-utils
```

**CRITICAL: Use python3-rpi-lgpio, NOT python3-rpi-lgpio or pip-installed RPi.GPIO**

On Raspberry Pi models with newer kernels (6.6+), including:
- Raspberry Pi 4
- Raspberry Pi 5  
- Raspberry Pi Zero 2W

You **must** use `python3-rpi-lgpio` from apt. The older `RPi.GPIO` library (especially from pip) causes "Failed to add edge detection" errors with newer kernels.

**If you previously installed RPi.GPIO via pip, remove it:**
```bash
sudo pip3 uninstall RPi.GPIO
sudo apt-get install python3-rpi-lgpio
```

### 2. Extract Sound Files

```bash
sudo mkdir -p /usr/share/sounds/mario
sudo tar -xzf mario-sounds.tar.gz -C /usr/share/sounds/mario/ --strip-components=1
```

The `--strip-components=1` flag removes the leading `luigi/` directory from the archive, placing sound files directly in `/usr/share/sounds/mario/`.

The sound directory should contain `.wav` or compatible audio files that will be randomly selected during playback.

### 3. Install Python Script

```bash
sudo cp mario.py /usr/local/bin/mario.py
sudo chmod +x /usr/local/bin/mario.py
```

### 4. Install systemd Service

```bash
# Install service unit file
sudo cp mario.service /etc/systemd/system/mario.service
sudo chmod 644 /etc/systemd/system/mario.service

# Reload systemd configuration
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable mario.service

# Start the service
sudo systemctl start mario.service
```

## Usage

### Service Management Commands

```bash
# Start the service
sudo systemctl start mario.service

# Stop the service
sudo systemctl stop mario.service

# Restart the service
sudo systemctl restart mario.service

# Check service status
sudo systemctl status mario.service

# View service logs (real-time)
sudo journalctl -u mario.service -f

# View recent logs
sudo journalctl -u mario.service -n 100

# Enable service on boot
sudo systemctl enable mario.service

# Disable service on boot
sudo systemctl disable mario.service
```

### Alternative: View Application Logs Directly

The service logs to `/var/log/luigi/mario.log`:

```bash
# Follow logs in real-time
tail -f /var/log/luigi/mario.log

# View recent logs
tail -100 /var/log/luigi/mario.log

# View all logs
cat /var/log/luigi/mario.log
```

### Manual Execution (Development/Testing)

```bash
# Run directly (requires root for GPIO access)
sudo python3 /usr/local/bin/mario.py

# Stop with Ctrl+C (SIGINT)
# The application will shut down gracefully
```

### Resetting Sound Cooldown

The mario module includes a utility script to reset the sound playback cooldown timer:

```bash
# Reset cooldown (installed system-wide)
mario-reset-cooldown

# View help and options
mario-reset-cooldown --help

# Use custom timer file location
mario-reset-cooldown --file /custom/path/mario_timer

# Use timer file from custom config
mario-reset-cooldown --config /custom/mario.conf
```

**Alternative: Run from source directory**
```bash
cd motion-detection/mario
./reset-cooldown.sh
```

**What it does:**
- Removes the timer file that tracks the last sound playback time
- Next motion detection will trigger sound immediately (regardless of when last sound played)
- **Note**: This only affects sound playback cooldown; MQTT events are always published

**When to use:**
- After testing when you want to trigger sound immediately
- When you want to manually reset the 30-minute cooldown
- After maintenance or system changes

**Safety**: The service gracefully handles missing timer files - if the timer file doesn't exist, it simply initializes the cooldown as expired, allowing sound on the next motion event.

## How It Works

1. **Initialization**: The script sets up GPIO pin 23 as an input for the PIR sensor
2. **Event Detection**: When the PIR sensor detects motion (rising edge), it triggers the callback function
3. **MQTT Publishing**: Motion event is immediately published to Home Assistant (if ha-mqtt installed)
4. **Cooldown Check**: The system checks if 30 minutes (1800 seconds) have passed since the last sound playback
5. **Sound Playback**: If the cooldown has expired, a random sound file is selected and played using `aplay`
6. **Timer Update**: The current timestamp is saved to track the sound cooldown period
7. **Graceful Shutdown**: The service responds to SIGTERM/SIGINT signals for clean shutdown

**Key Behavior**: All motion events are tracked in Home Assistant, but sound playback is limited by a 30-minute cooldown to prevent spam.

### Shutdown Mechanisms

The application uses signal handlers for graceful shutdown:

- **systemctl stop** (Recommended): Uses SIGTERM for graceful shutdown
  ```bash
  sudo systemctl stop mario.service
  ```
  
- **SIGTERM Signal**: Direct signal to process
  ```bash
  sudo kill -TERM <pid>
  ```
  
- **SIGINT Signal** (Interactive): Ctrl+C when running manually
  ```bash
  # Press Ctrl+C to stop
  ```

All shutdown methods trigger a graceful shutdown that:
- Stops motion monitoring
- Cleans up GPIO resources
- Closes log files properly
- Removes temporary files

## Configuration

The mario module uses an INI-style configuration file located at `/etc/luigi/motion-detection/mario/mario.conf`.

### Configuration File

Create or edit `/etc/luigi/motion-detection/mario/mario.conf`:

```ini
[GPIO]
# GPIO pin for PIR sensor (BCM numbering)
SENSOR_PIN=23

[Timing]
# Cooldown period in seconds (30 minutes = 1800)
# NOTE: Cooldown applies ONLY to sound playback, not MQTT publishing
# All motion events are sent to Home Assistant regardless of cooldown
COOLDOWN_SECONDS=1800
# Main loop sleep interval in seconds
MAIN_LOOP_SLEEP=100

[Files]
# Sound directory containing WAV/MP3 files
SOUND_DIR=/usr/share/sounds/mario/
# Timer file location for tracking last trigger time
TIMER_FILE=/tmp/mario_timer
# Log file location
LOG_FILE=/var/log/luigi/mario.log

[Logging]
# Log level: DEBUG, INFO, WARNING, ERROR, CRITICAL
LOG_LEVEL=INFO
# Maximum log file size in bytes (10MB default)
LOG_MAX_BYTES=10485760
# Number of backup log files to keep
LOG_BACKUP_COUNT=5
```

A sample configuration file (`mario.conf.example`) is included in this directory.

### Default Configuration

If the configuration file does not exist, the application will use default values:
- **GPIO Pin**: 23 (BCM)
- **Sound Cooldown**: 1800 seconds (30 minutes - applies only to sound playback)
- **Sound Directory**: `/usr/share/sounds/mario/`
- **Log File**: `/var/log/luigi/mario.log`
- **Log Level**: INFO

### Modifying Configuration

To change settings:

1. Create the configuration directory if it doesn't exist:
   ```bash
   sudo mkdir -p /etc/luigi/motion-detection/mario
   ```

2. Copy the example configuration:
   ```bash
   sudo cp mario.conf.example /etc/luigi/motion-detection/mario/mario.conf
   ```

3. Edit the configuration file:
   ```bash
   sudo nano /etc/luigi/motion-detection/mario/mario.conf
   ```

4. Restart the service to apply changes:
   ```bash
   sudo systemctl restart mario.service
   ```

## Adding Custom Sounds

To use your own sound files:

1. Prepare your audio files in a compatible format (WAV recommended)
2. Copy them to the sound directory:
   ```bash
   sudo cp your-sound.wav /usr/share/sounds/mario/
   ```
3. Ensure proper permissions:
   ```bash
   sudo chmod 644 /usr/share/sounds/mario/*.wav
   ```

The system will randomly select from all files in the directory.

## Home Assistant Integration

The mario module integrates with Home Assistant through the **ha-mqtt module**, allowing motion detection events to be published via MQTT and displayed in Home Assistant dashboards.

### Features

- **Zero-Coupling Design**: Motion detection works standalone; MQTT integration is optional
- **Automatic Discovery**: Sensor automatically appears in Home Assistant
- **Binary Sensor**: Motion events published as ON state to Home Assistant
- **Graceful Degradation**: Module continues working if MQTT is unavailable
- **Complete Motion Tracking**: All motion events published to MQTT, independent of sound cooldown
- **Smart Cooldown**: 30-minute cooldown applies only to sound playback, not MQTT publishing

### Prerequisites

1. **Install ha-mqtt module** (if not already installed):
   ```bash
   cd iot/ha-mqtt
   sudo ./setup.sh install
   ```

2. **Configure MQTT broker** in `/etc/luigi/ha-mqtt/ha-mqtt.conf`:
   - Set broker hostname, port, credentials
   - Ensure MQTT broker (e.g., Mosquitto) is accessible

3. **Verify ha-mqtt installation**:
   ```bash
   /usr/local/bin/luigi-mqtt-status
   ```

### Installation

The mario setup script automatically handles MQTT integration:

```bash
# Install mario with MQTT integration
cd motion-detection/mario
sudo ./setup.sh install
```

**What happens during installation:**
1. Checks if ha-mqtt is installed
2. If present, deploys sensor descriptor to `/etc/luigi/iot/ha-mqtt/sensors.d/mario_motion.json`
3. Runs `luigi-discover` to register sensor with Home Assistant
4. Motion events are now published to MQTT automatically

### Manual Integration

If ha-mqtt was installed after mario, you can manually integrate:

```bash
# Copy sensor descriptor
sudo cp mario_motion_descriptor.json /etc/luigi/iot/ha-mqtt/sensors.d/mario_motion.json

# Register with Home Assistant
sudo /usr/local/bin/luigi-discover

# Restart mario service
sudo systemctl restart mario.service
```

### Home Assistant Configuration

After installation, the sensor appears in Home Assistant:

**Entity ID**: `binary_sensor.mario_motion`

**View in Dashboard**:
```yaml
type: entities
entities:
  - entity: binary_sensor.mario_motion
    name: Mario Motion Detector
```

**Create Automation**:
```yaml
automation:
  - alias: "Mario Motion Alert"
    trigger:
      - platform: state
        entity_id: binary_sensor.mario_motion
        to: 'on'
    action:
      - service: notify.mobile_app
        data:
          message: "Motion detected by Mario sensor!"
```

### Troubleshooting MQTT

**Check MQTT integration status**:
```bash
./setup.sh status
```

**Test MQTT connection**:
```bash
/usr/local/bin/luigi-mqtt-status
```

**View MQTT logs in mario.log**:
```bash
tail -f /var/log/luigi/mario.log | grep MQTT
```

**Common issues:**
- **"ha-mqtt not available"**: Normal if ha-mqtt not installed; motion detection still works
- **"MQTT publish timeout"**: Check MQTT broker connectivity and credentials
- **"MQTT publish failed"**: Verify ha-mqtt configuration in `/etc/luigi/ha-mqtt/ha-mqtt.conf`

For detailed MQTT troubleshooting, see the ha-mqtt module documentation at `iot/ha-mqtt/README.md`.

## Troubleshooting

### No Sound Output

1. **Check audio configuration:**
   ```bash
   # List available audio devices
   aplay -l
   
   # Check current configuration
   cat /etc/asound.conf
   ```

2. **Common audio error: "audio open error: Unknown error 524"**
   
   This error occurs when aplay cannot access the configured audio device.
   
   **Solution:**
   - Reconfigure audio with root setup: `sudo ../../setup.sh install` (choose 'y' to reconfigure audio)
   - Or reconfigure from module directory: `sudo ./setup.sh install` (will skip if already configured)
   - Or manually create `/etc/asound.conf`:
     ```bash
     # Find your audio device
     aplay -l
     
     # Create /etc/asound.conf with your card and device numbers
     sudo nano /etc/asound.conf
     ```
     
     Example configuration for card 0, device 0:
     ```
     pcm.!default {
         type plug
         slave.pcm {
             type hw
             card 0
             device 0
         }
     }
     
     ctl.!default {
         type hw
         card 0
     }
     ```
     
     **Note:** The `type plug` is important for automatic format conversion.

3. **Audio format incompatibility: "Sample format non available"**
   
   Error message:
   ```
   aplay: set_params:1387: Sample format non available
   Available formats:
   - S32_LE
   ```
   
   This occurs when the audio device (like the Adafruit Sound Bonnet) only supports 32-bit format but the WAV files are 16-bit.
   
   **Solution:**
   - Ensure `/etc/asound.conf` uses `type plug` instead of `type hw` for automatic format conversion
   - The setup script now automatically creates the correct configuration
   - If you have an old configuration, reconfigure: `sudo ./setup.sh install` and choose 'y' to reconfigure audio
   
   **Manual fix:**
   ```bash
   # Edit /etc/asound.conf
   sudo nano /etc/asound.conf
   
   # Change this:
   # pcm.!default {
   #     type hw
   #     card 0
   #     device 0
   # }
   
   # To this (note the 'plug' type and nested structure):
   # pcm.!default {
   #     type plug
   #     slave.pcm {
   #         type hw
   #         card 0
   #         device 0
   #     }
   # }
   ```

4. **Test audio playback:**
   ```bash
   # Test with a sound file
   aplay /usr/share/sounds/mario/callingmario1.wav
   
   # Test with speaker test
   speaker-test -t wav -c 2
   
   # If audio works, restart the mario service
   sudo systemctl restart mario.service
   ```

4. **Adjust volume:**
   ```bash
   alsamixer
   ```

### Motion Not Detected

1. Verify PIR sensor wiring
2. Check GPIO pin assignment matches configuration
3. Test PIR sensor sensitivity adjustment (potentiometers on sensor)
4. Review logs: `tail -f /var/log/luigi/mario.log`

### Service Won't Start

1. Check service status and logs:
   ```bash
   sudo systemctl status mario.service
   sudo journalctl -u mario.service -n 50
   ```

2. **Common Issue: "Failed to add edge detection" error**
   
   This error occurs on Raspberry Pi models with newer kernels (6.6+), particularly:
   - Raspberry Pi 4
   - Raspberry Pi 5
   - Raspberry Pi Zero 2W
   
   **Symptoms:**
   - Error message: "RuntimeError: Failed to add edge detection"
   - In dmesg logs: "export_store: invalid GPIO X"
   - GPIO initializes but event detection fails
   
   **Root Cause:**
   This is a **library incompatibility issue**. The older `RPi.GPIO` library (especially when installed via pip) is incompatible with newer Raspberry Pi kernels (6.6+).
   
   **Solution:**
   Use `python3-rpi-lgpio` from apt instead of `RPi.GPIO`:
   
   ```bash
   # Remove any pip-installed RPi.GPIO
   sudo pip3 uninstall RPi.GPIO -y
   
   # Remove old python3-rpi-lgpio if installed
   sudo apt-get remove python3-rpi-lgpio -y
   sudo apt-get autoremove -y
   
   # Install the correct library
   sudo apt-get update
   sudo apt-get install python3-rpi-lgpio -y
   
   # Restart the service
   sudo systemctl restart mario.service
   ```
   
   **Verification:**
   Check which GPIO library is installed:
   ```bash
   dpkg -l | grep -i rpi
   ```
   
   You should see `python3-rpi-lgpio`, NOT `python3-rpi-lgpio`.
   
   **Why this works:**
   `python3-rpi-lgpio` is a compatibility shim that uses the newer `lgpio` library, which works correctly with kernel 6.6+. It provides the same `RPi.GPIO` API but uses the modern GPIO interface internally.

3. Verify Python script exists and has correct permissions:
   ```bash
   ls -l /usr/local/bin/mario.py
   ```

4. Verify Python dependencies:
   ```bash
   python3 -c "import RPi.GPIO"
   ```

5. Test script manually:
   ```bash
   sudo python3 /usr/local/bin/mario.py
   ```

## Architecture

The mario module follows modern Python development practices:

### Code Structure

- **Config Class**: Centralized configuration management
- **GPIOManager**: Hardware abstraction for GPIO operations
- **PIRSensor**: Sensor-specific interface with event handling
- **MotionDetectionApp**: Main application class with state management
- **Signal Handlers**: Graceful shutdown on SIGTERM/SIGINT

### Key Features

**Security Hardening:**
- `subprocess.run()` with list arguments (no shell injection)
- Path validation using `os.path.commonpath()`
- Log sanitization (limited length, no sensitive data)
- Timeout protection on subprocess calls

**Error Handling:**
- Try/except blocks on all I/O operations
- Comprehensive logging with context
- Graceful degradation on errors

**Logging:**
- Structured logging with `RotatingFileHandler`
- 10MB file size limit with 5 backups
- Dual output: journalctl + /var/log/luigi/mario.log

## Dependencies

- **python3-rpi-lgpio**: Python 3 library for GPIO control
  ```bash
  sudo apt-get install python3-rpi-lgpio
  ```

- **alsa-utils**: Audio playback utilities (includes `aplay`)
  ```bash
  sudo apt-get install alsa-utils
  ```

**Optional:**
- **ha-mqtt module**: For Home Assistant integration via MQTT
  - Install separately from `iot/ha-mqtt/` directory
  - Motion detection works standalone without ha-mqtt

**Note**: The setup script automatically installs the required dependencies.

## Notes

- The script uses BCM GPIO numbering (not physical pin numbers)
- Motion detection has a 30-minute cooldown to prevent spam
- The service runs as a systemd daemon with dual logging (journalctl + file)
- Graceful shutdown via SIGTERM signal (systemctl stop)
- Python 3.x required (uses modern Python features)
- Root privileges required for GPIO access

## Technical Details

**Code Metrics:**
- Lines of Code: ~520 (refactored from original 47 lines)
- Classes: 4 (Config, GPIOManager, PIRSensor, MotionDetectionApp)
- Functions: 15+ with comprehensive error handling
- Security Features: 5+ hardening measures implemented

**Refactoring Improvements:**
- Object-oriented architecture with hardware abstraction
- Configuration file support (INI-style, `/etc/luigi/motion-detection/mario/mario.conf`)
- Structured logging with rotation
- Signal-based shutdown (no polling)
- Mock GPIO support for testing
- Comprehensive error handling and validation
- Security hardening (command injection prevention, path validation)

## Future Enhancements

Potential improvements:
- Command-line arguments for runtime configuration
- Multiple sound directories/themes
- Web interface for remote control
- Motion event statistics and reporting
- Multi-sensor support
