#!/usr/bin/env python3
"""
Climate Monitoring Module

Main module for temperature and humidity monitoring with DHT22/BME280 sensors.
Features include real-time monitoring, database logging, threshold alerts,
and Home Assistant MQTT integration.

Hardware Requirements:
- Raspberry Pi Zero W (or compatible)
- DHT22 sensor on GPIO 4 (configurable) OR BME280 sensor on I2C
- Audio output device for alerts

Author: Luigi Project
License: MIT
"""

import sys
import os
import time
import signal
import logging
import yaml
import math
import subprocess
import threading
from datetime import datetime, timedelta
from pathlib import Path
from logging.handlers import RotatingFileHandler
from typing import Dict, Optional

# Import local modules
from sensors.dht22_sensor import DHT22Sensor
from sensors.bme280_sensor import BME280Sensor
from sensors.base_sensor import BaseSensor
from database.climate_db import ClimateDatabase


# ============================================================================
# Configuration
# ============================================================================

class Config:
    """Load application configuration from YAML file with fallback to defaults."""
    
    # Default configuration values
    DEFAULT_CONFIG = {
        'climate': {
            'enabled': True,
            'sensor': {
                'type': 'dht22',
                'gpio_pin': 4,
                'i2c_address': 0x76
            },
            'intervals': {
                'reading_seconds': 30,
                'logging_seconds': 300
            },
            'thresholds': {
                'temperature': {
                    'min_celsius': 15,
                    'max_celsius': 30,
                    'unit_display': 'celsius'
                },
                'humidity': {
                    'min_percent': 30,
                    'max_percent': 70
                }
            },
            'alerts': {
                'enabled': True,
                'cooldown_minutes': 30,
                'audio_enabled': True,
                'sounds': {
                    'too_hot': '/usr/share/sounds/climate/alert_hot.wav',
                    'too_cold': '/usr/share/sounds/climate/alert_cold.wav',
                    'too_humid': '/usr/share/sounds/climate/alert_humid.wav',
                    'too_dry': '/usr/share/sounds/climate/alert_dry.wav'
                }
            },
            'database': {
                'path': '/var/lib/luigi/climate.db',
                'retention_days': 30
            },
            'logging': {
                'level': 'INFO',
                'file': '/var/log/luigi/climate.log',
                'max_bytes': 10485760,  # 10MB
                'backup_count': 5
            }
        }
    }
    
    def __init__(self, config_path: str = "/etc/luigi/sensors/climate/climate.conf"):
        """
        Initialize configuration from file or defaults.
        
        Args:
            config_path: Path to YAML configuration file
        """
        self.config_path = config_path
        self.config = self._load_config()
    
    def _load_config(self) -> Dict:
        """Load configuration from file or use defaults."""
        if Path(self.config_path).exists():
            try:
                with open(self.config_path, 'r') as f:
                    loaded_config = yaml.safe_load(f)
                    # Merge with defaults (defaults provide fallback)
                    return self._merge_config(self.DEFAULT_CONFIG.copy(), loaded_config)
            except Exception as e:
                print(f"Warning: Failed to load config from {self.config_path}: {e}")
                print("Using default configuration")
        
        return self.DEFAULT_CONFIG.copy()
    
    def _merge_config(self, default: Dict, override: Dict) -> Dict:
        """Recursively merge override config into default config."""
        if override is None:
            return default
        
        for key, value in override.items():
            if key in default and isinstance(default[key], dict) and isinstance(value, dict):
                default[key] = self._merge_config(default[key], value)
            else:
                default[key] = value
        
        return default
    
    def get(self, *keys, default=None):
        """Get nested configuration value."""
        value = self.config
        for key in keys:
            if isinstance(value, dict) and key in value:
                value = value[key]
            else:
                return default
        return value
    
    @property
    def climate(self) -> Dict:
        """Get climate configuration section."""
        return self.config.get('climate', {})


# ============================================================================
# Climate Calculations
# ============================================================================

