#!/usr/bin/env python3
"""
Home Assistant MQTT Integration (Python Edition)

A Python-based MQTT bridge for Luigi modules to publish sensor data to
Home Assistant with automatic MQTT Discovery integration.

Features:
- MQTT connection management with automatic reconnection
- Home Assistant MQTT Discovery support
- Structured logging with rotation
- Graceful shutdown handling
- Configuration file support
- Mock MQTT for development

Hardware Requirements:
- Raspberry Pi with network connectivity (WiFi/Ethernet)
- Home Assistant instance with Mosquitto MQTT broker

Author: Luigi Project
License: MIT
"""

import sys
import os
import time
import signal
import logging
import json
import socket
import configparser
from pathlib import Path
from logging.handlers import RotatingFileHandler

# Try to import paho-mqtt, fall back to mock for development
try:
    import paho.mqtt.client as mqtt
    MOCK_MODE = False
except ImportError:
    # Mock MQTT for development/testing without paho-mqtt
    class MockMQTTClient:
        """Mock paho.mqtt.client for development without paho-mqtt installed."""
        
        MQTT_ERR_SUCCESS = 0
        
        def __init__(self, client_id="", clean_session=True, userdata=None):
            print(f"[MOCK] MQTT Client created: {client_id}")
            self._userdata = userdata
            self._connected = False
            
        def username_pw_set(self, username, password=None):
            print(f"[MOCK] Username set: {username}")
            
        def tls_set(self, ca_certs=None, certfile=None, keyfile=None):
            print(f"[MOCK] TLS enabled")
            
        def connect(self, host, port=1883, keepalive=60):
            print(f"[MOCK] Connecting to {host}:{port}")
            self._connected = True
            if self.on_connect:
                self.on_connect(self, self._userdata, {}, 0)
            return 0
            
        def disconnect(self):
            print(f"[MOCK] Disconnecting")
            self._connected = False
            if self.on_disconnect:
                self.on_disconnect(self, self._userdata, 0)
            return 0
            
        def publish(self, topic, payload=None, qos=0, retain=False):
            topic_safe = topic[:100] if topic else ""
            payload_safe = str(payload)[:100] if payload else ""
            print(f"[MOCK] Publish: {topic_safe} = {payload_safe}")
            # Return mock result with rc attribute
            class MockResult:
                rc = 0
            return MockResult()
            
        def subscribe(self, topic, qos=0):
            print(f"[MOCK] Subscribe: {topic}")
            return (0, 0)
            
        def loop_start(self):
            print(f"[MOCK] Loop started")
            
        def loop_stop(self):
            print(f"[MOCK] Loop stopped")
            
        def is_connected(self):
            return self._connected
            
        # Callback placeholders
        on_connect = None
        on_disconnect = None
        on_message = None
        on_publish = None
    
    mqtt = type('mqtt', (), {
        'Client': MockMQTTClient,
        'MQTT_ERR_SUCCESS': 0
    })()
    MOCK_MODE = True
    print("WARNING: Using mock MQTT (paho-mqtt not available)")


# ============================================================================
# Configuration
# ============================================================================

