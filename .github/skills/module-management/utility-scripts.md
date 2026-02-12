# Module Management Utility Scripts

This directory contains reference implementations of utility scripts for Luigi module management. These scripts demonstrate best practices for working with the centralized module registry.

## Utility Scripts

### Core Management Scripts

1. **list-modules.sh** - List all installed modules with versions and status
2. **module-info.sh** - Display detailed information about a specific module
3. **check-updates.sh** - Check for available module updates
4. **install-module.sh** - Install a module with dependency resolution
5. **update-module.sh** - Update a module to latest version
6. **remove-module.sh** - Remove a module safely
7. **registry-migrate.sh** - Migrate existing installations to use registry

### Registry Management Scripts

8. **validate-registry.sh** - Validate all registry entries
9. **cleanup-registry.sh** - Clean up orphaned registry entries
10. **export-registry.sh** - Export registry to JSON for backup
11. **import-registry.sh** - Import registry from backup

## Installation

These scripts should be placed in `/home/pi/luigi/util/` directory:

```bash
# Copy scripts to util directory
sudo cp *.sh /home/pi/luigi/util/
sudo chmod +x /home/pi/luigi/util/*.sh

# Verify installation
ls -l /home/pi/luigi/util/*.sh
```

## Usage Examples

### List All Modules

```bash
# Table format (default)
/home/pi/luigi/util/list-modules.sh

# JSON format
/home/pi/luigi/util/list-modules.sh json
```

### Get Module Information

```bash
/home/pi/luigi/util/module-info.sh motion-detection/mario
```

### Check for Updates

```bash
# Check all modules
/home/pi/luigi/util/check-updates.sh

# Check specific module
/home/pi/luigi/util/check-updates.sh motion-detection/mario
```

### Install Module with Dependencies

```bash
sudo /home/pi/luigi/util/install-module.sh motion-detection/mario
```

### Update Module

```bash
sudo /home/pi/luigi/util/update-module.sh motion-detection/mario
```

### Remove Module

```bash
# Remove module, keep configuration
sudo /home/pi/luigi/util/remove-module.sh motion-detection/mario

# Remove with configuration cleanup
sudo /home/pi/luigi/util/remove-module.sh motion-detection/mario --purge

# Check dependencies before removal
sudo /home/pi/luigi/util/remove-module.sh motion-detection/mario --check-deps
```

### Migrate to Registry

```bash
# Migrate all existing modules to use registry
sudo /home/pi/luigi/util/registry-migrate.sh

# Dry run (show what would be done)
sudo /home/pi/luigi/util/registry-migrate.sh --dry-run
```

### Validate Registry

```bash
# Validate all registry entries
sudo /home/pi/luigi/util/validate-registry.sh

# Validate specific module
sudo /home/pi/luigi/util/validate-registry.sh motion-detection/mario
```

### Cleanup Registry

```bash
# Clean up orphaned entries (modules removed from source)
sudo /home/pi/luigi/util/cleanup-registry.sh

# Dry run
sudo /home/pi/luigi/util/cleanup-registry.sh --dry-run
```

### Export/Import Registry

```bash
# Export registry to backup file
sudo /home/pi/luigi/util/export-registry.sh /backup/luigi-registry-$(date +%Y%m%d).json

# Import registry from backup
sudo /home/pi/luigi/util/import-registry.sh /backup/luigi-registry-20260212.json
```

## Script Implementation Details

### list-modules.sh

**Features:**
- Lists all installed modules from registry
- Supports table and JSON output formats
- Filters out removed modules by default
- Shows module path, version, and status

**Output Example (Table):**
```
MODULE PATH                              VERSION         STATUS
---------------------------------------- --------------- ------------
iot/ha-mqtt                             1.0.0           installed
motion-detection/mario                  1.0.0           active
system/management-api                   1.0.0           active
system/optimization                     1.0.0           installed
```

### module-info.sh

**Features:**
- Displays complete module information
- Shows both registry and source metadata
- Includes service status if applicable
- Compares registry vs source versions

**Output Example:**
```
Module: motion-detection/mario
========================================

INSTALLATION STATUS: Installed

Registry Information:
---------------------
{
  "module_path": "motion-detection/mario",
  "version": "1.0.0",
  "status": "active",
  ...
}

Source Information:
-------------------
{
  "name": "mario",
  "version": "1.0.0",
  ...
}

Service Status:
---------------
● mario.service - Mario Motion Detection
   Loaded: loaded (/etc/systemd/system/mario.service; enabled)
   Active: active (running)
```

### check-updates.sh

