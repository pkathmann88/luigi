#!/bin/bash
################################################################################
# Luigi Management Frontend - Setup Script
#
# Installs the React-based web interface as a standalone module.
# Frontend is served via nginx and communicates with management-api backend.
#
# Usage: sudo ./setup.sh [install|uninstall|status|build]
#
# Author: Luigi Project
################################################################################

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

readonly MODULE_NAME="management-frontend"
readonly MODULE_CATEGORY="system"

# Custom logging for this script
log_info() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
log_debug() { echo -e "\033[0;34m[DEBUG]\033[0m $1"; }

# Installation paths
readonly FRONTEND_DIR="/var/lib/luigi-frontend"
readonly NGINX_SITE_CONFIG="/etc/nginx/sites-available/luigi-frontend"
readonly NGINX_SITE_ENABLED="/etc/nginx/sites-enabled/luigi-frontend"
readonly SERVICE_NAME="management-frontend.service"
readonly SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"

# TLS certificate paths (shared with management-api backend)
readonly CERTS_DIR="/etc/luigi/system/management-api/certs"
readonly CERT_FILE="${CERTS_DIR}/server.crt"
readonly KEY_FILE="${CERTS_DIR}/server.key"

# Detect build user (for npm operations)
BUILD_USER="${SUDO_USER:-$(whoami)}"
if [ "$BUILD_USER" = "root" ]; then
    if id -u pi >/dev/null 2>&1; then
        BUILD_USER="pi"
        log_warn "Running as root without sudo. Using 'pi' for build operations"
    else
        log_error "Cannot determine user for build operations."
        log_error "Please run this script with sudo as a regular user: sudo ./setup.sh install"
        exit 1
    fi
fi
readonly BUILD_USER

