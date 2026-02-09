---
name: system-setup
description: Guide for creating automation scripts to configure Raspberry Pi Zero W for the Luigi project. Use this skill when generating deployment scripts, installation scripts, or system configuration automation for the Luigi motion detection system.
license: MIT
---

# Luigi Project System Setup Script Generation Guide

This skill provides guidance for **creating automation scripts** to configure and deploy the Luigi motion detection project on Raspberry Pi Zero W. Use this when generating bash scripts, installation automation, or system configuration tools.

## When to Use This Skill

Use this skill when:
- Creating deployment scripts for the Luigi project
- Generating installation automation
- Writing system configuration scripts
- Building host setup and initialization scripts
- Creating maintenance and update scripts
- Automating service configuration
- Generating troubleshooting scripts

**This skill helps you CREATE scripts, not execute commands directly.**

## OS Installation Prerequisites

### Recommended Operating System

**Raspberry Pi OS Lite (32-bit) - Debian 13 "Trixie"**
- **Release Date**: December 4, 2025
- **Linux Kernel**: 6.12
- **Architecture**: 32-bit (required for Pi Zero W)
- **Download**: https://www.raspberrypi.com/software/operating-systems/

**Why Raspberry Pi OS Lite:**
- Minimal resource usage (~100MB RAM vs 400MB+ Desktop)
- Faster boot times (10-15 seconds)
- Optimized for headless operation
- No desktop environment overhead
- Perfect for embedded/IoT projects

### OS Installation Using Raspberry Pi Imager

**Installation Steps:**
1. Download Raspberry Pi Imager for your OS
2. Choose Device: Raspberry Pi Zero W
3. Choose OS: Raspberry Pi OS Lite (32-bit)
4. Choose Storage: Your microSD card
5. Click gear icon (⚙️) for advanced settings:
   - Enable SSH
   - Set username/password
   - Configure Wi-Fi (SSID, password, country)
   - Set locale (timezone, keyboard)
6. Write image and wait for completion
7. Insert SD card into Pi Zero W and power on

**After first boot, SSH will be available at:**
- `ssh username@raspberrypi.local` (mDNS)
- `ssh username@[IP address]` (find IP from router)

## Script Generation Principles

### Best Practices for Setup Scripts

**1. Idempotent Operations**
- Scripts should be safe to run multiple times
- Check if components already exist before installing
- Use conditional logic to skip completed steps

**2. Error Handling**
- Check exit codes after each command
- Provide clear error messages
- Allow graceful failure and recovery

**3. User Feedback**
- Print status messages for each step
- Show progress indicators
- Summarize what was accomplished

**4. Validation**
- Verify prerequisites before proceeding
- Test installations after completion
- Confirm services are running

**5. Logging**
- Log actions to file for debugging
- Include timestamps
- Capture both success and failures

## Luigi Project Components

### What Needs to Be Deployed

**System Dependencies:**
- python3-rpi.gpio - GPIO control library
- python-rpi.gpio - GPIO control library (Python 2 compat)
- alsa-utils - Audio playback utilities
- git - Version control for cloning repository

**Project Files:**
- Repository: github.com/pkathmann88/luigi
- Sound files: /usr/share/sounds/mario/ (from mario-sounds.tar.gz)
- Python script: /usr/bin/luigi (from mario.py)
- Service script: /etc/init.d/mario (init.d service)

**Configuration:**
- GPIO Pin: 23 (BCM numbering)
- Service: Registered with update-rc.d for auto-start
- Logs: /var/log/motion.log

## Complete Deployment Script Template

Generate this comprehensive deployment script:

**File: `deploy_luigi.sh`**

