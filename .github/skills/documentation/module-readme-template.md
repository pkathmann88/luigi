# Module Name

Brief one-line description of what the module does.

## Overview

2-3 paragraphs describing:
- What the module does
- Why it's useful
- Primary use cases
- How it fits into the Luigi ecosystem

## Features

- Key feature 1
- Key feature 2
- Key feature 3
- Integration with other modules (if applicable)

## Hardware Requirements

### Components

List all required hardware components with specifications:

- **Component Name** (Model/Type)
  - Specification 1
  - Specification 2
  - Operating voltage
  - Purchase link (if helpful)

- **Component Name 2**
  - Specifications...

### GPIO Pin Configuration

**Pin Assignments:**

| Function | BCM Pin | Physical Pin | Direction | Notes |
|----------|---------|--------------|-----------|-------|
| Sensor Input | GPIO X | Pin Y | Input | Pull-up/down? |
| LED Output | GPIO Z | Pin W | Output | Via resistor |

**Total GPIO Usage:** X pins

### Power Requirements

- Total current draw
- Power source (Pi sufficient or external needed?)
- Voltage requirements

### Wiring Diagram

```
Component            Raspberry Pi Zero W
─────────           ────────────────────
VCC      ─────────> Pin 2  (5V Power)
GND      ─────────> Pin 6  (Ground)
DATA     ─────────> Pin 16 (GPIO 23)
```

Or use detailed table format (see documentation-patterns.md).

### Wiring Safety Notes

⚠️ **Important Safety Considerations:**
- Voltage compatibility warnings
- Static electricity precautions
- Polarity checks
- Any component-specific warnings

## Software Requirements

- **Operating System:** Raspberry Pi OS (Debian-based)
- **Python Version:** Python 3.x
- **Required Packages:**
  - Package 1 - Purpose
  - Package 2 - Purpose
- **Dependencies on Other Modules:**
  - module/path - Why it's required

## Installation

### Prerequisites

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

### Automatic Installation (Recommended)

```bash
# Clone repository if needed
git clone https://github.com/pkathmann88/luigi.git
cd luigi

# Install module (dependencies handled automatically)
sudo ./setup.sh install category/module-name

# Verify installation
./setup.sh status category/module-name
```

The setup script automatically:
- Installs system dependencies
- Creates required directories
- Deploys configuration files
- Installs and enables systemd service
- Starts the service

### Manual Installation

**Only use if automatic installation fails.**

#### 1. Install System Dependencies

```bash
sudo apt-get install -y package1 package2
```

#### 2. Create Directories

```bash
sudo mkdir -p /etc/luigi/category/module-name
sudo mkdir -p /var/log/luigi
# Additional directories as needed
```

#### 3. Deploy Files

```bash
# Copy scripts
sudo cp category/module-name/module-name.py /usr/local/bin/module-name
sudo chmod +x /usr/local/bin/module-name

# Deploy configuration
sudo cp category/module-name/module.conf.example /etc/luigi/category/module-name/module.conf
sudo chmod 640 /etc/luigi/category/module-name/module.conf

# Deploy service
sudo cp category/module-name/module-name.service /etc/systemd/system/
sudo chmod 644 /etc/systemd/system/module-name.service
```

#### 4. Enable and Start Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable module-name
sudo systemctl start module-name
```

### Verification

```bash
# Check service status
sudo systemctl status module-name

# View logs
journalctl -u module-name -n 20

# Expected output:
# [Show what successful startup looks like]
```

## Configuration

**Configuration File:** `/etc/luigi/category/module-name/module.conf`

### Configuration Format

The configuration file uses INI-style key=value format:

```ini
# Section: Description
OPTION_1=value1
OPTION_2=value2

# Section: More Options
OPTION_3=value3
```

### Configuration Options

#### Option Category 1

- **`OPTION_1`** (type, required/optional)
  - Description of what this does
  - Default: `value`
  - Range/Options: valid values
  - Example: `OPTION_1=value`

- **`OPTION_2`** (type, required/optional)
  - Description
  - Default: `value`
  - Example: `OPTION_2=value`

#### Option Category 2

[Continue pattern for all configuration options]

### Applying Configuration Changes

```bash
# Edit configuration
sudo nano /etc/luigi/category/module-name/module.conf

# Restart service to apply
sudo systemctl restart module-name

# Verify changes applied
journalctl -u module-name -n 20
```

## Usage

### Starting and Stopping

```bash
# Start the service
sudo systemctl start module-name

# Stop the service
sudo systemctl stop module-name

# Restart the service
sudo systemctl restart module-name

# View status
sudo systemctl status module-name
```

### Checking Status

```bash
# View service status
sudo systemctl status module-name

# View recent logs
journalctl -u module-name -n 50

