---
name: shell-scripting
description: Comprehensive guide for shell scripting in Luigi repository. Use this skill when creating, modifying, or debugging shell scripts (setup.sh, service scripts, utility scripts) following Luigi conventions and best practices.
license: MIT
---

# Shell Scripting for Luigi Repository

This skill provides comprehensive guidance for shell scripting in the Luigi repository, covering setup scripts, utility scripts, command-line tools, and testing scripts following established patterns and best practices.

## When to Use This Skill

Use this skill when:
- Creating new shell scripts (setup.sh, installation scripts, utility scripts)
- Modifying existing shell scripts in Luigi modules
- Creating command-line tools for Luigi modules
- Debugging shell script issues
- Writing test scripts for shell validation
- Implementing service management scripts
- Creating deployment or configuration scripts

## Luigi Shell Scripting Standards

### Important: Shared Setup Helper Library

**All Luigi module setup scripts MUST use the shared helper library:**

Luigi provides a shared helper library at `util/setup-helpers.sh` containing common functions used by all setup scripts. This eliminates code duplication and ensures consistency.

**Usage Pattern:**
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
# Use helper functions: log_info, log_warn, log_error, etc.
```

**Helper provides:**
- Color definitions: RED, GREEN, YELLOW, BLUE, CYAN, NC
- Logging functions: log_info, log_warn, log_error, log_step, log_header, log_debug, log_success
- Permission checking: check_root
- Package management: read_apt_packages, should_skip_packages, is_purge_mode
- Command availability: command_exists, check_required_commands
- File operations: check_file_exists, check_dir_exists, create_directory, remove_file, remove_directory
- User input: prompt_yes_no
- Service management: service_is_active, service_is_enabled, stop_service, disable_service
- Validation: validate_required_files

**See:** `util/README.md` for complete function reference and examples.

### Script Structure Template

For scripts that DON'T use the helper (rare, non-setup scripts):

```bash
#!/bin/bash
################################################################################
# {Script Name} - {Brief Description}
#
# {Detailed description of script purpose}
#
# Usage: {usage examples}
#
# Author: Luigi Project
# License: MIT
################################################################################

set -e  # Exit on error (for setup scripts)

# Color output definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory detection (POSIX-compatible)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Constants and configuration
CONSTANT_NAME="value"

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Main script logic
main() {
    # Script implementation
    :
}

# Execute main
main "$@"
```

### Bash Options and Safety

**For Setup/Installation Scripts:**
```bash
set -e  # Exit immediately if a command exits with a non-zero status
# Do NOT use set -u as it conflicts with ${VAR:-default} patterns
# Do NOT use set -o pipefail unless you specifically need it
```

**For Utility/CLI Tools:**
```bash
# Don't use set -e if you want to handle errors explicitly
# Use explicit error checking: if ! command; then ... fi
```

**For Library Scripts (sourced by other scripts):**
```bash
# Do NOT use set -e in library files
# Library files should never exit, only return error codes
```

### Logging Functions - Standard Pattern

All Luigi scripts MUST use these exact logging functions:

```bash
# Color definitions (always define these first)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Standard logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_header() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}
```

**Usage:**
```bash
log_info "Installing package xyz..."
log_warn "Configuration file already exists"
log_error "Failed to create directory"
log_step "Step 1: Checking dependencies..."
log_header "Module Installation"
```

**Never use:**
- `echo` with inline color codes
- Different logging function names
- `printf` for logging (use echo -e)

### Script Directory Detection

**Standard pattern (use this in all scripts):**
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

This provides the absolute path to the directory containing the script, regardless of where it's executed from.

**Usage:**
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/mario.py"
CONFIG_FILE="$SCRIPT_DIR/mario.conf.example"
```

### File Path Conventions

**Installation paths follow these conventions:**

