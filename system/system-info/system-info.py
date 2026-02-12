#!/usr/bin/env python3
"""
System Information Module

Collects and publishes system metrics (uptime, CPU temp, memory, disk usage)
to Home Assistant via MQTT every 5 minutes.

Features:
- System uptime monitoring
- CPU temperature tracking
- Memory usage monitoring
- Disk usage monitoring
- CPU usage percentage
- Configurable publish interval
- Graceful shutdown handling
- Structured logging with rotation

Shutdown Methods:
- **SIGTERM signal** (recommended): Graceful shutdown via signal handler
- **SIGINT signal** (Ctrl+C): Interactive shutdown

Hardware Requirements:
- Raspberry Pi Zero W (or compatible)
- Network connectivity for MQTT

Author: Luigi Project
License: MIT
"""

import sys
import os
import time
import signal
import logging
import subprocess
import configparser
import psutil
from pathlib import Path
from logging.handlers import RotatingFileHandler
from datetime import datetime, timedelta


# ============================================================================
# Configuration
# ============================================================================

class Config:
    """Load application configuration from file with fallback to defaults."""
    
    # Default configuration values
    DEFAULT_LOG_FILE = "/var/log/luigi/system-info.log"
    DEFAULT_LOG_LEVEL = "INFO"
    DEFAULT_LOG_MAX_BYTES = 10 * 1024 * 1024  # 10MB
    DEFAULT_LOG_BACKUP_COUNT = 5
    DEFAULT_PUBLISH_INTERVAL = 300  # 5 minutes in seconds
    DEFAULT_MAIN_LOOP_SLEEP = 60    # Check every minute
    
    def __init__(self, module_path="system/system-info"):
        """
        Initialize configuration from file or defaults.
        
        Args:
            module_path: Module path matching repository structure
        """
        self.module_path = module_path
        self.config_file = f"/etc/luigi/{module_path}/system-info.conf"
        
        # Load configuration
        self._load_config()
    
    def _load_config(self):
        """Load configuration from file or use defaults."""
        # Initialize with defaults
        self.LOG_FILE = self.DEFAULT_LOG_FILE
        self.LOG_LEVEL = self.DEFAULT_LOG_LEVEL
        self.LOG_MAX_BYTES = self.DEFAULT_LOG_MAX_BYTES
        self.LOG_BACKUP_COUNT = self.DEFAULT_LOG_BACKUP_COUNT
        self.PUBLISH_INTERVAL = self.DEFAULT_PUBLISH_INTERVAL
        self.MAIN_LOOP_SLEEP = self.DEFAULT_MAIN_LOOP_SLEEP
        
        # Try to read config file
        if os.path.exists(self.config_file):
            try:
                parser = configparser.ConfigParser()
                parser.read(self.config_file)
                
                # Load logging settings
                if parser.has_section('Logging'):
                    self.LOG_FILE = parser.get('Logging', 'log_file', 
                                               fallback=self.DEFAULT_LOG_FILE)
                    self.LOG_LEVEL = parser.get('Logging', 'log_level', 
                                                fallback=self.DEFAULT_LOG_LEVEL)
                    self.LOG_MAX_BYTES = parser.getint('Logging', 'log_max_bytes', 
                                                       fallback=self.DEFAULT_LOG_MAX_BYTES)
                    self.LOG_BACKUP_COUNT = parser.getint('Logging', 'log_backup_count', 
                                                         fallback=self.DEFAULT_LOG_BACKUP_COUNT)
                
                # Load timing settings
                if parser.has_section('Timing'):
                    self.PUBLISH_INTERVAL = parser.getint('Timing', 'publish_interval_seconds', 
                                                         fallback=self.DEFAULT_PUBLISH_INTERVAL)
                    self.MAIN_LOOP_SLEEP = parser.getint('Timing', 'main_loop_sleep_seconds', 
                                                        fallback=self.DEFAULT_MAIN_LOOP_SLEEP)
                
                logging.info(f"Configuration loaded from {self.config_file}")
            except Exception as e:
                logging.warning(f"Error loading config file {self.config_file}: {e}")
                logging.warning("Using default configuration")
        else:
            logging.info(f"Config file not found: {self.config_file}, using defaults")


# ============================================================================
# Logging Configuration
# ============================================================================

