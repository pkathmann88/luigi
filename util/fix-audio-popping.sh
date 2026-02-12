#!/bin/bash
################################################################################
# Luigi - Audio Popping Fix Utility
#
# This standalone script fixes audio popping/crackling on I2S devices like
# the Adafruit Sound Bonnet without requiring a full reinstallation.
#
# Usage: sudo ./util/fix-audio-popping.sh
#
# The script will:
# 1. Detect if you have an I2S audio device
# 2. Offer two solutions (improved ALSA config or silence playback service)
# 3. Apply the selected fix
# 4. Test audio playback if test files are available
#
# Author: Luigi Project
# License: MIT
################################################################################

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root"
    echo "Please run: sudo $0"
    exit 1
fi

log_header "Luigi Audio Popping Fix"
echo ""

# Check for I2S audio device
log_info "Checking for I2S audio device..."
echo ""

boot_configs=("/boot/firmware/config.txt" "/boot/config.txt")
config_file=""
has_i2s=0

for config in "${boot_configs[@]}"; do
    if [ -f "$config" ]; then
        config_file="$config"
        if grep -qE "dtoverlay=(hifiberry-dac|googlevoicehat-soundcard|adau7002-simple|i2s-mmap)" "$config" 2>/dev/null; then
            has_i2s=1
            break
        fi
    fi
done

if [ $has_i2s -eq 0 ]; then
    log_info "No I2S audio device detected in boot configuration"
    log_info "This fix is only needed for Adafruit Sound Bonnet and similar I2S devices"
    echo ""
    log_info "If you have an I2S device but it's not detected, check that the"
    log_info "device tree overlay is correctly configured in $config_file"
    echo ""
    exit 0
fi

log_info "✓ I2S audio device detected (Sound Bonnet or similar)"
echo ""

# Explain the problem
cat <<EOF
${YELLOW}What is the audio popping issue?${NC}

I2S audio devices like the Adafruit Sound Bonnet often produce annoying
"popping" or "crackling" sounds at the start and end of audio playback.

This happens because the digital-to-analog converter (DAC) loses sync with
the I2S clock when the audio interface powers down between sounds. When a
new sound starts, the DAC "wakes up" and re-syncs, creating an audible pop.

${CYAN}Two solutions are available:${NC}

  ${GREEN}1. Software-only fix (RECOMMENDED)${NC}
     - Creates an improved ALSA configuration with dmix plugin
     - Keeps audio buffers active longer to prevent DAC power cycling
     - No CPU overhead, no device blocking
     - Works with all applications simultaneously
     - Backs up existing configuration

  ${GREEN}2. Silence playback service${NC}
     - Plays continuous silence to keep DAC active at all times
     - Eliminates popping completely
     - Uses ~3-5% CPU on Pi Zero W (idle priority)
     - May conflict with some audio applications

EOF

read -p "Would you like to apply a fix? (y/N): " -n 1 -r
echo ""
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "No changes made"
    exit 0
fi

# Ask which solution
echo "Which solution would you like to use?"
echo "  1. Software-only fix (recommended)"
echo "  2. Silence playback service"
echo ""
read -p "Enter choice (1 or 2, default 1): " -n 1 -r
echo ""
echo ""

REPLY=${REPLY:-1}

if [[ $REPLY == "2" ]]; then
    # Install silence playback service
    log_step "Installing silence playback service..."
    echo ""
    
    log_info "Creating systemd service: luigi-silence-audio.service"
    
    cat > /etc/systemd/system/luigi-silence-audio.service <<'EOF'
[Unit]
Description=Luigi Audio Silence Playback (Prevents I2S DAC Popping)
Documentation=https://github.com/pkathmann88/luigi
After=sound.target alsa-restore.service

[Service]
Type=simple
# Play silence continuously to keep I2S DAC active
# This prevents popping/crackling sounds when audio starts/stops
ExecStart=/usr/bin/aplay -q -D default -c 2 -f S16_LE -r 44100 -t raw /dev/zero
Restart=always
RestartSec=3
StandardOutput=null
StandardError=null

# Use idle priority to minimize CPU impact
Nice=19
CPUSchedulingPolicy=idle

[Install]
WantedBy=multi-user.target
EOF
    
    chmod 644 /etc/systemd/system/luigi-silence-audio.service
    
    log_info "✓ Service file created"
    echo ""
    
    log_info "Enabling and starting service..."
    systemctl daemon-reload
    systemctl enable luigi-silence-audio.service
    systemctl start luigi-silence-audio.service
    
    sleep 2
    
    if systemctl is-active --quiet luigi-silence-audio.service; then
        log_info "✓ Silence playback service is running"
        echo ""
        log_info "${GREEN}Audio popping should now be eliminated!${NC}"
        log_info "Note: This service uses ~3-5% CPU on Pi Zero W (idle priority)"
        echo ""
        log_info "To disable if you experience issues:"
        echo "  sudo systemctl stop luigi-silence-audio.service"
        echo "  sudo systemctl disable luigi-silence-audio.service"
        echo ""
        log_info "To remove the service completely:"
        echo "  sudo systemctl stop luigi-silence-audio.service"
        echo "  sudo systemctl disable luigi-silence-audio.service"
        echo "  sudo rm /etc/systemd/system/luigi-silence-audio.service"
        echo "  sudo systemctl daemon-reload"
    else
        log_error "Failed to start silence playback service"
        log_error "Check status with: sudo systemctl status luigi-silence-audio.service"
        exit 1
    fi
    
