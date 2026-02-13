# Climate Monitoring Module

**Module:** sensors/climate  
**Category:** Sensors  
**Status:** Production Ready  
**Version:** 1.0.0

Real-time temperature and humidity monitoring with DHT22 or BME280 sensors. Features database logging, threshold alerts, derived meteorological calculations, and Home Assistant integration via MQTT.

---

## Overview

The Climate module provides comprehensive environmental monitoring for indoor spaces. It continuously reads temperature and humidity data, logs it to a SQLite database, calculates derived metrics (dew point, heat index, comfort level), and triggers audio alerts when thresholds are exceeded.

### Key Features

- **Dual Sensor Support** - Works with DHT22 (GPIO-based) or BME280 (I2C-based) sensors
- **Real-time Monitoring** - Configurable reading intervals (default: 30 seconds)
- **Database Logging** - SQLite storage with automatic retention management
- **Derived Metrics** - Dew point, heat index, and comfort level calculations
- **Threshold Alerts** - Configurable min/max limits with audio alerts
- **Alert Cooldown** - Prevents alert spam with configurable cooldown periods
- **Home Assistant Integration** - Automatic sensor discovery via MQTT
- **Data Export** - Export historical data to CSV or JSON formats
- **Graceful Shutdown** - Clean service lifecycle management
- **Mock Mode** - Development without hardware using mock sensors

### Why This Module

- **Health & Comfort** - Monitor indoor air quality and comfort levels
- **Equipment Protection** - Alert when conditions exceed safe ranges for electronics
- **Energy Efficiency** - Identify opportunities to optimize HVAC usage
- **Historical Analysis** - Track environmental trends over time
- **Home Automation** - Integrate with smart home systems via Home Assistant

---

## Contents

```
sensors/climate/
├── README.md                              # This file
├── module.json                            # Module metadata
├── setup.sh                               # Installation script
├── requirements.txt                       # Python dependencies
├── climate_module.py                      # Main application
├── climate.service                        # systemd service unit
├── climate_temperature_descriptor.json    # MQTT sensor descriptor (temp)
├── climate_humidity_descriptor.json       # MQTT sensor descriptor (humidity)
├── config/
│   └── climate.conf.example               # Default configuration
├── sensors/
│   ├── __init__.py                        # Package init
│   ├── base_sensor.py                     # Abstract sensor interface
│   ├── dht22_sensor.py                    # DHT22 driver
│   └── bme280_sensor.py                   # BME280 driver
├── database/
│   ├── __init__.py                        # Package init
│   └── climate_db.py                      # Database operations
└── sounds/
    └── README.md                          # Alert sounds documentation
```

---

## Hardware Requirements

### Option 1: DHT22 Sensor (Recommended for Beginners)

**Components:**
- DHT22 (AM2302) temperature and humidity sensor
- 10kΩ pull-up resistor
- 3 female-to-female jumper wires

**Specifications:**
- Temperature range: -40°C to 80°C (±0.5°C accuracy)
- Humidity range: 0% to 100% RH (±2% accuracy)
- Power: 3.3V-5V DC
- Interface: Single digital GPIO pin
- Reading interval: Minimum 2 seconds

**Wiring (GPIO 4):**

```
DHT22 Sensor         Raspberry Pi Zero W
┌──────────┐         ┌─────────────────┐
│          │         │                 │
│  VCC (+) ├─────────┤ Pin 1 (3.3V)    │
│          │         │                 │
│  DATA    ├────┬────┤ Pin 7 (GPIO 4)  │
│          │    │    │                 │
│          │    └────┤ Pin 1 (3.3V)    │ (via 10kΩ resistor)
│          │         │                 │
│  GND (-) ├─────────┤ Pin 9 (GND)     │
│          │         │                 │
└──────────┘         └─────────────────┘
```

**Pin Details:**
- VCC: Pin 1 (3.3V) or Pin 2 (5V)
- DATA: Pin 7 (GPIO 4) - Configurable
- GND: Pin 9 (Ground)
- Pull-up resistor: 10kΩ between DATA and VCC

### Option 2: BME280 Sensor (Advanced)

**Components:**
- BME280 temperature, humidity, and pressure sensor (I2C module)
- 4 female-to-female jumper wires

