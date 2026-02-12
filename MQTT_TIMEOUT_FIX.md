# MQTT Timeout Fix - Network Ordering Issue

## Problem

The system-info service was experiencing MQTT publish timeout errors:

```
WARNING:root:MQTT publish timeout for system_cpu_temp
WARNING:root:MQTT publish timeout for system_memory_usage
WARNING:root:MQTT publish timeout for system_disk_usage
WARNING:root:MQTT publish timeout for system_cpu_usage
WARNING:root:MQTT publish timeout for system_uptime
```

**Key Observation:** Manually running `luigi-publish` as root worked perfectly, indicating that:
- ✅ Permissions were correct (root could access config)
- ✅ MQTT broker was reachable
- ✅ Configuration was valid
- ❌ Something was wrong with the **timing** of service startup

## Root Cause

The issue was **systemd network ordering**, not permissions or configuration.

### The Problem with `network.target`

Services were configured with:
```ini
[Unit]
After=network.target
```

This means:
- ✅ Network subsystem is **initialized** (drivers loaded, interfaces created)
- ❌ Network is **NOT necessarily operational**
- ❌ IP addresses may not be assigned yet
- ❌ DNS resolution may not work yet
- ❌ Default routes may not be configured yet
- ❌ Network services (like MQTT brokers) may not be reachable yet

### Why Timeouts Occurred

When the service started immediately after `network.target`:

1. **DNS Resolution Failed**
   - MQTT broker hostname (e.g., `homeassistant.local`) couldn't resolve
   - `mosquitto_pub` command hung waiting for DNS
   - Hit 5-second timeout in Python code

2. **Network Not Ready**
   - Even with IP address configured, network might not be fully operational
   - Routing tables not complete
   - MQTT broker on remote host not reachable

3. **Too Short Timeout**
   - 5-second timeout wasn't enough for network startup delays
   - Service started, tried to publish immediately, failed

## Solution

### 1. Use `network-online.target`

Changed all network-dependent services to:
```ini
[Unit]
After=network-online.target
Wants=network-online.target
```

**What this ensures:**
- ✅ Network interfaces are **up and configured**
- ✅ IP addresses are **assigned**
- ✅ DNS resolution is **working**
- ✅ Default routes are **configured**
- ✅ Network is **actually operational**

### 2. Add Startup Delay (system-info only)

Added a brief delay to give network services extra time to stabilize:
```ini
[Service]
ExecStartPre=/bin/mkdir -p /var/log/luigi
ExecStartPre=/bin/sleep 3  # Give network time to fully stabilize
```

**Why 3 seconds?**
- Gives mDNS (.local hostnames) time to resolve
- Allows MQTT broker connections to establish
- Small enough not to significantly delay startup
- Large enough to avoid race conditions

### 3. Increase Timeout Values

Changed MQTT publish timeout from 5 to 10 seconds:
```python
result = subprocess.run(
    cmd,
    capture_output=True,
    timeout=10,  # Increased from 5 seconds
    check=True
)
```

**Why increase timeout?**
- More forgiving during network startup conditions
- Allows for DNS resolution delays
- Accommodates slow MQTT broker responses
- Reduces false positives during startup

## Services Updated

### 1. system-info.service
- ✅ Changed to `network-online.target`
- ✅ Added 3-second startup delay
- ✅ Increased Python timeout to 10 seconds
- **Purpose:** System metrics publishing to MQTT

### 2. mario.service
- ✅ Changed to `network-online.target`
- ✅ Increased Python timeout to 10 seconds
- **Purpose:** Motion detection notifications to MQTT

### 3. management-api.service
- ✅ Changed to `network-online.target`
- **Purpose:** Web server (needs network to serve requests)

## Understanding systemd Network Targets

### network.target (Old - Too Early)
```
Boot Sequence:
1. Kernel loads network drivers
2. Network interfaces created
3. systemd marks network.target as reached  ← Service starts here
4. NetworkManager/systemd-networkd configure interfaces
5. IP addresses assigned via DHCP
6. DNS resolvers configured
7. Routes established
8. Network actually works
```

**Problem:** Service starts at step 3, but network isn't usable until step 8.

### network-online.target (New - Correct)
```
Boot Sequence:
1. Kernel loads network drivers
2. Network interfaces created
3. systemd marks network.target as reached
4. NetworkManager/systemd-networkd configure interfaces
5. IP addresses assigned via DHCP
6. DNS resolvers configured
7. Routes established
8. systemd marks network-online.target as reached  ← Service starts here
```

