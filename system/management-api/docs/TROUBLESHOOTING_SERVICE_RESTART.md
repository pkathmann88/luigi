# Troubleshooting: Service Restart Issues

## Problem: management-api service restarts continuously

If the management-api service keeps restarting automatically, this guide will help you diagnose and fix the issue.

## Diagnosis

### 1. Check service status

```bash
sudo systemctl status management-api
```

Look for:
- **Active state**: Should be "active (running)", not "restarting" or "failed"
- **Recent log messages**: Check for error messages in the output

### 2. Check service logs

```bash
# View recent logs
sudo journalctl -u management-api -n 50

# Follow logs in real-time
sudo journalctl -u management-api -f
```

## Common Causes and Solutions

### Issue 1: Missing TLS Certificates

**Symptoms:**
- Service logs show: "SSL certificate or key not found!"
- Pre-start check fails with certificate errors

**Solution:**

1. Check if certificates exist:
```bash
ls -l /etc/luigi/system/management-api/certs/server.crt
ls -l /etc/luigi/system/management-api/certs/server.key
```

2. If certificates don't exist, generate them:
```bash
cd ~/luigi/system/management-api
bash scripts/generate-certs.sh
```

3. Restart the service:
```bash
sudo systemctl restart management-api
```

**Alternative:** Disable HTTPS (not recommended for production):
```bash
sudo nano /etc/luigi/system/management-api/.env
# Change: USE_HTTPS=false
sudo systemctl restart management-api
```

### Issue 2: Certificate Permission Problems

**Symptoms:**
- Certificates exist but service still fails
- Pre-start check shows "not readable" errors

**Solution:**

Check and fix permissions:
```bash
# Make certificate readable
sudo chmod 644 /etc/luigi/system/management-api/certs/server.crt

# Make private key readable by service user group (pi)
sudo chmod 640 /etc/luigi/system/management-api/certs/server.key
sudo chown root:pi /etc/luigi/system/management-api/certs/server.key

sudo systemctl restart management-api
```

### Issue 3: Configuration Errors

**Symptoms:**
- Service logs show "Configuration errors" or "Configuration validation failed"
- Missing AUTH_USERNAME or AUTH_PASSWORD

**Solution:**

1. Check configuration file exists:
```bash
ls -l /etc/luigi/system/management-api/.env
```

2. Verify required settings are present:
```bash
grep -E "AUTH_USERNAME|AUTH_PASSWORD|USE_HTTPS" /etc/luigi/system/management-api/.env
```

3. If missing, copy from example and edit:
```bash
sudo cp ~/luigi/system/management-api/.env.example /etc/luigi/system/management-api/.env
sudo nano /etc/luigi/system/management-api/.env
# Set AUTH_USERNAME and AUTH_PASSWORD
sudo systemctl restart management-api
```

### Issue 4: Port Already in Use

**Symptoms:**
- Service logs show "EADDRINUSE" or "address already in use"
- Port 8443 (or configured port) is occupied

**Solution:**

1. Check what's using the port:
```bash
sudo lsof -i :8443
```

2. Stop the conflicting service or change the port:
```bash
sudo nano /etc/luigi/system/management-api/.env
# Change: PORT=8444  (or another available port)
sudo systemctl restart management-api
```

### Issue 5: Module Directory Not Found

**Symptoms:**
- Service logs show "Modules directory not found"
- API returns empty module list

**Solution:**

1. Verify the modules path in configuration:
```bash
grep MODULES_PATH /etc/luigi/system/management-api/.env
```

2. Check if the directory exists:
```bash
# Default path
ls -ld /home/pi/luigi
```

3. If the directory doesn't exist or is wrong, update configuration:
```bash
sudo nano /etc/luigi/system/management-api/.env
# Set: MODULES_PATH=/path/to/your/luigi/installation
sudo systemctl restart management-api
```

### Issue 6: Node.js Dependencies Missing

**Symptoms:**
- Service logs show "Cannot find module" errors
- Errors about missing npm packages

**Solution:**

Reinstall dependencies:
```bash
cd ~/luigi/system/management-api
npm install --production
sudo systemctl restart management-api
```

## Pre-Start Validation

The service now includes automatic pre-start validation that checks:
- TLS certificates exist and are readable (when USE_HTTPS=true)
- Log directory is writable
- Configuration file exists

If pre-start validation fails, check the journal logs for specific error messages:
```bash
sudo journalctl -u management-api -n 20
```

## Manual Testing

To test if the application works outside of systemd:

```bash
cd ~/luigi/system/management-api
node server.js
```

If this works but the service doesn't:
- Check systemd security settings in the service file
- Verify file permissions
- Check user/group settings in the service file

## Getting More Help

If none of these solutions work:

1. **Collect diagnostic information:**
```bash
# Service status
sudo systemctl status management-api > ~/management-api-status.txt

# Recent logs (last 100 lines)
sudo journalctl -u management-api -n 100 > ~/management-api-logs.txt

# Configuration (remove sensitive data before sharing!)
cat /etc/luigi/system/management-api/.env | grep -v "PASSWORD" > ~/management-api-config.txt

# File permissions
ls -lah ~/luigi/system/management-api > ~/management-api-permissions.txt
ls -lah ~/certs >> ~/management-api-permissions.txt
```

2. **Report the issue:**
- Include the diagnostic files above
- Describe what you've already tried
- Mention when the issue started (after installation, after update, etc.)

## Prevention

To avoid restart issues:
- Always use the setup script for installation
- Keep TLS certificates backed up
- Don't manually edit files in the installation directory
- Use the provided scripts for updates and maintenance
- Monitor service logs regularly: `sudo journalctl -u management-api -f`