def setup_logging(config):
    """
    Configure logging with rotation and multiple outputs.
    
    Args:
        config: Config instance with logging settings
    """
    # Create log directory if it doesn't exist
    log_dir = os.path.dirname(config.LOG_FILE)
    if log_dir and not os.path.exists(log_dir):
        try:
            os.makedirs(log_dir, mode=0o755, exist_ok=True)
        except OSError:
            # Fall back to /tmp if we can't create /var/log
            config.LOG_FILE = "/tmp/system-info.log"
    
    # Create rotating file handler
    try:
        file_handler = RotatingFileHandler(
            config.LOG_FILE,
            maxBytes=config.LOG_MAX_BYTES,
            backupCount=config.LOG_BACKUP_COUNT
        )
        file_handler.setFormatter(logging.Formatter(
            '%(asctime)s - %(levelname)s - %(message)s'
        ))
    except (OSError, PermissionError) as e:
        print(f"Warning: Could not create log file {config.LOG_FILE}: {e}")
        file_handler = None
    
    # Console handler for development/debugging
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(logging.Formatter(
        '%(asctime)s - %(levelname)s - %(message)s'
    ))
    
    # Configure root logger
    handlers = [console_handler]
    if file_handler:
        handlers.append(file_handler)
    
    logging.basicConfig(
        level=getattr(logging, config.LOG_LEVEL.upper(), logging.INFO),
        handlers=handlers
    )
    
    logging.info("System Info Module started")
    logging.info(f"Publish interval: {config.PUBLISH_INTERVAL} seconds")


# ============================================================================
# MQTT Publishing
# ============================================================================

def publish_sensor_value(sensor_id, value, unit=None):
    """
    Publish sensor value to Home Assistant via MQTT.
    
    Optional integration with ha-mqtt module. Module works standalone
    if ha-mqtt is not installed.
    
    Args:
        sensor_id: Unique sensor identifier (e.g., 'system_uptime')
        value: Sensor value (e.g., '24.5', '45')
        unit: Unit of measurement (e.g., 'h', '°C', '%', 'GB')
        
    Returns:
        bool: True if published successfully, False otherwise
    """
    try:
        cmd = ['/usr/local/bin/luigi-publish', '--sensor', sensor_id, '--value', str(value)]
        
        if unit:
            cmd.extend(['--unit', unit])
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            timeout=10,  # Increased from 5 to 10 seconds for network startup delays
            check=True
        )
        
        logging.debug(f"Published {sensor_id}={value} {unit or ''} to MQTT")
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
# System Metrics Collection
# ============================================================================

class SystemMetrics:
    """Collects system information metrics."""
    
    @staticmethod
    def get_uptime_hours():
        """
        Get system uptime in hours.
        
        Returns:
            float: Uptime in hours, or None if unable to read
        """
        try:
            with open('/proc/uptime', 'r') as f:
                uptime_seconds = float(f.read().split()[0])
                return round(uptime_seconds / 3600, 2)
        except Exception as e:
            logging.error(f"Error reading uptime: {e}")
            return None
    
    @staticmethod
    def get_cpu_temperature():
        """
        Get CPU temperature in Celsius using vcgencmd (Raspberry Pi specific).
        Falls back to thermal zone if vcgencmd not available.
        
        Returns:
            float: CPU temperature in Celsius, or None if unable to read
        """
        # Try vcgencmd first (Raspberry Pi specific)
        try:
            result = subprocess.run(
                ['vcgencmd', 'measure_temp'],
                capture_output=True,
                timeout=2,
                check=True,
                text=True
            )
            # Output format: temp=45.2'C
            temp_str = result.stdout.strip()
            temp = float(temp_str.split('=')[1].split("'")[0])
            return round(temp, 1)
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired, 
                FileNotFoundError, ValueError, IndexError):
            pass
        
        # Fall back to thermal zone
        try:
            with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
                temp_millidegrees = int(f.read().strip())
                return round(temp_millidegrees / 1000.0, 1)
        except Exception as e:
            logging.error(f"Error reading CPU temperature: {e}")
            return None
    
    @staticmethod
    def get_memory_usage_percent():
        """
        Get memory usage percentage using psutil.
        
        Returns:
            float: Memory usage percentage, or None if unable to read
        """
        try:
            memory = psutil.virtual_memory()
            return round(memory.percent, 1)
        except Exception as e:
            logging.error(f"Error reading memory usage: {e}")
            return None
    
    @staticmethod
    def get_disk_usage_percent():
        """
        Get root filesystem disk usage percentage using psutil.
        
        Returns:
            float: Disk usage percentage, or None if unable to read
        """
        try:
            disk = psutil.disk_usage('/')
            return round(disk.percent, 1)
        except Exception as e:
            logging.error(f"Error reading disk usage: {e}")
            return None
    
    @staticmethod
    def get_cpu_usage_percent():
        """
        Get CPU usage percentage (averaged over 1 second) using psutil.
        
        Returns:
            float: CPU usage percentage, or None if unable to read
        """
        try:
            # Get CPU usage over 1 second interval
            cpu_percent = psutil.cpu_percent(interval=1)
            return round(cpu_percent, 1)
        except Exception as e:
            logging.error(f"Error reading CPU usage: {e}")
            return None


