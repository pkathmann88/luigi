# Shell Scripting Skill and Setup Helper Library

This PR creates a comprehensive shell scripting skill for Luigi agents and extracts duplicate code from all setup scripts into a shared helper library.

## Overview

This work establishes Luigi's shell scripting standards and eliminates code duplication across all module setup scripts by creating a shared utility library.

## Major Components

### 1. Shell Scripting Skill (`.github/skills/shell-scripting/`)

Created comprehensive shell scripting guidance for Luigi development:

**Files Created:**
- `SKILL.md` (1,165 lines) - Complete shell scripting standards and patterns
- `shell-scripting-patterns.md` (857 lines) - Advanced patterns (JSON, arrays, testing)
- `example-setup.sh` (515 lines) - Reference implementation
- `README.md` (162 lines) - Skill overview

**Coverage:**
- Luigi shell scripting standards and templates
- **Shared setup helper library usage** (util/setup-helpers.sh)
- Standard logging functions and color output patterns
- Argument parsing and CLI patterns
- Package management with module.json integration
- Service management with systemd
- Configuration file handling
- File operations with error handling
- User input and prompt patterns
- Security considerations
- Testing patterns and shellcheck validation

### 2. Shared Setup Helper Library (`util/`)

Extracted duplicate code from all setup scripts into centralized helper:

**Files Created:**
- `setup-helpers.sh` (357 lines) - 25 reusable functions
- `README.md` (220 lines) - Complete function reference

**Functions Provided (25 total):**

**Logging (7 functions):**
- `log_info` - Green [INFO] messages
- `log_warn` - Yellow [WARN] messages *(standardized, removed log_warning duplicate)*
- `log_error` - Red [ERROR] messages
- `log_step` - Blue [STEP] workflow steps
- `log_header` - Cyan section headers with borders
- `log_debug` - Blue [DEBUG] debug information
- `log_success` - Green ✓ success confirmations

**Package Management (3 functions):**
- `read_apt_packages` - Parse module.json apt_packages array
- `should_skip_packages` - Check SKIP_PACKAGES flag
- `is_purge_mode` - Check LUIGI_PURGE_MODE flag

**Utility Functions (18 functions):**
- Permission: `check_root`
- Command checking: `command_exists`, `check_required_commands`
- File operations: `check_file_exists`, `check_dir_exists`, `create_directory`, `remove_file`, `remove_directory`
- User input: `prompt_yes_no`
- Service management: `service_is_active`, `service_is_enabled`, `stop_service`, `disable_service`
- Validation: `validate_required_files`

### 3. Module Setup Scripts Updated

All 5 module setup scripts now source the shared helper:

**Scripts Updated:**
- `motion-detection/mario/setup.sh` - Removed 40 lines of duplication
- `iot/ha-mqtt/setup.sh` - Removed 41 lines, standardized log_warning → log_warn
- `system/optimization/setup.sh` - Removed 25 lines of duplication
- `system/system-info/setup.sh` - Removed 31 lines of duplication
- `system/management-api/setup.sh` - Removed 11 lines of duplication

**Total Reduction:** ~148 lines of duplicate code removed across 5 scripts

**Usage Pattern:**
```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source shared setup helpers
if [ -f "$REPO_ROOT/util/setup-helpers.sh" ]; then
    source "$REPO_ROOT/util/setup-helpers.sh"
fi

# Use helper functions
log_info "Installing module..."
packages=($(read_apt_packages "$SCRIPT_DIR/module.json"))
```

### 4. Documentation Updates

**Copilot Instructions (`.github/copilot-instructions.md`):**
- Added Shell Scripting Skill section
- Emphasized shared setup helper requirement
- Listed 25 helper functions available

**Skill Documentation:**
- Shell scripting SKILL.md - Added prominent setup-helpers.sh section
- Shell scripting patterns - Referenced helper functions
- All documentation cross-references util/README.md

## Code Quality Improvements

### Standardization
- ✅ All warning messages use `log_warn` (removed duplicate `log_warning`)
- ✅ Consistent logging format across all scripts
- ✅ Standard package management pattern via `read_apt_packages()`
- ✅ Uniform error handling and user prompts

### Deduplication
- ✅ Eliminated ~148 lines of duplicate code
- ✅ Single source of truth for common functions
- ✅ Consistent behavior across all setup scripts

### Maintainability
- ✅ Update once, affects all scripts
- ✅ Clear function reference in util/README.md
- ✅ Well-documented with examples
- ✅ Easier to test common functions

## Validation

All changes validated:
- ✅ All scripts pass shellcheck with 0 errors
- ✅ setup-helpers.sh passes shellcheck
- ✅ All module setup scripts tested (status commands work)
- ✅ Helper functions display correctly (✓ symbols, colors)
- ✅ Package reading functions work correctly

## Impact

**Lines Added:**
- Shell scripting skill: ~2,700 lines
- Setup helper library: ~577 lines
- Total new content: ~3,277 lines

**Lines Removed:**
- Duplicate code: ~148 lines across 5 scripts

**Scripts Modified:**
- 5 module setup scripts
- 1 copilot instructions file
- Total: 6 files

**Benefits:**
- Single source of truth for shell scripting patterns
- Consistent logging and error handling
- Reduced maintenance burden
- Comprehensive guidance for future development
- Zero code duplication in setup scripts

## Testing

Tested on all affected scripts:
```bash
# All pass shellcheck
shellcheck -S error util/setup-helpers.sh
shellcheck -S error iot/ha-mqtt/setup.sh
shellcheck -S error motion-detection/mario/setup.sh
shellcheck -S error system/optimization/setup.sh
shellcheck -S error system/system-info/setup.sh
shellcheck -S error system/management-api/setup.sh

# All status commands work
./iot/ha-mqtt/setup.sh status
./motion-detection/mario/setup.sh status
./system/optimization/setup.sh status
./system/system-info/setup.sh status
./system/management-api/setup.sh status
```

## Future Work

With the shell scripting skill and helper library in place:
- New modules can follow established patterns
- Less duplicate code in future setup scripts
- Consistent UX across all Luigi modules
- Easier onboarding for contributors
