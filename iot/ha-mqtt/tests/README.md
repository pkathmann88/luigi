# Testing Documentation for iot/ha-mqtt

**Part of Phase 1: Testing Strategy Implementation**

This directory contains the testing infrastructure for the iot/ha-mqtt module. The testing strategy follows a multi-layered approach to ensure code quality, functionality, and integration reliability.

## Testing Philosophy

The iot/ha-mqtt module follows Test-Driven Development (TDD) principles:

1. **Test Infrastructure First:** Create test harnesses and documentation before implementation
2. **Multiple Testing Layers:** Syntax, functional, integration, and end-to-end tests
3. **Incremental Testing:** Test as code is implemented in Phase 2
4. **Automated Validation:** Scripts that can run in CI/CD pipelines

## Test Directory Structure

```
tests/
├── README.md                           # This file
├── syntax/                             # Syntax validation tests (Phase 1.1)
│   ├── validate-all.sh                # Shell script syntax validation
│   └── validate-python.sh             # Python syntax validation
├── functional/                         # Functional tests (Phase 1.2)
│   └── run-functional-tests.sh        # Test harness for unit-level testing
├── integration/                        # Integration tests (Phase 1.3)
│   └── run-integration-tests.sh       # MQTT broker integration tests
└── E2E_SCENARIOS.md                   # End-to-end test scenarios (Phase 1.4)
```

## Test Layers

### Layer 1: Syntax Validation (Phase 1.1)

**Purpose:** Validate code syntax without execution

**Location:** `tests/syntax/`

**Tools:**
- `shellcheck` for shell scripts
- `python3 -m py_compile` for Python scripts

**Usage:**
```bash
# Validate all shell scripts
cd /path/to/iot/ha-mqtt
./tests/syntax/validate-all.sh

# Validate Python service (optional)
./tests/syntax/validate-python.sh
```

**When to Run:**
- After creating or modifying any shell script
- After creating or modifying Python service
- Before committing code changes
- In CI/CD pipeline (first gate)

**Exit Codes:**
- `0` = All syntax checks passed
- `1` = Syntax errors found

**Scripts Validated:**
- `setup.sh`
- `bin/luigi-publish`
- `bin/luigi-discover`
- `bin/luigi-mqtt-status`
- `lib/mqtt_helpers.sh`
- `lib/ha_discovery_generator.sh`
- `bin/ha-mqtt-bridge.py` (optional)

---

### Layer 2: Functional Testing (Phase 1.2)

**Purpose:** Test individual functions and scripts in isolation

**Location:** `tests/functional/`

**Test Categories:**

1. **Configuration Loading Tests**
   - Config file parsing (INI format)
   - Default value application
   - Required parameter validation
   - File permission enforcement (600)

2. **luigi-publish Parameter Validation**
   - Required parameters (--sensor, --value)
   - Optional parameters (--unit, --device-class)
   - Error handling for missing config
   - Topic construction logic
   - Return code validation

3. **luigi-discover Descriptor Tests**
   - Descriptor file scanning
   - JSON parsing and validation
   - Discovery payload generation
   - Malformed descriptor handling

4. **luigi-mqtt-status Connection Tests**
   - Connection check logic
   - Error message generation
   - Return codes for different failure modes

**Usage:**
```bash
cd /path/to/iot/ha-mqtt
./tests/functional/run-functional-tests.sh
```

**When to Run:**
- After implementing each script/function (incremental)
- After modifying existing functionality
- Before integration testing
- In CI/CD pipeline (second gate)

**Exit Codes:**
- `0` = All tests passed
- `1` = Test failures

**Note:** Tests will be skipped if scripts are not yet implemented. Test functions contain placeholders that will be filled during Phase 2.

---

### Layer 3: Integration Testing (Phase 1.3)

**Purpose:** Test MQTT broker integration and Home Assistant interaction

**Location:** `tests/integration/`

**Prerequisites:**
- MQTT broker running and accessible
- mosquitto-clients installed
- ha-mqtt.conf configured with valid credentials

**Test Categories:**

1. **MQTT Connection Tests**
   - Successful connection to broker
   - Authentication with credentials
   - Connection failure handling
   - TLS encryption (if configured)

2. **Publish Tests**
   - Publish test messages
   - Verify message receipt
   - QoS 0, 1, 2 settings
   - Retained message flag

3. **Discovery Tests**
   - Sensor registration
   - Discovery message format validation
   - Sensor appearance in Home Assistant
   - Re-registration after descriptor change

4. **Service Tests (Optional)**
   - Service start/stop
   - Automatic reconnection
   - Periodic descriptor scanning
   - Log rotation

**Usage:**
```bash
cd /path/to/iot/ha-mqtt

# Default broker (localhost)
./tests/integration/run-integration-tests.sh

# Specify broker host
./tests/integration/run-integration-tests.sh --broker mqtt.example.com

# Get help
./tests/integration/run-integration-tests.sh --help
```

**When to Run:**
- After completing functional testing
- After deploying to test environment
- Before end-to-end scenarios
- In CI/CD pipeline (third gate - requires MQTT broker)

**Exit Codes:**
- `0` = All tests passed
- `1` = Test failures
- `2` = Prerequisites not met

