#!/bin/bash
# setup.sh - Luigi Management API installation script
# Provides install, uninstall, and status functions

set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MODULE_NAME="management-api"
readonly MODULE_CATEGORY="system"
readonly APP_DIR="/home/pi/luigi/system/management-api"
readonly CONFIG_DIR="/etc/luigi/system/management-api"
readonly SERVICE_NAME="management-api.service"
readonly SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"
readonly CERTS_DIR="/home/pi/certs"
readonly LOG_DIR="/var/log"
readonly AUDIT_LOG_DIR="/var/log/luigi"

# Color output functions
log_info() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
log_debug() { echo -e "\033[0;34m[DEBUG]\033[0m $1"; }

# Check root privileges
require_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Install function
install() {
    require_root
    log_info "Installing ${MODULE_NAME}..."
    
    # 1. Check prerequisites
    log_info "Checking prerequisites..."
    
    # Check Node.js
    if ! command_exists node; then
        log_error "Node.js not found. Installing..."
        apt-get update
        apt-get install -y nodejs npm
    fi
    
    # Verify Node.js version
    local node_version
    node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$node_version" -lt 16 ]; then
        log_error "Node.js version 16 or higher is required (found: $(node --version))"
        exit 1
    fi
    log_info "Node.js version: $(node --version) ✓"
    
    # Check other dependencies
    for cmd in npm openssl curl; do
        if ! command_exists "$cmd"; then
            log_error "$cmd not found. Installing..."
            apt-get install -y "$cmd"
        fi
    done
    
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
    chown -R pi:pi "$APP_DIR"
    
    # 4. Install Node.js dependencies
    log_info "Installing Node.js dependencies..."
    cd "$APP_DIR"
    sudo -u pi npm install --production --no-audit
    
    # Run npm audit
    log_info "Running security audit..."
    sudo -u pi npm audit --audit-level=moderate || log_warn "Some vulnerabilities found - review with 'npm audit'"
    
    # 4.5. Build frontend
    log_info "Building web frontend..."
    if [ -d "$APP_DIR/frontend" ]; then
        (
            cd "$APP_DIR/frontend" || exit 1
            
            # Install frontend dependencies
            log_info "Installing frontend dependencies..."
            sudo -u pi npm install --no-audit
            
            # Run type check
            log_info "Running TypeScript type check..."
            sudo -u pi npm run type-check
            
            # Build production bundle
            log_info "Building production bundle..."
            sudo -u pi npm run build
        )
        
        # Verify dist directory exists
        if [ -d "$APP_DIR/frontend/dist" ]; then
            log_info "Frontend build successful ✓"
        else
            log_error "Frontend build failed - dist directory not found"
            exit 1
        fi
    else
        log_warn "Frontend directory not found, skipping frontend build"
    fi
    
    # 5. Deploy configuration
    log_info "Deploying configuration..."
    if [ ! -f "$CONFIG_DIR/.env" ]; then
        cp "$APP_DIR/.env.example" "$CONFIG_DIR/.env"
        chmod 600 "$CONFIG_DIR/.env"
        chown pi:pi "$CONFIG_DIR/.env"
        
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
    cp "$APP_DIR/management-api.service" "$SERVICE_FILE"
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

# Uninstall function
uninstall() {
    require_root
    log_info "Uninstalling ${MODULE_NAME}..."
    
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
    
    # 4. Ask about configuration removal
    if [ -d "$CONFIG_DIR" ]; then
        log_warn "Configuration directory exists: $CONFIG_DIR"
        read -p "Remove configuration? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Removing configuration..."
            rm -rf "$CONFIG_DIR"
        else
            log_info "Keeping configuration"
        fi
    fi
    
    # 5. Ask about log removal
    log_warn "Log files exist in $LOG_DIR"
    read -p "Remove log files? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Removing log files..."
        rm -f "$LOG_DIR/management-api.log"*
        rm -rf "$AUDIT_LOG_DIR"
    else
        log_info "Keeping log files"
    fi
    
    # 6. Ask about certificate removal
    if [ -d "$CERTS_DIR" ]; then
        log_warn "TLS certificates exist in $CERTS_DIR"
        read -p "Remove certificates? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Removing certificates..."
            rm -rf "$CERTS_DIR"
        else
            log_info "Keeping certificates"
        fi
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
case "${1:-}" in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {install|uninstall|status}"
        exit 1
        ;;
esac
