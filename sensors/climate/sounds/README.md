# Climate Alert Sounds

This directory contains audio alert files for climate threshold violations.

## Required Files

The climate module expects the following WAV files to be present:

- `alert_hot.wav` - Played when temperature exceeds maximum threshold
- `alert_cold.wav` - Played when temperature falls below minimum threshold
- `alert_humid.wav` - Played when humidity exceeds maximum threshold
- `alert_dry.wav` - Played when humidity falls below minimum threshold

## Installation

### Option 1: Use Your Own Sounds

Place your own WAV audio files in this directory. The files should be:
- Format: WAV
- Sample rate: 44.1kHz recommended
- Duration: 2-5 seconds recommended
- Volume: Normalized to prevent clipping

### Option 2: Generate Simple Beeps

You can generate simple beep sounds using `sox` (Sound eXchange):

```bash
# Install sox
sudo apt-get install sox

# Generate alert sounds (example)
sox -n alert_hot.wav synth 0.5 sine 880 fade 0 0.5 0.1
sox -n alert_cold.wav synth 0.5 sine 440 fade 0 0.5 0.1
sox -n alert_humid.wav synth 0.5 sine 660 fade 0 0.5 0.1
sox -n alert_dry.wav synth 0.5 sine 550 fade 0 0.5 0.1
```

### Option 3: Download Free Sounds

You can download Creative Commons or Public Domain sound effects from:
- https://freesound.org/
- https://www.zapsplat.com/
- https://soundbible.com/

## Configuration

The sound file paths can be configured in `/etc/luigi/sensors/climate/climate.conf`:

```yaml
alerts:
  sounds:
    too_hot: "/usr/share/sounds/climate/alert_hot.wav"
    too_cold: "/usr/share/sounds/climate/alert_cold.wav"
    too_humid: "/usr/share/sounds/climate/alert_humid.wav"
    too_dry: "/usr/share/sounds/climate/alert_dry.wav"
```

## Disabling Audio Alerts

If you don't want audio alerts, you can disable them in the configuration:

```yaml
alerts:
  audio_enabled: false
```

The module will still log threshold violations but won't play sounds.
