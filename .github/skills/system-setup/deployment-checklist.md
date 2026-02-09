# Luigi Project Deployment Checklist

Complete this checklist when deploying the Luigi motion detection system to ensure all components are properly configured and tested.

## Pre-Deployment (Host Preparation)

### Operating System Installation
- [ ] Raspberry Pi OS Lite (32-bit) installed on microSD card
- [ ] OS image written using Raspberry Pi Imager
- [ ] SSH enabled during imaging
- [ ] Wi-Fi configured (SSID, password, country code)
- [ ] Username and password set
- [ ] First boot successful
- [ ] SSH connection established

### Initial Host Configuration
- [ ] System packages updated (`sudo apt update && sudo apt full-upgrade -y`)
- [ ] System rebooted after initial updates
- [ ] Hostname configured (optional but recommended)
- [ ] Static IP configured (recommended for servers)
- [ ] Timezone and locale set correctly
- [ ] Keyboard layout configured

### System Optimization
- [ ] GPU memory set to 16MB (headless optimization)
- [ ] Filesystem expanded to use full SD card
- [ ] Unnecessary services disabled (bluetooth, avahi, triggerhappy)
- [ ] Swap reduced or disabled for SD card longevity

### Security Hardening
- [ ] Default password changed to strong password
- [ ] UFW firewall installed and configured
- [ ] Fail2ban installed for SSH protection
- [ ] Root SSH login disabled
- [ ] Automatic security updates enabled (unattended-upgrades)

### Hardware Interfaces
- [ ] I2C enabled (if using I2C sensors)
- [ ] SPI enabled (if using SPI devices)
- [ ] GPIO interface enabled
- [ ] Audio output tested

## Luigi Project Dependencies

### System Packages
- [ ] python3-rpi.gpio installed
- [ ] python-rpi.gpio installed (Python 2 compatibility)
- [ ] alsa-utils installed (audio playback)
- [ ] git installed (repository cloning)

### Dependency Verification
- [ ] Python 3 version confirmed (python3 --version)
- [ ] RPi.GPIO import test passed (`python3 -c "import RPi.GPIO"`)
- [ ] aplay available and working (aplay --version)
- [ ] git version confirmed (git --version)

### Audio Configuration
- [ ] Audio devices detected (`aplay -l`)
- [ ] Audio output selected (3.5mm jack or HDMI)
- [ ] Volume set appropriately (70% recommended)
- [ ] Audio test passed (speaker-test or aplay test file)
- [ ] Audio settings saved (`sudo alsactl store`)

## Luigi Repository

### Repository Setup
- [ ] Repository cloned to ~/luigi
- [ ] Repository path: `/home/[user]/luigi`
- [ ] Repository on correct branch (main/master)
- [ ] All files present and intact
- [ ] README.md reviewed

### File Verification
- [ ] mario.py present at `motion-detection/mario/mario.py`
- [ ] mario service script present at `motion-detection/mario/mario`
- [ ] mario-sounds.tar.gz present (sound archive)
- [ ] Python syntax validated (`python3 -m py_compile mario.py`)
- [ ] Shell script validated with shellcheck (if available)

## Sound Files Deployment

### Sound File Installation
- [ ] Sound directory created at `/usr/share/sounds/mario/`
- [ ] Sound archive extracted to sound directory
- [ ] 10 WAV files confirmed (callingmario1.wav through callingmario10.wav)
- [ ] File permissions set to 644 (`ls -l /usr/share/sounds/mario/`)
- [ ] Files readable by all users
- [ ] Test sound playback successful (`aplay /usr/share/sounds/mario/callingmario1.wav`)

## Python Script Deployment

### Script Installation
- [ ] mario.py copied to `/usr/bin/luigi`
- [ ] Script made executable (`chmod +x /usr/bin/luigi`)
- [ ] Script ownership correct (root:root)
- [ ] Script permissions: 755 or rwxr-xr-x
- [ ] Python syntax validated (`python3 -m py_compile /usr/bin/luigi`)
- [ ] No syntax errors reported

### Script Configuration
- [ ] GPIO pin configuration verified (SENSOR_PIN = 23)
- [ ] Sound directory path correct (`/usr/share/sounds/mario/`)
- [ ] Cooldown period appropriate (1800 seconds = 30 minutes)
- [ ] Stop file path: `/tmp/stop_mario`
- [ ] Timer file path: `/tmp/mario_timer`
- [ ] Log file path: `/var/log/motion.log`

## Service Installation

### Service Script Deployment
- [ ] mario service script copied to `/etc/init.d/mario`
- [ ] Service script made executable (`chmod +x /etc/init.d/mario`)
- [ ] Service script ownership correct (root:root)
- [ ] Service script permissions: 755 or rwxr-xr-x
- [ ] Shell script syntax validated (shellcheck /etc/init.d/mario)

### Service Registration
- [ ] Service registered with update-rc.d (`sudo update-rc.d mario defaults`)
- [ ] Service links created in /etc/rc*.d/
- [ ] Service configured for automatic startup
- [ ] Service priority appropriate (defaults)

## Service Testing

### Manual Service Testing
- [ ] Service starts successfully (`sudo /etc/init.d/mario start`)
- [ ] Process appears in process list (`ps aux | grep luigi`)
- [ ] Log file created at `/var/log/motion.log`
- [ ] No errors in log file
- [ ] Service stops cleanly (`sudo /etc/init.d/mario stop`)
- [ ] Process terminates properly
- [ ] Service restart works (`sudo /etc/init.d/mario restart`)