```bash
# Binary executables
INSTALL_BIN="/usr/local/bin/{script-name}"

# System services
INSTALL_SERVICE="/etc/systemd/system/{service-name}.service"

# Configuration files (follows repository structure)
INSTALL_CONFIG_DIR="/etc/luigi/{category}/{module-name}"
INSTALL_CONFIG="/etc/luigi/{category}/{module-name}/{module-name}.conf"

# Module resources
INSTALL_RESOURCES="/usr/share/{module-name}"

# Shared libraries
INSTALL_LIB_DIR="/usr/local/lib/luigi"

# Log files
LOG_FILE="/var/log/luigi/{module-name}.log"
LOG_DIR="/var/log/luigi"

# Temporary files
TEMP_FILE="/tmp/{module-name}_temp"
```

**Examples:**
```bash
# For motion-detection/mario module
INSTALL_BIN="/usr/local/bin/mario.py"
INSTALL_CONFIG_DIR="/etc/luigi/motion-detection/mario"
INSTALL_CONFIG="/etc/luigi/motion-detection/mario/mario.conf"
INSTALL_SOUNDS="/usr/share/sounds/mario"
LOG_FILE="/var/log/luigi/mario.log"

# For iot/ha-mqtt module
INSTALL_BIN_DIR="/usr/local/bin"  # Multiple scripts
INSTALL_LIB_DIR="/usr/local/lib/luigi"
INSTALL_CONFIG_DIR="/etc/luigi/iot/ha-mqtt"
```

### Root Permission Checking

**Standard check_root function:**
```bash
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        echo "Please run: sudo $0 $*"
        exit 1
    fi
}
```

**Always call at the beginning of setup scripts:**
```bash
main() {
    check_root
    # ... rest of script
}
```

### User Detection Pattern

**For scripts that need to determine the installation user:**

```bash
# Detect installation user (don't hardcode 'pi:pi')
INSTALL_USER="${SUDO_USER:-$(whoami)}"

# If running as root, check for pi user as fallback
if [ "$INSTALL_USER" = "root" ]; then
    if id -u pi >/dev/null 2>&1; then
        INSTALL_USER="pi"
    fi
fi

# Get user's home directory
INSTALL_USER_HOME=$(getent passwd "$INSTALL_USER" | cut -d: -f6)

# Usage in chown
chown "${INSTALL_USER}:${INSTALL_USER}" /path/to/file

# Usage in sudo
sudo -u "$INSTALL_USER" command
```

### Argument Parsing

**Standard pattern for setup scripts:**

```bash
# Parse command-line arguments
ACTION="${1:-install}"
MODULE_ARG="${2:-}"
SKIP_PACKAGES=0

# Parse flags
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-packages)
            SKIP_PACKAGES=1
            shift
            ;;
        install|uninstall|status)
            ACTION="$1"
            shift
            ;;
        *)
            MODULE_ARG="$1"
            shift
            ;;
    esac
done
```

**For command-line tools with multiple options:**

```bash
# Initialize variables
SENSOR_ID=""
VALUE=""
UNIT=""
BINARY_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --sensor)
            SENSOR_ID="$2"
            shift 2
            ;;
        --value)
            VALUE="$2"
            shift 2
            ;;
        --unit)
            UNIT="$2"
            shift 2
            ;;
        --binary)
            BINARY_MODE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -v|--version)
            echo "Version: $VERSION"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate required arguments
if [ -z "$SENSOR_ID" ]; then
    log_error "Missing required argument: --sensor"
    usage
    exit 1
fi
```

### File and Directory Operations

**Checking file existence:**
```bash
if [ ! -f "$file_path" ]; then
    log_error "File not found: $file_path"
    return 1
fi

if [ ! -d "$dir_path" ]; then
    log_error "Directory not found: $dir_path"
    return 1
fi

if [ ! -e "$path" ]; then
    log_error "Path does not exist: $path"
    return 1
fi
```

