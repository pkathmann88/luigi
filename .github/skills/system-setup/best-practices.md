# Raspberry Pi Zero W Setup Best Practices

This document outlines best practices for configuring Raspberry Pi Zero W systems following 2025/2026 standards.

## Operating System

### Recommended Configuration

**Base System:**
- OS: Raspberry Pi OS Lite (32-bit) - Debian 13 "Trixie"
- Kernel: 6.12+
- No desktop environment (headless operation)
- SSH enabled from first boot
- Wi-Fi configured during imaging

**Why These Choices:**
- 32-bit optimized for Pi Zero W's ARMv6 architecture
- Lite edition uses minimal resources (100MB RAM vs 400MB+)
- Headless operation eliminates GUI overhead
- SSH provides secure remote access
- Pre-configured networking avoids manual setup

## Initial System Configuration

### 1. System Updates (First Priority)

```bash
# Update package lists
sudo apt update

# Full system upgrade (includes kernel)
sudo apt full-upgrade -y

# Remove unnecessary packages
sudo apt autoremove -y

# Clean package cache
sudo apt clean
```

**Why:** Security patches, bug fixes, and latest features.

**Frequency:** Run on first boot, then weekly.

### 2. raspi-config Settings

**Essential Settings:**

```bash
# Expand filesystem (if not auto-done)
sudo raspi-config nonint do_expand_rootfs

# Set GPU memory to 16MB (headless optimization)
sudo raspi-config nonint do_memory_split 16

# Enable interfaces as needed
sudo raspi-config nonint do_i2c 0    # For I2C sensors
sudo raspi-config nonint do_spi 0    # For SPI devices
sudo raspi-config nonint do_ssh 0    # Ensure SSH enabled
```

**Why:**
- Expand filesystem: Use full SD card capacity
- GPU memory: Minimal allocation for headless (default is 64MB)
- Interfaces: Enable hardware protocols for sensors

### 3. Network Configuration

**Wi-Fi Country Code (Required):**
```bash
sudo raspi-config nonint do_wifi_country US
```

**Static IP (Recommended for Servers):**
```bash
# Edit /etc/dhcpcd.conf
interface wlan0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1 8.8.8.8
```

**Why:**
- Country code: Required for Wi-Fi regulatory compliance
- Static IP: Predictable access for services
- DNS servers: Primary (router) + fallback (Google)

### 4. Hostname Configuration

```bash
sudo raspi-config nonint do_hostname "luigi-pi"
```

**Why:** Easier identification on network, especially with multiple Pis.

**Convention:** Use descriptive names (project-device-number)

### 5. Locale Settings

```bash
# Set locale
sudo raspi-config nonint do_change_locale "en_US.UTF-8"

# Set timezone
sudo raspi-config nonint do_change_timezone "America/New_York"

# Set keyboard layout
sudo raspi-config nonint do_configure_keyboard "us"
```

**Why:** Proper character encoding, accurate timestamps, correct keyboard mapping.

## Security Hardening

### 1. Change Default Password

```bash
passwd
```

**Why:** Default passwords are security vulnerability.

**Best Practice:** Use strong, unique password (12+ characters, mixed case, numbers, symbols).

### 2. SSH Hardening

**Disable Root Login:**
```bash
# Edit /etc/ssh/sshd_config
PermitRootLogin no
```

**Use SSH Keys (Advanced):**
```bash
# On your computer:
ssh-copy-id pi@raspberrypi.local

# Then on Pi, disable password auth:
PasswordAuthentication no
```

**Change Default Port (Optional):**
```bash
Port 2222  # Instead of 22
```

**Why:** Reduces automated attack surface.

### 3. Firewall Configuration

```bash
# Install UFW
sudo apt install ufw

# Configure rules
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh  # or specific port: ufw allow 2222

# Enable firewall
sudo ufw enable
```

**Why:** Block unauthorized access, allow only needed services.

### 4. Fail2Ban Installation

```bash
# Install fail2ban
sudo apt install fail2ban

# Enable and start
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

**Why:** Automatic IP banning after failed login attempts.

**Default:** Bans after 5 failed attempts within 10 minutes.

### 5. Automatic Security Updates

```bash
# Install unattended-upgrades
sudo apt install unattended-upgrades

# Configure
sudo dpkg-reconfigure -plow unattended-upgrades
```

**Why:** Automatic security patches without manual intervention.

**Note:** Only security updates, not full upgrades.

## Performance Optimization

### 1. Disable Unnecessary Services

```bash
# Bluetooth (if not needed)
sudo systemctl disable bluetooth
sudo systemctl stop bluetooth

# Avahi daemon (if not using .local hostnames)
sudo systemctl disable avahi-daemon
sudo systemctl stop avahi-daemon

