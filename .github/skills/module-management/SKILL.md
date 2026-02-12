---
name: module-management
description: Comprehensive guide for managing Luigi modules including installation, updates, removal, dependency resolution, and centralized module registry tracking. Use this skill when installing, updating, managing module lifecycles, or working with the module registry.
license: MIT
---

# Luigi Module Management Skill

This skill provides comprehensive guidance for **managing Luigi modules** throughout their lifecycle - from installation through updates to removal. It covers the centralized module registry, dependency resolution, version tracking, and module management operations.

## When to Use This Skill

Use this skill when:
- Installing new Luigi modules on a system
- Updating existing modules to new versions
- Removing or uninstalling modules
- Managing module dependencies
- Working with the centralized module registry
- Tracking module versions and deployment status
- Querying which modules are installed on a system
- Resolving module conflicts or issues
- Implementing module management tools or APIs
- Creating automated module deployment scripts

**Related Skills:**
- `.github/skills/module-design/` - For designing NEW modules before implementation
- `.github/skills/shell-scripting/` - For creating setup.sh scripts
- `.github/skills/system-setup/` - For deployment automation

## Luigi Module Management Architecture

### Overview

Luigi uses a **decentralized source, centralized registry** model:
- **Module Source:** Modules live in category directories (`motion-detection/`, `iot/`, `system/`, etc.)
- **Module Registry:** Centralized tracking in `/etc/luigi/modules/` directory
- **Module Detection:** Based on presence of `setup.sh` files
- **Module Metadata:** Optional `module.json` provides version, dependencies, and requirements

### Key Components

1. **Module Source Repository** (`/home/pi/luigi/` or `~/luigi/`)
   - Where module code and resources live
   - Organized by category directories
   - Each module has `setup.sh` for installation

2. **Centralized Module Registry** (`/etc/luigi/modules/`)
   - Tracks installed modules and their versions
   - One JSON file per installed module
   - Enables version tracking and system overview

3. **Module Configuration** (`/etc/luigi/{category}/{module}/`)
   - Module-specific configuration files
   - Follows repository directory structure
   - Persists across updates

4. **Module Services** (`/etc/systemd/system/`)
   - Systemd service files for module daemons
   - Named `{module-name}.service`

5. **Module Logs** (`/var/log/luigi/`)
   - Standardized logging directory
   - Named `{module-name}.log`

## Centralized Module Registry

### Registry Location

**Registry Directory:** `/etc/luigi/modules/`

Each installed module creates a registry entry: `/etc/luigi/modules/{module-path}.json`

**Examples:**
```
/etc/luigi/modules/motion-detection__mario.json
/etc/luigi/modules/iot__ha-mqtt.json
/etc/luigi/modules/system__management-api.json
/etc/luigi/modules/system__optimization.json
```

**Path Encoding:** Module paths use `__` (double underscore) as directory separator to avoid filesystem path issues.
- `motion-detection/mario` → `motion-detection__mario.json`
- `iot/ha-mqtt` → `iot__ha-mqtt.json`
- `sensors/dht22` → `sensors__dht22.json`

### Registry Entry Format

