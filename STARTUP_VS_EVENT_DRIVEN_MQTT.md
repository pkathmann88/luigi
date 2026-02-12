# System-Info vs Mario: MQTT Publishing Pattern Difference

## Problem Discovery

**Observation:** Mario module's MQTT publishing works perfectly, but system-info fails with timeout errors.

## Root Cause Analysis

### Publishing Patterns

**system-info.py (Immediate Publishing):**
```python
def run(self):
    # Publish metrics IMMEDIATELY on startup
    self.collect_and_publish_metrics()  # ← Happens right away
    
    # Then enter main loop
    while self.running:
        # Publish periodically
        if self.should_publish():
            self.collect_and_publish_metrics()
```

**mario.py (Event-Driven Publishing):**
```python
def motion_detected(channel):
    # Only publishes WHEN motion is detected
    publish_sensor_value('mario_motion', 'ON', is_binary=True)
    
# Service starts → Waits for motion → Then publishes
# By this time, system has been running for a while
```

### Why This Matters

**Timing Diagram:**
```
Boot Sequence:
0s:   System boot
2s:   Kernel loads
5s:   Network drivers initialize
8s:   network.target reached
10s:  DHCP obtains IP address
12s:  DNS resolvers configured
15s:  network-online.target reached
      ↓
16s:  system-info service starts
17s:  system-info IMMEDIATELY tries to publish  ← FAILS! MQTT not ready
      ↓
30s:  MQTT broker connection finally ready
45s:  Motion detected → mario publishes  ← WORKS! Network stable now
```

**Key Insight:**
- Even with `network-online.target`, MQTT broker connections take time to establish
- system-info starts and publishes too quickly (within 1-2 seconds of network-online)
- mario waits for real-world events, giving network plenty of time to stabilize

## Solution: Retry Logic with Exponential Backoff

### Implementation

```python
def run(self):
    """Main application loop with retry logic for initial publish."""
    max_retries = 5
    retry_delay = 5  # Start with 5 seconds
    
    for attempt in range(1, max_retries + 1):
        published_count = self.collect_and_publish_metrics()
        
        if published_count > 0:
            # Success! At least one metric published
            logging.info("Initial metrics published successfully")
            break
        else:
            # Network not ready, retry with backoff
            if attempt < max_retries:
                logging.warning(f"Retrying in {retry_delay} seconds...")
                time.sleep(retry_delay)
                retry_delay = min(retry_delay * 2, 60)  # Exponential backoff
            else:
                logging.warning("All retries exhausted, continuing...")
    
    # Continue with main loop regardless of initial publish result
    while self.running:
        # ... normal operation ...
```

### Retry Sequence

**Scenario: MQTT broker takes 20 seconds to be ready**

```
Time  | Attempt | Action                           | Result
------|---------|----------------------------------|--------
0s    | 1       | Try publish                      | Timeout
5s    | 2       | Try publish (after 5s wait)     | Timeout
15s   | 3       | Try publish (after 10s wait)    | Timeout
35s   | 4       | Try publish (after 20s wait)    | Success! ✓
```

**Scenario: MQTT broker is immediately ready**

```
Time  | Attempt | Action                           | Result
------|---------|----------------------------------|--------
0s    | 1       | Try publish                      | Success! ✓
```

## Why Exponential Backoff?

### Linear Backoff (Fixed Delays)
```
Retry 1: Wait 5s
Retry 2: Wait 5s
Retry 3: Wait 5s
Retry 4: Wait 5s
Total: 20 seconds of waiting
```
❌ Too aggressive if network is slow
✅ Fast if network is quick

### Exponential Backoff (Increasing Delays)
```
Retry 1: Wait 5s
Retry 2: Wait 10s
Retry 3: Wait 20s
Retry 4: Wait 40s
Total: 75 seconds of waiting
```
✅ Adapts to slow networks
✅ Doesn't hammer the network with rapid retries
✅ Gives MQTT broker time to become available

## Code Changes

### 1. Return Value Added

**Before:**
```python
def collect_and_publish_metrics(self):
    """Collect and publish metrics."""
    # ... publish metrics ...
    # No return value
```

**After:**
```python
def collect_and_publish_metrics(self):
    """
    Collect and publish metrics.
    
    Returns:
        int: Number of metrics successfully published
    """
    # ... publish metrics ...
    return metrics_published  # Track success
```

### 2. Retry Logic in run()

**Before:**
```python
def run(self):
    # Publish immediately (one shot, no retry)
    try:
        self.collect_and_publish_metrics()
    except Exception as e:
        logging.error(f"Error: {e}")
    
    # Main loop
    while self.running:
        # ...
```

