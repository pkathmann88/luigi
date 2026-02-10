/**
 * Complete Example: Luigi Node.js Backend API Server
 * 
 * This example demonstrates:
 * - HTTP Basic Authentication
 * - GPIO control via REST API
 * - Input validation
 * - Rate limiting
 * - Error handling
 * - Security best practices
 * 
 * Usage:
 *   1. npm install express dotenv helmet cors express-rate-limit express-validator winston onoff
 *   2. Create .env file with AUTH_USERNAME and AUTH_PASSWORD
 *   3. node nodejs-backend-example.js
 */

require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const { body, param, validationResult } = require('express-validator');
const winston = require('winston');

// Mock GPIO for non-Raspberry Pi environments
let Gpio;
try {
  Gpio = require('onoff').Gpio;
} catch (error) {
  console.log('GPIO not available, using mock');
  Gpio = class MockGpio {
    constructor(pin, direction) {
      this.pin = pin;
      this.direction = direction;
      this.value = 0;
    }
    writeSync(value) { this.value = value; console.log(`[MOCK] Pin ${this.pin} = ${value}`); }
    readSync() { return this.value; }
    unexport() { console.log(`[MOCK] Pin ${this.pin} unexported`); }
  };
}

// Configuration
const PORT = process.env.PORT || 3000;
const AUTH_USERNAME = process.env.AUTH_USERNAME || 'admin';
const AUTH_PASSWORD = process.env.AUTH_PASSWORD || 'admin123';

// Logger setup
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    })
  ]
});

// GPIO Manager
class SimpleGpioManager {
  constructor() {
    this.pins = new Map();
  }

  setupOutput(pin, initialValue = 0) {
    if (this.pins.has(pin)) {
      throw new Error(`Pin ${pin} already in use`);
    }
    const gpioPin = new Gpio(pin, 'out');
    gpioPin.writeSync(initialValue);
    this.pins.set(pin, gpioPin);
    logger.info(`Output pin ${pin} initialized`);
  }

  setupInput(pin) {
    if (this.pins.has(pin)) {
      throw new Error(`Pin ${pin} already in use`);
    }
    const gpioPin = new Gpio(pin, 'in');
    this.pins.set(pin, gpioPin);
    logger.info(`Input pin ${pin} initialized`);
  }

  write(pin, value) {
    const gpioPin = this.pins.get(pin);
    if (!gpioPin) {
      throw new Error(`Pin ${pin} not initialized`);
    }
    gpioPin.writeSync(value);
  }

  read(pin) {
    const gpioPin = this.pins.get(pin);
    if (!gpioPin) {
      throw new Error(`Pin ${pin} not initialized`);
    }
    return gpioPin.readSync();
  }

  cleanup() {
    for (const [pin, gpioPin] of this.pins.entries()) {
      try {
        gpioPin.unexport();
        logger.info(`Pin ${pin} cleaned up`);
      } catch (error) {
        logger.error(`Failed to cleanup pin ${pin}:`, error);
      }
    }
    this.pins.clear();
  }

  listPins() {
    const result = [];
    for (const [pin, gpioPin] of this.pins.entries()) {
      result.push({
        pin,
        value: gpioPin.readSync()
      });
    }
    return result;
  }
}

const gpioManager = new SimpleGpioManager();

// Initialize Express app
const app = express();

// Security middleware
app.use(helmet());
app.disable('x-powered-by');

// CORS
app.use(cors({
  origin: false, // Restrict to no origin by default
  methods: ['GET', 'POST', 'PUT', 'DELETE']
}));

// Body parser
app.use(express.json({ limit: '1mb' }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  message: { success: false, error: 'Too many requests' }
});
app.use(limiter);