else
    # Apply software-only fix
    log_step "Applying software-only fix..."
    echo ""
    
    # Check if /etc/asound.conf exists
    if [ ! -f /etc/asound.conf ]; then
        log_error "ALSA configuration (/etc/asound.conf) not found"
        log_error "You need to configure your audio device first"
        echo ""
        log_info "Run the main Luigi setup to configure audio:"
        echo "  cd /path/to/luigi"
        echo "  sudo ./setup.sh install"
        echo ""
        exit 1
    fi
    
    # Extract current card and device from asound.conf
    # Use sed for better portability than grep -P
    card=$(grep 'card [0-9]' /etc/asound.conf | sed -n 's/.*card \([0-9]\+\).*/\1/p' | head -1)
    device=$(grep 'device [0-9]' /etc/asound.conf | sed -n 's/.*device \([0-9]\+\).*/\1/p' | head -1)
    
    if [ -z "$card" ] || [ -z "$device" ]; then
        log_error "Could not determine audio card/device from /etc/asound.conf"
        log_error "Your asound.conf may have an unsupported format"
        echo ""
        log_info "Current /etc/asound.conf contents:"
        cat /etc/asound.conf
        echo ""
        exit 1
    fi
    
    log_info "Current audio configuration: Card $card, Device $device"
    
    # Create backup
    backup_file="/etc/asound.conf.bak.$(date +%Y%m%d_%H%M%S)"
    log_info "Backing up /etc/asound.conf to $backup_file..."
    cp /etc/asound.conf "$backup_file"
    
    log_info "Creating improved ALSA configuration with anti-popping buffers..."
    
    # Create improved configuration with dmix and proper buffering
    cat > /etc/asound.conf <<EOF
# ALSA configuration for Luigi (with anti-popping fix)
# Created by fix-audio-popping.sh on $(date)
# Card $card, Device $device
#
# This configuration uses dmix (software mixing) with optimized buffer settings
# to prevent audio popping/crackling on I2S devices like the Adafruit Sound Bonnet

# Hardware device with plug for format conversion
pcm.hw_card {
    type plug
    slave.pcm {
        type hw
        card $card
        device $device
    }
}

# DMix device for software mixing and better buffering
pcm.dmixed {
    type dmix
    ipc_key 1024
    ipc_perm 0666
    slave {
        pcm "hw_card"
        # Larger buffer reduces popping but may add slight latency
        period_time 0
        period_size 2048
        buffer_size 16384
        rate 44100
    }
    bindings {
        0 0
        1 1
    }
}

# Default PCM device
pcm.!default {
    type plug
    slave.pcm "dmixed"
}

# Default control device
ctl.!default {
    type hw
    card $card
}
EOF
    
    log_info "✓ Improved ALSA configuration created"
    echo ""
    
    # Test the new configuration if test sounds exist
    log_info "Testing audio with new configuration..."
    test_dirs=("/usr/share/sounds/mario" "/usr/share/sounds/alsa")
    test_passed=0
    
    for dir in "${test_dirs[@]}"; do
        if [ -d "$dir" ]; then
            test_sound=$(find "$dir" -name "*.wav" -print -quit 2>/dev/null)
            if [ -n "$test_sound" ]; then
                if timeout 5 aplay -q "$test_sound" 2>/dev/null; then
                    log_info "✓ Audio test successful!"
                    test_passed=1
                else
                    log_warn "Audio test failed - reverting to backup"
                    mv "$backup_file" /etc/asound.conf
                    log_error "Configuration rolled back. Original config restored."
                    echo ""
                    log_info "The software fix may not be compatible with your setup."
                    log_info "You can try the silence playback service instead:"
                    echo "  sudo $0"
                    echo "  (choose option 2)"
                    exit 1
                fi
                break
            fi
        fi
    done
    
    if [ $test_passed -eq 0 ]; then
        log_info "✓ Configuration applied (no test sounds available for verification)"
    fi
    
    echo ""
    log_info "${GREEN}Audio popping fix applied successfully!${NC}"
    log_info ""
    log_info "The improved buffering should significantly reduce or eliminate popping."
    log_info ""
    log_info "If you still experience popping:"
    log_info "  1. Try the silence playback service: sudo $0 (choose option 2)"
    log_info "  2. Restore the backup: sudo cp $backup_file /etc/asound.conf"
    echo ""
fi

log_info "Done!"
