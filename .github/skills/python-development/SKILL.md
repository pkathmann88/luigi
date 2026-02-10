---
name: python-development
description: Comprehensive guide for Python development on Raspberry Pi Zero W with hardware integration. Use this skill when developing, debugging, or improving Python code that interacts with GPIO, sensors, or other hardware components.
license: MIT
---

# Python Development for Raspberry Pi Hardware Projects

This skill provides comprehensive guidance for developing Python applications that interact with Raspberry Pi Zero W hardware, including GPIO programming, code structure, testing strategies, error handling, and deployment practices.

## When to Use This Skill

Use this skill when:
- Developing new Python code for GPIO or hardware interactions
- Debugging hardware-related Python applications
- Improving existing hardware control code
- Implementing sensors, actuators, or other hardware interfaces
- Structuring Python projects for embedded systems
- Planning testing strategies for hardware-dependent code
- Deploying Python applications to Raspberry Pi

## Python Environment for Raspberry Pi

### Python Version Considerations

**Current Project Configuration:**
- **Shebang**: `#!/usr/bin/python` (points to Python 2.x on Raspberry Pi OS)
- **Development**: Python 3.x available via `python3`
- **Compatibility**: Code should work on both Python 2.7 and 3.x when possible

**Recommendations for New Code:**
- Use Python 3.x syntax for new development
- Test on target Raspberry Pi OS version
- Consider using `#!/usr/bin/env python3` for new scripts
- Document Python version requirements clearly

### Required Libraries

**Core GPIO Library:**
```bash
# Install RPi.GPIO for Python 3
sudo apt-get install python3-rpi.gpio

# Install RPi.GPIO for Python 2
sudo apt-get install python-rpi.gpio
```

**Common Additional Libraries:**
```bash
# For I2C/SMBus devices
sudo apt-get install python3-smbus i2c-tools

# For SPI devices
sudo apt-get install python3-spidev

# For system utilities
sudo apt-get install python3-psutil

# For configuration files
sudo apt-get install python3-yaml python3-configparser
```

## Code Structure Best Practices

### Project Organization

```
project-name/
├── project_name.py          # Main application script
├── config.py                # Configuration constants
├── hardware/                # Hardware abstraction modules
│   ├── __init__.py
│   ├── gpio_manager.py      # GPIO setup and management
│   └── sensors.py           # Sensor interfaces
├── utils/                   # Utility functions
│   ├── __init__.py
│   ├── logging_config.py    # Logging setup
│   └── file_utils.py        # File operations
├── tests/                   # Test scripts (syntax validation)
│   └── test_syntax.py
└── README.md                # Documentation
```

### Configuration Management

**Luigi modules MUST use configuration files in `/etc/luigi/{module-path}/`:**

The configuration path follows the repository structure. For a module at `motion-detection/mario/`, the config file is `/etc/luigi/motion-detection/mario/mario.conf`.

**Configuration File Format (INI-style):**

```ini
# /etc/luigi/motion-detection/mario/mario.conf
# Mario Motion Detection Configuration

[GPIO]
# GPIO pin for PIR sensor (BCM numbering)
SENSOR_PIN=23

[Timing]
# Cooldown period in seconds (30 minutes = 1800)
COOLDOWN_SECONDS=1800
# Main loop sleep interval
MAIN_LOOP_SLEEP=100

[Files]
# Sound directory
SOUND_DIR=/usr/share/sounds/mario/
# Timer file location
TIMER_FILE=/tmp/mario_timer
# Log file location
LOG_FILE=/var/log/motion.log

[Logging]
# Log level (DEBUG, INFO, WARNING, ERROR)
LOG_LEVEL=INFO
# Maximum log file size in bytes
LOG_MAX_BYTES=10485760
# Number of backup log files
LOG_BACKUP_COUNT=5
```

**Python Config Loader Pattern:**