Each registry entry contains metadata about the installed module:

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
  "source_hash": "a3f5c9d2e1b4...",
  "capabilities": ["service", "hardware", "sensor", "config"],
  "dependencies": ["iot/ha-mqtt"],
  "apt_packages": ["python3-rpi.gpio", "alsa-utils"],
  "hardware": {
    "gpio_pins": [23],
    "sensors": ["HC-SR501"]
  },
  "provides": [],
  "service_name": "mario.service",
  "service_enabled": true,
  "config_path": "/etc/luigi/motion-detection/mario",
  "log_path": "/var/log/luigi/mario.log",
  "status": "active"
}
```

### Registry Entry Fields

#### Required Fields (Always Present)

- **`module_path`** (string): Full module path relative to repo root (e.g., "motion-detection/mario")
- **`name`** (string): Module name (directory name)
- **`version`** (string): Semantic version (e.g., "1.0.0")
- **`category`** (string): Module category (e.g., "motion-detection", "iot", "system")
- **`installed_at`** (string): ISO 8601 timestamp of initial installation
- **`updated_at`** (string): ISO 8601 timestamp of last update
- **`installed_by`** (string): What installed the module (e.g., "setup.sh", "management-api", "manual")
- **`status`** (string): Current status - "active", "installed", "failed", "removed"

#### Optional Fields (From module.json)

- **`description`** (string): Brief description of module purpose
- **`capabilities`** (array): Module capability types (see Capability System below)
- **`dependencies`** (array): List of module paths this module depends on
- **`apt_packages`** (array): List of apt packages required
- **`author`** (string): Module author/maintainer
- **`hardware`** (object): Hardware requirements
  - **`gpio_pins`** (array): GPIO pins used
  - **`sensors`** (array): Sensors/hardware components required
- **`provides`** (array): Commands, utilities, or services provided

## Module Capability System

The **capabilities** field declares what features and functionality a module provides. This enables dynamic management interfaces and automated feature discovery.

### Standard Capability Types

1. **`service`** - Module provides a systemd service
   - Indicates the module has a background daemon that can be managed
   - Management interfaces can show start/stop/restart controls
   - Example: mario (motion detection service), management-api (API server)

2. **`cli-tools`** - Module provides command-line utilities
   - Indicates the module installs executable scripts
   - Management interfaces can list and document available commands
   - Example: ha-mqtt (luigi-publish, luigi-discover, luigi-mqtt-status)

3. **`api`** - Module provides HTTP/REST API endpoints
   - Indicates the module exposes web services
   - Management interfaces can show API documentation
   - Example: management-api (REST API for system management)

4. **`config`** - Module has user-configurable settings
   - Indicates the module has configuration files
   - Management interfaces can show configuration editors
   - Example: most modules with `/etc/luigi/{module-path}/` configs

5. **`hardware`** - Module interacts with GPIO/hardware
   - Indicates the module requires physical hardware connections
   - Management interfaces can show wiring diagrams
   - Example: mario (PIR sensor), future relay/LED modules

6. **`sensor`** - Module provides sensor data
   - Indicates the module reads and publishes measurements
   - Management interfaces can show current values/graphs
   - Example: motion detection, temperature sensors, door sensors

7. **`integration`** - Module integrates with external systems
   - Indicates the module connects to third-party services
   - Management interfaces can show connection status
   - Example: ha-mqtt (Home Assistant), future cloud integrations

### Using Capabilities in Management Interfaces

**Frontend Example:**
```javascript
// React component showing dynamic controls based on capabilities
function ModuleCard({ module }) {
  const hasService = module.capabilities?.includes('service');
  const hasConfig = module.capabilities?.includes('config');
  const hasAPI = module.capabilities?.includes('api');
  
  return (
    <div className="module-card">
      <h3>{module.name}</h3>
      <p>{module.description}</p>
      
      {/* Show service controls only if module has service capability */}
      {hasService && (
        <div className="service-controls">
          <button onClick={() => startModule(module.name)}>Start</button>
          <button onClick={() => stopModule(module.name)}>Stop</button>
          <button onClick={() => restartModule(module.name)}>Restart</button>
        </div>
      )}
      
      {/* Show config button only if module is configurable */}
      {hasConfig && (
        <button onClick={() => editConfig(module.name)}>Configure</button>
      )}
      
      {/* Show API docs link only if module provides API */}
      {hasAPI && (
        <a href={`/api/docs/${module.name}`}>API Documentation</a>
      )}
    </div>
  );
}
```

**Query Modules by Capability:**
```bash
# Find all modules with service capability (can be started/stopped)
jq -r 'select(.capabilities[]? == "service") | .module_path' \
    /etc/luigi/modules/*.json

# Find all sensor modules for dashboard
jq -r 'select(.capabilities[]? == "sensor") | 
    {name, description, category}' /etc/luigi/modules/*.json

# Find all modules with API capability
jq -r 'select(.capabilities[]? == "api") | .name' \
    /etc/luigi/modules/*.json
```

**Management API Integration:**
```javascript
// API endpoint to get manageable services
app.get('/api/modules/services', async (req, res) => {
  const modules = await loadModules();
  const services = modules.filter(m => 
    m.capabilities?.includes('service')
  );
  res.json(services);
});

// API endpoint to get configurable modules
app.get('/api/modules/configurable', async (req, res) => {
  const modules = await loadModules();
  const configurable = modules.filter(m => 
    m.capabilities?.includes('config')
  );
  res.json(configurable);
});
```

### Capability Benefits

- **Dynamic UI:** Frontend shows/hides features based on module capabilities
- **Feature Discovery:** Tools can find modules by capability type
- **API Filtering:** Management APIs can filter modules by capability
- **Documentation:** Clear declaration of what each module provides
- **Extensibility:** New capability types can be added without breaking existing code

#### Installation Tracking Fields

- **`install_method`** (string): How module was installed
  - `"manual"` - Manually via setup.sh
  - `"auto"` - Auto-installed as dependency
  - `"api"` - Installed via management-api
  - `"script"` - Batch installation script
  
- **`source_hash`** (string): Hash of module source files at installation time
  - Used to detect if module source has changed
  - Can trigger update prompts
  - SHA256 of concatenated key files (setup.sh, module.json, main scripts)

#### Service and Runtime Fields

- **`service_name`** (string | null): Systemd service name if module has a service
- **`service_enabled`** (boolean | null): Whether service is enabled to start at boot
- **`config_path`** (string | null): Path to module configuration directory
- **`log_path`** (string | null): Path to module log file

### Registry Status Values

- **`active`** - Module is installed and service is running
- **`installed`** - Module is installed but service is not running (or no service)
- **`failed`** - Module installation or service startup failed
- **`removed`** - Module was uninstalled but registry entry preserved for history

## Module Lifecycle Management

### 1. Module Installation

**Process:**

1. **Pre-Installation Checks**
   - Verify module source exists
   - Check if module is already installed (check registry)
   - Validate module.json if present
   - Check system requirements (hardware, dependencies)

2. **Dependency Resolution**
   - Parse `module.json` dependencies array
   - Check if dependencies are installed (query registry)
   - Install missing dependencies first (recursive)
   - Detect and prevent circular dependencies

3. **Execute Installation**
   - Run module's `setup.sh install` command
   - Install apt packages
   - Deploy module files and resources
   - Create configuration directory
   - Install systemd service if applicable
   - Configure logging

4. **Registry Update**
   - Create registry entry in `/etc/luigi/modules/`
   - Record installation metadata
   - Calculate and store source hash
   - Set status to "active" or "installed"

5. **Post-Installation**
   - Start service if applicable
   - Enable service to start at boot
   - Verify installation success
   - Display installation summary

**Installation Command Pattern:**
```bash
# Manual installation
cd /home/pi/luigi/motion-detection/mario
sudo ./setup.sh install

# With registry update
sudo ./setup.sh install --update-registry

# Automated installation (with dependencies)
sudo /home/pi/luigi/util/install-module.sh motion-detection/mario
```

**Registry Update Function (Bash):**
```bash
update_module_registry() {
    local module_path="$1"
    local module_name="$2"
    local version="$3"
    local category="$4"
    
    # Encode path for filename
    local registry_file="/etc/luigi/modules/${module_path/\//__}.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    # Create registry directory if needed
    mkdir -p /etc/luigi/modules
    
    # Build registry entry
    cat > "$registry_file" <<EOF
{
  "module_path": "$module_path",
  "name": "$module_name",
  "version": "$version",
  "category": "$category",
  "installed_at": "$timestamp",
  "updated_at": "$timestamp",
  "installed_by": "setup.sh",
  "install_method": "manual",
  "status": "installed"
}
EOF
    
    log_info "Updated module registry: $registry_file"
}
```

### 2. Module Updates

**Update Detection:**

Modules need updates when:
- Version in `module.json` is newer than registry version
- Source hash differs from registry hash
- Dependencies have been updated
- User explicitly requests update

**Update Process:**

1. **Pre-Update Checks**
   - Check registry for current version
   - Compare with source version
   - Check if dependencies need updates
   - Backup current configuration

2. **Execute Update**
   - Run `setup.sh install` (idempotent installation)
   - Update files while preserving configuration
   - Update service files if changed
   - Restart services if needed

3. **Registry Update**
   - Update `version` field
   - Update `updated_at` timestamp
   - Update `source_hash`
   - Preserve `installed_at` timestamp
   - Update dependencies if changed

4. **Post-Update**
   - Verify service restart if applicable
   - Check for configuration migration needs
   - Display update summary

**Update Command Pattern:**
```bash
# Manual update
cd /home/pi/luigi/motion-detection/mario
sudo ./setup.sh install  # Setup script is idempotent

# Update with version check
sudo /home/pi/luigi/util/update-module.sh motion-detection/mario

# Batch update all modules
sudo /home/pi/luigi/util/update-all-modules.sh
```

### 3. Module Removal

**Removal Process:**

1. **Pre-Removal Checks**
   - Check registry for module status
   - Check if other modules depend on this one
   - Warn about dependent modules
   - Confirm removal with user

2. **Execute Removal**
   - Stop service if running
   - Disable service from boot
   - Remove service file
   - Optionally remove configuration (prompt user)
   - Optionally remove logs (prompt user)
   - Run cleanup scripts if present

3. **Registry Update**
   - Update status to "removed"
   - Keep registry entry for history
   - Record removal timestamp
   - Preserve installation history

4. **Post-Removal**
   - Display removal summary
   - List any preserved files (configs, logs)
   - Suggest removing dependencies if no longer needed

**Removal Command Pattern:**
```bash
# Remove module (keep config and logs)
sudo /home/pi/luigi/util/remove-module.sh motion-detection/mario

# Remove with config cleanup
sudo /home/pi/luigi/util/remove-module.sh motion-detection/mario --purge

# Check dependencies before removal
sudo /home/pi/luigi/util/remove-module.sh motion-detection/mario --check-deps
```

### 4. Module Status and Queries

**Query Operations:**

**List All Installed Modules:**
```bash
# List all installed modules from registry
ls -1 /etc/luigi/modules/*.json | sed 's|/etc/luigi/modules/||; s|\.json$||; s|__|/|g'

# With versions (using jq)
for file in /etc/luigi/modules/*.json; do
    jq -r '"\(.module_path) - v\(.version) - \(.status)"' "$file"
done
```

**Get Module Details:**
```bash
# Get registry entry for specific module
cat /etc/luigi/modules/motion-detection__mario.json | jq '.'

# Get only version
jq -r '.version' /etc/luigi/modules/motion-detection__mario.json
```

**Check Module Status:**
```bash
# Check if module is installed
test -f /etc/luigi/modules/motion-detection__mario.json && echo "Installed" || echo "Not installed"

# Check service status
systemctl status mario.service
```

**Find Modules by Category:**
```bash
# List all motion-detection modules
jq -r 'select(.category == "motion-detection") | .module_path' /etc/luigi/modules/*.json
```

**Find Dependent Modules:**
```bash
# Find modules that depend on ha-mqtt
jq -r 'select(.dependencies[]? == "iot/ha-mqtt") | .module_path' /etc/luigi/modules/*.json
```

## Dependency Management

### Dependency Resolution Algorithm

**Installation Order:**

1. Parse target module's `module.json` dependencies
2. For each dependency:
   - Check if dependency is installed (query registry)
   - If not installed, recursively install dependency first
   - Detect circular dependencies
3. Install target module after all dependencies

**Example:**
```
Install: motion-detection/mario
├─ Depends on: iot/ha-mqtt
│  ├─ Depends on: [] (no dependencies)
│  └─ Install iot/ha-mqtt first
└─ Install motion-detection/mario

Result order: iot/ha-mqtt → motion-detection/mario
```

### Circular Dependency Detection

**Algorithm:**
```bash
check_circular_deps() {
    local module="$1"
    local chain="$2"
    
    # Check if module is already in the dependency chain
    if echo "$chain" | grep -q ":$module:"; then
        echo "Circular dependency detected: $chain → $module"
        return 1
    fi
    
    # Read module dependencies
    local deps=$(jq -r '.dependencies[]?' "$module/module.json" 2>/dev/null)
    
    # Recursively check each dependency
    for dep in $deps; do
        check_circular_deps "$dep" "$chain:$module"
    done
}
```

### Dependency Validation

**Before Installation:**
- Verify all dependencies exist in repository
- Check if dependencies are already installed
- Validate dependency versions if specified
- Ensure no circular dependencies

**During Updates:**
- Check if dependency updates are needed
- Update dependencies first if required
- Validate compatibility after updates

## Version Management

### Semantic Versioning

Luigi modules use **semantic versioning** (semver): `MAJOR.MINOR.PATCH`

- **MAJOR:** Breaking changes (incompatible updates)
- **MINOR:** New features (backward compatible)
- **PATCH:** Bug fixes (backward compatible)

**Examples:**
- `1.0.0` - Initial release
- `1.1.0` - Added new feature
- `1.1.1` - Bug fix
- `2.0.0` - Breaking change

### Version Comparison

**Check if Update Available:**
```bash
# Compare versions (requires semver comparison function)
current_version=$(jq -r '.version' /etc/luigi/modules/motion-detection__mario.json)
source_version=$(jq -r '.version' /home/pi/luigi/motion-detection/mario/module.json)

if [ "$source_version" != "$current_version" ]; then
    echo "Update available: $current_version → $source_version"
fi
```

### Version History

**Tracking Version Changes:**

Registry maintains installation history:
- `installed_at` - Original installation time (never changes)
- `updated_at` - Last update time (changes on each update)
- `version` - Current version (changes on update)

**Best Practice:** Implement version history log:
```bash
# Append to version history
echo "$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ") - Updated $module_path from $old_version to $new_version" \
    >> /var/log/luigi/module-updates.log
```

## Module Management API Integration

### Management API Service

The `system/management-api` module provides REST API for module management:

**Endpoints:**
- `GET /api/modules` - List all modules
- `GET /api/modules/:name` - Get module details and status
- `POST /api/modules/:name/start` - Start module service
- `POST /api/modules/:name/stop` - Stop module service
- `POST /api/modules/:name/restart` - Restart module service
- `GET /api/modules/:name/logs` - Get module logs

**Module Service Implementation:**
```javascript
// src/services/moduleService.js

async function listModules() {
  // 1. Scan source directory for modules (setup.sh detection)
  // 2. Read module.json metadata
  // 3. Query registry for installation status
  // 4. Merge source and registry data
  // 5. Return combined module list
}

async function getModuleDetails(moduleName) {
  // 1. Find module in source directory
  // 2. Read registry entry
  // 3. Get systemd service status
  // 4. Return complete module information
}
```

**Enhancing API with Registry:**

Modify `moduleService.js` to use registry:

```javascript
const fs = require('fs').promises;
const path = require('path');

const REGISTRY_PATH = '/etc/luigi/modules';

async function getRegistryEntry(modulePath) {
  try {
    const filename = modulePath.replace(/\//g, '__') + '.json';
    const filepath = path.join(REGISTRY_PATH, filename);
    const content = await fs.readFile(filepath, 'utf8');
    return JSON.parse(content);
  } catch (err) {
    return null; // Module not installed
  }
}

async function listInstalledModules() {
  try {
    const files = await fs.readdir(REGISTRY_PATH);
    const modules = [];
    
    for (const file of files) {
      if (file.endsWith('.json')) {
        const filepath = path.join(REGISTRY_PATH, file);
        const content = await fs.readFile(filepath, 'utf8');
        const entry = JSON.parse(content);
        if (entry.status !== 'removed') {
          modules.push(entry);
        }
      }
    }
    
    return modules;
  } catch (err) {
    return [];
  }
}
```

## Module Management Utilities

### Utility Script: list-modules.sh

**Purpose:** List all installed modules with versions and status

**Location:** `/home/pi/luigi/util/list-modules.sh`

**Implementation:**
```bash
#!/bin/bash
################################################################################
# List Modules - Display all installed Luigi modules
#
# Reads the centralized module registry and displays module information
#
# Usage: ./list-modules.sh [--format json|table]
#
# Author: Luigi Project
# License: MIT
################################################################################

set -e

REGISTRY_PATH="/etc/luigi/modules"

# Default format
FORMAT="${1:-table}"

list_modules_json() {
    echo "["
    local first=true
    for file in "$REGISTRY_PATH"/*.json; do
        [ -f "$file" ] || continue
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi
        cat "$file"
    done
    echo "]"
}

list_modules_table() {
    printf "%-40s %-15s %-12s\n" "MODULE PATH" "VERSION" "STATUS"
    printf "%-40s %-15s %-12s\n" "----------------------------------------" "---------------" "------------"
    
    for file in "$REGISTRY_PATH"/*.json; do
        [ -f "$file" ] || continue
        
        module_path=$(jq -r '.module_path' "$file")
        version=$(jq -r '.version' "$file")
        status=$(jq -r '.status' "$file")
        
        printf "%-40s %-15s %-12s\n" "$module_path" "$version" "$status"
    done
}

case "$FORMAT" in
    json)
        list_modules_json
        ;;
    table)
        list_modules_table
        ;;
    *)
        echo "Error: Invalid format '$FORMAT'. Use 'json' or 'table'."
        exit 1
        ;;
esac
```

### Utility Script: module-info.sh

**Purpose:** Display detailed information about a specific module

**Location:** `/home/pi/luigi/util/module-info.sh`

**Implementation:**
```bash
#!/bin/bash
################################################################################
# Module Info - Display detailed module information
#
# Shows both source and registry information for a module
#
# Usage: ./module-info.sh <module-path>
#   Example: ./module-info.sh motion-detection/mario
#
# Author: Luigi Project
# License: MIT
################################################################################

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <module-path>"
    echo "Example: $0 motion-detection/mario"
    exit 1
fi

MODULE_PATH="$1"
REGISTRY_FILE="/etc/luigi/modules/${MODULE_PATH/\//__}.json"
SOURCE_DIR="/home/pi/luigi/$MODULE_PATH"

echo "Module: $MODULE_PATH"
echo "========================================"

# Check if installed
if [ -f "$REGISTRY_FILE" ]; then
    echo ""
    echo "INSTALLATION STATUS: Installed"
    echo ""
    echo "Registry Information:"
    echo "---------------------"
    jq '.' "$REGISTRY_FILE"
else
    echo ""
    echo "INSTALLATION STATUS: Not Installed"
fi

# Check if source exists
if [ -d "$SOURCE_DIR" ]; then
    echo ""
    echo "Source Information:"
    echo "-------------------"
    if [ -f "$SOURCE_DIR/module.json" ]; then
        jq '.' "$SOURCE_DIR/module.json"
    else
        echo "No module.json found in source"
    fi
else
    echo ""
    echo "Source directory not found: $SOURCE_DIR"
fi

# Check service status if installed
if [ -f "$REGISTRY_FILE" ]; then
    SERVICE_NAME=$(jq -r '.service_name // empty' "$REGISTRY_FILE")
    if [ -n "$SERVICE_NAME" ]; then
        echo ""
        echo "Service Status:"
        echo "---------------"
        systemctl status "$SERVICE_NAME" --no-pager || true
    fi
fi
```

### Utility Script: check-updates.sh

**Purpose:** Check for available module updates

**Location:** `/home/pi/luigi/util/check-updates.sh`

**Implementation:**
```bash
#!/bin/bash
################################################################################
# Check Updates - Check for available module updates
#
# Compares registry versions with source versions
#
# Usage: ./check-updates.sh [module-path]
#   No args: Check all modules
#   With arg: Check specific module
#
# Author: Luigi Project
# License: MIT
################################################################################

set -e

REGISTRY_PATH="/etc/luigi/modules"
SOURCE_ROOT="/home/pi/luigi"

check_module_update() {
    local registry_file="$1"
    
    local module_path=$(jq -r '.module_path' "$registry_file")
    local current_version=$(jq -r '.version' "$registry_file")
    local status=$(jq -r '.status' "$registry_file")
    
    # Skip removed modules
    [ "$status" = "removed" ] && return 0
    
    local source_dir="$SOURCE_ROOT/$module_path"
    local source_json="$source_dir/module.json"
    
    if [ ! -f "$source_json" ]; then
        echo "⚠️  $module_path - No source metadata (current: v$current_version)"
        return 0
    fi
    
    local source_version=$(jq -r '.version' "$source_json")
    
    if [ "$source_version" != "$current_version" ]; then
        echo "🔄 $module_path - Update available: v$current_version → v$source_version"
    else
        echo "✅ $module_path - Up to date (v$current_version)"
    fi
}

if [ $# -eq 1 ]; then
    # Check specific module
    MODULE_PATH="$1"
    REGISTRY_FILE="$REGISTRY_PATH/${MODULE_PATH/\//__}.json"
    
    if [ ! -f "$REGISTRY_FILE" ]; then
        echo "Error: Module '$MODULE_PATH' is not installed"
        exit 1
    fi
    
    check_module_update "$REGISTRY_FILE"
else
    # Check all modules
    echo "Checking for module updates..."
    echo ""
    
    for file in "$REGISTRY_PATH"/*.json; do
        [ -f "$file" ] || continue
        check_module_update "$file"
    done
fi
```

## Best Practices

### 1. Always Update Registry

**Every module installation must update the registry:**
- Create or update registry entry in `/etc/luigi/modules/`
- Record accurate version and timestamp
- Set appropriate status
- Include all relevant metadata

### 2. Idempotent Installations

**Setup scripts must be idempotent:**
- Running `setup.sh install` multiple times should be safe
- Update existing installations rather than failing
- Preserve user configuration
- Update registry on each run

### 3. Dependency First

**Always install dependencies before the module:**
- Parse `dependencies` from module.json
- Check registry for installation status
- Install missing dependencies recursively
- Fail installation if dependencies cannot be satisfied

### 4. Graceful Degradation

**Handle missing optional dependencies:**
- Some dependencies may be optional (e.g., ha-mqtt integration)
- Module should work without optional dependencies
- Log warnings about missing optional features
- Don't list optional dependencies in `dependencies` array

### 5. Configuration Preservation

**Never overwrite user configuration:**
- Check if config exists before creating
- Prompt user for confirmation if overwriting
- Backup existing config before updates
- Document configuration changes in update notes

### 6. Service Management

**Proper service lifecycle:**
- Stop service before updating
- Reload systemd after service file changes
- Start service after successful installation
- Enable service to start at boot
- Record service status in registry

### 7. Cleanup on Failure

**If installation fails:**
- Roll back partial installations
- Clean up temporary files
- Update registry status to "failed"
- Log error details for troubleshooting
- Leave system in consistent state

### 8. Version Validation

**Validate versions:**
- Use semantic versioning (MAJOR.MINOR.PATCH)
- Validate version format in module.json
- Compare versions properly (not string comparison)
- Document version compatibility requirements

## Common Module Management Tasks

### Task: Install New Module

```bash
# 1. Navigate to module directory
cd /home/pi/luigi/motion-detection/mario

# 2. Run setup script
sudo ./setup.sh install

# 3. Verify installation
sudo /home/pi/luigi/util/module-info.sh motion-detection/mario

# 4. Check service status
sudo systemctl status mario.service
```

### Task: Update Existing Module

```bash
# 1. Check for updates
sudo /home/pi/luigi/util/check-updates.sh motion-detection/mario

# 2. Pull latest code (if using git)
cd /home/pi/luigi
git pull

# 3. Run setup again (idempotent)
cd motion-detection/mario
sudo ./setup.sh install

# 4. Verify update
sudo /home/pi/luigi/util/module-info.sh motion-detection/mario
```

### Task: Remove Module

```bash
# 1. Check dependencies
jq -r 'select(.dependencies[]? == "motion-detection/mario") | .module_path' \
    /etc/luigi/modules/*.json

# 2. Stop service
sudo systemctl stop mario.service
sudo systemctl disable mario.service

# 3. Remove service file
sudo rm /etc/systemd/system/mario.service
sudo systemctl daemon-reload

# 4. Update registry status
sudo jq '.status = "removed" | .updated_at = "'"$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")"'"' \
    /etc/luigi/modules/motion-detection__mario.json > /tmp/registry.json
sudo mv /tmp/registry.json /etc/luigi/modules/motion-detection__mario.json

# 5. Optionally remove config and logs
# sudo rm -rf /etc/luigi/motion-detection/mario
# sudo rm /var/log/luigi/mario.log
```

### Task: List All Modules

```bash
# Simple list
sudo /home/pi/luigi/util/list-modules.sh

# JSON output for scripting
sudo /home/pi/luigi/util/list-modules.sh json | jq '.'

# Filter by category
jq -r 'select(.category == "iot") | "\(.module_path) - v\(.version)"' \
    /etc/luigi/modules/*.json
```

### Task: Batch Update All Modules

```bash
# Check all for updates
sudo /home/pi/luigi/util/check-updates.sh

# Update all with script
for file in /etc/luigi/modules/*.json; do
    module_path=$(jq -r '.module_path' "$file")
    status=$(jq -r '.status' "$file")
    
    # Skip removed modules
    [ "$status" = "removed" ] && continue
    
    echo "Updating $module_path..."
    cd "/home/pi/luigi/$module_path"
    sudo ./setup.sh install
done
```

## Integration with Management API

### Enhance moduleService.js

Add registry integration to existing module service:

```javascript
// At the top with other requires
const REGISTRY_PATH = '/etc/luigi/modules';

/**
 * Get registry entry for a module
 */
