# Luigi Uninstallation Guide

## Overview

Luigi provides comprehensive uninstallation options to remove installed modules and restore your system to its pre-Luigi state.

## Uninstallation Modes

### 1. Normal Uninstall (Recommended)

Removes module files and services but keeps configurations. Prompts for each optional removal.

```bash
sudo ./setup.sh uninstall
```

**What it removes:**
- Python scripts and binaries
- Service files
- Libraries and helper scripts

**What it preserves (unless you choose to remove):**
- Configuration files
- Log files
- Sound files (for mario)
- Certificates (for management-api)
- Installed system packages

**Interactive prompts for:**
- Configuration removal
- Log file removal
- Package removal (per module)

### 2. Purge Mode (Complete Cleanup)

Completely removes all Luigi files, configurations, and installed packages without prompts. System is restored to pre-installation state.

```bash
sudo ./setup.sh purge
```

**Confirmation required:** Type `yes` to proceed

**What it removes:**
- Everything from normal uninstall
- All configuration files
- All log files
- All sound files
- All certificates
- All installed system packages
- Setup script dependencies (jq)

## Module-Specific Uninstallation

### Uninstall Single Module

```bash
# Normal uninstall
sudo ./setup.sh uninstall motion-detection/mario

# Purge single module
sudo ./setup.sh purge motion-detection/mario
```

## Packages Removed by Purge

Each module removes its own dependencies when purged:

### Main Setup Script
- `jq` - JSON processor for dependency management

### ha-mqtt Module
- `mosquitto-clients` - MQTT command-line tools
- `jq` - JSON processor

### mario Module
- `python3-rpi.gpio` - GPIO library for Python
- `alsa-utils` - ALSA sound utilities

### system-info Module
- `python3-psutil` - Process and system utilities for Python

### management-api Module
- `nodejs` - Node.js runtime
- `npm` - Node.js package manager

### optimization Module
- **Does not remove python3** (system-critical package)
- Note: Applied optimizations (disabled services, boot config changes) remain active

## Examples

### Complete Removal of All Modules

```bash
# Step 1: Purge all modules
sudo ./setup.sh purge

# Step 2: Verify clean system
./setup.sh status
```

### Remove Specific Module with Packages

```bash
# Remove mario and its packages
sudo ./setup.sh purge motion-detection/mario
```

### Uninstall Without Removing Packages

```bash
# Uninstall all modules
sudo ./setup.sh uninstall

# When prompted, answer 'N' to package removal questions
```

## Verification

After uninstallation, verify the system is clean:

```bash
# Check no services are running
systemctl list-units | grep -i luigi
systemctl list-units | grep -i mario
systemctl list-units | grep -i system-info
systemctl list-units | grep -i management-api

# Check no Luigi files remain
ls -la /usr/local/bin/ | grep -i luigi
ls -la /etc/luigi/
ls -la /var/log/ | grep -i luigi

# Check package status (if purged)
dpkg -l | grep -E "mosquitto-clients|python3-rpi.gpio|alsa-utils|python3-psutil"
```

## Notes and Warnings

### Purge Mode
- **Irreversible**: Cannot be undone
- **Requires explicit confirmation**: Type `yes` to proceed
- **Removes all data**: Configurations, logs, everything

### Optimization Module
- Uninstall does NOT revert applied optimizations
- Services disabled by optimization remain disabled
- Boot configuration changes remain active
- To revert: Manually re-enable services and edit boot config

### Package Safety
- `python3` is not removed even in purge mode (system-critical)
- Other packages are safely removed with `apt-get autoremove`
- Dependencies used by other software are preserved by apt

### Configuration Preservation
- Normal uninstall keeps configs by default
- Useful for reinstalling with same settings
- Configs can be manually removed if needed

## Troubleshooting

### Service Won't Stop
```bash
# Force stop if needed
sudo systemctl stop mario.service --force
sudo systemctl disable mario.service
sudo rm -f /etc/systemd/system/mario.service
sudo systemctl daemon-reload
```

### Package Removal Fails
```bash
# Check what's using the package
apt-cache rdepends package-name

# Force remove if safe
sudo apt-get remove --purge package-name
sudo apt-get autoremove
```

### Partial Uninstall
```bash
# If uninstall fails partway, run again
sudo ./setup.sh uninstall

# Or manually clean specific module
cd module-directory
sudo ./setup.sh uninstall
```

## Best Practices

1. **Test in VM first**: Try purge in a test environment before production
2. **Backup configs**: Save `/etc/luigi/` before purging if you might need them
3. **Check dependencies**: Verify no other software needs Luigi packages
4. **Document customizations**: Note any manual changes made to configs
5. **Verify clean state**: Check system after purge to ensure complete removal

## Support

For issues or questions about uninstallation:
1. Check `./setup.sh status` to see what's installed
2. Review module-specific README files
3. Run `./setup.sh --help` for command reference
