#!/usr/bin/env python3
"""
Mario Motion Detection Module

A motion detection system that plays random Mario-themed sound effects
when motion is detected via a PIR sensor connected to GPIO23.

Features:
- PIR motion sensor integration
- Random sound playback on motion detection
- 30-minute cooldown between triggers
- Graceful shutdown handling
- Structured logging with rotation

Shutdown Methods:
- **SIGTERM signal** (recommended): Graceful shutdown via signal handler
- **SIGINT signal** (Ctrl+C): Interactive shutdown

Hardware Requirements:
- Raspberry Pi Zero W (or compatible)
- PIR motion sensor on GPIO23
- Audio output device

Author: Luigi Project
License: MIT
"""

import sys
import os
import time
import signal
import logging
import random
import subprocess
import configparser
from pathlib import Path
from logging.handlers import RotatingFileHandler

# Try to import RPi.GPIO, fall back to mock for development
try:
    import RPi.GPIO as GPIO
    MOCK_MODE = False
except (ImportError, RuntimeError):
    # Mock GPIO for development/testing without hardware
    class MockGPIO:
        """Mock RPi.GPIO for development without Raspberry Pi hardware."""
        BCM = "BCM"
        IN = "IN"
        RISING = "RISING"
        
        @classmethod
        def setmode(cls, mode):
            print(f"[MOCK] GPIO mode set to {mode}")
        
        @classmethod
        def setup(cls, pin, direction):
            print(f"[MOCK] Pin {pin} configured as {direction}")
        
        @classmethod
        def add_event_detect(cls, pin, edge, callback=None):
            print(f"[MOCK] Event detect added on pin {pin}")
        
        @classmethod
        def remove_event_detect(cls, pin):
            print(f"[MOCK] Event detect removed from pin {pin}")
        
        @classmethod
        def cleanup(cls):
            print("[MOCK] GPIO cleaned up")
    
    GPIO = MockGPIO
    MOCK_MODE = True
    print("WARNING: Using mock GPIO (no hardware available)")


# ============================================================================
# Configuration
# ============================================================================