# Follow logs in real-time
journalctl -u module-name -f
```

### Common Operations

Describe common usage scenarios with examples:

**Operation 1: Description**
```bash
# Commands to perform operation
```

**Operation 2: Description**
```bash
# Commands
```

### Expected Behavior

Describe what normal operation looks like:
- What events trigger actions
- What outputs to expect
- Timing/frequency of operations

## Integration with Other Modules

### Home Assistant MQTT (Optional)

If the module supports MQTT integration:

**Prerequisites:**
- ha-mqtt module installed
- MQTT broker configured

**Setup:**

1. Install ha-mqtt if not already present:
```bash
sudo ./setup.sh install iot/ha-mqtt
```

2. Create sensor descriptor at `/etc/luigi/iot/ha-mqtt/sensors.d/sensor-name.json`:
```json
{
  "sensor_id": "sensor_name",
  "name": "Human-Readable Sensor Name",
  "module": "category/module-name",
  "device_class": "motion|temperature|humidity|...",
  "icon": "mdi:icon-name"
}
```

3. Run discovery:
```bash
sudo /usr/local/bin/luigi-discover
```

4. Enable MQTT in module configuration:
```ini
MQTT_ENABLED=true
MQTT_SENSOR_ID=sensor_name
```

5. Restart service:
```bash
sudo systemctl restart module-name
```

**Verification:**
Check Home Assistant for the new sensor entity.

See `iot/ha-mqtt/README.md` for complete MQTT integration documentation.

## Logs

### Log Locations

- **systemd Journal:** `journalctl -u module-name`
- **Log File (if applicable):** `/var/log/luigi/module-name.log`

### Viewing Logs

```bash
# Recent logs
journalctl -u module-name -n 50

# Real-time logs
journalctl -u module-name -f

# Errors only
journalctl -u module-name -p err

# Logs from specific time
journalctl -u module-name --since "2024-01-15 10:00"
```

### Log Rotation

Logs are automatically rotated by systemd. To manage journal size:

```bash
# Check journal disk usage
journalctl --disk-usage

# Clean old logs
sudo journalctl --vacuum-time=7d  # Keep 7 days
```

## Troubleshooting

### Issue 1: Service Won't Start

**Symptom:** 
Describe what the user sees/experiences

**Diagnosis:**
```bash
# Commands to diagnose
```

**Cause:**
Why this happens

**Solution:**
Step-by-step fix:
1. Step 1
2. Step 2
3. Verify fix worked

---

### Issue 2: [Problem Description]

**Symptom:** 
...

**Diagnosis:**
...

**Cause:**
...

**Solution:**
...

---

### Issue 3: [Another Common Issue]

[Continue pattern]

---

### General Debugging

For any issue:

1. **Check service status:**
   ```bash
   sudo systemctl status module-name
   ```

2. **View recent logs:**
   ```bash
   journalctl -u module-name -n 50
   ```

3. **Check configuration:**
   ```bash
   cat /etc/luigi/category/module-name/module.conf
   ```

4. **Verify wiring (if hardware module):**
   - Double-check all GPIO connections
   - Verify component voltages
   - Test components individually

5. **Restart service:**
   ```bash
   sudo systemctl restart module-name
   ```

If problems persist, open an issue on [GitHub](https://github.com/pkathmann88/luigi/issues) with:
- Service status output
- Recent log entries (last 50 lines)
- Configuration file contents
- Hardware setup description (if applicable)

## Uninstallation

```bash
# Uninstall module (keeps configuration)
sudo ./setup.sh uninstall category/module-name

# Complete removal (purge everything)
sudo ./setup.sh purge category/module-name
```

**What gets removed:**
- Service file
- Python scripts
- Resources

**What gets kept (unless purge):**
- Configuration files
- Log files

## Technical Details

### Architecture

Brief description of code structure:
- Main classes/functions
- Hardware abstraction approach
- Error handling strategy

### Code Structure

```
module-name/
├── module-name.py       # Main application
├── module-name.service  # systemd service
├── module.conf.example  # Configuration template
└── setup.sh            # Installation script
```

### Key Components

**Class: ClassName**
- Purpose
- Key methods

**Function: function_name**
- Purpose
- Parameters

### Development and Testing

For developers:

```bash
# Syntax validation
python3 -m py_compile category/module-name/module-name.py
shellcheck category/module-name/setup.sh

# Test without hardware (if mock GPIO supported)
# Instructions for mock testing
```

## Security Considerations

- Security features implemented
- Permissions required
- Network security (if applicable)
- Data handling practices

## Performance Notes

- Resource usage (CPU, memory)
- Timing characteristics
- Scalability considerations

## Future Enhancements

Planned improvements or features (optional):
- Feature idea 1
- Feature idea 2

## Contributing

Contributions welcome! When contributing to this module:

1. Test on actual Raspberry Pi hardware
2. Follow existing code patterns
3. Update documentation for any changes
4. Run syntax validation before committing
5. Test installation and uninstallation

## Related Documentation

- [Main Luigi README](/README.md) - Platform overview
- [ha-mqtt Module](../../iot/ha-mqtt/README.md) - For MQTT integration
- [Agent Skills](../../.github/skills/) - Development guidance

## License

[License information]

## Credits

- Original author
- Contributors
- Third-party libraries/resources used

---

**Questions or Issues?** Open an issue on [GitHub](https://github.com/pkathmann88/luigi/issues)