```bash
#!/bin/bash
#
# Luigi Motion Detection System - Deployment Script
# 
# Automates deployment of Luigi project on Raspberry Pi Zero W
# Safe to run multiple times (idempotent)
#
# Usage: ./deploy_luigi.sh
#

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$HOME/luigi"
SOUND_DIR="/usr/share/sounds/mario"
BIN_PATH="/usr/bin/luigi"
SERVICE_PATH="/etc/init.d/mario"
LOG_FILE="/var/log/luigi_deployment.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Success message
success() {
    echo -e "${GREEN}✓${NC} $1"
    log "SUCCESS: $1"
}

# Error message
error() {
    echo -e "${RED}✗${NC} $1"
    log "ERROR: $1"
}

# Warning message
warning() {
    echo -e "${YELLOW}!${NC} $1"
    log "WARNING: $1"
}

# Info message
info() {
    echo -e "  $1"
}

# Check if running as root
check_sudo() {
    if [ "$EUID" -eq 0 ]; then
        error "Do not run this script as root. It will request sudo when needed."
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    echo "Checking prerequisites..."
    
    # Check OS
    if [ ! -f /etc/os-release ]; then
        error "Cannot determine OS version"
        exit 1
    fi
    
    # Check network connectivity
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        warning "No internet connectivity detected"
    else
        success "Internet connection available"
    fi
    
    # Check if running on Raspberry Pi
    if [ ! -f /proc/device-tree/model ]; then
        warning "Not running on Raspberry Pi hardware"
    else
        MODEL=$(cat /proc/device-tree/model)
        info "Device: $MODEL"
        success "Running on Raspberry Pi"
    fi
}

# Update system packages
update_system() {
    log "Updating system packages..."
    echo ""
    echo "Step 1: Updating system packages..."
    
    sudo apt update || {
        error "Failed to update package lists"
        exit 1
    }
    
    success "Package lists updated"
}

# Install dependencies
install_dependencies() {
    log "Installing dependencies..."
    echo ""
    echo "Step 2: Installing dependencies..."
    
    PACKAGES="python3-rpi.gpio python-rpi.gpio alsa-utils git"
    
    for pkg in $PACKAGES; do
        if dpkg -l | grep -q "^ii  $pkg"; then
            info "$pkg already installed"
        else
            info "Installing $pkg..."
            sudo apt install -y "$pkg" || {
                error "Failed to install $pkg"
                exit 1
            }
        fi
    done
    
    success "All dependencies installed"
}

# Verify installations
verify_dependencies() {
    log "Verifying dependencies..."
    echo ""
    echo "Step 3: Verifying installations..."
    
    # Check Python GPIO
    if python3 -c "import RPi.GPIO" 2>/dev/null; then
        success "RPi.GPIO library available"
    else
        error "RPi.GPIO library not working"
        exit 1
    fi
    
    # Check audio
    if command -v aplay >/dev/null 2>&1; then
        success "Audio utilities (aplay) available"
    else
        error "Audio utilities not found"
        exit 1
    fi
    
    # Check git
    if command -v git >/dev/null 2>&1; then
        success "Git available"
    else
        error "Git not found"
        exit 1
    fi
}

# Clone or update repository
setup_repository() {
    log "Setting up repository..."
    echo ""
    echo "Step 4: Setting up repository..."
    
    if [ -d "$PROJECT_DIR/.git" ]; then
        info "Repository already exists, updating..."
        cd "$PROJECT_DIR"
        git pull || {
            warning "Failed to update repository"
        }
        success "Repository updated"
    else
        info "Cloning repository..."
        cd ~
        git clone https://github.com/pkathmann88/luigi.git || {
            error "Failed to clone repository"
            exit 1
        }
        success "Repository cloned"
    fi
}

# Deploy sound files
deploy_sounds() {
    log "Deploying sound files..."
    echo ""
    echo "Step 5: Deploying sound files..."
    
    # Create sound directory
    if [ ! -d "$SOUND_DIR" ]; then
        sudo mkdir -p "$SOUND_DIR" || {
            error "Failed to create sound directory"
            exit 1
        }
    fi
    
    # Extract sound files
    cd "$PROJECT_DIR"
    if [ -f "motion-detection/mario/mario-sounds.tar.gz" ]; then
        sudo tar -xzf motion-detection/mario/mario-sounds.tar.gz -C "$SOUND_DIR/" || {
            error "Failed to extract sound files"
            exit 1
        }
        
        # Set permissions
        sudo chmod 644 "$SOUND_DIR"/*.wav
        
        # Count files
        FILE_COUNT=$(ls -1 "$SOUND_DIR"/*.wav 2>/dev/null | wc -l)
        success "Deployed $FILE_COUNT sound files to $SOUND_DIR"
    else
        error "Sound archive not found"
        exit 1
    fi
}

# Test audio configuration
test_audio() {
    log "Testing audio..."
    echo ""
    echo "Step 6: Testing audio configuration..."
    
    # Check audio devices
    if aplay -l >/dev/null 2>&1; then
        success "Audio devices detected"
        
        # Test with first sound file
        FIRST_SOUND=$(ls "$SOUND_DIR"/*.wav 2>/dev/null | head -1)
        if [ -n "$FIRST_SOUND" ]; then
            info "Testing audio playback (this may be silent if no speaker connected)..."
            timeout 5 aplay "$FIRST_SOUND" >/dev/null 2>&1 || true
            success "Audio test completed"
        fi
    else
        warning "No audio devices found (this is OK if running headless)"
    fi
}

# Deploy Python script
deploy_script() {
    log "Deploying Python script..."
    echo ""
    echo "Step 7: Deploying Python script..."
    
    cd "$PROJECT_DIR"
    
    # Validate syntax first
    if ! python3 -m py_compile motion-detection/mario/mario.py 2>/dev/null; then
        error "Python script has syntax errors"
        exit 1
    fi
    
    # Copy to system location
    sudo cp motion-detection/mario/mario.py "$BIN_PATH" || {
        error "Failed to copy script"
        exit 1
    }
    
    # Make executable
    sudo chmod +x "$BIN_PATH"
    
    success "Python script deployed to $BIN_PATH"
}

# Deploy service
deploy_service() {
    log "Deploying service..."
    echo ""
    echo "Step 8: Deploying service..."
    
    cd "$PROJECT_DIR"
    
    # Validate service script
    if command -v shellcheck >/dev/null 2>&1; then
        if shellcheck motion-detection/mario/mario 2>/dev/null; then
            success "Service script validated with shellcheck"
        else
            warning "Service script has shellcheck warnings"
        fi
    fi
    
    # Copy service script
    sudo cp motion-detection/mario/mario "$SERVICE_PATH" || {
        error "Failed to copy service script"
        exit 1
    }
    
    # Make executable
    sudo chmod +x "$SERVICE_PATH"
    
    # Register service
    sudo update-rc.d mario defaults || {
        warning "Failed to register service for auto-start"
    }
    
    success "Service deployed to $SERVICE_PATH"
}

# Test service
test_service() {
    log "Testing service..."
    echo ""
    echo "Step 9: Testing service..."
    
    # Start service
    info "Starting service..."
    sudo "$SERVICE_PATH" start || {
        error "Failed to start service"
        exit 1
    }
    
    # Wait a moment
    sleep 2
    
    # Check if running
    if pgrep -f "$BIN_PATH" >/dev/null; then
        success "Service is running"
        
        # Check log file
        if [ -f /var/log/motion.log ]; then
            success "Log file created"
        fi
        
        # Stop service for now
        info "Stopping service..."
        sudo "$SERVICE_PATH" stop
        success "Service stopped"
    else
        error "Service failed to start"
        exit 1
    fi
}

# Print summary
print_summary() {
    echo ""
    echo "========================================"
    echo "  Luigi Deployment Complete!"
    echo "========================================"
    echo ""
    echo "Installation Summary:"
    echo "  - Dependencies: Installed"
    echo "  - Repository: $PROJECT_DIR"
    echo "  - Sound files: $SOUND_DIR"
    echo "  - Script: $BIN_PATH"
    echo "  - Service: $SERVICE_PATH"
    echo ""
    echo "Service Management:"
    echo "  Start:   sudo /etc/init.d/mario start"
    echo "  Stop:    sudo /etc/init.d/mario stop"
    echo "  Restart: sudo /etc/init.d/mario restart"
    echo ""
    echo "Logs:"
    echo "  View logs: tail -f /var/log/motion.log"
    echo "  Deployment log: $LOG_FILE"
    echo ""
    echo "Next Steps:"
    echo "  1. Connect PIR sensor to GPIO 23"
    echo "  2. Start service: sudo /etc/init.d/mario start"
    echo "  3. Monitor logs: tail -f /var/log/motion.log"
    echo ""
    log "Deployment completed successfully"
}

# Main execution
main() {
    echo "========================================"
    echo "  Luigi Deployment Script"
    echo "  Raspberry Pi Zero W Setup"
    echo "========================================"
    echo ""
    
    check_sudo
    check_prerequisites
    update_system
    install_dependencies
    verify_dependencies
    setup_repository
    deploy_sounds
    test_audio
    deploy_script
    deploy_service
    test_service
    print_summary
}

# Run main function
main
```