**Specifications:**
- Temperature range: -40°C to 85°C (±1°C accuracy)
- Humidity range: 0% to 100% RH (±3% accuracy)
- Pressure range: 300-1100 hPa (±1 hPa accuracy)
- Power: 3.3V DC
- Interface: I2C (address 0x76 or 0x77)
- Reading interval: Sub-second

**Wiring (I2C):**

```
BME280 Sensor        Raspberry Pi Zero W
┌──────────┐         ┌─────────────────┐
│          │         │                 │
│  VCC (+) ├─────────┤ Pin 1 (3.3V)    │
│          │         │                 │
│  GND (-) ├─────────┤ Pin 9 (GND)     │
│          │         │                 │
│  SCL     ├─────────┤ Pin 5 (SCL)     │
│          │         │                 │
│  SDA     ├─────────┤ Pin 3 (SDA)     │
│          │         │                 │
└──────────┘         └─────────────────┘
```

**Pin Details:**
- VCC: Pin 1 (3.3V)
- GND: Pin 9 (Ground)
- SCL: Pin 5 (GPIO 3 / SCL)
- SDA: Pin 3 (GPIO 2 / SDA)

**I2C Configuration:**
```bash
# Enable I2C interface
sudo raspi-config
# Navigate to: Interface Options → I2C → Enable

# Verify I2C is enabled
ls /dev/i2c-*

# Detect sensor (should show 76 or 77)
sudo i2cdetect -y 1
```

### Audio Output

For audio alerts, you need:
- Built-in audio jack (3.5mm) with speakers/headphones, OR
- USB audio device, OR
- I2S audio DAC (e.g., Adafruit Sound Bonnet)

---

## Installation

### Prerequisites

1. **Raspberry Pi Setup**
   - Raspberry Pi Zero W (or any Pi model) with Raspberry Pi OS
   - Internet connection
   - SSH access or direct terminal access

2. **Luigi Framework**
   - Luigi repository cloned
   - Located at `/path/to/luigi`

3. **Dependencies** (optional - ha-mqtt)
   - For Home Assistant integration, install `iot/ha-mqtt` module first

### Quick Install

```bash
# Navigate to Luigi repository
cd /path/to/luigi

# Install Climate module
sudo sensors/climate/setup.sh install
```

### Installation Steps

The setup script performs the following:

1. **Install System Dependencies**
   - `python3-pip` - Python package manager
   - `python3-venv` - Python virtual environments
   - `sqlite3` - Database engine
   - `python3-yaml` - YAML configuration parser
   - `alsa-utils` - Audio playback (`aplay`)

2. **Install Python Packages**
   - `adafruit-circuitpython-dht` - DHT22 sensor library
   - `adafruit-circuitpython-bme280` - BME280 sensor library
   - `PyYAML` - YAML configuration support

3. **Deploy Module Files**
   - Python modules → `/usr/local/lib/climate/`
   - Configuration → `/etc/luigi/sensors/climate/climate.conf`
   - Service unit → `/etc/systemd/system/climate.service`
   - Alert sounds directory → `/usr/share/sounds/climate/`

4. **Create Data Directories**
   - Database directory → `/var/lib/luigi/`
   - Log directory → `/var/log/luigi/`

5. **Register with Home Assistant**
   - Install sensor descriptors → `/etc/luigi/iot/ha-mqtt/sensors.d/`
   - Run MQTT discovery (if ha-mqtt installed)

6. **Start Service**
   - Enable automatic startup on boot
   - Start climate monitoring service
   - Verify service is running

### Post-Installation

After installation completes:

```bash
# Check service status
sudo systemctl status climate.service

# View live logs
sudo journalctl -u climate.service -f

# Test sensor reading (mock mode will be used if no hardware)
# Logs will show temperature and humidity readings

# Add alert sounds (optional)
# See /usr/share/sounds/climate/README.md
```

---

## Configuration

Configuration file: `/etc/luigi/sensors/climate/climate.conf`

### Default Configuration