**Creating directories:**
```bash
# Create with error checking
if ! mkdir -p "$directory"; then
    log_error "Failed to create directory: $directory"
    return 1
fi

# Create multiple directories
local directories=(
    "/etc/luigi/module"
    "/var/log/luigi"
    "/usr/share/module"
)

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        if mkdir -p "$dir"; then
            log_info "Created: $dir"
        else
            log_error "Failed to create: $dir"
            return 1
        fi
    fi
done
```

**Copying files:**
```bash
# Copy with error checking
if ! cp "$source" "$dest"; then
    log_error "Failed to copy $source to $dest"
    return 1
fi

# Copy and set permissions
if cp "$source" "$dest" && chmod 755 "$dest"; then
    log_info "Installed: $dest"
else
    log_error "Failed to install: $dest"
    return 1
fi

# Copy and set ownership
if cp "$source" "$dest" && chown root:root "$dest" && chmod 644 "$dest"; then
    log_info "Installed: $dest"
else
    log_error "Failed to install: $dest"
    return 1
fi
```

**Removing files safely:**
```bash
# Check before removing
if [ -f "$file" ]; then
    if rm "$file"; then
        log_info "Removed: $file"
    else
        log_warn "Failed to remove: $file"
    fi
fi

# Remove directory
if [ -d "$dir" ]; then
    if rm -rf "$dir"; then
        log_info "Removed: $dir"
    else
        log_warn "Failed to remove: $dir"
    fi
fi
```

### Command Availability Checking

**Standard pattern:**
```bash
# Check single command
if ! command -v mosquitto_pub >/dev/null 2>&1; then
    log_error "mosquitto_pub not found - please install mosquitto-clients"
    return 1
fi

# Check multiple commands
local commands=("mosquitto_pub" "jq" "python3")
local missing=0

for cmd in "${commands[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "$cmd not found"
        missing=1
    fi
done

if [ $missing -eq 1 ]; then
    log_error "Missing required commands"
    return 1
fi
```

**Never use:**
- `which` command (deprecated, not POSIX)
- `type` without `-p` flag
- Checking `$?` after command execution without suppressing output

### Package Management Pattern

**Luigi modules declare dependencies in module.json:**

```json
{
  "name": "module-name",
  "apt_packages": [
    "package1",
    "package2"
  ]
}
```

**Reading packages from module.json:**
```bash
# Get module directory
MODULE_DIR="$SCRIPT_DIR"
MODULE_JSON="$MODULE_DIR/module.json"

# Read apt_packages array
get_apt_packages() {
    local packages=()
    
    if [ -f "$MODULE_JSON" ] && command -v jq >/dev/null 2>&1; then
        # Parse apt_packages array from JSON
        while IFS= read -r pkg; do
            packages+=("$pkg")
        done < <(jq -r '.apt_packages[]? // empty' "$MODULE_JSON" 2>/dev/null)
    fi
    
    echo "${packages[@]}"
}
```

**SKIP_PACKAGES flag handling:**

All module setup scripts MUST support `--skip-packages` flag:

```bash
# Parse --skip-packages flag
SKIP_PACKAGES=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-packages)
            SKIP_PACKAGES=1
            export SKIP_PACKAGES
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# In install/uninstall functions, check flag
install_packages() {
    if [ "${SKIP_PACKAGES:-}" = "1" ]; then
        log_info "Skipping package installation (--skip-packages)"
        return 0
    fi
    
    # Install packages
    local packages=($(get_apt_packages))
    if [ ${#packages[@]} -eq 0 ]; then
        return 0
    fi
    
    log_step "Installing packages: ${packages[*]}"
    if apt-get install -y "${packages[@]}"; then
        log_info "Packages installed successfully"
    else
        log_error "Failed to install packages"
        return 1
    fi
}
```

**Package removal with user prompt:**