**Solution:** Service waits until network is actually working.

## Technical Details

### How network-online.target Works

The `network-online.target` requires a "network online" service to be active:
- On systems with NetworkManager: `NetworkManager-wait-online.service`
- On systems with systemd-networkd: `systemd-networkd-wait-online.service`

These services don't complete until:
- At least one network interface is up
- IP address is assigned
- Default route exists
- DNS is configured

### The Role of `Wants=`

```ini
Wants=network-online.target
```

This line ensures that:
- systemd **activates** the network-online.target
- If network-online.target fails, service still starts (non-fatal dependency)
- Service startup is delayed until network is ready

Without `Wants=`, the `After=` alone wouldn't ensure network-online.target is reached.

## Testing

### Verify the Fix

**1. Check service configuration:**
```bash
systemctl cat system-info.service | grep -A2 "\[Unit\]"
# Should show: After=network-online.target
#              Wants=network-online.target
```

**2. Monitor service startup:**
```bash
# Watch service logs in real-time
sudo journalctl -u system-info -f

# Restart service
sudo systemctl restart system-info
```

**3. Verify no timeout errors:**
```bash
# Check recent logs for timeout warnings
sudo journalctl -u system-info -n 50 | grep -i timeout
# Should return nothing (no timeout errors)
```

**4. Confirm MQTT publishing:**
```bash
# Look for successful metric collection
sudo journalctl -u system-info -n 50 | grep "Metrics:"
# Should show: "Metrics: 5 collected, 5 published"
```

### Expected Behavior

**Startup sequence:**
1. System boots
2. Network subsystem initializes (network.target)
3. Network configuration completes (DHCP, DNS)
4. network-online.target reached
5. system-info service starts (after 3-second delay)
6. First MQTT publish attempt (with 10-second timeout)
7. ✅ Success - no timeout errors

## Common Issues and Solutions

### Issue: Service Still Times Out

**Diagnosis:**
```bash
# Check if network-online.target is reached
systemctl status network-online.target

# Check which network manager is running
systemctl status NetworkManager
systemctl status systemd-networkd
```

**Solution:**
Ensure the network manager's wait-online service is enabled:
```bash
# For NetworkManager
sudo systemctl enable NetworkManager-wait-online.service

# For systemd-networkd
sudo systemctl enable systemd-networkd-wait-online.service
```

### Issue: Service Takes Too Long to Start

**Diagnosis:**
```bash
# Check service startup time
systemd-analyze blame | grep system-info
```

**Solution:**
The 3-second delay is intentional. If it's too long for your use case:
- Reduce the sleep time in ExecStartPre
- Or remove it if your network is very fast

### Issue: MQTT Broker Not Reachable

**Diagnosis:**
```bash
# Test MQTT connectivity manually
mosquitto_pub -h homeassistant.local -p 1883 -t test/topic -m "test"
```

**Solution:**
- Verify MQTT broker is running and reachable
- Check firewall rules
- Verify DNS resolution for broker hostname

## When to Use network-online.target

**Use network-online.target when your service needs:**
- ✅ DNS resolution to work (hostnames)
- ✅ Network connectivity to remote services
- ✅ Outbound connections to the internet
- ✅ Services that use network protocols (MQTT, HTTP, etc.)

**Don't use it for:**
- ❌ Services that don't use the network
- ❌ Services that only listen on localhost
- ❌ Services that can gracefully handle network unavailability

## Best Practices

1. **Always use network-online.target for network services**
   ```ini
   After=network-online.target
   Wants=network-online.target
   ```

2. **Add startup delays for critical timing**
   ```ini
   ExecStartPre=/bin/sleep 3
   ```

3. **Use generous timeouts during startup**
   ```python
   timeout=10  # Not 5 seconds
   ```

4. **Log network issues clearly**
   ```python
   logging.warning(f"MQTT publish timeout for {sensor_id}")
   ```

5. **Test service startup thoroughly**
   ```bash
   sudo systemctl restart service
   sudo journalctl -u service -f
   ```

## Summary

The MQTT timeout issue was caused by services starting before the network was fully operational. By switching to `network-online.target`, adding a startup delay, and increasing timeout values, services now wait for the network to be ready before attempting MQTT connections.

**Result:** ✅ No more timeout errors, reliable MQTT publishing from service startup.