class Config:
    """Load application configuration from file with fallback to defaults."""
    
    # Default configuration values
    DEFAULT_BROKER_HOST = "localhost"
    DEFAULT_BROKER_PORT = 1883
    DEFAULT_TLS_ENABLED = False
    DEFAULT_USERNAME = ""
    DEFAULT_PASSWORD = ""
    DEFAULT_CLIENT_ID = "luigi-{HOSTNAME}"
    DEFAULT_KEEPALIVE = 60
    DEFAULT_QOS = 1
    DEFAULT_RECONNECT_DELAY = 5
    DEFAULT_TOPIC_PREFIX = "homeassistant"
    DEFAULT_STATE_TOPIC = "luigi/{HOSTNAME}"
    DEFAULT_AVAILABILITY_TOPIC = "luigi/{HOSTNAME}/availability"
    DEFAULT_DEVICE_NAME = "Luigi-{HOSTNAME}"
    DEFAULT_DEVICE_MANUFACTURER = "Luigi Project"
    DEFAULT_DEVICE_MODEL = "Raspberry Pi Zero W"
    DEFAULT_LOG_FILE = "/var/log/ha-mqtt-py.log"
    DEFAULT_LOG_LEVEL = "INFO"
    DEFAULT_LOG_MAX_BYTES = 10 * 1024 * 1024  # 10MB
    DEFAULT_LOG_BACKUP_COUNT = 5
    
    def __init__(self, module_path="iot/ha-mqtt-py"):
        """
        Initialize configuration from file or defaults.
        
        Args:
            module_path: Module path matching repository structure
        """
        self.module_path = module_path
        self.config_file = f"/etc/luigi/{module_path}/ha-mqtt-py.conf"
        self.hostname = socket.gethostname()
        self._load_config()
    
    def _load_config(self):
        """Load configuration from INI file or use defaults."""
        parser = configparser.ConfigParser()
        
        if os.path.exists(self.config_file):
            try:
                parser.read(self.config_file)
                
                # Broker Settings
                self.BROKER_HOST = parser.get('Broker', 'HOST', 
                                             fallback=self.DEFAULT_BROKER_HOST)
                self.BROKER_PORT = parser.getint('Broker', 'PORT',
                                                fallback=self.DEFAULT_BROKER_PORT)
                tls_enabled_str = parser.get('Broker', 'TLS_ENABLED',
                                            fallback=str(self.DEFAULT_TLS_ENABLED))
                self.TLS_ENABLED = tls_enabled_str.lower() in ('yes', 'true', '1')
                self.TLS_CA_CERT = parser.get('Broker', 'TLS_CA_CERT', fallback=None)
                self.TLS_CERT = parser.get('Broker', 'TLS_CERT', fallback=None)
                self.TLS_KEY = parser.get('Broker', 'TLS_KEY', fallback=None)
                
                # Authentication Settings
                self.USERNAME = parser.get('Authentication', 'USERNAME',
                                          fallback=self.DEFAULT_USERNAME)
                self.PASSWORD = parser.get('Authentication', 'PASSWORD',
                                          fallback=self.DEFAULT_PASSWORD)
                
                # Client Settings
                client_id_template = parser.get('Client', 'CLIENT_ID',
                                               fallback=self.DEFAULT_CLIENT_ID)
                self.CLIENT_ID = client_id_template.replace('{HOSTNAME}', self.hostname)
                self.KEEPALIVE = parser.getint('Client', 'KEEPALIVE',
                                              fallback=self.DEFAULT_KEEPALIVE)
                self.QOS = parser.getint('Client', 'QOS',
                                        fallback=self.DEFAULT_QOS)
                self.RECONNECT_DELAY = parser.getint('Client', 'RECONNECT_DELAY',
                                                    fallback=self.DEFAULT_RECONNECT_DELAY)
                
                # Topic Settings
                self.TOPIC_PREFIX = parser.get('Topics', 'TOPIC_PREFIX',
                                              fallback=self.DEFAULT_TOPIC_PREFIX)
                state_topic_template = parser.get('Topics', 'STATE_TOPIC',
                                                 fallback=self.DEFAULT_STATE_TOPIC)
                self.STATE_TOPIC = state_topic_template.replace('{HOSTNAME}', self.hostname)
                avail_topic_template = parser.get('Topics', 'AVAILABILITY_TOPIC',
                                                 fallback=self.DEFAULT_AVAILABILITY_TOPIC)
                self.AVAILABILITY_TOPIC = avail_topic_template.replace('{HOSTNAME}', self.hostname)
                
                # Discovery Settings
                device_name_template = parser.get('Discovery', 'DEVICE_NAME',
                                                 fallback=self.DEFAULT_DEVICE_NAME)
                self.DEVICE_NAME = device_name_template.replace('{HOSTNAME}', self.hostname)
                self.DEVICE_MANUFACTURER = parser.get('Discovery', 'DEVICE_MANUFACTURER',
                                                     fallback=self.DEFAULT_DEVICE_MANUFACTURER)
                self.DEVICE_MODEL = parser.get('Discovery', 'DEVICE_MODEL',
                                              fallback=self.DEFAULT_DEVICE_MODEL)
                
                # Logging Settings
                self.LOG_FILE = parser.get('Logging', 'LOG_FILE',
                                          fallback=self.DEFAULT_LOG_FILE)
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
        self.BROKER_HOST = self.DEFAULT_BROKER_HOST
        self.BROKER_PORT = self.DEFAULT_BROKER_PORT
        self.TLS_ENABLED = self.DEFAULT_TLS_ENABLED
        self.TLS_CA_CERT = None
        self.TLS_CERT = None
        self.TLS_KEY = None
        self.USERNAME = self.DEFAULT_USERNAME
        self.PASSWORD = self.DEFAULT_PASSWORD
        self.CLIENT_ID = self.DEFAULT_CLIENT_ID.replace('{HOSTNAME}', self.hostname)
        self.KEEPALIVE = self.DEFAULT_KEEPALIVE
        self.QOS = self.DEFAULT_QOS
        self.RECONNECT_DELAY = self.DEFAULT_RECONNECT_DELAY
        self.TOPIC_PREFIX = self.DEFAULT_TOPIC_PREFIX
        self.STATE_TOPIC = self.DEFAULT_STATE_TOPIC.replace('{HOSTNAME}', self.hostname)
        self.AVAILABILITY_TOPIC = self.DEFAULT_AVAILABILITY_TOPIC.replace('{HOSTNAME}', self.hostname)
        self.DEVICE_NAME = self.DEFAULT_DEVICE_NAME.replace('{HOSTNAME}', self.hostname)
        self.DEVICE_MANUFACTURER = self.DEFAULT_DEVICE_MANUFACTURER
        self.DEVICE_MODEL = self.DEFAULT_DEVICE_MODEL
        self.LOG_FILE = self.DEFAULT_LOG_FILE
        self.LOG_LEVEL = self._parse_log_level(self.DEFAULT_LOG_LEVEL)
        self.LOG_MAX_BYTES = self.DEFAULT_LOG_MAX_BYTES
        self.LOG_BACKUP_COUNT = self.DEFAULT_LOG_BACKUP_COUNT
    
    def _parse_log_level(self, level_str):
        """
        Convert log level string to logging constant.
        
        Args:
            level_str: String representation (DEBUG, INFO, WARNING, ERROR, CRITICAL)
            
        Returns:
            logging level constant (defaults to INFO for invalid values)
        """
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
# MQTT Client Manager
# ============================================================================