---

### Layer 4: End-to-End Scenario Testing (Phase 1.4)

**Purpose:** Validate complete integration workflows from module deployment to Home Assistant

**Location:** `tests/E2E_SCENARIOS.md`

**Test Scenarios:**

1. **Scenario 1: New Module Integration**
   - Complete workflow for integrating a new sensor module
   - Tests descriptor creation, discovery, publishing, and HA verification

2. **Scenario 2: Module Update**
   - Workflow for updating sensor metadata
   - Tests re-registration and metadata updates in HA

3. **Scenario 3: Module Removal**
   - Workflow for removing a sensor
   - Documents manual cleanup requirements

**Prerequisites:**
- Complete ha-mqtt installation
- MQTT broker running
- Home Assistant instance accessible
- Test sensor descriptors available

**Usage:**
```bash
# Manual execution following E2E_SCENARIOS.md
# Automated script will be created in Phase 2
```

**When to Run:**
- After complete module installation
- Before production deployment
- During acceptance testing
- After major changes to integration logic

---

## Test Execution Order

Follow this sequence for complete testing:

```
1. Syntax Validation
   ↓
2. Functional Testing
   ↓
3. Integration Testing
   ↓
4. End-to-End Scenarios
   ↓
5. Code Review & Security Scan
   ↓
6. Production Deployment
```

## Quick Test Commands

```bash
# Run all syntax validation
cd /path/to/iot/ha-mqtt
./tests/syntax/validate-all.sh
./tests/syntax/validate-python.sh

# Run functional tests
./tests/functional/run-functional-tests.sh

# Run integration tests
./tests/integration/run-integration-tests.sh --broker YOUR_BROKER

# Run all automated tests in sequence
./tests/syntax/validate-all.sh && \
./tests/functional/run-functional-tests.sh && \
./tests/integration/run-integration-tests.sh
```

## Test Status by Phase

### Phase 1: Testing Strategy Implementation (Current)
- [x] Syntax validation infrastructure created
- [x] Functional test framework created
- [x] Integration test framework created
- [x] End-to-end scenarios documented
- [x] Test README documentation created
- [ ] All test placeholders filled (Phase 2)

### Phase 2: Core Implementation
- [ ] Implement test functions as scripts are created
- [ ] Execute tests incrementally during development
- [ ] Achieve passing tests for all implemented features
- [ ] Create automated E2E test script

### Phase 5: Final Verification
- [ ] All tests passing
- [ ] Test coverage analysis
- [ ] Performance testing
- [ ] Security testing

## Test Results

Test execution results will be documented here during Phase 2:

| Date | Layer | Tests Run | Passed | Failed | Notes |
|------|-------|-----------|--------|--------|-------|
| TBD  | Syntax | - | - | - | Phase 2 |
| TBD  | Functional | - | - | - | Phase 2 |
| TBD  | Integration | - | - | - | Phase 2 |
| TBD  | E2E | - | - | - | Phase 2 |

## Continuous Integration

**Future Enhancement:** Integrate with GitHub Actions or GitLab CI/CD

```yaml
# Example .github/workflows/ha-mqtt-tests.yml (future)
name: ha-mqtt Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install shellcheck
        run: sudo apt-get install shellcheck
      - name: Syntax Validation
        run: cd iot/ha-mqtt && ./tests/syntax/validate-all.sh
      - name: Functional Tests
        run: cd iot/ha-mqtt && ./tests/functional/run-functional-tests.sh
```

## Troubleshooting Tests

### Syntax Tests Failing
- Check shellcheck is installed: `shellcheck --version`
- Check Python 3 is available: `python3 --version`
- Review shellcheck output for specific issues

### Functional Tests Not Running
- Verify scripts exist in bin/ and lib/ directories
- Check script permissions (755 for executables)
- Review test output for skip reasons

### Integration Tests Failing
- Verify MQTT broker is running: `mosquitto_pub -h BROKER -t test -m test`
- Check network connectivity
- Verify ha-mqtt.conf exists and has correct credentials
- Check firewall rules

### E2E Scenarios Issues
- Verify complete installation: `sudo ./setup.sh status`
- Check Home Assistant is accessible
- Verify MQTT integration in Home Assistant
- Review Home Assistant logs for errors

## Contributing

When adding new features to ha-mqtt:

1. **Add syntax validation** to validate-all.sh or validate-python.sh
2. **Add functional tests** to run-functional-tests.sh
3. **Add integration tests** to run-integration-tests.sh if MQTT interaction is involved
4. **Document E2E scenarios** if user-facing workflow changes
5. **Run all tests** before submitting PR
6. **Update this README** if test approach changes

## References

- **IMPLEMENTATION_PLAN.md:** Complete implementation phases
- **DESIGN_ANALYSIS.md:** Module architecture and design decisions
- **Phase 1 Checklist:** See IMPLEMENTATION_PLAN.md Phase 1 section
- **Luigi Testing Standards:** `.github/copilot-instructions.md`

---

**Phase 1 Status:** Complete  
**Document Version:** 1.0  
**Created:** 2026-02-10  
**Last Updated:** 2026-02-10
