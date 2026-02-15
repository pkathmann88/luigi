# Luigi Permission Management

## Overview

The Luigi management-api service runs as a dedicated user (`luigi-api`) and needs read access to:
- Log files in `/var/log/luigi/`
- Config directories and files in `/etc/luigi/`

This document explains the permission strategy and how to manage permissions correctly.

## Permission Strategy

**Problem:** Module services run as different users (root, pi, module-specific users), but the management-api needs to read their logs and configs.

**Solution:** Use Linux group permissions with `luigi-api` as a shared group:
- Module files are owned by the module user (e.g., root)
- Files have `luigi-api` as the group
- Group has read permission, allowing management-api to access them

## Standard Permissions

### Log Files
- **Location:** `/var/log/luigi/<module-name>.log`
- **Owner:** Module user (e.g., root, pi)
- **Group:** `luigi-api`
- **Permissions:** `640` (rw-r-----)
- **Meaning:** Owner can read/write, group can read, others have no access

### Config Directories
- **Location:** `/etc/luigi/<module-path>/`
- **Owner:** `root`
- **Group:** `luigi-api`
- **Permissions:** `755` (rwxr-xr-x)
- **Meaning:** All can read/list, only owner can write

### Config Files
- **Location:** `/etc/luigi/<module-path>/<module-name>.conf`
- **Owner:** `root`
- **Group:** `luigi-api`
- **Permissions:** `644` (rw-r--r--)
- **Meaning:** All can read, only owner can write

## For Module Developers

### During Installation

When writing a module setup script, use the provided helper functions:

```bash
# Source the helpers
source "$REPO_ROOT/util/setup-helpers.sh"

# In your install function:

# 1. Setup config directory permissions
setup_config_permissions "/etc/luigi/your-module/path" || {
    log_warn "Failed to set config permissions (non-fatal)"
}

# 2. Setup log file permissions after service starts
setup_log_permissions "/var/log/luigi/your-module.log" "root" || {
    log_warn "Failed to set log permissions (non-fatal)"
}
```

### Helper Functions

#### `ensure_luigi_group()`
Creates the `luigi-api` system group if it doesn't exist.

```bash
ensure_luigi_group || exit 1
```

#### `setup_log_permissions(log_file, owner)`
Sets up permissions for a log file.

**Parameters:**
- `log_file` - Full path to log file (e.g., `/var/log/luigi/mario.log`)
- `owner` - Owner user (optional, defaults to `root`)

**Example:**
```bash
setup_log_permissions "/var/log/luigi/mario.log" "root"
```

**Result:**
- Creates log file if it doesn't exist
- Sets ownership to `owner:luigi`
- Sets permissions to `640`

#### `setup_config_permissions(config_dir)`
Sets up permissions for a config directory and all files within it.

**Parameters:**
- `config_dir` - Full path to config directory (e.g., `/etc/luigi/motion-detection/mario`)

**Example:**
```bash
setup_config_permissions "/etc/luigi/motion-detection/mario"
```

**Result:**
- Creates directory if it doesn't exist
- Sets directory to `root:luigi` with `755`
- Sets all files to `root:luigi` with `644`

## For System Administrators

### Fixing Permissions Manually

If permissions get corrupted or you need to reset them for all modules:

```bash
sudo ./util/fix-permissions.sh
```

This script:
1. Ensures the `luigi-api` group exists
2. Fixes base directory permissions (`/etc/luigi`, `/var/log/luigi`)
3. Scans and fixes all log files in `/var/log/luigi/`
4. Scans and fixes all config directories in `/etc/luigi/`
5. Processes the module registry to find and fix module-specific paths

### Checking Current Permissions

```bash
# Check log directory
ls -la /var/log/luigi/

# Check config directory
ls -la /etc/luigi/

# Check specific module
ls -la /etc/luigi/motion-detection/mario/
```

### Verifying Management API Access

```bash
# Switch to luigi-api user (requires root)
sudo -u luigi-api bash

# Try to read a log file
cat /var/log/luigi/mario.log

# Try to read a config file
cat /etc/luigi/motion-detection/mario/mario.conf

# Exit back to your user
exit
```

If the above commands fail, permissions need to be fixed.

## Troubleshooting

### Problem: Management API Can't Read Logs

**Symptoms:**
- Log viewer in web UI shows "File not found" or permission errors
- API returns 403 or 500 errors when accessing logs

**Solution:**
```bash
sudo ./util/fix-permissions.sh
sudo systemctl restart management-api
```

### Problem: Management API Can't Read Configs

**Symptoms:**
- Config editor in web UI shows "File not found" or permission errors
- Module config operations fail

**Solution:**
```bash
sudo ./util/fix-permissions.sh
sudo systemctl restart management-api
```

### Problem: luigi-api Group Doesn't Exist

**Symptoms:**
- `id luigi-api` returns "no such user"
- Permission setup fails during module installation

**Solution:**
```bash
# Create the group
sudo groupadd --system luigi-api

# Run fix-permissions to apply to all files
sudo ./util/fix-permissions.sh
```

### Problem: Permissions Reset After System Update

If system updates or manual changes reset permissions:

```bash
# Reset all permissions
sudo ./util/fix-permissions.sh

# Restart management-api to ensure it picks up changes
sudo systemctl restart management-api
```

## Security Considerations

### Why Not World-Readable?

We use group permissions instead of world-readable (`644`) for logs because:
- Logs may contain sensitive information (IP addresses, system details)
- Config files may contain API keys or credentials
- Restricting to `luigi-api` group limits exposure to only the management service

### File Ownership

- **Config files:** Owned by `root` to prevent unauthorized modification
- **Log files:** Owned by module user (often `root`) to allow writing
- **Group:** Always `luigi-api` to allow management-api to read

### Permission Model

```
Owner (module user):  Read/Write
Group (luigi-api):    Read only
Others:               No access
```

This follows the principle of least privilege.

## Examples

### Mario Motion Detection Module

```bash
# Log file
/var/log/luigi/mario.log
  Owner: root:luigi
  Permissions: 640 (rw-r-----)

# Config directory
/etc/luigi/motion-detection/mario/
  Owner: root:luigi
  Permissions: 755 (rwxr-xr-x)

# Config file
/etc/luigi/motion-detection/mario/mario.conf
  Owner: root:luigi
  Permissions: 644 (rw-r--r--)
```

### Management API Module

```bash
# Config directory
/etc/luigi/system/management-api/
  Owner: root:luigi
  Permissions: 755 (rwxr-xr-x)

# Config files
/etc/luigi/system/management-api/.env
  Owner: luigi-api:luigi-api
  Permissions: 600 (rw-------)  # More restrictive due to credentials

/etc/luigi/system/management-api/certs/
  Owner: root:luigi
  Permissions: 755 (rwxr-xr-x)
```

## Implementation Details

### Helper Functions Location
`util/setup-helpers.sh` - Functions available to all module setup scripts

### Fix Script Location
`util/fix-permissions.sh` - Standalone script for manual permission fixes

### Module Setup Integration
All module setup scripts (`<module>/setup.sh`) should call permission helpers during installation.

## References

- [Linux File Permissions Guide](https://www.linux.org/threads/file-permissions-chmod.4124/)
- [Linux Groups and Users](https://www.linux.com/training-tutorials/users-groups-and-other-linux-beasts-part-1/)
- [Principle of Least Privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege)
