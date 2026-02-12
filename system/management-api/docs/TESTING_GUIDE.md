# Testing Guide for Service Restart Fix

## Quick Verification Steps

After installing the updated management-api, follow these steps to verify the fix works:

### 1. Check Service is Running
```bash
sudo systemctl status management-api
```

**Expected Output:**
- Status should be "active (running)"
- Should NOT show "restarting" or continuous restart attempts

### 2. View Startup Logs
```bash
sudo journalctl -u management-api -n 100
```

**What to Look For:**
- Configuration loading section with clear values
- Module loading confirmations
- TLS certificate checks (✓ success indicators)
- Server startup completion message
- "Server is ready to accept connections"

**Example of Healthy Startup:**
```
==========================================
Luigi Management API - Configuration Loading
==========================================
Loading configuration from: /etc/luigi/system/management-api/.env
Node Environment: production
Port: 8443
Host: 0.0.0.0
HTTPS Enabled: true
...
✓ Configuration validation passed
==========================================
...
✓ Certificate file found: /home/pi/certs/server.crt
✓ Key file found: /home/pi/certs/server.key
...
✓ Server started successfully!
```

### 3. Test API Access
```bash
# Check health endpoint (replace with your actual hostname/IP)
curl -k https://localhost:8443/health

# Should return: {"status":"ok","timestamp":"..."}
```

### 4. Verify No Restart Loops
```bash
# Watch the service for 1 minute
watch -n 5 'sudo systemctl status management-api'
```

**Expected:** Service stays "active (running)" without restarting

## Detailed Test Scenarios

### Scenario A: Fresh Installation on Non-Standard Path

**Purpose:** Verify dynamic path detection works

**Steps:**
1. Clone repository to custom location:
   ```bash
   mkdir -p /opt/luigi-test
   cd /opt/luigi-test
   git clone <repo-url> .
   cd system/management-api
   ```

2. Install:
   ```bash
   sudo ./setup.sh install
   ```

3. Check service file paths:
   ```bash
   sudo cat /etc/systemd/system/management-api.service | grep ExecStart
   ```

4. Verify paths match `/opt/luigi-test/system/management-api/...`

**Expected Result:** Service starts successfully with correct paths

### Scenario B: Missing Certificates

**Purpose:** Verify pre-start validation prevents restart loops

**Steps:**
1. Stop service and remove certificates:
   ```bash
   sudo systemctl stop management-api
   rm -f ~/certs/server.crt ~/certs/server.key
   ```

2. Try to start service:
   ```bash
   sudo systemctl start management-api
   ```

3. Check logs:
   ```bash
   sudo journalctl -u management-api -n 30
   ```

**Expected Result:**
- Pre-start check fails with clear error message
- Shows missing certificate path
- Provides solution: "Run: bash scripts/generate-certs.sh"
- Service does NOT enter restart loop

4. Generate certificates and restart:
   ```bash
   cd ~/luigi/system/management-api
   bash scripts/generate-certs.sh
   sudo systemctl start management-api
   ```

**Expected Result:** Service starts successfully

### Scenario C: HTTPS Disabled

**Purpose:** Verify service works without TLS

**Steps:**
1. Edit configuration:
   ```bash
   sudo nano /etc/luigi/system/management-api/.env
   # Change: USE_HTTPS=false
   ```

2. Restart service:
   ```bash
   sudo systemctl restart management-api
   ```

3. Check logs:
   ```bash
   sudo journalctl -u management-api -n 30
   ```

**Expected Result:**
- Pre-start check shows "HTTPS disabled"
- Server starts in HTTP mode
- Warning shown: "⚠ WARNING: HTTPS is disabled!"
- Service runs on http://localhost:8443

### Scenario D: Configuration Errors

**Purpose:** Verify early error detection

**Steps:**
1. Break configuration:
   ```bash
   sudo nano /etc/luigi/system/management-api/.env
   # Remove AUTH_USERNAME line
   ```