class MQTTClientManager:
    """
    MQTT connection management with paho-mqtt library.
    
    What: Manages MQTT broker connection, publishing, and callbacks
    Why: Abstracts MQTT complexity from application logic
    How: Uses paho-mqtt.Client with automatic reconnection
    Who: Used by Application class to publish data and handle events
    """
    
    def __init__(self, config):
        """
        Initialize MQTT client manager.
        
        Args:
            config: Config instance with MQTT settings
        """
        self.config = config
        self.client = None
        self.connected = False
        self.reconnect_attempts = 0
        
    def connect(self):
        """Connect to MQTT broker with authentication and TLS if configured."""
        try:
            # Create MQTT client
            self.client = mqtt.Client(client_id=self.config.CLIENT_ID)
            
            # Set up callbacks
            self.client.on_connect = self._on_connect
            self.client.on_disconnect = self._on_disconnect
            
            # Set authentication if provided
            if self.config.USERNAME:
                self.client.username_pw_set(
                    self.config.USERNAME,
                    self.config.PASSWORD if self.config.PASSWORD else None
                )
                logging.info(f"Authentication configured for user: {self.config.USERNAME}")
            
            # Set up TLS if enabled
            if self.config.TLS_ENABLED:
                self.client.tls_set(
                    ca_certs=self.config.TLS_CA_CERT,
                    certfile=self.config.TLS_CERT,
                    keyfile=self.config.TLS_KEY
                )
                logging.info("TLS encryption enabled")
            
            # Connect to broker
            logging.info(f"Connecting to MQTT broker at {self.config.BROKER_HOST}:{self.config.BROKER_PORT}")
            self.client.connect(
                self.config.BROKER_HOST,
                self.config.BROKER_PORT,
                self.config.KEEPALIVE
            )
            
            # Start network loop in background thread
            self.client.loop_start()
            
            return True
            
        except Exception as e:
            logging.error(f"Failed to connect to MQTT broker: {e}")
            self.reconnect_attempts += 1
            return False
    
    def disconnect(self):
        """Disconnect from MQTT broker gracefully."""
        if self.client and self.connected:
            try:
                # Publish offline status
                self.publish(
                    self.config.AVAILABILITY_TOPIC,
                    "offline",
                    retain=True
                )
                
                # Stop loop and disconnect
                self.client.loop_stop()
                self.client.disconnect()
                logging.info("Disconnected from MQTT broker")
            except Exception as e:
                logging.error(f"Error during disconnect: {e}")
    
    def publish(self, topic, payload, qos=None, retain=False):
        """
        Publish message to MQTT topic.
        
        Args:
            topic: MQTT topic string
            payload: Message payload (string or bytes)
            qos: Quality of Service (0, 1, or 2), defaults to config QOS
            retain: Retain message on broker
            
        Returns:
            bool: True if publish successful, False otherwise
        """
        if not self.client:
            logging.error("Cannot publish: MQTT client not initialized")
            return False
        
        if qos is None:
            qos = self.config.QOS
        
        try:
            # Validate and sanitize topic
            if not topic or not isinstance(topic, str):
                logging.error("Invalid topic")
                return False
            
            # Sanitize for logging (limit length)
            topic_log = topic[:100] if len(topic) > 100 else topic
            payload_log = str(payload)[:200] if payload and len(str(payload)) > 200 else str(payload)
            
            result = self.client.publish(topic, payload, qos=qos, retain=retain)
            
            if result.rc == mqtt.MQTT_ERR_SUCCESS:
                logging.debug(f"Published to {topic_log}: {payload_log}")
                return True
            else:
                logging.warning(f"Publish failed with code {result.rc}")
                return False
                
        except Exception as e:
            logging.error(f"Error publishing message: {e}")
            return False
    
    def subscribe(self, topic, callback=None):
        """
        Subscribe to MQTT topic.
        
        Args:
            topic: MQTT topic string
            callback: Function to call on message received
            
        Returns:
            bool: True if subscribe successful, False otherwise
        """
        if not self.client:
            logging.error("Cannot subscribe: MQTT client not initialized")
            return False
        
        try:
            result = self.client.subscribe(topic, qos=self.config.QOS)
            
            if result[0] == mqtt.MQTT_ERR_SUCCESS:
                logging.info(f"Subscribed to topic: {topic}")
                if callback:
                    self.client.on_message = callback
                return True
            else:
                logging.warning(f"Subscribe failed with code {result[0]}")
                return False
                
        except Exception as e:
            logging.error(f"Error subscribing to topic: {e}")
            return False
    
    def is_connected(self):
        """Check if client is connected to broker."""
        return self.connected and self.client and self.client.is_connected()
    
    def _on_connect(self, client, userdata, flags, rc):
        """Callback when connection established."""
        if rc == 0:
            self.connected = True
            self.reconnect_attempts = 0
            logging.info("Successfully connected to MQTT broker")
            
            # Publish online status
            self.publish(
                self.config.AVAILABILITY_TOPIC,
                "online",
                retain=True
            )
        else:
            self.connected = False
            logging.error(f"Connection failed with code {rc}")
    
    def _on_disconnect(self, client, userdata, rc):
        """Callback when disconnected from broker."""
        self.connected = False
        if rc != 0:
            logging.warning(f"Unexpected disconnect (code {rc}), will attempt to reconnect")
        else:
            logging.info("Disconnected from MQTT broker")


