#!/bin/bash
# setup.sh - Luigi Management API installation script
# Provides install, uninstall, and status functions

set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source shared setup helpers
# shellcheck source=../../util/setup-helpers.sh
if [ -f "$REPO_ROOT/util/setup-helpers.sh" ]; then
    source "$REPO_ROOT/util/setup-helpers.sh"
else
    echo "Error: Cannot find setup-helpers.sh"
    echo "Expected location: $REPO_ROOT/util/setup-helpers.sh"
    exit 1
fi

readonly MODULE_NAME="management-api"
readonly MODULE_CATEGORY="system"

# Note: Keeping custom logging format for this script's specific needs
# These override the helper functions but maintain compatibility
log_info() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
log_debug() { echo -e "\033[0;34m[DEBUG]\033[0m $1"; }

# Detect the user who invoked sudo (fallback to current user if not using sudo)
INSTALL_USER="${SUDO_USER:-$(whoami)}"
if [ "$INSTALL_USER" = "root" ]; then
    # If running directly as root (not via sudo), try to use 'pi' if it exists
    # This handles Raspberry Pi where 'pi' is the default user
    if id -u pi >/dev/null 2>&1; then
        INSTALL_USER="pi"
        log_warn "Running as root without sudo. Defaulting to user 'pi'"
    else
        log_error "Cannot determine non-root user for installation."
        log_error "Please run this script with sudo as a regular user: sudo ./setup.sh install"
        exit 1
    fi
fi
readonly INSTALL_USER

# Get user's home directory
INSTALL_USER_HOME=$(getent passwd "$INSTALL_USER" | cut -d: -f6)
readonly INSTALL_USER_HOME

readonly APP_DIR="${INSTALL_USER_HOME}/luigi/system/management-api"
readonly CONFIG_DIR="/etc/luigi/system/management-api"
readonly SERVICE_NAME="management-api.service"
readonly SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"
readonly CERTS_DIR="${INSTALL_USER_HOME}/certs"
readonly LOG_DIR="/var/log"
readonly AUDIT_LOG_DIR="/var/log/luigi"