```yaml
climate:
  enabled: true
  
  # Sensor configuration
  sensor:
    type: "dht22"           # Options: dht22, bme280
    gpio_pin: 4             # GPIO pin for DHT22 (BCM numbering)
    i2c_address: 0x76       # I2C address for BME280 (0x76 or 0x77)
  
  # Reading and logging intervals
  intervals:
    reading_seconds: 30     # How often to read sensor
    logging_seconds: 300    # How often to log to database (5 minutes)
  
  # Threshold configuration
  thresholds:
    temperature:
      min_celsius: 15       # Minimum comfortable temperature
      max_celsius: 30       # Maximum comfortable temperature
      unit_display: "celsius"
    humidity:
      min_percent: 30       # Minimum comfortable humidity
      max_percent: 70       # Maximum comfortable humidity
  
  # Alert configuration
  alerts:
    enabled: true           # Enable/disable alerts
    cooldown_minutes: 30    # Minimum time between same alert type
    audio_enabled: true     # Enable/disable audio alerts
    sounds:
      too_hot: "/usr/share/sounds/climate/alert_hot.wav"
      too_cold: "/usr/share/sounds/climate/alert_cold.wav"
      too_humid: "/usr/share/sounds/climate/alert_humid.wav"
      too_dry: "/usr/share/sounds/climate/alert_dry.wav"
  
  # Database configuration
  database:
    path: "/var/lib/luigi/climate.db"
    retention_days: 30      # Days to retain historical data
  
  # Logging configuration
  logging:
    level: "INFO"           # Options: DEBUG, INFO, WARNING, ERROR
    file: "/var/log/luigi/climate.log"
    max_bytes: 10485760     # 10 MB
    backup_count: 5         # Number of backup files
```

### Configuration Options

#### Sensor Selection

**DHT22 (Default):**
```yaml
sensor:
  type: "dht22"
  gpio_pin: 4  # Can be any free GPIO pin
```

**BME280:**
```yaml
sensor:
  type: "bme280"
  i2c_address: 0x76  # Usually 0x76, some modules use 0x77
```

#### Reading Intervals

- **reading_seconds**: How often to poll the sensor (min: 2 seconds for DHT22, faster for BME280)
- **logging_seconds**: How often to write to database (recommended: 300 = 5 minutes)

#### Temperature Thresholds

```yaml
thresholds:
  temperature:
    min_celsius: 15   # Alert when below this
    max_celsius: 30   # Alert when above this
```

Common ranges:
- **Home Comfort**: 18-24°C (64-75°F)
- **Server Room**: 18-27°C (64-80°F)
- **Wine Storage**: 10-15°C (50-59°F)

#### Humidity Thresholds

```yaml
thresholds:
  humidity:
    min_percent: 30  # Alert when too dry
    max_percent: 70  # Alert when too humid
```

Common ranges:
- **Home Comfort**: 30-60%
- **Museum/Archive**: 40-50%
- **Electronics**: 30-50%

#### Alert Cooldown

```yaml
alerts:
  cooldown_minutes: 30  # Wait 30 minutes between same alert type
```

Prevents alert spam. Each alert type (too_hot, too_cold, too_humid, too_dry) has independent cooldown.

### Applying Configuration Changes

After editing the configuration file:

```bash
# Restart the service to apply changes
sudo systemctl restart climate.service

# Verify new configuration
sudo journalctl -u climate.service -n 20
```

---

## Usage

### Service Management

```bash
# Start service
sudo systemctl start climate.service

# Stop service
sudo systemctl stop climate.service

# Restart service
sudo systemctl restart climate.service

# Check status
sudo systemctl status climate.service

# Enable auto-start on boot
sudo systemctl enable climate.service

# Disable auto-start
sudo systemctl disable climate.service
```

### Viewing Logs

```bash
# View recent logs
sudo journalctl -u climate.service -n 50

# Follow logs in real-time
sudo journalctl -u climate.service -f

# View logs with timestamps
sudo journalctl -u climate.service -o short-iso

# View logs from today
sudo journalctl -u climate.service --since today

# View logs from specific date
sudo journalctl -u climate.service --since "2024-01-01"
```

### Database Access

The climate data is stored in SQLite database at `/var/lib/luigi/climate.db`.

#### View Recent Readings

```bash
# Last 10 readings
sudo sqlite3 /var/lib/luigi/climate.db \
  "SELECT datetime(timestamp, 'localtime'), temperature_c, humidity, comfort_level 
   FROM climate_readings 
   ORDER BY timestamp DESC 
   LIMIT 10;"
```