**Features:**
- Compares registry versions with source versions
- Checks all modules or specific module
- Visual indicators for status (✅ up to date, 🔄 update available)
- Lists modules missing source metadata

**Output Example:**
```
Checking for module updates...

✅ iot/ha-mqtt - Up to date (v1.0.0)
🔄 motion-detection/mario - Update available: v1.0.0 → v1.1.0
✅ system/optimization - Up to date (v1.0.0)
⚠️  system/management-api - No source metadata (current: v1.0.0)
```

### install-module.sh

**Features:**
- Installs module with dependency resolution
- Checks if module is already installed
- Installs dependencies recursively
- Updates registry after installation
- Verifies installation success

**Usage:**
```bash
sudo ./install-module.sh <module-path>
```

### update-module.sh

**Features:**
- Updates module to latest version from source
- Checks if update is needed
- Preserves configuration
- Updates dependencies if needed
- Updates registry with new version

**Usage:**
```bash
sudo ./update-module.sh <module-path>
```

### remove-module.sh

**Features:**
- Safely removes module
- Checks for dependent modules
- Stops and disables service
- Optionally removes configuration (--purge)
- Updates registry status to "removed"
- Preserves registry entry for history

**Usage:**
```bash
sudo ./remove-module.sh <module-path> [--purge] [--check-deps]
```

### registry-migrate.sh

**Features:**
- Creates registry entries for existing installations
- Detects modules via setup.sh files
- Reads metadata from module.json
- Checks service status
- Supports dry-run mode

**Usage:**
```bash
sudo ./registry-migrate.sh [--dry-run]
```

### validate-registry.sh

**Features:**
- Validates JSON syntax
- Checks required fields
- Validates field formats (versions, timestamps)
- Verifies module paths exist
- Reports all validation errors

**Usage:**
```bash
sudo ./validate-registry.sh [module-path]
```

### cleanup-registry.sh

**Features:**
- Finds orphaned registry entries
- Marks missing modules as "removed"
- Optionally deletes removed entries
- Supports dry-run mode

**Usage:**
```bash
sudo ./cleanup-registry.sh [--dry-run] [--delete-removed]
```

## Integration with Setup Scripts

### Adding Registry Support to setup.sh

Module setup scripts should update the registry on installation:

```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source shared helpers
source "$REPO_ROOT/util/setup-helpers.sh"

# Module information
MODULE_PATH="motion-detection/mario"
MODULE_NAME="mario"
CATEGORY="motion-detection"

# Read version from module.json
VERSION=$(jq -r '.version' "$SCRIPT_DIR/module.json")

# ... installation logic ...

# Update registry
update_registry_entry() {
    log_step "Updating module registry"
    
    local registry_file="/etc/luigi/modules/${MODULE_PATH/\//__}.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    # Create registry directory
    mkdir -p /etc/luigi/modules
    
    # Check if entry exists (for installed_at preservation)
    local installed_at="$timestamp"
    if [ -f "$registry_file" ]; then
        installed_at=$(jq -r '.installed_at' "$registry_file")
    fi
    
    # Read metadata from module.json
    local metadata=$(cat "$SCRIPT_DIR/module.json")
    
    # Create registry entry
    cat > "$registry_file" <<EOF
{
  "module_path": "$MODULE_PATH",
  "name": "$MODULE_NAME",
  "version": "$VERSION",
  "category": "$CATEGORY",
  "description": $(echo "$metadata" | jq -r '.description // ""' | jq -R .),
  "installed_at": "$installed_at",
  "updated_at": "$timestamp",
  "installed_by": "setup.sh",
  "install_method": "manual",
  "status": "installed",
  "dependencies": $(echo "$metadata" | jq '.dependencies // []'),
  "apt_packages": $(echo "$metadata" | jq '.apt_packages // []'),
  "author": $(echo "$metadata" | jq -r '.author // ""' | jq -R .),
  "hardware": $(echo "$metadata" | jq '.hardware // null'),
  "provides": $(echo "$metadata" | jq '.provides // []'),
  "service_name": "$MODULE_NAME.service",
  "service_enabled": true,
  "config_path": "/etc/luigi/$MODULE_PATH",
  "log_path": "/var/log/luigi/$MODULE_NAME.log"
}
EOF
    
    log_success "Registry updated: $registry_file"
}

# Call during installation
install() {
    log_header "Installing $MODULE_NAME module"
    
    # ... installation steps ...
    
    # Update registry
    update_registry_entry
    
    # Update status to active if service started
    if systemctl is-active "$MODULE_NAME.service" &>/dev/null; then
        jq '.status = "active"' "$registry_file" > /tmp/registry.json
        mv /tmp/registry.json "$registry_file"
    fi
    
    log_success "Installation complete!"
}
```