# Triggerhappy (keyboard shortcuts)
sudo systemctl disable triggerhappy
sudo systemctl stop triggerhappy
```

**Why:** Free RAM and CPU cycles for application tasks.

### 2. Reduce Swap Usage

```bash
# Edit /etc/dphys-swapfile
CONF_SWAPSIZE=100  # Reduce from 2048MB to 100MB

# Or disable completely for SD card longevity:
# CONF_SWAPSIZE=0

# Apply changes
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

**Why:** 
- Reduce SD card wear
- Swap is slow on SD cards
- 512MB RAM sufficient for most headless tasks

### 3. Optimize Boot Time

```bash
# Check boot time
systemd-analyze

# Identify slow services
systemd-analyze blame

# Disable unnecessary boot services
sudo systemctl disable plymouth  # Boot splash screen
```

**Why:** Faster startup, especially important for embedded systems.

### 4. HDMI Power Saving

```bash
# Disable HDMI (saves ~25mA)
sudo /opt/vc/bin/tvservice -o

# Make permanent: add to /etc/rc.local
/usr/bin/tvservice -o
```

**Why:** Power saving for headless operation.

## Storage Best Practices

### 1. SD Card Selection

**Recommended:**
- Brand: SanDisk Extreme, Samsung EVO Select, Kingston Canvas Select
- Capacity: 16GB minimum, 32GB recommended
- Class: Class 10, A1 or A2 rating
- Avoid: Generic brands, very large cards (128GB+)

**Why:**
- Quality cards have better wear leveling
- A1/A2 optimized for random I/O (app performance)
- 16-32GB sufficient, larger cards unnecessary

### 2. Minimize Writes

```bash
# Log to RAM (loses logs on reboot)
# Edit /etc/fstab, add:
tmpfs /tmp tmpfs defaults,noatime,nosuid,size=50m 0 0
tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=10m 0 0
```

**Trade-off:** Reduced SD wear vs log persistence.

**Alternative:** Use log rotation with limited retention.

### 3. Regular Backups

```bash
# On your computer (with Pi running):
ssh pi@raspberrypi.local "sudo dd if=/dev/mmcblk0 bs=4M | gzip -" > backup_$(date +%Y%m%d).img.gz

# Or backup specific directories:
rsync -avz pi@raspberrypi.local:/home/pi/ backup/
```

**Why:** SD cards can fail without warning.

**Frequency:** Weekly for active development, monthly for stable systems.

## Monitoring and Maintenance

### 1. Temperature Monitoring

```bash
# Check temperature
vcgencmd measure_temp

# Continuous monitoring
watch -n 2 vcgencmd measure_temp

# Check throttling
vcgencmd get_throttled
# 0x0 = OK, anything else indicates problems
```

**Operating Range:**
- Normal: 40-60°C
- Warning: 60-80°C
- Throttling: >80°C (CPU frequency reduced)
- Shutdown: >85°C

**Solutions for high temperature:**
- Add heatsink (passive cooling)
- Improve airflow
- Reduce overclocking
- Check power supply

### 2. Resource Monitoring

```bash
# Memory usage
free -h

# Disk usage
df -h

# Process list
htop

# System load
uptime
```

**Normal Pi Zero W Usage:**
- RAM: 80-150MB used (headless)
- CPU: 0-5% idle system
- Disk: <4GB for base + Luigi

### 3. Log Management

```bash
# View system logs
sudo journalctl -xe

# View kernel messages
dmesg | tail -50

# Check log sizes
sudo du -sh /var/log/*

# Rotate logs
sudo journalctl --vacuum-time=7d
sudo journalctl --vacuum-size=100M
```

**Why:** Logs can fill SD card over time.

**Best Practice:** Retain 7-30 days of logs.

### 4. Update Schedule

**Security Updates:** Automatic (via unattended-upgrades)

**Manual Updates:**
```bash
# Weekly or bi-weekly
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
```

**Full Upgrade (Monthly):**
```bash
sudo apt update
sudo apt full-upgrade -y
sudo reboot
```

## Power Management

### 1. Power Supply Requirements

**Pi Zero W Specifications:**
- Idle: ~100mA (0.5W)
- Active: ~200mA (1W)
- Peak: ~300mA (1.5W)
- **Recommended PSU:** 5V 2A (allows margin)

**Symptoms of insufficient power:**
- Random reboots
- SD card corruption
- Wi-Fi dropouts
- USB device failures
- Rainbow square on screen

### 2. Power Optimization

```bash
# Disable HDMI (saves ~25mA)
/usr/bin/tvservice -o

# Disable LEDs (saves ~5mA each)
# Edit /boot/config.txt:
dtparam=act_led_trigger=none
dtparam=act_led_activelow=off

# Disable Bluetooth (saves ~10mA)
# Add to /boot/config.txt:
dtoverlay=disable-bt
```