#### View Statistics

```bash
# Today's min/max/avg
sudo sqlite3 /var/lib/luigi/climate.db \
  "SELECT 
     MIN(temperature_c) as min_temp,
     MAX(temperature_c) as max_temp,
     AVG(temperature_c) as avg_temp,
     MIN(humidity) as min_humidity,
     MAX(humidity) as max_humidity,
     AVG(humidity) as avg_humidity
   FROM climate_readings
   WHERE date(timestamp) = date('now', 'localtime');"
```

#### Export Data

```bash
# Export to CSV (last 7 days)
sudo sqlite3 -header -csv /var/lib/luigi/climate.db \
  "SELECT * FROM climate_readings 
   WHERE timestamp > datetime('now', '-7 days')" \
  > climate_data.csv

# Export to JSON
sudo sqlite3 /var/lib/luigi/climate.db \
  "SELECT json_group_array(
     json_object(
       'timestamp', timestamp,
       'temperature_c', temperature_c,
       'humidity', humidity
     )
   ) FROM climate_readings 
   WHERE timestamp > datetime('now', '-7 days')" \
  > climate_data.json
```

### Database Schema

```sql
CREATE TABLE climate_readings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    temperature_c REAL NOT NULL,
    temperature_f REAL NOT NULL,
    humidity REAL NOT NULL,
    dew_point_c REAL,
    heat_index_c REAL,
    comfort_level TEXT
);

CREATE INDEX idx_timestamp ON climate_readings(timestamp);
```

---

## Home Assistant Integration

The Climate module automatically integrates with Home Assistant via the `ha-mqtt` module.

### Prerequisites

1. **Install ha-mqtt module first**:
   ```bash
   sudo iot/ha-mqtt/setup.sh install
   ```

2. **Configure MQTT broker** in `/etc/luigi/iot/ha-mqtt/ha-mqtt.conf`

### Auto-Discovery

During Climate module installation, sensor descriptors are automatically installed and discovered:

- **climate_temperature** - Temperature sensor (°C)
- **climate_humidity** - Humidity sensor (%)

### Home Assistant Entities

After installation, these entities appear in Home Assistant:

```yaml
sensor.climate_temperature:
  unit_of_measurement: °C
  device_class: temperature
  state_class: measurement

sensor.climate_humidity:
  unit_of_measurement: %
  device_class: humidity
  state_class: measurement
```

### Using in Automations

**Example: Alert when temperature too high**

```yaml
automation:
  - alias: "Climate - High Temperature Alert"
    trigger:
      - platform: numeric_state
        entity_id: sensor.climate_temperature
        above: 30
    action:
      - service: notify.mobile_app
        data:
          message: "Temperature is {{ states('sensor.climate_temperature') }}°C!"
```

**Example: Control fan based on temperature**

```yaml
automation:
  - alias: "Climate - Auto Fan Control"
    trigger:
      - platform: numeric_state
        entity_id: sensor.climate_temperature
        above: 26
    action:
      - service: switch.turn_on
        target:
          entity_id: switch.desk_fan
```

### Manual MQTT Publishing

The module publishes data automatically, but you can test manually:

```bash
# Publish temperature
sudo /usr/local/bin/luigi-publish \
  --sensor climate_temperature \
  --value 22.5

# Publish humidity
sudo /usr/local/bin/luigi-publish \
  --sensor climate_humidity \
  --value 45.0
```

---

## Derived Metrics

### Dew Point

The temperature at which air becomes saturated and condensation begins. Calculated using the Magnus formula.

**Interpretation:**
- Below 10°C (50°F): Very dry, comfortable
- 10-15°C (50-60°F): Comfortable
- 15-20°C (60-68°F): Slightly uncomfortable
- 20-24°C (68-75°F): Uncomfortable, muggy
- Above 24°C (75°F): Oppressive

### Heat Index

Apparent temperature based on temperature and humidity. Only calculated when temperature exceeds 27°C (80°F). Uses NOAA's formula.

**Interpretation:**
- 27-32°C (80-90°F): Caution - fatigue possible
- 32-40°C (90-105°F): Extreme caution - heat cramps/exhaustion possible
- 40-54°C (105-130°F): Danger - heat exhaustion likely
- Above 54°C (130°F): Extreme danger - heat stroke imminent

