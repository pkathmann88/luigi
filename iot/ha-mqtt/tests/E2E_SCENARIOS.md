# End-to-End Scenario Tests for iot/ha-mqtt

**Part of Phase 1: Testing Strategy Implementation (Phase 1.4)**

This document describes the end-to-end testing scenarios for the iot/ha-mqtt module. These scenarios validate the complete integration workflow from module deployment to Home Assistant integration.

## Prerequisites

- MQTT broker running and accessible
- Home Assistant instance with MQTT integration configured
- ha-mqtt module fully installed (`sudo ./setup.sh install`)
- ha-mqtt.conf configured with valid broker credentials

## Test Environment Setup

1. **MQTT Broker:** Mosquitto or equivalent MQTT broker
2. **Home Assistant:** Any recent version with MQTT integration
3. **Luigi System:** Complete Luigi installation with ha-mqtt module
4. **Test Descriptors:** Available in `examples/sensors.d/`

---

## Scenario 1: New Module Integration

**Goal:** Validate that a new Luigi module can integrate with Home Assistant without modifying ha-mqtt code.

### Steps

1. **Create Test Sensor Descriptor**
   ```bash
   # Create a descriptor for a test temperature sensor
   sudo nano /etc/luigi/iot/ha-mqtt/sensors.d/test_temp_sensor.json
   ```
   
   Content:
   ```json
   {
     "sensor_id": "test_temp_sensor",
     "name": "Test Temperature Sensor",
     "device_class": "temperature",
     "unit_of_measurement": "°C",
     "icon": "mdi:thermometer",
     "state_class": "measurement",
     "module": "test-module"
   }
   ```

2. **Run luigi-discover**
   ```bash
   sudo luigi-discover
   ```
   
   **Expected Output:**
   - Scanning /etc/luigi/iot/ha-mqtt/sensors.d/
   - Found 1 sensor descriptor(s)
   - Registering test_temp_sensor... OK
   - Summary: 1 sensor(s) registered, 0 failed

3. **Publish Test Value**
   ```bash
   luigi-publish --sensor test_temp_sensor --value 23.5
   ```
   
   **Expected Output:**
   - Publishing to topic: homeassistant/sensor/luigi-raspberrypi/test_temp_sensor/state
   - Value: 23.5
   - Published successfully

4. **Verify in Home Assistant**
   - Navigate to Developer Tools > States
   - Search for "test_temp_sensor"
   - Verify entity exists: `sensor.test_temp_sensor`
   - Verify current value: 23.5
   - Verify attributes: unit_of_measurement, device_class, icon

### Success Criteria

- ✓ Descriptor file accepted without errors
- ✓ Discovery message published successfully
- ✓ Sensor appears in Home Assistant
- ✓ Published value appears in Home Assistant
- ✓ All sensor metadata correct (name, unit, device_class, icon)
- ✓ No changes required to ha-mqtt code

### Cleanup

```bash
sudo rm /etc/luigi/iot/ha-mqtt/sensors.d/test_temp_sensor.json
```

---

## Scenario 2: Module Update

**Goal:** Validate that updating a sensor descriptor correctly updates the sensor in Home Assistant.

### Steps

1. **Use Existing Test Sensor** (from Scenario 1)
   
   Initial descriptor:
   ```json
   {
     "sensor_id": "test_temp_sensor",
     "name": "Test Temperature Sensor",
     "device_class": "temperature",
     "unit_of_measurement": "°C",
     "icon": "mdi:thermometer",
     "state_class": "measurement",
     "module": "test-module"
   }
   ```

2. **Modify Descriptor**
   ```bash
   sudo nano /etc/luigi/iot/ha-mqtt/sensors.d/test_temp_sensor.json
   ```
   
   Change name and icon:
   ```json
   {
     "sensor_id": "test_temp_sensor",
     "name": "Updated Temperature Sensor",
     "device_class": "temperature",
     "unit_of_measurement": "°C",
     "icon": "mdi:temperature-celsius",
     "state_class": "measurement",
     "module": "test-module"
   }
   ```

3. **Re-run Discovery**
   ```bash
   sudo luigi-discover --force
   ```
   
   **Expected Output:**
   - Scanning /etc/luigi/iot/ha-mqtt/sensors.d/
   - Found 1 sensor descriptor(s)
   - Re-registering test_temp_sensor... OK
   - Summary: 1 sensor(s) registered, 0 failed

4. **Verify Changes in Home Assistant**
   - Navigate to Developer Tools > States
   - Search for "test_temp_sensor"
   - Verify entity: `sensor.test_temp_sensor`
   - Verify updated name: "Updated Temperature Sensor"
   - Verify updated icon: mdi:temperature-celsius

### Success Criteria

- ✓ Descriptor modification accepted
- ✓ Re-discovery successful with --force flag
- ✓ Updated metadata reflected in Home Assistant
- ✓ Sensor ID remains the same (no duplicate entities)
- ✓ Historical data preserved