**Why:** Longer battery life, reduced heat, lower power bill.

## Network Best Practices

### 1. Wi-Fi Optimization

```bash
# Disable Wi-Fi power management (reduces dropouts)
sudo iw wlan0 set power_save off

# Make permanent: add to /etc/rc.local
/sbin/iw wlan0 set power_save off
```

**Why:** Power saving can cause connection stability issues.

### 2. Connection Reliability

**Use 2.4GHz Wi-Fi:**
- Pi Zero W only supports 2.4GHz (not 5GHz)
- Better range and wall penetration
- Less prone to interference for IoT

**Optimal Router Settings:**
- Channel: 1, 6, or 11 (non-overlapping)
- Channel width: 20MHz (not 40MHz)
- Security: WPA2-PSK or WPA3

### 3. DNS Configuration

```bash
# Use reliable DNS servers
# Edit /etc/dhcpcd.conf:
static domain_name_servers=192.168.1.1 8.8.8.8 1.1.1.1
```

**Options:**
- Router DNS: 192.168.1.1 (fastest, local)
- Google DNS: 8.8.8.8, 8.8.4.4
- Cloudflare DNS: 1.1.1.1, 1.0.0.1

## Development Environment

### 1. Essential Tools

```bash
sudo apt install -y \
    git vim nano \
    htop screen tmux \
    curl wget rsync \
    tree net-tools
```

**Why:** Standard toolkit for development and troubleshooting.

### 2. Python Environment

```bash
# Python 3 (should be pre-installed)
python3 --version

# Virtual environments
sudo apt install python3-venv

# Development headers
sudo apt install python3-dev
```

**Best Practice:** Use virtual environments for Python projects.

### 3. Git Configuration

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Optional: Store credentials
git config --global credential.helper store
```

## Common Pitfalls to Avoid

### 1. DO NOT:

❌ Use 64-bit OS on Pi Zero W (incompatible with ARMv6)  
❌ Run as root user for normal operations  
❌ Pull power without proper shutdown  
❌ Use cheap/generic SD cards  
❌ Ignore high temperature warnings  
❌ Forget to backup before major changes  
❌ Disable swap completely if RAM usage is high  
❌ Use default passwords in production  

### 2. DO:

✅ Always update before deploying projects  
✅ Use quality power supply (official or equivalent)  
✅ Monitor temperature regularly  
✅ Create regular backups  
✅ Test thoroughly before production deployment  
✅ Document custom configurations  
✅ Use static IP for servers  
✅ Keep logs manageable with rotation  

## Deployment Checklist

Use this checklist before declaring a system "production ready":

**System Configuration:**
- [ ] Fresh Raspberry Pi OS Lite installed
- [ ] System fully updated (apt full-upgrade)
- [ ] GPU memory set to 16MB
- [ ] Filesystem expanded
- [ ] Hostname configured
- [ ] Locale and timezone set

**Network:**
- [ ] Wi-Fi connected and stable
- [ ] Static IP configured (if needed)
- [ ] SSH accessible
- [ ] Firewall enabled and configured

**Security:**
- [ ] Default password changed
- [ ] Root SSH login disabled
- [ ] Firewall (UFW) enabled
- [ ] Fail2ban installed and running
- [ ] Automatic security updates enabled

**Performance:**
- [ ] Unnecessary services disabled
- [ ] Boot time optimized
- [ ] Swap configured appropriately
- [ ] HDMI disabled (if headless)

**Monitoring:**
- [ ] Temperature within normal range
- [ ] Disk space adequate (>20% free)
- [ ] Log rotation configured
- [ ] System aliases configured

**Backup:**
- [ ] Initial backup created
- [ ] Backup schedule established
- [ ] Backup tested (restoration verified)

**Application:**
- [ ] Luigi dependencies installed
- [ ] Luigi service deployed and tested
- [ ] Service auto-start configured
- [ ] Logs being written correctly

## References

**Official Documentation:**
- Raspberry Pi Documentation: https://www.raspberrypi.com/documentation/
- Raspberry Pi OS: https://www.raspberrypi.com/software/
- Debian Wiki: https://wiki.debian.org/

**Community Resources:**
- Raspberry Pi Forums: https://forums.raspberrypi.com/
- Stack Exchange: https://raspberrypi.stackexchange.com/

**Security:**
- SSH Hardening: https://www.ssh.com/academy/ssh/sshd_config
- UFW Tutorial: https://wiki.debian.org/Uncomplicated Firewall (ufw)

## Conclusion

Following these best practices ensures:
- Secure system configuration
- Optimal performance for Pi Zero W hardware
- Reliable operation
- Easy maintenance
- Long SD card lifespan
- Professional-grade deployment

Remember: **The Pi Zero W is resource-constrained hardware. Every optimization matters.**
