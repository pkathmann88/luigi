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
- **Agent Skills** - Built-in Copilot guidance for documentation, hardware, Python development, and deployment

## Quick Start

```bash
# Clone the repository
git clone https://github.com/pkathmann88/luigi.git
cd luigi

# Install all modules (requires root for system integration)
sudo ./setup.sh install

# During installation, you will be prompted to:
# 1. Optionally install the Adafruit Sound Bonnet for audio modules
# 2. Configure ALSA audio device (automatic device detection)
# 3. Optionally fix audio popping/crackling on I2S audio devices

# Check installation status
./setup.sh status

# Uninstall modules (keeps configs)
sudo ./setup.sh uninstall

# Complete removal (purge everything)
sudo ./setup.sh purge
```

That's it! Services are now running and will start automatically on boot.

**For complete uninstallation instructions, see [UNINSTALL_GUIDE.md](UNINSTALL_GUIDE.md)**

## Current Modules

Luigi currently includes the following modules. See each module's README for detailed documentation:

| Module | Category | Description |
|--------|----------|-------------|
| [Mario Motion Detection](motion-detection/mario/) | motion-detection | Plays random Mario-themed sounds when motion is detected via PIR sensor |
| [Home Assistant MQTT](iot/ha-mqtt/) | iot | Zero-touch MQTT bridge connecting Luigi sensors to Home Assistant for centralized monitoring and automation |
| [System Info](system/system-info/) | system | Monitors and publishes system metrics (uptime, CPU temp, memory, disk) to Home Assistant every 5 minutes |
| [System Optimization](system/optimization/) | system | Optimizes Raspberry Pi performance by disabling services and tuning boot config |

For detailed information about each module (features, installation, configuration, troubleshooting), please refer to the module-specific README files.

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
├── module.json        # Module metadata (optional, for dependencies)
├── setup.sh           # Installation script (install/uninstall/status)
├── module.py          # Python application
├── module.service     # systemd service unit
└── resources/         # Additional files (sounds, configs, etc.)
```

### Centralized Management

The root `setup.sh` automatically discovers modules in all categories and handles dependency resolution:

```bash
# Install all modules (automatically resolves dependencies)
sudo ./setup.sh install

# Install specific module
sudo ./setup.sh install motion-detection/mario

# Uninstall all modules
sudo ./setup.sh uninstall

# Check status
./setup.sh status
```

**Dependency Management:**

Modules can declare dependencies on other modules using an optional `module.json` file. The setup system automatically:
- Reads module metadata and dependencies
- Performs topological sort to determine installation order
- Installs dependencies before dependent modules
- Detects and reports circular dependencies

Example `module.json`:
```json
{
  "name": "mario",
  "version": "1.0.0",
  "description": "Motion detection with sound effects",
  "category": "motion-detection",
  "dependencies": ["iot/ha-mqtt"]
}
```

See [MODULE_SCHEMA.md](MODULE_SCHEMA.md) for complete schema documentation.

## Usage

### Managing Services

Modules that run as services can be managed using standard systemctl commands:

```bash
# Start/stop/restart a service
sudo systemctl start <service-name>
sudo systemctl stop <service-name>
sudo systemctl restart <service-name>

# Check service status
sudo systemctl status <service-name>

# Enable/disable autostart on boot
sudo systemctl enable <service-name>
sudo systemctl disable <service-name>

# View real-time logs
sudo journalctl -u <service-name> -f
```

### Module-Specific Usage

Each module has its own README with detailed usage instructions, configuration options, and troubleshooting guidance. Refer to the module's README for complete documentation.

## Development

### Creating a New Module

1. **Choose a category** (motion-detection, sensors, automation, security, iot)
2. **Create module directory:** `category/your-module/`
3. **Implement required files:**
   - `README.md` - Documentation
   - `setup.sh` - Installation script supporting: `install`, `uninstall`, `status`
   - `your-module.py` - Python application
   - `your-module.service` - systemd service unit
   - `module.json` - (Optional) Module metadata and dependencies

4. **Declare dependencies** (if needed):
   Create `module.json` to declare dependencies on other modules:
   ```json
   {
     "name": "your-module",
     "version": "1.0.0",
     "description": "Your module description",
     "category": "sensors",
     "dependencies": ["iot/ha-mqtt"]
   }
   ```
   Dependencies will be installed automatically before your module. See [MODULE_SCHEMA.md](MODULE_SCHEMA.md) for details.

5. **Follow established patterns:**
   - Use Config class for constants
   - Implement GPIOManager for hardware abstraction
   - Use signal handlers (SIGTERM/SIGINT) for shutdown
   - Add structured logging with rotation
   - Implement security hardening (see mario module)

6. **Test installation:**
```bash
sudo ./setup.sh install category/your-module
./setup.sh status category/your-module
```

### Agent Skills

Luigi includes Copilot Agent Skills for development assistance:

- **`.github/skills/documentation/`** - Documentation standards, module README templates, API documentation
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
- **Logs:** `/var/log/luigi/` and systemd journal

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
│       ├── documentation/         # Documentation standards and templates
│       ├── python-development/    # Python patterns and testing
│       ├── raspi-zero-w/         # Hardware and GPIO reference
│       └── system-setup/         # Deployment automation
├── motion-detection/             # Motion detection modules
│   ├── README.md                 # Category overview
│   └── mario/                    # Mario motion detection
│       └── README.md             # Module documentation
├── system/                       # System-level modules
│   └── optimization/            # System optimization
│       └── README.md            # Module documentation
├── README.md                    # This file
├── setup.sh                     # Centralized module management
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

- **Module Documentation:** See individual module READMEs for detailed documentation
- **Agent Skills:** Context-aware development guidance in `.github/skills/`
- **Raspberry Pi GPIO:** See `.github/skills/raspi-zero-w/gpio-pinout.md`

---

**Optimized for Raspberry Pi Zero W** - Compatible with other Raspberry Pi models