```bash
remove_packages() {
    if [ "${SKIP_PACKAGES:-}" = "1" ]; then
        log_info "Skipping package removal (--skip-packages)"
        return 0
    fi
    
    # Check if purge mode (LUIGI_PURGE_MODE from root setup.sh)
    if [ "${LUIGI_PURGE_MODE:-}" = "1" ]; then
        # Purge mode: remove without prompting
        local packages=($(get_apt_packages))
        if [ ${#packages[@]} -gt 0 ]; then
            log_step "Removing packages: ${packages[*]}"
            apt-get purge -y "${packages[@]}" 2>/dev/null || true
            apt-get autoremove -y 2>/dev/null || true
        fi
        return 0
    fi
    
    # Normal uninstall: prompt user
    local packages=($(get_apt_packages))
    if [ ${#packages[@]} -eq 0 ]; then
        return 0
    fi
    
    log_warn "The following packages can be removed:"
    for pkg in "${packages[@]}"; do
        echo "  - $pkg"
    done
    
    read -p "Remove these packages? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_step "Removing packages..."
        apt-get purge -y "${packages[@]}" 2>/dev/null || true
        apt-get autoremove -y 2>/dev/null || true
        log_info "Packages removed"
    else
        log_info "Skipping package removal"
    fi
}
```

### User Input and Prompts

**Standard user prompt pattern:**

```bash
# WARNING prompt
log_warn "This will overwrite existing configuration"
read -p "Continue? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # User confirmed
    do_action
else
    log_info "Cancelled by user"
    return 0
fi
```

**NEVER do this:**
```bash
# WRONG - Don't embed color codes in read -p
read -rp "$(echo -e "${YELLOW}[WARN]${NC} Continue? (y/N): ")" -n 1
```

**Instead, use this pattern:**
```bash
# CORRECT - Log message first, then read
log_warn "Continue? (y/N): "
read -p "" -n 1 -r
echo
```

**Or this simpler pattern:**
```bash
# CORRECT - Simple read with plain prompt
read -p "Continue? (y/N): " -n 1 -r
echo
```

### Service User Creation

**IMPORTANT: No service should run as root.**

All Luigi modules with service capability MUST create a dedicated system user for the service. This follows the principle of least privilege and provides process isolation.

**Standard Pattern:**

```bash
# Create dedicated service user
create_service_user() {
    log_step "Creating dedicated service user..."
    
    # Create luigi-{module} user with optional hardware groups
    # Args: username, description, home_dir, additional_groups
    create_service_user "luigi-mario" \
                        "Mario Motion Detection Service" \
                        "/var/lib/luigi-mario" \
                        "gpio" || {
        log_error "Failed to create service user"
        exit 1
    }
    
    log_success "Service user luigi-mario created and configured"
}
```

**User Naming Convention:**
- Format: `luigi-{module-name}`
- Examples: `luigi-mario`, `luigi-sysinfo`, `luigi-api`

**Group Membership:**
- **luigi group** (REQUIRED): All service users MUST be members of the luigi group
- **Hardware groups** (OPTIONAL): Add gpio, spi, i2c, etc. as needed
- Examples:
  - GPIO access: `"gpio"`
  - SPI + I2C: `"gpio,spi,i2c"`
  - No hardware: `""` (empty string)

**Properties:**
- System user (UID < 1000)
- No password
- Login shell: `/usr/sbin/nologin` (no interactive login)
- Home directory: `/var/lib/luigi-{module-name}`
- Member of luigi group (for shared file access)

**In systemd service file:**

```ini
[Service]
Type=simple
User=luigi-mario
Group=luigi-mario
# Service user has read access to all configs/logs via luigi group
# Hardware access via gpio group membership (no root needed)
```

**Complete installation sequence:**

```bash
install() {
    check_root
    check_files
    install_dependencies
    create_service_user      # Step 1: Create user BEFORE installing files
    install_script           # Step 2: Install application files
    install_config           # Step 3: Install configuration
    install_service          # Step 4: Install and enable service
    start_service            # Step 5: Start service
}
```