## Additional Script Templates

### Update Script

**File: `update_luigi.sh`**

```bash
#!/bin/bash
# Luigi System Update Script

set -e

PROJECT_DIR="$HOME/luigi"

echo "Updating Luigi System..."

# Stop service
sudo /etc/init.d/mario stop || true

# Update system packages
sudo apt update
sudo apt upgrade -y

# Update repository
cd "$PROJECT_DIR"
git pull

# Redeploy components
sudo cp motion-detection/mario/mario.py /usr/bin/luigi
sudo chmod +x /usr/bin/luigi
sudo cp motion-detection/mario/mario /etc/init.d/mario
sudo chmod +x /etc/init.d/mario

# Validate
python3 -m py_compile /usr/bin/luigi

# Restart service
sudo /etc/init.d/mario start

echo "Update complete!"
```

### Audio Configuration Script

**File: `setup_audio.sh`**

```bash
#!/bin/bash
# Luigi Audio Configuration Script

echo "Configuring audio for Luigi..."

# Set audio output to 3.5mm jack
amixer cset numid=3 1

# Set volume to 70%
amixer set PCM 70%

# Save settings
sudo alsactl store

# Test audio
if [ -f "/usr/share/sounds/mario/callingmario1.wav" ]; then
    echo "Playing test sound..."
    aplay "/usr/share/sounds/mario/callingmario1.wav"
fi

echo "Audio configuration complete!"
```