# ============================================================================
# Main Application
# ============================================================================

class SystemInfoMonitor:
    """Main application class for system info monitoring."""
    
    def __init__(self, config):
        """
        Initialize system info monitor.
        
        Args:
            config: Config instance
        """
        self.config = config
        self.running = False
        self.last_publish_time = None
        
        # Setup signal handlers
        signal.signal(signal.SIGTERM, self._signal_handler)
        signal.signal(signal.SIGINT, self._signal_handler)
    
    def _signal_handler(self, signum, frame):
        """Handle shutdown signals gracefully."""
        sig_name = signal.Signals(signum).name
        logging.info(f"Received {sig_name}, initiating graceful shutdown...")
        self.running = False
    
    def collect_and_publish_metrics(self):
        """Collect all system metrics and publish to MQTT."""
        logging.info("Collecting system metrics...")
        
        metrics_collected = 0
        metrics_published = 0
        
        # Collect and publish uptime
        uptime = SystemMetrics.get_uptime_hours()
        if uptime is not None:
            metrics_collected += 1
            logging.info(f"Uptime: {uptime} hours")
            if publish_sensor_value('system_uptime', uptime, unit='h'):
                metrics_published += 1
        
        # Collect and publish CPU temperature
        cpu_temp = SystemMetrics.get_cpu_temperature()
        if cpu_temp is not None:
            metrics_collected += 1
            logging.info(f"CPU Temperature: {cpu_temp}°C")
            if publish_sensor_value('system_cpu_temp', cpu_temp, unit='°C'):
                metrics_published += 1
        
        # Collect and publish memory usage
        memory_usage = SystemMetrics.get_memory_usage_percent()
        if memory_usage is not None:
            metrics_collected += 1
            logging.info(f"Memory Usage: {memory_usage}%")
            if publish_sensor_value('system_memory_usage', memory_usage, unit='%'):
                metrics_published += 1
        
        # Collect and publish disk usage
        disk_usage = SystemMetrics.get_disk_usage_percent()
        if disk_usage is not None:
            metrics_collected += 1
            logging.info(f"Disk Usage: {disk_usage}%")
            if publish_sensor_value('system_disk_usage', disk_usage, unit='%'):
                metrics_published += 1
        
        # Collect and publish CPU usage
        cpu_usage = SystemMetrics.get_cpu_usage_percent()
        if cpu_usage is not None:
            metrics_collected += 1
            logging.info(f"CPU Usage: {cpu_usage}%")
            if publish_sensor_value('system_cpu_usage', cpu_usage, unit='%'):
                metrics_published += 1
        
        logging.info(f"Metrics: {metrics_collected} collected, {metrics_published} published")
        
        # Update last publish time
        self.last_publish_time = time.time()
    
    def should_publish(self):
        """
        Check if it's time to publish metrics.
        
        Returns:
            bool: True if should publish, False otherwise
        """
        if self.last_publish_time is None:
            return True
        
        elapsed = time.time() - self.last_publish_time
        return elapsed >= self.config.PUBLISH_INTERVAL
    
    def run(self):
        """Main application loop."""
        self.running = True
        
        logging.info("System Info Monitor starting...")
        
        # Publish metrics immediately on startup
        try:
            self.collect_and_publish_metrics()
        except Exception as e:
            logging.error(f"Error during initial metrics collection: {e}")
        
        # Main loop
        while self.running:
            try:
                # Check if it's time to publish
                if self.should_publish():
                    self.collect_and_publish_metrics()
                
                # Sleep before next check
                time.sleep(self.config.MAIN_LOOP_SLEEP)
                
            except Exception as e:
                logging.error(f"Error in main loop: {e}")
                time.sleep(self.config.MAIN_LOOP_SLEEP)
        
        logging.info("System Info Monitor stopped")


# ============================================================================
# Entry Point
# ============================================================================

def main():
    """Main entry point."""
    try:
        # Load configuration
        config = Config()
        
        # Setup logging
        setup_logging(config)
        
        # Create and run monitor
        monitor = SystemInfoMonitor(config)
        monitor.run()
        
    except KeyboardInterrupt:
        logging.info("Interrupted by user")
        sys.exit(0)
    except Exception as e:
        logging.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