### Alternative Service Commands
- [ ] `sudo service mario start` works
- [ ] `sudo service mario stop` works
- [ ] `sudo service mario restart` works
- [ ] `sudo service mario status` shows status

### Log Monitoring
- [ ] Log file readable (`tail -f /var/log/motion.log`)
- [ ] Startup message logged
- [ ] GPIO initialization logged
- [ ] No error messages present
- [ ] Timestamp format correct

## Hardware Testing

### PIR Sensor Connection
- [ ] PIR sensor physically connected
- [ ] Wiring verified:
  - [ ] VCC → 5V (Pin 2 or 4)
  - [ ] GND → GND (Pin 6)
  - [ ] OUT → GPIO 23 (Pin 16, BCM numbering)
- [ ] Connections secure
- [ ] No loose wires
- [ ] Power LED on sensor lit (if present)

### Motion Detection Testing
- [ ] Service running (`sudo /etc/init.d/mario start`)
- [ ] Monitoring logs (`tail -f /var/log/motion.log`)
- [ ] Hand wave triggers sensor
- [ ] "Motion detected!" message in log
- [ ] Sound plays from speaker
- [ ] Random sound selection working (multiple tests)
- [ ] Cooldown period working (30 min between sounds)

### Audio Output Testing
- [ ] Speaker or audio device connected
- [ ] Audio cable secure (3.5mm jack)
- [ ] Volume audible but not distorted
- [ ] Sound quality acceptable
- [ ] All sound files playable
- [ ] No crackling or distortion

## Service Auto-Start Testing

### Boot Testing
- [ ] Service configured for auto-start
- [ ] System rebooted (`sudo reboot`)
- [ ] SSH reconnected after boot
- [ ] Service started automatically
- [ ] Process running after boot (`ps aux | grep luigi`)
- [ ] Log file shows startup
- [ ] Motion detection working after boot

## System Monitoring

### Resource Usage
- [ ] CPU usage acceptable (<10% idle)
- [ ] Memory usage reasonable (<200MB)
- [ ] Temperature in normal range (<70°C)
- [ ] No throttling (`vcgencmd get_throttled` returns 0x0)
- [ ] Disk space adequate (>20% free)

### Long-term Testing
- [ ] Service running for >1 hour without issues
- [ ] Multiple motion detections working
- [ ] Cooldown timer working correctly
- [ ] No memory leaks (memory stable over time)
- [ ] Log file size manageable
- [ ] No system crashes or freezes

## Backup and Documentation

### System Backup
- [ ] Initial system backup created
- [ ] Backup tested (can restore if needed)
- [ ] Backup stored safely
- [ ] Backup documentation written (date, contents)

### Configuration Documentation
- [ ] Network settings documented (IP, hostname)
- [ ] Custom configurations noted
- [ ] GPIO pin assignments recorded
- [ ] Service settings documented
- [ ] Any modifications to scripts noted

## Production Readiness

### Final Checks
- [ ] All tests passed
- [ ] No critical errors in logs
- [ ] System stable for extended period
- [ ] Performance acceptable
- [ ] Security hardening complete
- [ ] Monitoring in place

### User Training (if applicable)
- [ ] Service management commands documented
- [ ] Troubleshooting guide provided
- [ ] Contact information for support
- [ ] Emergency procedures documented

### Handoff
- [ ] Deployment checklist completed
- [ ] Documentation provided
- [ ] Credentials securely shared (if needed)
- [ ] Support plan established
- [ ] Maintenance schedule defined

## Post-Deployment

### Week 1 Monitoring
- [ ] Check logs daily
- [ ] Monitor system resources
- [ ] Verify motion detection accuracy
- [ ] Check for any errors or warnings
- [ ] Address any issues found

### Month 1 Maintenance
- [ ] Run system updates
- [ ] Check SD card health
- [ ] Review log file sizes
- [ ] Verify backup currency
- [ ] Test restoration procedure

### Regular Maintenance Schedule
- [ ] Weekly: Review logs
- [ ] Weekly: Check system resources
- [ ] Bi-weekly: Run system updates
- [ ] Monthly: Create new backup
- [ ] Quarterly: Review and update documentation
- [ ] Yearly: Consider SD card replacement

## Troubleshooting Quick Reference

If something doesn't work, check:

**Service won't start:**
- [ ] Python script has no syntax errors
- [ ] All dependencies installed
- [ ] File permissions correct
- [ ] No conflicting process running

**No motion detection:**
- [ ] PIR sensor wired correctly
- [ ] GPIO 23 configured properly
- [ ] Service actually running
- [ ] Check logs for errors
- [ ] Verify sensor with test script

**No sound:**
- [ ] Sound files extracted correctly
- [ ] Audio device configured
- [ ] Volume not muted
- [ ] Speaker connected
- [ ] Test with aplay command

**High resource usage:**
- [ ] Check for process loops
- [ ] Review log file size
- [ ] Check temperature
- [ ] Verify no memory leaks

## Sign-Off

**Deployed By:** _______________  
**Date:** _______________  
**System ID/Hostname:** _______________  
**Notes:** 

________________________________
________________________________
________________________________

**Verified By:** _______________  
**Date:** _______________  

---

## Deployment Status

- [ ] **Pre-Deployment Complete** - Host prepared and optimized
- [ ] **Dependencies Installed** - All required packages available
- [ ] **Luigi Deployed** - Scripts and services installed
- [ ] **Testing Complete** - All functionality verified
- [ ] **Production Ready** - System stable and documented

**Final Status:** ☐ Success ☐ Issues (see notes) ☐ Failed

**Deployment Time:** _____ hours

**Next Review Date:** _______________
