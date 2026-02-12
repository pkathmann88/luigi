# Module Registry Schema Reference

## Overview

The Luigi module registry provides centralized tracking of all installed modules on a system. Each module gets a JSON file in `/etc/luigi/modules/` that records installation metadata, version information, and current status.

## Registry File Naming Convention

**Pattern:** `/etc/luigi/modules/{encoded-module-path}.json`

**Path Encoding:** Module paths use `__` (double underscore) as directory separator.

**Examples:**
| Module Path | Registry File |
|-------------|---------------|
| `motion-detection/mario` | `/etc/luigi/modules/motion-detection__mario.json` |
| `iot/ha-mqtt` | `/etc/luigi/modules/iot__ha-mqtt.json` |
| `system/management-api` | `/etc/luigi/modules/system__management-api.json` |
| `sensors/dht22` | `/etc/luigi/modules/sensors__dht22.json` |

**Encoding Function (Bash):**
```bash
encode_module_path() {
    echo "$1" | tr '/' '_' | sed 's/_/__/g'
}

# Usage
registry_file="/etc/luigi/modules/$(encode_module_path "$module_path").json"
```

**Decoding Function (Bash):**
```bash
decode_module_path() {
    echo "$1" | sed 's/__/\//g'
}

# Usage
module_path=$(decode_module_path "motion-detection__mario")
# Result: motion-detection/mario
```

## Complete Schema

```typescript
interface ModuleRegistryEntry {
  // Core Identity
  module_path: string;          // Full module path (e.g., "motion-detection/mario")
  name: string;                 // Module name (directory name)
  version: string;              // Semantic version (e.g., "1.0.0")
  category: string;             // Category (e.g., "motion-detection", "iot", "system")
  
  // Timestamps
  installed_at: string;         // ISO 8601 timestamp of initial installation
  updated_at: string;           // ISO 8601 timestamp of last update
  
  // Installation Metadata
  installed_by: string;         // What installed the module ("setup.sh", "management-api", "manual")
  install_method: string;       // How installed ("manual", "auto", "api", "script")
  source_hash?: string;         // Hash of source files at installation time
  
  // Status
  status: string;               // Current status ("active", "installed", "failed", "removed")
  
  // Optional Module Metadata (from module.json)
  description?: string;         // Brief description
  author?: string;              // Module author/maintainer
  dependencies?: string[];      // List of module paths this depends on
  apt_packages?: string[];      // Required apt packages
  provides?: string[];          // Commands/utilities/services provided
  
  // Hardware Requirements
  hardware?: {
    gpio_pins?: number[];       // GPIO pins used
    sensors?: string[];         // Sensors/hardware required
  };
  
  // Service Integration
  service_name?: string | null; // Systemd service name if applicable
  service_enabled?: boolean | null; // Whether service starts at boot
  
  // File System Paths
  config_path?: string | null;  // Path to configuration directory
  log_path?: string | null;     // Path to log file
}
```

## Field Descriptions

### Core Identity Fields

#### `module_path` (Required)
- **Type:** string
- **Description:** Full module path relative to repository root
- **Format:** `{category}/{module-name}`
- **Examples:** `"motion-detection/mario"`, `"iot/ha-mqtt"`, `"sensors/dht22"`
- **Purpose:** Unique identifier for the module across the system

#### `name` (Required)
- **Type:** string
- **Description:** Module name (should match directory name)
- **Format:** lowercase with hyphens
- **Examples:** `"mario"`, `"ha-mqtt"`, `"management-api"`
- **Purpose:** Human-readable module identifier

#### `version` (Required)
- **Type:** string
- **Description:** Module version in semantic versioning format
- **Format:** `MAJOR.MINOR.PATCH`
- **Examples:** `"1.0.0"`, `"2.3.1"`, `"0.1.0"`
- **Purpose:** Track module version for updates

#### `category` (Required)
- **Type:** string
- **Description:** Module category
- **Valid Values:** 
  - `"motion-detection"` - Motion detection modules
  - `"sensors"` - Sensor modules
  - `"automation"` - Automation modules
  - `"security"` - Security modules
  - `"iot"` - IoT integration modules
  - `"system"` - System modules
- **Purpose:** Organize and filter modules by type

### Timestamp Fields