```python
#!/usr/bin/env python3
"""Configuration loader for Luigi modules."""
import os
import configparser
from pathlib import Path

class Config:
    """Load configuration from file with fallback to defaults."""
    
    # Default configuration values
    DEFAULT_SENSOR_PIN = 23
    DEFAULT_COOLDOWN_SECONDS = 1800
    DEFAULT_SOUND_DIR = "/usr/share/sounds/mario/"
    DEFAULT_LOG_FILE = "/var/log/motion.log"
    DEFAULT_LOG_LEVEL = "INFO"
    
    def __init__(self, module_path="motion-detection/mario"):
        """
        Initialize configuration.
        
        Args:
            module_path: Module path matching repository structure
                        (e.g., "motion-detection/mario", "sensors/temp")
        """
        self.module_path = module_path
        self.config_file = f"/etc/luigi/{module_path}/config.conf"
        self._load_config()
    
    def _load_config(self):
        """Load configuration from file or use defaults."""
        parser = configparser.ConfigParser()
        
        if os.path.exists(self.config_file):
            try:
                parser.read(self.config_file)
                self.SENSOR_PIN = parser.getint('GPIO', 'SENSOR_PIN', 
                                                 fallback=self.DEFAULT_SENSOR_PIN)
                self.COOLDOWN_SECONDS = parser.getint('Timing', 'COOLDOWN_SECONDS',
                                                       fallback=self.DEFAULT_COOLDOWN_SECONDS)
                self.SOUND_DIR = parser.get('Files', 'SOUND_DIR',
                                             fallback=self.DEFAULT_SOUND_DIR)
                self.LOG_FILE = parser.get('Files', 'LOG_FILE',
                                            fallback=self.DEFAULT_LOG_FILE)
                self.LOG_LEVEL = parser.get('Logging', 'LOG_LEVEL',
                                             fallback=self.DEFAULT_LOG_LEVEL)
                print(f"Configuration loaded from {self.config_file}")
            except Exception as e:
                print(f"Warning: Error reading config file: {e}")
                print("Using default configuration")
                self._use_defaults()
        else:
            print(f"Config file not found: {self.config_file}")
            print("Using default configuration")
            self._use_defaults()
    
    def _use_defaults(self):
        """Set all values to defaults."""
        self.SENSOR_PIN = self.DEFAULT_SENSOR_PIN
        self.COOLDOWN_SECONDS = self.DEFAULT_COOLDOWN_SECONDS
        self.SOUND_DIR = self.DEFAULT_SOUND_DIR
        self.LOG_FILE = self.DEFAULT_LOG_FILE
        self.LOG_LEVEL = self.DEFAULT_LOG_LEVEL

# Usage in main code
config = Config(module_path="motion-detection/mario")
GPIO.setup(config.SENSOR_PIN, GPIO.IN)
```

**Alternative: Simple Key=Value Parser (No Dependencies):**

```python
def load_config(config_file, defaults):
    """
    Load simple key=value config file.
    
    Args:
        config_file: Path to config file
        defaults: Dictionary of default values
        
    Returns:
        Dictionary of configuration values
    """
    config = defaults.copy()
    
    if not os.path.exists(config_file):
        return config
    
    try:
        with open(config_file, 'r') as f:
            for line in f:
                line = line.strip()
                # Skip comments and empty lines
                if not line or line.startswith('#'):
                    continue
                # Parse key=value
                if '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip()
                    # Convert types
                    if value.isdigit():
                        config[key] = int(value)
                    elif value.lower() in ('true', 'false'):
                        config[key] = value.lower() == 'true'
                    else:
                        config[key] = value
    except Exception as e:
        print(f"Warning: Error reading config: {e}")
    
    return config

# Usage
defaults = {
    'SENSOR_PIN': 23,
    'COOLDOWN_SECONDS': 1800,
    'SOUND_DIR': '/usr/share/sounds/mario/',
    'LOG_FILE': '/var/log/motion.log'
}
config = load_config('/etc/luigi/motion-detection/mario/mario.conf', defaults)
GPIO.setup(config['SENSOR_PIN'], GPIO.IN)
```

### Hardware Abstraction Pattern

**Create abstraction layer for hardware:**

