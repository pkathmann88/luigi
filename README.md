# Luigi

**A modular platform for Raspberry Pi hardware projects with automated deployment and service management.**

Luigi makes it easy to build, deploy, and manage hardware-integrated applications on Raspberry Pi. The platform provides a centralized setup system, modern Python architecture patterns, and comprehensive tooling for rapid development of GPIO-based projects.

## Key Features

- **One-Command Deployment** - Centralized setup script installs/uninstalls all modules automatically
- **Modular Architecture** - Each module is self-contained with its own setup script and dependencies
- **systemd Integration** - Reliable service management with automatic restart and logging
- **Hardware Abstraction** - Clean separation between hardware control and application logic
- **Security Hardened** - Command injection prevention, path validation, and log sanitization
- **Mock GPIO Support** - Develop and test without physical hardware
- **Agent Skills** - Built-in Copilot guidance for hardware, Python development, and deployment

## Quick Start

```bash
# Clone the repository
git clone https://github.com/pkathmann88/luigi.git
cd luigi

# Install all modules (requires root for system integration)
sudo ./setup.sh install

# Check installation status
./setup.sh status
```

That's it! Services are now running and will start automatically on boot.

## Current Modules

### Mario Motion Detection
**Location:** `motion-detection/mario/`  
**Description:** Plays random Mario-themed sound effects when motion is detected via PIR sensor

**Features:**
- PIR sensor integration (default GPIO 23)
- Random audio playback with configurable cooldown (default 30 min)
- Modern OOP architecture (Config, GPIOManager, PIRSensor, MotionDetectionApp classes)
- Rotating logs with structured logging
- Graceful shutdown via signal handlers
- Comprehensive automated setup script

**Hardware:** PIR motion sensor, audio output device  
**Service:** `mario.service` (systemd)

### System Optimization
**Location:** `system/optimization/`  
**Description:** Optimizes Raspberry Pi Zero W for performance by disabling unnecessary services and configuring boot parameters

**Features:**
- Disables unused systemd services (bluetooth, avahi-daemon, etc.)
- Optimizes boot configuration (GPU memory, hardware interfaces)
- Blacklists unused kernel modules
- Removes unnecessary packages
- Dry-run mode for safe testing
- Automatic boot config backup

**Benefits:** 50-100MB+ RAM savings, 10-30% faster boot time  
**Usage:** `sudo optimize.py` (one-time script, not a service)

## Platform

**Target Hardware:** Raspberry Pi Zero W (compatible with other Raspberry Pi models)  
**Operating System:** Raspberry Pi OS (Debian-based)  
**Language:** Python 3  
**Dependencies:** RPi.GPIO, ALSA utils

## Architecture

### Module Categories

Luigi supports six module categories for different use cases:

```
luigi/
├── motion-detection/    # Motion sensors and detection
├── sensors/            # Environmental sensors (temp, humidity, light)
├── automation/         # Control and automation (relays, motors)
├── security/           # Security monitoring and alerts
├── iot/               # IoT integration and networking
└── system/            # System optimization and configuration
```

### Module Structure

Each module follows a standardized structure:

```
category/module-name/
├── README.md          # Module documentation
├── setup.sh           # Installation script (install/uninstall/status)
├── module.py          # Python application
├── module.service     # systemd service unit
└── resources/         # Additional files (sounds, configs, etc.)
```

### Centralized Management

The root `setup.sh` automatically discovers modules in all categories:

```bash
# Install all modules
sudo ./setup.sh install

# Install specific module
sudo ./setup.sh install motion-detection/mario

# Uninstall all modules
sudo ./setup.sh uninstall

# Check status
./setup.sh status
```

## Usage

### Managing Services

After installation, manage services using systemctl:

```bash
# Start/stop/restart a service
sudo systemctl start mario.service
sudo systemctl stop mario.service
sudo systemctl restart mario.service

# Check service status
sudo systemctl status mario.service

# Enable/disable autostart on boot
sudo systemctl enable mario.service
sudo systemctl disable mario.service

# View real-time logs
sudo journalctl -u mario.service -f
```

