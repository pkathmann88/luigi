# Luigi Utility Scripts

This directory contains shared utility scripts and helper functions used across the Luigi repository.

## Files

### setup-helpers.sh

Shared functions for all Luigi module setup scripts. Eliminates duplicate code across setup scripts and ensures consistency.

**Functions Provided:**

#### Color Definitions
- `RED`, `GREEN`, `YELLOW`, `BLUE`, `CYAN`, `NC` - ANSI color codes for terminal output

#### Logging Functions
- `log_info(message)` - Print informational message in green
- `log_warn(message)` - Print warning message in yellow  
- `log_error(message)` - Print error message in red
- `log_step(message)` - Print step message in blue
- `log_header(message)` - Print section header in cyan with decorative borders

#### Permission Checking
- `check_root()` - Verify script is run with root privileges, exit if not

#### Package Management
- `read_apt_packages(module_json)` - Read apt_packages array from module.json file
- `should_skip_packages()` - Check if SKIP_PACKAGES flag is set
- `is_purge_mode()` - Check if LUIGI_PURGE_MODE flag is set (for uninstall)

#### Command Availability
- `command_exists(command)` - Check if a command is available
- `check_required_commands(cmd1 cmd2 ...)` - Verify multiple commands exist

#### File and Directory Operations
- `check_file_exists(file, description)` - Verify file exists with error message
- `check_dir_exists(dir, description)` - Verify directory exists with error message
- `create_directory(dir, description)` - Create directory with parents and error handling
- `remove_file(file, description)` - Safely remove file with error handling
- `remove_directory(dir, description)` - Safely remove directory with error handling

#### User Input
- `prompt_yes_no(prompt, default)` - Prompt user for yes/no confirmation

#### Systemd Service Helpers
- `service_is_active(service_name)` - Check if systemd service is running
- `service_is_enabled(service_name)` - Check if systemd service is enabled
- `stop_service(service_name, description)` - Safely stop a systemd service
- `disable_service(service_name, description)` - Safely disable a systemd service

#### Validation
- `validate_required_files(file1 file2 ...)` - Verify all required files exist

## Usage in Setup Scripts

All Luigi module setup scripts should source this helper file at the beginning:

```bash
#!/bin/bash
set -e  # Exit on error

# Script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"  # Adjust path as needed

# Source shared setup helpers
# shellcheck source=../../util/setup-helpers.sh
if [ -f "$REPO_ROOT/util/setup-helpers.sh" ]; then
    source "$REPO_ROOT/util/setup-helpers.sh"
else
    echo "Error: Cannot find setup-helpers.sh"
    echo "Expected location: $REPO_ROOT/util/setup-helpers.sh"
    exit 1
fi

# Your setup script code continues here...
```

**Path Adjustments:**
- For modules at `motion-detection/mario/`: Use `../..` (2 levels up)
- For modules at `system/optimization/`: Use `../..` (2 levels up)
- For modules at `iot/ha-mqtt/`: Use `../..` (2 levels up)

## Examples

### Using Logging Functions

```bash
log_step "Installing dependencies..."
log_info "All dependencies installed successfully"
log_warn "Configuration file already exists"
log_error "Failed to create directory"
```

### Using Package Management

```bash
# Read packages from module.json
packages=($(read_apt_packages "$SCRIPT_DIR/module.json"))

# Check if we should skip packages
if should_skip_packages; then
    log_info "Skipping package installation (managed centrally)"
    return 0
fi

# Install packages...
apt-get install -y "${packages[@]}"
```

### Using File Operations

```bash
# Create directory with error handling
if ! create_directory "/etc/luigi/module" "Config directory"; then
    return 1
fi

# Check if file exists
if ! check_file_exists "$config_file" "Config file"; then
    return 1
fi

# Remove file safely
remove_file "/tmp/tempfile" "Temporary file"
```

### Using Service Helpers

```bash
# Stop service if running
stop_service "mario" "Mario Motion Detection"

# Disable service if enabled
disable_service "mario" "Mario Motion Detection"

# Check service status
if service_is_active "mario"; then
    log_info "Service is running"
fi
```

### Using User Prompts

```bash
# Prompt for confirmation
if prompt_yes_no "Overwrite existing config?"; then
    # User confirmed
    cp config.example config.conf
else
    log_info "Keeping existing config"
fi
```

## Module-Specific Customization

Some modules may need to override helper functions with custom logging formats. This is allowed:

```bash
# Source the helpers first
source "$REPO_ROOT/util/setup-helpers.sh"

# Then override specific functions
log_info() {
    echo -e "\033[0;32m[INFO]\033[0m $1"  # Custom format
}
```

## Scripts Using This Helper

Currently used by:
- `motion-detection/mario/setup.sh`
- `iot/ha-mqtt/setup.sh`
- `system/optimization/setup.sh`
- `system/system-info/setup.sh`
- `system/management-api/setup.sh`

## Benefits

- **Consistency**: All setup scripts use the same logging, error handling, and patterns
- **Maintainability**: Changes to common functions only need to be made in one place
- **Reduced Duplication**: ~125 lines of duplicate code eliminated across 5 scripts
- **Easier Testing**: Common functions can be tested independently
- **Documentation**: Clear reference for setup script conventions

## Validation

The helper script passes shellcheck validation with zero errors:

```bash
shellcheck -S error util/setup-helpers.sh
```

All setup scripts using the helper also pass shellcheck validation.

## See Also

- `.github/skills/shell-scripting/` - Shell scripting skill with detailed patterns
- `setup.sh` - Root setup script for centralized module management
- `MODULE_SCHEMA.md` - Module structure and conventions

---

**Created**: 2026-02-11  
**Version**: 1.0  
**License**: MIT