#### `installed_at` (Required)
- **Type:** string (ISO 8601)
- **Description:** Timestamp of initial module installation
- **Format:** `YYYY-MM-DDTHH:mm:ss.sssZ` (UTC)
- **Example:** `"2026-02-12T10:30:45.123Z"`
- **Purpose:** Track when module was first installed
- **Note:** This value NEVER changes after initial installation

#### `updated_at` (Required)
- **Type:** string (ISO 8601)
- **Description:** Timestamp of last module update
- **Format:** `YYYY-MM-DDTHH:mm:ss.sssZ` (UTC)
- **Example:** `"2026-02-15T14:22:10.456Z"`
- **Purpose:** Track when module was last updated
- **Note:** This value changes on every update/reinstallation

### Installation Metadata Fields

#### `installed_by` (Required)
- **Type:** string
- **Description:** What tool/method installed the module
- **Valid Values:**
  - `"setup.sh"` - Installed via module's setup script
  - `"management-api"` - Installed via management API
  - `"manual"` - Manually installed by user
  - `"migration"` - Created during registry migration
  - `"script"` - Installed by batch script
- **Purpose:** Track installation source for troubleshooting

#### `install_method` (Required)
- **Type:** string
- **Description:** How the module was installed
- **Valid Values:**
  - `"manual"` - User manually ran setup script
  - `"auto"` - Auto-installed as dependency
  - `"api"` - Installed via REST API
  - `"script"` - Installed via batch script
- **Purpose:** Distinguish between automatic and manual installations

#### `source_hash` (Optional)
- **Type:** string
- **Description:** Hash of module source files at installation time
- **Format:** SHA256 hexadecimal string (64 characters)
- **Example:** `"a3f5c9d2e1b4f8c7a6d5e4f3b2c1d0e9f8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3"`
- **Purpose:** Detect if module source has changed since installation
- **Calculation:** Hash of concatenated key files (setup.sh, module.json, main scripts)
- **Note:** Can be used to trigger update prompts

### Status Field

#### `status` (Required)
- **Type:** string (enum)
- **Description:** Current module status
- **Valid Values:**
  - `"active"` - Module installed and service running
  - `"installed"` - Module installed, service not running (or no service)
  - `"failed"` - Module installation or service startup failed
  - `"removed"` - Module uninstalled (registry preserved for history)
- **Purpose:** Quick status check for module health

### Optional Module Metadata (from module.json)

#### `description` (Optional)
- **Type:** string
- **Description:** Brief description of module purpose
- **Example:** `"Mario-themed motion detection module using PIR sensors"`
- **Purpose:** Human-readable explanation of what module does
- **Source:** Copied from `module.json` if present

#### `author` (Optional)
- **Type:** string
- **Description:** Module author or maintainer
- **Example:** `"Luigi Project"`
- **Purpose:** Credit and contact information
- **Source:** Copied from `module.json` if present

#### `dependencies` (Optional)
- **Type:** array of strings
- **Description:** List of module paths this module depends on
- **Example:** `["iot/ha-mqtt"]`
- **Purpose:** Track module dependencies for installation order
- **Source:** Copied from `module.json` if present

#### `apt_packages` (Optional)
- **Type:** array of strings
- **Description:** List of apt packages required by this module
- **Example:** `["python3-rpi.gpio", "alsa-utils"]`
- **Purpose:** Track system dependencies
- **Source:** Copied from `module.json` if present

#### `provides` (Optional)
- **Type:** array of strings
- **Description:** Commands, utilities, or services provided by module
- **Example:** `["luigi-publish", "luigi-discover", "luigi-mqtt-status"]`
- **Purpose:** Track what module provides to system
- **Source:** Copied from `module.json` if present

### Hardware Requirements

#### `hardware` (Optional)
- **Type:** object
- **Description:** Hardware requirements for module
- **Purpose:** Document physical hardware needed

##### `hardware.gpio_pins` (Optional)
- **Type:** array of numbers
- **Description:** GPIO pins used by module
- **Example:** `[23]`, `[17, 27]`
- **Purpose:** Track pin usage to avoid conflicts

##### `hardware.sensors` (Optional)
- **Type:** array of strings
- **Description:** Sensors or hardware components required
- **Example:** `["HC-SR501"]`, `["DHT22", "Relay module"]`
- **Purpose:** Document hardware shopping list

### Service Integration

#### `service_name` (Optional)
- **Type:** string | null
- **Description:** Systemd service name if module has a service
- **Format:** `{module-name}.service`
- **Example:** `"mario.service"`, `"ha-mqtt.service"`
- **Purpose:** Link registry entry to systemd service
- **Note:** Set to `null` if module has no service

