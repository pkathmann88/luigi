---
name: Luigi Deployment Automation
description: Guide for creating automation scripts to configure Raspberry Pi Zero W for the Luigi project. Use this skill when generating deployment scripts, installation scripts, or system configuration automation for the Luigi motion detection system.
license: MIT
---

# Luigi Deployment Automation Skill

This skill helps agents **create automation scripts** for deploying the Luigi motion detection system to a Raspberry Pi Zero W. The skill focuses on generating bash scripts that handle dependencies, file deployment, and service configuration.

**Important**: This skill guides script CREATION, not direct execution. Agents should generate deployment scripts that users can review and run.

## Scope

### In Scope
- Luigi application deployment scripts
- Project-specific dependency installation
- File copying and permissions
- Service configuration and management
- Module deployment from this repository

### Out of Scope
- OS installation
- Initial host setup (user creation, SSH configuration)
- General system hardening
- Network configuration

## Target Environment

- **Hardware**: Raspberry Pi Zero W
- **OS**: Raspberry Pi OS Lite (32-bit) based on Debian 13 "Trixie"
- **Init System**: systemd (primary) with init.d compatibility
- **Python**: Python 3.x (python3 command)
- **Audio**: ALSA (aplay command)

## Luigi Project Structure

The current Luigi repository contains:
- **motion-detection/mario/**: Mario-themed motion detector module
  - `mario.py`: Python script using RPi.GPIO for motion detection
  - `mario`: init.d service script
  - `mario-sounds.tar.gz`: Audio files archive (~1.3MB, 10 WAV files)

Future expansions may add more modules under `motion-detection/`.

## Deployment Script Patterns

### 1. Complete Deployment Script

Generate a comprehensive deployment script that handles everything:

```bash
#!/bin/bash
# deploy_luigi.sh - Complete Luigi deployment script
# Usage: sudo ./deploy_luigi.sh

set -e  # Exit on error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root (use sudo)"
    exit 1
fi

# 1. Update package list
log_info "Updating package list..."
apt-get update

# 2. Install dependencies
log_info "Installing dependencies..."
apt-get install -y python3-rpi.gpio alsa-utils git

# 3. Create directories
log_info "Creating directories..."
mkdir -p /usr/share/sounds/mario
mkdir -p /opt/luigi

# 4. Clone repository (if not already present)
if [ ! -d "/opt/luigi/.git" ]; then
    log_info "Cloning Luigi repository..."
    git clone https://github.com/pkathmann88/luigi.git /opt/luigi
else
    log_info "Repository already exists, pulling latest..."
    cd /opt/luigi
    git pull
fi

# 5. Extract and deploy sound files
log_info "Deploying sound files..."
tar -xzf /opt/luigi/motion-detection/mario/mario-sounds.tar.gz -C /usr/share/sounds/mario/
chmod 644 /usr/share/sounds/mario/*.wav

# 6. Deploy Python script
log_info "Deploying Python script..."
cp /opt/luigi/motion-detection/mario/mario.py /usr/local/bin/mario.py
chmod 755 /usr/local/bin/mario.py

# 7. Deploy init.d service
log_info "Deploying service script..."
cp /opt/luigi/motion-detection/mario/mario /etc/init.d/mario
chmod 755 /etc/init.d/mario

# 8. Enable service
log_info "Enabling mario service..."
update-rc.d mario defaults

# 9. Start service
log_info "Starting mario service..."
service mario start

# 10. Verify deployment
log_info "Verifying deployment..."
sleep 2
if service mario status > /dev/null 2>&1; then
    log_info "✓ Service is running"
else
    log_warn "Service may not be running, check logs"
fi

if [ -f "/var/log/motion.log" ]; then
    log_info "✓ Log file created"
else
    log_warn "Log file not yet created"
fi

log_info "Deployment complete!"
log_info "Check status: sudo service mario status"
log_info "View logs: tail -f /var/log/motion.log"
```

### 2. Modular Script Pattern

For more complex deployments, generate separate scripts for each concern:

**install_dependencies.sh**:
```bash
#!/bin/bash
# Install Luigi dependencies

set -e

apt-get update
apt-get install -y \
    python3-rpi.gpio \
    alsa-utils \
    git

# Verify installations
python3 -c "import RPi.GPIO" || exit 1
which aplay > /dev/null || exit 1

echo "Dependencies installed successfully"
```

**deploy_files.sh**:
```bash
#!/bin/bash
# Deploy Luigi files

set -e

REPO_DIR="/opt/luigi"
SOUND_DIR="/usr/share/sounds/mario"

# Create directories
mkdir -p "$SOUND_DIR"

# Extract sounds
tar -xzf "$REPO_DIR/motion-detection/mario/mario-sounds.tar.gz" -C "$SOUND_DIR"
chmod 644 "$SOUND_DIR"/*.wav

# Deploy script
cp "$REPO_DIR/motion-detection/mario/mario.py" /usr/local/bin/mario.py
chmod 755 /usr/local/bin/mario.py

echo "Files deployed successfully"
```

**setup_service.sh**:
```bash
#!/bin/bash
# Set up Mario service

set -e

REPO_DIR="/opt/luigi"

# Deploy service script
cp "$REPO_DIR/motion-detection/mario/mario" /etc/init.d/mario
chmod 755 /etc/init.d/mario

# Enable and start
update-rc.d mario defaults
service mario start

echo "Service configured and started"
```

### 3. Service Management Script

Generate a helper script for service operations:

```bash
#!/bin/bash
# manage_mario.sh - Service management helper

OPERATION="${1:-status}"

case "$OPERATION" in
    start)
        sudo service mario start
        echo "Mario service started"
        ;;
    stop)
        sudo service mario stop
        echo "Mario service stopped"
        ;;
    restart)
        sudo service mario restart
        echo "Mario service restarted"
        ;;
    status)
        sudo service mario status
        ;;
    logs)
        tail -f /var/log/motion.log
        ;;
    enable)
        sudo update-rc.d mario defaults
        echo "Mario service enabled at boot"
        ;;
    disable)
        sudo update-rc.d mario remove
        echo "Mario service disabled at boot"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|enable|disable}"
        exit 1
        ;;
esac
```

### 4. Update Script

Generate script for updating Luigi deployment:

```bash
#!/bin/bash
# update_luigi.sh - Update Luigi to latest version

set -e

REPO_DIR="/opt/luigi"

echo "Stopping service..."
service mario stop

echo "Pulling latest changes..."
cd "$REPO_DIR"
git pull

echo "Redeploying files..."
cp motion-detection/mario/mario.py /usr/local/bin/mario.py
cp motion-detection/mario/mario /etc/init.d/mario

echo "Restarting service..."
service mario start

echo "Update complete!"
service mario status
```

### 5. Uninstall Script

Generate cleanup script:

```bash
#!/bin/bash
# uninstall_luigi.sh - Remove Luigi deployment

set -e

echo "Stopping service..."
service mario stop || true

echo "Disabling service..."
update-rc.d mario remove || true

echo "Removing files..."
rm -f /etc/init.d/mario
rm -f /usr/local/bin/mario.py
rm -rf /usr/share/sounds/mario
rm -rf /opt/luigi

echo "Removing log file..."
rm -f /var/log/motion.log

echo "Luigi uninstalled successfully"
```

## Service Integration Patterns

### Init.d Service Script Structure

The Mario service uses the traditional init.d format. When creating or modifying services:

```bash
#!/bin/sh
### BEGIN INIT INFO
# Provides:          mario
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Mario motion detection service
# Description:       Motion detection with Mario sound effects
### END INIT INFO

# Service implementation here
```

**Key points for init.d scripts**:
- Include LSB (Linux Standard Base) headers
- Support standard actions: start, stop, restart, status
- Use proper exit codes (0=success, 1=error)
- Implement proper PID file management
- Handle stop gracefully (create stop file, wait for process)

### Systemd Unit File (Alternative)

For modern systemd integration, generate a unit file instead:

```ini
# /etc/systemd/system/mario.service
[Unit]
Description=Mario Motion Detection Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/usr/local/bin
ExecStart=/usr/bin/python3 /usr/local/bin/mario.py
Restart=on-failure
RestartSec=10
StandardOutput=append:/var/log/motion.log
StandardError=append:/var/log/motion.log

[Install]
WantedBy=multi-user.target
```

**Deployment commands for systemd**:
```bash
# Install unit file
cp mario.service /etc/systemd/system/
chmod 644 /etc/systemd/system/mario.service

# Reload systemd
systemctl daemon-reload

# Enable and start
systemctl enable mario.service
systemctl start mario.service

# Check status
systemctl status mario.service
```

## Dependency Management

### Core Luigi Dependencies

Always include these in deployment scripts:

```bash
# Python GPIO library
apt-get install -y python3-rpi.gpio

# Audio playback
apt-get install -y alsa-utils

# Version control (for cloning/updating)
apt-get install -y git
```

### Optional Dependencies

For enhanced functionality:

```bash
# For audio format conversion
apt-get install -y sox

# For better logging
apt-get install -y rsyslog

# For cron-based maintenance
# (already included in base OS)
```

### Python Package Management

If using pip for Python packages:

```bash
# Install pip if needed
apt-get install -y python3-pip

# Install packages
pip3 install RPi.GPIO  # Alternative to apt package
```

**Note**: Prefer system packages (`apt`) over pip when available for better integration.

## File Deployment Best Practices

### Directory Structure

Standard locations for Luigi files:

```
/opt/luigi/                      # Repository clone
/usr/local/bin/mario.py         # Python script (executable)
/usr/share/sounds/mario/        # Sound files (read-only)
/etc/init.d/mario               # Service script
/var/log/motion.log             # Log file
/tmp/stop_mario                 # Stop signal file
/tmp/mario_timer                # Cooldown timer file
```

### File Permissions

Set appropriate permissions in deployment scripts:

```bash
# Executable scripts
chmod 755 /usr/local/bin/mario.py
chmod 755 /etc/init.d/mario

# Read-only data
chmod 644 /usr/share/sounds/mario/*.wav

# Log file (will be created by service)
touch /var/log/motion.log
chmod 644 /var/log/motion.log
```

### Sound File Deployment

Extract and deploy sound files:

```bash
# Create directory
mkdir -p /usr/share/sounds/mario

# Extract archive
tar -xzf mario-sounds.tar.gz -C /usr/share/sounds/mario/

# Set permissions
chmod 644 /usr/share/sounds/mario/*.wav

# Verify files
ls -l /usr/share/sounds/mario/
```

## Configuration Management

### Hardcoded Configuration

Current Mario implementation uses hardcoded values:
- GPIO pin: 23
- Cooldown: 10 seconds
- Sound directory: `/usr/share/sounds/mario/`

### Future: Configuration File Support

For enhanced modules, generate config file patterns:

```bash
# /etc/luigi/mario.conf
GPIO_PIN=23
COOLDOWN_SECONDS=10
SOUND_DIR=/usr/share/sounds/mario
LOG_FILE=/var/log/motion.log
```

**Deployment**:
```bash
mkdir -p /etc/luigi
cp mario.conf /etc/luigi/
chmod 644 /etc/luigi/mario.conf
```

## Testing and Verification

### Post-Deployment Checks

Include verification in deployment scripts:

```bash
#!/bin/bash
# verify_deployment.sh

ERRORS=0

# Check files exist
echo "Checking files..."
for FILE in /usr/local/bin/mario.py /etc/init.d/mario; do
    if [ ! -f "$FILE" ]; then
        echo "✗ Missing: $FILE"
        ERRORS=$((ERRORS + 1))
    else
        echo "✓ Found: $FILE"
    fi
done

# Check sound files
echo "Checking sound files..."
SOUND_COUNT=$(ls /usr/share/sounds/mario/*.wav 2>/dev/null | wc -l)
if [ "$SOUND_COUNT" -eq 10 ]; then
    echo "✓ All 10 sound files present"
else
    echo "✗ Expected 10 sound files, found $SOUND_COUNT"
    ERRORS=$((ERRORS + 1))
fi

# Check service
echo "Checking service..."
if service mario status > /dev/null 2>&1; then
    echo "✓ Service is running"
else
    echo "✗ Service is not running"
    ERRORS=$((ERRORS + 1))
fi

# Check log file
echo "Checking log file..."
if [ -f "/var/log/motion.log" ]; then
    echo "✓ Log file exists"
    tail -5 /var/log/motion.log
else
    echo "✗ Log file missing"
    ERRORS=$((ERRORS + 1))
fi

# Summary
echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✓ All checks passed!"
    exit 0
else
    echo "✗ $ERRORS error(s) found"
    exit 1
fi
```

### Hardware Testing

Generate hardware test scripts:

```bash
#!/bin/bash
# test_hardware.sh - Test GPIO and audio

echo "Testing audio..."
if aplay /usr/share/sounds/mario/callingmario1.wav; then
    echo "✓ Audio working"
else
    echo "✗ Audio failed"
fi

echo "Testing GPIO (requires hardware)..."
python3 << 'EOF'
import RPi.GPIO as GPIO
import time

GPIO.setmode(GPIO.BCM)
GPIO.setup(23, GPIO.IN)

print(f"GPIO 23 state: {GPIO.input(23)}")
print("Wave your hand near the PIR sensor...")

start = time.time()
while time.time() - start < 5:
    if GPIO.input(23):
        print("✓ Motion detected!")
        GPIO.cleanup()
        exit(0)
    time.sleep(0.1)

print("✗ No motion detected in 5 seconds")
GPIO.cleanup()
EOF
```

## Error Handling

### Robust Deployment Scripts

Include error handling in generated scripts:

```bash
#!/bin/bash

set -e  # Exit on error
set -u  # Exit on undefined variable

# Trap errors
trap 'echo "Error on line $LINENO"; exit 1' ERR

# Function to check command success
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 not found"
        exit 1
    fi
}

# Verify prerequisites
check_command python3
check_command aplay
check_command git

# Continue with deployment...
```

### Rollback Support

Generate scripts with rollback capability:

```bash
#!/bin/bash
# deploy_with_rollback.sh

BACKUP_DIR="/tmp/luigi_backup_$(date +%s)"

# Backup existing installation
if [ -d "/opt/luigi" ]; then
    echo "Backing up existing installation..."
    mkdir -p "$BACKUP_DIR"
    cp -r /opt/luigi "$BACKUP_DIR/"
    cp /usr/local/bin/mario.py "$BACKUP_DIR/" 2>/dev/null || true
    cp /etc/init.d/mario "$BACKUP_DIR/" 2>/dev/null || true
fi

# Deploy new version
if ./deploy_luigi.sh; then
    echo "Deployment successful!"
    rm -rf "$BACKUP_DIR"
else
    echo "Deployment failed! Rolling back..."
    if [ -d "$BACKUP_DIR" ]; then
        cp -r "$BACKUP_DIR/luigi" /opt/
        cp "$BACKUP_DIR/mario.py" /usr/local/bin/ 2>/dev/null || true
        cp "$BACKUP_DIR/mario" /etc/init.d/ 2>/dev/null || true
        service mario restart
    fi
    exit 1
fi
```

## Multi-Module Deployment

### Extensible Deployment Pattern

When multiple modules exist:

```bash
#!/bin/bash
# deploy_all_modules.sh

MODULES=("mario")  # Add more modules here as they're developed

for MODULE in "${MODULES[@]}"; do
    echo "Deploying module: $MODULE"
    
    # Deploy Python script
    cp "motion-detection/$MODULE/$MODULE.py" "/usr/local/bin/"
    chmod 755 "/usr/local/bin/$MODULE.py"
    
    # Deploy service
    cp "motion-detection/$MODULE/$MODULE" "/etc/init.d/"
    chmod 755 "/etc/init.d/$MODULE"
    
    # Enable service
    update-rc.d "$MODULE" defaults
    
    # Start service
    service "$MODULE" start
    
    echo "✓ $MODULE deployed"
done
```

## Troubleshooting Scripts

### Service Troubleshooting

Generate diagnostic scripts:

```bash
#!/bin/bash
# troubleshoot_mario.sh

echo "=== Mario Service Diagnostics ==="
echo ""

echo "Service Status:"
service mario status || echo "Service not running"
echo ""

echo "Recent Logs:"
tail -20 /var/log/motion.log 2>/dev/null || echo "No logs found"
echo ""

echo "Process Check:"
ps aux | grep mario.py | grep -v grep || echo "No mario process found"
echo ""

echo "File Permissions:"
ls -l /usr/local/bin/mario.py 2>/dev/null || echo "Script not found"
ls -l /etc/init.d/mario 2>/dev/null || echo "Service script not found"
echo ""

echo "Sound Files:"
ls -l /usr/share/sounds/mario/ 2>/dev/null || echo "Sound directory not found"
echo ""

echo "GPIO Test:"
python3 -c "import RPi.GPIO; print('GPIO library OK')" || echo "GPIO library error"
echo ""

echo "Audio Test:"
aplay --version > /dev/null && echo "Audio system OK" || echo "Audio system error"
```

## Best Practices for Script Generation

When generating deployment scripts, agents should:

1. **Use descriptive comments**: Explain each step clearly
2. **Include error handling**: Use `set -e`, check exit codes
3. **Provide feedback**: Echo progress messages for users
4. **Make scripts idempotent**: Safe to run multiple times
5. **Check prerequisites**: Verify dependencies before deployment
6. **Test verification**: Include post-deployment checks
7. **Document usage**: Add help text and examples
8. **Use standard paths**: Follow FHS (Filesystem Hierarchy Standard)
9. **Set proper permissions**: Ensure security and functionality
10. **Support updates**: Make it easy to update deployments

## Script Template

Use this template for new deployment scripts:

```bash
#!/bin/bash
# script_name.sh - Brief description
# Usage: sudo ./script_name.sh [options]

set -e  # Exit on error

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_FILE="/var/log/luigi_deployment.log"

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Logging functions
log() {
    echo -e "$@" | tee -a "$LOG_FILE"
}

log_info() {
    log "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    log "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    log "${RED}[ERROR]${NC} $1"
}

# Check root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run as root (use sudo)"
        exit 1
    fi
}

# Main function
main() {
    log_info "Starting $SCRIPT_NAME"
    
    # Script logic here
    
    log_info "Completed successfully"
}

# Run main
check_root
main "$@"
```

## Quick Reference

### Essential Commands

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y python3-rpi.gpio alsa-utils git

# Deploy service
sudo cp mario /etc/init.d/
sudo chmod 755 /etc/init.d/mario
sudo update-rc.d mario defaults

# Manage service
sudo service mario start
sudo service mario stop
sudo service mario restart
sudo service mario status

# View logs
tail -f /var/log/motion.log

# Test audio
aplay /usr/share/sounds/mario/callingmario1.wav

# Test GPIO
python3 -c "import RPi.GPIO; print('OK')"
```

### File Locations

```
/opt/luigi/                        # Repository
/usr/local/bin/mario.py           # Script
/etc/init.d/mario                 # Service
/usr/share/sounds/mario/          # Sounds
/var/log/motion.log               # Logs
```

## Additional Resources

See also:
- `system-reference.md` - System command quick reference
- `.github/skills/raspi-zero-w/` - Hardware setup and GPIO details
- `.github/skills/python-development/` - Python code patterns

---

**Remember**: This skill helps CREATE automation scripts. Always generate well-commented, robust scripts that users can review before execution.