```python
# hardware/gpio_manager.py
"""GPIO management and abstraction."""
import RPi.GPIO as GPIO
import logging

class GPIOManager:
    """Manages GPIO setup and cleanup."""
    
    def __init__(self, mode=GPIO.BCM):
        """Initialize GPIO with specified mode."""
        self.mode = mode
        self.initialized = False
        self.pins_in_use = []
    
    def initialize(self):
        """Set up GPIO mode."""
        try:
            GPIO.setmode(self.mode)
            self.initialized = True
            logging.info(f"GPIO initialized with mode: {self.mode}")
        except RuntimeError as e:
            logging.error(f"Failed to initialize GPIO: {e}")
            raise
    
    def setup_input(self, pin, pull_up_down=None):
        """Configure pin as input."""
        if not self.initialized:
            raise RuntimeError("GPIO not initialized")
        
        kwargs = {}
        if pull_up_down is not None:
            kwargs['pull_up_down'] = pull_up_down
        
        GPIO.setup(pin, GPIO.IN, **kwargs)
        self.pins_in_use.append(pin)
        logging.debug(f"Pin {pin} configured as input")
    
    def setup_output(self, pin, initial=GPIO.LOW):
        """Configure pin as output."""
        if not self.initialized:
            raise RuntimeError("GPIO not initialized")
        
        GPIO.setup(pin, GPIO.OUT, initial=initial)
        self.pins_in_use.append(pin)
        logging.debug(f"Pin {pin} configured as output")
    
    def cleanup(self):
        """Clean up GPIO resources."""
        if self.initialized:
            GPIO.cleanup()
            self.initialized = False
            logging.info("GPIO cleaned up")
```

**Sensor abstraction example:**

```python
# hardware/sensors.py
"""Sensor interface classes."""
import RPi.GPIO as GPIO
import logging

class PIRSensor:
    """PIR motion sensor interface."""
    
    def __init__(self, pin, callback=None):
        """
        Initialize PIR sensor.
        
        Args:
            pin: GPIO pin number (BCM mode)
            callback: Function to call on motion detection
        """
        self.pin = pin
        self.callback = callback
        self._event_registered = False
    
    def start(self):
        """Start monitoring for motion."""
        if self.callback is None:
            raise ValueError("Callback function required")
        
        try:
            GPIO.add_event_detect(
                self.pin,
                GPIO.RISING,
                callback=self.callback
            )
            self._event_registered = True
            logging.info(f"PIR sensor started on pin {self.pin}")
        except RuntimeError as e:
            logging.error(f"Failed to start PIR sensor: {e}")
            raise
    
    def stop(self):
        """Stop monitoring for motion."""
        if self._event_registered:
            GPIO.remove_event_detect(self.pin)
            self._event_registered = False
            logging.info(f"PIR sensor stopped on pin {self.pin}")
    
    @staticmethod
    def read_state(pin):
        """Read current sensor state."""
        return GPIO.input(pin)
```

## Error Handling Patterns

### GPIO Access Errors

**Always handle permission errors:**

```python
import sys
import RPi.GPIO as GPIO

try:
    GPIO.setmode(GPIO.BCM)
except RuntimeError as e:
    print(f"Error: {e}")
    print("GPIO requires root access. Run with: sudo python3 script.py")
    sys.exit(1)
```

### Hardware Initialization

**Robust initialization with retries:**

```python
import time
import logging

def initialize_hardware(max_retries=3):
    """Initialize hardware with retry logic."""
    for attempt in range(max_retries):
        try:
            GPIO.setmode(GPIO.BCM)
            GPIO.setup(SENSOR_PIN, GPIO.IN)
            logging.info("Hardware initialized successfully")
            return True
        except Exception as e:
            logging.warning(f"Initialization attempt {attempt + 1} failed: {e}")
            if attempt < max_retries - 1:
                time.sleep(1)
            else:
                logging.error("Failed to initialize hardware after retries")
                raise
    return False
```

### Graceful Shutdown

**Always implement cleanup:**

```python
import signal
import sys
import RPi.GPIO as GPIO

def signal_handler(sig, frame):
    """Handle shutdown signals gracefully."""
    print("\nShutdown signal received...")
    GPIO.cleanup()
    sys.exit(0)

# Register signal handlers
signal.signal(signal.SIGINT, signal_handler)   # Ctrl+C
signal.signal(signal.SIGTERM, signal_handler)  # kill command

try:
    # Main application logic
    while True:
        time.sleep(1)
finally:
    # Cleanup on any exit
    GPIO.cleanup()
```