class Config:
    """Load application configuration from file with fallback to defaults."""
    
    # Default configuration values
    DEFAULT_GPIO_MODE = GPIO.BCM
    DEFAULT_SENSOR_PIN = 23
    DEFAULT_SOUND_DIR = "/usr/share/sounds/mario/"
    DEFAULT_TIMER_FILE = "/tmp/mario_timer"
    DEFAULT_LOG_FILE = "/var/log/motion.log"
    DEFAULT_COOLDOWN_SECONDS = 1800  # 30 minutes
    DEFAULT_MAIN_LOOP_SLEEP = 100    # seconds
    DEFAULT_LOG_LEVEL = "INFO"
    DEFAULT_LOG_MAX_BYTES = 10 * 1024 * 1024  # 10MB
    DEFAULT_LOG_BACKUP_COUNT = 5
    
    def __init__(self, module_path="motion-detection/mario"):
        """
        Initialize configuration from file or defaults.
        
        Args:
            module_path: Module path matching repository structure
        """
        self.module_path = module_path
        self.config_file = f"/etc/luigi/{module_path}/mario.conf"
        self._load_config()
    
    def _load_config(self):
        """Load configuration from INI file or use defaults."""
        parser = configparser.ConfigParser()
        
        # Set GPIO mode first (not configurable)
        self.GPIO_MODE = self.DEFAULT_GPIO_MODE
        
        if os.path.exists(self.config_file):
            try:
                parser.read(self.config_file)
                
                # GPIO Settings
                self.SENSOR_PIN = parser.getint('GPIO', 'SENSOR_PIN', 
                                                fallback=self.DEFAULT_SENSOR_PIN)
                
                # Timing Settings
                self.COOLDOWN_SECONDS = parser.getint('Timing', 'COOLDOWN_SECONDS',
                                                      fallback=self.DEFAULT_COOLDOWN_SECONDS)
                self.MAIN_LOOP_SLEEP = parser.getint('Timing', 'MAIN_LOOP_SLEEP',
                                                     fallback=self.DEFAULT_MAIN_LOOP_SLEEP)
                
                # File Paths
                self.SOUND_DIR = parser.get('Files', 'SOUND_DIR',
                                           fallback=self.DEFAULT_SOUND_DIR)
                self.TIMER_FILE = parser.get('Files', 'TIMER_FILE',
                                             fallback=self.DEFAULT_TIMER_FILE)
                self.LOG_FILE = parser.get('Files', 'LOG_FILE',
                                           fallback=self.DEFAULT_LOG_FILE)
                
                # Logging Settings
                log_level_str = parser.get('Logging', 'LOG_LEVEL',
                                          fallback=self.DEFAULT_LOG_LEVEL)
                self.LOG_LEVEL = self._parse_log_level(log_level_str)
                self.LOG_MAX_BYTES = parser.getint('Logging', 'LOG_MAX_BYTES',
                                                   fallback=self.DEFAULT_LOG_MAX_BYTES)
                self.LOG_BACKUP_COUNT = parser.getint('Logging', 'LOG_BACKUP_COUNT',
                                                      fallback=self.DEFAULT_LOG_BACKUP_COUNT)
                
                # Note: Using print here as logging is not yet configured
                print(f"Configuration loaded from {self.config_file}")
                
            except (configparser.Error, ValueError, KeyError) as e:
                print(f"Warning: Error reading config file: {e}")
                print("Using default configuration")
                self._use_defaults()
        else:
            print(f"Config file not found: {self.config_file}")
            print("Using default configuration")
            self._use_defaults()
    
    def _use_defaults(self):
        """Set all configuration values to defaults."""
        self.SENSOR_PIN = self.DEFAULT_SENSOR_PIN
        self.SOUND_DIR = self.DEFAULT_SOUND_DIR
        self.TIMER_FILE = self.DEFAULT_TIMER_FILE
        self.LOG_FILE = self.DEFAULT_LOG_FILE
        self.COOLDOWN_SECONDS = self.DEFAULT_COOLDOWN_SECONDS
        self.MAIN_LOOP_SLEEP = self.DEFAULT_MAIN_LOOP_SLEEP
        self.LOG_LEVEL = self._parse_log_level(self.DEFAULT_LOG_LEVEL)
        self.LOG_MAX_BYTES = self.DEFAULT_LOG_MAX_BYTES
        self.LOG_BACKUP_COUNT = self.DEFAULT_LOG_BACKUP_COUNT
    
    def _parse_log_level(self, level_str):
        """
        Convert log level string to logging constant.
        
        Args:
            level_str: String representation (DEBUG, INFO, WARNING, ERROR, CRITICAL)
                       or any other type (will be treated as invalid)
            
        Returns:
            logging level constant (defaults to INFO for invalid or non-string values)
        """
        # Handle non-string values
        if not isinstance(level_str, str):
            return logging.INFO
        
        level_map = {
            'DEBUG': logging.DEBUG,
            'INFO': logging.INFO,
            'WARNING': logging.WARNING,
            'ERROR': logging.ERROR,
            'CRITICAL': logging.CRITICAL
        }
        return level_map.get(level_str.upper(), logging.INFO)


# ============================================================================
# Logging Setup
# ============================================================================

def setup_logging(config):
    """
    Configure application logging with console and file handlers.
    
    Args:
        config: Config instance with logging settings
    """
    logger = logging.getLogger()
    logger.setLevel(config.LOG_LEVEL)
    
    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.INFO)
    console_format = logging.Formatter('%(levelname)s: %(message)s')
    console_handler.setFormatter(console_format)
    logger.addHandler(console_handler)
    
    # File handler with rotation
    try:
        Path(config.LOG_FILE).parent.mkdir(parents=True, exist_ok=True)
        file_handler = RotatingFileHandler(
            config.LOG_FILE,
            maxBytes=config.LOG_MAX_BYTES,
            backupCount=config.LOG_BACKUP_COUNT
        )
        file_handler.setLevel(config.LOG_LEVEL)
        file_format = logging.Formatter(
            '%(asctime)s - %(levelname)s - %(message)s'
        )
        file_handler.setFormatter(file_format)
        logger.addHandler(file_handler)
        logging.info(f"Logging to file: {config.LOG_FILE}")
    except PermissionError:
        logging.warning(f"Cannot write to {config.LOG_FILE}, using console only")
    
    return logger


