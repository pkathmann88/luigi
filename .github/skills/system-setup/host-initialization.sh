#!/bin/bash
#
# Raspberry Pi Host Initialization Script
#
# Configures a fresh Raspberry Pi Zero W installation with best practices
# Run this BEFORE deploying the Luigi project
#
# Usage: ./host-initialization.sh
#

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_FILE="/var/log/host_init.log"

# Logging functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
    log "SUCCESS: $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
    log "ERROR: $1"
}

warning() {
    echo -e "${YELLOW}!${NC} $1"
    log "WARNING: $1"
}

info() {
    echo -e "${BLUE}→${NC} $1"
}

# Check if running as correct user
check_user() {
    if [ "$EUID" -eq 0 ]; then
        error "Do not run as root. Script will request sudo when needed."
        exit 1
    fi
}

# Display system information
show_system_info() {
    echo "========================================"
    echo "  Raspberry Pi Host Initialization"
    echo "========================================"
    echo ""
    echo "System Information:"
    
    if [ -f /proc/device-tree/model ]; then
        echo "  Model: $(cat /proc/device-tree/model)"
    fi
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "  OS: $PRETTY_NAME"
    fi
    
    echo "  Kernel: $(uname -r)"
    echo "  Hostname: $(hostname)"
    echo "  User: $USER"
    echo ""
}

# Update system packages
update_system() {
    info "Updating system packages..."
    log "Starting system update"
    
    sudo apt update || {
        error "Failed to update package lists"
        exit 1
    }
    
    sudo apt full-upgrade -y || {
        error "Failed to upgrade packages"
        exit 1
    }
    
    sudo apt autoremove -y
    sudo apt clean
    
    success "System packages updated"
}

# Configure system settings with raspi-config
configure_system() {
    info "Configuring system settings..."
    log "Configuring raspi-config settings"
    
    # Expand filesystem (if not already done)
    info "Expanding filesystem..."
    sudo raspi-config nonint do_expand_rootfs
    
    # Set GPU memory split to 16MB (optimal for headless)
    info "Setting GPU memory to 16MB..."
    sudo raspi-config nonint do_memory_split 16
    
    # Enable SSH (should already be enabled)
    info "Ensuring SSH is enabled..."
    sudo raspi-config nonint do_ssh 0
    
    # Enable I2C (useful for sensors)
    info "Enabling I2C..."
    sudo raspi-config nonint do_i2c 0
    
    # Enable SPI (useful for sensors)
    info "Enabling SPI..."
    sudo raspi-config nonint do_spi 0
    
    success "System settings configured"
}

# Configure network settings
configure_network() {
    info "Configuring network..."
    log "Configuring network settings"
    
    # Check if Wi-Fi is working
    if iwconfig wlan0 2>/dev/null | grep -q "ESSID"; then
        SSID=$(iwconfig wlan0 | grep ESSID | cut -d'"' -f2)
        success "Wi-Fi connected to: $SSID"
    else
        warning "Wi-Fi not connected"
    fi
    
    # Display current IP
    IP_ADDR=$(hostname -I | awk '{print $1}')
    if [ -n "$IP_ADDR" ]; then
        success "IP Address: $IP_ADDR"
    fi
    
    # Optional: Configure static IP (commented out by default)
    # read -p "Configure static IP? (y/n): " -n 1 -r
    # echo
    # if [[ $REPLY =~ ^[Yy]$ ]]; then
    #     configure_static_ip
    # fi
}

# Configure static IP (optional)
configure_static_ip() {
    info "Static IP configuration..."
    
    read -p "Enter static IP (e.g., 192.168.1.100): " STATIC_IP
    read -p "Enter router IP (e.g., 192.168.1.1): " ROUTER_IP
    read -p "Enter DNS server (e.g., 8.8.8.8): " DNS_SERVER
    
    # Backup dhcpcd.conf
    sudo cp /etc/dhcpcd.conf /etc/dhcpcd.conf.backup
    
    # Add static IP configuration
    sudo tee -a /etc/dhcpcd.conf > /dev/null << DHCP_EOF

# Static IP configuration added by host-initialization.sh
interface wlan0
static ip_address=${STATIC_IP}/24
static routers=${ROUTER_IP}
static domain_name_servers=${DNS_SERVER}
DHCP_EOF
    
    success "Static IP configured: $STATIC_IP"
    warning "Changes will take effect after reboot"
}

# Configure hostname (optional)
configure_hostname() {
    CURRENT_HOSTNAME=$(hostname)
    
    read -p "Change hostname from '$CURRENT_HOSTNAME'? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter new hostname: " NEW_HOSTNAME
        
        if [ -n "$NEW_HOSTNAME" ]; then
            sudo raspi-config nonint do_hostname "$NEW_HOSTNAME"
            success "Hostname changed to: $NEW_HOSTNAME"
            warning "Hostname change requires reboot to take effect"
        fi
    fi
}

