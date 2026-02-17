#!/usr/bin/env python3
"""
Base Sensor Interface

Abstract base class defining the interface that all climate sensors must implement.
This allows for easy addition of new sensor types while maintaining a consistent API.
"""

from abc import ABC, abstractmethod
from typing import Dict, Optional


class BaseSensor(ABC):
    """Abstract base class for all climate sensors."""
    
    def __init__(self, config: Dict):
        """
        Initialize the sensor with configuration.
        
        Args:
            config: Dictionary containing sensor configuration
        """
        self.config = config
        self._last_reading = None
    
    @abstractmethod
    def read(self) -> Optional[Dict[str, float]]:
        """
        Read current temperature and humidity from the sensor.
        
        Returns:
            Dictionary with keys:
                - 'temperature': Temperature in Celsius
                - 'humidity': Relative humidity percentage (0-100)
            Returns None if reading fails
        """
        pass
    
    @abstractmethod
    def is_available(self) -> bool:
        """
        Check if sensor is responding and available.
        
        Returns:
            True if sensor is available, False otherwise
        """
        pass
    
    @property
    def last_reading(self) -> Optional[Dict[str, float]]:
        """Get the last successful reading."""
        return self._last_reading
    
    @abstractmethod
    def cleanup(self):
        """Clean up sensor resources."""
        pass
