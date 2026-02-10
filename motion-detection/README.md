# Motion Detection Components

This directory contains various motion detection implementations for the Luigi project.

## Overview

The motion detection components use PIR (Passive Infrared) sensors to detect movement and trigger various actions. These components are designed to run on Raspberry Pi hardware with Raspberry Pi OS.

## Available Components

### Mario
A motion detection system that plays random Mario-themed sound effects when motion is detected.

**Location**: `motion-detection/mario/`

See [motion-detection/mario/README.md](mario/README.md) for complete documentation including features, installation, configuration, and troubleshooting.

## Hardware Requirements

All components in this directory require:
- Raspberry Pi (tested on Raspberry Pi Zero W)
- PIR motion sensor (HC-SR501 or similar)
- Audio output (3.5mm jack, HDMI, or USB audio device)

## General Setup

1. Connect PIR sensor to appropriate GPIO pins (refer to specific component documentation)
2. Ensure audio output is properly configured on your Raspberry Pi
3. Install required Python dependencies (RPi.GPIO, etc.)
4. Follow component-specific installation instructions

## Contributing

When adding new motion detection components:
1. Create a new subdirectory with a descriptive name
2. Include a detailed README.md with setup and usage instructions
3. Document GPIO pin assignments and hardware requirements
4. Provide example use cases and configuration options

## See Also

- Main project documentation: [../README.md](../README.md)
- Mario component: [mario/README.md](mario/README.md)
