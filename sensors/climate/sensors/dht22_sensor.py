#!/usr/bin/env python3
"""
DHT22 Sensor Driver

Implementation for DHT22 temperature and humidity sensor.
Uses GPIO communication protocol with a single data pin.
"""

import time
import logging
from typing import Dict, Optional

from .base_sensor import BaseSensor

# Try to import DHT sensor library
try:
    import adafruit_dht
    import board
    DHT_AVAILABLE = True
except ImportError:
    DHT_AVAILABLE = False
    print("WARNING: adafruit_dht library not available, using mock mode")


class MockDHT:
    """Mock DHT sensor for development without hardware."""
    
    def __init__(self, pin):
        self.pin = pin
        self._read_count = 0
    
    @property
    def temperature(self):
        """Return mock temperature with slight variation."""
        import random
        base_temp = 22.0
        self._read_count += 1
        # Add some variation
        return base_temp + random.uniform(-2.0, 3.0)
    
    @property
    def humidity(self):
        """Return mock humidity with slight variation."""
        import random
        base_humidity = 50.0
        return base_humidity + random.uniform(-10.0, 15.0)
    
    def exit(self):
        """Mock cleanup."""
        pass


class DHT22Sensor(BaseSensor):
    """DHT22 temperature and humidity sensor driver."""
    
    def __init__(self, config: Dict):
        """
        Initialize DHT22 sensor.
        
        Args:
            config: Dictionary containing:
                - gpio_pin: GPIO pin number (BCM mode) where DHT22 data pin is connected
                - max_retries: Maximum number of read attempts (default: 3)
                - retry_delay: Delay between retries in seconds (default: 2)
        """
        super().__init__(config)
        
        self.gpio_pin = config.get('gpio_pin', 4)
        self.max_retries = config.get('max_retries', 3)
        self.retry_delay = config.get('retry_delay', 2)
        self.logger = logging.getLogger(__name__)
        
        # Initialize sensor
        if DHT_AVAILABLE:
            try:
                # Map GPIO pin number to board pin
                pin_map = {
                    4: board.D4,
                    17: board.D17,
                    27: board.D27,
                    22: board.D22,
                    # Add more pins as needed
                }
                
                board_pin = pin_map.get(self.gpio_pin)
                if board_pin is None:
                    self.logger.warning(f"GPIO pin {self.gpio_pin} not in pin map, attempting direct access")
                    # Try to get pin directly
                    board_pin = getattr(board, f'D{self.gpio_pin}', None)
                    if board_pin is None:
                        raise ValueError(f"Unsupported GPIO pin: {self.gpio_pin}")
                
                self.dht_device = adafruit_dht.DHT22(board_pin, use_pulseio=False)
                self.logger.info(f"DHT22 sensor initialized on GPIO pin {self.gpio_pin}")
            except Exception as e:
                self.logger.error(f"Failed to initialize DHT22 sensor: {e}")
                self.logger.warning("Falling back to mock mode")
                self.dht_device = MockDHT(self.gpio_pin)
        else:
            self.logger.warning("DHT library not available, using mock sensor")
            self.dht_device = MockDHT(self.gpio_pin)
    
    def read(self) -> Optional[Dict[str, float]]:
        """
        Read temperature and humidity from DHT22 sensor.
        
        Returns:
            Dictionary with 'temperature' (°C) and 'humidity' (%) keys,
            or None if all read attempts fail
        """
        for attempt in range(self.max_retries):
            try:
                temperature = self.dht_device.temperature
                humidity = self.dht_device.humidity
                
                # Validate readings
                if temperature is None or humidity is None:
                    raise ValueError("Sensor returned None values")
                
                if not (-40 <= temperature <= 80):
                    raise ValueError(f"Temperature {temperature}°C out of valid range (-40 to 80)")
                
                if not (0 <= humidity <= 100):
                    raise ValueError(f"Humidity {humidity}% out of valid range (0 to 100)")
                
                # Successful reading
                self._last_reading = {
                    'temperature': round(temperature, 1),
                    'humidity': round(humidity, 1)
                }
                
                return self._last_reading
                
            except RuntimeError as e:
                # DHT sensors can occasionally fail to read, this is normal
                self.logger.debug(f"DHT22 read attempt {attempt + 1} failed: {e}")
                if attempt < self.max_retries - 1:
                    time.sleep(self.retry_delay)
                continue
                
            except Exception as e:
                self.logger.error(f"Unexpected error reading DHT22: {e}")
                if attempt < self.max_retries - 1:
                    time.sleep(self.retry_delay)
                continue
        
        self.logger.warning(f"Failed to read DHT22 after {self.max_retries} attempts")
        return None
    
    def is_available(self) -> bool:
        """
        Check if DHT22 sensor is available.
        
        Returns:
            True if sensor can be read, False otherwise
        """
        reading = self.read()
        return reading is not None
    
    def cleanup(self):
        """Clean up DHT22 sensor resources."""
        try:
            if hasattr(self.dht_device, 'exit'):
                self.dht_device.exit()
            self.logger.info("DHT22 sensor cleaned up")
        except Exception as e:
            self.logger.error(f"Error cleaning up DHT22: {e}")
