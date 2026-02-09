---
name: system-setup
description: Guide for configuring Raspberry Pi Zero W system for the Luigi project, including dependency installation, service setup, and module deployment. Use this skill when deploying the Luigi motion detection system to a Raspberry Pi.
license: MIT
---

# Luigi Project System Setup and Deployment Guide

This skill provides comprehensive guidance for setting up and deploying the Luigi motion detection project on a Raspberry Pi Zero W, including OS prerequisites, dependency installation, service configuration, and module deployment.

## When to Use This Skill

Use this skill when:
- Deploying the Luigi project to a new Raspberry Pi Zero W
- Installing project-specific dependencies
- Setting up and configuring the motion detection service
- Troubleshooting deployment or service issues
- Updating system packages for the project
- Configuring system for optimal performance
- Performing project-specific system maintenance

## Prerequisites

### Operating System Requirements

**Recommended: Raspberry Pi OS Lite (32-bit) - Debian 13 "Trixie"**
- **Release Date**: December 4, 2025
- **Linux Kernel**: 6.12
- **Why Lite**: Optimal for headless operation, minimal resource usage
- **Architecture**: 32-bit (required for Pi Zero W compatibility)

**If you need to install the OS first**, see the OS Installation section at the end of this document or use Raspberry Pi Imager with these settings:
- Device: Raspberry Pi Zero W
- OS: Raspberry Pi OS Lite (32-bit)
- Enable SSH
- Configure Wi-Fi
- Set username/password

This guide assumes you have:
- ✅ Raspberry Pi OS installed and booted
- ✅ SSH access enabled
- ✅ Network connectivity (Wi-Fi configured)
- ✅ Basic system updated (`sudo apt update && sudo apt upgrade`)

## Quick Deployment (For Experienced Users)

If you're familiar with Raspberry Pi setup, use this quick deployment:

```bash
# Update system
sudo apt update && sudo apt full-upgrade -y

# Install dependencies
sudo apt install -y python3-rpi.gpio python-rpi.gpio alsa-utils git

# Clone repository
cd ~ && git clone https://github.com/pkathmann88/luigi.git && cd luigi

# Deploy project
sudo mkdir -p /usr/share/sounds/mario
sudo tar -xzf motion-detection/mario/mario-sounds.tar.gz -C /usr/share/sounds/mario/
sudo cp motion-detection/mario/mario.py /usr/bin/luigi
sudo chmod +x /usr/bin/luigi
sudo cp motion-detection/mario/mario /etc/init.d/mario
sudo chmod +x /etc/init.d/mario
sudo update-rc.d mario defaults

# Test and start
python3 -m py_compile /usr/bin/luigi
sudo /etc/init.d/mario start
tail -f /var/log/motion.log
```

**Continue reading for detailed step-by-step instructions.**

## Step-by-Step Deployment Guide

### Step 1: Connect to Your Raspberry Pi

```bash
# SSH into your Raspberry Pi
ssh pi@raspberrypi.local
# or use IP address
ssh pi@192.168.1.xxx

# Enter password when prompted
```

### Step 2: Update System Packages

**Always start with an updated system:**

```bash
# Update package lists
sudo apt update

# Upgrade all packages (may take 10-30 minutes)
sudo apt full-upgrade -y

# Clean up
sudo apt autoremove -y
sudo apt clean

# Reboot to apply updates
sudo reboot
```

**Wait 30 seconds, then reconnect via SSH.**

### Step 3: Install Luigi Project Dependencies

**Required packages for the Luigi motion detection system:**

```bash
# GPIO Control Libraries
sudo apt install -y python3-rpi.gpio python-rpi.gpio

# Audio Playback Utilities
sudo apt install -y alsa-utils

# Version Control (for cloning repository)
sudo apt install -y git

# Optional: Development tools (if you plan to modify code)
sudo apt install -y python3-pip python3-dev build-essential

# Verify installations
python3 -c "import RPi.GPIO; print('✓ RPi.GPIO installed')"
aplay --version | head -1
git --version
```

**Expected output:**
```
✓ RPi.GPIO installed
aplay: version 1.2.x by Jaroslav Kysela
git version 2.x.x
```

### Step 4: Configure Audio Output

**Test and configure audio for sound playback:**