# Configure locale settings
configure_locale() {
    info "Configuring locale settings..."
    log "Configuring locale"
    
    # Set locale to en_US.UTF-8 (default)
    sudo raspi-config nonint do_change_locale "en_US.UTF-8"
    
    # Set timezone (you may want to change this)
    # Example: America/New_York, Europe/London, etc.
    sudo raspi-config nonint do_change_timezone "Etc/UTC"
    
    # Set keyboard layout to US
    sudo raspi-config nonint do_configure_keyboard "us"
    
    success "Locale configured"
}

# Install essential tools
install_essential_tools() {
    info "Installing essential tools..."
    log "Installing essential packages"
    
    ESSENTIAL_PACKAGES=(
        "vim"              # Text editor
        "nano"             # Simple text editor
        "htop"             # Process monitor
        "git"              # Version control
        "curl"             # HTTP client
        "wget"             # Download utility
        "rsync"            # File sync
        "tree"             # Directory viewer
        "screen"           # Terminal multiplexer
        "tmux"             # Terminal multiplexer
        "net-tools"        # Network utilities
        "dnsutils"         # DNS utilities
        "iotop"            # I/O monitor
        "sysstat"          # System statistics
    )
    
    for pkg in "${ESSENTIAL_PACKAGES[@]}"; do
        if dpkg -l | grep -q "^ii  $pkg"; then
            info "$pkg already installed"
        else
            info "Installing $pkg..."
            sudo apt install -y "$pkg" || warning "Failed to install $pkg"
        fi
    done
    
    success "Essential tools installed"
}

# Configure security settings
configure_security() {
    info "Configuring security settings..."
    log "Configuring security"
    
    # Install and configure UFW firewall
    info "Setting up firewall..."
    if ! dpkg -l | grep -q "^ii  ufw"; then
        sudo apt install -y ufw
    fi
    
    # Configure firewall rules
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw --force enable
    
    success "Firewall configured and enabled"
    
    # Install fail2ban for SSH protection
    info "Installing fail2ban..."
    if ! dpkg -l | grep -q "^ii  fail2ban"; then
        sudo apt install -y fail2ban
        sudo systemctl enable fail2ban
        sudo systemctl start fail2ban
        success "Fail2ban installed and started"
    else
        info "Fail2ban already installed"
    fi
    
    # Disable root login via SSH (if not already disabled)
    if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
        info "Disabling root SSH login..."
        sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
        sudo systemctl restart sshd
        success "Root SSH login disabled"
    fi
}

# Optimize system performance
optimize_performance() {
    info "Optimizing system performance..."
    log "Optimizing system"
    
    # Disable unnecessary services
    SERVICES_TO_DISABLE=(
        "bluetooth"
        "triggerhappy"
        "avahi-daemon"
    )
    
    for service in "${SERVICES_TO_DISABLE[@]}"; do
        if systemctl is-enabled "$service" 2>/dev/null | grep -q enabled; then
            info "Disabling $service..."
            sudo systemctl disable "$service"
            sudo systemctl stop "$service" 2>/dev/null || true
        fi
    done
    
    # Reduce swap usage (optional)
    info "Configuring swap..."
    if [ -f /etc/dphys-swapfile ]; then
        sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=100/' /etc/dphys-swapfile
        sudo dphys-swapfile setup
        sudo dphys-swapfile swapon
    fi
    
    success "Performance optimizations applied"
}

# Configure automatic security updates
configure_auto_updates() {
    info "Configuring automatic security updates..."
    log "Configuring unattended-upgrades"
    
    if ! dpkg -l | grep -q "^ii  unattended-upgrades"; then
        sudo apt install -y unattended-upgrades
    fi
    
    sudo dpkg-reconfigure -plow unattended-upgrades
    
    success "Automatic security updates configured"
}

