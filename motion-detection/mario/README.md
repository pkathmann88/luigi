# Mario Motion Detection Component

A fun motion detection system that plays random Mario-themed sound effects when motion is detected via a PIR sensor.

## Contents

- `mario` - init.d service script for system service integration
- `mario.py` - Python script implementing motion detection and sound playback
- `mario-sounds.tar.gz` - Archive containing default Mario-themed sound files

## Overview

This component uses a PIR (Passive Infrared) motion sensor to detect movement and responds by playing a random sound effect from a collection of audio files. The system includes intelligent cooldown management to prevent excessive triggering.

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

## Installation

### 1. Extract Sound Files

```bash
sudo mkdir -p /usr/share/sounds/mario
sudo tar -xzf mario-sounds.tar.gz -C /usr/share/sounds/mario/
```

The sound directory should contain `.wav` or compatible audio files that will be randomly selected during playback.

### 2. Install Python Script

```bash
sudo cp mario.py /usr/local/bin/mario.py
sudo chmod +x /usr/local/bin/mario.py
```

### 3. Install systemd Service

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

1. Check script permissions:
   ```bash
   ls -l /usr/bin/luigi
   ls -l /etc/init.d/mario
   ```

2. Verify Python dependencies:
   ```bash
   python -c "import RPi.GPIO"
   ```

3. Check for error messages:
   ```bash
   sudo /usr/bin/luigi
   ```

## Dependencies

- **RPi.GPIO**: Python library for GPIO control
  ```bash
  sudo apt-get install python-rpi.gpio
  ```

- **alsa-utils**: Audio playback utilities (includes `aplay`)
  ```bash
  sudo apt-get install alsa-utils
  ```

## Notes

- The script uses BCM GPIO numbering (not physical pin numbers)
- Motion detection has a 30-minute cooldown to prevent spam
- The service runs as a background daemon with output logged to `/var/log/motion.log`
- The service can be stopped gracefully using systemctl or by sending SIGTERM signal

## Future Enhancements

Potential improvements:
- Configurable cooldown period via command-line argument
- Multiple sound directories for different themes
- Web interface for remote control
- Integration with other home automation systems
- Motion event logging and statistics
