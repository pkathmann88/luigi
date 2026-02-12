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
- **`capabilities`** (array): List of capability types this module provides (see Capability Types below)
- **`hardware`** (object): Hardware requirements
  - **`gpio_pins`** (array): List of GPIO pins used by the module
  - **`sensors`** (array): List of sensors or hardware components required
- **`provides`** (array): List of commands, utilities, or services provided by this module

## Capability Types

The `capabilities` array declares what features and functionality the module provides. This enables dynamic management interfaces and automated feature discovery.

### Standard Capability Types

- **`service`** - Module provides a systemd service that can be managed (start/stop/restart/status)
  - Indicates the module has a background daemon or service
  - Management interfaces can show service control buttons
  - Example: motion-detection modules, management-api
  
- **`cli-tools`** - Module provides command-line utilities
  - Indicates the module installs executable scripts to `/usr/local/bin/` or similar
  - Management interfaces can list available commands
  - Example: ha-mqtt provides luigi-publish, luigi-discover, luigi-mqtt-status
  
- **`api`** - Module provides HTTP/REST API endpoints
  - Indicates the module exposes web services
  - Management interfaces can show API documentation or endpoint testing
  - Example: management-api provides REST API
  
- **`config`** - Module has user-configurable settings
  - Indicates the module has configuration files in `/etc/luigi/{module-path}/`
  - Management interfaces can show configuration editor
  - Example: most modules with setup-specific settings
  
- **`hardware`** - Module directly interacts with GPIO pins or hardware
  - Indicates the module requires physical hardware connections
  - Management interfaces can show hardware requirements and wiring diagrams
  - Example: mario (PIR sensor), future relay/LED modules
  
- **`sensor`** - Module provides sensor data or measurements
  - Indicates the module can publish sensor readings
  - Management interfaces can show current values or historical data
  - Example: motion detection, temperature sensors, door sensors
  
- **`integration`** - Module integrates with external systems
  - Indicates the module connects to third-party services or platforms
  - Management interfaces can show connection status
  - Example: ha-mqtt (Home Assistant), future cloud integrations

### Usage Guidelines

**Multiple Capabilities:**
Modules can declare multiple capabilities. For example, mario has:
```json
"capabilities": ["service", "hardware", "sensor", "config"]
```

**Capability-Driven UI:**
Frontend applications should check capabilities to determine available actions:
```javascript
// Show restart button only if module has 'service' capability
if (module.capabilities?.includes('service')) {
  showRestartButton();
}

// Show config editor only if module has 'config' capability
if (module.capabilities?.includes('config')) {
  showConfigButton();
}
```

**Discovery:**
Tools can query modules by capability:
```bash
# Find all modules with service capability
jq -r 'select(.capabilities[]? == "service") | .module_path' /etc/luigi/modules/*.json

# Find all sensor modules
jq -r 'select(.capabilities[]? == "sensor") | .module_path' /etc/luigi/modules/*.json
```

### Future Capability Types

The capability system is extensible. Future additions might include:
- `webhook` - Module accepts webhook callbacks
- `mqtt` - Module uses MQTT messaging
- `database` - Module uses database storage
- `ui` - Module provides web interface
- `scheduler` - Module runs scheduled tasks
- `alert` - Module sends notifications/alerts

## Example Schemas

### Module with Dependencies

