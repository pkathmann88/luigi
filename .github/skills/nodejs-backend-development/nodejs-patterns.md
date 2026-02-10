# Advanced Node.js Patterns for Raspberry Pi Zero W

This document provides advanced patterns, examples, and best practices for Node.js backend development on Raspberry Pi Zero W.

## Table of Contents
- [WebSocket Integration](#websocket-integration)
- [Scheduled Tasks](#scheduled-tasks)
- [Event-Driven Architecture](#event-driven-architecture)
- [Graceful Shutdown](#graceful-shutdown)
- [Error Recovery](#error-recovery)
- [Database Integration](#database-integration)
- [API Versioning](#api-versioning)
- [Performance Monitoring](#performance-monitoring)

## WebSocket Integration

### Real-Time GPIO Updates with Socket.IO

```javascript
// server.js - Add WebSocket support
const http = require('http');
const https = require('https');
const socketIo = require('socket.io');
const app = require('./src/app');
const gpioManager = require('./src/hardware/gpioManager');
const logger = require('./src/utils/logger');

// Create server
const server = https.createServer(httpsOptions, app);

// Setup Socket.IO with authentication
const io = socketIo(server, {
  cors: {
    origin: process.env.CORS_ORIGIN || false,
    methods: ['GET', 'POST'],
    credentials: true
  }
});

// Authentication middleware for WebSocket
io.use((socket, next) => {
  const auth = socket.handshake.auth;
  
  if (!auth || !auth.username || !auth.password) {
    return next(new Error('Authentication required'));
  }
  
  // Verify credentials (same as Basic Auth)
  if (auth.username === process.env.AUTH_USERNAME && 
      auth.password === process.env.AUTH_PASSWORD) {
    socket.username = auth.username;
    next();
  } else {
    next(new Error('Invalid credentials'));
  }
});

// Connection handling
io.on('connection', (socket) => {
  logger.info(`WebSocket client connected: ${socket.id} (${socket.username})`);
  
  // Send current GPIO state
  socket.emit('gpio-state', gpioManager.getStatistics());
  
  // Handle GPIO control requests
  socket.on('gpio-write', async (data) => {
    try {
      const { pin, value } = data;
      gpioManager.writePin(pin, value);
      
      // Broadcast to all clients
      io.emit('gpio-change', { pin, value, timestamp: new Date().toISOString() });
      
      socket.emit('gpio-write-result', { success: true, pin, value });
    } catch (error) {
      logger.error('WebSocket GPIO write error:', error);
      socket.emit('gpio-write-result', { success: false, error: error.message });
    }
  });
  
  // Handle disconnection
  socket.on('disconnect', () => {
    logger.info(`WebSocket client disconnected: ${socket.id}`);
  });
});

// Broadcast GPIO input changes to all connected clients
function broadcastGpioChange(pin, value) {
  io.emit('gpio-change', {
    pin,
    value,
    timestamp: new Date().toISOString()
  });
}

// Setup GPIO input listeners
gpioManager.setupInput(23, 'both', (value) => {
  broadcastGpioChange(23, value);
});

server.listen(PORT, HOST);
```

### WebSocket Client Example

```javascript
// Client-side JavaScript
const socket = io('https://192.168.1.10:8443', {
  auth: {
    username: 'admin',
    password: 'your-secure-password'
  },
  rejectUnauthorized: false // Only for self-signed certs
});

socket.on('connect', () => {
  console.log('Connected to Luigi API');
});

socket.on('gpio-change', (data) => {
  console.log(`GPIO ${data.pin} changed to ${data.value}`);
  updateUI(data.pin, data.value);
});

socket.on('gpio-state', (state) => {
  console.log('Current GPIO state:', state);
});

// Control GPIO
function controlGPIO(pin, value) {
  socket.emit('gpio-write', { pin, value });
}

socket.on('gpio-write-result', (result) => {
  if (result.success) {
    console.log(`GPIO ${result.pin} set to ${result.value}`);
  } else {
    console.error('GPIO control failed:', result.error);
  }
});
```

## Scheduled Tasks

### Using node-cron for Periodic Tasks

```javascript
// src/utils/scheduler.js
const cron = require('node-cron');
const logger = require('./logger');
const gpioManager = require('../hardware/gpioManager');
const mqttPublisher = require('./mqttPublisher');

class Scheduler {
  constructor() {
    this.tasks = new Map();
  }

  /**
   * Schedule sensor reading every 5 minutes
   */
  scheduleSensorReads() {
    const task = cron.schedule('*/5 * * * *', async () => {
      try {
        const value = gpioManager.readPin(24);
        await mqttPublisher.publishBinary('scheduled_sensor', value);
        logger.info(`Scheduled sensor read: ${value}`);
      } catch (error) {
        logger.error('Scheduled sensor read failed:', error);
      }
    });

    this.tasks.set('sensor-reads', task);
    logger.info('Scheduled sensor reads every 5 minutes');
  }

  /**
   * Schedule GPIO cleanup at midnight
   */
  scheduleNightlyCleanup() {
    const task = cron.schedule('0 0 * * *', () => {
      logger.info('Running nightly GPIO cleanup');
      // Reset all output pins to safe state
      for (const [pin, _] of gpioManager.pins.entries()) {
        try {
          gpioManager.writePin(pin, 0);
        } catch (error) {
          logger.error(`Failed to reset pin ${pin}:`, error);
        }
      }
    });

    this.tasks.set('nightly-cleanup', task);
    logger.info('Scheduled nightly cleanup at midnight');
  }

  /**
   * Schedule health checks every minute
   */
  scheduleHealthChecks() {
    const task = cron.schedule('* * * * *', () => {
      const stats = gpioManager.getStatistics();
      if (!stats.initialized) {
        logger.error('GPIO system not initialized!');
      }
    });

    this.tasks.set('health-checks', task);
    logger.info('Scheduled health checks every minute');
  }

  /**
   * Stop a scheduled task
   */
  stopTask(name) {
    const task = this.tasks.get(name);
    if (task) {
      task.stop();
      this.tasks.delete(name);
      logger.info(`Stopped scheduled task: ${name}`);
    }
  }

  /**
   * Stop all scheduled tasks
   */
  stopAll() {
    for (const [name, task] of this.tasks.entries()) {
      task.stop();
      logger.info(`Stopped scheduled task: ${name}`);
    }
    this.tasks.clear();
  }
}

module.exports = new Scheduler();
```

## Event-Driven Architecture

### Custom Event Emitter for GPIO Events

```javascript
// src/hardware/gpioEventEmitter.js
const EventEmitter = require('events');
const logger = require('../utils/logger');

class GpioEventEmitter extends EventEmitter {
  constructor() {
    super();
    this.debounceTimers = new Map();
  }

  /**
   * Emit GPIO change event with debouncing
   */
  emitChange(pin, value, debounceMs = 50) {
    const key = `pin-${pin}`;

    // Clear existing timer
    if (this.debounceTimers.has(key)) {
      clearTimeout(this.debounceTimers.get(key));
    }

    // Set new timer
    const timer = setTimeout(() => {
      this.emit('gpio:change', { pin, value, timestamp: Date.now() });
      this.emit(`gpio:${pin}:change`, value);
      this.debounceTimers.delete(key);
    }, debounceMs);

    this.debounceTimers.set(key, timer);
  }

  /**
   * Emit motion detected event
   */
  emitMotion(pin) {
    this.emit('motion:detected', { pin, timestamp: Date.now() });
    logger.info(`Motion detected on pin ${pin}`);
  }

  /**
   * Emit button press event
   */
  emitButtonPress(pin, duration) {
    this.emit('button:press', { pin, duration, timestamp: Date.now() });
    
    if (duration > 3000) {
      this.emit('button:longpress', { pin, duration });
    }
  }
}

module.exports = new GpioEventEmitter();
```

### Event Listeners

```javascript
// src/app.js - Setup event listeners
const gpioEvents = require('./hardware/gpioEventEmitter');
const mqttPublisher = require('./utils/mqttPublisher');
const logger = require('./utils/logger');

// Listen for GPIO changes
gpioEvents.on('gpio:change', async (data) => {
  logger.debug(`GPIO ${data.pin} changed to ${data.value}`);
  
  // Publish to MQTT
  await mqttPublisher.publishBinary(`gpio_${data.pin}`, data.value);
});

// Listen for motion events
gpioEvents.on('motion:detected', async (data) => {
  logger.info(`Motion detected on pin ${data.pin}`);
  
  // Trigger actions
  await mqttPublisher.publishBinary('motion_sensor', true);
  
  // Turn on LED for 10 seconds
  gpioManager.writePin(18, 1);
  setTimeout(() => {
    gpioManager.writePin(18, 0);
  }, 10000);
});

// Listen for button events
gpioEvents.on('button:press', (data) => {
  logger.info(`Button pressed on pin ${data.pin}`);
});

gpioEvents.on('button:longpress', (data) => {
  logger.info(`Long press detected on pin ${data.pin}`);
  // Trigger special action
});
```

## Graceful Shutdown

### Comprehensive Shutdown Handler

```javascript
// src/utils/shutdownHandler.js
const logger = require('./logger');

class ShutdownHandler {
  constructor() {
    this.shutdownHandlers = [];
    this.isShuttingDown = false;
  }

  /**
   * Register a shutdown handler
   */
  register(name, handler) {
    this.shutdownHandlers.push({ name, handler });
    logger.debug(`Registered shutdown handler: ${name}`);
  }

  /**
   * Perform graceful shutdown
   */
  async shutdown(signal) {
    if (this.isShuttingDown) {
      logger.warn('Shutdown already in progress');
      return;
    }

    this.isShuttingDown = true;
    logger.info(`${signal} received, starting graceful shutdown`);

    // Execute all shutdown handlers
    for (const { name, handler } of this.shutdownHandlers) {
      try {
        logger.info(`Executing shutdown handler: ${name}`);
        await handler();
        logger.info(`Shutdown handler completed: ${name}`);
      } catch (error) {
        logger.error(`Shutdown handler failed: ${name}`, error);
      }
    }

    logger.info('Graceful shutdown complete');
    process.exit(0);
  }

  /**
   * Setup signal handlers
   */
  setup() {
    process.on('SIGTERM', () => this.shutdown('SIGTERM'));
    process.on('SIGINT', () => this.shutdown('SIGINT'));

    // Handle uncaught exceptions
    process.on('uncaughtException', (error) => {
      logger.error('Uncaught exception:', error);
      this.shutdown('UNCAUGHT_EXCEPTION');
    });

    // Handle unhandled promise rejections
    process.on('unhandledRejection', (reason, promise) => {
      logger.error('Unhandled rejection at:', promise, 'reason:', reason);
      this.shutdown('UNHANDLED_REJECTION');
    });
  }
}

module.exports = new ShutdownHandler();
```

### Usage in server.js

```javascript
// server.js
const shutdownHandler = require('./src/utils/shutdownHandler');
const gpioManager = require('./src/hardware/gpioManager');
const scheduler = require('./src/utils/scheduler');

// Register shutdown handlers
shutdownHandler.register('http-server', () => {
  return new Promise((resolve) => {
    server.close(() => {
      logger.info('HTTP server closed');
      resolve();
    });
  });
});

shutdownHandler.register('gpio-cleanup', () => {
  gpioManager.cleanup();
  return Promise.resolve();
});

shutdownHandler.register('scheduler', () => {
  scheduler.stopAll();
  return Promise.resolve();
});

shutdownHandler.register('flush-logs', () => {
  return new Promise((resolve) => {
    logger.on('finish', resolve);
    logger.end();
  });
});

// Setup signal handlers
shutdownHandler.setup();
```

## Error Recovery

### Automatic GPIO Recovery

```javascript
// src/hardware/gpioRecovery.js
const logger = require('../utils/logger');

class GpioRecovery {
  constructor(gpioManager) {
    this.gpioManager = gpioManager;
    this.retryAttempts = 3;
    this.retryDelay = 1000; // 1 second
  }

  /**
   * Attempt to recover from GPIO error
   */
  async recover(pin, operation, ...args) {
    for (let attempt = 1; attempt <= this.retryAttempts; attempt++) {
      try {
        logger.info(`GPIO recovery attempt ${attempt}/${this.retryAttempts} for pin ${pin}`);
        
        // Try to re-initialize the pin
        if (operation === 'write') {
          return this.gpioManager.writePin(pin, ...args);
        } else if (operation === 'read') {
          return this.gpioManager.readPin(pin);
        }
      } catch (error) {
        logger.error(`Recovery attempt ${attempt} failed:`, error);
        
        if (attempt < this.retryAttempts) {
          await this.delay(this.retryDelay * attempt);
        }
      }
    }

    logger.error(`GPIO recovery failed after ${this.retryAttempts} attempts`);
    throw new Error(`GPIO recovery failed for pin ${pin}`);
  }

  /**
   * Delay helper
   */
  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

module.exports = GpioRecovery;
```

## Database Integration

### SQLite for Local Storage

```javascript
// src/database/db.js
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const logger = require('../utils/logger');

const DB_PATH = process.env.DB_PATH || '/var/lib/luigi/api.db';

class Database {
  constructor() {
    this.db = null;
  }

  /**
   * Initialize database
   */
  async initialize() {
    return new Promise((resolve, reject) => {
      this.db = new sqlite3.Database(DB_PATH, (err) => {
        if (err) {
          logger.error('Database initialization failed:', err);
          reject(err);
        } else {
          logger.info(`Database initialized: ${DB_PATH}`);
          this.createTables().then(resolve).catch(reject);
        }
      });
    });
  }

  /**
   * Create tables
   */
  async createTables() {
    const queries = [
      `CREATE TABLE IF NOT EXISTS gpio_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pin INTEGER NOT NULL,
        value INTEGER NOT NULL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        user TEXT
      )`,
      `CREATE INDEX IF NOT EXISTS idx_gpio_log_timestamp 
       ON gpio_log(timestamp)`,
      `CREATE TABLE IF NOT EXISTS sensor_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sensor_id TEXT NOT NULL,
        value REAL NOT NULL,
        unit TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      )`
    ];

    for (const query of queries) {
      await this.run(query);
    }

    logger.info('Database tables created');
  }

  /**
   * Run query
   */
  run(query, params = []) {
    return new Promise((resolve, reject) => {
      this.db.run(query, params, function(err) {
        if (err) {
          reject(err);
        } else {
          resolve({ id: this.lastID, changes: this.changes });
        }
      });
    });
  }

  /**
   * Get single row
   */
  get(query, params = []) {
    return new Promise((resolve, reject) => {
      this.db.get(query, params, (err, row) => {
        if (err) {
          reject(err);
        } else {
          resolve(row);
        }
      });
    });
  }

  /**
   * Get all rows
   */
  all(query, params = []) {
    return new Promise((resolve, reject) => {
      this.db.all(query, params, (err, rows) => {
        if (err) {
          reject(err);
        } else {
          resolve(rows);
        }
      });
    });
  }

  /**
   * Log GPIO operation
   */
  async logGpioOperation(pin, value, user) {
    return this.run(
      'INSERT INTO gpio_log (pin, value, user) VALUES (?, ?, ?)',
      [pin, value, user]
    );
  }

  /**
   * Get GPIO history
   */
  async getGpioHistory(pin, limit = 100) {
    return this.all(
      'SELECT * FROM gpio_log WHERE pin = ? ORDER BY timestamp DESC LIMIT ?',
      [pin, limit]
    );
  }

  /**
   * Close database
   */
  close() {
    return new Promise((resolve, reject) => {
      if (this.db) {
        this.db.close((err) => {
          if (err) {
            reject(err);
          } else {
            logger.info('Database connection closed');
            resolve();
          }
        });
      } else {
        resolve();
      }
    });
  }
}

module.exports = new Database();
```

## API Versioning

### Version-based Routing

```javascript
// src/routes/index.js - API versioning
const express = require('express');
const v1Routes = require('./v1');
const v2Routes = require('./v2');

const router = express.Router();

// Version 1 routes
router.use('/v1', v1Routes);

// Version 2 routes (new features)
router.use('/v2', v2Routes);

// Default to latest version
router.use('/', v2Routes);

module.exports = router;
```

```javascript
// src/routes/v1/gpio.js
const express = require('express');
const { authenticate } = require('../../middleware/authenticate');
const gpioControllerV1 = require('../../controllers/v1/gpioController');

const router = express.Router();

router.use(authenticate);
router.get('/pins', gpioControllerV1.listPins);
router.post('/output/:pin', gpioControllerV1.setOutput);

module.exports = router;
```

## Performance Monitoring

### Custom Performance Middleware

```javascript
// src/middleware/performance.js
const logger = require('../utils/logger');

class PerformanceMonitor {
  constructor() {
    this.requestTimes = [];
    this.maxRequestTime = 0;
    this.avgRequestTime = 0;
  }

  /**
   * Middleware to track request performance
   */
  middleware() {
    return (req, res, next) => {
      const startTime = process.hrtime.bigint();
      const startMemory = process.memoryUsage();

      // Intercept response
      const originalSend = res.send;
      res.send = (data) => {
        res.send = originalSend;

        // Calculate time
        const endTime = process.hrtime.bigint();
        const duration = Number(endTime - startTime) / 1000000; // Convert to ms

        // Calculate memory
        const endMemory = process.memoryUsage();
        const memoryDelta = endMemory.heapUsed - startMemory.heapUsed;

        // Track statistics
        this.recordRequest(duration);

        // Log slow requests
        if (duration > 1000) {
          logger.warn('Slow request detected:', {
            method: req.method,
            path: req.path,
            duration: `${duration.toFixed(2)}ms`,
            memory: `${Math.round(memoryDelta / 1024)}KB`
          });
        }

        // Add performance headers
        res.set('X-Response-Time', `${duration.toFixed(2)}ms`);

        return res.send(data);
      };

      next();
    };
  }

  /**
   * Record request timing
   */
  recordRequest(duration) {
    this.requestTimes.push(duration);
    
    // Keep only last 100 requests
    if (this.requestTimes.length > 100) {
      this.requestTimes.shift();
    }

    // Update max
    if (duration > this.maxRequestTime) {
      this.maxRequestTime = duration;
    }

    // Calculate average
    const sum = this.requestTimes.reduce((a, b) => a + b, 0);
    this.avgRequestTime = sum / this.requestTimes.length;
  }

  /**
   * Get performance statistics
   */
  getStats() {
    return {
      requestCount: this.requestTimes.length,
      avgResponseTime: `${this.avgRequestTime.toFixed(2)}ms`,
      maxResponseTime: `${this.maxRequestTime.toFixed(2)}ms`,
      memory: process.memoryUsage(),
      uptime: process.uptime()
    };
  }
}

module.exports = new PerformanceMonitor();
```

## Additional Patterns

### Circuit Breaker Pattern

```javascript
// src/utils/circuitBreaker.js
class CircuitBreaker {
  constructor(options = {}) {
    this.failureThreshold = options.failureThreshold || 5;
    this.successThreshold = options.successThreshold || 2;
    this.timeout = options.timeout || 60000; // 1 minute
    this.state = 'CLOSED'; // CLOSED, OPEN, HALF_OPEN
    this.failureCount = 0;
    this.successCount = 0;
    this.nextAttempt = Date.now();
  }

  async execute(fn) {
    if (this.state === 'OPEN') {
      if (Date.now() < this.nextAttempt) {
        throw new Error('Circuit breaker is OPEN');
      }
      this.state = 'HALF_OPEN';
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  onSuccess() {
    this.failureCount = 0;

    if (this.state === 'HALF_OPEN') {
      this.successCount++;
      if (this.successCount >= this.successThreshold) {
        this.state = 'CLOSED';
        this.successCount = 0;
      }
    }
  }

  onFailure() {
    this.failureCount++;
    if (this.failureCount >= this.failureThreshold) {
      this.state = 'OPEN';
      this.nextAttempt = Date.now() + this.timeout;
    }
  }
}

module.exports = CircuitBreaker;
```

These patterns provide a solid foundation for building robust, maintainable Node.js applications on Raspberry Pi Zero W.