#### `service_enabled` (Optional)
- **Type:** boolean | null
- **Description:** Whether service is enabled to start at boot
- **Values:** `true` (enabled), `false` (disabled), `null` (no service)
- **Purpose:** Track boot configuration
- **Note:** Set to `null` if module has no service

### File System Paths

#### `config_path` (Optional)
- **Type:** string | null
- **Description:** Path to module configuration directory
- **Format:** `/etc/luigi/{category}/{module-name}`
- **Example:** `"/etc/luigi/motion-detection/mario"`
- **Purpose:** Locate module configuration files
- **Note:** Set to `null` if module has no configuration

#### `log_path` (Optional)
- **Type:** string | null
- **Description:** Path to module log file
- **Format:** `/var/log/luigi/{module-name}.log`
- **Example:** `"/var/log/luigi/mario.log"`
- **Purpose:** Locate module log files
- **Note:** Set to `null` if module doesn't log to file

## Complete Example

### Example 1: Full-Featured Module (mario)

```json
{
  "module_path": "motion-detection/mario",
  "name": "mario",
  "version": "1.0.0",
  "category": "motion-detection",
  "description": "Mario-themed motion detection module using PIR sensors",
  "installed_at": "2026-02-12T10:30:45.123Z",
  "updated_at": "2026-02-12T10:30:45.123Z",
  "installed_by": "setup.sh",
  "install_method": "manual",
  "source_hash": "a3f5c9d2e1b4f8c7a6d5e4f3b2c1d0e9f8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3",
  "status": "active",
  "dependencies": ["iot/ha-mqtt"],
  "apt_packages": ["python3-rpi.gpio", "alsa-utils"],
  "author": "Luigi Project",
  "hardware": {
    "gpio_pins": [23],
    "sensors": ["HC-SR501"]
  },
  "provides": [],
  "service_name": "mario.service",
  "service_enabled": true,
  "config_path": "/etc/luigi/motion-detection/mario",
  "log_path": "/var/log/luigi/mario.log"
}
```

### Example 2: Service Module (ha-mqtt)

```json
{
  "module_path": "iot/ha-mqtt",
  "name": "ha-mqtt",
  "version": "1.0.0",
  "category": "iot",
  "description": "Home Assistant MQTT integration for Luigi sensor modules",
  "installed_at": "2026-02-12T10:25:30.456Z",
  "updated_at": "2026-02-12T10:25:30.456Z",
  "installed_by": "setup.sh",
  "install_method": "manual",
  "source_hash": "b2f4d8c1a9e7f5b3c6d4e2f1a8b9c7d5e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8",
  "status": "installed",
  "dependencies": [],
  "apt_packages": ["mosquitto-clients", "jq"],
  "author": "Luigi Project",
  "provides": [
    "luigi-publish",
    "luigi-discover",
    "luigi-mqtt-status"
  ],
  "service_name": null,
  "service_enabled": null,
  "config_path": "/etc/luigi/iot/ha-mqtt",
  "log_path": "/var/log/luigi/ha-mqtt.log"
}
```

### Example 3: Minimal Module

```json
{
  "module_path": "system/optimization",
  "name": "optimization",
  "version": "1.0.0",
  "category": "system",
  "installed_at": "2026-02-12T11:15:20.789Z",
  "updated_at": "2026-02-12T11:15:20.789Z",
  "installed_by": "setup.sh",
  "install_method": "manual",
  "status": "installed"
}
```

### Example 4: Removed Module

```json
{
  "module_path": "motion-detection/mario",
  "name": "mario",
  "version": "1.0.0",
  "category": "motion-detection",
  "description": "Mario-themed motion detection module using PIR sensors",
  "installed_at": "2026-02-12T10:30:45.123Z",
  "updated_at": "2026-02-15T16:45:12.345Z",
  "installed_by": "setup.sh",
  "install_method": "manual",
  "status": "removed",
  "dependencies": ["iot/ha-mqtt"],
  "service_name": "mario.service",
  "service_enabled": false,
  "config_path": "/etc/luigi/motion-detection/mario",
  "log_path": "/var/log/luigi/mario.log"
}
```

## Status Transitions

Valid status transitions:

```
[Initial] → installed → active
                ↓         ↓
              failed   removed
```

- **Initial Installation:**
  - With service: `installed` → `active` (if service starts successfully)
  - Without service: `installed` (final state)
  - Failure: `failed`

