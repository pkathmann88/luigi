#!/usr/bin/env python3
"""
BME280 Sensor Driver

Implementation for BME280 temperature, humidity, and pressure sensor.
Uses I2C communication protocol.
"""

import time
import logging
from typing import Dict, Optional

from .base_sensor import BaseSensor

# Try to import BME280 sensor library
try:
    import board
    import adafruit_bme280.advanced as adafruit_bme280
    BME280_AVAILABLE = True
except ImportError:
    BME280_AVAILABLE = False
    print("WARNING: adafruit_bme280 library not available, using mock mode")


class MockBME280:
    """Mock BME280 sensor for development without hardware."""
    
    def __init__(self, i2c):
        self._read_count = 0
    
    @property
    def temperature(self):
        """Return mock temperature with slight variation."""
        import random
        base_temp = 22.5
        self._read_count += 1
        return base_temp + random.uniform(-1.5, 2.5)
    
    @property
    def humidity(self):
        """Return mock humidity with slight variation."""
        import random
        base_humidity = 48.0
        return base_humidity + random.uniform(-8.0, 12.0)
    
    @property
    def pressure(self):
        """Return mock pressure."""
        import random
        return 1013.25 + random.uniform(-10.0, 10.0)


class BME280Sensor(BaseSensor):
    """BME280 temperature, humidity, and pressure sensor driver."""
    
    def __init__(self, config: Dict):
        """
        Initialize BME280 sensor.
        
        Args:
            config: Dictionary containing:
                - i2c_address: I2C address (default: 0x76 or 0x77)
                - max_retries: Maximum number of read attempts (default: 3)
                - retry_delay: Delay between retries in seconds (default: 1)
        """
        super().__init__(config)
        
        self.i2c_address = config.get('i2c_address', 0x76)
        self.max_retries = config.get('max_retries', 3)
        self.retry_delay = config.get('retry_delay', 1)
        self.logger = logging.getLogger(__name__)
        
        # Initialize sensor
        if BME280_AVAILABLE:
            try:
                import busio
                i2c = busio.I2C(board.SCL, board.SDA)
                self.bme_device = adafruit_bme280.Adafruit_BME280_I2C(i2c, address=self.i2c_address)
                
                # Set oversampling for better accuracy
                self.bme_device.sea_level_pressure = 1013.25
                
                self.logger.info(f"BME280 sensor initialized on I2C address 0x{self.i2c_address:02X}")
            except Exception as e:
                self.logger.error(f"Failed to initialize BME280 sensor: {e}")
                self.logger.warning("Falling back to mock mode")
                self.bme_device = MockBME280(None)
        else:
            self.logger.warning("BME280 library not available, using mock sensor")
            self.bme_device = MockBME280(None)
    
    def read(self) -> Optional[Dict[str, float]]:
        """
        Read temperature and humidity from BME280 sensor.
        
        Returns:
            Dictionary with 'temperature' (°C), 'humidity' (%), and 'pressure' (hPa) keys,
            or None if all read attempts fail
        """
        for attempt in range(self.max_retries):
            try:
                temperature = self.bme_device.temperature
                humidity = self.bme_device.humidity
                pressure = self.bme_device.pressure
                
                # Validate readings
                if temperature is None or humidity is None:
                    raise ValueError("Sensor returned None values")
                
                if not (-40 <= temperature <= 85):
                    raise ValueError(f"Temperature {temperature}°C out of valid range (-40 to 85)")
                
                if not (0 <= humidity <= 100):
                    raise ValueError(f"Humidity {humidity}% out of valid range (0 to 100)")
                
                # Successful reading
                self._last_reading = {
                    'temperature': round(temperature, 1),
                    'humidity': round(humidity, 1),
                    'pressure': round(pressure, 1)
                }
                
                return self._last_reading
                
            except Exception as e:
                self.logger.error(f"BME280 read attempt {attempt + 1} failed: {e}")
                if attempt < self.max_retries - 1:
                    time.sleep(self.retry_delay)
                continue
        
        self.logger.warning(f"Failed to read BME280 after {self.max_retries} attempts")
        return None
    
    def is_available(self) -> bool:
        """
        Check if BME280 sensor is available.
        
        Returns:
            True if sensor can be read, False otherwise
        """
        reading = self.read()
        return reading is not None
    
    def cleanup(self):
        """Clean up BME280 sensor resources."""
        try:
            # BME280 doesn't require explicit cleanup
            self.logger.info("BME280 sensor cleaned up")
        except Exception as e:
            self.logger.error(f"Error cleaning up BME280: {e}")