// Authentication middleware
const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    res.set('WWW-Authenticate', 'Basic realm="Luigi API"');
    return res.status(401).json({
      success: false,
      error: 'Authentication required'
    });
  }

  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Basic') {
    return res.status(401).json({
      success: false,
      error: 'Invalid authorization format'
    });
  }

  try {
    const decoded = Buffer.from(parts[1], 'base64').toString('utf-8');
    const colonIndex = decoded.indexOf(':');
    const username = decoded.substring(0, colonIndex);
    const password = decoded.substring(colonIndex + 1);

    if (username === AUTH_USERNAME && password === AUTH_PASSWORD) {
      req.user = { username };
      next();
    } else {
      logger.warn(`Failed auth attempt from ${req.ip}`);
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials'
      });
    }
  } catch (error) {
    return res.status(401).json({
      success: false,
      error: 'Invalid credentials format'
    });
  }
};

// Routes

// Health check (public)
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// List all GPIO pins (authenticated)
app.get('/api/gpio/pins', authenticate, (req, res) => {
  try {
    const pins = gpioManager.listPins();
    res.json({
      success: true,
      count: pins.length,
      pins
    });
  } catch (error) {
    logger.error('Error listing pins:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Setup output pin (authenticated)
app.post('/api/gpio/setup/output',
  authenticate,
  [
    body('pin').isInt({ min: 2, max: 27 }),
    body('initialValue').optional().isIn([0, 1])
  ],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array()
      });
    }

    try {
      const { pin, initialValue = 0 } = req.body;
      gpioManager.setupOutput(pin, initialValue);
      res.status(201).json({
        success: true,
        message: `Output pin ${pin} configured`,
        pin,
        initialValue
      });
    } catch (error) {
      logger.error('Error setting up output:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
);

// Setup input pin (authenticated)
app.post('/api/gpio/setup/input',
  authenticate,
  [
    body('pin').isInt({ min: 2, max: 27 })
  ],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array()
      });
    }

    try {
      const { pin } = req.body;
      gpioManager.setupInput(pin);
      res.status(201).json({
        success: true,
        message: `Input pin ${pin} configured`,
        pin
      });
    } catch (error) {
      logger.error('Error setting up input:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
);

// Write to output pin (authenticated)
app.post('/api/gpio/output/:pin',
  authenticate,
  [
    param('pin').isInt({ min: 2, max: 27 }),
    body('value').isIn([0, 1, '0', '1', true, false])
  ],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array()
      });
    }

    try {
      const pin = parseInt(req.params.pin);
      let value = req.body.value;

      // Normalize value
      value = (value === true || value === '1' || value === 1) ? 1 : 0;

      gpioManager.write(pin, value);

      res.json({
        success: true,
        message: `Pin ${pin} set to ${value}`,
        pin,
        value
      });
    } catch (error) {
      logger.error('Error writing to pin:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
);

// Read from input pin (authenticated)
app.get('/api/gpio/input/:pin',
  authenticate,
  [
    param('pin').isInt({ min: 2, max: 27 })
  ],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array()
      });
    }

    try {
      const pin = parseInt(req.params.pin);
      const value = gpioManager.read(pin);

      res.json({
        success: true,
        pin,
        value,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      logger.error('Error reading pin:', error);
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Not found'
  });
});

// Error handler
app.use((err, req, res, next) => {
  logger.error('Unhandled error:', err);
  res.status(500).json({
    success: false,
    error: 'Internal server error'
  });
});

// Start server
const server = app.listen(PORT, '0.0.0.0', () => {
  logger.info(`Luigi API Server running on http://0.0.0.0:${PORT}`);
  logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
  logger.info(`Authentication: ${AUTH_USERNAME}:${AUTH_PASSWORD.replace(/./g, '*')}`);
  logger.info('Press Ctrl+C to stop');
});

// Graceful shutdown
const shutdown = (signal) => {
  logger.info(`${signal} received, shutting down gracefully`);
  server.close(() => {
    logger.info('HTTP server closed');
    gpioManager.cleanup();
    process.exit(0);
  });
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

// Handle errors
process.on('uncaughtException', (error) => {
  logger.error('Uncaught exception:', error);
  shutdown('UNCAUGHT_EXCEPTION');
});

process.on('unhandledRejection', (reason) => {
  logger.error('Unhandled rejection:', reason);
  shutdown('UNHANDLED_REJECTION');
});

logger.info('Server initialization complete');
