# luigi

A Python project designed to run on Raspberry Pi Zero W for motion detection with sound playback.

## Platform

This project is designed to run on:
- **Hardware:** Raspberry Pi Zero W
- **Operating System:** Raspberry Pi OS
- **Programming Language:** Python

## Overview

Luigi is a motion detection system that plays random sound effects when motion is detected via a PIR (Passive Infrared) sensor. The system includes a cooldown period to prevent continuous triggering and can be controlled via a system service.

## Prerequisites

- Raspberry Pi Zero W
- Raspberry Pi OS installed
- Python installed (typically pre-installed on Raspberry Pi OS)
- PIR motion sensor connected to GPIO pin 23
- Audio output device (speakers or headphone jack)
- Python RPi.GPIO library

## Hardware Setup

Connect a PIR motion sensor to your Raspberry Pi:
- **VCC** → 5V (Pin 2 or 4)
- **GND** → Ground (Pin 6, 9, 14, 20, 25, 30, 34, or 39)
- **OUT** → GPIO 23 (Pin 16)

## Installation

```bash
# Clone the repository
git clone https://github.com/pkathmann88/luigi.git
cd luigi

# Install required Python packages
sudo apt-get update
sudo apt-get install python-rpi.gpio alsa-utils

# Install sound files (extract mario-sounds.tar.gz)
sudo mkdir -p /usr/share/sounds/mario
sudo tar -xzf motion-detection/mario/mario-sounds.tar.gz -C /usr/share/sounds/mario/

# Copy the Python script to /usr/bin
sudo cp motion-detection/mario/mario.py /usr/bin/luigi
sudo chmod +x /usr/bin/luigi

# Install the init.d service script
sudo cp motion-detection/mario/mario /etc/init.d/mario
sudo chmod +x /etc/init.d/mario
sudo update-rc.d mario defaults
```

## Usage

Start the motion detection service:
```bash
sudo /etc/init.d/mario start
```

Stop the motion detection service:
```bash
sudo /etc/init.d/mario stop
```

Check the logs:
```bash
tail -f /var/log/motion.log
```

## Features

- **Motion Detection**: Uses PIR sensor on GPIO 23 to detect motion
- **Random Sound Playback**: Plays a random sound file from the configured directory
- **Cooldown Period**: 30-minute cooldown between sound playback events to prevent spam
- **Service Control**: Can be started/stopped via init.d service
- **Graceful Shutdown**: Service can be cleanly stopped using the stop command

## Project Structure

```
luigi/
├── README.md                          # This file
└── motion-detection/                  # Motion detection components
    ├── README.md                      # Motion detection documentation
    └── mario/                         # Mario-themed motion detector
        ├── README.md                  # Mario component documentation
        ├── mario                      # init.d service script
        ├── mario.py                   # Python motion detection script
        └── mario-sounds.tar.gz        # Sound files archive
```

## Configuration

Key configuration variables in `mario.py`:
- `SENSOR_PIN = 23` - GPIO pin for PIR sensor
- `SOUND_DIR = "/usr/share/sounds/mario/"` - Directory containing sound files
- `STOP_FILE = "/tmp/stop_mario"` - File used to signal service stop
- `TIMER_FILE = "/tmp/mario_timer"` - File used to track cooldown period

Cooldown period: 1800 seconds (30 minutes) between sound playback events

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[License information to be added]

## Notes

This project is specifically optimized for Raspberry Pi Zero W hardware and Raspberry Pi OS.