# Create useful aliases and environment settings
configure_user_environment() {
    info "Configuring user environment..."
    log "Setting up user environment"
    
    BASHRC="$HOME/.bashrc"
    
    # Backup .bashrc
    cp "$BASHRC" "${BASHRC}.backup"
    
    # Add useful aliases if not present
    if ! grep -q "# Luigi project aliases" "$BASHRC"; then
        cat >> "$BASHRC" << 'BASHRC_EOF'

# Luigi project aliases
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias update='sudo apt update && sudo apt upgrade -y'
alias temperature='vcgencmd measure_temp'
alias mario-start='sudo /etc/init.d/mario start'
alias mario-stop='sudo /etc/init.d/mario stop'
alias mario-restart='sudo /etc/init.d/mario restart'
alias mario-logs='tail -f /var/log/motion.log'
alias mario-status='ps aux | grep luigi'

# Useful functions
temp() {
    echo "CPU Temperature: $(vcgencmd measure_temp)"
    echo "CPU Frequency: $(vcgencmd measure_clock arm)"
}

sysinfo() {
    echo "=== System Information ==="
    echo "Uptime: $(uptime -p)"
    echo "Memory:"
    free -h
    echo ""
    echo "Disk Usage:"
    df -h /
    echo ""
    echo "Temperature: $(vcgencmd measure_temp)"
}
BASHRC_EOF
        
        success "User environment configured"
    else
        info "Aliases already configured"
    fi
}

# Create maintenance scripts
create_maintenance_scripts() {
    info "Creating maintenance scripts..."
    log "Creating maintenance scripts"
    
    # System update script
    cat > "$HOME/system-update.sh" << 'UPDATE_EOF'
#!/bin/bash
# System maintenance and update script

echo "Running system maintenance..."

# Update package lists
sudo apt update

# Upgrade packages
sudo apt full-upgrade -y

# Clean up
sudo apt autoremove -y
sudo apt clean

# Update Luigi if installed
if [ -d "$HOME/luigi/.git" ]; then
    echo "Updating Luigi repository..."
    cd "$HOME/luigi"
    git pull
fi

echo "Maintenance complete!"
echo "Temperature: $(vcgencmd measure_temp)"
echo "Disk usage:"
df -h /
UPDATE_EOF
    
    chmod +x "$HOME/system-update.sh"
    success "Maintenance scripts created at $HOME/system-update.sh"
}

# Check system health
check_system_health() {
    info "Checking system health..."
    log "System health check"
    
    # Check temperature
    TEMP=$(vcgencmd measure_temp | grep -oP '\d+\.\d+')
    if (( $(echo "$TEMP > 80" | bc -l) )); then
        warning "High temperature: ${TEMP}°C"
    else
        success "Temperature OK: ${TEMP}°C"
    fi
    
    # Check disk space
    DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 80 ]; then
        warning "Disk usage high: ${DISK_USAGE}%"
    else
        success "Disk space OK: ${DISK_USAGE}% used"
    fi
    
    # Check memory
    MEM_FREE=$(free | grep Mem | awk '{print int($4/$2 * 100)}')
    if [ "$MEM_FREE" -lt 20 ]; then
        warning "Low free memory: ${MEM_FREE}%"
    else
        success "Memory OK: ${MEM_FREE}% free"
    fi
}

# Print summary and next steps
print_summary() {
    echo ""
    echo "========================================"
    echo "  Host Initialization Complete!"
    echo "========================================"
    echo ""
    echo "System Configuration:"
    echo "  ✓ System packages updated"
    echo "  ✓ Essential tools installed"
    echo "  ✓ System settings configured"
    echo "  ✓ Security hardening applied"
    echo "  ✓ Performance optimized"
    echo "  ✓ User environment configured"
    echo ""
    echo "System Information:"
    echo "  Hostname: $(hostname)"
    echo "  IP Address: $(hostname -I | awk '{print $1}')"
    echo "  Temperature: $(vcgencmd measure_temp)"
    echo "  Disk Usage: $(df -h / | tail -1 | awk '{print $5}')"
    echo ""
    echo "Next Steps:"
    echo "  1. Reboot system: sudo reboot"
    echo "  2. After reboot, run Luigi deployment script"
    echo "  3. Use 'system-update.sh' for regular maintenance"
    echo ""
    echo "Useful Commands:"
    echo "  mario-start   - Start motion detection"
    echo "  mario-stop    - Stop motion detection"
    echo "  mario-logs    - View logs"
    echo "  sysinfo       - Show system information"
    echo "  temperature   - Show CPU temperature"
    echo ""
    
    log "Host initialization completed successfully"
    
    read -p "Reboot now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Rebooting system..."
        sudo reboot
    else
        info "Please reboot manually: sudo reboot"
    fi
}

# Main execution
main() {
    check_user
    show_system_info
    
    echo "This script will configure your Raspberry Pi with best practices"
    read -p "Continue? (y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Initialization cancelled"
        exit 0
    fi
    
    echo ""
    update_system
    configure_system
    configure_network
    configure_hostname
    configure_locale
    install_essential_tools
    configure_security
    optimize_performance
    configure_auto_updates
    configure_user_environment
    create_maintenance_scripts
    check_system_health
    print_summary
}

# Run main function
main