# Function to install packages
install_packages() {
    # Check if --skip-packages flag is set (use helper function)
    if should_skip_packages; then
        log_info "Skipping package installation (managed centrally)"
        return 0
    fi
    
    log_info "Installing required packages..."
    
    # Read packages from module.json using helper function
    local module_json="$SCRIPT_DIR/module.json"
    local packages=($(read_apt_packages "$module_json"))
    
    if [ ${#packages[@]} -eq 0 ]; then
        # Fallback to hardcoded packages if module.json not available
        log_warn "module.json not found or jq not available, using fallback package list"
        packages=("nginx" "nodejs" "npm")
    fi
    
    # Check if packages are needed
    local to_install=()
    for pkg in "${packages[@]}"; do
        if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
            log_success "$pkg already installed"
        else
            to_install+=("$pkg")
        fi
    done
    
    # Install packages if needed
    if [ ${#to_install[@]} -gt 0 ]; then
        # Update package list
        if ! apt-get update >/dev/null 2>&1; then
            log_error "Failed to update package list"
            return 1
        fi
        
        # Install each package
        for pkg in "${to_install[@]}"; do
            log_info "Installing $pkg..."
            if apt-get install -y "$pkg" >/dev/null 2>&1; then
                log_success "$pkg installed"
            else
                log_error "Failed to install $pkg"
                return 1
            fi
        done
    fi
    
    return 0
}

# Build function - builds frontend in source directory
build() {
    log_info "Building frontend..."
    
    if [ ! -d "$SCRIPT_DIR/frontend" ]; then
        log_error "Frontend directory not found at $SCRIPT_DIR/frontend"
        exit 1
    fi
    
    # Check if already built
    if [ -d "$SCRIPT_DIR/frontend/dist" ] && [ -n "$(ls -A "$SCRIPT_DIR/frontend/dist" 2>/dev/null)" ]; then
        log_info "Frontend already built in $SCRIPT_DIR/frontend/dist"
        read -p "Do you want to rebuild? (y/N): " -n 1 -r rebuild_choice
        echo
        if [[ ! $rebuild_choice =~ ^[Yy]$ ]]; then
            log_info "Skipping rebuild"
            return 0
        fi
    fi
    
    log_info "Building frontend in source directory..."
    (
        cd "$SCRIPT_DIR/frontend" || exit 1
        
        # Determine user context for npm commands
        local use_sudo=""
        if [ -n "${SUDO_USER:-}" ]; then
            use_sudo="sudo -u $BUILD_USER"
        fi
        
        # Install dependencies
        log_info "Installing frontend dependencies..."
        $use_sudo npm install --no-audit
        
        # Type check
        log_info "Running TypeScript type check..."
        $use_sudo npm run type-check
        
        # Build production bundle
        log_info "Building production bundle..."
        $use_sudo npm run build
    )
    
    if [ -d "$SCRIPT_DIR/frontend/dist" ]; then
        log_success "Frontend build successful ✓"
    else
        log_error "Frontend build failed - dist directory not found"
        exit 1
    fi
}

# Check and generate TLS certificates if needed
check_and_generate_certificates() {
    log_info "Checking TLS certificates..."
    
    # Check if certificates already exist
    if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
        log_info "TLS certificates already exist at $CERTS_DIR"
        
        # Verify certificate is valid
        if openssl x509 -checkend 86400 -noout -in "$CERT_FILE" >/dev/null 2>&1; then
            log_success "Existing certificates are valid"
            return 0
        else
            log_warn "Existing certificate is expired or invalid"
            log_info "Regenerating certificates..."
        fi
    else
        log_info "TLS certificates not found, generating new certificates..."
    fi
    
    # Create certs directory if it doesn't exist
    mkdir -p "$CERTS_DIR"
    
    # Generate self-signed certificate
    log_info "Generating self-signed SSL certificate..."
    cd "$CERTS_DIR"
    
    # Generate private key
    openssl genrsa -out server.key 2048 2>/dev/null
    
    # Generate certificate signing request
    openssl req -new -key server.key -out server.csr \
        -subj "/C=US/ST=State/L=City/O=Luigi/CN=raspberrypi.local" 2>/dev/null
    
    # Generate self-signed certificate (valid for 365 days)
    openssl x509 -req -days 365 -in server.csr \
        -signkey server.key -out server.crt 2>/dev/null
    
    # Set proper permissions
    # Private key: readable by owner and group
    chmod 640 server.key
    # Certificate: world-readable (public certificate)
    chmod 644 server.crt
    
    # Set ownership - allow both nginx and management-api to read
    # nginx typically runs as www-data, but we'll use root:root and rely on 644/640 perms
    chown root:root server.key server.crt
    
    # Clean up CSR
    rm -f server.csr
    
    log_success "TLS certificates generated successfully"
    log_info "Certificate: $CERT_FILE"
    log_info "Private key: $KEY_FILE"
}

# Install function
install() {
    check_root
    log_info "Installing ${MODULE_NAME}..."
    
    # Check if management-api is installed (dependency)
    if [ ! -f /etc/systemd/system/management-api.service ]; then
        log_warn "management-api.service not found"
        log_warn "The frontend requires management-api backend to be installed first"
        read -p "Continue anyway? (y/N): " -n 1 -r continue_choice
        echo
        if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
            log_error "Installation cancelled. Please install management-api first."
            exit 1
        fi
    fi
    
    # 1. Install apt packages
    log_info "Installing system packages..."
    install_packages
    
    # 2. Build frontend if not already built
    if [ ! -d "$SCRIPT_DIR/frontend/dist" ]; then
        log_info "Frontend not built, building now..."
        build
    fi
    
    # 3. Create deployment directory
    log_info "Creating deployment directory..."
    mkdir -p "$FRONTEND_DIR"
    
    # 4. Deploy built frontend files
    log_info "Deploying frontend files to $FRONTEND_DIR..."
    if [ -d "$SCRIPT_DIR/frontend/dist" ]; then
        cp -r "$SCRIPT_DIR/frontend/dist" "$FRONTEND_DIR/"
        log_success "Frontend files deployed"
    else
        log_error "Frontend dist directory not found. Run './setup.sh build' first."
        exit 1
    fi
    
    # 5. Check and generate TLS certificates
    check_and_generate_certificates
    
    # 6. Configure nginx
    log_info "Configuring nginx..."
    
    # Remove default nginx site if it exists
    if [ -L "/etc/nginx/sites-enabled/default" ]; then
        log_info "Removing default nginx site..."
        rm -f /etc/nginx/sites-enabled/default
    fi
    
    # Install our nginx configuration
    cp "$SCRIPT_DIR/nginx-site.conf" "$NGINX_SITE_CONFIG"
    ln -sf "$NGINX_SITE_CONFIG" "$NGINX_SITE_ENABLED"
    log_success "Nginx configuration installed"
    
    # Test nginx configuration
    log_info "Testing nginx configuration..."
    if nginx -t; then
        log_success "Nginx configuration valid"
    else
        log_error "Nginx configuration test failed"
        exit 1
    fi
    
    # 7. Install systemd service
    log_info "Installing systemd service..."
    cp "$SCRIPT_DIR/$SERVICE_NAME" "$SERVICE_FILE"
    systemctl daemon-reload
    log_success "Systemd service installed"
    
    # 8. Register module in Luigi registry
    log_info "Registering module in Luigi registry..."
    update_module_registry_full \
        "$MODULE_CATEGORY/$MODULE_NAME" \
        "$SCRIPT_DIR/module.json" \
        "installed"
    
    # 9. Enable and start services
    log_info "Enabling and starting services..."
    
    # Ensure nginx is enabled and running
    systemctl enable nginx.service
    systemctl restart nginx.service
    
    # Enable our management-frontend service (it will trigger nginx reload)
    systemctl enable "$SERVICE_NAME"
    systemctl start "$SERVICE_NAME"
    
    log_success "Services started successfully"
    
    # 10. Display status
    echo ""
    log_success "Installation complete!"
    echo ""
    echo "Frontend is now available at:"
    echo "  https://$(hostname -I | awk '{print $1}')/"
    echo "  https://localhost/"
    echo ""
    echo "Note: HTTP requests on port 80 are automatically redirected to HTTPS"
    echo ""
    echo "The frontend communicates with the backend API at https://localhost:8443"
    echo ""
    echo "Commands:"
    echo "  sudo systemctl status nginx"
    echo "  sudo systemctl status $SERVICE_NAME"
    echo "  sudo journalctl -u nginx -f"
    echo ""
}

# Uninstall function
uninstall() {
    check_root
    log_info "Uninstalling ${MODULE_NAME}..."
    
    # 1. Stop and disable services
    log_info "Stopping services..."
    systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    systemctl disable "$SERVICE_NAME" 2>/dev/null || true
    
    # 2. Remove systemd service
    if [ -f "$SERVICE_FILE" ]; then
        rm -f "$SERVICE_FILE"
        systemctl daemon-reload
        log_success "Systemd service removed"
    fi
    
    # 3. Remove nginx configuration
    log_info "Removing nginx configuration..."
    rm -f "$NGINX_SITE_ENABLED"
    rm -f "$NGINX_SITE_CONFIG"
    
    # Reload nginx to apply changes
    if systemctl is-active --quiet nginx; then
        systemctl reload nginx || true
    fi
    log_success "Nginx configuration removed"
    
    # 4. Remove deployed files
    log_info "Removing deployed files..."
    if [ -d "$FRONTEND_DIR" ]; then
        rm -rf "$FRONTEND_DIR"
        log_success "Deployment directory removed"
    fi
    
    # 5. Mark module as removed in registry
    log_info "Updating module registry..."
    mark_module_removed "$MODULE_CATEGORY/$MODULE_NAME"
    
    log_success "Uninstallation complete!"
}

# Status function
status() {
    echo ""
    echo "========================================"
    echo "Luigi Management Frontend - Status"
    echo "========================================"
    echo ""
    
    # Check if frontend files are deployed
    if [ -d "$FRONTEND_DIR/dist" ]; then
        echo "✓ Frontend files: Deployed at $FRONTEND_DIR/dist"
    else
        echo "✗ Frontend files: Not deployed"
    fi
    
    # Check nginx configuration
    if [ -f "$NGINX_SITE_CONFIG" ]; then
        echo "✓ Nginx config: Installed"
        if [ -L "$NGINX_SITE_ENABLED" ]; then
            echo "  └─ Enabled"
        else
            echo "  └─ Not enabled"
        fi
    else
        echo "✗ Nginx config: Not installed"
    fi
    
    # Check systemd service
    if [ -f "$SERVICE_FILE" ]; then
        echo "✓ Systemd service: Installed"
        if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
            echo "  └─ Enabled"
        else
            echo "  └─ Disabled"
        fi
        if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
            echo "  └─ Active"
        else
            echo "  └─ Inactive"
        fi
    else
        echo "✗ Systemd service: Not installed"
    fi
    
    # Check nginx status
    echo ""
    echo "Nginx Status:"
    systemctl status nginx --no-pager -l || true
    
    echo ""
    echo "Frontend Service Status:"
    systemctl status "$SERVICE_NAME" --no-pager -l || true
    
    echo ""
    echo "========================================"
}

# Main script logic
main() {
    local command="${1:-}"
    
    case "$command" in
        install)
            install
            ;;
        uninstall)
            uninstall
            ;;
        status)
            status
            ;;
        build)
            build
            ;;
        *)
            echo "Usage: $0 {install|uninstall|status|build}"
            echo ""
            echo "Commands:"
            echo "  install     - Install and configure the frontend module"
            echo "  uninstall   - Remove the frontend module"
            echo "  status      - Show installation and service status"
            echo "  build       - Build the frontend in source directory"
            exit 1
            ;;
    esac
}

main "$@"