class ClimateCalculations:
    """Meteorological calculations for climate data."""
    
    @staticmethod
    def celsius_to_fahrenheit(celsius: float) -> float:
        """Convert Celsius to Fahrenheit."""
        return (celsius * 9/5) + 32
    
    @staticmethod
    def fahrenheit_to_celsius(fahrenheit: float) -> float:
        """Convert Fahrenheit to Celsius."""
        return (fahrenheit - 32) * 5/9
    
    @staticmethod
    def calculate_dew_point(temperature_c: float, humidity: float) -> float:
        """
        Calculate dew point temperature using Magnus formula.
        
        Args:
            temperature_c: Temperature in Celsius
            humidity: Relative humidity percentage (0-100)
        
        Returns:
            Dew point temperature in Celsius
        """
        # Magnus formula constants
        a = 17.27
        b = 237.7
        
        # Calculate intermediate value
        alpha = ((a * temperature_c) / (b + temperature_c)) + math.log(humidity / 100.0)
        
        # Calculate dew point
        dew_point = (b * alpha) / (a - alpha)
        
        return round(dew_point, 1)
    
    @staticmethod
    def calculate_heat_index(temperature_c: float, humidity: float) -> Optional[float]:
        """
        Calculate heat index using NOAA formula.
        Only applicable when temperature is above 27°C (80°F).
        
        Args:
            temperature_c: Temperature in Celsius
            humidity: Relative humidity percentage (0-100)
        
        Returns:
            Heat index in Celsius, or None if not applicable
        """
        # Convert to Fahrenheit for calculation
        temp_f = ClimateCalculations.celsius_to_fahrenheit(temperature_c)
        
        # Heat index only applies above 80°F
        if temp_f < 80:
            return None
        
        # NOAA Heat Index formula coefficients
        c1 = -42.379
        c2 = 2.04901523
        c3 = 10.14333127
        c4 = -0.22475541
        c5 = -0.00683783
        c6 = -0.05481717
        c7 = 0.00122874
        c8 = 0.00085282
        c9 = -0.00000199
        
        # Calculate heat index in Fahrenheit
        hi_f = (c1 + (c2 * temp_f) + (c3 * humidity) + 
                (c4 * temp_f * humidity) + (c5 * temp_f * temp_f) + 
                (c6 * humidity * humidity) + (c7 * temp_f * temp_f * humidity) + 
                (c8 * temp_f * humidity * humidity) + 
                (c9 * temp_f * temp_f * humidity * humidity))
        
        # Convert back to Celsius
        hi_c = ClimateCalculations.fahrenheit_to_celsius(hi_f)
        
        return round(hi_c, 1)
    
    @staticmethod
    def calculate_comfort_level(temperature_c: float, humidity: float) -> str:
        """
        Calculate comfort level based on temperature and humidity.
        
        Args:
            temperature_c: Temperature in Celsius
            humidity: Relative humidity percentage (0-100)
        
        Returns:
            Comfort level string: 'comfortable', 'too_hot', 'too_cold', 
            'too_humid', 'too_dry', or combinations
        """
        issues = []
        
        # Temperature thresholds
        if temperature_c < 18:
            issues.append('too_cold')
        elif temperature_c > 26:
            issues.append('too_hot')
        
        # Humidity thresholds
        if humidity < 30:
            issues.append('too_dry')
        elif humidity > 60:
            issues.append('too_humid')
        
        # Return result
        if not issues:
            return 'comfortable'
        elif len(issues) == 1:
            return issues[0]
        else:
            return '_and_'.join(issues)


# ============================================================================
# Main Climate Module
# ============================================================================