### Cleanup

```bash
sudo rm /etc/luigi/iot/ha-mqtt/sensors.d/test_temp_sensor.json
```

---

## Scenario 3: Module Removal

**Goal:** Validate the process for removing a sensor from the Luigi system and understand Home Assistant cleanup requirements.

### Steps

1. **Start with Active Sensor** (from previous scenarios)
   - Sensor registered in ha-mqtt
   - Sensor visible in Home Assistant

2. **Remove Descriptor File**
   ```bash
   sudo rm /etc/luigi/iot/ha-mqtt/sensors.d/test_temp_sensor.json
   ```

3. **Verify Descriptor Removed**
   ```bash
   sudo luigi-discover
   ```
   
   **Expected Output:**
   - Scanning /etc/luigi/iot/ha-mqtt/sensors.d/
   - Found 0 sensor descriptor(s)
   - No sensors to register

4. **Check Home Assistant**
   - Navigate to Developer Tools > States
   - Search for "test_temp_sensor"
   - **Note:** Sensor entity still exists in Home Assistant
   - Sensor becomes "unavailable" (no new data published)

5. **Manual Home Assistant Cleanup** (Required)
   ```bash
   # Option 1: Use Home Assistant UI
   # - Go to Configuration > Entities
   # - Search for test_temp_sensor
   # - Select entity and click "Delete"
   
   # Option 2: Restart Home Assistant
   # - Configuration > Server Controls > Restart
   # - Stale MQTT entities will be removed after restart
   ```

### Success Criteria

- ✓ Descriptor file removed successfully
- ✓ luigi-discover no longer finds the sensor
- ✓ No errors during discovery scan
- ✓ Sensor becomes unavailable in Home Assistant
- ✓ Manual cleanup documented and understood
- ✓ No orphaned topics on MQTT broker

### Important Notes

- **Manual Cleanup Required:** Home Assistant MQTT Discovery does not automatically remove entities when discovery messages stop. Manual removal is required.
- **Retained Messages:** Discovery messages are retained on the broker. Consider publishing empty retained message to clean up:
  ```bash
  mosquitto_pub -h BROKER -t "homeassistant/sensor/luigi-raspberrypi/test_temp_sensor/config" -r -n
  ```
- **Documentation:** This behavior should be clearly documented in the module README under "Removing Sensors" section.

---

## Additional Test Scenarios (Optional)

### Scenario 4: Multiple Sensor Types

Test registration of different sensor types (binary_sensor, sensor, etc.) to validate generic interface.

### Scenario 5: Concurrent Publishing

Test multiple modules publishing simultaneously to validate no conflicts or race conditions.

### Scenario 6: Network Interruption Recovery

Test sensor re-registration and data publishing after network outage.

### Scenario 7: Broker Restart Resilience

Test system behavior when MQTT broker restarts (retained discovery messages should enable auto-recovery).

---

## Test Execution Checklist

Use this checklist when running end-to-end scenario tests:

### Pre-Test Setup
- [ ] MQTT broker running and accessible
- [ ] Home Assistant running with MQTT integration
- [ ] ha-mqtt.conf configured correctly
- [ ] Test environment clean (no leftover test sensors)

### Scenario 1: New Module Integration
- [ ] Test descriptor created
- [ ] luigi-discover runs successfully
- [ ] Discovery message visible in MQTT broker logs
- [ ] Sensor appears in Home Assistant
- [ ] Publishing works with luigi-publish
- [ ] Values appear correctly in Home Assistant
- [ ] Metadata correct (name, unit, class, icon)
- [ ] Cleanup completed

### Scenario 2: Module Update
- [ ] Initial descriptor deployed
- [ ] Descriptor modified
- [ ] Re-discovery with --force succeeds
- [ ] Updated metadata visible in Home Assistant
- [ ] No duplicate entities created
- [ ] Cleanup completed

### Scenario 3: Module Removal
- [ ] Descriptor removed from sensors.d/
- [ ] luigi-discover confirms no sensors
- [ ] Sensor becomes unavailable in HA
- [ ] Manual HA cleanup performed
- [ ] MQTT retained message cleared (optional)
- [ ] Complete cleanup verified

---

## Test Automation Script

For automated testing, a script will be created in Phase 2:

```bash
# Future: tests/e2e/run-e2e-tests.sh
# Will automate all three scenarios with assertions
```

---

## Test Documentation Status

- [x] Scenario 1 documented (New Module Integration)
- [x] Scenario 2 documented (Module Update)
- [x] Scenario 3 documented (Module Removal)
- [ ] Automation script created (Phase 2)
- [ ] Test results template created
- [ ] CI/CD integration (future enhancement)

---

**Phase 1 Status:** Documentation Complete  
**Next Step:** Execute scenarios during Phase 2 Core Implementation  
**Document Version:** 1.0  
**Created:** 2026-02-10