### Registry Helper Functions

Add to `util/setup-helpers.sh`:

```bash
# Update module registry entry
update_module_registry() {
    local module_path="$1"
    local version="$2"
    local status="${3:-installed}"
    
    local name=$(basename "$module_path")
    local category=$(dirname "$module_path")
    local registry_file="/etc/luigi/modules/${module_path/\//__}.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    # Preserve installed_at if exists
    local installed_at="$timestamp"
    if [ -f "$registry_file" ]; then
        installed_at=$(jq -r '.installed_at' "$registry_file")
    fi
    
    mkdir -p /etc/luigi/modules
    
    cat > "$registry_file" <<EOF
{
  "module_path": "$module_path",
  "name": "$name",
  "version": "$version",
  "category": "$category",
  "installed_at": "$installed_at",
  "updated_at": "$timestamp",
  "installed_by": "setup.sh",
  "install_method": "manual",
  "status": "$status"
}
EOF
}

# Check if module is installed
is_module_installed() {
    local module_path="$1"
    local registry_file="/etc/luigi/modules/${module_path/\//__}.json"
    
    [ -f "$registry_file" ] && [ "$(jq -r '.status' "$registry_file")" != "removed" ]
}

# Get installed module version
get_installed_version() {
    local module_path="$1"
    local registry_file="/etc/luigi/modules/${module_path/\//__}.json"
    
    if [ -f "$registry_file" ]; then
        jq -r '.version' "$registry_file"
    else
        echo "0.0.0"
    fi
}

# Mark module as removed in registry
mark_module_removed() {
    local module_path="$1"
    local registry_file="/etc/luigi/modules/${module_path/\//__}.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    if [ -f "$registry_file" ]; then
        jq ".status = \"removed\" | .updated_at = \"$timestamp\" | .service_enabled = false" \
            "$registry_file" > /tmp/registry.json
        mv /tmp/registry.json "$registry_file"
    fi
}
```

## Best Practices

### 1. Always Update Registry

Every installation, update, or removal should update the registry:
- Create entry on installation
- Update entry on reinstallation/update
- Mark as removed on uninstallation (don't delete)

### 2. Preserve History

Never delete registry entries:
- Mark as "removed" instead of deleting
- Preserve `installed_at` timestamp on updates
- Keep installation history for auditing

### 3. Validate Input

Always validate before operating on modules:
- Check module path format
- Verify module exists in source
- Validate version format
- Check required fields in registry

### 4. Handle Errors Gracefully

Fail safely and leave system in consistent state:
- Use transactions where possible
- Roll back on failure
- Update registry status to "failed" on errors
- Log detailed error messages

### 5. Use Atomic Operations

Make registry updates atomic:
- Write to temp file first
- Move to final location (atomic operation)
- Verify after write

### 6. Check Dependencies

Before installation or removal:
- Check module dependencies
- Install dependencies first
- Warn about dependent modules on removal
- Prevent removal if other modules depend on it

## Testing

### Test Registry Operations

```bash
# Test create
sudo /home/pi/luigi/util/install-module.sh test/dummy
test -f /etc/luigi/modules/test__dummy.json && echo "✅ Create OK" || echo "❌ Create failed"

# Test update
sudo /home/pi/luigi/util/update-module.sh test/dummy
version=$(jq -r '.version' /etc/luigi/modules/test__dummy.json)
echo "Version: $version"

# Test removal
sudo /home/pi/luigi/util/remove-module.sh test/dummy
status=$(jq -r '.status' /etc/luigi/modules/test__dummy.json)
[ "$status" = "removed" ] && echo "✅ Remove OK" || echo "❌ Remove failed"
```

### Validate Registry Integrity

```bash
# Validate all entries
sudo /home/pi/luigi/util/validate-registry.sh

# Check for orphaned entries
sudo /home/pi/luigi/util/cleanup-registry.sh --dry-run
```

## Troubleshooting

### Registry Directory Missing

```bash
sudo mkdir -p /etc/luigi/modules
sudo chmod 755 /etc/luigi/modules
```

### Corrupted Registry Entry

```bash
# Validate and fix
sudo /home/pi/luigi/util/validate-registry.sh motion-detection/mario

# Or recreate from source
cd /home/pi/luigi/motion-detection/mario
sudo ./setup.sh install
```

### Orphaned Registry Entries

```bash
# Clean up
sudo /home/pi/luigi/util/cleanup-registry.sh
```

## See Also

- **SKILL.md** - Main module management skill
- **registry-schema.md** - Complete registry schema documentation
- **util/setup-helpers.sh** - Shared helper functions for setup scripts
