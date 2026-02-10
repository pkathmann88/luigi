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

### 3. Install System Service

#### Option A: systemd (Recommended for Modern Systems)

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

#### Option B: init.d (Legacy Compatibility)

```bash
sudo cp mario /etc/init.d/mario
sudo chmod +x /etc/init.d/mario
sudo update-rc.d mario defaults
```

This registers the motion detection as a system service that can be managed with standard service commands.

## Usage

### systemd Commands (Recommended)

```bash
# Start the service
sudo systemctl start mario.service

# Stop the service
sudo systemctl stop mario.service

# Restart the service
sudo systemctl restart mario.service

# Check service status
sudo systemctl status mario.service

# View service logs
sudo journalctl -u mario.service -f

# Enable service on boot
sudo systemctl enable mario.service

# Disable service on boot
sudo systemctl disable mario.service
```

### init.d Commands (Legacy)

```bash
# Start the service
sudo /etc/init.d/mario start
# or
sudo service mario start

# Stop the service
sudo /etc/init.d/mario stop
# or
sudo service mario stop

# Restart the service
sudo /etc/init.d/mario restart
# or
sudo service mario restart

# Check service status
sudo /etc/init.d/mario status
# or
sudo service mario status
```

### View Service Logs

The service logs output to `/var/log/motion.log`:

```bash
# Follow logs in real-time
tail -f /var/log/motion.log

# View recent logs
tail -100 /var/log/motion.log

# For systemd, you can also use journalctl
sudo journalctl -u mario.service -n 100
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

The application supports multiple shutdown methods:

- **SIGTERM Signal** (Recommended): Used by systemd and modern init systems
  ```bash
  sudo systemctl stop mario.service
  # or
  sudo kill -TERM <pid>
  ```
  
- **SIGINT Signal** (Interactive): Ctrl+C when running manually
  ```bash
  # Press Ctrl+C to stop
  ```

- **Stop File** (Legacy): Backwards compatibility with old init.d script
  ```bash
  touch /tmp/stop_mario
  # Application will detect and shut down on next motion event
  ```

All methods trigger a graceful shutdown that:
- Stops motion monitoring
- Cleans up GPIO resources
- Closes log files properly
- Removes temporary files

## Configuration

Key parameters in `mario.py` (defined in Config class):

```python
# GPIO Settings
SENSOR_PIN = 23                           # GPIO pin for PIR sensor (BCM numbering)

# File Paths
SOUND_DIR = "/usr/share/sounds/mario/"    # Directory containing sound files
STOP_FILE = "/tmp/stop_mario"             # Stop signal file (legacy)
TIMER_FILE = "/tmp/mario_timer"           # Cooldown tracking file
LOG_FILE = "/var/log/motion.log"          # Application log file

# Timing
COOLDOWN_SECONDS = 1800                   # 30 minutes between triggers
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
# systemd
sudo systemctl restart mario.service

# init.d
sudo service mario restart
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
- Stopping the service creates a stop file that the script monitors for graceful shutdown

## Future Enhancements

Potential improvements:
- Configurable cooldown period via command-line argument
- Multiple sound directories for different themes
- Web interface for remote control
- Integration with other home automation systems
- Motion event logging and statistics