```json
{
  "name": "mario",
  "version": "1.0.0",
  "description": "Mario-themed motion detection module using PIR sensors",
  "category": "motion-detection",
  "capabilities": [
    "service",
    "hardware",
    "sensor",
    "config"
  ],
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
  "capabilities": [
    "cli-tools",
    "integration",
    "config"
  ],
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

### System Service Module

```json
{
  "name": "management-api",
  "version": "1.0.0",
  "description": "REST API and web interface for Luigi system management",
  "category": "system",
  "capabilities": [
    "service",
    "api",
    "config"
  ],
  "dependencies": [],
  "apt_packages": [
    "nodejs",
    "npm"
  ],
  "author": "Luigi Project"
}
```

### Minimal Module

```json
{
  "name": "simple-module",
  "version": "1.0.0",
  "description": "A simple module example",
  "category": "sensors",
  "capabilities": [],
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

1. **Always declare capabilities**: List all capability types your module provides. This enables dynamic management interfaces and feature discovery.

2. **Always specify dependencies**: If your module uses functionality from another module (like mario → ha-mqtt), declare it in dependencies.

3. **Always specify apt_packages**: List all apt packages your module requires (e.g., python3-rpi.gpio, mosquitto-clients). This enables batch installation and improves setup efficiency.

4. **Keep descriptions concise**: Aim for one-line descriptions that clearly explain the module's purpose.

5. **Use semantic versioning**: Follow semver (MAJOR.MINOR.PATCH) for version numbers.

6. **Document hardware requirements**: If your module uses GPIO pins or specific hardware, document it in the `hardware` section.

7. **List provided utilities**: If your module installs commands or services that other modules might depend on, list them in `provides`.

8. **Declare multiple capabilities**: Most modules have multiple capabilities. Be comprehensive - it helps users and management tools understand what the module does.

### Capability Declaration Guidelines

**Service Capability:**
- Declare if your module installs a systemd service file
- Example: motion detection daemons, API servers, monitoring services

**CLI Tools Capability:**
- Declare if your module installs executable scripts to `/usr/local/bin/`
- List the commands in the `provides` array

**Hardware Capability:**
- Declare if your module uses GPIO pins or connected hardware
- Document specific pins and sensors in the `hardware` section

**Sensor Capability:**
- Declare if your module reads and publishes sensor data
- Works well with `integration` for MQTT publishing

**Config Capability:**
- Declare if your module has configuration files in `/etc/luigi/`
- Helps management interfaces show configuration editors

**API Capability:**
- Declare if your module provides HTTP/REST endpoints
- Indicates the module can be controlled/queried via web API

**Integration Capability:**
- Declare if your module connects to external systems
- Example: MQTT brokers, Home Assistant, cloud services

## Example Use Cases

### Sensor Module with MQTT Integration

A temperature sensor module that publishes to Home Assistant:

```json
{
  "name": "dht22",
  "version": "1.0.0",
  "description": "DHT22 temperature and humidity sensor with MQTT publishing",
  "category": "sensors",
  "capabilities": [
    "service",
    "hardware",
    "sensor",
    "config"
  ],
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
  "capabilities": [
    "service",
    "hardware",
    "sensor",
    "config"
  ],
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

### CLI Tools Module

A utility module providing command-line tools without a service:

```json
{
  "name": "gpio-utils",
  "version": "1.0.0",
  "description": "GPIO testing and diagnostic utilities",
  "category": "system",
  "capabilities": [
    "cli-tools",
    "hardware"
  ],
  "dependencies": [],
  "apt_packages": ["python3-rpi.gpio"],
  "provides": [
    "gpio-test",
    "gpio-status",
    "gpio-reset"
  ]
}
```

## Capabilities-Driven Management

### Frontend Integration Example

Management interfaces can use capabilities to show/hide features:

```javascript
// React component example
function ModuleCard({ module }) {
  const canRestart = module.capabilities?.includes('service');
  const canConfigure = module.capabilities?.includes('config');
  const hasAPI = module.capabilities?.includes('api');
  
  return (
    <div className="module-card">
      <h3>{module.name}</h3>
      <p>{module.description}</p>
      
      <div className="actions">
        {canRestart && (
          <button onClick={() => restartModule(module.name)}>
            Restart Service
          </button>
        )}
        {canConfigure && (
          <button onClick={() => openConfig(module.name)}>
            Configure
          </button>
        )}
        {hasAPI && (
          <a href={`/api/docs/${module.name}`}>API Docs</a>
        )}
      </div>
    </div>
  );
}
```

### CLI Query Examples

```bash
# Find all modules with service capability
jq -r 'select(.capabilities[]? == "service") | .name' /etc/luigi/modules/*.json

# Find all sensor modules for dashboard
jq -r 'select(.capabilities[]? == "sensor") | {name, description}' \
    /etc/luigi/modules/*.json

# Find all modules that can be configured
jq -r 'select(.capabilities[]? == "config") | .module_path' \
    /etc/luigi/modules/*.json

# Find hardware modules requiring GPIO
jq -r 'select(.capabilities[]? == "hardware") | 
    {name, pins: .hardware.gpio_pins}' /etc/luigi/modules/*.json
```

### Management API Integration

```javascript
// API endpoint to get manageable services
app.get('/api/modules/services', (req, res) => {
  const modules = loadModules();
  const services = modules.filter(m => 
    m.capabilities?.includes('service')
  );
  res.json(services);
});

// API endpoint to get configurable modules
app.get('/api/modules/configurable', (req, res) => {
  const modules = loadModules();
  const configurable = modules.filter(m => 
    m.capabilities?.includes('config')
  );
  res.json(configurable);
});
```

## See Also

- Root `setup.sh`: Implements dependency resolution and installation ordering
- Module-specific `setup.sh`: Handles actual installation of module files and configuration
- Module README: User-facing documentation for module usage