### Troubleshooting Script

**File: `diagnose_luigi.sh`**

```bash
#!/bin/bash
# Luigi Troubleshooting Script

echo "Luigi System Diagnostics"
echo "========================"
echo ""

echo "1. Hardware:"
[ -f /proc/device-tree/model ] && cat /proc/device-tree/model || echo "Not on Raspberry Pi"
echo ""

echo "2. Python GPIO:"
python3 -c "import RPi.GPIO; print('✓ RPi.GPIO working')" || echo "✗ RPi.GPIO not available"
echo ""

echo "3. Audio:"
command -v aplay >/dev/null && echo "✓ aplay available" || echo "✗ aplay not found"
aplay -l 2>&1 | grep -q "card" && echo "✓ Audio devices found" || echo "✗ No audio devices"
echo ""

echo "4. Repository:"
[ -d "$HOME/luigi/.git" ] && echo "✓ Repository at $HOME/luigi" || echo "✗ Repository not found"
echo ""

echo "5. Deployed Components:"
[ -f /usr/bin/luigi ] && echo "✓ Luigi script" || echo "✗ Luigi script missing"
[ -f /etc/init.d/mario ] && echo "✓ Service script" || echo "✗ Service script missing"
[ -d /usr/share/sounds/mario ] && echo "✓ Sound files" || echo "✗ Sound files missing"
echo ""

echo "6. Service Status:"
pgrep -f "/usr/bin/luigi" >/dev/null && echo "✓ Service running" || echo "✗ Service not running"
echo ""

echo "7. System Resources:"
echo "Temperature: $(vcgencmd measure_temp 2>/dev/null || echo 'N/A')"
free -h | grep Mem
```

