# System Reference for Luigi Deployment

Quick reference for common system commands used in Luigi deployment scripts.

## Service Management

### Init.d Commands

```bash
# Start service
sudo service mario start

# Stop service
sudo service mario stop

# Restart service
sudo service mario restart

# Check status
sudo service mario status

# Enable at boot
sudo update-rc.d mario defaults

# Disable at boot
sudo update-rc.d mario remove
```

### Systemd Commands (Alternative)

```bash
# Start service
sudo systemctl start mario.service

# Stop service
sudo systemctl stop mario.service

# Restart service
sudo systemctl restart mario.service

# Check status
sudo systemctl status mario.service

# Enable at boot
sudo systemctl enable mario.service

# Disable at boot
sudo systemctl disable mario.service

# Reload configuration
sudo systemctl daemon-reload

# View logs
sudo journalctl -u mario.service -f
```

## Package Management

### APT Commands

```bash
# Update package list
sudo apt-get update

# Install package
sudo apt-get install -y package-name

# Install multiple packages
sudo apt-get install -y python3-rpi.gpio alsa-utils git

# Remove package
sudo apt-get remove package-name

# Remove package and config files
sudo apt-get purge package-name

# Clean up
sudo apt-get autoremove
sudo apt-get clean

# Check if package is installed
dpkg -l | grep package-name
```

### Python Package Management

```bash
# Install pip
sudo apt-get install -y python3-pip

# Install Python package
sudo pip3 install package-name

# List installed packages
pip3 list

# Show package details
pip3 show package-name
```

## File Operations

### Directory Management

```bash
# Create directory
mkdir -p /path/to/directory

# Remove directory
rm -rf /path/to/directory

# Copy directory
cp -r /source /destination

# Move/rename directory
mv /source /destination

# Check directory size
du -sh /path/to/directory
```

### File Management

```bash
# Copy file
cp source.txt destination.txt

# Move/rename file
mv old.txt new.txt

# Remove file
rm file.txt

# Create empty file
touch file.txt

# Set permissions
chmod 755 script.sh    # rwxr-xr-x
chmod 644 file.txt     # rw-r--r--

# Set ownership
chown user:group file.txt
chown -R user:group /directory

# Check file permissions
ls -l file.txt
```

### Archive Operations

```bash
# Extract tar.gz
tar -xzf archive.tar.gz

# Extract to specific directory
tar -xzf archive.tar.gz -C /destination

# Create tar.gz
tar -czf archive.tar.gz /source

# List archive contents
tar -tzf archive.tar.gz

# Extract specific file
tar -xzf archive.tar.gz path/to/file
```

## Log Management

### Viewing Logs

```bash
# View last 20 lines
tail -20 /var/log/motion.log

# Follow log in real-time
tail -f /var/log/motion.log

# View first 20 lines
head -20 /var/log/motion.log

# Search log
grep "error" /var/log/motion.log

# View entire log with pagination
less /var/log/motion.log
```

### Log Rotation

```bash
# Create logrotate config
sudo nano /etc/logrotate.d/luigi

# Example config:
# /var/log/motion.log {
#     daily
#     rotate 7
#     compress
#     missingok
#     notifempty
#     create 644 root root
# }

# Test logrotate
sudo logrotate -d /etc/logrotate.d/luigi

# Force rotation
sudo logrotate -f /etc/logrotate.d/luigi
```

## Process Management

### Process Commands

```bash
# List all processes
ps aux

# Find process by name
ps aux | grep mario

# Kill process by PID
kill PID

# Force kill
kill -9 PID

# Kill by name
pkill mario.py

# Show process tree
pstree

# Monitor processes
top
htop  # if installed
```

### Background Processes

```bash
# Run in background
./script.sh &

# List background jobs
jobs

# Bring to foreground
fg %1

# Send to background
bg %1
```

## System Information

### Hardware Info

```bash
# CPU info
cat /proc/cpuinfo

# Memory info
free -h

# Disk usage
df -h

# System uptime
uptime

# Kernel version
uname -a

# Raspberry Pi specific
vcgencmd measure_temp     # Temperature
vcgencmd get_mem arm      # ARM memory
vcgencmd get_mem gpu      # GPU memory
```

### Network Info

```bash
# Network interfaces
ip addr
ifconfig  # deprecated but still works

# Network connections
netstat -tuln
ss -tuln

# Test connectivity
ping -c 4 8.8.8.8

# DNS lookup
nslookup example.com
```

## Audio Commands

### ALSA Commands

```bash
# Play audio file
aplay /path/to/file.wav

# List audio devices
aplay -l

# Adjust volume
alsamixer

# Set volume (0-100%)
amixer set Master 75%

# Mute/unmute
amixer set Master mute
amixer set Master unmute

# Test audio
speaker-test -t sine -f 1000 -l 1
```

### Audio Configuration

