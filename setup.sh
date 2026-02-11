#!/bin/bash
################################################################################
# Luigi - Centralized Setup Script
#
# This script discovers and executes setup scripts for all Luigi modules.
# Each module in a category directory (e.g., motion-detection/, sensors/, etc.)
# can have its own setup.sh script. This centralized script orchestrates the
# execution of all module setup scripts.
#
# Usage: sudo ./setup.sh [install|uninstall|status] [module]
#
# Arguments:
#   install   - Install all modules or a specific module (default)
#   uninstall - Uninstall all modules or a specific module
#   status    - Show status of all modules or a specific module
#   [module]  - Optional: specific module path (e.g., motion-detection/mario)
#
# Examples:
#   sudo ./setup.sh install                    # Install all modules
#   sudo ./setup.sh install motion-detection/mario  # Install specific module
#   sudo ./setup.sh status                     # Show status of all modules
#   sudo ./setup.sh uninstall                  # Uninstall all modules
#
# Author: Luigi Project
# License: MIT
################################################################################

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Category directories to search for modules
CATEGORIES=("motion-detection" "sensors" "automation" "security" "iot" "system")

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

log_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Check if running as root (only for install/uninstall)
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root for install/uninstall operations"
        echo "Please run: sudo $0 $*"
        exit 1
    fi
}

# Check and install required dependencies for setup script
check_and_install_dependencies() {
    local missing_deps=()
    local install_needed=0
    
    log_step "Checking setup script dependencies..."
    
    # Check for jq (required for module dependency management)
    if ! command -v jq >/dev/null 2>&1; then
        log_warn "jq is not installed (required for module dependency management)"
        missing_deps+=("jq")
        install_needed=1
    else
        log_info "✓ jq is installed"
    fi
    
    # If dependencies are missing, offer to install them
    if [ $install_needed -eq 1 ]; then
        echo ""
        log_warn "Missing dependencies: ${missing_deps[*]}"
        echo ""
        echo "These dependencies are required for proper module installation."
        echo "Without them, module dependencies cannot be resolved and modules"
        echo "may be installed in the wrong order."
        echo ""
        
        # Auto-install if running as root, otherwise provide instructions
        if [ "$EUID" -eq 0 ]; then
            echo "Installing missing dependencies..."
            echo ""
            
            # Update apt cache
            log_step "Updating package cache..."
            if ! apt-get update -qq; then
                log_error "Failed to update package cache"
                return 1
            fi
            
            # Install missing packages
            for dep in "${missing_deps[@]}"; do
                log_step "Installing $dep..."
                if apt-get install -y -qq "$dep"; then
                    log_info "✓ $dep installed successfully"
                else
                    log_error "Failed to install $dep"
                    return 1
                fi
            done
            
            echo ""
            log_info "All dependencies installed successfully"
            echo ""
        else
            echo "Please install the missing dependencies manually:"
            echo "  sudo apt-get update"
            echo "  sudo apt-get install ${missing_deps[*]}"
            echo ""
            return 1
        fi
    else
        log_info "✓ All required dependencies are installed"
        echo ""
    fi
    
    return 0
}

# Get apt packages from a module's module.json file
# Returns newline-separated list of package names
get_module_apt_packages() {
    local module_path="$1"
    local module_json="$SCRIPT_DIR/$module_path/module.json"
    
    # Check if module.json exists
    if [ ! -f "$module_json" ]; then
        # No module.json = no packages
        return 0
    fi
    
    # Check if jq is available for JSON parsing
    if ! command -v jq >/dev/null 2>&1; then
        # jq not available, can't parse
        return 0
    fi
    
    # Parse apt_packages array from JSON (jq outputs one package per line)
    local packages
    packages=$(jq -r '.apt_packages[]? // empty' "$module_json" 2>/dev/null)
    
    if [ -n "$packages" ]; then
        echo "$packages"
    fi
}

# Collect all apt packages from all modules
# Returns unique list of packages, one per line
collect_all_apt_packages() {
    local modules=("$@")
    local all_packages=()
    
    # Collect packages from all modules
    for module in "${modules[@]}"; do
        local packages
        packages=$(get_module_apt_packages "$module")
        
        if [ -n "$packages" ]; then
            while IFS= read -r pkg; do
                # Add to array if not already present
                local already_added=0
                for existing_pkg in "${all_packages[@]}"; do
                    if [ "$existing_pkg" = "$pkg" ]; then
                        already_added=1
                        break
                    fi
                done
                
                if [ $already_added -eq 0 ]; then
                    all_packages+=("$pkg")
                fi
            done <<< "$packages"
        fi
    done
    
    # Output one package per line
    printf '%s\n' "${all_packages[@]}"
}