### File Operation Safety

**Handle file operations robustly:**

```python
import os
from pathlib import Path

def safe_write_file(filepath, content):
    """Write file with error handling."""
    try:
        # Ensure directory exists
        Path(filepath).parent.mkdir(parents=True, exist_ok=True)
        
        # Write to temporary file first
        temp_path = f"{filepath}.tmp"
        with open(temp_path, 'w') as f:
            f.write(content)
        
        # Atomic rename
        os.replace(temp_path, filepath)
        return True
    except IOError as e:
        logging.error(f"Failed to write {filepath}: {e}")
        return False

def safe_read_file(filepath, default=None):
    """Read file with error handling."""
    try:
        with open(filepath, 'r') as f:
            return f.read().strip()
    except FileNotFoundError:
        logging.debug(f"File not found: {filepath}")
        return default
    except IOError as e:
        logging.error(f"Failed to read {filepath}: {e}")
        return default
```

## Logging Best Practices

### Structured Logging Setup

```python
import logging
import sys
from logging.handlers import RotatingFileHandler

def setup_logging(log_file='/var/log/application.log', level=logging.INFO):
    """Configure application logging."""
    
    # Create logger
    logger = logging.getLogger()
    logger.setLevel(level)
    
    # Console handler (for development)
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.INFO)
    console_format = logging.Formatter(
        '%(levelname)s: %(message)s'
    )
    console_handler.setFormatter(console_format)
    
    # File handler (for production)
    try:
        file_handler = RotatingFileHandler(
            log_file,
            maxBytes=10*1024*1024,  # 10MB
            backupCount=5
        )
        file_handler.setLevel(level)
        file_format = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        file_handler.setFormatter(file_format)
        logger.addHandler(file_handler)
    except PermissionError:
        logging.warning(f"Cannot write to {log_file}, using console only")
    
    logger.addHandler(console_handler)
    return logger

# Usage
logger = setup_logging()
logger.info("Application started")
```

### Logging Hardware Events

```python
import logging

# Log hardware events with context
logging.info(f"Motion detected on GPIO{SENSOR_PIN}")
logging.debug(f"Sensor state: {GPIO.input(SENSOR_PIN)}")
logging.warning(f"Cooldown period active, ignoring motion")
logging.error(f"Failed to play sound: {error}")

# Log with timing information
start_time = time.time()
# ... operation ...
elapsed = time.time() - start_time
logging.info(f"Operation completed in {elapsed:.2f}s")
```

## Testing and Validation

### Syntax Validation (No Hardware Required)

**Always validate syntax before deployment:**

```bash
# Python syntax check
python3 -m py_compile script.py

# Check all Python files in project
find . -name "*.py" -exec python3 -m py_compile {} \;

# Use pylint for code quality (if available)
pylint script.py

# Use flake8 for style checking (if available)
flake8 script.py
```

### Mock GPIO for Development

**Test logic without hardware:**

```python
# test_mock_gpio.py
"""Test script using mock GPIO for development."""

class MockGPIO:
    """Mock RPi.GPIO for testing without hardware."""
    
    BCM = "BCM"
    BOARD = "BOARD"
    IN = "IN"
    OUT = "OUT"
    HIGH = 1
    LOW = 0
    RISING = "RISING"
    FALLING = "FALLING"
    
    _mode = None
    _pins = {}
    _callbacks = {}
    
    @classmethod
    def setmode(cls, mode):
        cls._mode = mode
        print(f"[MOCK] GPIO mode set to {mode}")
    
    @classmethod
    def setup(cls, pin, direction, **kwargs):
        cls._pins[pin] = direction
        print(f"[MOCK] Pin {pin} configured as {direction}")
    
    @classmethod
    def input(cls, pin):
        return cls._pins.get(pin, cls.LOW)
    
    @classmethod
    def output(cls, pin, state):
        print(f"[MOCK] Pin {pin} set to {state}")
    
    @classmethod
    def add_event_detect(cls, pin, edge, callback=None):
        cls._callbacks[pin] = callback
        print(f"[MOCK] Event detect added on pin {pin}")
    
    @classmethod
    def cleanup(cls):
        cls._pins.clear()
        cls._callbacks.clear()
        print("[MOCK] GPIO cleaned up")

# Use mock in development
try:
    import RPi.GPIO as GPIO
except (ImportError, RuntimeError):
    GPIO = MockGPIO
    print("Using mock GPIO (no hardware available)")
```