class ClimateModule:
    """Main climate monitoring module."""
    
    def __init__(self, config_path: str = "/etc/luigi/sensors/climate/climate.conf"):
        """
        Initialize climate module.
        
        Args:
            config_path: Path to configuration file
        """
        # Load configuration
        self.config = Config(config_path)
        
        # Setup logging
        self._setup_logging()
        
        # Initialize components
        self.sensor = None
        self.database = None
        self.running = False
        self.reading_thread = None
        self.logging_thread = None
        
        # Alert tracking
        self.last_alert_time = {}
        self.last_alert_lock = threading.Lock()
        
        # Latest reading cache
        self.latest_reading = None
        self.reading_lock = threading.Lock()
        
        # Setup signal handlers
        signal.signal(signal.SIGTERM, self._signal_handler)
        signal.signal(signal.SIGINT, self._signal_handler)
        
        self.logger.info("Climate module initialized")
    
    def _setup_logging(self):
        """Configure logging with rotation."""
        log_config = self.config.get('climate', 'logging')
        log_file = log_config.get('file', '/var/log/luigi/climate.log')
        log_level = log_config.get('level', 'INFO')
        max_bytes = log_config.get('max_bytes', 10485760)
        backup_count = log_config.get('backup_count', 5)
        
        # Ensure log directory exists
        log_dir = Path(log_file).parent
        log_dir.mkdir(parents=True, exist_ok=True)
        
        # Configure root logger
        self.logger = logging.getLogger()
        self.logger.setLevel(getattr(logging, log_level.upper(), logging.INFO))
        
        # Remove existing handlers
        self.logger.handlers = []
        
        # File handler with rotation
        file_handler = RotatingFileHandler(
            log_file,
            maxBytes=max_bytes,
            backupCount=backup_count
        )
        file_handler.setFormatter(logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        ))
        self.logger.addHandler(file_handler)
        
        # Console handler
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(logging.Formatter(
            '%(asctime)s - %(levelname)s - %(message)s'
        ))
        self.logger.addHandler(console_handler)
    
    def _signal_handler(self, signum, frame):
        """Handle shutdown signals."""
        self.logger.info(f"Received signal {signum}, shutting down...")
        self.stop()
        sys.exit(0)
    
    def _initialize_sensor(self) -> bool:
        """Initialize the configured sensor."""
        sensor_config = self.config.get('climate', 'sensor')
        sensor_type = sensor_config.get('type', 'dht22').lower()
        
        try:
            if sensor_type == 'dht22':
                self.logger.info("Initializing DHT22 sensor...")
                self.sensor = DHT22Sensor({
                    'gpio_pin': sensor_config.get('gpio_pin', 4),
                    'max_retries': 3,
                    'retry_delay': 2
                })
            elif sensor_type == 'bme280':
                self.logger.info("Initializing BME280 sensor...")
                self.sensor = BME280Sensor({
                    'i2c_address': sensor_config.get('i2c_address', 0x76),
                    'max_retries': 3,
                    'retry_delay': 1
                })
            else:
                self.logger.error(f"Unknown sensor type: {sensor_type}")
                return False
            
            # Test sensor
            if self.sensor.is_available():
                self.logger.info(f"{sensor_type.upper()} sensor initialized successfully")
                return True
            else:
                self.logger.error(f"{sensor_type.upper()} sensor not responding")
                return False
                
        except Exception as e:
            self.logger.error(f"Failed to initialize sensor: {e}")
            return False
    
    def _initialize_database(self) -> bool:
        """Initialize the database."""
        try:
            db_config = self.config.get('climate', 'database')
            db_path = db_config.get('path', '/var/lib/luigi/climate.db')
            retention_days = db_config.get('retention_days', 30)
            
            self.logger.info(f"Initializing database at {db_path}...")
            self.database = ClimateDatabase(db_path, retention_days)
            self.logger.info("Database initialized successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to initialize database: {e}")
            return False
    
    def _process_reading(self, reading: Dict[str, float]):
        """
        Process a sensor reading: calculate derived metrics, log to database,
        check thresholds, and publish to MQTT.
        
        Args:
            reading: Dictionary with 'temperature' and 'humidity' keys
        """
        try:
            temp_c = reading['temperature']
            humidity = reading['humidity']
            
            # Calculate derived metrics
            temp_f = ClimateCalculations.celsius_to_fahrenheit(temp_c)
            dew_point = ClimateCalculations.calculate_dew_point(temp_c, humidity)
            heat_index = ClimateCalculations.calculate_heat_index(temp_c, humidity)
            comfort_level = ClimateCalculations.calculate_comfort_level(temp_c, humidity)
            
            # Store latest reading
            with self.reading_lock:
                self.latest_reading = {
                    'timestamp': datetime.now().isoformat(),
                    'temperature_c': temp_c,
                    'temperature_f': temp_f,
                    'humidity': humidity,
                    'dew_point_c': dew_point,
                    'heat_index_c': heat_index,
                    'comfort_level': comfort_level
                }
            
            # Log to database (every logging_seconds interval)
            # This is handled by the logging thread
            
            # Check thresholds and trigger alerts
            self._check_thresholds(temp_c, humidity, comfort_level)
            
            # Publish to Home Assistant via MQTT
            self._publish_to_mqtt(temp_c, humidity)
            
        except Exception as e:
            self.logger.error(f"Error processing reading: {e}")
    
    def _check_thresholds(self, temperature_c: float, humidity: float, comfort_level: str):
        """Check if readings exceed thresholds and trigger alerts."""
        alert_config = self.config.get('climate', 'alerts')
        
        if not alert_config.get('enabled', True):
            return
        
        temp_thresholds = self.config.get('climate', 'thresholds', 'temperature')
        humidity_thresholds = self.config.get('climate', 'thresholds', 'humidity')
        
        min_temp = temp_thresholds.get('min_celsius', 15)
        max_temp = temp_thresholds.get('max_celsius', 30)
        min_humidity = humidity_thresholds.get('min_percent', 30)
        max_humidity = humidity_thresholds.get('max_percent', 70)
        
        # Check each condition
        if temperature_c < min_temp:
            self._trigger_alert('too_cold', f"Temperature too low: {temperature_c}°C")
        elif temperature_c > max_temp:
            self._trigger_alert('too_hot', f"Temperature too high: {temperature_c}°C")
        
        if humidity < min_humidity:
            self._trigger_alert('too_dry', f"Humidity too low: {humidity}%")
        elif humidity > max_humidity:
            self._trigger_alert('too_humid', f"Humidity too high: {humidity}%")
    
    def _trigger_alert(self, alert_type: str, message: str):
        """
        Trigger an alert with cooldown mechanism.
        
        Args:
            alert_type: Type of alert ('too_hot', 'too_cold', 'too_humid', 'too_dry')
            message: Alert message for logging
        """
        alert_config = self.config.get('climate', 'alerts')
        cooldown_minutes = alert_config.get('cooldown_minutes', 30)
        
        # Check cooldown
        with self.last_alert_lock:
            last_time = self.last_alert_time.get(alert_type)
            now = datetime.now()
            
            if last_time:
                time_since_last = (now - last_time).total_seconds() / 60
                if time_since_last < cooldown_minutes:
                    return  # Still in cooldown period
            
            # Update last alert time
            self.last_alert_time[alert_type] = now
        
        # Log alert
        self.logger.warning(f"ALERT: {message}")
        
        # Play audio alert
        if alert_config.get('audio_enabled', True):
            self._play_alert_sound(alert_type)
    
    def _play_alert_sound(self, alert_type: str):
        """Play audio alert for the given alert type."""
        try:
            alert_config = self.config.get('climate', 'alerts')
            sounds = alert_config.get('sounds', {})
            sound_file = sounds.get(alert_type)
            
            if sound_file and Path(sound_file).exists():
                subprocess.run(['aplay', '-q', sound_file], 
                             timeout=10,
                             check=False)
                self.logger.debug(f"Played alert sound: {sound_file}")
            else:
                self.logger.debug(f"Alert sound file not found: {sound_file}")
                
        except Exception as e:
            self.logger.error(f"Failed to play alert sound: {e}")
    
    def _publish_to_mqtt(self, temperature_c: float, humidity: float):
        """Publish readings to Home Assistant via luigi-publish."""
        try:
            # Publish temperature
            subprocess.run([
                '/usr/local/bin/luigi-publish',
                '--sensor', 'climate_temperature',
                '--value', str(temperature_c)
            ], timeout=5, check=False, capture_output=True)
            
            # Publish humidity
            subprocess.run([
                '/usr/local/bin/luigi-publish',
                '--sensor', 'climate_humidity',
                '--value', str(humidity)
            ], timeout=5, check=False, capture_output=True)
            
        except Exception as e:
            # Don't crash on MQTT errors, just log
            self.logger.debug(f"MQTT publish failed (non-critical): {e}")
    
    def _reading_loop(self):
        """Main loop for reading sensor data."""
        intervals_config = self.config.get('climate', 'intervals')
        reading_interval = intervals_config.get('reading_seconds', 30)
        
        self.logger.info(f"Starting reading loop (interval: {reading_interval}s)")
        
        while self.running:
            try:
                # Read sensor
                reading = self.sensor.read()
                
                if reading:
                    self.logger.debug(f"Reading: {reading['temperature']}°C, {reading['humidity']}%")
                    self._process_reading(reading)
                else:
                    self.logger.warning("Failed to read sensor")
                
                # Sleep for interval
                time.sleep(reading_interval)
                
            except Exception as e:
                self.logger.error(f"Error in reading loop: {e}")
                time.sleep(reading_interval)
    
    def _logging_loop(self):
        """Loop for logging readings to database."""
        intervals_config = self.config.get('climate', 'intervals')
        logging_interval = intervals_config.get('logging_seconds', 300)
        
        self.logger.info(f"Starting logging loop (interval: {logging_interval}s)")
        
        while self.running:
            try:
                time.sleep(logging_interval)
                
                # Get latest reading
                with self.reading_lock:
                    reading = self.latest_reading
                
                if reading:
                    # Log to database
                    success = self.database.log_reading(
                        temperature_c=reading['temperature_c'],
                        temperature_f=reading['temperature_f'],
                        humidity=reading['humidity'],
                        dew_point_c=reading.get('dew_point_c'),
                        heat_index_c=reading.get('heat_index_c'),
                        comfort_level=reading.get('comfort_level')
                    )
                    
                    if success:
                        self.logger.debug("Logged reading to database")
                    else:
                        self.logger.warning("Failed to log reading to database")
                
                # Periodic cleanup of old data (once per day check)
                if datetime.now().hour == 3 and datetime.now().minute < 5:
                    deleted = self.database.cleanup_old_data()
                    if deleted > 0:
                        self.logger.info(f"Cleaned up {deleted} old database records")
                
            except Exception as e:
                self.logger.error(f"Error in logging loop: {e}")
    
    def start(self):
        """Start the climate monitoring module."""
        if self.running:
            self.logger.warning("Module already running")
            return
        
        # Initialize components
        if not self._initialize_sensor():
            self.logger.error("Failed to initialize sensor, exiting")
            sys.exit(1)
        
        if not self._initialize_database():
            self.logger.error("Failed to initialize database, exiting")
            sys.exit(1)
        
        # Start monitoring threads
        self.running = True
        
        self.reading_thread = threading.Thread(target=self._reading_loop, daemon=True)
        self.reading_thread.start()
        
        self.logging_thread = threading.Thread(target=self._logging_loop, daemon=True)
        self.logging_thread.start()
        
        self.logger.info("Climate module started successfully")
        
        # Main loop - just keep alive
        try:
            while self.running:
                time.sleep(1)
        except KeyboardInterrupt:
            self.logger.info("Keyboard interrupt received")
            self.stop()
    
    def stop(self):
        """Stop the climate monitoring module."""
        if not self.running:
            return
        
        self.logger.info("Stopping climate module...")
        self.running = False
        
        # Wait for threads to finish
        if self.reading_thread and self.reading_thread.is_alive():
            self.reading_thread.join(timeout=5)
        
        if self.logging_thread and self.logging_thread.is_alive():
            self.logging_thread.join(timeout=5)
        
        # Cleanup sensor
        if self.sensor:
            self.sensor.cleanup()
        
        # Close database
        if self.database:
            self.database.close()
        
        self.logger.info("Climate module stopped")


# ============================================================================
# Main Entry Point
# ============================================================================

def main():
    """Main entry point for the climate module."""
    # Parse command line arguments for config path
    import argparse
    
    parser = argparse.ArgumentParser(description='Luigi Climate Monitoring Module')
    parser.add_argument('--config', default='/etc/luigi/sensors/climate/climate.conf',
                       help='Path to configuration file')
    args = parser.parse_args()
    
    # Create and start module
    module = ClimateModule(config_path=args.config)
    module.start()


if __name__ == '__main__':
    main()