```bash
# List available audio devices
aplay -l

# Test audio output (should play test sound)
speaker-test -t wav -c 2 -l 1

# Set audio output to 3.5mm jack (if needed)
sudo raspi-config
# Navigate to: 1 System Options → S2 Audio → 1 Headphones
# Or use command line:
amixer cset numid=3 1  # Force 3.5mm jack

# Set volume to 70%
amixer set PCM 70%

# Save audio settings
sudo alsactl store
```

**Troubleshooting audio:**
- No sound? Check volume with `alsamixer`
- Wrong output? Use `sudo raspi-config` to select audio device
- Distorted sound? Use better power supply (2A+)

### Step 5: Clone Luigi Repository

```bash
# Navigate to home directory
cd ~

# Clone the repository
git clone https://github.com/pkathmann88/luigi.git

# Enter project directory
cd luigi

# Verify repository contents
ls -la
# Should show: .github/, motion-detection/, README.md, etc.
```

**If repository is private or you need specific branch:**
```bash
# Clone specific branch
git clone -b branch-name https://github.com/pkathmann88/luigi.git

# Or if already cloned, switch branch
cd luigi
git checkout branch-name
git pull
```

### Step 6: Deploy Sound Files

**Extract and install sound files to system location:**

```bash
# Create sound directory
sudo mkdir -p /usr/share/sounds/mario

# Extract sound files
sudo tar -xzf motion-detection/mario/mario-sounds.tar.gz -C /usr/share/sounds/mario/

# Verify files extracted
ls -lh /usr/share/sounds/mario/
# Should show: callingmario1.wav through callingmario10.wav

# Check permissions
sudo chmod 644 /usr/share/sounds/mario/*.wav

# Test a sound file
aplay /usr/share/sounds/mario/callingmario1.wav
```

### Step 7: Install Python Script

**Deploy the motion detection script:**

```bash
# Copy script to system binary directory
sudo cp motion-detection/mario/mario.py /usr/bin/luigi

# Make executable
sudo chmod +x /usr/bin/luigi

# Verify syntax
python3 -m py_compile /usr/bin/luigi
# No output = success!

# Check script is accessible
which luigi
# Should output: /usr/bin/luigi
```

### Step 8: Install System Service

**Set up the init.d service for automatic startup:**

```bash
# Copy service script
sudo cp motion-detection/mario/mario /etc/init.d/mario

# Make executable
sudo chmod +x /etc/init.d/mario

# Validate service script with shellcheck (if available)
shellcheck /etc/init.d/mario || echo "Shellcheck not installed, skipping validation"

# Register service for automatic startup
sudo update-rc.d mario defaults

# Verify service is registered
ls -l /etc/init.d/mario
# Should show: -rwxr-xr-x ... /etc/init.d/mario
```

### Step 9: Test the Service

**Verify everything works before finalizing:**

```bash
# Start the service
sudo /etc/init.d/mario start

# Check if process is running
ps aux | grep luigi
# Should show: /usr/bin/python /usr/bin/luigi

# Monitor the log file
tail -f /var/log/motion.log
# Press Ctrl+C to exit

# Trigger motion sensor (wave hand in front)
# Should see log entry and hear sound (if PIR sensor connected)

# Stop the service
sudo /etc/init.d/mario stop

# Verify service stopped
ps aux | grep luigi
# Should show only the grep command itself
```

**Alternative service commands:**
```bash
# Start service
sudo service mario start

# Stop service  
sudo service mario stop

# Check service status
sudo service mario status
```

### Step 10: Configure Service Behavior (Optional)

**Modify configuration if needed:**

```bash
# Edit the Python script to change settings
sudo nano /usr/bin/luigi

# Key configuration variables:
# SENSOR_PIN = 23              # GPIO pin for PIR sensor
# SOUND_DIR = "/usr/share/sounds/mario/"  # Sound files location
# STOP_FILE = "/tmp/stop_mario"  # Stop signal file
# TIMER_FILE = "/tmp/mario_timer"  # Cooldown tracker
# Cooldown: Line 36: (now - ts) >= 1800  # 30 minutes in seconds

# Save changes: Ctrl+X, Y, Enter

# Validate syntax after changes
python3 -m py_compile /usr/bin/luigi

# Restart service to apply changes
sudo /etc/init.d/mario restart
```

