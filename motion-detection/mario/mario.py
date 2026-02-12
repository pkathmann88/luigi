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
import threading
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
    DEFAULT_LOG_FILE = "/var/log/luigi/mario.log"
    DEFAULT_COOLDOWN_SECONDS = 1800  # 30 minutes
    DEFAULT_MAIN_LOOP_SLEEP = 100    # seconds
    DEFAULT_MQTT_OFF_DELAY = 5       # seconds to wait before sending OFF to MQTT
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
                self.MQTT_OFF_DELAY = parser.getint('Timing', 'MQTT_OFF_DELAY',
                                                    fallback=self.DEFAULT_MQTT_OFF_DELAY)
                
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
        self.MQTT_OFF_DELAY = self.DEFAULT_MQTT_OFF_DELAY
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
        """Initialize GPIO mode with diagnostic logging."""
        logging.info("=" * 60)
        logging.info("Starting GPIO initialization")
        logging.info(f"GPIO mode to set: {self.config.GPIO_MODE}")
        logging.info(f"Target sensor pin: {self.config.SENSOR_PIN}")
        
        # Log environment diagnostics
        try:
            import os
            logging.info(f"Running as UID: {os.getuid()}, GID: {os.getgid()}")
            logging.info(f"Effective UID: {os.geteuid()}, Effective GID: {os.getegid()}")
        except Exception as e:
            logging.warning(f"Could not get user info: {e}")
        
        # Check if running in mock mode
        if MOCK_MODE:
            logging.warning("Running in MOCK MODE (no actual hardware)")
        else:
            logging.info("Running in HARDWARE MODE (real GPIO)")
            
        # Attempt GPIO initialization
        try:
            logging.info("Calling GPIO.setmode()...")
            GPIO.setmode(self.config.GPIO_MODE)
            logging.info(f"✓ GPIO.setmode() succeeded with mode: {self.config.GPIO_MODE}")
            
            # Check current mode
            try:
                mode = GPIO.getmode()
                logging.info(f"Current GPIO mode after setmode: {mode}")
            except Exception as e:
                logging.warning(f"Could not get GPIO mode: {e}")
            
            self.initialized = True
            logging.info("✓ GPIO initialization completed successfully")
            logging.info("=" * 60)
            
        except RuntimeError as e:
            logging.error("=" * 60)
            logging.error(f"✗ GPIO initialization FAILED with RuntimeError: {e}")
            logging.error(f"Error type: {type(e).__name__}")
            logging.error(f"Error args: {e.args}")
            
            # Try to provide helpful context
            if "not permitted" in str(e).lower() or "permission" in str(e).lower():
                logging.error("DIAGNOSIS: Permission denied - GPIO access requires root privileges")
                logging.error("  Solution: Ensure service runs as root or user is in gpio group")
            elif "already" in str(e).lower():
                logging.error("DIAGNOSIS: GPIO mode already set")
                logging.error("  Solution: Call GPIO.cleanup() before setmode")
            else:
                logging.error("DIAGNOSIS: Unknown GPIO initialization error")
                logging.error("  Check: 1) RPi.GPIO library installed, 2) Running on Raspberry Pi, 3) Kernel modules loaded")
            
            logging.error("=" * 60)
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
        """Configure GPIO pin for sensor with diagnostic logging."""
        logging.info("=" * 60)
        logging.info(f"Configuring PIR sensor on GPIO{self.pin}")
        
        try:
            logging.info(f"Calling GPIO.setup({self.pin}, GPIO.IN)...")
            GPIO.setup(self.pin, GPIO.IN)
            logging.info(f"✓ GPIO.setup() succeeded for pin {self.pin}")
            
            # Try to read initial pin state
            try:
                state = GPIO.input(self.pin)
                logging.info(f"Initial pin state: {state}")
            except Exception as e:
                logging.warning(f"Could not read pin state: {e}")
            
            logging.info(f"✓ PIR sensor configured successfully on GPIO{self.pin}")
            logging.info("=" * 60)
            
        except RuntimeError as e:
            logging.error("=" * 60)
            logging.error(f"✗ GPIO.setup() FAILED for pin {self.pin}")
            logging.error(f"Error: {e}")
            logging.error(f"Error type: {type(e).__name__}")
            
            if "in use" in str(e).lower():
                logging.error(f"DIAGNOSIS: GPIO{self.pin} is already in use")
                logging.error("  Possible causes: Another process using this pin, previous cleanup failed")
                logging.error("  Solution: Check for other processes, try GPIO.cleanup() first")
            elif "invalid" in str(e).lower():
                logging.error(f"DIAGNOSIS: GPIO{self.pin} is invalid")
                logging.error("  Solution: Check pin number is valid for BCM mode")
            else:
                logging.error("DIAGNOSIS: Unknown GPIO setup error")
            
            logging.error("=" * 60)
            raise
    
    def start_monitoring(self):
        """Start monitoring for motion events with diagnostic logging."""
        logging.info("=" * 60)
        logging.info(f"Starting motion monitoring on GPIO{self.pin}")
        
        # Check if event detection already exists
        logging.info("Checking for existing event detection...")
        try:
            GPIO.remove_event_detect(self.pin)
            logging.warning(f"Removed existing event detection on GPIO{self.pin} - this shouldn't normally happen")
        except RuntimeError as e:
            logging.info(f"No existing event detection found (expected): {e}")
        
        # Attempt to add event detection
        try:
            logging.info(f"Calling GPIO.add_event_detect({self.pin}, GPIO.RISING, callback=...)") 
            GPIO.add_event_detect(
                self.pin,
                GPIO.RISING,
                callback=self.callback
            )
            self._event_registered = True
            logging.info("✓ GPIO.add_event_detect() succeeded")
            logging.info("✓ Motion monitoring started successfully")
            logging.info("=" * 60)
            
        except RuntimeError as e:
            logging.error("=" * 60)
            logging.error(f"✗ GPIO.add_event_detect() FAILED for pin {self.pin}")
            logging.error(f"Error: {e}")
            logging.error(f"Error type: {type(e).__name__}")
            logging.error(f"Error args: {e.args}")
            
            # Detailed diagnosis
            error_str = str(e).lower()
            if "failed to add edge detection" in error_str:
                logging.error("DIAGNOSIS: Failed to add edge detection")
                logging.error("  Common causes:")
                logging.error("    1. Pin already has event detection (not cleaned up)")
                logging.error("    2. GPIO in wrong mode or not initialized")
                logging.error("    3. Pin already in use by kernel driver")
                logging.error("    4. Insufficient permissions")
                logging.error("  Troubleshooting:")
                logging.error("    - Check: sudo cat /sys/kernel/debug/gpio")
                logging.error("    - Check: lsmod | grep gpio")
                logging.error("    - Try: GPIO.cleanup() and restart")
            elif "in use" in error_str:
                logging.error(f"DIAGNOSIS: GPIO{self.pin} is in use")
                logging.error("  Another process or driver is using this pin")
            else:
                logging.error("DIAGNOSIS: Unknown event detection error")
            
            # Try to get GPIO mode for debugging
            try:
                mode = GPIO.getmode()
                logging.error(f"Current GPIO mode: {mode} (expected: {GPIO.BCM})")
                if mode != GPIO.BCM:
                    logging.error("  ERROR: GPIO mode mismatch!")
            except Exception as mode_e:
                logging.error(f"Could not get GPIO mode: {mode_e}")
            
            logging.error("=" * 60)
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
        # OFF-timer state (thread-safe access via timer_lock)
        self.off_timer = None  # Timer for delayed OFF message
        self.timer_lock = threading.Lock()  # Thread-safe timer access
    
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
    
    def _cancel_off_timer(self):
        """Cancel any pending OFF timer (thread-safe)."""
        with self.timer_lock:
            if self.off_timer is not None:
                self.off_timer.cancel()
                self.off_timer = None
                logging.debug("OFF timer cancelled")
    
    def _start_off_timer(self):
        """Start or reset the OFF timer (thread-safe)."""
        # Only start timer if MQTT_OFF_DELAY is configured (> 0)
        if self.config.MQTT_OFF_DELAY <= 0:
            return
        
        # Cancel any existing timer
        self._cancel_off_timer()
        
        # Start new timer
        with self.timer_lock:
            self.off_timer = threading.Timer(
                self.config.MQTT_OFF_DELAY,
                self._publish_off_message
            )
            self.off_timer.start()
            logging.debug(f"OFF timer started ({self.config.MQTT_OFF_DELAY}s)")
    
    def _publish_off_message(self):
        """
        Publish OFF message to MQTT (called by timer thread).
        
        This method runs in the timer's thread context. The timer reference
        is cleared to maintain explicit state (off_timer=None means no active timer).
        """
        try:
            logging.info("Publishing OFF to MQTT (motion timer expired)")
            publish_sensor_value('mario_motion', 'OFF', is_binary=True)
            
            # Clear timer reference for explicit state management
            with self.timer_lock:
                self.off_timer = None
                
        except Exception as e:
            logging.error(f"Error publishing OFF message: {e}")
    
    def on_motion_detected(self, channel):
        """
        Callback for motion detection events.
        
        All motion events are logged and published to MQTT/Home Assistant.
        Sound playback respects cooldown period to prevent spam.
        OFF message is sent to MQTT after configured delay (if no new motion).
        
        Args:
            channel: GPIO channel that triggered the event
        """
        try:
            now = int(time.time())
            time_since_last = now - self.last_trigger_time
            
            # Always log motion detection
            logging.info(f"Motion detected on GPIO{channel}")
            
            # Always publish ON to MQTT (Home Assistant tracks all motion)
            publish_sensor_value('mario_motion', 'ON', is_binary=True)
            
            # Start/reset OFF timer (publishes OFF after delay if no new motion)
            self._start_off_timer()
            
            # Check cooldown for sound playback only
            if time_since_last < self.config.COOLDOWN_SECONDS:
                remaining = self.config.COOLDOWN_SECONDS - time_since_last
                logging.info(f"Sound cooldown active ({remaining}s remaining), skipping playback")
                return
            
            # Play sound (cooldown expired)
            self.play_sound_for_motion()
            
            # Update last trigger time for sound cooldown
            self.last_trigger_time = now
            safe_write_file(self.config.TIMER_FILE, now)
            
        except Exception as e:
            logging.error(f"Error in motion callback: {e}")
    
    def play_sound_for_motion(self):
        """
        Play random sound file for motion detection.
        
        Only called after cooldown period has expired.
        """
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
            
            # Use aplay with parameters to reduce audio artifacts on I2S devices
            # -q: quiet mode (no status output)
            # The following parameters help prevent popping/crackling on I2S audio devices
            # like the Adafruit Sound Bonnet by ensuring proper buffer management
            result = subprocess.run(
                ['aplay', '-q', filepath],
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
        
        # Cancel any pending OFF timer
        self._cancel_off_timer()
        
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

def run_startup_diagnostics():
    """Run comprehensive diagnostics before attempting GPIO operations."""
    logging.info("#" * 70)
    logging.info("MARIO MOTION DETECTION - STARTUP DIAGNOSTICS")
    logging.info("#" * 70)
    
    # System information
    import platform
    import sys
    logging.info(f"Python version: {sys.version}")
    logging.info(f"Platform: {platform.platform()}")
    logging.info(f"Machine: {platform.machine()}")
    logging.info(f"Processor: {platform.processor()}")
    
    # Check if running on Raspberry Pi
    try:
        with open('/proc/cpuinfo', 'r') as f:
            cpuinfo = f.read()
            if 'Raspberry Pi' in cpuinfo or 'BCM' in cpuinfo:
                logging.info("✓ Running on Raspberry Pi hardware")
            else:
                logging.warning("⚠ May not be running on Raspberry Pi hardware")
    except Exception as e:
        logging.warning(f"Could not read /proc/cpuinfo: {e}")
    
    # Check user/permissions
    import os
    logging.info(f"User ID: {os.getuid()}, Effective: {os.geteuid()}")
    logging.info(f"Group ID: {os.getgid()}, Effective: {os.getegid()}")
    if os.geteuid() != 0:
        logging.warning("⚠ NOT running as root - GPIO access may fail")
    else:
        logging.info("✓ Running as root")
    
    # Check GPIO library
    logging.info(f"RPi.GPIO library: {'MOCK MODE' if MOCK_MODE else 'Hardware mode'}")
    if not MOCK_MODE:
        try:
            import RPi.GPIO
            version = getattr(RPi.GPIO, 'VERSION', 'unknown')
            logging.info(f"✓ RPi.GPIO version: {version}")
        except Exception as e:
            logging.error(f"✗ RPi.GPIO library issue: {e}")
    
    # Check for GPIO-related kernel modules
    try:
        import subprocess
        result = subprocess.run(['lsmod'], capture_output=True, text=True, timeout=5)
        if result.returncode == 0:
            gpio_modules = [line for line in result.stdout.split('\n') if 'gpio' in line.lower()]
            if gpio_modules:
                logging.info(f"GPIO kernel modules loaded: {len(gpio_modules)}")
                for mod in gpio_modules[:5]:  # Show first 5
                    logging.info(f"  - {mod.split()[0]}")
            else:
                logging.warning("No GPIO kernel modules found via lsmod")
    except Exception as e:
        logging.warning(f"Could not check kernel modules: {e}")
    
    # Check /dev/gpiochip0 access
    try:
        if os.path.exists('/dev/gpiochip0'):
            stat = os.stat('/dev/gpiochip0')
            logging.info(f"✓ /dev/gpiochip0 exists (mode: {oct(stat.st_mode)})")
            if os.access('/dev/gpiochip0', os.R_OK | os.W_OK):
                logging.info("✓ /dev/gpiochip0 is accessible (read/write)")
            else:
                logging.warning("⚠ /dev/gpiochip0 exists but not accessible")
        else:
            logging.warning("⚠ /dev/gpiochip0 does not exist")
    except Exception as e:
        logging.warning(f"Could not check /dev/gpiochip0: {e}")
    
    # Check log file writability
    import pathlib
    log_file = pathlib.Path("/var/log/luigi/mario.log")
    try:
        log_file.parent.mkdir(parents=True, exist_ok=True)
        logging.info(f"✓ Log directory exists: {log_file.parent}")
        if log_file.exists():
            logging.info(f"✓ Log file exists: {log_file}")
        else:
            logging.info(f"Log file will be created: {log_file}")
    except Exception as e:
        logging.error(f"✗ Cannot create log directory: {e}")
    
    logging.info("#" * 70)
    logging.info("END DIAGNOSTICS - Starting application...")
    logging.info("#" * 70)


def main():
    """Main entry point for the application."""
    global app_instance
    
    # Load configuration first (prints to console, logging not yet configured)
    config = Config(module_path="motion-detection/mario")
    
    # Setup logging with config
    setup_logging(config)
    
    # Run diagnostics BEFORE anything else
    run_startup_diagnostics()
    
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
