# Raspberry Pi System Reference

Quick reference for Raspberry Pi Zero W system administration and troubleshooting.

## System Commands Quick Reference

### System Information
```bash
# Show OS version
cat /etc/os-release
lsb_release -a

# Show kernel version
uname -r
uname -a

# Show Raspberry Pi model
cat /proc/device-tree/model

# Show CPU information
cat /proc/cpuinfo

# Show firmware version
vcgencmd version
```

### Resource Monitoring
```bash
# Memory usage
free -h
cat /proc/meminfo

# Disk usage
df -h
du -sh /home/pi/*

# CPU temperature
vcgencmd measure_temp

# CPU frequency
vcgencmd measure_clock arm

# Voltage
vcgencmd measure_volts

# System load
uptime
w

# Process monitoring
top
htop
```

### Service Management
```bash
# List all services
systemctl list-units --type=service

# Check service status
sudo systemctl status [service]

# Start/stop/restart service
sudo systemctl start [service]
sudo systemctl stop [service]
sudo systemctl restart [service]

# Enable/disable service at boot
sudo systemctl enable [service]
sudo systemctl disable [service]

# View service logs
sudo journalctl -u [service]
sudo journalctl -u [service] -f  # Follow logs
```

### Package Management
```bash
# Update package list
sudo apt update

# Upgrade packages
sudo apt upgrade          # Standard upgrade
sudo apt full-upgrade     # Full upgrade (handles dependencies)
sudo apt dist-upgrade     # Distribution upgrade

# Install package
sudo apt install [package]

# Remove package
sudo apt remove [package]
sudo apt purge [package]  # Remove with config files

# Search for package
apt search [keyword]
apt-cache search [keyword]

# Show package information
apt show [package]

# List installed packages
dpkg -l
apt list --installed

# Clean up
sudo apt autoremove
sudo apt autoclean
sudo apt clean
```

### File System Management
```bash
# Check filesystem
sudo fsck -f /dev/mmcblk0p2

# Mount/unmount
sudo mount /dev/mmcblk0p1 /mnt/boot
sudo umount /mnt/boot

# Show mount points
mount
df -h

# Check inode usage
df -i

# Find large files
du -ah / | sort -rh | head -20

# Find files by size
find / -type f -size +100M
```

### Log Files
```bash
# System logs
sudo journalctl -xe
sudo journalctl --since today
sudo journalctl --since "2 hours ago"

# Boot messages
dmesg
dmesg | tail -50

# Specific log files
/var/log/messages
/var/log/syslog
/var/log/auth.log
/var/log/daemon.log

# View logs
sudo tail -f /var/log/syslog
sudo less /var/log/messages

# Clear journal logs
sudo journalctl --vacuum-time=7d
sudo journalctl --vacuum-size=100M
```

## Configuration Files

### Important System Files
```
/boot/config.txt           # Boot configuration
/boot/cmdline.txt          # Kernel command line
/etc/rc.local              # Startup script
/etc/fstab                 # Filesystem mounts
/etc/hosts                 # Host name resolution
/etc/hostname              # System hostname
/etc/resolv.conf           # DNS configuration
```

### Network Configuration
```
/etc/dhcpcd.conf           # DHCP client configuration
/etc/network/interfaces    # Network interfaces
/etc/wpa_supplicant/wpa_supplicant.conf  # Wi-Fi configuration
```

### SSH Configuration
```
/etc/ssh/sshd_config       # SSH server configuration
~/.ssh/authorized_keys     # SSH public keys
~/.ssh/config              # SSH client configuration
```

## Raspberry Pi Specific Commands

### vcgencmd Commands
```bash
# Temperature
vcgencmd measure_temp

# CPU frequency
vcgencmd measure_clock arm
vcgencmd measure_clock core

# Voltage
vcgencmd measure_volts core
vcgencmd measure_volts sdram_c

# Memory split
vcgencmd get_mem arm
vcgencmd get_mem gpu

# Throttling status
vcgencmd get_throttled
# 0x0 = OK
# 0x50000 = Throttled
# 0x50005 = Throttled + Under-voltage

# Display information
vcgencmd get_lcd_info
vcgencmd get_config int

# Codec information
vcgencmd codec_enabled H264
```

### raspi-config Options
```bash
# Launch configuration tool
sudo raspi-config

# Non-interactive mode
sudo raspi-config nonint do_ssh 0          # Enable SSH
sudo raspi-config nonint do_i2c 0          # Enable I2C
sudo raspi-config nonint do_spi 0          # Enable SPI
sudo raspi-config nonint do_serial 0       # Enable serial
sudo raspi-config nonint do_expand_rootfs  # Expand filesystem
```

## Troubleshooting Common Issues

### Boot Issues

**Won't boot (no LED activity)**
- Check power supply (must be 5V, 2A+)
- Try different SD card
- Check SD card is properly inserted

**Green LED blinks (boot failure)**
- SD card corrupted or not properly written
- Incompatible SD card
- Try reimaging SD card

**Red LED only (no boot)**
- No valid OS image on SD card
- SD card not properly formatted
- Power supply insufficient

### Network Issues

