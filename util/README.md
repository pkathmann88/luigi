# Luigi Utility Scripts

This directory contains shared utility scripts and helper functions used across the Luigi repository.

## Files

### fix-audio-popping.sh

**Standalone utility to fix audio popping/crackling on I2S audio devices (Adafruit Sound Bonnet and similar).**

This script provides an easy way to apply the audio popping fix without running a full Luigi installation.

**Features:**
- Automatically detects I2S audio devices in boot configuration
- Offers two solutions:
  1. Software-only fix with improved ALSA buffering (recommended)
  2. Silence playback systemd service for complete elimination
- Backs up existing configuration before making changes
- Tests audio playback to verify the fix
- Can be run independently at any time

**Usage:**
```bash
sudo ./util/fix-audio-popping.sh
```

**When to use:**
- You're experiencing popping/crackling sounds at the start/end of audio playback
- You have an Adafruit Sound Bonnet or similar I2S audio device
- You want to fix the issue without running `sudo ./setup.sh install`
- You've already installed Luigi but didn't apply the audio fix

**What it does:**
1. Checks for I2S device tree overlay in boot config
2. Explains the root cause of audio popping
3. Prompts user to select a fix method
4. Applies the selected fix (software config or systemd service)
5. Tests audio playback if test files are available
6. Provides rollback instructions if needed

**Requirements:**
- Must be run as root (uses sudo)
- I2S audio device must be configured (hifiberry-dac overlay or similar)
- For software fix: `/etc/asound.conf` must exist (created by Luigi audio configuration)

### setup-helpers.sh

Shared functions for all Luigi module setup scripts. Eliminates duplicate code across setup scripts and ensures consistency.

**Functions Provided:**

#### Color Definitions
- `RED`, `GREEN`, `YELLOW`, `BLUE`, `CYAN`, `NC` - ANSI color codes for terminal output

#### Logging Functions
- `log_info(message)` - Print informational message in green with [INFO] prefix
- `log_warn(message)` - Print warning message in yellow with [WARN] prefix
- `log_error(message)` - Print error message in red with [ERROR] prefix
- `log_step(message)` - Print step message in blue with [STEP] prefix
- `log_header(message)` - Print section header in cyan with decorative borders
- `log_debug(message)` - Print debug message in blue with [DEBUG] prefix
- `log_success(message)` - Print success message with ✓ symbol

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
log_debug "Variable value: $DEBUG_VAR"
log_success "Package installed successfully"
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

Some modules may need to override helper functions with custom logging formats. This is allowed and documented:

```bash
# Source the helpers first
source "$REPO_ROOT/util/setup-helpers.sh"

# Then override specific functions for module-specific formatting
log_info() {
    echo -e "\033[0;32m[INFO]\033[0m $1"  # Custom format without color variables
}
```

**Current overrides:**
- `system/management-api/setup.sh` - Custom log format for consistency with Node.js app
- All other functions should use the helper versions

**Note:** Overriding is discouraged unless there's a specific formatting requirement. Always document why an override is needed.

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