### Unit Testing Approach

```python
# tests/test_logic.py
"""Test application logic without hardware dependencies."""
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

def test_cooldown_logic():
    """Test cooldown calculation."""
    from config import COOLDOWN_SECONDS
    import time
    
    # Simulate timestamp logic
    last_trigger = int(time.time()) - 2000  # 2000 seconds ago
    now = int(time.time())
    should_trigger = (now - last_trigger) >= COOLDOWN_SECONDS
    
    assert should_trigger == True, "Cooldown should have expired"
    print("✓ Cooldown logic test passed")

def test_file_operations():
    """Test file read/write logic."""
    import tempfile
    
    # Test writing and reading
    with tempfile.NamedTemporaryFile(mode='w', delete=False) as f:
        test_file = f.name
        f.write("test123")
    
    with open(test_file, 'r') as f:
        content = f.read()
    
    os.unlink(test_file)
    assert content == "test123", "File content should match"
    print("✓ File operations test passed")

if __name__ == '__main__':
    test_cooldown_logic()
    test_file_operations()
    print("\nAll tests passed!")
```

### Integration Testing on Hardware

```python
# tests/test_hardware.py
"""Integration tests - run on actual Raspberry Pi."""
import RPi.GPIO as GPIO
import time
import sys

def test_gpio_setup():
    """Test GPIO initialization."""
    try:
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(23, GPIO.IN)
        print("✓ GPIO setup successful")
        return True
    except Exception as e:
        print(f"✗ GPIO setup failed: {e}")
        return False
    finally:
        GPIO.cleanup()

def test_sensor_read():
    """Test reading sensor state."""
    try:
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(23, GPIO.IN)
        state = GPIO.input(23)
        print(f"✓ Sensor read successful: {state}")
        return True
    except Exception as e:
        print(f"✗ Sensor read failed: {e}")
        return False
    finally:
        GPIO.cleanup()

if __name__ == '__main__':
    print("Running hardware integration tests...")
    print("Note: Requires actual Raspberry Pi with hardware connected\n")
    
    if not test_gpio_setup():
        sys.exit(1)
    
    if not test_sensor_read():
        sys.exit(1)
    
    print("\nAll hardware tests passed!")
```

## Development Workflow

### Local Development (Without Hardware)

1. **Write and validate syntax:**
   ```bash
   python3 -m py_compile script.py
   ```

2. **Run with mock GPIO:**
   ```bash
   # Use mock GPIO class for logic testing
   python3 script.py  # Will use MockGPIO if RPi.GPIO unavailable
   ```

3. **Test logic components:**
   ```bash
   python3 tests/test_logic.py
   ```

4. **Code review and linting:**
   ```bash
   # If available
   pylint script.py
   flake8 script.py
   ```

### Deployment to Raspberry Pi

1. **Transfer code to Raspberry Pi:**
   ```bash
   # Using scp
   scp script.py pi@raspberrypi.local:~/project/
   
   # Or using rsync (better for projects)
   rsync -av --exclude='*.pyc' --exclude='.git' \
         project/ pi@raspberrypi.local:~/project/
   ```

2. **Install dependencies on Pi:**
   ```bash
   ssh pi@raspberrypi.local
   cd ~/project
   sudo apt-get update
   sudo apt-get install python3-rpi.gpio
   ```

3. **Run integration tests:**
   ```bash
   sudo python3 tests/test_hardware.py
   ```

4. **Test application:**
   ```bash
   sudo python3 script.py
   ```

5. **Deploy as service (if needed):**
   ```bash
   sudo cp service_script /etc/init.d/service_name
   sudo chmod +x /etc/init.d/service_name
   sudo update-rc.d service_name defaults
   ```

### Debugging Hardware Issues

**Enable debug logging:**
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