### Module-Specific Usage

Each module has its own README with detailed usage instructions:
- **Mario Motion Detection:** See `motion-detection/mario/README.md`

## Development

### Creating a New Module

1. **Choose a category** (motion-detection, sensors, automation, security, iot)
2. **Create module directory:** `category/your-module/`
3. **Implement required files:**
   - `README.md` - Documentation
   - `setup.sh` - Installation script supporting: `install`, `uninstall`, `status`
   - `your-module.py` - Python application
   - `your-module.service` - systemd service unit

4. **Follow established patterns:**
   - Use Config class for constants
   - Implement GPIOManager for hardware abstraction
   - Use signal handlers (SIGTERM/SIGINT) for shutdown
   - Add structured logging with rotation
   - Implement security hardening (see mario module)

5. **Test installation:**
```bash
sudo ./setup.sh install category/your-module
./setup.sh status category/your-module
```

### Agent Skills

Luigi includes Copilot Agent Skills for development assistance:

- **`.github/skills/python-development/`** - Python patterns, testing, hardware abstraction
- **`.github/skills/raspi-zero-w/`** - GPIO pinout, wiring diagrams, hardware setup
- **`.github/skills/system-setup/`** - Deployment scripts, service configuration

These skills provide context-aware guidance when working with Copilot.

### Code Quality Standards

- **Python:** Modern OOP design, type hints, comprehensive error handling
- **Shell Scripts:** POSIX-compliant, validated with shellcheck
- **Security:** No shell=True, path validation, input sanitization
- **Services:** systemd best practices, security sandboxing, graceful shutdown
- **Documentation:** Clear README for each module with examples

## Technical Details

### Installation Locations

- **Python Scripts:** `/usr/local/bin/`
- **systemd Services:** `/etc/systemd/system/`
- **Resources:** `/usr/share/` (module-specific subdirectories)
- **Logs:** `/var/log/` and systemd journal

### Python Architecture

Modern modules use the following pattern:

```python
class Config:
    """Configuration constants"""
    
class GPIOManager:
    """Hardware abstraction layer"""
    
class SensorClass:
    """Sensor-specific logic"""
    
class ApplicationClass:
    """Main application orchestration"""
```

### Security Features

- Command injection prevention (subprocess.run with list args)
- Path traversal prevention (os.path.commonpath validation)
- Log sanitization (length limits, newline removal)
- Timeout protection on subprocess calls
- systemd security sandboxing (PrivateTmp, NoNewPrivileges)

## Repository Structure

```
luigi/
├── .github/
│   ├── copilot-instructions.md    # Agent instructions
│   └── skills/                    # Copilot Agent Skills
│       ├── python-development/    # Python patterns and testing
│       ├── raspi-zero-w/         # Hardware and GPIO reference
│       └── system-setup/         # Deployment automation
├── motion-detection/
│   └── mario/                    # Mario motion detection module
│       ├── README.md
│       ├── setup.sh
│       ├── mario.py
│       ├── mario.service
│       └── mario-sounds.tar.gz
├── README.md                     # This file
├── setup.sh                      # Centralized module management
└── .gitignore
```

## Contributing

Contributions are welcome! When contributing:

1. **Follow existing patterns** - Review the mario module as reference
2. **Test thoroughly** - Validate on actual Raspberry Pi hardware
3. **Document well** - Include detailed README with module
4. **Security first** - Follow security hardening practices
5. **Submit PR** - Include description of module purpose and testing performed

## License

[License information to be added]

## Resources

- **Mario Module:** Full-featured reference implementation with modern architecture
- **Agent Skills:** Context-aware development guidance in `.github/skills/`
- **Raspberry Pi GPIO:** See `.github/skills/raspi-zero-w/gpio-pinout.md`

---

**Optimized for Raspberry Pi Zero W** - Compatible with other Raspberry Pi models