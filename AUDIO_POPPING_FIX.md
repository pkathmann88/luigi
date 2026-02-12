# Audio Popping Fix - Sound Bonnet and I2S Devices

## Problem Description

If you're using an I2S audio device like the **Adafruit Sound Bonnet** (or similar I2S DACs), you may experience annoying "popping" or "crackling" sounds at the beginning and/or end of audio playback.

**Symptoms:**
- Audible "pop" or "crack" when sound starts playing
- Audible "pop" or "crack" when sound finishes playing
- Otherwise clear audio during playback
- Issue occurs with every sound, every time

## Root Cause

This is a **known issue** with I2S (Inter-IC Sound) digital-to-analog converters (DACs). The popping occurs because:

1. When no audio is playing, the Raspberry Pi's I2S interface powers down to save energy
2. The DAC chip (e.g., MAX98357A in the Sound Bonnet) loses sync with the I2S clock
3. When new audio starts, the I2S interface powers back on
4. The DAC needs to re-sync with the I2S clock, causing a brief noise artifact
5. The same happens in reverse when audio stops

This is a **hardware limitation**, not a bug in Luigi or your code. It affects all I2S audio HATs/Bonnets on Raspberry Pi.

## Solutions

Luigi provides **two proven solutions** to fix this issue. You can choose the one that best fits your needs.

### Solution 1: Software-Only Fix (Recommended)

**What it does:**
- Reconfigures ALSA (Advanced Linux Sound Architecture) to use larger audio buffers
- Uses the dmix plugin for software mixing
- Keeps audio buffers active longer, preventing the I2S interface from powering down immediately

**Advantages:**
- ✅ No CPU overhead
- ✅ No additional services running
- ✅ Works with all audio applications simultaneously
- ✅ Significantly reduces or eliminates popping
- ✅ Automatic backup and rollback

**Disadvantages:**
- ⚠️ May not eliminate popping 100% in all cases
- ⚠️ Adds ~50ms of audio latency (usually unnoticeable)

**Best for:**
- General use cases
- Battery-powered or low-power setups
- When you want minimal system changes

### Solution 2: Silence Playback Service

**What it does:**
- Creates a systemd service that continuously plays silence (from `/dev/zero`)
- Keeps the I2S interface permanently active
- Prevents the DAC from ever losing sync

**Advantages:**
- ✅ Eliminates popping 100%
- ✅ Simple and reliable
- ✅ Proven solution from Adafruit

**Disadvantages:**
- ⚠️ Uses ~3-5% CPU on Raspberry Pi Zero W (idle priority)
- ⚠️ May conflict with some audio applications (rare)
- ⚠️ Additional systemd service to manage

**Best for:**
- Critical audio applications where any popping is unacceptable
- Setups with adequate power supply
- When you need guaranteed pop-free audio

## How to Apply the Fix

### Option A: During Luigi Installation (Automated)

When you run `sudo ./setup.sh install`, you'll be prompted:

```
Would you like to apply the audio popping fix? (y/N)
```

Choose 'y', then select which solution you prefer (1 or 2).

### Option B: Standalone Utility (After Installation)

If Luigi is already installed and you want to apply the fix:

```bash
cd /path/to/luigi
sudo ./util/fix-audio-popping.sh
```

Follow the interactive prompts to choose and apply a solution.

### Option C: Manual Configuration

If you prefer to configure it manually, see the detailed instructions in `motion-detection/mario/README.md` under the "Audio Popping/Crackling" troubleshooting section.

## Verification

After applying a fix, test your audio:

```bash
# Test with a Mario sound (if installed)
aplay /usr/share/sounds/mario/callingmario1.wav

# Or test with a system sound
speaker-test -t wav -c 2 -l 1
```

Listen carefully for popping at the start and end of the sound. If popping persists:
1. Try the alternative solution (if you used software fix, try silence service)
2. Check that your audio device is correctly configured
3. Verify the I2S device tree overlay is properly loaded

## Switching Between Solutions

### From Software Fix to Silence Service