### Comfort Level

Classification based on combined temperature and humidity:

- **comfortable**: Ideal conditions (18-26°C, 30-60% humidity)
- **too_hot**: Temperature above 26°C
- **too_cold**: Temperature below 18°C
- **too_humid**: Humidity above 60%
- **too_dry**: Humidity below 30%
- **too_hot_and_too_humid**: Both conditions exceeded
- **too_cold_and_too_dry**: Both conditions below minimums

---

## Alert Sounds

The module can play audio alerts when thresholds are exceeded. Alert sound files must be provided by the user.

### Setup Alert Sounds

1. **Create or obtain WAV files** for each alert type:
   - `alert_hot.wav` - Temperature too high
   - `alert_cold.wav` - Temperature too low
   - `alert_humid.wav` - Humidity too high
   - `alert_dry.wav` - Humidity too low

2. **Copy to sounds directory**:
   ```bash
   sudo cp alert_*.wav /usr/share/sounds/climate/
   ```

3. **Set permissions**:
   ```bash
   sudo chmod 644 /usr/share/sounds/climate/*.wav
   ```

### Generating Simple Beeps

If you don't have sound files, you can generate simple beeps using `sox`:

```bash
# Install sox
sudo apt-get install sox

# Generate alert sounds
cd /usr/share/sounds/climate
sudo sox -n alert_hot.wav synth 0.5 sine 880 fade 0 0.5 0.1
sudo sox -n alert_cold.wav synth 0.5 sine 440 fade 0 0.5 0.1
sudo sox -n alert_humid.wav synth 0.5 sine 660 fade 0 0.5 0.1
sudo sox -n alert_dry.wav synth 0.5 sine 550 fade 0 0.5 0.1
```

### Disabling Audio Alerts

To disable audio alerts but keep threshold logging:

```yaml
alerts:
  audio_enabled: false
```

Or disable all alerts:

```yaml
alerts:
  enabled: false
```

---

## Troubleshooting

### Service Won't Start

**Problem**: Service fails to start or crashes immediately.

**Solutions**:

1. **Check logs**:
   ```bash
   sudo journalctl -u climate.service -n 50
   ```

2. **Verify sensor connection**:
   - DHT22: Check wiring and pull-up resistor
   - BME280: Run `sudo i2cdetect -y 1` to verify sensor is detected

3. **Test sensor manually**:
   ```bash
   # DHT22
   python3 -c "import adafruit_dht; import board; sensor = adafruit_dht.DHT22(board.D4); print(sensor.temperature, sensor.humidity)"
   
   # BME280
   python3 -c "import board; import adafruit_bme280; i2c = board.I2C(); sensor = adafruit_bme280.Adafruit_BME280_I2C(i2c); print(sensor.temperature, sensor.humidity)"
   ```

4. **Verify Python dependencies**:
   ```bash
   pip3 list | grep adafruit
   ```

5. **Check permissions**:
   ```bash
   sudo chown -R root:root /usr/local/lib/climate
   sudo chmod -R 755 /usr/local/lib/climate
   ```

### Sensor Read Failures

**Problem**: "Failed to read sensor" errors in logs.

**DHT22 Solutions**:
- DHT22 can occasionally fail (normal behavior)
- Module retries up to 3 times automatically
- Ensure minimum 2 second interval between readings
- Check pull-up resistor (10kΩ required)
- Try a different GPIO pin if problems persist

**BME280 Solutions**:
- Verify I2C is enabled: `ls /dev/i2c-*`
- Check I2C address: `sudo i2cdetect -y 1`
- Some modules use 0x77 instead of 0x76
- Check wiring (SDA/SCL not reversed)

### No Data in Database

**Problem**: Database is empty or not updating.

**Solutions**:

1. **Check service is running**:
   ```bash
   sudo systemctl status climate.service
   ```

2. **Verify logging interval**:
   - Default is 300 seconds (5 minutes)
   - Check `/etc/luigi/sensors/climate/climate.conf`

3. **Check database permissions**:
   ```bash
   sudo ls -l /var/lib/luigi/climate.db
   sudo chmod 644 /var/lib/luigi/climate.db
   ```