# Install apt packages in batch
install_apt_packages() {
    local packages=("$@")
    
    if [ ${#packages[@]} -eq 0 ]; then
        log_info "No apt packages to install"
        return 0
    fi
    
    log_step "Installing apt packages for all modules..."
    echo ""
    
    # Filter out packages that are already installed
    local to_install=()
    for pkg in "${packages[@]}"; do
        if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
            log_info "✓ $pkg (already installed)"
        else
            log_info "  $pkg (needs installation)"
            to_install+=("$pkg")
        fi
    done
    
    echo ""
    
    # Install packages if needed
    if [ ${#to_install[@]} -gt 0 ]; then
        log_step "Installing ${#to_install[@]} package(s)..."
        
        # Update apt cache
        log_info "Updating package cache..."
        if ! apt-get update -qq; then
            log_error "Failed to update package cache"
            return 1
        fi
        
        # Install packages
        log_info "Installing packages: ${to_install[*]}"
        if apt-get install -y -qq "${to_install[@]}"; then
            log_info "✓ All packages installed successfully"
            echo ""
            return 0
        else
            log_error "Failed to install some packages"
            return 1
        fi
    else
        log_info "✓ All required packages are already installed"
        echo ""
        return 0
    fi
}

# Remove apt packages in batch (after module uninstallation)
remove_apt_packages() {
    local packages=("$@")
    local purge_mode="$1"
    shift
    packages=("$@")
    
    if [ ${#packages[@]} -eq 0 ]; then
        log_info "No apt packages to remove"
        return 0
    fi
    
    log_step "Removing apt packages from all modules..."
    echo ""
    
    # Filter packages that are actually installed
    local to_remove=()
    for pkg in "${packages[@]}"; do
        if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
            log_info "  $pkg (installed)"
            to_remove+=("$pkg")
        else
            log_info "✓ $pkg (not installed)"
        fi
    done
    
    echo ""
    
    # Remove packages if any are installed
    if [ ${#to_remove[@]} -gt 0 ]; then
        # In purge mode, don't prompt
        if [ "$purge_mode" = "purge" ]; then
            log_step "Removing ${#to_remove[@]} package(s)..."
            log_info "Packages: ${to_remove[*]}"
            
            for pkg in "${to_remove[@]}"; do
                log_info "Removing $pkg..."
                if apt-get remove -y -qq "$pkg" 2>/dev/null; then
                    log_info "✓ $pkg removed"
                else
                    log_warn "Failed to remove $pkg (may not have been installed by Luigi)"
                fi
            done
            
            # Clean up unused dependencies
            log_info "Removing unused dependencies..."
            apt-get autoremove -y -qq 2>/dev/null || true
            
            log_info "✓ Package removal completed"
            echo ""
        else
            # In regular uninstall mode, prompt the user
            log_warn "The following packages were installed by Luigi modules:"
            for pkg in "${to_remove[@]}"; do
                echo "  - $pkg"
            done
            echo ""
            echo "Note: These packages may be used by other software on your system."
            echo ""
            read -p "Remove these packages? (y/N): " -n 1 -r
            echo ""
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log_step "Removing ${#to_remove[@]} package(s)..."
                
                for pkg in "${to_remove[@]}"; do
                    log_info "Removing $pkg..."
                    if apt-get remove -y -qq "$pkg" 2>/dev/null; then
                        log_info "✓ $pkg removed"
                    else
                        log_warn "Failed to remove $pkg"
                    fi
                done
                
                # Clean up unused dependencies
                log_info "Removing unused dependencies..."
                apt-get autoremove -y -qq 2>/dev/null || true
                
                log_info "✓ Package removal completed"
                echo ""
            else
                log_info "Keeping packages"
                echo ""
            fi
        fi
    else
        log_info "✓ No packages to remove"
        echo ""
    fi
    
    return 0
}

# Discover all module setup scripts
discover_modules() {
    local modules=()
    
    # Search in all category directories
    for category in "${CATEGORIES[@]}"; do
        local category_path="$SCRIPT_DIR/$category"
        
        # Check if category directory exists
        if [ -d "$category_path" ]; then
            # Find all setup.sh scripts in subdirectories
            while IFS= read -r -d '' setup_script; do
                # Get module path relative to project root
                local module_dir
                local module_path
                module_dir=$(dirname "$setup_script")
                module_path=$(realpath --relative-to="$SCRIPT_DIR" "$module_dir")
                modules+=("$module_path")
            done < <(find "$category_path" -mindepth 2 -maxdepth 2 -name "setup.sh" -type f -print0)
        fi
    done
    
    echo "${modules[@]}"
}

# Read dependencies from a module's module.json file
# Returns space-separated list of dependency module paths
get_module_dependencies() {
    local module_path="$1"
    local module_json="$SCRIPT_DIR/$module_path/module.json"
    
    # Check if module.json exists
    if [ ! -f "$module_json" ]; then
        # No module.json = no dependencies
        return 0
    fi
    
    # Check if jq is available for JSON parsing
    if ! command -v jq >/dev/null 2>&1; then
        # Redirect warnings to stderr to avoid capture by command substitution
        log_warn "jq not found, cannot parse module.json for $module_path" >&2
        log_warn "Install jq to enable dependency management: sudo apt-get install jq" >&2
        return 0
    fi
    
    # Parse dependencies array from JSON
    local deps
    deps=$(jq -r '.dependencies[]? // empty' "$module_json" 2>/dev/null)
    
    if [ -n "$deps" ]; then
        echo "$deps"
    fi
}

# Sort modules by dependencies using topological sort
# Modules with no dependencies come first, then modules that depend on them
sort_modules_by_dependencies() {
    local modules=("$@")
    local sorted=()
    local visited=()
    local visiting=()
    
    # Helper function for depth-first search
    visit_module() {
        local module="$1"
        
        # Check for circular dependency
        for v in "${visiting[@]}"; do
            if [ "$v" = "$module" ]; then
                log_error "Circular dependency detected involving: $module"
                return 1
            fi
        done
        
        # Check if already visited
        for v in "${visited[@]}"; do
            if [ "$v" = "$module" ]; then
                return 0
            fi
        done
        
        # Mark as visiting
        visiting+=("$module")
        
        # Visit dependencies first
        local deps
        deps=$(get_module_dependencies "$module")
        
        if [ -n "$deps" ]; then
            while IFS= read -r dep; do
                # Check if dependency exists in modules list
                local dep_exists=0
                for m in "${modules[@]}"; do
                    if [ "$m" = "$dep" ]; then
                        dep_exists=1
                        break
                    fi
                done
                
                if [ $dep_exists -eq 0 ]; then
                    log_warn "Module $module depends on $dep, but $dep is not found"
                    log_warn "Continuing installation, but $module may not work correctly"
                else
                    # Recursively visit dependency
                    if ! visit_module "$dep"; then
                        return 1
                    fi
                fi
            done <<< "$deps"
        fi
        
        # Remove from visiting
        local new_visiting=()
        for v in "${visiting[@]}"; do
            if [ "$v" != "$module" ]; then
                new_visiting+=("$v")
            fi
        done
        visiting=("${new_visiting[@]}")
        
        # Mark as visited and add to sorted list
        visited+=("$module")
        sorted+=("$module")
        
        return 0
    }
    
    # Visit all modules
    for module in "${modules[@]}"; do
        if ! visit_module "$module"; then
            log_error "Failed to resolve dependencies"
            return 1
        fi
    done
    
    echo "${sorted[@]}"
}

# Execute a command on a specific module
execute_module_command() {
    local module_path="$1"
    local command="$2"
    shift 2
    local extra_args=("$@")
    local module_setup="$SCRIPT_DIR/$module_path/setup.sh"
    
    if [ ! -f "$module_setup" ]; then
        log_error "Setup script not found: $module_setup"
        return 1
    fi
    
    if [ ! -x "$module_setup" ]; then
        log_warn "Setup script not executable, adding execute permission: $module_setup"
        chmod +x "$module_setup"
    fi
    
    log_header "Module: $module_path"
    
    # Execute the module setup script with the command and any extra args
    if ! "$module_setup" "$command" "${extra_args[@]}"; then
        log_error "Failed to execute '$command' for module: $module_path"
        return 1
    fi
    
    echo ""
    return 0
}

# Setup Adafruit Sound Bonnet (Speaker Bonnet)
# This is an optional setup that installs the necessary drivers for the Adafruit Sound Bonnet
setup_sound_bonnet() {
    log_header "Sound Bonnet Setup"
    
    echo ""
    echo "The Adafruit Sound Bonnet (Speaker Bonnet) provides high-quality I2S audio output"
    echo "for your Raspberry Pi. It is required for modules that use audio playback."
    echo ""
    echo "This will:"
    echo "  - Install required dependencies (wget, python3-pip)"
    echo "  - Install adafruit-python-shell"
    echo "  - Download and run the i2samp.py installation script"
    echo "  - Configure I2S audio in the boot configuration"
    echo ""
    echo "Note: I2C must be enabled separately via raspi-config if you need I2C devices."
    echo "      (I2C is not required for basic audio functionality)"
    echo ""
    
    log_warn "Do you want to install the Adafruit Sound Bonnet now?"
    read -p "Install Sound Bonnet? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping Sound Bonnet installation"
        log_info "You can install it later by re-running: sudo ./setup.sh install"
        echo ""
        return 0
    fi
    
    log_step "Installing Adafruit Sound Bonnet..."
    echo ""
    
    # Install dependencies
    log_info "Installing required packages..."
    local deps=("wget" "python3-pip" "python3-venv")
    for dep in "${deps[@]}"; do
        if dpkg -l "$dep" 2>/dev/null | grep -q "^ii"; then
            log_info "✓ $dep (already installed)"
        else
            log_info "Installing $dep..."
            if apt-get install -y -qq "$dep" 2>/dev/null; then
                log_info "✓ $dep installed"
            else
                log_warn "Failed to install $dep, continuing anyway"
            fi
        fi
    done
    
    echo ""
    
    # Install adafruit-python-shell
    log_info "Installing adafruit-python-shell..."
    if pip3 install --break-system-packages adafruit-python-shell >/dev/null 2>&1; then
        log_info "✓ adafruit-python-shell installed"
    else
        log_warn "Failed with --break-system-packages, trying without it..."
        if pip3 install adafruit-python-shell >/dev/null 2>&1; then
            log_info "✓ adafruit-python-shell installed"
        else
            log_error "Failed to install adafruit-python-shell"
            return 1
        fi
    fi
    
    echo ""
    
    # Download the i2samp.py installer script
    local script_url='https://github.com/adafruit/Raspberry-Pi-Installer-Scripts/raw/main/i2samp.py'
    local script_path='/tmp/i2samp.py'
    
    log_info "Downloading installation script from Adafruit..."
    if wget -q -O "$script_path" "$script_url"; then
        log_info "✓ Installation script downloaded"
    else
        log_error "Failed to download i2samp.py installation script"
        return 1
    fi
    
    # Make the script executable
    chmod +x "$script_path"
    
    echo ""
    
    # Run the installation script
    log_info "Running Sound Bonnet installation script..."
    log_info "This may take a few minutes and will configure I2S audio..."
    echo ""
    
    # The script needs to be run with environment variables preserved
    if python3 "$script_path"; then
        log_info "✓ Sound Bonnet installation complete!"
    else
        log_error "Installation script failed"
        # Clean up the downloaded script
        rm -f "$script_path" 2>/dev/null
        return 1
    fi
    
    # Clean up the downloaded script
    rm -f "$script_path" 2>/dev/null
    
    echo ""
    log_info "============================================"
    log_info "Sound Bonnet Installation Complete"
    log_info "============================================"
    echo ""
    log_warn "IMPORTANT: A reboot is required for the changes to take effect"
    log_info "After reboot, use 'alsamixer' to adjust volume (50% is a good starting point)"
    echo ""
    
    return 0
}

# Install all modules or a specific module
install_modules() {
    local specific_module="$1"
    local modules
    local failed_modules=()
    local success_count=0
    
    # Check and install required dependencies first
    if ! check_and_install_dependencies; then
        log_error "Failed to install required dependencies"
        log_error "Cannot proceed with module installation"
        return 1
    fi
    
    if [ -n "$specific_module" ]; then
        # Install specific module with its dependencies
        log_info "Installing specific module: $specific_module"
        
        # Collect the module and all its dependencies recursively
        local modules_with_deps=()
        local visited_modules=()
        
        collect_dependencies() {
            local mod="$1"
            
            # Check if already visited
            for v in "${visited_modules[@]}"; do
                if [ "$v" = "$mod" ]; then
                    return 0
                fi
            done
            
            visited_modules+=("$mod")
            
            # Get dependencies
            local deps
            deps=$(get_module_dependencies "$mod")
            
            # Recursively collect dependencies first
            if [ -n "$deps" ]; then
                while IFS= read -r dep; do
                    # Verify dependency exists
                    if [ -f "$SCRIPT_DIR/$dep/setup.sh" ]; then
                        collect_dependencies "$dep"
                    else
                        log_warn "Dependency $dep not found, $mod may not work correctly"
                    fi
                done <<< "$deps"
            fi
            
            # Add this module
            modules_with_deps+=("$mod")
        }
        
        collect_dependencies "$specific_module"
        modules=("${modules_with_deps[@]}")
        
        if [ ${#modules[@]} -gt 1 ]; then
            log_info "Installing with dependencies (${#modules[@]} module(s) total):"
            for module in "${modules[@]}"; do
                echo "  - $module"
            done
        fi
    else
        # Discover and install all modules
        read -r -a modules <<< "$(discover_modules)"
        
        if [ ${#modules[@]} -eq 0 ]; then
            log_warn "No modules found to install"
            echo ""
            echo "Place module directories with setup.sh scripts in:"
            for category in "${CATEGORIES[@]}"; do
                echo "  - $category/"
            done
            echo ""
            return 0
        fi
        
        log_info "Found ${#modules[@]} module(s) to install"
        
        # Sort modules by dependencies
        log_info "Resolving module dependencies..."
        local sorted_modules
        if ! sorted_modules=$(sort_modules_by_dependencies "${modules[@]}"); then
            log_error "Failed to resolve module dependencies"
            return 1
        fi
        
        # Update modules array with sorted order
        read -r -a modules <<< "$sorted_modules"
        
        # Log installation order
        log_info "Installation order (dependencies first):"
        for module in "${modules[@]}"; do
            echo "  - $module"
        done
    fi
    
    echo ""
    
    # Collect and install all apt packages in batch before module installation
    log_step "Collecting apt package requirements from all modules..."
    local all_packages
    mapfile -t all_packages < <(collect_all_apt_packages "${modules[@]}")
    
    if ! install_apt_packages "${all_packages[@]}"; then
        log_error "Failed to install required apt packages"
        log_error "Cannot proceed with module installation"
        return 1
    fi
    
    # Optional Sound Bonnet setup (must be done before modules that need audio)
    setup_sound_bonnet
    
    # Execute install command for each module
    for module in "${modules[@]}"; do
        if execute_module_command "$module" "install" "--skip-packages"; then
            ((success_count++))
        else
            failed_modules+=("$module")
        fi
    done
    
    # Summary
    log_header "Installation Summary"
    log_info "Successfully installed: $success_count module(s)"
    
    if [ ${#failed_modules[@]} -gt 0 ]; then
        log_error "Failed to install ${#failed_modules[@]} module(s):"
        for module in "${failed_modules[@]}"; do
            echo "  - $module"
        done
        return 1
    fi
    
    echo ""
}

# Uninstall all modules or a specific module
uninstall_modules() {
    local specific_module="$1"
    local purge_mode="$2"
    local modules
    local failed_modules=()
    local success_count=0
    
    if [ -n "$specific_module" ]; then
        # Uninstall specific module
        modules=("$specific_module")
        log_info "Uninstalling specific module: $specific_module"
    else
        # Discover and uninstall all modules
        read -r -a modules <<< "$(discover_modules)"
        
        if [ ${#modules[@]} -eq 0 ]; then
            log_warn "No modules found to uninstall"
            return 0
        fi
        
        log_info "Found ${#modules[@]} module(s) to uninstall"
    fi
    
    # Show purge warning if enabled
    if [ "$purge_mode" = "purge" ]; then
        echo ""
        log_warn "PURGE MODE ENABLED"
        log_warn "This will remove ALL Luigi files, configurations, and installed packages"
        log_warn "Your system will be restored to its pre-Luigi state"
        echo ""
        read -p "Are you absolutely sure? Type 'yes' to continue: " -r
        echo ""
        if [ "$REPLY" != "yes" ]; then
            log_info "Purge cancelled"
            return 0
        fi
    fi
    
    echo ""
    
    # Export purge mode for module scripts
    export LUIGI_PURGE_MODE="$purge_mode"
    
    # Execute uninstall command for each module with --skip-packages flag
    for module in "${modules[@]}"; do
        if execute_module_command "$module" "uninstall" "--skip-packages"; then
            ((success_count++))
        else
            failed_modules+=("$module")
        fi
    done
    
    # Collect and remove apt packages AFTER all modules are uninstalled
    if [ -z "$specific_module" ]; then
        # Only do centralized package removal when uninstalling all modules
        log_step "Collecting apt package requirements from all modules..."
        local all_packages
        mapfile -t all_packages < <(collect_all_apt_packages "${modules[@]}")
        
        if ! remove_apt_packages "$purge_mode" "${all_packages[@]}"; then
            log_warn "Some packages could not be removed"
        fi
    else
        # For specific module uninstall, show a note about packages
        echo ""
        log_info "Note: Apt packages are not removed when uninstalling a specific module"
        log_info "To remove packages, use: sudo ./setup.sh uninstall (all modules)"
        echo ""
    fi
    
    # Remove setup script dependencies if purging everything
    if [ "$purge_mode" = "purge" ] && [ -z "$specific_module" ]; then
        echo ""
        log_step "Removing setup script dependencies..."
        
        # Remove jq if it was installed
        if command -v jq >/dev/null 2>&1; then
            log_info "Removing jq..."
            if apt-get remove -y jq >/dev/null 2>&1; then
                apt-get autoremove -y >/dev/null 2>&1
                log_info "✓ jq removed"
            else
                log_warn "Failed to remove jq (may not have been installed by Luigi)"
            fi
        fi
    fi
    
    # Summary
    log_header "Uninstallation Summary"
    log_info "Successfully uninstalled: $success_count module(s)"
    
    if [ ${#failed_modules[@]} -gt 0 ]; then
        log_error "Failed to uninstall ${#failed_modules[@]} module(s):"
        for module in "${failed_modules[@]}"; do
            echo "  - $module"
        done
        return 1
    fi
    
    if [ "$purge_mode" = "purge" ]; then
        log_info "System has been restored to pre-Luigi state"
    fi
    
    echo ""
}

# Show status of all modules or a specific module
show_status() {
    local specific_module="$1"
    local modules
    
    if [ -n "$specific_module" ]; then
        # Show status of specific module
        modules=("$specific_module")
    else
        # Discover and show status of all modules
        read -r -a modules <<< "$(discover_modules)"
        
        if [ ${#modules[@]} -eq 0 ]; then
            log_warn "No modules found"
            echo ""
            echo "Place module directories with setup.sh scripts in:"
            for category in "${CATEGORIES[@]}"; do
                echo "  - $category/"
            done
            echo ""
            return 0
        fi
        
        log_info "Found ${#modules[@]} module(s)"
    fi
    
    echo ""
    
    # Execute status command for each module
    for module in "${modules[@]}"; do
        execute_module_command "$module" "status" || true
    done
}

# Show usage information
show_usage() {
    echo "Usage: $0 [install|uninstall|purge|status] [module]"
    echo ""
    echo "Commands:"
    echo "  install   - Install all modules or a specific module (default)"
    echo "  uninstall - Remove all modules or a specific module (keeps configs)"
    echo "  purge     - Remove all modules AND installed packages (complete cleanup)"
    echo "  status    - Show installation status of all modules or a specific module"
    echo ""
    echo "Arguments:"
    echo "  [module]  - Optional: specific module path (e.g., motion-detection/mario)"
    echo ""
    echo "Examples:"
    echo "  sudo $0 install                         # Install all modules"
    echo "  sudo $0 install motion-detection/mario  # Install specific module"
    echo "  sudo $0 status                          # Show status of all modules"
    echo "  sudo $0 uninstall                       # Uninstall all modules (keep configs)"
    echo "  sudo $0 purge                           # Complete removal (packages + configs)"
    echo ""
    echo "Supported categories:"
    for category in "${CATEGORIES[@]}"; do
        echo "  - $category/"
    done
    echo ""
}

# Main script
main() {
    local action="${1:-install}"
    local module="${2:-}"
    
    case "$action" in
        install)
            check_root "$@"
            install_modules "$module"
            ;;
        uninstall)
            check_root "$@"
            uninstall_modules "$module" ""
            ;;
        purge)
            check_root "$@"
            uninstall_modules "$module" "purge"
            ;;
        status)
            show_status "$module"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $action"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
