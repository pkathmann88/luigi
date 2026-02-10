# luigi

A Python project designed to run on Raspberry Pi Zero W for motion detection with sound playback.

## Platform

This project is designed to run on:
- **Hardware:** Raspberry Pi Zero W
- **Operating System:** Raspberry Pi OS
- **Programming Language:** Python

## Overview

Luigi is an extensible platform for Raspberry Pi hardware projects, designed to make it easy to deploy and manage multiple modules for different purposes. Currently includes motion detection with sound playback, but designed to support sensors, automation, security, and IoT modules.

### Current Modules

- **Mario Motion Detection** (`motion-detection/mario/`) - Plays random Mario sound effects when motion is detected via PIR sensor

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

### Quick Start - Install All Modules

The easiest way to install Luigi is using the centralized setup script:

```bash
# Clone the repository
git clone https://github.com/pkathmann88/luigi.git
cd luigi

# Install all modules
sudo ./setup.sh install
```

This will automatically discover and install all available Luigi modules.

### Install Specific Module

To install only a specific module:

```bash
# Install only the mario motion detection module
sudo ./setup.sh install motion-detection/mario
```

### Manual Installation

For manual installation of individual modules, see the README.md file in each module directory (e.g., `motion-detection/mario/README.md`).

### Check Installation Status

```bash
# Check status of all modules
./setup.sh status

# Check status of specific module
./setup.sh status motion-detection/mario
```

## Usage

### Managing Modules

Each module can be managed using its own setup script or the centralized setup script.

**Using centralized setup:**
```bash
# Install all modules
sudo ./setup.sh install

# Install specific module
sudo ./setup.sh install motion-detection/mario

# Uninstall all modules
sudo ./setup.sh uninstall

# Uninstall specific module
sudo ./setup.sh uninstall motion-detection/mario

# Check status of all modules
./setup.sh status
```

**Managing services (after installation):**
```bash
# Example: Managing mario motion detection service
sudo systemctl start mario.service
sudo systemctl stop mario.service
sudo systemctl restart mario.service
sudo systemctl status mario.service

# View logs
sudo journalctl -u mario.service -f
```

For detailed usage instructions for each module, see the README.md file in the module directory.

## Features

- **Centralized Setup** - Install/uninstall all modules with a single command
- **Modular Architecture** - Each module is independent with its own setup script
- **Extensible Design** - Easy to add new modules in various categories (motion detection, sensors, automation, security, IoT)
- **Modern Service Management** - systemd integration for reliable service control
- **Hardware Abstraction** - Clean separation between hardware and application logic
- **Discovery System** - Automatically discovers and manages all installed modules

## Project Structure

```
luigi/
├── README.md                          # This file
├── setup.sh                           # Centralized setup script (install/uninstall all modules)
└── motion-detection/                  # Motion detection components
    ├── README.md                      # Motion detection documentation
    └── mario/                         # Mario-themed motion detector
        ├── README.md                  # Mario component documentation
        ├── setup.sh                   # Mario module setup script
        ├── mario.py                   # Python motion detection script
        ├── mario.service              # systemd service unit
        └── mario-sounds.tar.gz        # Sound files archive
```

Luigi is designed as an extensible platform. Additional modules can be added in the following categories:
- `motion-detection/` - Motion detection modules
- `sensors/` - Environmental sensors (temperature, humidity, etc.)
- `automation/` - Automation and control modules
- `security/` - Security monitoring modules
- `iot/` - IoT integration modules

Each module should contain its own `setup.sh` script for installation and management. The centralized `setup.sh` in the project root will automatically discover and manage all modules.

## Configuration

Configuration for each module is documented in the module's README.md file. For example, see `motion-detection/mario/README.md` for mario module configuration options.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[License information to be added]

## Notes

This project is specifically optimized for Raspberry Pi Zero W hardware and Raspberry Pi OS.