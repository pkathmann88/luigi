# System Optimization Module

A system optimization module for Raspberry Pi Zero W that improves performance by disabling unnecessary services, optimizing boot configuration, and removing unused packages.

## Contents

- `setup.sh` - Automated installation script for easy deployment
- `optimize.py` - Python script that applies system optimizations
- `optimize.conf.example` - Sample configuration file with optimization settings

## Overview

This module optimizes the Raspberry Pi Zero W for better performance and lower resource usage by:

- **Disabling Unnecessary Services**: Stops and disables systemd services that aren't needed for headless or embedded operations (e.g., Bluetooth, ModemManager, avahi-daemon)
- **Boot Configuration**: Modifies `/boot/firmware/config.txt` to disable unused hardware interfaces and reduce GPU memory
- **Kernel Module Blacklisting**: Prevents loading of unused kernel modules
- **Package Removal**: Removes unnecessary packages to free up disk space
- **Adafruit Sound Bonnet Setup**: Optionally installs and configures the Adafruit Speaker Bonnet for high-quality audio output

## Features

- **Safe Defaults**: Conservative default settings that work for most headless setups
- **Highly Configurable**: INI-style config file at `/etc/luigi/system/optimization/optimize.conf`
- **Idempotent Execution**: Can be run multiple times safely - applies current configuration each time
- **Dry-Run Mode**: Preview changes before applying them
- **Comprehensive Logging**: All operations logged to `/var/log/system-optimization.log`
- **Backup Protection**: Automatically backs up boot config before modifications
- **Interactive Installation**: Optional guided installation with prompts
- **Sound Bonnet Integration**: Automated setup for Adafruit Sound Bonnet hardware

## Quick Start

The easiest way to install the system optimization module is using the provided setup script:

```bash
# Navigate to the module directory
cd system/optimization

# Run the installation script
sudo ./setup.sh install
```

The setup script will:
1. Install the optimization script to `/usr/local/bin/optimize.py`
2. Create configuration directory at `/etc/luigi/system/optimization/`
3. Deploy the default configuration file
4. Optionally run the optimization immediately

## Configuration

Configuration is managed through `/etc/luigi/system/optimization/optimize.conf` (INI format).

### Services Section

Configures which systemd services to disable or mask:

```ini
[Services]
# Services to disable (comma-separated)
disable_services=bluetooth,hciuart,ModemManager,triggerhappy,console-setup

# Services to mask (prevent from being started)
mask_services=apt-daily-upgrade.timer,apt-daily.timer
```

**Common services safe to disable on headless systems:**
- `bluetooth`, `hciuart`: Bluetooth services
- `ModemManager`: Modem management (not needed for most setups)
- `avahi-daemon`: mDNS/Bonjour (only needed for .local domain names)
- `triggerhappy`: Hotkey daemon
- `console-setup`: Console font/keymap setup
- `alsa-restore`: Audio state restoration (if not using audio)
- `rpc-statd-notify`: NFS client service (if not using NFS)
- `rpi-eeprom-update`: EEPROM update service (can be run manually)

### Boot Section

Configures boot-time hardware optimizations in `/boot/firmware/config.txt`:

```ini
[Boot]
# Disable unused hardware interfaces to save memory and CPU
disable_i2c=no
disable_i2s=yes
disable_spi=no
disable_audio=no
disable_camera=yes
disable_wifi=no
disable_bluetooth=no

# GPU memory in MB (16 is minimum for headless, default is 64)
gpu_mem=16
```

**Hardware Interface Optimization:**
- **I2C**: Inter-Integrated Circuit bus (disable if not using I2C devices)
- **I2S**: Inter-IC Sound (disable if not using I2S audio)
- **SPI**: Serial Peripheral Interface (disable if not using SPI devices)
- **Audio**: Built-in audio (disable for headless systems)
- **Camera**: Camera support (disable if not using camera)
- **WiFi**: Wireless networking (disable if using Ethernet only)
- **Bluetooth**: Bluetooth radio (disable if not needed)

**GPU Memory:**
- Default: 64MB allocated to GPU
- Headless minimum: 16MB (frees ~48MB for system RAM)
- Lower values free more memory for applications