# ============================================================================
# Discovery Manager
# ============================================================================

class DiscoveryManager:
    """
    Home Assistant MQTT Discovery integration.
    
    What: Generates and publishes HA Discovery configuration messages
    Why: Enables automatic sensor registration without manual YAML config
    How: Constructs JSON payloads following HA Discovery spec
    Who: Used by Application and external modules to register sensors
    """
    
    def __init__(self, mqtt_client, config):
        """
        Initialize discovery manager.
        
        Args:
            mqtt_client: MQTTClientManager instance
            config: Config instance
        """
        self.mqtt_client = mqtt_client
        self.config = config
        self.registered_sensors = set()
    
    def register_sensor(self, sensor_id, name, device_class=None, 
                       unit=None, icon=None, state_topic=None, state_class=None):
        """
        Register sensor with Home Assistant Discovery.
        
        Args:
            sensor_id: Unique sensor identifier (alphanumeric, underscore, hyphen)
            name: Human-readable sensor name
            device_class: HA device class (temperature, humidity, etc.)
            unit: Unit of measurement (°C, %, etc.)
            icon: Material Design Icon (mdi:icon-name)
            state_topic: MQTT topic for sensor state (default: config.STATE_TOPIC/sensor_id)
            state_class: State class (measurement, total, total_increasing)
            
        Returns:
            bool: True if registration successful, False otherwise
        """
        try:
            # Validate sensor_id (alphanumeric, underscore, hyphen only)
            if not sensor_id or not isinstance(sensor_id, str):
                logging.error("Invalid sensor_id")
                return False
            
            import re
            if not re.match(r'^[a-zA-Z0-9_-]+$', sensor_id):
                logging.error(f"Invalid sensor_id format: {sensor_id}")
                return False
            
            # Build discovery topic
            node_id = self.config.CLIENT_ID
            discovery_topic = f"{self.config.TOPIC_PREFIX}/sensor/{node_id}/{sensor_id}/config"
            
            # Build state topic
            if not state_topic:
                state_topic = f"{self.config.STATE_TOPIC}/{sensor_id}"
            
            # Build device info
            device_info = {
                "identifiers": [node_id],
                "name": self.config.DEVICE_NAME,
                "manufacturer": self.config.DEVICE_MANUFACTURER,
                "model": self.config.DEVICE_MODEL
            }
            
            # Build discovery payload
            discovery_payload = {
                "name": name,
                "state_topic": state_topic,
                "unique_id": f"{node_id}_{sensor_id}",
                "device": device_info,
                "availability_topic": self.config.AVAILABILITY_TOPIC
            }
            
            # Add optional fields
            if device_class:
                discovery_payload["device_class"] = device_class
            if unit:
                discovery_payload["unit_of_measurement"] = unit
            if icon:
                discovery_payload["icon"] = icon
            if state_class:
                discovery_payload["state_class"] = state_class
            
            # Publish discovery config
            payload_json = json.dumps(discovery_payload)
            success = self.mqtt_client.publish(
                discovery_topic,
                payload_json,
                retain=True
            )
            
            if success:
                self.registered_sensors.add(sensor_id)
                logging.info(f"Registered sensor: {sensor_id} ({name})")
                return True
            else:
                logging.error(f"Failed to register sensor: {sensor_id}")
                return False
                
        except Exception as e:
            logging.error(f"Error registering sensor: {e}")
            return False
    
    def register_binary_sensor(self, sensor_id, name, device_class="motion",
                              icon=None, state_topic=None):
        """
        Register binary sensor (ON/OFF) with Home Assistant Discovery.
        
        Args:
            sensor_id: Unique sensor identifier
            name: Human-readable sensor name
            device_class: Binary sensor class (motion, door, window, etc.)
            icon: Material Design Icon
            state_topic: MQTT topic for sensor state
            
        Returns:
            bool: True if registration successful, False otherwise
        """
        try:
            # Validate sensor_id
            if not sensor_id or not isinstance(sensor_id, str):
                logging.error("Invalid sensor_id")
                return False
            
            import re
            if not re.match(r'^[a-zA-Z0-9_-]+$', sensor_id):
                logging.error(f"Invalid sensor_id format: {sensor_id}")
                return False
            
            # Build discovery topic (binary_sensor component)
            node_id = self.config.CLIENT_ID
            discovery_topic = f"{self.config.TOPIC_PREFIX}/binary_sensor/{node_id}/{sensor_id}/config"
            
            # Build state topic
            if not state_topic:
                state_topic = f"{self.config.STATE_TOPIC}/{sensor_id}"
            
            # Build device info
            device_info = {
                "identifiers": [node_id],
                "name": self.config.DEVICE_NAME,
                "manufacturer": self.config.DEVICE_MANUFACTURER,
                "model": self.config.DEVICE_MODEL
            }
            
            # Build discovery payload
            discovery_payload = {
                "name": name,
                "state_topic": state_topic,
                "unique_id": f"{node_id}_{sensor_id}",
                "device": device_info,
                "device_class": device_class,
                "availability_topic": self.config.AVAILABILITY_TOPIC,
                "payload_on": "ON",
                "payload_off": "OFF"
            }
            
            # Add optional icon
            if icon:
                discovery_payload["icon"] = icon
            
            # Publish discovery config
            payload_json = json.dumps(discovery_payload)
            success = self.mqtt_client.publish(
                discovery_topic,
                payload_json,
                retain=True
            )
            
            if success:
                self.registered_sensors.add(sensor_id)
                logging.info(f"Registered binary sensor: {sensor_id} ({name})")
                return True
            else:
                logging.error(f"Failed to register binary sensor: {sensor_id}")
                return False
                
        except Exception as e:
            logging.error(f"Error registering binary sensor: {e}")
            return False
    
    def unregister_sensor(self, sensor_id):
        """
        Remove sensor from Home Assistant (publish empty config).
        
        Args:
            sensor_id: Sensor identifier to remove
            
        Returns:
            bool: True if unregistration successful, False otherwise
        """
        try:
            node_id = self.config.CLIENT_ID
            
            # Try both sensor and binary_sensor topics
            for component in ['sensor', 'binary_sensor']:
                discovery_topic = f"{self.config.TOPIC_PREFIX}/{component}/{node_id}/{sensor_id}/config"
                self.mqtt_client.publish(discovery_topic, "", retain=True)
            
            if sensor_id in self.registered_sensors:
                self.registered_sensors.remove(sensor_id)
            
            logging.info(f"Unregistered sensor: {sensor_id}")
            return True
            
        except Exception as e:
            logging.error(f"Error unregistering sensor: {e}")
            return False


