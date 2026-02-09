# Python Patterns for Hardware Development

This document provides common Python patterns and idioms specifically useful for Raspberry Pi hardware projects.

## Pattern: Hardware Resource Manager

Use context managers to ensure proper cleanup of hardware resources:

```python
class GPIOResource:
    """Context manager for GPIO resources."""
    
    def __init__(self, pin, mode=GPIO.BCM):
        self.pin = pin
        self.mode = mode
    
    def __enter__(self):
        GPIO.setmode(self.mode)
        GPIO.setup(self.pin, GPIO.IN)
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        GPIO.cleanup()
        return False  # Don't suppress exceptions

# Usage
with GPIOResource(23) as gpio:
    state = GPIO.input(23)
    print(f"Sensor state: {state}")
# GPIO automatically cleaned up
```

## Pattern: Singleton for GPIO Manager

Ensure only one GPIO manager exists:

```python
class GPIOManager:
    """Singleton GPIO manager."""
    
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance
    
    def initialize(self):
        """Initialize GPIO (only once)."""
        if not self._initialized:
            GPIO.setmode(GPIO.BCM)
            self._initialized = True
    
    def cleanup(self):
        """Clean up GPIO."""
        if self._initialized:
            GPIO.cleanup()
            self._initialized = False

# Usage - always gets same instance
manager1 = GPIOManager()
manager2 = GPIOManager()
assert manager1 is manager2  # Same object
```

## Pattern: State Machine for Sensor

Implement sensor states cleanly:

```python
from enum import Enum

class SensorState(Enum):
    IDLE = "idle"
    DETECTING = "detecting"
    COOLDOWN = "cooldown"
    ERROR = "error"

class StatefulSensor:
    """Sensor with state management."""
    
    def __init__(self, pin):
        self.pin = pin
        self.state = SensorState.IDLE
        self.last_detection = 0
        self.cooldown_period = 1800
    
    def on_motion(self, channel):
        """Handle motion detection based on state."""
        if self.state == SensorState.IDLE:
            self.state = SensorState.DETECTING
            self.handle_detection()
            self.state = SensorState.COOLDOWN
            self.last_detection = time.time()
        elif self.state == SensorState.COOLDOWN:
            if time.time() - self.last_detection > self.cooldown_period:
                self.state = SensorState.IDLE
                self.on_motion(channel)  # Retry
        else:
            logging.debug(f"Motion ignored in state: {self.state}")
    
    def handle_detection(self):
        """Process detection event."""
        logging.info("Motion detected!")
        # Process event...
```

## Pattern: Observer for Hardware Events

Implement pub/sub for hardware events:

```python
class EventPublisher:
    """Publish hardware events to subscribers."""
    
    def __init__(self):
        self._subscribers = {}
    
    def subscribe(self, event_type, callback):
        """Subscribe to event type."""
        if event_type not in self._subscribers:
            self._subscribers[event_type] = []
        self._subscribers[event_type].append(callback)
    
    def publish(self, event_type, data=None):
        """Publish event to subscribers."""
        if event_type in self._subscribers:
            for callback in self._subscribers[event_type]:
                try:
                    callback(data)
                except Exception as e:
                    logging.error(f"Callback error: {e}")

# Usage
publisher = EventPublisher()

def on_motion(data):
    print(f"Motion detected: {data}")

def on_button_press(data):
    print(f"Button pressed: {data}")

publisher.subscribe("motion", on_motion)
publisher.subscribe("button", on_button_press)

# In GPIO callback
def gpio_callback(channel):
    publisher.publish("motion", {"pin": channel, "time": time.time()})
```

## Pattern: Retry Decorator

Retry hardware operations automatically:

```python
import functools
import time

def retry(max_attempts=3, delay=1, exceptions=(Exception,)):
    """Decorator to retry function on exception."""
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except exceptions as e:
                    if attempt == max_attempts - 1:
                        raise
                    logging.warning(f"Attempt {attempt + 1} failed: {e}")
                    time.sleep(delay)
        return wrapper
    return decorator

# Usage
@retry(max_attempts=3, delay=0.5, exceptions=(IOError, RuntimeError))
def initialize_sensor(pin):
    """Initialize sensor with automatic retry."""
    GPIO.setup(pin, GPIO.IN)
    # Verify sensor responds
    state = GPIO.input(pin)
    return state
```