# ============================================================================
# Utility Functions
# ============================================================================

def safe_read_file(filepath, default=None):
    """
    Read file content safely with error handling.
    
    Args:
        filepath: Path to file
        default: Default value if file doesn't exist
        
    Returns:
        File content as string, or default value
    """
    try:
        with open(filepath, 'r') as f:
            return f.read().strip()
    except FileNotFoundError:
        logging.debug(f"File not found: {filepath}")
        return default
    except IOError as e:
        logging.error(f"Failed to read {filepath}: {e}")
        return default


def safe_write_file(filepath, content):
    """
    Write file content safely with error handling.
    
    Args:
        filepath: Path to file
        content: Content to write
        
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        Path(filepath).parent.mkdir(parents=True, exist_ok=True)
        with open(filepath, 'w') as f:
            f.write(str(content))
        return True
    except IOError as e:
        logging.error(f"Failed to write {filepath}: {e}")
        return False


def publish_sensor_value(sensor_id, value, is_binary=False, unit=None):
    """
    Publish sensor value to Home Assistant via MQTT.
    
    Optional integration with ha-mqtt module. Module works standalone
    if ha-mqtt is not installed.
    
    Args:
        sensor_id: Unique sensor identifier (e.g., 'mario_motion')
        value: Sensor value (e.g., 'ON', 'OFF', '23.5')
        is_binary: True for binary sensors (motion, door), False for measurements
        unit: Unit of measurement for numeric sensors (e.g., '°C', '%', 'lux')
        
    Returns:
        bool: True if published successfully, False otherwise
    """
    try:
        cmd = ['/usr/local/bin/luigi-publish', '--sensor', sensor_id, '--value', str(value)]
        
        if is_binary:
            cmd.append('--binary')
        
        if unit:
            cmd.extend(['--unit', unit])
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            timeout=5,
            check=True
        )
        
        logging.debug(f"Published {sensor_id}={value} to MQTT")
        return True
        
    except subprocess.TimeoutExpired:
        logging.warning(f"MQTT publish timeout for {sensor_id}")
        return False
        
    except subprocess.CalledProcessError as e:
        stderr_msg = e.stderr.decode('utf-8', errors='replace') if e.stderr else 'no output'
        logging.warning(f"MQTT publish failed for {sensor_id}: {stderr_msg}")
        return False
        
    except FileNotFoundError:
        # ha-mqtt not installed - this is OK, module should work standalone
        logging.debug("ha-mqtt not available, skipping MQTT publish")
        return False
        
    except Exception as e:
        logging.error(f"Unexpected error publishing to MQTT: {e}")
        return False


# ============================================================================
# Hardware Abstraction Layer
# ============================================================================

class GPIOManager:
    """Manages GPIO initialization and cleanup."""
    
    def __init__(self, config):
        """
        Initialize GPIO manager.
        
        Args:
            config: Config instance with GPIO settings
        """
        self.config = config
        self.initialized = False
    
    def initialize(self):
        """Initialize GPIO mode."""
        try:
            GPIO.setmode(self.config.GPIO_MODE)
            self.initialized = True
            logging.info("GPIO initialized successfully")
        except RuntimeError as e:
            logging.error(f"Failed to initialize GPIO: {e}")
            raise
    
    def cleanup(self):
        """Clean up GPIO resources."""
        if self.initialized:
            GPIO.cleanup()
            self.initialized = False
            logging.info("GPIO cleaned up")


class PIRSensor:
    """PIR motion sensor interface."""
    
    def __init__(self, pin, callback):
        """
        Initialize PIR sensor.
        
        Args:
            pin: GPIO pin number (BCM mode)
            callback: Function to call on motion detection
        """
        self.pin = pin
        self.callback = callback
        self._event_registered = False
    
    def setup(self):
        """Configure GPIO pin for sensor."""
        try:
            GPIO.setup(self.pin, GPIO.IN)
            logging.info(f"PIR sensor configured on GPIO{self.pin}")
        except RuntimeError as e:
            logging.error(f"Failed to setup sensor: {e}")
            raise
    
    def start_monitoring(self):
        """Start monitoring for motion events."""
        try:
            GPIO.add_event_detect(
                self.pin,
                GPIO.RISING,
                callback=self.callback
            )
            self._event_registered = True
            logging.info("Motion monitoring started")
        except RuntimeError as e:
            logging.error(f"Failed to start monitoring: {e}")
            raise
    
    def stop_monitoring(self):
        """Stop monitoring for motion events."""
        if self._event_registered:
            try:
                GPIO.remove_event_detect(self.pin)
                self._event_registered = False
                logging.info("Motion monitoring stopped")
            except RuntimeError as e:
                logging.error(f"Failed to stop monitoring: {e}")


# ============================================================================
# Application Logic
# ============================================================================

class MotionDetectionApp:
    """Main motion detection application."""
    
    def __init__(self, config):
        """
        Initialize the application.
        
        Args:
            config: Config instance with application settings
        """
        self.config = config
        self.gpio_manager = GPIOManager(config)
        self.sensor = None
        self.running = False
        self.last_trigger_time = 0
    
    def initialize(self):
        """Initialize application components."""
        logging.info("Initializing motion detection application...")
        
        # Initialize GPIO
        self.gpio_manager.initialize()
        
        # Setup sensor
        self.sensor = PIRSensor(self.config.SENSOR_PIN, self.on_motion_detected)
        self.sensor.setup()
        
        # Validate sound directory at startup
        self._validate_sound_directory()
        
        # Load last trigger time
        last_time_str = safe_read_file(self.config.TIMER_FILE, "0")
        try:
            self.last_trigger_time = int(last_time_str)
            logging.info(f"Last trigger: {self.last_trigger_time}")
        except ValueError:
            self.last_trigger_time = 0
            # Sanitize timer file content before logging (limit to 50 chars)
            sanitized_content = last_time_str[:50] if last_time_str else ""
            logging.warning(f"Invalid timer file content (first 50 chars): {sanitized_content!r}, reset to 0")
    
    def _validate_sound_directory(self):
        """Validate sound directory exists and contains sound files."""
        if not os.path.isdir(self.config.SOUND_DIR):
            logging.warning(f"Sound directory not found: {self.config.SOUND_DIR}")
            return
        
        sound_files = [
            f for f in os.listdir(self.config.SOUND_DIR)
            if f.lower().endswith(('.wav', '.mp3'))
        ]
        
        if not sound_files:
            logging.warning(f"No sound files in {self.config.SOUND_DIR}")
        else:
            logging.info(f"Found {len(sound_files)} sound file(s) in {self.config.SOUND_DIR}")
    
    def on_motion_detected(self, channel):
        """
        Callback for motion detection events.
        
        All motion events are logged and published to MQTT/Home Assistant.
        Sound playback respects cooldown period to prevent spam.
        
        Args:
            channel: GPIO channel that triggered the event
        """
        try:
            now = int(time.time())
            time_since_last = now - self.last_trigger_time
            
            # Always log motion detection
            logging.info(f"Motion detected on GPIO{channel}")
            
            # Always publish to MQTT (Home Assistant tracks all motion)
            publish_sensor_value('mario_motion', 'ON', is_binary=True)
            
            # Check cooldown for sound playback only
            if time_since_last < self.config.COOLDOWN_SECONDS:
                remaining = self.config.COOLDOWN_SECONDS - time_since_last
                logging.info(f"Sound cooldown active ({remaining}s remaining), skipping playback")
                return
            
            # Play sound (cooldown expired)
            logging.info("Cooldown expired, playing sound")
            self.play_sound_for_motion()
            
            # Update last trigger time for sound cooldown
            self.last_trigger_time = now
            safe_write_file(self.config.TIMER_FILE, now)
            
        except Exception as e:
            logging.error(f"Error in motion callback: {e}")
    
    def play_sound_for_motion(self):
        """Play random sound file when motion is detected (after cooldown check)."""
        try:
            sound_files = [
                f for f in os.listdir(self.config.SOUND_DIR)
                if f.lower().endswith(('.wav', '.mp3'))
            ]
            
            if not sound_files:
                logging.error(f"No sound files available in {self.config.SOUND_DIR}")
                return
            
            sound_file = random.choice(sound_files)
            sound_path = os.path.join(self.config.SOUND_DIR, sound_file)
            
            logging.info(f"Playing sound: {sound_file}")
            self.play_sound(sound_path)
            
        except FileNotFoundError:
            logging.error(f"Sound directory not found: {self.config.SOUND_DIR}")
        except Exception as e:
            logging.error(f"Failed to play sound: {e}")
    
    def play_sound(self, filepath):
        """
        Play sound file using aplay.
        
        Args:
            filepath: Path to sound file
        """
        try:
            # Validate filepath before execution
            if not os.path.isfile(filepath):
                logging.error(f"Sound file not found: {os.path.basename(filepath)}")
                return
            
            # Ensure file is within expected sound directory (prevent path traversal)
            real_path = os.path.realpath(filepath)
            real_sound_dir = os.path.realpath(self.config.SOUND_DIR)
            
            # Use os.path.commonpath to properly check directory containment
            try:
                common = os.path.commonpath([real_path, real_sound_dir])
                if common != real_sound_dir:
                    logging.error("Sound file outside allowed directory")
                    return
            except ValueError:
                # Paths are on different drives (Windows) or one is relative
                logging.error("Invalid sound file path")
                return
            
            if MOCK_MODE:
                print(f"[MOCK] Would play: {os.path.basename(filepath)}")
                return
            
            result = subprocess.run(
                ['aplay', filepath],
                capture_output=True,
                timeout=10,
                check=False
            )
            
            if result.returncode != 0:
                # Sanitize stderr output (limit length, remove newlines)
                stderr_msg = result.stderr.decode('utf-8', errors='replace')[:200].replace('\n', ' ')
                logging.error(f"Audio playback failed: {stderr_msg}")
        except subprocess.TimeoutExpired:
            logging.error("Audio playback timed out")
        except FileNotFoundError:
            logging.error("aplay command not found")
        except Exception as e:
            logging.error(f"Error playing sound: {e}")
    
    def run(self):
        """Main application loop."""
        logging.info("Starting motion detection service...")
        self.running = True
        
        # Start sensor monitoring
        self.sensor.start_monitoring()
        
        # Main loop - sleep and let events handle everything
        # Signal handlers (SIGINT, SIGTERM) will trigger graceful shutdown
        try:
            while self.running:
                time.sleep(self.config.MAIN_LOOP_SLEEP)
                
        except KeyboardInterrupt:
            logging.info("Keyboard interrupt received")
        finally:
            self.stop()
    
    def stop(self):
        """Stop application and clean up resources."""
        if not self.running:
            return
        
        logging.info("Stopping motion detection service...")
        self.running = False
        
        # Stop sensor monitoring
        if self.sensor:
            self.sensor.stop_monitoring()
        
        # Cleanup GPIO
        self.gpio_manager.cleanup()
        
        logging.info("Motion detection service stopped")


# ============================================================================
# Signal Handlers
# ============================================================================

# Global app instance for signal handlers
app_instance = None

def signal_handler(signum, frame):
    """
    Handle shutdown signals gracefully.
    
    Args:
        signum: Signal number
        frame: Current stack frame
    """
    signal_name = signal.Signals(signum).name
    logging.info(f"Received signal: {signal_name}")
    
    if app_instance:
        app_instance.stop()
    
    sys.exit(0)


# ============================================================================
# Main Entry Point
# ============================================================================

def main():
    """Main entry point for the application."""
    global app_instance
    
    # Load configuration first (prints to console, logging not yet configured)
    config = Config(module_path="motion-detection/mario")
    
    # Setup logging with config
    setup_logging(config)
    logging.info("=" * 60)
    logging.info("Mario Motion Detection Application Starting")
    logging.info("=" * 60)
    
    # Check permissions
    if not MOCK_MODE and os.geteuid() != 0:
        logging.error("This script requires root privileges for GPIO access")
        print("Please run with: sudo python3", sys.argv[0])
        sys.exit(1)
    
    # Register signal handlers
    signal.signal(signal.SIGINT, signal_handler)   # Ctrl+C
    signal.signal(signal.SIGTERM, signal_handler)  # kill command
    
    # Create and initialize application
    try:
        app_instance = MotionDetectionApp(config)
        app_instance.initialize()
        
        # Run main loop
        app_instance.run()
        
    except Exception as e:
        logging.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)
    
    logging.info("Application exited normally")


if __name__ == '__main__':
    main()