## Project Configuration Options

### Changing GPIO Pin

If you need to use a different GPIO pin for the PIR sensor:

```bash
# Edit the script
sudo nano /usr/bin/luigi

# Find line: SENSOR_PIN = 23
# Change to desired BCM pin number, e.g.: SENSOR_PIN = 24

# Save and validate
python3 -m py_compile /usr/bin/luigi

# Restart service
sudo /etc/init.d/mario restart
```

**Remember to update hardware wiring accordingly!** See `.github/skills/raspi-zero-w/` for GPIO pinout.

### Changing Cooldown Period

Modify the cooldown between sound playback events:

```bash
sudo nano /usr/bin/luigi

# Find line 36: shouldCheck = (now - ts) >= 1800
# Change 1800 (seconds) to desired cooldown
# Examples:
#   300   = 5 minutes
#   600   = 10 minutes
#   1800  = 30 minutes (default)
#   3600  = 1 hour

# Save, validate, restart
python3 -m py_compile /usr/bin/luigi
sudo /etc/init.d/mario restart
```

### Adding Custom Sounds

Add your own sound files:

```bash
# Copy WAV files to sound directory
sudo cp /path/to/your/sound.wav /usr/share/sounds/mario/

# Set permissions
sudo chmod 644 /usr/share/sounds/mario/*.wav

# Verify
ls -lh /usr/share/sounds/mario/

# Restart service to use new sounds
sudo /etc/init.d/mario restart
```

**Sound file requirements:**
- Format: WAV (recommended) or MP3
- Place in: `/usr/share/sounds/mario/`
- Permissions: 644 (readable by all)
- The script randomly selects from all files in the directory

## Service Management

### Daily Operations

```bash
# Start motion detection
sudo /etc/init.d/mario start

# Stop motion detection
sudo /etc/init.d/mario stop

# Restart service (after config changes)
sudo /etc/init.d/mario restart

# View logs
tail -f /var/log/motion.log

# View last 50 log lines
tail -50 /var/log/motion.log

# Search logs for specific events
grep "Motion detected" /var/log/motion.log
```

### Automatic Startup

The service is configured to start automatically on boot after running `update-rc.d`.

**Disable automatic startup:**
```bash
sudo update-rc.d -f mario remove
```

**Re-enable automatic startup:**
```bash
sudo update-rc.d mario defaults
```

**Check if enabled:**
```bash
ls /etc/rc*.d/ | grep mario
# Should show: S01mario in various rc directories
```

### Monitoring the Service

```bash
# Check if service is running
ps aux | grep luigi

# Monitor in real-time
watch -n 2 'ps aux | grep luigi'

# Check system resource usage
htop
# Find luigi process and check CPU/memory usage

# Monitor log file continuously
tail -f /var/log/motion.log

# Check for errors in system logs
sudo journalctl | grep luigi
sudo journalctl | grep mario
```

## Troubleshooting Deployment Issues

### Service Won't Start

**Check if script exists and is executable:**
```bash
ls -l /usr/bin/luigi
ls -l /etc/init.d/mario

# If missing execute permission:
sudo chmod +x /usr/bin/luigi
sudo chmod +x /etc/init.d/mario
```

**Verify Python syntax:**
```bash
python3 -m py_compile /usr/bin/luigi
# No output = success
# Syntax error? Fix the script and try again
```

**Check for missing dependencies:**
```bash
python3 -c "import RPi.GPIO"
# ImportError? Install: sudo apt install python3-rpi.gpio

aplay --version
# Command not found? Install: sudo apt install alsa-utils
```

**Check service logs:**
```bash
tail -50 /var/log/motion.log
sudo journalctl | grep luigi
```

### Motion Not Detected

**Verify PIR sensor connection:**
- Check wiring: VCC→5V, GND→GND, OUT→GPIO23
- See `.github/skills/raspi-zero-w/wiring-diagram.md` for details

**Check GPIO pin configuration:**
```bash
# View current pin setting in script
grep "SENSOR_PIN" /usr/bin/luigi
# Should show: SENSOR_PIN = 23

# Verify BCM pin 23 = physical pin 16
# See `.github/skills/raspi-zero-w/gpio-pinout.md`
```