2. Try to restart:
   ```bash
   sudo systemctl restart management-api
   ```

3. Check logs:
   ```bash
   sudo journalctl -u management-api -n 30
   ```

**Expected Result:**
- Configuration validation fails
- Clear error: "AUTH_USERNAME is required"
- Service does not start
- No restart loop

4. Fix configuration and restart:
   ```bash
   sudo nano /etc/luigi/system/management-api/.env
   # Add back: AUTH_USERNAME=admin
   sudo systemctl restart management-api
   ```

**Expected Result:** Service starts successfully

### Scenario E: Startup Performance

**Purpose:** Verify startup time is reasonable

**Steps:**
1. Restart service and measure time:
   ```bash
   sudo systemctl restart management-api
   sleep 2
   sudo systemctl status management-api
   ```

2. Check startup duration in logs:
   ```bash
   sudo journalctl -u management-api --since "1 minute ago" | grep "started successfully"
   ```

**Expected Result:**
- Service starts within 2-3 seconds
- All startup phases complete quickly
- No delays or timeouts

## Common Issues and Verification

### Issue: Service Still Restarting

**Check:**
```bash
# View last 50 log lines
sudo journalctl -u management-api -n 50

# Look for:
# - Configuration errors
# - Certificate errors
# - Permission errors
# - Port conflicts
```

**Verification:** Error message should be clear with solution

### Issue: Can't Access API

**Check:**
```bash
# Verify service is listening
sudo netstat -tlnp | grep 8443

# Check firewall
sudo ufw status

# Test local connection
curl -k https://localhost:8443/health
```

**Verification:** Should get JSON response: `{"status":"ok"}`

### Issue: Certificates Not Generated

**Check:**
```bash
# Verify certificate script exists
ls -l ~/luigi/system/management-api/scripts/generate-certs.sh

# Run manually
cd ~/luigi/system/management-api
bash scripts/generate-certs.sh

# Check certificates created
ls -l ~/certs/
```

**Verification:** Should see server.crt and server.key

## Success Criteria

The fix is successful if:

- ✅ Service starts without restart loops
- ✅ Startup logs show detailed progress
- ✅ Clear error messages when configuration is wrong
- ✅ Pre-start validation catches issues early
- ✅ Service works in non-standard installation paths
- ✅ Works with both HTTPS enabled and disabled
- ✅ API responds correctly after startup
- ✅ Service remains stable over time

## Monitoring After Fix

Set up ongoing monitoring:

```bash
# Create simple monitoring script
cat > ~/check-management-api.sh << 'EOF'
#!/bin/bash
if systemctl is-active --quiet management-api; then
    echo "✓ Service is running"
    curl -k -s https://localhost:8443/health | jq .
else
    echo "✗ Service is not running!"
    sudo journalctl -u management-api -n 20
fi
EOF
chmod +x ~/check-management-api.sh

# Run periodically
watch -n 30 ~/check-management-api.sh
```

## Reporting Results

If you encounter any issues, collect this information:

```bash
# Create diagnostic bundle
mkdir -p ~/management-api-diagnostics
cd ~/management-api-diagnostics

# Service status
sudo systemctl status management-api > service-status.txt

# Recent logs (last 200 lines)
sudo journalctl -u management-api -n 200 > service-logs.txt

# Service file
sudo cat /etc/systemd/system/management-api.service > service-file.txt

# Configuration (remove sensitive data!)
sudo cat /etc/luigi/system/management-api/.env | grep -v PASSWORD > config.txt

# Certificate check
ls -lah ~/certs/ > certificates.txt

# Installation directory
ls -lah ~/luigi/system/management-api/ > installation-dir.txt

# Compress and share
tar -czf management-api-diagnostics.tar.gz *.txt
echo "Diagnostic bundle created: ~/management-api-diagnostics/management-api-diagnostics.tar.gz"
```

Share the diagnostic bundle when reporting issues.