4. **Verify database writes in logs**:
   ```bash
   sudo journalctl -u climate.service | grep "Logged reading"
   ```

### Alerts Not Working

**Problem**: Threshold exceeded but no audio alert.

**Solutions**:

1. **Verify alerts are enabled**:
   ```yaml
   alerts:
     enabled: true
     audio_enabled: true
   ```

2. **Check alert sound files exist**:
   ```bash
   ls -l /usr/share/sounds/climate/
   ```

3. **Test audio playback**:
   ```bash
   aplay /usr/share/sounds/climate/alert_hot.wav
   ```

4. **Check cooldown period**:
   - Alerts have 30-minute cooldown by default
   - Check logs for "ALERT:" messages
   - Wait for cooldown to expire

5. **Verify threshold configuration**:
   ```bash
   grep -A 10 "thresholds:" /etc/luigi/sensors/climate/climate.conf
   ```

### High CPU Usage

**Problem**: Service uses excessive CPU.

**Solutions**:

1. **Increase reading interval**:
   ```yaml
   intervals:
     reading_seconds: 60  # Increase from 30
   ```

2. **Check for sensor errors**:
   - Frequent sensor failures cause retries
   - View logs for patterns of errors

3. **Verify sensor type matches configuration**:
   - Don't configure BME280 when using DHT22
   - Check `/etc/luigi/sensors/climate/climate.conf`

### Mock Mode in Production

**Problem**: Logs show "Using mock GPIO" or "mock sensor" on actual hardware.

**Solutions**:

1. **Install GPIO library**:
   ```bash
   sudo apt-get install python3-lgpio
   pip3 install --break-system-packages adafruit-circuitpython-dht
   ```

2. **For BME280, ensure I2C enabled**:
   ```bash
   sudo raspi-config
   # Interface Options → I2C → Enable
   sudo reboot
   ```

3. **Check library installation**:
   ```bash
   python3 -c "import adafruit_dht; print('DHT22 library OK')"
   python3 -c "import adafruit_bme280; print('BME280 library OK')"
   ```

---

## Uninstallation

### Remove Module

```bash
# Uninstall climate module
sudo sensors/climate/setup.sh uninstall
```

This removes:
- Service file and disables service
- Module files from `/usr/local/lib/climate/`
- Alert sounds directory
- Home Assistant sensor descriptors

### Preserved After Uninstall

The following are **not** removed (manual cleanup required):

```bash
# Configuration (preserved for reinstall)
sudo rm -rf /etc/luigi/sensors/climate/

# Database (preserved for data retention)
sudo rm -f /var/lib/luigi/climate.db

# Logs (preserved for troubleshooting)
sudo rm -f /var/log/luigi/climate.log*
```

### Complete Removal

```bash
# Uninstall module
sudo sensors/climate/setup.sh uninstall

# Remove all data
sudo rm -rf /etc/luigi/sensors/climate
sudo rm -f /var/lib/luigi/climate.db
sudo rm -f /var/log/luigi/climate.log*

# Uninstall Python packages (optional)
pip3 uninstall -y adafruit-circuitpython-dht adafruit-circuitpython-bme280
```

---

## Development

### Testing Without Hardware

The module includes mock sensors for development:

```bash
# Run in development mode (uses mock sensors)
cd /home/runner/work/luigi/luigi/sensors/climate
python3 climate_module.py --config config/climate.conf.example
```

Mock sensors provide:
- Simulated temperature readings (20-25°C with variation)
- Simulated humidity readings (40-60% with variation)
- All calculations and database operations work normally

### Python Syntax Validation

```bash
cd sensors/climate
python3 -m py_compile climate_module.py
python3 -m py_compile sensors/*.py
python3 -m py_compile database/*.py
```

### Shell Script Validation

```bash
shellcheck sensors/climate/setup.sh
```

---

## Technical Details

### Architecture