### Uninstall Script

**File: `uninstall_luigi.sh`**

```bash
#!/bin/bash
# Luigi Uninstall Script

read -p "Remove all Luigi components? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled"
    exit 0
fi

echo "Removing Luigi..."

# Stop and remove service
sudo /etc/init.d/mario stop 2>/dev/null || true
sudo update-rc.d -f mario remove 2>/dev/null || true
sudo rm -f /etc/init.d/mario

# Remove components
sudo rm -f /usr/bin/luigi
sudo rm -rf /usr/share/sounds/mario
sudo rm -f /var/log/motion.log
sudo rm -f /tmp/stop_mario /tmp/mario_timer

echo "Luigi components removed!"
echo "Repository at ~/luigi not removed (remove manually if needed)"
```

## Script Generation Guidelines

### Structure Every Script With:

1. **Shebang and description**
2. **Error handling** (`set -e`)
3. **Configuration variables** at top
4. **Helper functions** for common tasks
5. **Main functions** for each step
6. **Main execution** function
7. **Clear output** with colors and status

### Key Patterns for Idempotency:

```bash
# Check before creating
if [ ! -d "$DIR" ]; then
    mkdir -p "$DIR"
fi

# Check before installing
if ! dpkg -l | grep -q "^ii  $PKG"; then
    sudo apt install -y "$PKG"
fi

# Check file age before copying
if [ ! -f "$DEST" ] || [ "$SRC" -nt "$DEST" ]; then
    sudo cp "$SRC" "$DEST"
fi
```

### Error Handling Pattern:

```bash
command || {
    echo "Error: command failed"
    exit 1
}
```

### Validation Pattern:

```bash
# Validate before proceeding
validate() {
    python3 -m py_compile "$SCRIPT" || return 1
    [ -f "$FILE" ] || return 1
    return 0
}

validate || {
    echo "Validation failed"
    exit 1
}
```

## Summary

When generating setup scripts for Luigi:

1. **Use the deployment script template** as the primary installer
2. **Generate utility scripts** for common tasks (update, audio, diagnostics)
3. **Follow bash best practices** (error handling, idempotency, validation)
4. **Provide clear feedback** with colors and progress indicators
5. **Log operations** for troubleshooting
6. **Test on actual hardware** when possible
7. **Make scripts safe** to run multiple times

These templates can be customized based on specific requirements while maintaining consistency and reliability.

## Additional Resources in This Directory

This skill directory contains several helper resources for system setup:

### 1. host-initialization.sh

**Complete host setup automation script.**

This script automates the initial configuration of a fresh Raspberry Pi OS installation following best practices. It configures:
- System updates
- raspi-config settings (GPU memory, interfaces)
- Network configuration
- Security hardening (firewall, fail2ban, SSH)
- Performance optimization
- User environment (aliases, functions)
- Maintenance scripts

**Usage:**
```bash
chmod +x host-initialization.sh
./host-initialization.sh
```

**When to use:** Run this BEFORE deploying Luigi project to prepare the host system.

### 2. best-practices.md

**Comprehensive guide to Raspberry Pi Zero W best practices.**

Covers:
- OS selection and configuration
- Security hardening standards
- Performance optimization techniques
- Storage management
- Network configuration
- Monitoring and maintenance
- Common pitfalls to avoid
- Production deployment checklist