### Sound Bonnet Section

Configures Adafruit Sound Bonnet (Speaker Bonnet) setup:

```ini
[SoundBonnet]
# Adafruit Sound Bonnet (Speaker Bonnet) Setup
# Set to yes to install and configure the Adafruit Sound Bonnet
enable_sound_bonnet=yes
```

**Adafruit Sound Bonnet:**
- The Sound Bonnet is an I2S DAC (Digital-to-Analog Converter) add-on board for Raspberry Pi
- Provides high-quality audio output for speakers
- **Enabled by default** to support Luigi modules that require audio playback (e.g., Mario motion detection)
- When enabled, the optimization script will:
  - Install required dependencies (wget, python3-pip)
  - Install adafruit-python-shell Python package
  - Download and run the official Adafruit i2samp.py installation script
  - Configure I2S audio interface and ALSA settings
  - Add necessary device tree overlays to boot configuration
- **Important Note:** I2C must be enabled manually via `sudo raspi-config` → Interface Options → I2C if you plan to use I2C devices
  - I2C is **not required** for basic audio functionality on the Sound Bonnet
  - The Sound Bonnet uses I2S for audio, not I2C
  - Enable I2C only if you have additional I2C sensors or peripherals
- After installation, a reboot is required for changes to take effect
- Use `alsamixer` to adjust volume (50% is a good starting point)
- Set to `no` if you don't have a Sound Bonnet or prefer different audio hardware
- Reference: [Adafruit Sound Bonnet Setup Guide](https://learn.adafruit.com/adafruit-speaker-bonnet-for-raspberry-pi/raspberry-pi-usage)

### Kernel Section

Configures kernel module blacklisting:

```ini
[Kernel]
# Kernel modules to blacklist (comma-separated)
# Example modules:
# - snd_bcm2835: Built-in audio
# - bcmbt: Bluetooth
# - brcmfmac, brcmutil: WiFi
# - uvc, videobuf2: Camera/video
blacklist_modules=
```

### Packages Section

Configures packages to remove:

```ini
[Packages]
# Packages to remove (comma-separated)
# Be careful - only remove packages you're certain are not needed
# Examples: bluez, avahi-daemon, modemmanager
remove_packages=
```

### Logging Section

Configures logging behavior:

```ini
[Logging]
log_file=/var/log/system-optimization.log
log_level=INFO
```

## Usage

### Running Optimization

After installation, run the optimization script:

```bash
# Preview changes (dry-run mode)
sudo optimize.py --dry-run

# Apply optimizations
sudo optimize.py

# Reboot to apply all changes
sudo reboot
```

**The script is fully idempotent** - you can run it multiple times safely:
- If you change the configuration file, run `optimize.py` again to apply the new settings
- Services already disabled will be skipped
- Boot configuration will be updated to match the current config
- Packages already removed will be skipped
- Each run applies the current configuration state

### Command-Line Options

```
sudo optimize.py [OPTIONS]

Options:
  --dry-run          Show what would be done without making changes
  --config FILE      Use alternative config file
  --help             Show help message
```

### Checking Status

Check the installation status and view recent logs:

```bash
sudo ./setup.sh status
```

### Viewing Logs

View the full optimization log:

```bash
sudo cat /var/log/system-optimization.log
```

View recent log entries:

```bash
sudo tail -f /var/log/system-optimization.log
```

## Best Practices

1. **Always review the config** before running optimizations
2. **Use dry-run mode first** to preview changes
3. **Test on a non-critical system** before deploying to production
4. **Keep backups** of important files (boot config is auto-backed up)
5. **Document changes** for future reference
6. **Reboot after optimizations** to ensure all changes take effect

## Safety and Reversibility

### What Gets Modified

- **Systemd services**: Disabled or masked (can be re-enabled)
- **Boot config**: Modified with backup created (`.bak` file)
- **Kernel modules**: Blacklisted in `/etc/modprobe.d/luigi-blacklist.conf`
- **Packages**: Removed with apt-get (can be reinstalled)

### Reverting Changes

**Re-enable services:**
```bash
sudo systemctl enable service-name
sudo systemctl start service-name
```

**Restore boot config:**
```bash
sudo cp /boot/firmware/config.txt.bak /boot/firmware/config.txt
sudo reboot
```

**Remove module blacklist:**
```bash
sudo rm /etc/modprobe.d/luigi-blacklist.conf
sudo reboot
```

**Reinstall packages:**
```bash
sudo apt-get install package-name
```

## Expected Performance Improvements

Based on community benchmarks and best practices:

- **Memory savings**: 50-100MB+ of freed RAM (depending on disabled services)
- **Faster boot**: 10-30% reduction in boot time
- **Lower CPU usage**: Fewer background processes
- **Extended SD card life**: Reduced write operations
- **Improved stability**: Fewer services means fewer potential failures

## Use Cases

This module is ideal for:

- **Headless servers**: Systems without display or keyboard
- **Embedded applications**: Dedicated single-purpose devices
- **IoT projects**: Resource-constrained deployments
- **Motion detection systems**: Like the Luigi Mario module (Sound Bonnet enabled by default for audio playback)
- **Sensor monitoring**: Environmental or automation projects
- **Network services**: Web servers, API endpoints, etc.
- **Audio applications**: Projects requiring sound output (Sound Bonnet provides high-quality I2S audio)

## Uninstallation

To uninstall the system optimization module:

```bash
cd system/optimization
sudo ./setup.sh uninstall
```

**Note**: Uninstalling the module does NOT revert applied optimizations. You must manually re-enable services and restore boot configuration if desired.

## Troubleshooting

### Services Won't Disable

Some services may not exist on your system. The script will skip non-existent services automatically.

### Boot Config Not Found

The script checks both `/boot/firmware/config.txt` and `/boot/config.txt`. If neither exists, boot optimizations will be skipped.

### Permission Errors

All operations require root privileges. Always run with `sudo`.

### Optimization Failed

Check the log file for detailed error messages:
```bash
sudo cat /var/log/system-optimization.log
```

### System Won't Boot After Optimization

If you encounter boot issues:
1. Connect to the Pi via serial console or SSH (if still accessible)
2. Restore the boot config backup: `sudo cp /boot/firmware/config.txt.bak /boot/firmware/config.txt`
3. Reboot

If SSH is not accessible, remove the SD card and edit the config file from another computer.

## Technical Details

### System Requirements

- Raspberry Pi Zero W (or compatible)
- Raspberry Pi OS (Raspbian) - Lite or Full
- Python 3.6 or later
- Root access (sudo)

### File Locations

- Script: `/usr/local/bin/optimize.py`
- Config: `/etc/luigi/system/optimization/optimize.conf`
- Log: `/var/log/system-optimization.log`
- Boot Config: `/boot/firmware/config.txt` or `/boot/config.txt`
- Module Blacklist: `/etc/modprobe.d/luigi-blacklist.conf`

### Dependencies

- Python 3 (automatically installed by setup script)
- systemd (standard on Raspberry Pi OS)
- apt-get (standard on Raspberry Pi OS)

## Contributing

To add new optimization features:

1. Update `optimize.conf.example` with new options
2. Add configuration parsing in `optimize.py` Config class
3. Implement optimization logic in SystemOptimizer class
4. Add documentation to this README
5. Test thoroughly on actual hardware

## Related Modules

- **motion-detection/mario**: Motion detection with PIR sensors
- Other Luigi modules may benefit from system optimization

## References

This module implements best practices from:

- [Raspberry Pi Official Documentation](https://www.raspberrypi.com/documentation/)
- [Optimize Your Raspberry Pi by Disabling Unneeded Services](https://thelinuxcode.com/disable-unnecessary-services-raspberry-pi/)
- [Removing Unwanted Services for Headless Raspberry Pi](https://felsqualle.com/posts/2025/07/bts3-removing-unwanted-modules-for-headless-pi-zero/)
- [Raspberry Pi Forums - Boot Speed Optimization](https://forums.raspberrypi.com/viewtopic.php?t=335212)

## License

MIT License - see repository root for details

## Author

Luigi Project - Raspberry Pi Hardware Integration Platform