**Test PIR sensor manually:**
```bash
# Stop service
sudo /etc/init.d/mario stop

# Run simple test
sudo python3 << 'EOF'
import RPi.GPIO as GPIO
import time

GPIO.setmode(GPIO.BCM)
GPIO.setup(23, GPIO.IN)

print("Testing GPIO23 - Wave hand in front of sensor")
print("Press Ctrl+C to exit")

try:
    while True:
        if GPIO.input(23):
            print("Motion detected!")
        time.sleep(0.1)
except KeyboardInterrupt:
    GPIO.cleanup()
    print("\nTest complete")
EOF
```

**Check cooldown period:**
```bash
# View last trigger time
cat /tmp/mario_timer
date -d @$(cat /tmp/mario_timer)

# Cooldown is 30 minutes by default
# Delete timer to reset:
sudo rm /tmp/mario_timer
```

### Sound Not Playing

**Check sound files exist:**
```bash
ls -lh /usr/share/sounds/mario/
# Should list .wav files
```

**Test audio manually:**
```bash
aplay /usr/share/sounds/mario/callingmario1.wav
```

**If no sound:**
```bash
# Check audio devices
aplay -l

# Test speaker
speaker-test -t wav -c 2 -l 1

# Adjust volume
alsamixer

# Set audio output
amixer cset numid=3 1  # 3.5mm jack
```

**Check file permissions:**
```bash
ls -l /usr/share/sounds/mario/
# Should show: -rw-r--r--

# Fix if needed:
sudo chmod 644 /usr/share/sounds/mario/*.wav
```

### High CPU Usage or Slow Performance

**Check system resources:**
```bash
# CPU and memory usage
htop

# Temperature (should be under 80°C)
vcgencmd measure_temp

# Check throttling
vcgencmd get_throttled
# 0x0 = OK, anything else indicates issues
```

**Optimize system:**
```bash
# Reduce GPU memory (for headless)
sudo raspi-config
# Navigate to: 6 Advanced → A3 Memory Split → 16

# Disable unnecessary services
sudo systemctl disable bluetooth
sudo systemctl disable avahi-daemon

# Reboot
sudo reboot
```

### Log File Growing Too Large

```bash
# Check log size
du -h /var/log/motion.log

# Truncate log file
sudo truncate -s 0 /var/log/motion.log

# Or implement log rotation
sudo nano /etc/logrotate.d/motion
```

Add:
```
/var/log/motion.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
```

## Updating the Luigi Project

### Update to Latest Version

```bash
# Navigate to repository
cd ~/luigi

# Save any local changes (if modified)
git stash

# Pull latest changes
git pull origin main

# Restore local changes (if any)
git stash pop

# Redeploy updated files
sudo cp motion-detection/mario/mario.py /usr/bin/luigi
sudo cp motion-detection/mario/mario /etc/init.d/mario
sudo chmod +x /usr/bin/luigi /etc/init.d/mario

# Validate syntax
python3 -m py_compile /usr/bin/luigi
shellcheck /etc/init.d/mario

# Restart service
sudo /etc/init.d/mario restart
```

### Update Sound Files

```bash
cd ~/luigi

# Extract new sound files
sudo tar -xzf motion-detection/mario/mario-sounds.tar.gz -C /usr/share/sounds/mario/

# Set permissions
sudo chmod 644 /usr/share/sounds/mario/*.wav

# Restart service
sudo /etc/init.d/mario restart
```

## Deployment Checklist

Use this checklist when deploying Luigi to a new Raspberry Pi:

**Prerequisites:**
- [ ] Raspberry Pi OS Lite (32-bit) installed
- [ ] SSH enabled and accessible
- [ ] Wi-Fi configured and connected
- [ ] System updated (`sudo apt update && sudo apt full-upgrade`)

**Dependencies:**
- [ ] python3-rpi.gpio installed
- [ ] python-rpi.gpio installed
- [ ] alsa-utils installed
- [ ] git installed

**Audio Configuration:**
- [ ] Audio output tested with `speaker-test`
- [ ] Audio device configured (3.5mm jack or HDMI)
- [ ] Volume set appropriately with `alsamixer`
- [ ] Audio settings saved with `sudo alsactl store`