- **Update:**
  - Status typically remains the same
  - Update `updated_at` timestamp
  - Update `version` field

- **Removal:**
  - Any status → `removed`
  - Keep registry entry for history
  - Set `service_enabled` to `false`

## Validation Rules

### Required Field Validation

```bash
validate_registry_entry() {
    local file="$1"
    local errors=0
    
    # Check required fields
    for field in module_path name version category installed_at updated_at installed_by install_method status; do
        if ! jq -e ".$field" "$file" >/dev/null 2>&1; then
            echo "Error: Missing required field '$field' in $file"
            errors=$((errors + 1))
        fi
    done
    
    return $errors
}
```

### Version Format Validation

```bash
validate_version() {
    local version="$1"
    
    # Check semver format: MAJOR.MINOR.PATCH
    if ! echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        echo "Error: Invalid version format '$version'. Expected MAJOR.MINOR.PATCH"
        return 1
    fi
    
    return 0
}
```

### Timestamp Format Validation

```bash
validate_timestamp() {
    local timestamp="$1"
    
    # Check ISO 8601 format
    if ! echo "$timestamp" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}Z$'; then
        echo "Error: Invalid timestamp format '$timestamp'. Expected ISO 8601"
        return 1
    fi
    
    return 0
}
```

## Query Examples

### List All Installed Modules

```bash
for file in /etc/luigi/modules/*.json; do
    [ -f "$file" ] || continue
    jq -r 'select(.status != "removed") | "\(.module_path) - v\(.version) - \(.status)"' "$file"
done
```

### Find Modules by Category

```bash
category="motion-detection"
jq -r "select(.category == \"$category\" and .status != \"removed\") | .module_path" \
    /etc/luigi/modules/*.json
```

### Find Active Modules

```bash
jq -r 'select(.status == "active") | "\(.module_path) - \(.service_name)"' \
    /etc/luigi/modules/*.json
```

### Find Modules Using GPIO Pin

```bash
pin=23
jq -r "select(.hardware.gpio_pins[]? == $pin) | \"\(.module_path) uses GPIO $pin\"" \
    /etc/luigi/modules/*.json
```

### Find Modules Depending on Another

```bash
dependency="iot/ha-mqtt"
jq -r "select(.dependencies[]? == \"$dependency\") | .module_path" \
    /etc/luigi/modules/*.json
```

### Check for Updates

```bash
for file in /etc/luigi/modules/*.json; do
    module_path=$(jq -r '.module_path' "$file")
    current=$(jq -r '.version' "$file")
    status=$(jq -r '.status' "$file")
    
    [ "$status" = "removed" ] && continue
    
    source_json="/home/pi/luigi/$module_path/module.json"
    if [ -f "$source_json" ]; then
        source=$(jq -r '.version' "$source_json")
        if [ "$source" != "$current" ]; then
            echo "$module_path: $current → $source"
        fi
    fi
done
```

## Migration Tools

### Create Registry Entry

```bash
create_registry_entry() {
    local module_path="$1"
    local version="$2"
    local status="${3:-installed}"
    
    local name=$(basename "$module_path")
    local category=$(dirname "$module_path")
    local registry_file="/etc/luigi/modules/${module_path/\//__}.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    mkdir -p /etc/luigi/modules
    
    cat > "$registry_file" <<EOF
{
  "module_path": "$module_path",
  "name": "$name",
  "version": "$version",
  "category": "$category",
  "installed_at": "$timestamp",
  "updated_at": "$timestamp",
  "installed_by": "manual",
  "install_method": "manual",
  "status": "$status"
}
EOF
    
    echo "Created: $registry_file"
}
```

### Update Registry Entry

```bash
update_registry_field() {
    local module_path="$1"
    local field="$2"
    local value="$3"
    
    local registry_file="/etc/luigi/modules/${module_path/\//__}.json"
    
    if [ ! -f "$registry_file" ]; then
        echo "Error: Registry entry not found for $module_path"
        return 1
    fi
    
    jq ".$field = \"$value\"" "$registry_file" > /tmp/registry.json
    mv /tmp/registry.json "$registry_file"
    
    echo "Updated $field for $module_path"
}
```

## See Also

- **SKILL.md** - Main module management skill documentation
- **MODULE_SCHEMA.md** - Module metadata (module.json) schema
- **management-api** - REST API for module management with registry integration