async function getRegistryEntry(modulePath) {
  try {
    const filename = modulePath.replace(/\//g, '__') + '.json';
    const filepath = path.join(REGISTRY_PATH, filename);
    const content = await fs.readFile(filepath, 'utf8');
    return JSON.parse(content);
  } catch (err) {
    return null; // Not installed
  }
}

/**
 * List modules with registry data
 */
async function listModulesWithRegistry() {
  const sourceModules = await listModules(); // Existing function
  const enrichedModules = [];
  
  for (const module of sourceModules) {
    const registryEntry = await getRegistryEntry(module.path);
    
    enrichedModules.push({
      ...module,
      installed: registryEntry !== null,
      installedVersion: registryEntry?.version,
      installedAt: registryEntry?.installed_at,
      updatedAt: registryEntry?.updated_at,
      registryStatus: registryEntry?.status,
      hasUpdate: registryEntry && module.metadata?.version !== registryEntry.version
    });
  }
  
  return enrichedModules;
}

/**
 * Create or update registry entry
 */
async function updateRegistry(moduleData) {
  try {
    const filename = moduleData.path.replace(/\//g, '__') + '.json';
    const filepath = path.join(REGISTRY_PATH, filename);
    
    // Ensure registry directory exists
    await fs.mkdir(REGISTRY_PATH, { recursive: true });
    
    // Read existing entry if present
    let existingEntry = null;
    try {
      const content = await fs.readFile(filepath, 'utf8');
      existingEntry = JSON.parse(content);
    } catch (err) {
      // No existing entry
    }
    
    const now = new Date().toISOString();
    
    const registryEntry = {
      module_path: moduleData.path,
      name: moduleData.name,
      version: moduleData.metadata?.version || '0.0.0',
      category: moduleData.category,
      description: moduleData.metadata?.description || '',
      installed_at: existingEntry?.installed_at || now,
      updated_at: now,
      installed_by: 'management-api',
      install_method: 'api',
      status: 'installed',
      dependencies: moduleData.metadata?.dependencies || [],
      apt_packages: moduleData.metadata?.apt_packages || [],
      hardware: moduleData.metadata?.hardware || null,
      provides: moduleData.metadata?.provides || [],
      service_name: `${moduleData.name}.service`,
      config_path: `/etc/luigi/${moduleData.path}`,
      log_path: `/var/log/luigi/${moduleData.name}.log`
    };
    
    await fs.writeFile(filepath, JSON.stringify(registryEntry, null, 2));
    logger.info(`Updated registry for module: ${moduleData.path}`);
    
    return registryEntry;
  } catch (error) {
    logger.error(`Failed to update registry for ${moduleData.path}: ${error.message}`);
    throw error;
  }
}

module.exports = {
  listModules,
  listModulesWithRegistry,
  getRegistryEntry,
  updateRegistry,
  // ... other exports
};
```

## Troubleshooting

### Registry Not Found

**Problem:** `/etc/luigi/modules/` directory doesn't exist

**Solution:**
```bash
sudo mkdir -p /etc/luigi/modules
sudo chmod 755 /etc/luigi/modules
```

### Module Shows as Not Installed Despite Running

**Problem:** Service is running but no registry entry exists

**Solution:**
```bash
# Manually create registry entry
cd /home/pi/luigi/motion-detection/mario
sudo ./setup.sh install  # Re-run setup to create registry entry
```

### Version Mismatch Between Source and Registry

**Problem:** Registry shows old version, source has new version

**Solution:**
```bash
# Re-run setup to update registry
cd /home/pi/luigi/motion-detection/mario
sudo ./setup.sh install
```

### Orphaned Registry Entries

**Problem:** Registry entry exists but module source removed

**Solution:**
```bash
# Update status to removed
sudo jq '.status = "removed"' \
    /etc/luigi/modules/motion-detection__mario.json > /tmp/temp.json
sudo mv /tmp/temp.json /etc/luigi/modules/motion-detection__mario.json
```

## Migration Guide

### Adding Registry to Existing Installations

For systems with modules already installed without registry:

```bash
#!/bin/bash
# migrate-to-registry.sh - Create registry entries for existing modules

REPO_ROOT="/home/pi/luigi"
REGISTRY_PATH="/etc/luigi/modules"

# Create registry directory
mkdir -p "$REGISTRY_PATH"

# Find all modules
find "$REPO_ROOT" -name "setup.sh" -type f | while read setup_file; do
    module_dir=$(dirname "$setup_file")
    module_path=$(realpath --relative-to="$REPO_ROOT" "$module_dir")
    module_name=$(basename "$module_dir")
    category=$(echo "$module_path" | cut -d'/' -f1)
    
    echo "Migrating: $module_path"
    
    # Read module.json if exists
    version="0.0.0"
    description=""
    if [ -f "$module_dir/module.json" ]; then
        version=$(jq -r '.version // "0.0.0"' "$module_dir/module.json")
        description=$(jq -r '.description // ""' "$module_dir/module.json")
    fi
    
    # Check if service is running
    service_name="${module_name}.service"
    status="installed"
    if systemctl is-active "$service_name" &>/dev/null; then
        status="active"
    fi
    
    # Create registry entry
    registry_file="$REGISTRY_PATH/${module_path/\//__}.json"
    cat > "$registry_file" <<EOF
{
  "module_path": "$module_path",
  "name": "$module_name",
  "version": "$version",
  "category": "$category",
  "description": "$description",
  "installed_at": "$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")",
  "updated_at": "$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")",
  "installed_by": "migration",
  "install_method": "manual",
  "status": "$status",
  "service_name": "$service_name",
  "config_path": "/etc/luigi/$module_path",
  "log_path": "/var/log/luigi/${module_name}.log"
}
EOF
    
    echo "Created: $registry_file"
done

echo ""
echo "Migration complete!"
echo "Installed modules:"
ls -1 "$REGISTRY_PATH"/*.json | wc -l
```

## See Also

- **Module Design Skill** (`.github/skills/module-design/`) - Designing new modules
- **Shell Scripting Skill** (`.github/skills/shell-scripting/`) - Writing setup scripts
- **System Setup Skill** (`.github/skills/system-setup/`) - Deployment automation
- **MODULE_SCHEMA.md** - Module metadata schema documentation
- **Management API** (`system/management-api/`) - REST API for module management