**After:**
```python
def run(self):
    # Publish with retry and exponential backoff
    max_retries = 5
    retry_delay = 5
    
    for attempt in range(1, max_retries + 1):
        try:
            published_count = self.collect_and_publish_metrics()
            if published_count > 0:
                break  # Success!
            else:
                # Retry with backoff
                time.sleep(retry_delay)
                retry_delay = min(retry_delay * 2, 60)
        except Exception as e:
            logging.error(f"Attempt {attempt} failed: {e}")
            time.sleep(retry_delay)
            retry_delay = min(retry_delay * 2, 60)
    
    # Main loop (continues even if initial publish failed)
    while self.running:
        # ...
```

### 3. Service File Simplified

**Before:**
```ini
[Service]
ExecStartPre=/bin/mkdir -p /var/log/luigi
ExecStartPre=/bin/sleep 3  # Fixed 3-second delay
ExecStart=/usr/bin/python3 /usr/local/bin/system-info.py
```

**After:**
```ini
[Service]
ExecStartPre=/bin/mkdir -p /var/log/luigi
# No sleep - retry logic in Python handles timing
ExecStart=/usr/bin/python3 /usr/local/bin/system-info.py
```

## Benefits of This Approach

### 1. Self-Adapting
- Fast networks: Succeeds on first attempt, no delay
- Slow networks: Retries until successful
- Variable networks: Adapts to actual conditions

### 2. Robust
- Doesn't fail permanently if MQTT not ready
- Continues with main loop even after retries exhausted
- Will retry on next publish interval (5 minutes)

### 3. Observable
- Clear logging of each retry attempt
- Easy to diagnose network issues
- Shows actual timing of MQTT availability

### 4. Configurable
- Easy to adjust max_retries (5 attempts)
- Easy to adjust initial delay (5 seconds)
- Easy to adjust max delay (60 seconds)

## Comparison

| Aspect | System-Info (Before) | System-Info (After) | Mario |
|--------|---------------------|---------------------|-------|
| **Publish Timing** | Immediate | Immediate with retry | Event-driven |
| **Network Wait** | 3s fixed delay | 5-60s adaptive | Natural delay |
| **Retry Logic** | ❌ None | ✅ 5 attempts | N/A |
| **Result** | ❌ Fails often | ✅ Reliable | ✅ Always worked |

## Lessons Learned

### For Future Luigi Modules

**If your module publishes at startup:**
- ✅ Implement retry logic with exponential backoff
- ✅ Return success/failure counts from publish functions
- ✅ Log retry attempts clearly
- ✅ Continue operation even if initial publish fails

**If your module publishes on events:**
- ✅ Event-driven publishing naturally avoids this issue
- ✅ By event time, network is stable
- ⚠️ Still use timeouts and error handling

**Best Practice:**
```python
def publish_with_retry(sensor_id, value, max_retries=3):
    """Publish with retry logic for reliability."""
    for attempt in range(1, max_retries + 1):
        try:
            if publish_sensor_value(sensor_id, value):
                return True  # Success
            else:
                if attempt < max_retries:
                    time.sleep(2 ** attempt)  # Exponential: 2, 4, 8 seconds
        except Exception as e:
            logging.warning(f"Publish attempt {attempt} failed: {e}")
            if attempt < max_retries:
                time.sleep(2 ** attempt)
    
    return False  # All retries failed
```

## Testing

### Verify the Fix

**1. Monitor startup behavior:**
```bash
sudo systemctl restart system-info
sudo journalctl -u system-info -f
```

**Expected output:**
```
INFO: System Info Monitor starting...
INFO: Initial metrics publish attempt 1/5...
INFO: Collecting system metrics...
[If network not ready]
WARNING: No metrics published, retrying in 5 seconds...
INFO: Initial metrics publish attempt 2/5...
[Eventually]
INFO: Initial metrics published successfully (5 metrics)
INFO: Entering main loop...
```

**2. Simulate slow network:**
```bash
# Temporarily delay MQTT broker startup
sudo systemctl stop mosquitto
sudo systemctl start system-info
# Watch logs - should see retry attempts
sleep 30
sudo systemctl start mosquitto
# Should see success after broker starts
```

**3. Compare with mario:**
```bash
# Mario doesn't need retries - it's event-driven
sudo systemctl restart mario
# Trigger motion
# Check logs - should publish immediately when motion detected
```

## Summary

The key difference between mario and system-info is **when they publish**:

- **system-info**: Immediate at startup → needs retry logic
- **mario**: On motion detection → natural delay makes it work

The solution is retry logic with exponential backoff, which:
- Adapts to actual network timing
- Doesn't give up too quickly
- Continues operation even if MQTT unavailable
- Provides clear visibility into startup behavior

This pattern should be used for any Luigi module that publishes data immediately at startup.