**Benefits:**
- ✅ No root privileges - security best practice
- ✅ Process isolation - contained security breaches
- ✅ Shared file access - via luigi group membership
- ✅ Hardware access - via gpio/spi/i2c groups
- ✅ Consistent pattern across all modules

### Service Management

**Systemd service operations:**

```bash
# Reload systemd daemon
systemctl daemon-reload

# Enable service
if systemctl enable "$SERVICE_NAME"; then
    log_info "Service enabled"
else
    log_error "Failed to enable service"
    return 1
fi

# Start service
if systemctl start "$SERVICE_NAME"; then
    log_info "Service started"
else
    log_error "Failed to start service"
    return 1
fi

# Check service status
if systemctl is-active --quiet "$SERVICE_NAME"; then
    log_info "Service is running"
else
    log_warn "Service is not running"
fi

# Stop service
systemctl stop "$SERVICE_NAME" 2>/dev/null || true

# Disable service
systemctl disable "$SERVICE_NAME" 2>/dev/null || true
```

**Full service installation pattern:**

```bash
install_service() {
    log_step "Installing systemd service..."
    
    # Copy service file
    if ! cp "$SCRIPT_DIR/$SERVICE_FILE" "$INSTALL_SERVICE"; then
        log_error "Failed to copy service file"
        return 1
    fi
    
    # Set permissions
    chmod 644 "$INSTALL_SERVICE"
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable and start service
    if systemctl enable "$SERVICE_NAME"; then
        log_info "Service enabled"
    else
        log_error "Failed to enable service"
        return 1
    fi
    
    if systemctl start "$SERVICE_NAME"; then
        log_info "Service started successfully"
    else
        log_error "Failed to start service"
        log_info "Check logs with: journalctl -u $SERVICE_NAME -n 50"
        return 1
    fi
}

uninstall_service() {
    log_step "Removing systemd service..."
    
    # Stop service
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        systemctl stop "$SERVICE_NAME" 2>/dev/null || true
        log_info "Service stopped"
    fi
    
    # Disable service
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        systemctl disable "$SERVICE_NAME" 2>/dev/null || true
        log_info "Service disabled"
    fi
    
    # Remove service file
    if [ -f "$INSTALL_SERVICE" ]; then
        rm "$INSTALL_SERVICE"
        log_info "Service file removed"
    fi
    
    # Reload systemd
    systemctl daemon-reload
}
```

### Configuration File Handling

**Create configuration from example:**

```bash
install_config() {
    log_step "Installing configuration..."
    
    # Create config directory
    local parent_dir=$(dirname "$INSTALL_CONFIG_DIR")
    if [ ! -d "$parent_dir" ]; then
        mkdir -p "$parent_dir"
    fi
    
    if [ ! -d "$INSTALL_CONFIG_DIR" ]; then
        if mkdir -p "$INSTALL_CONFIG_DIR"; then
            log_info "Created config directory: $INSTALL_CONFIG_DIR"
        else
            log_error "Failed to create config directory"
            return 1
        fi
    fi
    
    # Check if config already exists
    if [ -f "$INSTALL_CONFIG" ]; then
        log_warn "Config file already exists: $INSTALL_CONFIG"
        read -p "Overwrite existing config? (y/N): " -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping existing config"
            return 0
        fi
    fi
    
    # Copy example config
    if [ ! -f "$SCRIPT_DIR/$CONFIG_EXAMPLE" ]; then
        log_error "Config example not found: $CONFIG_EXAMPLE"
        return 1
    fi
    
    if cp "$SCRIPT_DIR/$CONFIG_EXAMPLE" "$INSTALL_CONFIG"; then
        chmod 644 "$INSTALL_CONFIG"
        log_info "Config installed: $INSTALL_CONFIG"
    else
        log_error "Failed to install config"
        return 1
    fi
}
```

