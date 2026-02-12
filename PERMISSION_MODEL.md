# Luigi Group-Based Permission Model

## Overview

Luigi implements a **group-based permission model** for secure shared access to sensitive resources like MQTT credentials. This document explains the architecture and usage.

## The luigi System Group

### Purpose
The `luigi` system group enables:
- Secure sharing of MQTT credentials across modules
- Non-root service operation while maintaining security
- Controlled access to sensitive configuration files
- Multiple services accessing shared resources safely

### Creation
The `luigi` group is created **automatically** by the root `setup.sh` during installation:

```bash
# In setup.sh
create_luigi_group() {
    groupadd --system luigi
    usermod -a -G luigi "$SUDO_USER"  # Add installer to group
}
```

**Important:** The group is created ONCE in the root setup.sh, not in individual module setup scripts. This ensures consistency across all modules.

## Permission Model

### MQTT Configuration File

**File:** `/etc/luigi/iot/ha-mqtt/ha-mqtt.conf`

**Permissions:**
```bash
Owner: root (read/write)
Group: luigi (read-only)
Others: no access
Mode: 640 (rw-r-----)
```

**Applied by:** `iot/ha-mqtt/setup.sh` during installation/upgrade

### Why This Model?

**Security Benefits:**
- ✅ More secure than `600` (only root) or `644` (world-readable)
- ✅ Credentials not accessible to arbitrary users
- ✅ Follows Linux security best practices (principle of least privilege)
- ✅ Audit trail via group membership

**Operational Benefits:**
- ✅ Services can run as non-root users (when properly configured)
- ✅ Multiple modules can share MQTT credentials
- ✅ Easy to add new services (just add to group)
- ✅ No need for credential duplication

## Service Access Patterns

### Pattern 1: Root Services (Current Default)

Services running as root can always read group-readable files.

**Example:** `system-info.service`
```ini
[Service]
User=root  # Can read root:luigi 640 files
```

**Use Cases:**
- Services requiring GPIO access (RPi.GPIO needs root)
- Services needing hardware access
- Simplest configuration (no user management needed)

**Pros:**
- Always works, no permission issues
- No group membership management needed

**Cons:**
- Runs with elevated privileges
- Less secure than dedicated service user

### Pattern 2: Luigi Group Members (Recommended for New Services)

Non-root services can access MQTT config by being in the luigi group.

**Example:** Future sensor service
```ini
[Service]
User=sensorbot
Group=luigi  # OR supplementary group via usermod
```

**Setup:**
```bash
# Create dedicated service user
useradd --system --no-create-home --shell /usr/sbin/nologin sensorbot

# Add to luigi group
usermod -a -G luigi sensorbot
```

**Pros:**
- More secure (principle of least privilege)
- Service runs with minimal permissions
- Can be restricted further with systemd directives

**Cons:**
- Requires user/group management
- User must be in luigi group

### Pattern 3: Mixed Approach

Service runs as dedicated user but with group access:

```ini
[Service]
User=luigiservice
# Automatically gets group access if user is in luigi group
```

## Usage Guide

### For Module Developers

When creating a new module that needs MQTT access:

**1. DO NOT create the luigi group in your module**
The root `setup.sh` creates it automatically.

**2. Use group-readable permissions**
```bash
# In your module's setup.sh
chown root:luigi /etc/luigi/your-module/sensitive.conf
chmod 640 /etc/luigi/your-module/sensitive.conf
```

**3. Document group requirements**
In your module's README:
```markdown
## MQTT Integration
This module uses luigi-publish for MQTT. If running as non-root:
- Add service user to luigi group: `sudo usermod -a -G luigi username`
- User must log out and back in for group membership to take effect
```

**4. Service file options**
Choose based on your needs:
```ini
# Option A: Run as root (simple, works for GPIO)
[Service]
User=root

# Option B: Run as dedicated user (more secure)
[Service]
User=myservice
# Add myservice to luigi group during installation
```

### For System Administrators

**Add a user to the luigi group:**
```bash
sudo usermod -a -G luigi username
```

**Verify group membership:**
```bash
groups username
# Should show: ... luigi ...
```

**Important:** Users must log out and back in for new group membership to take effect.

**Check if service can access MQTT config:**
```bash
# As the service user
sudo -u serviceuser head -1 /etc/luigi/iot/ha-mqtt/ha-mqtt.conf
# Should show config file contents (not permission denied)
```

### For Troubleshooting

**Problem:** Service can't access MQTT config

**Check 1:** Verify luigi group exists
```bash
getent group luigi
# Should show: luigi:x:GID:members
```

**Check 2:** Verify config permissions
```bash
ls -l /etc/luigi/iot/ha-mqtt/ha-mqtt.conf
# Should show: -rw-r----- 1 root luigi ...
```

**Check 3:** Verify service user is in luigi group
```bash
# Check service file
systemctl cat myservice | grep User=
# Then check that user's groups
groups service_username
```

**Check 4:** User logged in after being added to group?
```bash
# Current session groups
groups
# All groups (including new ones after re-login)
id
```

## Migration Guide

### Upgrading from Old Permission Model

If you have an existing installation with `600` (root-only) permissions:

**Option 1: Automatic (recommended)**
```bash
# Re-run ha-mqtt setup
cd iot/ha-mqtt
sudo ./setup.sh install
# Automatically updates to root:luigi 640
```

**Option 2: Manual**
```bash
# Create luigi group if needed
sudo groupadd --system luigi

# Update permissions
sudo chown root:luigi /etc/luigi/iot/ha-mqtt/ha-mqtt.conf
sudo chmod 640 /etc/luigi/iot/ha-mqtt/ha-mqtt.conf

# Add service users to group
sudo usermod -a -G luigi pi  # or other service user
```

## Security Considerations

### What the Model Protects Against
- ✅ Unauthorized access to MQTT credentials
- ✅ Credential leakage to arbitrary users
- ✅ Accidental world-readable config files

### What the Model Does NOT Protect Against
- ❌ Root compromise (root can always read any file)
- ❌ Physical access attacks
- ❌ Kernel vulnerabilities

### Additional Security Measures
For production deployments, consider:
- TLS encryption for MQTT (configured in ha-mqtt.conf)
- Strong MQTT broker authentication
- Network isolation (firewall rules)
- Regular security updates
- Audit logging of MQTT access

## Testing

### Automated Test
Use the included test script:
```bash
sudo /tmp/test-mqtt-permissions.sh
```

### Manual Test
```bash
# 1. Verify group exists
getent group luigi

# 2. Check config permissions
stat /etc/luigi/iot/ha-mqtt/ha-mqtt.conf

# 3. Test as root (should work)
sudo head -1 /etc/luigi/iot/ha-mqtt/ha-mqtt.conf

# 4. Test as luigi group member (should work)
sudo -u member_user head -1 /etc/luigi/iot/ha-mqtt/ha-mqtt.conf

# 5. Test as non-member (should fail with Permission denied)
sudo -u other_user head -1 /etc/luigi/iot/ha-mqtt/ha-mqtt.conf
```

## References

- Linux group management: `man groupadd`, `man usermod`
- File permissions: `man chmod`, `man chown`
- Systemd user/group: `man systemd.exec` (User=, Group= directives)
- Security best practices: Principle of least privilege

## Summary

The luigi group-based permission model provides:
- **Security** through controlled access
- **Flexibility** for both root and non-root services  
- **Scalability** across multiple modules
- **Simplicity** via automatic setup

All Luigi modules should leverage this pattern for shared resource access.
