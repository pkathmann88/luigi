# Mario Motion Detection Component

A modern motion detection system that plays random Mario-themed sound effects when motion is detected via a PIR sensor.

## Contents

- `setup.sh` - Automated installation script for easy deployment
- `mario.py` - Refactored Python application with modern architecture
- `mario.service` - systemd service unit for system integration
- `mario-sounds.tar.gz` - Archive containing Mario-themed sound files (10 WAV files)

## Overview

This component uses a PIR (Passive Infrared) motion sensor to detect movement and responds by playing a random sound effect from a collection of audio files. The system features:

- **Modern Python Architecture**: Object-oriented design with hardware abstraction
- **Intelligent Cooldown**: 30-minute cooldown to prevent excessive triggering
- **Security Hardened**: Command injection prevention, path validation, log sanitization
- **Structured Logging**: Rotating logs with proper error handling
- **Graceful Shutdown**: Signal handler-based shutdown (SIGTERM/SIGINT)
- **Mock GPIO Support**: Can run without hardware for development/testing

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
- Install dependencies (python3-rpi.gpio, alsa-utils)
- Extract and install sound files
- Install the Python application
- Install and enable the systemd service
- Start the service

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
sudo apt-get install python3-rpi.gpio alsa-utils
```

### 2. Extract Sound Files

```bash
sudo mkdir -p /usr/share/sounds/mario
sudo tar -xzf mario-sounds.tar.gz -C /usr/share/sounds/mario/
```

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

The service also logs to `/var/log/motion.log`:

```bash
# Follow logs in real-time
tail -f /var/log/motion.log

# View recent logs
tail -100 /var/log/motion.log
```

### Manual Execution (Development/Testing)

```bash
# Run directly (requires root for GPIO access)
sudo python3 /usr/local/bin/mario.py

# Stop with Ctrl+C (SIGINT)
# The application will shut down gracefully
```

## How It Works

1. **Initialization**: The script sets up GPIO pin 23 as an input for the PIR sensor
2. **Event Detection**: When the PIR sensor detects motion (rising edge), it triggers the callback function
3. **Cooldown Check**: The system checks if 30 minutes (1800 seconds) have passed since the last trigger
4. **Sound Playback**: If the cooldown has expired, a random sound file is selected and played using `aplay`
5. **Timer Update**: The current timestamp is saved to track the cooldown period
6. **Graceful Shutdown**: The service responds to SIGTERM/SIGINT signals for clean shutdown

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

Key parameters in `mario.py` (defined in Config class):

```python
class Config:
    """Application configuration constants."""
    
    # GPIO Settings (BCM numbering)
    GPIO_MODE = GPIO.BCM
    SENSOR_PIN = 23
    
    # File Paths
    SOUND_DIR = "/usr/share/sounds/mario/"
    TIMER_FILE = "/tmp/mario_timer"
    LOG_FILE = "/var/log/motion.log"
    
    # Timing Settings
    COOLDOWN_SECONDS = 1800  # 30 minutes
    MAIN_LOOP_SLEEP = 100    # seconds
    
    # Logging
    LOG_LEVEL = logging.INFO
    LOG_MAX_BYTES = 10 * 1024 * 1024  # 10MB
    LOG_BACKUP_COUNT = 5
```

Cooldown duration: **1800 seconds (30 minutes)**

To modify the cooldown period, edit the Config class in `mario.py`:
```python
class Config:
    # Timing Settings
    COOLDOWN_SECONDS = 1800  # Change to desired seconds (e.g., 900 = 15 minutes)
```

After changing configuration, restart the service:
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

## Troubleshooting

### No Sound Output

1. Test audio system:
   ```bash
   speaker-test -t wav -c 2
   ```

2. Check audio device:
   ```bash
   aplay -l
   ```

3. Adjust volume:
   ```bash
   alsamixer
   ```

### Motion Not Detected

1. Verify PIR sensor wiring
2. Check GPIO pin assignment matches configuration
3. Test PIR sensor sensitivity adjustment (potentiometers on sensor)
4. Review logs: `tail -f /var/log/motion.log`

### Service Won't Start

1. Check service status and logs:
   ```bash
   sudo systemctl status mario.service
   sudo journalctl -u mario.service -n 50
   ```

2. Verify Python script exists and has correct permissions:
   ```bash
   ls -l /usr/local/bin/mario.py
   ```

3. Verify Python dependencies:
   ```bash
   python3 -c "import RPi.GPIO"
   ```

4. Test script manually:
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
- Dual output: journalctl + /var/log/motion.log

## Dependencies

- **python3-rpi.gpio**: Python 3 library for GPIO control
  ```bash
  sudo apt-get install python3-rpi.gpio
  ```

- **alsa-utils**: Audio playback utilities (includes `aplay`)
  ```bash
  sudo apt-get install alsa-utils
  ```

**Note**: The setup script automatically installs these dependencies.

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
- Configuration management via Config class
- Structured logging with rotation
- Signal-based shutdown (no polling)
- Mock GPIO support for testing
- Comprehensive error handling and validation
- Security hardening (command injection prevention, path validation)

## Future Enhancements

Potential improvements:
- Configuration file support (YAML/JSON)
- Command-line arguments for runtime configuration
- Multiple sound directories/themes
- Web interface for remote control
- Home automation integration (MQTT, Home Assistant)
- Motion event statistics and reporting
- Multi-sensor support
