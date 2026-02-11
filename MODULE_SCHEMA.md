# Module Metadata Schema (module.json)

## Overview

Each Luigi module can include an optional `module.json` file in its root directory. This file provides metadata about the module, including dependencies, versioning, and other information that helps the setup system manage module installation.

## Schema Version: 1.0

## File Location

The `module.json` file should be placed in the module's root directory, alongside the `setup.sh` script:

```
category/module-name/
├── module.json      # Module metadata
├── setup.sh         # Setup script
└── ...              # Other module files
```

## JSON Structure

### Required Fields

- **`name`** (string): Module name (must match directory name)
- **`version`** (string): Module version in semantic versioning format (e.g., "1.0.0")
- **`description`** (string): Brief description of the module's purpose
- **`category`** (string): Module category (e.g., "motion-detection", "iot", "system")
- **`dependencies`** (array): List of module paths that must be installed before this module
- **`apt_packages`** (array): List of apt package names required by this module (e.g., ["python3-rpi.gpio", "alsa-utils"])

### Optional Fields

- **`author`** (string): Module author or maintainer
- **`hardware`** (object): Hardware requirements
  - **`gpio_pins`** (array): List of GPIO pins used by the module
  - **`sensors`** (array): List of sensors or hardware components required
- **`provides`** (array): List of commands, utilities, or services provided by this module

## Example Schemas

### Module with Dependencies

```json
{
  "name": "mario",
  "version": "1.0.0",
  "description": "Mario-themed motion detection module using PIR sensors",
  "category": "motion-detection",
  "dependencies": [
    "iot/ha-mqtt"
  ],
  "apt_packages": [
    "python3-rpi.gpio",
    "alsa-utils"
  ],
  "author": "Luigi Project",
  "hardware": {
    "gpio_pins": [23],
    "sensors": ["HC-SR501"]
  }
}
```

### Module without Dependencies

```json
{
  "name": "ha-mqtt",
  "version": "1.0.0",
  "description": "Home Assistant MQTT integration for Luigi sensor modules",
  "category": "iot",
  "dependencies": [],
  "apt_packages": [
    "mosquitto-clients",
    "jq"
  ],
  "author": "Luigi Project",
  "provides": [
    "luigi-publish",
    "luigi-discover",
    "luigi-mqtt-status"
  ]
}
```

### Minimal Module

```json
{
  "name": "simple-module",
  "version": "1.0.0",
  "description": "A simple module example",
  "category": "sensors",
  "dependencies": [],
  "apt_packages": []
}
```

## Dependency Format

Dependencies are specified as **module paths** relative to the repository root:

```json
{
  "dependencies": [
    "iot/ha-mqtt",           // Single dependency
    "system/optimization"     // Another dependency
  ]
}
```

### Dependency Resolution Rules

1. **Installation Order**: Modules are installed in dependency order. Dependencies are always installed before modules that depend on them.

2. **Circular Dependencies**: The setup system will detect circular dependencies and report an error.

3. **Missing Dependencies**: If a dependency is not found, the setup system will report an error and skip installation of the dependent module.

4. **Optional Dependencies**: All dependencies listed in `module.json` are considered **required**. For optional integrations (like ha-mqtt for sensor modules), the module's `setup.sh` should handle graceful degradation.

## Backward Compatibility

The `module.json` file is **optional**. Modules without `module.json` will:
- Be discovered and executed normally
- Be installed in arbitrary order (no guaranteed ordering)
- Cannot declare dependencies on other modules

Existing modules continue to work without modification.

## Future Extensions

The `module.json` schema is designed for extensibility. Future versions may include:

- **`config`**: Configuration schema and defaults
- **`conflicts`**: List of incompatible modules
- **`replaces`**: List of modules this one replaces
- **`tags`**: Categorization tags for filtering
- **`documentation`**: URLs to external documentation
- **`repository`**: Source code repository information

## Validation

The setup system performs basic validation:
- JSON syntax must be valid
- Required fields must be present
- Dependency paths must be valid module paths
- Module name must match directory name (recommended, not enforced)

Invalid `module.json` files will generate warnings but will not prevent module discovery or installation.

## Best Practices

1. **Always specify dependencies**: If your module uses functionality from another module (like mario → ha-mqtt), declare it in dependencies.

2. **Always specify apt_packages**: List all apt packages your module requires (e.g., python3-rpi.gpio, mosquitto-clients). This enables batch installation and improves setup efficiency.

3. **Keep descriptions concise**: Aim for one-line descriptions that clearly explain the module's purpose.

4. **Use semantic versioning**: Follow semver (MAJOR.MINOR.PATCH) for version numbers.

5. **Document hardware requirements**: If your module uses GPIO pins or specific hardware, document it in the `hardware` section.

6. **List provides**: If your module installs commands or services that other modules might depend on, list them in `provides`.

## Example Use Cases

### Sensor Module with MQTT Integration

A temperature sensor module that publishes to Home Assistant:

```json
{
  "name": "dht22",
  "version": "1.0.0",
  "description": "DHT22 temperature and humidity sensor with MQTT publishing",
  "category": "sensors",
  "dependencies": ["iot/ha-mqtt"],
  "apt_packages": ["python3-pip"],
  "hardware": {
    "gpio_pins": [4],
    "sensors": ["DHT22"]
  }
}
```

### Automation Module with Multiple Dependencies

A door automation module that uses both sensors and MQTT:

```json
{
  "name": "door-control",
  "version": "1.0.0",
  "description": "Automated door control with sensor monitoring",
  "category": "automation",
  "dependencies": [
    "sensors/magnetic-switch",
    "iot/ha-mqtt"
  ],
  "apt_packages": [],
  "hardware": {
    "gpio_pins": [17, 27],
    "sensors": ["Magnetic door sensor", "Relay module"]
  }
}
```

## See Also

- Root `setup.sh`: Implements dependency resolution and installation ordering
- Module-specific `setup.sh`: Handles actual installation of module files and configuration
- Module README: User-facing documentation for module usage