**Project Deployment:**
- [ ] Repository cloned to ~/luigi
- [ ] Sound files extracted to /usr/share/sounds/mario/
- [ ] Python script copied to /usr/bin/luigi
- [ ] Script is executable (chmod +x)
- [ ] Script syntax validated (py_compile)
- [ ] Init.d service copied to /etc/init.d/mario
- [ ] Service is executable (chmod +x)
- [ ] Service registered with update-rc.d

**Testing:**
- [ ] Service starts without errors
- [ ] Log file created at /var/log/motion.log
- [ ] PIR sensor detects motion
- [ ] Sound plays on motion detection
- [ ] Cooldown period works correctly
- [ ] Service stops cleanly

**Final Steps:**
- [ ] Service configured for automatic startup
- [ ] System backup created
- [ ] Documentation reviewed
- [ ] Hardware connections verified

## Quick Reference Commands

### Service Management
```bash
sudo /etc/init.d/mario start          # Start service
sudo /etc/init.d/mario stop           # Stop service
sudo /etc/init.d/mario restart        # Restart service
tail -f /var/log/motion.log           # View logs
ps aux | grep luigi                   # Check if running
```

### System Commands
```bash
sudo apt update && sudo apt upgrade   # Update system
sudo reboot                           # Reboot
vcgencmd measure_temp                 # Check temperature
free -h                               # Check memory
df -h                                 # Check disk space
```

### Audio Commands
```bash
aplay -l                              # List audio devices
speaker-test -t wav -c 2 -l 1        # Test audio
alsamixer                             # Adjust volume
amixer cset numid=3 1                 # Set 3.5mm output
```

### Troubleshooting Commands
```bash
python3 -m py_compile /usr/bin/luigi  # Validate Python syntax
shellcheck /etc/init.d/mario          # Validate shell script
python3 -c "import RPi.GPIO"          # Test GPIO library
aplay /usr/share/sounds/mario/callingmario1.wav  # Test sound
```

## Additional Resources

- **System Reference**: See `system-reference.md` in this directory for detailed system commands
- **Hardware Setup**: See `.github/skills/raspi-zero-w/` for GPIO wiring and pinout
- **Python Development**: See `.github/skills/python-development/` for code patterns
- **Project Documentation**: See main `README.md` and `motion-detection/mario/README.md`

## OS Installation (If Needed)

If you need to install Raspberry Pi OS from scratch, use the **Raspberry Pi Imager**:

### Download Imager

**Windows:** https://www.raspberrypi.com/software/  
**macOS:** `brew install --cask raspberry-pi-imager`  
**Linux:** `sudo apt install rpi-imager`

### Configure and Write

1. **Choose Device**: Raspberry Pi Zero W
2. **Choose OS**: Raspberry Pi OS (other) → Raspberry Pi OS Lite (32-bit)
3. **Choose Storage**: Your microSD card
4. **Configure** (click gear icon ⚙️):
   - Enable SSH
   - Set username: `pi`
   - Set password
   - Configure Wi-Fi (SSID, password, country)
   - Set timezone and keyboard layout
5. **Write**: Confirm and wait for completion
6. **Eject**: Safely remove SD card

### First Boot

1. Insert SD card into Raspberry Pi Zero W
2. Connect power (2A+ micro-USB to PWR IN port)
3. Wait 60 seconds for first boot
4. Find IP address (check router or use `nmap`)
5. SSH connect: `ssh pi@raspberrypi.local`
6. Update system: `sudo apt update && sudo apt full-upgrade -y`
7. Reboot: `sudo reboot`

**Then follow the deployment steps in this guide.**

## Summary

This guide covers:
- ✅ Installing project dependencies (GPIO, audio, git)
- ✅ Cloning and deploying the Luigi repository
- ✅ Installing sound files and Python scripts
- ✅ Setting up the system service
- ✅ Testing and verification
- ✅ Configuration and customization
- ✅ Troubleshooting common issues
- ✅ Maintenance and updates

For hardware wiring and GPIO details, see `.github/skills/raspi-zero-w/`.  
For Python code development, see `.github/skills/python-development/`.

**Your Luigi motion detection system is now deployed and ready to use!**