# Install function
install() {
    check_root
    log_info "Installing ${MODULE_NAME}..."
    
    # 1. Check prerequisites
    if [ "${SKIP_PACKAGES:-}" != "1" ]; then
        log_info "Checking prerequisites..."
        
        # Read packages from module.json
        local module_json="$SCRIPT_DIR/module.json"
        local packages=()
        
        if [ -f "$module_json" ] && command -v jq >/dev/null 2>&1; then
            # Parse apt_packages array from JSON
            while IFS= read -r pkg; do
                packages+=("$pkg")
            done < <(jq -r '.apt_packages[]? // empty' "$module_json" 2>/dev/null)
        else
            # Fallback to hardcoded packages if module.json or jq not available
            log_warn "module.json or jq not found, using fallback package list"
            packages=("nodejs" "npm" "openssl" "curl")
        fi
        
        # Check which packages need installation
        local to_install=()
        for pkg in "${packages[@]}"; do
            if ! dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
                to_install+=("$pkg")
            fi
        done
        
        # Install packages if needed
        if [ ${#to_install[@]} -gt 0 ]; then
            log_info "Installing required packages: ${to_install[*]}"
            apt-get update
            apt-get install -y "${to_install[@]}"
        fi
    else
        log_info "Skipping package installation (managed centrally)"
    fi
    
    # Verify Node.js is available and check version
    if ! command_exists node; then
        log_error "Node.js installation failed or not in PATH"
        exit 1
    fi
    
    local node_version
    node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$node_version" -lt 16 ]; then
        log_error "Node.js version 16 or higher is required (found: $(node --version))"
        exit 1
    fi
    log_info "Node.js version: $(node --version) ✓"
    
    # 2. Create directory structure
    log_info "Creating directories..."
    mkdir -p "$APP_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$AUDIT_LOG_DIR"
    mkdir -p "$CERTS_DIR"
    
    # 3. Copy application files
    log_info "Copying application files..."
    cp -r "$SCRIPT_DIR"/* "$APP_DIR/"
    
    # Set ownership
    chown -R "${INSTALL_USER}:${INSTALL_USER}" "$APP_DIR"
    
    # 4. Install Node.js dependencies
    log_info "Installing Node.js dependencies..."
    cd "$APP_DIR"
    sudo -u "$INSTALL_USER" npm install --production --no-audit
    
    # Run npm audit
    log_info "Running security audit..."
    sudo -u "$INSTALL_USER" npm audit --audit-level=moderate || log_warn "Some vulnerabilities found - review with 'npm audit'"
    
    # 4.5. Build frontend
    log_info "Building web frontend..."
    if [ -d "$APP_DIR/frontend" ]; then
        # Check if frontend is already built
        local should_build=true
        if [ -d "$APP_DIR/frontend/dist" ] && [ -n "$(ls -A "$APP_DIR/frontend/dist" 2>/dev/null)" ]; then
            log_info "Frontend build already exists in $APP_DIR/frontend/dist"
            read -r -p "Do you want to rebuild the frontend? (y/N): " rebuild_choice
            echo
            if [[ ! $rebuild_choice =~ ^[Yy]$ ]]; then
                log_info "Skipping frontend rebuild (using existing build)"
                should_build=false
            else
                log_info "Proceeding with frontend rebuild..."
            fi
        fi
        
        if [ "$should_build" = true ]; then
            (
                cd "$APP_DIR/frontend" || exit 1
                
                # Install frontend dependencies
                log_info "Installing frontend dependencies..."
                sudo -u "$INSTALL_USER" npm install --no-audit
                
                # Run type check
                log_info "Running TypeScript type check..."
                sudo -u "$INSTALL_USER" npm run type-check
                
                # Build production bundle
                log_info "Building production bundle..."
                sudo -u "$INSTALL_USER" npm run build
            )
            
            # Verify dist directory exists
            if [ -d "$APP_DIR/frontend/dist" ]; then
                log_info "Frontend build successful ✓"
            else
                log_error "Frontend build failed - dist directory not found"
                exit 1
            fi
        fi
    else
        log_warn "Frontend directory not found, skipping frontend build"
    fi
    
    # 5. Deploy configuration
    log_info "Deploying configuration..."
    if [ ! -f "$CONFIG_DIR/.env" ]; then
        cp "$APP_DIR/.env.example" "$CONFIG_DIR/.env"
        chmod 600 "$CONFIG_DIR/.env"
        chown "${INSTALL_USER}:${INSTALL_USER}" "$CONFIG_DIR/.env"
        
        log_warn "Configuration file created: $CONFIG_DIR/.env"
        log_warn "IMPORTANT: You must edit this file and set a secure password!"
        log_warn ""
        log_warn "  sudo nano $CONFIG_DIR/.env"
        log_warn ""
        log_warn "Change AUTH_PASSWORD to a strong password (minimum 12 characters)"
        
        # Prompt for password
        read -p "Press Enter to edit the configuration file now, or Ctrl+C to exit..." -r
        nano "$CONFIG_DIR/.env"
    else
        log_info "Configuration file already exists, skipping"
    fi
    
    # 6. Generate TLS certificates
    log_info "Checking TLS certificates..."
    if [ ! -f "$CERTS_DIR/server.crt" ] || [ ! -f "$CERTS_DIR/server.key" ]; then
        log_info "Generating self-signed TLS certificates..."
        bash "$APP_DIR/scripts/generate-certs.sh"
    else
        log_info "TLS certificates already exist"
    fi
    
    # 7. Deploy systemd service
    log_info "Installing systemd service..."
    
    # Generate service file with correct user and paths
    sed -e "s|User=pi|User=${INSTALL_USER}|g" \
        -e "s|Group=pi|Group=${INSTALL_USER}|g" \
        -e "s|WorkingDirectory=/home/pi/luigi/system/management-api|WorkingDirectory=${APP_DIR}|g" \
        "$APP_DIR/management-api.service" > "$SERVICE_FILE"
    
    chmod 644 "$SERVICE_FILE"
    systemctl daemon-reload
    
    # 8. Enable and start service
    log_info "Enabling and starting service..."
    systemctl enable "$SERVICE_NAME"
    systemctl start "$SERVICE_NAME"
    
    # Wait for service to start
    sleep 3
    
    # 9. Verify installation
    log_info "Verifying installation..."
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_info "Service is running ✓"
        
        # Test API
        local health_url="https://localhost:8443/health"
        if curl -k -s "$health_url" | grep -q "ok"; then
            log_info "API health check passed ✓"
        else
            log_warn "API health check failed - service may still be starting"
        fi
    else
        log_error "Service failed to start"
        systemctl status "$SERVICE_NAME" --no-pager -l
        exit 1
    fi
    
    # Display access information
    log_info ""
    log_info "✓ Installation complete!"
    log_info ""
    log_info "Access the Web Frontend at: https://<raspberry-pi-ip>:8443"
    log_info "API endpoint: https://<raspberry-pi-ip>:8443/api"
    log_info "Health check: https://<raspberry-pi-ip>:8443/health"
    log_info "API documentation: $APP_DIR/README.md"
    log_info "Frontend documentation: $APP_DIR/frontend/README.md"
    log_info ""
    log_info "Default credentials (CHANGE THESE!):"
    log_info "  Username: admin"
    log_info "  Password: (set in $CONFIG_DIR/.env)"
    log_info ""
    log_info "Service management:"
    log_info "  Status:  sudo systemctl status $SERVICE_NAME"
    log_info "  Start:   sudo systemctl start $SERVICE_NAME"
    log_info "  Stop:    sudo systemctl stop $SERVICE_NAME"
    log_info "  Restart: sudo systemctl restart $SERVICE_NAME"
    log_info "  Logs:    sudo journalctl -u $SERVICE_NAME -f"
    log_info ""
}

# Build function - builds frontend and backend without full installation
# Builds in place (in the repository directory) for development workflows
build() {
    log_info "Building ${MODULE_NAME} in place..."
    
    # For build command, check if we're running with sudo
    # If so, we'll use INSTALL_USER; otherwise use current user
    local build_user="$USER"
    local use_sudo=""
    if [ -n "${SUDO_USER:-}" ]; then
        build_user="$INSTALL_USER"
        use_sudo="sudo -u $INSTALL_USER"
        log_info "Running as sudo, will build as user: $build_user"
    else
        log_info "Running as user: $build_user"
    fi
    
    # 1. Check prerequisites
    if [ "${SKIP_PACKAGES:-}" != "1" ]; then
        # Package installation requires root
        if [ "$EUID" -ne 0 ]; then
            log_warn "Package installation requires root privileges"
            log_warn "Run with sudo to install packages, or use --skip-packages"
        else
            log_info "Checking prerequisites..."
            
            # Read packages from module.json
            local module_json="$SCRIPT_DIR/module.json"
            local packages=()
            
            if [ -f "$module_json" ] && command -v jq >/dev/null 2>&1; then
                # Parse apt_packages array from JSON
                while IFS= read -r pkg; do
                    packages+=("$pkg")
                done < <(jq -r '.apt_packages[]? // empty' "$module_json" 2>/dev/null)
            else
                # Fallback to hardcoded packages if module.json or jq not available
                log_warn "module.json or jq not found, using fallback package list"
                packages=("nodejs" "npm" "openssl" "curl")
            fi
            
            # Check which packages need installation
            local to_install=()
            for pkg in "${packages[@]}"; do
                if ! dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
                    to_install+=("$pkg")
                fi
            done
            
            # Install packages if needed
            if [ ${#to_install[@]} -gt 0 ]; then
                log_info "Installing required packages: ${to_install[*]}"
                apt-get update
                apt-get install -y "${to_install[@]}"
            fi
        fi
    else
        log_info "Skipping package installation (managed centrally)"
    fi
    
    # Verify Node.js is available and check version
    if ! command_exists node; then
        log_error "Node.js installation failed or not in PATH"
        exit 1
    fi
    
    local node_version
    node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$node_version" -lt 16 ]; then
        log_error "Node.js version 16 or higher is required (found: $(node --version))"
        exit 1
    fi
    log_info "Node.js version: $(node --version) ✓"
    
    # 2. Install Node.js dependencies (in place)
    log_info "Installing Node.js dependencies..."
    cd "$SCRIPT_DIR"
    $use_sudo npm install --production --no-audit
    
    # Run npm audit
    log_info "Running security audit..."
    $use_sudo npm audit --audit-level=moderate || log_warn "Some vulnerabilities found - review with 'npm audit'"
    
    # 3. Build frontend (in place)
    log_info "Building web frontend..."
    if [ -d "$SCRIPT_DIR/frontend" ]; then
        # Check if frontend is already built
        local should_build=true
        if [ -d "$SCRIPT_DIR/frontend/dist" ] && [ -n "$(ls -A "$SCRIPT_DIR/frontend/dist" 2>/dev/null)" ]; then
            log_info "Frontend build already exists in $SCRIPT_DIR/frontend/dist"
            read -r -p "Do you want to rebuild the frontend? (y/N): " rebuild_choice
            echo
            if [[ ! $rebuild_choice =~ ^[Yy]$ ]]; then
                log_info "Skipping frontend rebuild (using existing build)"
                should_build=false
            else
                log_info "Proceeding with frontend rebuild..."
            fi
        fi
        
        if [ "$should_build" = true ]; then
            (
                cd "$SCRIPT_DIR/frontend" || exit 1
                
                # Install frontend dependencies
                log_info "Installing frontend dependencies..."
                $use_sudo npm install --no-audit
                
                # Run type check
                log_info "Running TypeScript type check..."
                $use_sudo npm run type-check
                
                # Build production bundle
                log_info "Building production bundle..."
                $use_sudo npm run build
            )
            
            # Verify dist directory exists
            if [ -d "$SCRIPT_DIR/frontend/dist" ]; then
                log_info "Frontend build successful ✓"
            else
                log_error "Frontend build failed - dist directory not found"
                exit 1
            fi
        fi
    else
        log_warn "Frontend directory not found, skipping frontend build"
    fi
    
    # Display build information
    log_info ""
    log_info "✓ Build complete!"
    log_info ""
    log_info "Built files location: $SCRIPT_DIR"
    log_info "Backend: $SCRIPT_DIR (Node.js dependencies installed)"
    log_info "Frontend: $SCRIPT_DIR/frontend/dist"
    log_info ""
    log_info "Note: Built in place (repository directory)"
    log_info "For full installation with deployment, run: sudo ./setup.sh install"
    log_info ""
}

# Uninstall function
uninstall() {
    check_root
    log_info "Uninstalling ${MODULE_NAME}..."
    
    # Check if purge mode is enabled
    local purge_mode="${LUIGI_PURGE_MODE:-}"
    local remove_config="N"
    local remove_logs="N"
    local remove_certs="N"
    local remove_packages="N"
    
    if [ "$purge_mode" = "purge" ]; then
        log_warn "PURGE MODE: Removing all files, configs, and packages"
        remove_config="y"
        remove_logs="y"
        remove_certs="y"
        remove_packages="y"
    fi
    
    # 1. Stop and disable service
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_info "Stopping service..."
        systemctl stop "$SERVICE_NAME"
    fi
    
    if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
        log_info "Disabling service..."
        systemctl disable "$SERVICE_NAME"
    fi
    
    # 2. Remove service file
    if [ -f "$SERVICE_FILE" ]; then
        log_info "Removing service file..."
        rm -f "$SERVICE_FILE"
        systemctl daemon-reload
    fi
    
    # 3. Remove application files
    if [ -d "$APP_DIR" ]; then
        log_info "Removing application directory..."
        rm -rf "$APP_DIR"
    fi
    
    # 4. Handle configuration removal
    if [ "$purge_mode" != "purge" ] && [ -d "$CONFIG_DIR" ]; then
        log_warn "Configuration directory exists: $CONFIG_DIR"
        read -p "Remove configuration? (y/N): " -n 1 -r
        echo
        remove_config=$REPLY
    fi
    
    if [[ $remove_config =~ ^[Yy]$ ]]; then
        if [ -d "$CONFIG_DIR" ]; then
            log_info "Removing configuration..."
            rm -rf "$CONFIG_DIR"
        fi
    else
        [ -d "$CONFIG_DIR" ] && log_info "Keeping configuration"
    fi
    
    # 5. Handle log removal
    if [ "$purge_mode" != "purge" ]; then
        log_warn "Log files exist in $LOG_DIR"
        read -p "Remove log files? (y/N): " -n 1 -r
        echo
        remove_logs=$REPLY
    fi
    
    if [[ $remove_logs =~ ^[Yy]$ ]]; then
        log_info "Removing log files..."
        rm -f "$LOG_DIR/management-api.log"* 2>/dev/null
        rm -rf "$AUDIT_LOG_DIR" 2>/dev/null
    else
        log_info "Keeping log files"
    fi
    
    # 6. Handle certificate removal
    if [ "$purge_mode" != "purge" ] && [ -d "$CERTS_DIR" ]; then
        log_warn "TLS certificates exist in $CERTS_DIR"
        read -p "Remove certificates? (y/N): " -n 1 -r
        echo
        remove_certs=$REPLY
    fi
    
    if [[ $remove_certs =~ ^[Yy]$ ]]; then
        if [ -d "$CERTS_DIR" ]; then
            log_info "Removing certificates..."
            rm -rf "$CERTS_DIR"
        fi
    else
        [ -d "$CERTS_DIR" ] && log_info "Keeping certificates"
    fi
    
    # 7. Remove packages if in purge mode or requested
    if [ "$purge_mode" != "purge" ] && [ "${SKIP_PACKAGES:-}" != "1" ]; then
        echo ""
        # Read packages from module.json for display
        local package_list="nodejs, npm, openssl, curl"
        if [ -f "$SCRIPT_DIR/module.json" ] && command -v jq >/dev/null 2>&1; then
            local packages_json
            packages_json=$(jq -r '.apt_packages | join(", ")' "$SCRIPT_DIR/module.json" 2>/dev/null)
            [ -n "$packages_json" ] && package_list="$packages_json"
        fi
        read -p "Remove installed packages ($package_list)? (y/N): " -n 1 -r
        echo
        remove_packages=$REPLY
    fi
    
    if [ "${SKIP_PACKAGES:-}" = "1" ]; then
        log_info "Skipping package removal (managed centrally)"
    elif [[ $remove_packages =~ ^[Yy]$ ]]; then
        log_step "Removing packages..."
        
        # Read packages from module.json
        local packages=()
        if [ -f "$SCRIPT_DIR/module.json" ] && command -v jq >/dev/null 2>&1; then
            while IFS= read -r pkg; do
                packages+=("$pkg")
            done < <(jq -r '.apt_packages[]? // empty' "$SCRIPT_DIR/module.json" 2>/dev/null)
        else
            # Fallback to hardcoded packages
            packages=("nodejs" "npm")
        fi
        
        for pkg in "${packages[@]}"; do
            if dpkg -l | grep -q "^ii  $pkg "; then
                log_info "Removing $pkg..."
                apt-get remove -y "$pkg" >/dev/null 2>&1 || log_warn "Failed to remove $pkg"
            fi
        done
        
        # Clean up unused dependencies
        log_info "Removing unused dependencies..."
        apt-get autoremove -y >/dev/null 2>&1
    fi
    
    log_info "✓ Uninstall complete!"
}

# Status function
status() {
    log_info "Checking ${MODULE_NAME} status..."
    echo ""
    
    # Service status
    echo "=== Service Status ==="
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo "✓ Service is running"
        systemctl status "$SERVICE_NAME" --no-pager -l
    else
        echo "✗ Service is not running"
        if [ -f "$SERVICE_FILE" ]; then
            echo "  Service file exists: $SERVICE_FILE"
        else
            echo "  Service file not found"
        fi
    fi
    echo ""
    
    # Installation check
    echo "=== Installation ==="
    if [ -d "$APP_DIR" ]; then
        echo "✓ Application directory: $APP_DIR"
    else
        echo "✗ Application directory not found"
    fi
    
    if [ -f "$CONFIG_DIR/.env" ]; then
        echo "✓ Configuration file: $CONFIG_DIR/.env"
    else
        echo "✗ Configuration file not found"
    fi
    
    if [ -f "$CERTS_DIR/server.crt" ] && [ -f "$CERTS_DIR/server.key" ]; then
        echo "✓ TLS certificates: $CERTS_DIR"
    else
        echo "✗ TLS certificates not found"
    fi
    
    if [ -d "$APP_DIR/frontend/dist" ]; then
        echo "✓ Frontend built: $APP_DIR/frontend/dist"
    else
        echo "✗ Frontend not built (run: cd $APP_DIR/frontend && npm run build)"
    fi
    echo ""
    
    # API health check
    echo "=== API Health Check ==="
    if curl -k -s https://localhost:8443/health 2>/dev/null | grep -q "ok"; then
        echo "✓ API is responding"
    else
        echo "✗ API is not responding"
    fi
    echo ""
    
    # Recent logs
    echo "=== Recent Logs (last 10 lines) ==="
    if command_exists journalctl && systemctl is-active --quiet "$SERVICE_NAME"; then
        journalctl -u "$SERVICE_NAME" -n 10 --no-pager
    else
        echo "No logs available"
    fi
    echo ""
    
    # Access information
    echo "=== Access Information ==="
    echo "Web Frontend: https://<raspberry-pi-ip>:8443"
    echo "API endpoint: https://<raspberry-pi-ip>:8443/api"
    echo "Health check: https://<raspberry-pi-ip>:8443/health"
    echo "Configuration: $CONFIG_DIR/.env"
    echo "Application: $APP_DIR"
    echo "Logs: sudo journalctl -u $SERVICE_NAME -f"
    echo ""
}

# Main
# Parse command and flags
action="${1:-}"
shift || true

# Parse flags
while [ $# -gt 0 ]; do
    case "$1" in
        --skip-packages)
            export SKIP_PACKAGES=1
            shift
            ;;
        *)
            shift
            ;;
    esac
done

case "$action" in
    install)
        install
        ;;
    build)
        build
        ;;
    uninstall)
        uninstall
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {install|build|uninstall|status} [--skip-packages]"
        echo ""
        echo "Commands:"
        echo "  install         - Full installation (copies to ~/luigi, deploys config/certs/service)"
        echo "  build           - Build in place (repository directory) - for development"
        echo "  uninstall       - Remove installation"
        echo "  status          - Check installation status"
        echo ""
        echo "Options:"
        echo "  --skip-packages - Skip apt package installation/removal (for centralized management)"
        exit 1
        ;;
esac