```
┌─────────────────────────────────────────────────┐
│           ClimateModule (Main)                  │
│  ┌───────────────────────────────────────────┐  │
│  │  Reading Thread                           │  │
│  │  - Poll sensor every 30s                  │  │
│  │  - Calculate derived metrics              │  │
│  │  - Check thresholds                       │  │
│  │  - Trigger alerts                         │  │
│  │  - Publish to MQTT                        │  │
│  └───────────────────────────────────────────┘  │
│                                                  │
│  ┌───────────────────────────────────────────┐  │
│  │  Logging Thread                           │  │
│  │  - Log to database every 5 minutes        │  │
│  │  - Cleanup old data daily                 │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
           │                    │
           ▼                    ▼
    ┌────────────┐      ┌─────────────┐
    │   Sensor   │      │  Database   │
    │  (DHT22/   │      │  (SQLite)   │
    │   BME280)  │      └─────────────┘
    └────────────┘
```

### Threading Model

- **Main Thread**: Initialization and signal handling
- **Reading Thread**: Sensor polling and processing (daemon)
- **Logging Thread**: Database operations (daemon)

Threads are daemon threads that exit when main thread exits.

### Sensor Abstraction

All sensors implement `BaseSensor` interface:
- `read()` - Get current reading
- `is_available()` - Check sensor status
- `cleanup()` - Release resources

This allows easy addition of new sensor types.

### Database Retention

Old data is automatically cleaned up:
- Runs daily at 3:00 AM
- Deletes records older than `retention_days` (default: 30)
- Logs number of records deleted

### Alert Cooldown

Each alert type tracks last trigger time independently:
- `too_hot` - Temperature too high
- `too_cold` - Temperature too low
- `too_humid` - Humidity too high
- `too_dry` - Humidity too low

Cooldown prevents repeated alerts for the same condition.

---

## Performance

### Resource Usage

**Typical consumption on Raspberry Pi Zero W:**
- **CPU**: < 1% average (spikes to ~5% during sensor reads)
- **Memory**: ~25 MB RSS
- **Disk I/O**: Minimal (database writes every 5 minutes)
- **Network**: Minimal (MQTT publishes every 30 seconds)

### Database Growth

**Estimated database size:**
- Reading frequency: Every 5 minutes
- Readings per day: 288
- Readings per month: ~8,640
- Storage per reading: ~200 bytes
- Monthly growth: ~1.7 MB

With 30-day retention, database stabilizes around 50 MB.

---

## Security Considerations

### File Permissions

- Configuration: `640 root:root` (sensitive settings)
- Database: `644 root:root` (readable for exports)
- Logs: `644 root:root` (readable for troubleshooting)
- Service: Runs as root (required for GPIO access)

### Network Security

- MQTT credentials stored in ha-mqtt configuration
- No external network listeners
- Data published only to local MQTT broker

### Data Privacy

- All data stored locally
- No cloud uploads
- MQTT publishing optional (can be disabled)

---

## Future Enhancements

Potential improvements for future versions:

- [ ] Web dashboard with real-time charts
- [ ] REST API for programmatic access
- [ ] Support for multiple sensors in different locations
- [ ] Email/SMS alert notifications
- [ ] Predictive alerts based on trends
- [ ] Calibration offset configuration
- [ ] Integration with external weather APIs
- [ ] Air quality sensor support (PM2.5, CO2)
- [ ] Historical data visualization tools
- [ ] Export to cloud storage (Google Drive, Dropbox)

---

## Support

### Getting Help

1. **Check logs**: `sudo journalctl -u climate.service -f`
2. **Review troubleshooting section** above
3. **Verify hardware wiring** matches diagrams
4. **Test sensors manually** using Python commands
5. **Open GitHub issue** with logs and configuration

### Reporting Issues

When reporting issues, include:
- Raspberry Pi model
- Sensor type (DHT22 or BME280)
- Relevant logs (`journalctl -u climate.service -n 100`)
- Configuration file
- Output of `sudo sensors/climate/setup.sh status`

---

## License

MIT License - See main Luigi repository for details.

---

## Credits

**Author**: Luigi Project  
**Module Category**: Sensors  
**Dependencies**: iot/ha-mqtt (optional)

**Libraries Used:**
- Adafruit CircuitPython DHT (MIT License)
- Adafruit CircuitPython BME280 (MIT License)
- PyYAML (MIT License)

---

## See Also

- [Main Luigi README](../../README.md)
- [Home Assistant MQTT Integration](../../iot/ha-mqtt/README.md)
- [Module Schema Documentation](../../MODULE_SCHEMA.md)
- [Uninstall Guide](../../UNINSTALL_GUIDE.md)