**Reading INI-style configuration:**

```bash
# Parse INI file
load_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        log_error "Config file not found: $config_file"
        return 1
    fi
    
    local section=""
    while IFS= read -r line || [ -n "$line" ]; do
        # Remove leading/trailing whitespace
        line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        
        # Skip empty lines and comments
        if [ -z "$line" ] || [[ "$line" =~ ^[#;] ]]; then
            continue
        fi
        
        # Check for section header [Section]
        if [[ "$line" =~ ^\[.*\]$ ]]; then
            section=$(echo "$line" | sed 's/[][]//g')
            continue
        fi
        
        # Parse key=value
        if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
            local key=$(echo "$line" | cut -d= -f1)
            local value=$(echo "$line" | cut -d= -f2-)
            
            # Remove quotes from value
            value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
            
            # Export as environment variable
            export "${section}_${key}=$value"
        fi
    done < "$config_file"
}
```

### Error Handling Patterns

**Function with error checking:**

```bash
do_installation() {
    log_step "Installing component..."
    
    # Check preconditions
    if [ ! -f "$SOURCE_FILE" ]; then
        log_error "Source file not found: $SOURCE_FILE"
        return 1
    fi
    
    # Perform operation with error checking
    if ! cp "$SOURCE_FILE" "$DEST_FILE"; then
        log_error "Failed to copy file"
        return 1
    fi
    
    # Multiple operations
    if mkdir -p "$DEST_DIR" && cp "$SOURCE" "$DEST_DIR/" && chmod 755 "$DEST_DIR/$SOURCE"; then
        log_info "Installation successful"
    else
        log_error "Installation failed"
        return 1
    fi
    
    return 0
}
```

**Graceful failure (non-fatal errors):**

```bash
# ha-mqtt integration - must not fail module installation
install_ha_mqtt_integration() {
    log_step "Installing ha-mqtt integration (optional)..."
    
    # Check if ha-mqtt is installed
    if [ ! -d "$HA_MQTT_SENSORS_DIR" ]; then
        log_info "ha-mqtt not installed - skipping integration"
        return 0  # Success, not an error
    fi
    
    # Try to copy descriptor
    if ! cp "$SCRIPT_DIR/$SENSOR_DESCRIPTOR" "$HA_MQTT_DESCRIPTOR" 2>/dev/null; then
        log_warn "Failed to install ha-mqtt descriptor - integration unavailable"
        return 0  # Still return success
    fi
    
    log_info "ha-mqtt integration installed"
    return 0
}
```

### Validation and Testing

**Shellcheck validation:**

All shell scripts MUST pass shellcheck validation:

```bash
# Validate script syntax
shellcheck -S error script.sh
```

**Common shellcheck directives:**

```bash
# Disable specific checks at file level
# shellcheck disable=SC2034  # Variable appears unused

# Disable for single line
# shellcheck disable=SC2086
variable_without_quotes=$value

# Source file hint for shellcheck
# shellcheck source=../lib/mqtt_helpers.sh
source "$LIB_DIR/mqtt_helpers.sh"
```

**Testing pattern:**

Create `tests/syntax/` directory with validation scripts:

```bash
#!/bin/bash
# validate-all.sh - Validate all shell scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Find all shell scripts
scripts=(
    "$MODULE_DIR/setup.sh"
    "$MODULE_DIR/bin/script1"
    "$MODULE_DIR/bin/script2"
)

failed=0

for script in "${scripts[@]}"; do
    if [ ! -f "$script" ]; then
        continue
    fi
    
    echo "Validating: $script"
    
    if shellcheck -S error "$script" 2>/dev/null; then
        echo "  ✓ OK"
    else
        echo "  ✗ FAILED"
        shellcheck "$script" 2>&1 | sed 's/^/    /'
        failed=1
    fi
done

exit $failed
```

## Advanced Patterns