**When to use:** Reference when making system configuration decisions or troubleshooting issues.

### 3. deployment-checklist.md

**Step-by-step deployment verification checklist.**

Comprehensive checklist covering:
- Pre-deployment (host preparation)
- Dependency installation
- Luigi project deployment
- Service configuration
- Hardware testing
- Auto-start verification
- Production readiness
- Post-deployment monitoring

**When to use:** Follow during deployment to ensure nothing is missed. Can be printed or used as a tracking document.

### 4. system-reference.md

**Quick reference for system administration commands.**

Includes:
- System information commands
- Resource monitoring
- Service management
- Package management
- Log management
- Raspberry Pi specific commands (vcgencmd, raspi-config)
- Troubleshooting procedures
- Backup and recovery

**When to use:** Quick lookup for common system administration tasks.

## Recommended Script Generation Workflow

### 1. Initial Host Setup

Generate and run the host initialization script:

```bash
# Create host-initialization.sh (or use the one in this directory)
chmod +x host-initialization.sh
./host-initialization.sh
sudo reboot
```

This prepares the system with security hardening, performance optimization, and essential tools.

### 2. Deploy Luigi Project

Generate and run the Luigi deployment script:

```bash
# Create deploy_luigi.sh (template in this SKILL.md)
chmod +x deploy_luigi.sh
./deploy_luigi.sh
```

This installs dependencies, clones the repository, and configures the service.

### 3. Verify Deployment

Use the deployment checklist to verify all components:

```bash
# Review deployment-checklist.md systematically
# Test each component
# Document any issues or customizations
```

### 4. Ongoing Maintenance

Generate maintenance scripts for regular updates:

```bash
# Create update_luigi.sh
# Create diagnose_luigi.sh  
# Schedule regular maintenance
```

## Script Generation Tips

### For Host Initialization Scripts:

1. **Always check prerequisites** before making changes
2. **Backup configuration files** before modifying
3. **Provide rollback information** in comments
4. **Test each section independently** when possible
5. **Log all actions** for audit trail

### For Deployment Scripts:

1. **Verify dependencies** before deploying application
2. **Use idempotent operations** (safe to re-run)
3. **Validate syntax** before copying files
4. **Test service** before enabling auto-start
5. **Provide clear success/failure feedback**

### For Maintenance Scripts:

1. **Stop services** before updating
2. **Backup before major changes**
3. **Test in development** before production
4. **Restart services** after updates
5. **Verify functionality** after maintenance

## Integration with Other Skills

The system-setup skill works with other Luigi skills:

**After system-setup (this skill):**
- Use **raspi-zero-w skill** for hardware wiring guidance
- Use **python-development skill** for code modifications

**Workflow:**
1. **system-setup**: Configure OS and deploy Luigi
2. **raspi-zero-w**: Connect PIR sensor and verify GPIO
3. **python-development**: Customize code if needed

## Summary

This skill provides templates and guidance for generating:

✅ **Complete deployment automation** - One command deployment  
✅ **Host initialization scripts** - System preparation  
✅ **Maintenance scripts** - Updates and diagnostics  
✅ **Service management** - Start, stop, restart wrappers  
✅ **Troubleshooting tools** - Diagnostic scripts  
✅ **Uninstall scripts** - Clean removal  

**Best Practices:**
- Generate scripts, don't execute commands directly
- Make scripts idempotent (safe to re-run)
- Include comprehensive error handling
- Provide clear user feedback
- Log all operations
- Validate before and after operations

**Key Files Generated:**
- `deploy_luigi.sh` - Main deployment script
- `host-initialization.sh` - System preparation
- `update_luigi.sh` - Maintenance script
- `setup_audio.sh` - Audio configuration
- `diagnose_luigi.sh` - Troubleshooting
- `uninstall_luigi.sh` - Cleanup script

Use these templates as starting points and customize based on specific deployment requirements while maintaining security, reliability, and best practices.