## Pattern: Configuration from File

Load configuration from YAML or JSON:

```python
import yaml
import os

class Config:
    """Configuration loader with validation."""
    
    DEFAULT_CONFIG = {
        'gpio': {
            'mode': 'BCM',
            'sensor_pin': 23,
            'led_pin': 18
        },
        'timing': {
            'cooldown': 1800,
            'debounce': 200
        },
        'paths': {
            'sound_dir': '/usr/share/sounds/mario/',
            'log_file': '/var/log/motion.log'
        }
    }
    
    def __init__(self, config_file='config.yaml'):
        self.config_file = config_file
        self.config = self.load_config()
    
    def load_config(self):
        """Load configuration from file or use defaults."""
        if os.path.exists(self.config_file):
            try:
                with open(self.config_file, 'r') as f:
                    config = yaml.safe_load(f)
                logging.info(f"Loaded config from {self.config_file}")
                return config
            except Exception as e:
                logging.error(f"Failed to load config: {e}")
        
        logging.info("Using default configuration")
        return self.DEFAULT_CONFIG.copy()
    
    def get(self, key_path, default=None):
        """Get config value using dot notation."""
        keys = key_path.split('.')
        value = self.config
        for key in keys:
            if isinstance(value, dict) and key in value:
                value = value[key]
            else:
                return default
        return value

# Usage
config = Config('config.yaml')
sensor_pin = config.get('gpio.sensor_pin', 23)
cooldown = config.get('timing.cooldown', 1800)
```

## Pattern: Command Pattern for Actions

Encapsulate hardware actions:

```python
from abc import ABC, abstractmethod

class Command(ABC):
    """Abstract command interface."""
    
    @abstractmethod
    def execute(self):
        pass
    
    @abstractmethod
    def undo(self):
        pass

class LEDOnCommand(Command):
    """Command to turn on LED."""
    
    def __init__(self, pin):
        self.pin = pin
    
    def execute(self):
        GPIO.output(self.pin, GPIO.HIGH)
        logging.info(f"LED {self.pin} turned ON")
    
    def undo(self):
        GPIO.output(self.pin, GPIO.LOW)
        logging.info(f"LED {self.pin} turned OFF")

class PlaySoundCommand(Command):
    """Command to play sound."""
    
    def __init__(self, sound_file):
        self.sound_file = sound_file
        self.process = None
    
    def execute(self):
        self.process = subprocess.Popen(['aplay', self.sound_file])
        logging.info(f"Playing {self.sound_file}")
    
    def undo(self):
        if self.process:
            self.process.kill()
            logging.info(f"Stopped {self.sound_file}")

# Usage
commands = [
    LEDOnCommand(18),
    PlaySoundCommand('/path/to/sound.wav')
]

for cmd in commands:
    cmd.execute()
```

## Pattern: Async Hardware Operations

Use async/await for concurrent operations:

```python
import asyncio

class AsyncSensor:
    """Asynchronous sensor monitoring."""
    
    def __init__(self, pin):
        self.pin = pin
        self.running = False
    
    async def monitor(self):
        """Monitor sensor asynchronously."""
        self.running = True
        while self.running:
            state = GPIO.input(self.pin)
            if state == GPIO.HIGH:
                await self.on_detection()
            await asyncio.sleep(0.1)
    
    async def on_detection(self):
        """Handle detection asynchronously."""
        logging.info("Motion detected!")
        # Can await other async operations
        await self.play_sound_async()
    
    async def play_sound_async(self):
        """Play sound without blocking."""
        process = await asyncio.create_subprocess_exec(
            'aplay', '/path/to/sound.wav',
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        await process.wait()
    
    def stop(self):
        """Stop monitoring."""
        self.running = False

# Usage
async def main():
    sensor = AsyncSensor(23)
    try:
        await sensor.monitor()
    except KeyboardInterrupt:
        sensor.stop()

if __name__ == '__main__':
    asyncio.run(main())
```

## Pattern: Debouncing Decorator

Prevent rapid repeated calls:

```python
import time
from functools import wraps

def debounce(wait_time):
    """Decorator to debounce function calls."""
    def decorator(func):
        last_called = [0]  # Use list to allow modification in closure
        
        @wraps(func)
        def wrapper(*args, **kwargs):
            now = time.time()
            if now - last_called[0] >= wait_time:
                last_called[0] = now
                return func(*args, **kwargs)
            else:
                logging.debug("Call debounced")
        return wrapper
    return decorator

# Usage
@debounce(0.5)  # Minimum 0.5 seconds between calls
def on_button_press(channel):
    print(f"Button pressed on GPIO{channel}")
    # Process button press
```

## Pattern: Lazy Initialization

Initialize hardware only when needed:

```python
class LazySensor:
    """Sensor with lazy initialization."""
    
    def __init__(self, pin):
        self.pin = pin
        self._initialized = False
        self._gpio = None
    
    def _ensure_initialized(self):
        """Initialize if not already done."""
        if not self._initialized:
            GPIO.setmode(GPIO.BCM)
            GPIO.setup(self.pin, GPIO.IN)
            self._initialized = True
            logging.info(f"Sensor {self.pin} initialized")
    
    def read(self):
        """Read sensor value."""
        self._ensure_initialized()
        return GPIO.input(self.pin)
    
    def start_monitoring(self, callback):
        """Start event monitoring."""
        self._ensure_initialized()
        GPIO.add_event_detect(self.pin, GPIO.RISING, callback=callback)
```

## Pattern: Thread-Safe GPIO Access

Protect GPIO access in multi-threaded applications:

```python
import threading

class ThreadSafeGPIO:
    """Thread-safe GPIO wrapper."""
    
    def __init__(self):
        self._lock = threading.Lock()
        self._initialized = False
    
    def setup(self, pin, direction):
        """Thread-safe GPIO setup."""
        with self._lock:
            if not self._initialized:
                GPIO.setmode(GPIO.BCM)
                self._initialized = True
            GPIO.setup(pin, direction)
    
    def read(self, pin):
        """Thread-safe GPIO read."""
        with self._lock:
            return GPIO.input(pin)
    
    def write(self, pin, value):
        """Thread-safe GPIO write."""
        with self._lock:
            GPIO.output(pin, value)

# Usage
gpio = ThreadSafeGPIO()

def worker_thread():
    gpio.write(18, GPIO.HIGH)
    time.sleep(1)
    gpio.write(18, GPIO.LOW)

# Safe for multiple threads
threads = [threading.Thread(target=worker_thread) for _ in range(5)]
for t in threads:
    t.start()
```

## Pattern: Factory for Sensors

Create sensors using factory pattern:

```python
class SensorFactory:
    """Factory for creating sensor objects."""
    
    @staticmethod
    def create_sensor(sensor_type, pin, **kwargs):
        """Create sensor instance based on type."""
        if sensor_type == 'pir':
            return PIRSensor(pin, **kwargs)
        elif sensor_type == 'button':
            return ButtonSensor(pin, **kwargs)
        elif sensor_type == 'ultrasonic':
            return UltrasonicSensor(pin, **kwargs)
        else:
            raise ValueError(f"Unknown sensor type: {sensor_type}")

# Usage
sensor = SensorFactory.create_sensor('pir', 23, callback=on_motion)
```

## Pattern: Logging Context Manager

Add context to log messages:

```python
import logging
from contextlib import contextmanager

@contextmanager
def log_context(context_name):
    """Add context to log messages."""
    logger = logging.getLogger()
    old_factory = logger.makeRecord
    
    def record_factory(*args, **kwargs):
        record = old_factory(*args, **kwargs)
        record.context = context_name
        return record
    
    logger.makeRecord = record_factory
    
    # Custom formatter
    formatter = logging.Formatter(
        '%(asctime)s - [%(context)s] - %(levelname)s - %(message)s'
    )
    for handler in logger.handlers:
        handler.setFormatter(formatter)
    
    try:
        yield
    finally:
        logger.makeRecord = old_factory

# Usage
with log_context("GPIO_INIT"):
    GPIO.setmode(GPIO.BCM)
    # All logs in this block will have [GPIO_INIT] context
```

## Summary

These patterns help create:
- **Maintainable code**: Clear structure and separation of concerns
- **Robust applications**: Error handling and resource management
- **Testable logic**: Decoupled from hardware dependencies
- **Reusable components**: Abstract, modular designs
- **Production-ready systems**: Thread-safety, logging, configuration

Choose patterns based on project complexity and requirements.