# ============================================================================
# Main Application
# ============================================================================

class HAMQTTApplication:
    """
    Main application orchestrating MQTT integration.
    
    What: Main entry point coordinating all components
    Why: Provides clean application lifecycle management
    How: Initializes components, runs main loop, handles shutdown
    Who: Called by main() function, managed by systemd
    """
    
    def __init__(self):
        """Initialize application."""
        self.config = None
        self.mqtt_client = None
        self.discovery_manager = None
        self.running = False
    
    def initialize(self):
        """Initialize all components."""
        logging.info("Initializing Home Assistant MQTT application...")
        
        # Load configuration (already loaded, but ensure it's available)
        if not self.config:
            logging.error("Configuration not loaded")
            return False
        
        # Initialize MQTT client
        self.mqtt_client = MQTTClientManager(self.config)
        
        # Connect to broker
        if not self.mqtt_client.connect():
            logging.error("Failed to connect to MQTT broker")
            return False
        
        # Wait a moment for connection to establish
        time.sleep(1)
        
        # Initialize discovery manager
        self.discovery_manager = DiscoveryManager(self.mqtt_client, self.config)
        
        logging.info("Application initialized successfully")
        return True
    
    def run(self):
        """Main application loop."""
        logging.info("Starting Home Assistant MQTT service...")
        self.running = True
        
        try:
            # Main loop - keep running and handle reconnections
            while self.running:
                # Check connection status
                if not self.mqtt_client.is_connected():
                    logging.warning("Connection lost, attempting to reconnect...")
                    time.sleep(self.config.RECONNECT_DELAY)
                    self.mqtt_client.connect()
                
                # Sleep for a reasonable interval
                time.sleep(10)
                
        except KeyboardInterrupt:
            logging.info("Keyboard interrupt received")
        finally:
            self.stop()
    
    def stop(self):
        """Stop application and clean up resources."""
        if not self.running:
            return
        
        logging.info("Stopping Home Assistant MQTT service...")
        self.running = False
        
        # Disconnect MQTT client
        if self.mqtt_client:
            self.mqtt_client.disconnect()
        
        logging.info("Home Assistant MQTT service stopped")


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
    config = Config(module_path="iot/ha-mqtt-py")
    
    # Setup logging with config
    setup_logging(config)
    logging.info("=" * 60)
    logging.info("Home Assistant MQTT Integration (Python) Starting")
    logging.info("=" * 60)
    
    if MOCK_MODE:
        logging.warning("Running in MOCK MODE - no actual MQTT connection")
    
    # Register signal handlers
    signal.signal(signal.SIGINT, signal_handler)   # Ctrl+C
    signal.signal(signal.SIGTERM, signal_handler)  # kill command
    
    # Create and initialize application
    try:
        app_instance = HAMQTTApplication()
        app_instance.config = config
        
        if not app_instance.initialize():
            logging.error("Application initialization failed")
            sys.exit(1)
        
        # Run main loop
        app_instance.run()
        
    except Exception as e:
        logging.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)
    
    logging.info("Application exited normally")


if __name__ == '__main__':
    main()