**Test GPIO states interactively:**
```python
#!/usr/bin/env python3
import RPi.GPIO as GPIO
import time

GPIO.setmode(GPIO.BCM)
GPIO.setup(23, GPIO.IN)

print("Reading GPIO23 state (Ctrl+C to exit):")
try:
    while True:
        state = GPIO.input(23)
        print(f"State: {state}", end='\r')
        time.sleep(0.1)
except KeyboardInterrupt:
    pass
finally:
    GPIO.cleanup()
```

**Monitor system logs:**
```bash
# Watch application logs
tail -f /var/log/motion.log

# Check system messages
dmesg | tail -20

# View service status
sudo systemctl status service_name
```

## Performance Optimization

### Efficient Event Handling

**Use event detection instead of polling:**

```python
# Good: Event-driven (efficient, low CPU usage)
GPIO.add_event_detect(SENSOR_PIN, GPIO.RISING, callback=handler)
while True:
    time.sleep(100)  # Sleep most of the time

# Bad: Polling (wastes CPU)
while True:
    if GPIO.input(SENSOR_PIN):
        handler()
    time.sleep(0.1)  # Still uses CPU checking constantly
```

### Memory Management

```python
# Use context managers for files
with open(TIMER_FILE, 'w') as f:
    f.write(str(timestamp))

# Close resources explicitly if not using context managers
file_handle = open(LOG_FILE, 'a')
try:
    file_handle.write(log_entry)
finally:
    file_handle.close()
```

### Minimize External Process Calls

```python
# Instead of: os.system('aplay sound.wav')
# Use subprocess for better control:
import subprocess

result = subprocess.run(
    ['aplay', sound_file],
    capture_output=True,
    timeout=10
)

if result.returncode != 0:
    logging.error(f"Audio playback failed: {result.stderr}")
```

## Security Considerations

### Input Validation

```python
def validate_sound_file(filename):
    """Validate sound file path to prevent injection."""
    import re
    
    # Only allow safe characters
    if not re.match(r'^[a-zA-Z0-9_\-\.]+$', filename):
        raise ValueError("Invalid filename")
    
    # Check file exists and is in allowed directory
    full_path = os.path.join(SOUND_DIR, filename)
    if not os.path.isfile(full_path):
        raise ValueError("File not found")
    
    return full_path
```

### Safe Command Execution

```python
# Never use os.system() with user input
# Bad: os.system(f'aplay {user_input}')

# Good: Use subprocess with list
subprocess.run(['aplay', validated_file], check=True)
```

### File Permissions

```python
# Set appropriate permissions for log files
import stat

def create_log_file(filepath):
    """Create log file with restricted permissions."""
    # Create file if it doesn't exist
    if not os.path.exists(filepath):
        open(filepath, 'a').close()
        # Set permissions: owner read/write only
        os.chmod(filepath, stat.S_IRUSR | stat.S_IWUSR)
```

## Code Style Guidelines

### Follow PEP 8 with Hardware Context

```python
# Constants in UPPERCASE
SENSOR_PIN = 23
COOLDOWN_SECONDS = 1800

# Functions and variables in snake_case
def motion_detected(channel):
    current_time = int(time.time())

# Classes in PascalCase
class SensorManager:
    pass

# Module-level docstrings
"""
Module for PIR sensor motion detection.

This module handles motion detection using a PIR sensor connected
to GPIO23 and triggers sound playback with cooldown logic.
"""

# Function docstrings
def check_cooldown(last_trigger):
    """
    Check if cooldown period has elapsed.
    
    Args:
        last_trigger: Unix timestamp of last trigger
        
    Returns:
        bool: True if cooldown elapsed, False otherwise
    """
    return (time.time() - last_trigger) >= COOLDOWN_SECONDS
```

### Imports Organization

```python
# Standard library imports first
import os
import sys
import time
from pathlib import Path

# Third-party imports
import RPi.GPIO as GPIO

# Local application imports
from config import SENSOR_PIN, COOLDOWN_SECONDS
from hardware.sensors import PIRSensor
```

## Example: Complete Application Structure

See `example_application.py` in this directory for a complete, production-ready example demonstrating all best practices.

## Deployment Checklist

Before deploying to production:

- [ ] Syntax validation passed: `python3 -m py_compile *.py`
- [ ] Configuration separated from code
- [ ] Error handling implemented for all GPIO operations
- [ ] Logging configured with appropriate levels
- [ ] Graceful shutdown with GPIO cleanup
- [ ] File operations use safe patterns
- [ ] Integration tests passed on hardware
- [ ] Documentation updated (README, comments)
- [ ] Service script tested (if applicable)
- [ ] Permissions verified (sudo required for GPIO)

## Common Pitfalls and Solutions

### Issue: GPIO Already in Use
```python
# Solution: Clean up at start
GPIO.setwarnings(False)
GPIO.cleanup()
GPIO.setmode(GPIO.BCM)
```

### Issue: Script Exits Before Cleanup
```python
# Solution: Use try/finally
try:
    main_loop()
finally:
    GPIO.cleanup()
```

### Issue: Permission Denied on GPIO
```python
# Solution: Check if running with sudo
import os
if os.geteuid() != 0:
    print("This script requires root. Run with: sudo python3 script.py")
    sys.exit(1)
```

### Issue: Event Callback Exceptions
```python
# Solution: Wrap callback in try/except
def safe_callback(channel):
    try:
        actual_callback(channel)
    except Exception as e:
        logging.error(f"Callback error: {e}")
```

## Additional Resources

- **Python Best Practices**: See `python-patterns.md` in this directory
- **Hardware Integration**: See `.github/skills/raspi-zero-w/` for GPIO details
- **RPi.GPIO Documentation**: https://sourceforge.net/p/raspberry-gpio-python/wiki/Home/
- **Python 3 Documentation**: https://docs.python.org/3/
- **PEP 8 Style Guide**: https://pep8.org/

## Project-Specific Patterns

### Current Project (Mario Module) Analysis

The `mario.py` module in `motion-detection/mario/` serves as a **reference implementation** for Luigi modules.

**Good Practices Used:**
- Try/finally block for GPIO cleanup
- Event-driven architecture (GPIO.add_event_detect)
- Cooldown logic to prevent spam
- File-based stop mechanism

**Recommended Improvements for Any Module:**
- Add configuration file instead of hardcoded constants
- Implement structured logging instead of print statements
- Use context managers for file operations
- Add error handling for external processes (sound playback, etc.)
- Validate file paths before use
- Add command-line arguments for flexibility
- Create hardware abstraction layer for reusability

**Extending Beyond Motion Detection:**

The Mario module demonstrates patterns applicable to ANY Luigi module:
- **Environmental Sensors:** Replace PIR with DHT22, use similar event patterns
- **Automation Controllers:** Replace sound playback with relay control
- **Security Monitors:** Replace cooldown with alert mechanisms
- **IoT Integrations:** Add MQTT/HTTP instead of local sounds

All modules can share common patterns while implementing different hardware interfaces and behaviors.

**Example Refactored Pattern (Applicable to Any Module):**
```python
#!/usr/bin/env python3
"""Generic hardware module - refactored pattern."""
import logging
from config import SENSOR_PIN, DATA_DIR, COOLDOWN_SECONDS
from hardware.gpio_manager import GPIOManager
from hardware.sensors import SensorFactory

def main():
    # Setup logging
    setup_logging()
    
    # Initialize GPIO
    gpio = GPIOManager()
    gpio.initialize()
    
    # Create sensor
    sensor = PIRSensor(SENSOR_PIN, callback=motion_handler)
    
    try:
        sensor.start()
        logging.info("Motion detection started")
        
        while True:
            time.sleep(100)
            
    except KeyboardInterrupt:
        logging.info("Shutdown requested")
    finally:
        sensor.stop()
        gpio.cleanup()

if __name__ == '__main__':
    main()
```

## Summary

Successful Python development for Raspberry Pi hardware requires:

1. **Proper error handling** - GPIO operations can fail
2. **Clean separation** - Configuration, hardware abstraction, logic
3. **Robust cleanup** - Always use try/finally for GPIO
4. **Good logging** - Essential for debugging hardware issues
5. **Syntax validation** - Test without hardware first
6. **Incremental testing** - Test components before integration
7. **Documentation** - Hardware setup and code structure

Follow these patterns to create maintainable, reliable hardware control applications.