```bash
cd /path/to/luigi
sudo ./util/fix-audio-popping.sh
# Choose option 2
```

### From Silence Service to Software Fix

```bash
# First stop and disable the service
sudo systemctl stop luigi-silence-audio.service
sudo systemctl disable luigi-silence-audio.service

# Then apply software fix
cd /path/to/luigi
sudo ./util/fix-audio-popping.sh
# Choose option 1
```

## Removing the Fix

### Remove Software Fix

Restore your backup (the utility creates timestamped backups):

```bash
# List available backups
ls -l /etc/asound.conf.bak*

# Restore a backup
sudo cp /etc/asound.conf.bak.YYYYMMDD_HHMMSS /etc/asound.conf
```

### Remove Silence Service

```bash
sudo systemctl stop luigi-silence-audio.service
sudo systemctl disable luigi-silence-audio.service
sudo rm /etc/systemd/system/luigi-silence-audio.service
sudo systemctl daemon-reload
```

## Technical Details

### Software Fix Details

The improved ALSA configuration uses:
- **dmix plugin**: Allows multiple applications to share the audio device
- **period_size: 2048**: Larger period size for better buffering
- **buffer_size: 16384**: Large buffer keeps audio pipeline active longer
- **rate: 44100**: Standard CD-quality sample rate

### Silence Service Details

The systemd service runs:
```bash
aplay -q -D default -c 2 -f S16_LE -r 44100 -t raw /dev/zero
```

Parameters:
- `-q`: Quiet mode (no status output)
- `-D default`: Use default audio device
- `-c 2`: 2 channels (stereo)
- `-f S16_LE`: 16-bit little-endian format
- `-r 44100`: 44.1kHz sample rate
- `-t raw`: Raw audio format
- `/dev/zero`: Infinite stream of zeros (silence)

The service uses:
- `Nice=19`: Lowest CPU priority
- `CPUSchedulingPolicy=idle`: Only uses idle CPU cycles
- `Restart=always`: Automatically restarts if it crashes

## Troubleshooting

### "Device or resource busy" Error

If you get this error after enabling the silence service:

```bash
# Stop the silence service temporarily
sudo systemctl stop luigi-silence-audio.service

# Play your audio
aplay /path/to/sound.wav

# Restart the silence service
sudo systemctl start luigi-silence-audio.service
```

This usually indicates a conflict. Consider switching to the software-only fix.

### Popping Still Occurs

If popping persists after applying the software fix:
1. Verify the fix was applied: `cat /etc/asound.conf | grep dmix`
2. Try the silence playback service instead
3. Check your Sound Bonnet is properly seated and configured
4. Verify the I2S overlay in `/boot/config.txt` or `/boot/firmware/config.txt`

### High CPU Usage with Silence Service

If the silence service uses too much CPU:
1. Verify it's using idle scheduling: `systemctl status luigi-silence-audio.service`
2. Consider switching to the software-only fix
3. Check for other high-CPU processes competing for resources

## Additional Resources

- **Adafruit Sound Bonnet Guide**: https://learn.adafruit.com/adafruit-speaker-bonnet-for-raspberry-pi/raspberry-pi-usage
- **Luigi Main README**: `README.md` (installation and setup)
- **Mario Module README**: `motion-detection/mario/README.md` (detailed troubleshooting)
- **Raspberry Pi Forums**: Search for "I2S audio popping" for community solutions

## Support

If you continue to experience issues after trying both solutions:
1. Check that your Sound Bonnet is correctly installed
2. Verify the device tree overlay is loaded: `dtoverlay -l`
3. Test with a different audio device to isolate the issue
4. Report the issue on the Luigi GitHub repository with:
   - Your Raspberry Pi model
   - Sound Bonnet type
   - Output of `aplay -l`
   - Contents of `/etc/asound.conf`
   - Contents of `/boot/config.txt` or `/boot/firmware/config.txt`

---

**Last Updated**: 2026-02-12  
**Luigi Version**: 1.0+  
**Tested With**: Adafruit Sound Bonnet, Raspberry Pi Zero W