See `shell-scripting-patterns.md` for advanced topics:
- JSON parsing with jq
- Array operations
- String manipulation
- Subprocess management
- Signal handling
- Logging to files
- Multi-script architectures
- Library sourcing patterns
- Testing frameworks

## Common Issues and Solutions

### Issue: Script fails with "unbound variable"

**Problem:**
```bash
set -u  # Causes failures with ${VAR:-default}
echo "${UNDEFINED_VAR:-default}"  # Fails with set -u
```

**Solution:**
Don't use `set -u` in Luigi scripts. Use explicit checks instead:
```bash
if [ -z "${VAR:-}" ]; then
    VAR="default"
fi
```

### Issue: Color codes not working

**Problem:**
```bash
echo -e "$GREEN[INFO]$NC Message"  # Wrong
```

**Solution:**
```bash
echo -e "${GREEN}[INFO]${NC} Message"  # Correct - braces required
```

### Issue: Script directory detection fails

**Problem:**
```bash
SCRIPT_DIR=$(dirname "$0")  # Wrong - relative path
```

**Solution:**
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # Correct
```

### Issue: File checks fail silently

**Problem:**
```bash
if [ -f $file ]; then  # Wrong - fails with spaces in filename
```

**Solution:**
```bash
if [ -f "$file" ]; then  # Correct - always quote variables
```

### Issue: Command output captured incorrectly

**Problem:**
```bash
output=`command`  # Wrong - backticks deprecated
```

**Solution:**
```bash
output=$(command)  # Correct - use $()
```

## Security Considerations

### Input Validation

**Always validate user input:**
```bash
# Validate sensor ID (alphanumeric, underscore, hyphen only)
validate_sensor_id() {
    local sensor_id="$1"
    
    if [[ ! "$sensor_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "Invalid sensor ID: $sensor_id"
        log_error "Must contain only letters, numbers, underscores, and hyphens"
        return 1
    fi
    
    # Prevent path traversal
    if [[ "$sensor_id" == *".."* ]] || [[ "$sensor_id" == *"/"* ]]; then
        log_error "Invalid sensor ID: contains path traversal characters"
        return 1
    fi
    
    return 0
}
```

### Avoid Shell Injection

**NEVER do this:**
```bash
# DANGEROUS - Shell injection vulnerability
eval "rm $user_input"
command=$(cat file)
eval "$command"
```

**Always use safe alternatives:**
```bash
# SAFE - Direct command execution
rm "$user_input"

# SAFE - Array for command arguments
args=("$arg1" "$arg2" "$arg3")
command "${args[@]}"
```

### File Permissions

**Set appropriate permissions:**
```bash
# Executables
chmod 755 /usr/local/bin/script

# Configuration files (may contain secrets)
chmod 600 /etc/luigi/module/config.conf

# Regular data files
chmod 644 /usr/share/module/data.txt

# Directories
chmod 755 /etc/luigi/module
```

### Credential Handling

**NEVER:**
- Hardcode passwords in scripts
- Echo passwords to console
- Store passwords in world-readable files

**Always:**
```bash
# Store credentials in config files with 600 permissions
chmod 600 /etc/luigi/module/config.conf

# Read passwords securely
read -s -p "Enter password: " password
echo

# Check config file permissions
perms=$(stat -c "%a" "$config_file")
if [ "$perms" != "600" ] && [ "$perms" != "400" ]; then
    log_warn "Config file has insecure permissions: $perms"
    log_warn "Should be 600 (owner read/write only)"
fi
```

## References

- Luigi Repository: https://github.com/pkathmann88/luigi
- Existing Scripts: See `setup.sh`, `motion-detection/mario/setup.sh`, `iot/ha-mqtt/setup.sh`
- Testing Examples: See `iot/ha-mqtt/tests/`
- shellcheck: https://www.shellcheck.net/
- Bash Best Practices: https://google.github.io/styleguide/shellguide.html