```bash
# Configure audio output
sudo raspi-config
# Navigate to: System Options > Audio > Choose output

# Test audio device
aplay -D plughw:0,0 test.wav

# Check audio device status
cat /proc/asound/cards
```

## GPIO Commands

### GPIO Testing

```bash
# Test GPIO library
python3 -c "import RPi.GPIO; print('GPIO OK')"

# Interactive GPIO test
python3 << 'EOF'
import RPi.GPIO as GPIO
GPIO.setmode(GPIO.BCM)
GPIO.setup(23, GPIO.IN)
print(f"GPIO 23: {GPIO.input(23)}")
GPIO.cleanup()
EOF
```

### GPIO Utilities

```bash
# Install GPIO utilities
sudo apt-get install -y wiringpi

# Read GPIO pin
gpio -g read 23

# Set GPIO mode
gpio -g mode 23 in

# Monitor GPIO
gpio -g wfi 23 rising  # Wait for interrupt
```

## Git Commands

### Repository Operations

```bash
# Clone repository
git clone https://github.com/pkathmann88/luigi.git

# Pull latest changes
cd /opt/luigi
git pull

# Check status
git status

# View commit history
git log --oneline -10

# Switch branch
git checkout branch-name

# Show remote URL
git remote -v
```

## Text Editing

### Nano

```bash
# Edit file
nano file.txt

# Common shortcuts:
# Ctrl+O: Save
# Ctrl+X: Exit
# Ctrl+K: Cut line
# Ctrl+U: Paste
# Ctrl+W: Search
```

### Vim

```bash
# Edit file
vim file.txt

# Common commands:
# i: Insert mode
# Esc: Command mode
# :w: Save
# :q: Quit
# :wq: Save and quit
# :q!: Quit without saving
```

## Script Testing

### Validation Commands

```bash
# Check Python syntax
python3 -m py_compile script.py

# Check shell script syntax
bash -n script.sh

# Check with shellcheck
shellcheck script.sh

# Make script executable
chmod +x script.sh

# Test script without execution
bash -x script.sh  # Debug mode
```

### Script Debugging

```bash
# Enable debug mode in script
set -x  # Print commands
set -e  # Exit on error
set -u  # Exit on undefined variable

# Disable debug mode
set +x
```

## User Management

### User Commands

```bash
# Add user
sudo adduser username

# Delete user
sudo deluser username

# Add to group
sudo usermod -aG groupname username

# Switch user
su - username

# Run as different user
sudo -u username command
```

## Cron Jobs

### Crontab Management

```bash
# Edit crontab
crontab -e

# List crontab
crontab -l

# Remove crontab
crontab -r

# Example entries:
# Run every reboot
@reboot /path/to/script.sh

# Run daily at 2am
0 2 * * * /path/to/script.sh

# Run every hour
0 * * * * /path/to/script.sh
```

## Troubleshooting

### Common Checks

```bash
# Check if port is listening
sudo netstat -tulpn | grep :PORT

# Check file dependencies
ldd /path/to/binary

# Check which process using file
lsof /path/to/file

# Check disk I/O
iostat

# Check system messages
dmesg | tail

# Check system errors
journalctl -p err -b
```

### Raspberry Pi Specific

```bash
# Open configuration tool
sudo raspi-config

# Check throttling
vcgencmd get_throttled

# Reboot
sudo reboot

# Shutdown
sudo shutdown -h now
```

## Backup and Restore

### Backup Commands

```bash
# Backup directory
tar -czf backup.tar.gz /opt/luigi

# Backup with date
tar -czf "backup-$(date +%Y%m%d).tar.gz" /opt/luigi

# Restore from backup
tar -xzf backup.tar.gz -C /

# Copy with rsync
rsync -av /source/ /destination/
```

## Performance Monitoring

### System Monitoring

```bash
# CPU and memory usage
top

# Disk I/O
iotop

# Network usage
iftop

# Process monitoring
watch -n 1 'ps aux | grep mario'
```

## File Search

### Find Commands

```bash
# Find file by name
find /path -name "filename"

# Find by type
find /path -type f  # Files
find /path -type d  # Directories

# Find by size
find /path -size +10M  # Larger than 10MB

# Find and execute
find /path -name "*.log" -exec rm {} \;
```

### Grep Commands

```bash
# Search in file
grep "pattern" file.txt

# Search recursively
grep -r "pattern" /path

# Case insensitive
grep -i "pattern" file.txt

# Show line numbers
grep -n "pattern" file.txt

# Invert match
grep -v "pattern" file.txt
```

## Quick Shortcuts

```bash
# Previous command
!!

# Previous command's argument
!$

# Clear screen
clear
# or Ctrl+L

# Exit terminal
exit
# or Ctrl+D

# Stop current command
# Ctrl+C

# Background current command
# Ctrl+Z
```

---

**Note**: Always use `sudo` for commands that require root privileges (service management, package installation, system configuration).
