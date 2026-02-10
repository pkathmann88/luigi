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
- File-based stop signal mechanism (legacy compatibility)

Shutdown Methods:
- **SIGTERM signal** (recommended): Graceful shutdown via signal handler
- **SIGINT signal** (Ctrl+C): Interactive shutdown
- **Stop file** (/tmp/stop_mario): Legacy method for backwards compatibility

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
        def cleanup(cls):
            print("[MOCK] GPIO cleaned up")
    
    GPIO = MockGPIO
    MOCK_MODE = True
    print("WARNING: Using mock GPIO (no hardware available)")


# ============================================================================
# Configuration
# ============================================================================

class Config:
    """Application configuration constants."""
    
    # GPIO Settings (BCM numbering)
    GPIO_MODE = GPIO.BCM
    SENSOR_PIN = 23
    
    # File Paths
    SOUND_DIR = "/usr/share/sounds/mario/"
    STOP_FILE = "/tmp/stop_mario"
    TIMER_FILE = "/tmp/mario_timer"
    LOG_FILE = "/var/log/motion.log"
    
    # Timing Settings
    COOLDOWN_SECONDS = 1800  # 30 minutes
    MAIN_LOOP_SLEEP = 100    # seconds
    
    # Logging
    LOG_LEVEL = logging.INFO
    LOG_MAX_BYTES = 10 * 1024 * 1024  # 10MB
    LOG_BACKUP_COUNT = 5


# ============================================================================
# Logging Setup
# ============================================================================

def setup_logging():
    """Configure application logging with console and file handlers."""
    logger = logging.getLogger()
    logger.setLevel(Config.LOG_LEVEL)
    
    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.INFO)
    console_format = logging.Formatter('%(levelname)s: %(message)s')
    console_handler.setFormatter(console_format)
    logger.addHandler(console_handler)
    
    # File handler with rotation
    try:
        Path(Config.LOG_FILE).parent.mkdir(parents=True, exist_ok=True)
        file_handler = RotatingFileHandler(
            Config.LOG_FILE,
            maxBytes=Config.LOG_MAX_BYTES,
            backupCount=Config.LOG_BACKUP_COUNT
        )
        file_handler.setLevel(Config.LOG_LEVEL)
        file_format = logging.Formatter(
            '%(asctime)s - %(levelname)s - %(message)s'
        )
        file_handler.setFormatter(file_format)
        logger.addHandler(file_handler)
        logging.info(f"Logging to file: {Config.LOG_FILE}")
    except PermissionError:
        logging.warning(f"Cannot write to {Config.LOG_FILE}, using console only")
    
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


def check_stop_signal():
    """
    Check if stop signal file exists.
    
    Returns:
        bool: True if stop requested, False otherwise
    """
    return os.path.isfile(Config.STOP_FILE)


def remove_stop_signal():
    """Remove stop signal file if it exists."""
    try:
        if os.path.isfile(Config.STOP_FILE):
            os.remove(Config.STOP_FILE)
            logging.info("Stop signal file removed")
    except OSError as e:
        logging.error(f"Failed to remove stop file: {e}")


# ============================================================================
# Hardware Abstraction Layer
# ============================================================================

class GPIOManager:
    """Manages GPIO initialization and cleanup."""
    
    def __init__(self):
        self.initialized = False
    
    def initialize(self):
        """Initialize GPIO mode."""
        try:
            GPIO.setmode(Config.GPIO_MODE)
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
    
    def __init__(self):
        self.gpio_manager = GPIOManager()
        self.sensor = None
        self.running = False
        self.last_trigger_time = 0
    
    def initialize(self):
        """Initialize application components."""
        logging.info("Initializing motion detection application...")
        
        # Initialize GPIO
        self.gpio_manager.initialize()
        
        # Setup sensor
        self.sensor = PIRSensor(Config.SENSOR_PIN, self.on_motion_detected)
        self.sensor.setup()
        
        # Remove any lingering stop signal
        remove_stop_signal()
        
        # Validate sound directory at startup
        self._validate_sound_directory()
        
        # Load last trigger time
        last_time_str = safe_read_file(Config.TIMER_FILE, "0")
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
        if not os.path.isdir(Config.SOUND_DIR):
            logging.warning(f"Sound directory not found: {Config.SOUND_DIR}")
            return
        
        sound_files = [
            f for f in os.listdir(Config.SOUND_DIR)
            if f.lower().endswith(('.wav', '.mp3'))
        ]
        
        if not sound_files:
            logging.warning(f"No sound files in {Config.SOUND_DIR}")
        else:
            logging.info(f"Found {len(sound_files)} sound file(s) in {Config.SOUND_DIR}")
    
    def on_motion_detected(self, channel):
        """
        Callback for motion detection events.
        
        Args:
            channel: GPIO channel that triggered the event
        
        Note:
            The stop file check is maintained for backwards compatibility
            with the old init.d script. Modern service managers should use
            SIGTERM signal (handled by signal_handler) for graceful shutdown.
        """
        try:
            # Check for stop signal file (backwards compatibility)
            if check_stop_signal():
                logging.info("Stop signal file detected, shutting down...")
                self.stop()
                return
            
            # Check cooldown period
            now = int(time.time())
            time_since_last = now - self.last_trigger_time
            
            if time_since_last < Config.COOLDOWN_SECONDS:
                remaining = Config.COOLDOWN_SECONDS - time_since_last
                logging.debug(f"Cooldown active ({remaining}s remaining)")
                return
            
            # Process motion event
            logging.info(f"Motion detected on GPIO{channel}")
            self.handle_motion()
            
            # Update last trigger time
            self.last_trigger_time = now
            safe_write_file(Config.TIMER_FILE, now)
            
        except Exception as e:
            logging.error(f"Error in motion callback: {e}")
    
    def handle_motion(self):
        """Process motion detection event."""
        try:
            sound_files = [
                f for f in os.listdir(Config.SOUND_DIR)
                if f.lower().endswith(('.wav', '.mp3'))
            ]
            
            if not sound_files:
                logging.error(f"No sound files available in {Config.SOUND_DIR}")
                return
            
            sound_file = random.choice(sound_files)
            sound_path = os.path.join(Config.SOUND_DIR, sound_file)
            
            logging.info(f"Playing sound: {sound_file}")
            self.play_sound(sound_path)
            
        except FileNotFoundError:
            logging.error(f"Sound directory not found: {Config.SOUND_DIR}")
        except Exception as e:
            logging.error(f"Failed to handle motion: {e}")
    
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
            real_sound_dir = os.path.realpath(Config.SOUND_DIR)
            
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
                time.sleep(Config.MAIN_LOOP_SLEEP)
                
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
        
        # Remove stop signal file
        remove_stop_signal()
        
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
    
    # Setup logging
    setup_logging()
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
        app_instance = MotionDetectionApp()
        app_instance.initialize()
        
        # Run main loop
        app_instance.run()
        
    except Exception as e:
        logging.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)
    
    logging.info("Application exited normally")


if __name__ == '__main__':
    main()