**Can't connect to Wi-Fi**
```bash
# Check Wi-Fi interface
iwconfig

# Restart networking
sudo systemctl restart dhcpcd

# Check wpa_supplicant
sudo wpa_cli -i wlan0 reconfigure
sudo systemctl restart wpa_supplicant

# View Wi-Fi logs
sudo journalctl -u wpa_supplicant
dmesg | grep brcm
```

**SSH not working**
```bash
# Check SSH service
sudo systemctl status ssh

# Restart SSH
sudo systemctl restart ssh

# Check if ssh file exists on boot partition
ls /boot/ssh

# Recreate ssh file
sudo touch /boot/ssh
sudo reboot
```

### Performance Issues

**System slow or unresponsive**
```bash
# Check memory
free -h

# Check CPU load
uptime
top

# Check temperature
vcgencmd measure_temp

# Check for throttling
vcgencmd get_throttled

# Check swap usage
swapon --show

# Check disk I/O
sudo iotop
```

**High temperature**
```bash
# Check current temp
vcgencmd measure_temp

# Monitor continuously
watch -n 1 vcgencmd measure_temp

# Solutions:
# - Add heatsink
# - Improve ventilation
# - Reduce GPU memory (if not using display)
sudo raspi-config
# Advanced → Memory Split → 16
```

### Storage Issues

**SD card full**
```bash
# Check disk usage
df -h

# Find large files
du -sh /* | sort -h
find / -type f -size +50M

# Clean package cache
sudo apt clean
sudo apt autoremove

# Clean logs
sudo journalctl --vacuum-size=50M
```

**SD card corruption**
```bash
# Check filesystem (from another system)
sudo fsck -f /dev/sdX2

# Or from Pi (boot to single user mode)
sudo fsck -f /dev/mmcblk0p2

# Prevent future corruption:
# - Use quality SD card
# - Proper shutdown (don't pull power)
# - Use UPS or backup power
# - Regular backups
```

## Security Hardening

### Basic Security
```bash
# Change default password
passwd

# Update system
sudo apt update && sudo apt full-upgrade -y

# Install firewall
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable

# Install fail2ban
sudo apt install fail2ban
sudo systemctl enable fail2ban
```

### SSH Hardening
```bash
# Edit SSH config
sudo nano /etc/ssh/sshd_config

# Recommended changes:
Port 2222                    # Change default port
PermitRootLogin no           # Disable root login
PasswordAuthentication no    # Use keys only
PubkeyAuthentication yes     # Enable key authentication
MaxAuthTries 3               # Limit auth attempts
ClientAliveInterval 300      # Timeout idle sessions
ClientAliveCountMax 2

# Restart SSH
sudo systemctl restart sshd
```

### System Monitoring
```bash
# Check authentication logs
sudo tail -f /var/log/auth.log

# Check failed login attempts
sudo lastb

# Check successful logins
last

# Check currently logged in users
w
who
```

## Backup and Recovery

### System Backup
```bash
# Backup SD card (from another system)
sudo dd if=/dev/sdX of=backup.img bs=4M status=progress
gzip backup.img

# Backup important directories
tar -czf home_backup.tar.gz /home/pi
tar -czf etc_backup.tar.gz /etc

# Rsync backup
rsync -avz /home/pi/ backup/home/
rsync -avz --exclude=/proc --exclude=/sys --exclude=/dev / backup/system/
```

### System Restore
```bash
# Restore SD card image
gunzip backup.img.gz
sudo dd if=backup.img of=/dev/sdX bs=4M status=progress
sync
```

## Performance Tuning

### Optimize for Headless Operation
```bash
# Reduce GPU memory
sudo raspi-config
# Advanced → Memory Split → 16

# Disable unnecessary services
sudo systemctl disable bluetooth
sudo systemctl disable avahi-daemon
sudo systemctl disable triggerhappy

# Disable HDMI
sudo /opt/vc/bin/tvservice -o

# Add to /etc/rc.local
/usr/bin/tvservice -o
```

### Reduce Swap
```bash
# Check swap
swapon --show

# Disable swap
sudo dphys-swapfile swapoff
sudo systemctl disable dphys-swapfile

# Or reduce swap size
sudo nano /etc/dphys-swapfile
# CONF_SWAPSIZE=100

sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

## Useful Scripts

### System Status Script
```bash
#!/bin/bash
echo "=== System Status ==="
echo "Temperature: $(vcgencmd measure_temp)"
echo "CPU Frequency: $(vcgencmd measure_clock arm)"
echo "Memory:"
free -h
echo ""
echo "Disk Usage:"
df -h /
echo ""
echo "Uptime:"
uptime
echo ""
echo "Network:"
hostname -I
```

### Update Script
```bash
#!/bin/bash
echo "Updating system..."
sudo apt update
sudo apt full-upgrade -y
sudo apt autoremove -y
sudo apt clean
echo "System updated!"
```

### Backup Script
```bash
#!/bin/bash
BACKUP_DIR=~/backups/$(date +%Y%m%d)
mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/home.tar.gz /home/pi
tar -czf $BACKUP_DIR/etc.tar.gz /etc
echo "Backup completed: $BACKUP_DIR"
```

## Additional Resources

- Official Documentation: https://www.raspberrypi.com/documentation/
- Forums: https://forums.raspberrypi.com/
- Raspberry Pi StackExchange: https://raspberrypi.stackexchange.com/
- GPIO Pinout: https://pinout.xyz/
