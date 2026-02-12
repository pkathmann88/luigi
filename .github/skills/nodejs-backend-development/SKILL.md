---
name: nodejs-backend-development
description: Comprehensive guide for developing secure Node.js backend applications with REST APIs on Raspberry Pi Zero W. Use this skill when developing, debugging, or deploying Node.js servers that provide backend APIs and interact with GPIO hardware, with emphasis on local network security.
license: MIT
---

# Node.js Backend Development for Raspberry Pi Zero W

This skill provides comprehensive guidance for developing **secure** Node.js backend applications on Raspberry Pi Zero W, including REST API development, GPIO integration, hardware abstraction, deployment strategies, and performance optimization for resource-constrained environments.

**Security Emphasis:** Since these APIs will be available on the local network, this guide places particular emphasis on authentication, authorization, input validation, rate limiting, and protection against common attack vectors.

## When to Use This Skill

Use this skill when:
- Developing Node.js backend APIs for Raspberry Pi Zero W
- Creating REST/HTTP services that interact with hardware
- Building IoT backend services with GPIO control exposed via API
- Implementing web APIs for sensor data collection
- Structuring secure Node.js projects for embedded systems
- Integrating Express.js or similar frameworks with hardware
- Planning deployment and service management for Node.js apps
- Securing APIs accessible on local networks
- Optimizing Node.js performance on resource-constrained devices

## Node.js Environment for Raspberry Pi Zero W

### Hardware Constraints

**Raspberry Pi Zero W Specifications:**
- **CPU**: 1GHz single-core ARM1176JZF-S
- **RAM**: 512MB
- **Storage**: microSD card (I/O limited)
- **Network**: 802.11n Wi-Fi (2.4GHz only)

**Performance Implications:**
- Limited CPU power - avoid CPU-intensive operations
- Limited RAM - monitor memory usage, avoid memory leaks
- Single core - no benefit from multi-threading (use clustering carefully)
- Slow I/O - optimize file operations and use async I/O
- Network bandwidth limits - implement efficient data transfer

### Node.js Installation

**Recommended Node.js Version:**
- Node.js 16.x LTS (best ARM6 support and security updates)
- Node.js 18.x LTS (verify ARM6 compatibility)
- Avoid older versions (<14) due to security vulnerabilities

**Installation Method (NodeSource Repository - Recommended):**
```bash
# Add NodeSource repository for Node.js 16.x LTS
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -

# Install Node.js and npm
sudo apt-get install -y nodejs

# Verify installation
node --version  # Should show v16.x.x
npm --version   # Should show 8.x.x or higher

# Verify npm audit is available
npm audit
```

**Alternative: Official ARM Build (Manual Installation):**
```bash
# Download official ARM6 build
wget https://unofficial-builds.nodejs.org/download/release/v16.20.0/node-v16.20.0-linux-armv6l.tar.xz

# Verify checksum (important for security)
wget https://unofficial-builds.nodejs.org/download/release/v16.20.0/SHASUMS256.txt
sha256sum -c SHASUMS256.txt 2>&1 | grep node-v16.20.0-linux-armv6l.tar.xz

# Extract and install
sudo mkdir -p /usr/local/lib/nodejs
sudo tar -xJvf node-v16.20.0-linux-armv6l.tar.xz -C /usr/local/lib/nodejs

# Set up environment
echo 'export PATH=/usr/local/lib/nodejs/node-v16.20.0-linux-armv6l/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### Required System Dependencies

```bash
# Build tools (for native modules)
sudo apt-get install -y build-essential python3

# GPIO access library
sudo apt-get install -y python3-rpi.gpio

# System utilities
sudo apt-get install -y git curl

# Security tools
sudo apt-get install -y ufw fail2ban
```

## Security First: Essential Principles

### 🔒 Local Network Security Considerations

**Threat Model for Local Network APIs:**
1. **Unauthorized Access** - Other devices on network accessing API
2. **Man-in-the-Middle** - Network traffic interception
3. **Brute Force Attacks** - Password/token guessing
4. **Denial of Service** - Resource exhaustion attacks
5. **Injection Attacks** - SQL, command, or GPIO injection
6. **Data Exposure** - Sensitive information leakage
7. **Privilege Escalation** - Gaining unauthorized control

### Security Architecture Layers

```
┌─────────────────────────────────────────┐
│   Network Layer (Firewall/VPN)         │
├─────────────────────────────────────────┤
│   Transport Layer (HTTPS/TLS)          │
├─────────────────────────────────────────┤
│   Authentication (JWT/API Keys)         │
├─────────────────────────────────────────┤
│   Authorization (Role-Based Access)     │
├─────────────────────────────────────────┤
│   Input Validation & Sanitization       │
├─────────────────────────────────────────┤
│   Rate Limiting & Throttling            │
├─────────────────────────────────────────┤
│   Application Logic                     │
├─────────────────────────────────────────┤
│   Hardware Abstraction (GPIO Safety)    │
└─────────────────────────────────────────┘
```

### Mandatory Security Checklist

Before deploying any Node.js API on local network:

- [ ] **Authentication implemented** - No anonymous access to sensitive endpoints
- [ ] **HTTPS/TLS enabled** - All traffic encrypted (even on local network)
- [ ] **Input validation on all endpoints** - Prevent injection attacks
- [ ] **Rate limiting configured** - Prevent DoS and brute force
- [ ] **Firewall rules set** - Restrict access to trusted IPs
- [ ] **Secrets in environment variables** - Never hardcode credentials
- [ ] **Error messages sanitized** - Don't leak system information
- [ ] **GPIO pin validation** - Prevent hardware damage
- [ ] **Logging enabled** - Monitor for suspicious activity
- [ ] **Dependencies audited** - No known vulnerabilities
- [ ] **CORS properly configured** - Restrict origins
- [ ] **Security headers set** - Helmet.js configured

## Project Structure

```
api-server/
├── package.json              # Dependencies and scripts
├── package-lock.json         # Locked dependency versions
├── .env.example              # Environment variables template
├── .gitignore                # Git exclusions (MUST include .env)
├── server.js                 # Main application entry point
├── config/
│   ├── index.js              # Configuration loader
│   ├── security.js           # Security configuration
│   ├── default.json          # Default configuration
│   └── production.json       # Production overrides
├── src/
│   ├── app.js                # Express app setup
│   ├── routes/
│   │   ├── index.js          # Route aggregator
│   │   ├── gpio.js           # GPIO control endpoints (protected)
│   │   ├── sensors.js        # Sensor data endpoints (protected)
│   │   └── health.js         # Health check endpoints (public)
│   ├── controllers/
│   │   ├── gpioController.js # GPIO business logic
│   │   └── sensorController.js
│   ├── middleware/
│   │   ├── authenticate.js   # Basic authentication middleware
│   │   ├── validateInput.js  # Input validation middleware
│   │   ├── rateLimit.js      # Rate limiting middleware
│   │   ├── ipFilter.js       # IP whitelist middleware
│   │   ├── errorHandler.js   # Error handling middleware
│   │   ├── logger.js         # Request logging middleware
│   │   └── securityMonitor.js # Security monitoring
│   ├── hardware/
│   │   ├── gpioManager.js    # GPIO abstraction layer
│   │   └── sensorManager.js  # Sensor interfaces
│   ├── utils/
│   │   ├── logger.js         # Winston logger setup
│   │   ├── validator.js      # Input validation helpers
│   │   └── mqttPublisher.js  # MQTT publishing (Luigi integration)
│   └── security/
│       ├── pinValidator.js   # GPIO pin safety validation
│       └── auditLogger.js    # Security audit logging
├── certs/                    # SSL/TLS certificates
│   ├── server.crt
│   └── server.key
├── tests/
│   ├── unit/                 # Unit tests
│   ├── integration/          # Integration tests
│   ├── security/             # Security tests
│   └── mocks/
│       └── mockGpio.js       # GPIO mocking for tests
├── scripts/
│   ├── setup.sh              # Installation script
│   ├── deploy.sh             # Deployment script
│   └── generate-certs.sh     # Self-signed cert generator
└── README.md                 # Documentation
```

## Essential Dependencies

### Core Framework and Security

**package.json:**
```json
{
  "name": "luigi-api-server",
  "version": "1.0.0",
  "description": "Secure Node.js API server for Raspberry Pi Zero W",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "NODE_ENV=development nodemon server.js",
    "test": "jest --coverage",
    "audit": "npm audit --audit-level=moderate",
    "audit-fix": "npm audit fix"
  },
  "dependencies": {
    "express": "^4.18.2",
    "dotenv": "^16.0.3",
    "helmet": "^7.0.0",
    "cors": "^2.8.5",
    "compression": "^1.7.4",
    "express-rate-limit": "^6.7.0",
    "express-slow-down": "^1.6.0",
    "express-validator": "^7.0.1",
    "winston": "^3.8.2",
    "morgan": "^1.10.0",
    "joi": "^17.9.2",
    "onoff": "^6.0.3",
    "node-cache": "^5.1.2"
  },
  "devDependencies": {
    "jest": "^29.5.0",
    "supertest": "^6.3.3",
    "nodemon": "^2.0.22"
  },
  "engines": {
    "node": ">=16.0.0",
    "npm": ">=8.0.0"
  }
}
```

### Security Dependency Analysis

**Run security audit regularly:**
```bash
# Check for vulnerabilities
npm audit

# Fix vulnerabilities automatically (when possible)
npm audit fix

# Force fix (may introduce breaking changes)
npm audit fix --force

# Check specific package
npm view express versions
```

## 🔐 Authentication Implementation

### HTTP Basic Authentication

HTTP Basic Authentication provides a simple, built-in method for securing API endpoints. It's ideal for local network deployments where simplicity is preferred over complex token-based systems.

**Security Note:** Always use HTTPS with Basic Auth to prevent credentials from being transmitted in plaintext!

**Environment Configuration (.env):**
```bash
# NEVER commit this file!
NODE_ENV=production
PORT=8443
HOST=0.0.0.0

# Basic Authentication Credentials
AUTH_USERNAME=admin
AUTH_PASSWORD=your-secure-password-here

# Allowed IPs (comma-separated)
ALLOWED_IPS=192.168.1.100,192.168.1.101

# TLS/SSL (REQUIRED for Basic Auth!)
USE_HTTPS=true
TLS_CERT_PATH=/home/pi/certs/server.crt
TLS_KEY_PATH=/home/pi/certs/server.key
```

**Authentication Middleware:**
```javascript
// src/middleware/authenticate.js
const logger = require('../utils/logger');
const auditLogger = require('../security/auditLogger');

// Load credentials from environment
const AUTH_USERNAME = process.env.AUTH_USERNAME;
const AUTH_PASSWORD = process.env.AUTH_PASSWORD;

if (!AUTH_USERNAME || !AUTH_PASSWORD) {
  throw new Error('AUTH_USERNAME and AUTH_PASSWORD must be set in environment!');
}

// Warn if using default/weak password
if (AUTH_PASSWORD.length < 12) {
  logger.warn('WARNING: AUTH_PASSWORD is less than 12 characters. Use a stronger password!');
}

/**
 * HTTP Basic Authentication Middleware
 * 
 * Expects Authorization header: Basic base64(username:password)
 */
const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    logger.warn(`Authentication required but no header provided from ${req.ip}`);
    auditLogger.logUnauthorizedAccess(req.ip, req.path, null, 'No authorization header');
    
    // Send WWW-Authenticate header to prompt browser for credentials
    res.set('WWW-Authenticate', 'Basic realm="Luigi API"');
    return res.status(401).json({
      success: false,
      error: 'Authentication required'
    });
  }

  // Parse Basic auth header
  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Basic') {
    logger.warn(`Invalid authorization header format from ${req.ip}`);
    auditLogger.logSecurityViolation('invalid_auth_header', { header: parts[0] }, req.ip);
    
    return res.status(401).json({
      success: false,
      error: 'Invalid authorization header format',
      message: 'Expected "Basic base64(username:password)"'
    });
  }

  // Decode credentials
  let credentials;
  try {
    const decoded = Buffer.from(parts[1], 'base64').toString('utf-8');
    const colonIndex = decoded.indexOf(':');
    
    if (colonIndex === -1) {
      throw new Error('Invalid credentials format');
    }

    credentials = {
      username: decoded.substring(0, colonIndex),
      password: decoded.substring(colonIndex + 1)
    };
  } catch (error) {
    logger.warn(`Failed to decode credentials from ${req.ip}`);
    auditLogger.logSecurityViolation('invalid_credentials_encoding', {}, req.ip);
    
    return res.status(401).json({
      success: false,
      error: 'Invalid credentials format'
    });
  }

  // Verify credentials (constant-time comparison to prevent timing attacks)
  const usernameMatch = safeCompare(credentials.username, AUTH_USERNAME);
  const passwordMatch = safeCompare(credentials.password, AUTH_PASSWORD);

  if (!usernameMatch || !passwordMatch) {
    logger.warn(`Failed authentication attempt for username: ${credentials.username} from ${req.ip}`);
    auditLogger.logAuth(credentials.username, req.ip, false, 'Invalid credentials');
    
    return res.status(401).json({
      success: false,
      error: 'Invalid credentials'
    });
  }

  // Authentication successful
  req.user = {
    username: credentials.username,
    authenticated: true
  };

  logger.debug(`Authenticated request from user: ${credentials.username}`);
  auditLogger.logAuth(credentials.username, req.ip, true);

  next();
};

/**
 * Constant-time string comparison to prevent timing attacks
 */
function safeCompare(a, b) {
  if (a.length !== b.length) {
    return false;
  }

  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }

  return result === 0;
}

/**
 * Optional: Check if request is authenticated (doesn't require auth)
 * Useful for endpoints that behave differently when authenticated
 */
const optionalAuth = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    req.user = null;
    return next();
  }

  // Try to authenticate, but don't fail if it doesn't work
  authenticate(req, res, (err) => {
    if (err) {
      req.user = null;
    }
    next();
  });
};

module.exports = {
  authenticate,
  optionalAuth
};
```

**Usage in Routes:**
```javascript
// src/routes/gpio.js
const express = require('express');
const { authenticate } = require('../middleware/authenticate');
const gpioController = require('../controllers/gpioController');
const { gpioLimiter } = require('../middleware/rateLimit');

const router = express.Router();

// Apply authentication to all GPIO routes
router.use(authenticate);

// Apply rate limiting
router.use(gpioLimiter);

// All authenticated routes
router.get('/pins', gpioController.listPins);
router.get('/input/:pin', gpioController.getInput);
router.post('/output/:pin', gpioController.setOutput);
router.post('/setup/output', gpioController.setupOutput);
router.post('/setup/input', gpioController.setupInput);
router.delete('/:pin', gpioController.releasePin);

module.exports = router;
```

**Testing Authentication:**
```bash
# Test without authentication (should fail with 401)
curl -k https://localhost:8443/api/gpio/pins

# Test with valid credentials
curl -k https://localhost:8443/api/gpio/pins \
  -u admin:your-secure-password-here

# Test with invalid credentials (should fail with 401)
curl -k https://localhost:8443/api/gpio/pins \
  -u admin:wrong-password

# Using Authorization header directly
curl -k https://localhost:8443/api/gpio/pins \
  -H "Authorization: Basic $(echo -n 'admin:your-secure-password-here' | base64)"
```

**Browser Usage:**
When accessing the API from a web browser, the browser will automatically prompt for username and password when it receives a 401 response with the `WWW-Authenticate` header.

**Client Library Usage:**
```javascript
// JavaScript/Node.js client
const axios = require('axios');

const api = axios.create({
  baseURL: 'https://192.168.1.10:8443/api',
  auth: {
    username: 'admin',
    password: 'your-secure-password-here'
  },
  httpsAgent: new https.Agent({
    rejectUnauthorized: false // Only for self-signed certs
  })
});

// Make authenticated request
const response = await api.get('/gpio/pins');
```

```python
# Python client
import requests

response = requests.get(
    'https://192.168.1.10:8443/api/gpio/pins',
    auth=('admin', 'your-secure-password-here'),
    verify=False  # Only for self-signed certs
)
```

### Password Management

**Generating Secure Passwords:**
```bash
# Generate a random 20-character password
openssl rand -base64 20

# Or use Node.js
node -e "console.log(require('crypto').randomBytes(20).toString('base64'))"
```

**Changing Password:**
```bash
# 1. Edit .env file
nano /etc/luigi/api-server/.env

# 2. Update AUTH_PASSWORD
AUTH_PASSWORD=new-secure-password-here

# 3. Restart service
sudo systemctl restart luigi-api
```

**Security Best Practices for Basic Auth:**
- ✅ **Always use HTTPS** - Basic Auth sends base64-encoded credentials (not encrypted!)
- ✅ **Use strong passwords** - Minimum 12 characters, mix of letters, numbers, symbols
- ✅ **Change default credentials** - Never use default passwords in production
- ✅ **Limit failed attempts** - Use rate limiting to prevent brute force attacks
- ✅ **Monitor logs** - Watch for failed authentication attempts
- ✅ **Restrict IPs** - Use IP whitelisting for additional security
- ✅ **Use environment variables** - Never hardcode credentials in source code

## 🛡️ Input Validation and Sanitization

### Comprehensive Input Validation

```javascript
// src/middleware/validateInput.js
const { body, param, query, validationResult } = require('express-validator');
const logger = require('../utils/logger');

/**
 * Validation error handler
 */
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  
  if (!errors.isEmpty()) {
    logger.warn(`Validation failed for ${req.method} ${req.path}:`, errors.array());
    return res.status(400).json({
      success: false,
      error: 'Validation failed',
      details: errors.array()
    });
  }
  
  next();
};

/**
 * GPIO Pin Validation Rules
 * 
 * Safe GPIO pins for Raspberry Pi Zero W (BCM numbering):
 * - Avoid: 0, 1 (I2C), 2, 3 (I2C), 7, 8, 9, 10, 11 (SPI), 14, 15 (UART)
 * - Safe for general use: 4, 17, 18, 22, 23, 24, 25, 27
 * - Be cautious with: 5, 6, 12, 13, 16, 19, 20, 21, 26
 */
const SAFE_GPIO_PINS = [4, 17, 18, 22, 23, 24, 25, 27];
const ALL_GPIO_PINS = [4, 5, 6, 12, 13, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27];

const gpioValidation = {
  /**
   * Validate GPIO pin number (strict - only safe pins)
   */
  pin: param('pin')
    .isInt({ min: 2, max: 27 })
    .withMessage('Pin must be between 2 and 27')
    .custom((value) => {
      if (!ALL_GPIO_PINS.includes(parseInt(value))) {
        throw new Error('Invalid GPIO pin number');
      }
      return true;
    }),

  /**
   * Validate GPIO pin in request body
   */
  pinBody: body('pin')
    .isInt({ min: 2, max: 27 })
    .withMessage('Pin must be between 2 and 27')
    .custom((value) => {
      if (!ALL_GPIO_PINS.includes(parseInt(value))) {
        throw new Error('Invalid GPIO pin number');
      }
      return true;
    }),

  /**
   * Validate GPIO pin value (0 or 1)
   */
  value: body('value')
    .custom((value) => {
      if (value === 0 || value === 1 || value === '0' || value === '1' || 
          value === true || value === false) {
        return true;
      }
      throw new Error('Value must be 0, 1, true, or false');
    }),

  /**
   * Validate edge type for input pins
   */
  edge: body('edge')
    .optional()
    .isIn(['none', 'rising', 'falling', 'both'])
    .withMessage('Edge must be: none, rising, falling, or both'),

  /**
   * Warn if using non-safe GPIO pin
   */
  warnUnsafePin: (req, res, next) => {
    const pin = parseInt(req.params.pin || req.body.pin);
    if (pin && !SAFE_GPIO_PINS.includes(pin)) {
      logger.warn(`Using non-standard GPIO pin ${pin} - ensure this is intentional`);
    }
    next();
  }
};

/**
 * Sensor validation rules
 */
const sensorValidation = {
  temperature: body('value')
    .isFloat({ min: -50, max: 100 })
    .withMessage('Temperature must be between -50 and 100'),

  humidity: body('value')
    .isFloat({ min: 0, max: 100 })
    .withMessage('Humidity must be between 0 and 100'),

  pressure: body('value')
    .isFloat({ min: 800, max: 1200 })
    .withMessage('Pressure must be between 800 and 1200'),

  boolean: body('value')
    .isBoolean()
    .withMessage('Value must be boolean (true/false)')
};

/**
 * General validation rules
 */
const generalValidation = {
  /**
   * Sanitize string input (prevent XSS)
   */
  sanitizeString: body('*')
    .optional()
    .trim()
    .escape(),

  /**
   * Limit pagination
   */
  pagination: [
    query('page')
      .optional()
      .isInt({ min: 1, max: 1000 })
      .withMessage('Page must be between 1 and 1000'),
    query('limit')
      .optional()
      .isInt({ min: 1, max: 100 })
      .withMessage('Limit must be between 1 and 100')
  ]
};

module.exports = {
  handleValidationErrors,
  gpioValidation,
  sensorValidation,
  generalValidation,
  SAFE_GPIO_PINS,
  ALL_GPIO_PINS
};
```

## 🚦 Rate Limiting and DDoS Protection

### Multi-Layer Rate Limiting

```javascript
// src/middleware/rateLimit.js
const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');
const logger = require('../utils/logger');

/**
 * General API rate limiter
 * 100 requests per 15 minutes per IP
 */
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  message: {
    success: false,
    error: 'Too many requests',
    message: 'Please try again later'
  },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    logger.warn(`Rate limit exceeded for IP: ${req.ip} on ${req.path}`);
    res.status(429).json({
      success: false,
      error: 'Rate limit exceeded',
      message: 'Too many requests. Please try again later.'
    });
  }
});

/**
 * Strict limiter for authentication endpoints
 * 5 attempts per 15 minutes per IP
 */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  skipSuccessfulRequests: true, // Don't count successful logins
  message: {
    success: false,
    error: 'Too many login attempts',
    message: 'Account temporarily locked. Try again in 15 minutes.'
  },
  handler: (req, res) => {
    logger.warn(`Auth rate limit exceeded for IP: ${req.ip}`);
    res.status(429).json({
      success: false,
      error: 'Too many login attempts',
      message: 'Account temporarily locked. Try again in 15 minutes.'
    });
  }
});

/**
 * GPIO operation rate limiter
 * 50 requests per minute per IP
 */
const gpioLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 50,
  message: {
    success: false,
    error: 'GPIO rate limit exceeded',
    message: 'Too many GPIO operations. Please slow down.'
  },
  handler: (req, res) => {
    logger.warn(`GPIO rate limit exceeded for IP: ${req.ip}`);
    res.status(429).json({
      success: false,
      error: 'GPIO rate limit exceeded',
      message: 'Too many GPIO operations. Please slow down.'
    });
  }
});

/**
 * Speed limiter - slows down requests instead of blocking
 * Starts slowing after 10 requests in 1 minute
 */
const speedLimiter = slowDown({
  windowMs: 1 * 60 * 1000, // 1 minute
  delayAfter: 10, // Allow 10 requests at full speed
  delayMs: 100, // Add 100ms delay per request after limit
  maxDelayMs: 5000, // Maximum 5 second delay
  onLimitReached: (req, res, options) => {
    logger.info(`Speed limit applied for IP: ${req.ip}`);
  }
});

/**
 * Per-user rate limiter (requires authentication)
 */
const createUserLimiter = (maxRequests, windowMinutes = 15) => {
  const store = new Map();
  
  return (req, res, next) => {
    if (!req.user) {
      return next(); // Skip if not authenticated
    }

    const userId = req.user.id;
    const now = Date.now();
    const windowMs = windowMinutes * 60 * 1000;

    if (!store.has(userId)) {
      store.set(userId, { count: 1, resetTime: now + windowMs });
      return next();
    }

    const userData = store.get(userId);

    if (now > userData.resetTime) {
      // Reset window
      userData.count = 1;
      userData.resetTime = now + windowMs;
      return next();
    }

    if (userData.count >= maxRequests) {
      logger.warn(`User rate limit exceeded for user: ${req.user.username}`);
      return res.status(429).json({
        success: false,
        error: 'Rate limit exceeded',
        message: `Maximum ${maxRequests} requests per ${windowMinutes} minutes`
      });
    }

    userData.count++;
    next();
  };
};

module.exports = {
  apiLimiter,
  authLimiter,
  gpioLimiter,
  speedLimiter,
  createUserLimiter
};
```

## 🔒 HTTPS/TLS Configuration

### Self-Signed Certificate Generation

```bash
#!/bin/bash
# scripts/generate-certs.sh

set -e

CERTS_DIR="/home/pi/certs"
DAYS_VALID=365

echo "Generating self-signed SSL certificate..."

# Create certs directory
mkdir -p "$CERTS_DIR"
cd "$CERTS_DIR"

# Generate private key
openssl genrsa -out server.key 2048

# Generate certificate signing request
openssl req -new -key server.key -out server.csr \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=raspberrypi.local"

# Generate self-signed certificate
openssl x509 -req -days $DAYS_VALID -in server.csr \
  -signkey server.key -out server.crt

# Set proper permissions
chmod 600 server.key
chmod 644 server.crt

echo "Certificate generated successfully!"
echo "Certificate location: $CERTS_DIR/server.crt"
echo "Private key location: $CERTS_DIR/server.key"
echo "Valid for $DAYS_VALID days"
```

### HTTPS Server Setup

```javascript
// server.js with HTTPS support
require('dotenv').config();
const fs = require('fs');
const https = require('https');
const http = require('http');
const app = require('./src/app');
const config = require('./config');
const logger = require('./src/utils/logger');
const gpioManager = require('./src/hardware/gpioManager');

const PORT = config.port || 8443;
const HOST = config.host || '0.0.0.0';
const USE_HTTPS = process.env.USE_HTTPS === 'true';

async function startServer() {
  try {
    // Initialize GPIO if not in test mode
    if (process.env.NODE_ENV !== 'test') {
      await gpioManager.initialize();
      logger.info('GPIO system initialized');
    }

    let server;

    if (USE_HTTPS) {
      // HTTPS server
      const certPath = process.env.TLS_CERT_PATH || '/home/pi/certs/server.crt';
      const keyPath = process.env.TLS_KEY_PATH || '/home/pi/certs/server.key';

      if (!fs.existsSync(certPath) || !fs.existsSync(keyPath)) {
        logger.error('SSL certificate or key not found!');
        logger.error(`Run: bash scripts/generate-certs.sh`);
        process.exit(1);
      }

      const httpsOptions = {
        key: fs.readFileSync(keyPath),
        cert: fs.readFileSync(certPath),
        // TLS options for security
        minVersion: 'TLSv1.2',
        ciphers: [
          'ECDHE-ECDSA-AES128-GCM-SHA256',
          'ECDHE-RSA-AES128-GCM-SHA256',
          'ECDHE-ECDSA-AES256-GCM-SHA384',
          'ECDHE-RSA-AES256-GCM-SHA384'
        ].join(':'),
        honorCipherOrder: true
      };

      server = https.createServer(httpsOptions, app);
      logger.info('HTTPS enabled');
    } else {
      // HTTP server (development only!)
      server = http.createServer(app);
      logger.warn('HTTPS disabled - Use only for development!');
    }

    // Start server
    server.listen(PORT, HOST, () => {
      const protocol = USE_HTTPS ? 'https' : 'http';
      logger.info(`Server running on ${protocol}://${HOST}:${PORT}`);
      logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
    });

    // Graceful shutdown
    const shutdown = async (signal) => {
      logger.info(`${signal} received, shutting down gracefully`);
      
      server.close(() => {
        logger.info('HTTP server closed');
        gpioManager.cleanup();
        process.exit(0);
      });

      // Force shutdown after 10 seconds
      setTimeout(() => {
        logger.error('Forced shutdown after timeout');
        process.exit(1);
      }, 10000);
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));

  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();
```


## 🌐 Network Security and Firewall Configuration

### UFW Firewall Setup

```bash
#!/bin/bash
# Secure firewall configuration for Luigi API server

# Enable UFW
sudo ufw --force enable

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (important - don't lock yourself out!)
sudo ufw allow 22/tcp

# Allow API server on specific port
sudo ufw allow 8443/tcp comment 'Luigi API HTTPS'

# Allow only from specific IPs (recommended for production)
# sudo ufw allow from 192.168.1.100 to any port 8443 proto tcp

# Allow MQTT (if using ha-mqtt)
sudo ufw allow 1883/tcp comment 'MQTT'

# Check status
sudo ufw status verbose
```

### IP Whitelist Middleware

```javascript
// src/middleware/ipFilter.js
const logger = require('../utils/logger');

/**
 * IP Whitelist middleware
 * Only allows requests from specified IP addresses
 */
const ipWhitelist = (req, res, next) => {
  const allowedIPs = process.env.ALLOWED_IPS?.split(',').map(ip => ip.trim()) || [];
  
  // If no whitelist configured, allow all (log warning)
  if (allowedIPs.length === 0) {
    logger.warn('IP whitelist not configured - allowing all IPs');
    return next();
  }

  const clientIP = req.ip || req.connection.remoteAddress;
  const normalizedIP = clientIP.replace('::ffff:', ''); // Remove IPv6 prefix

  if (allowedIPs.includes(normalizedIP)) {
    return next();
  }

  logger.warn(`Blocked request from unauthorized IP: ${normalizedIP} to ${req.path}`);
  
  res.status(403).json({
    success: false,
    error: 'Access denied',
    message: 'Your IP address is not authorized to access this API'
  });
};

/**
 * Local network only middleware
 * Only allows requests from local network (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
 */
const localNetworkOnly = (req, res, next) => {
  const clientIP = req.ip || req.connection.remoteAddress;
  const normalizedIP = clientIP.replace('::ffff:', '');

  // Check if IP is localhost
  if (normalizedIP === '127.0.0.1' || normalizedIP === '::1') {
    return next();
  }

  // Check if IP is in private ranges
  const isLocal = (
    normalizedIP.startsWith('192.168.') ||
    normalizedIP.startsWith('10.') ||
    /^172\.(1[6-9]|2[0-9]|3[0-1])\./.test(normalizedIP)
  );

  if (isLocal) {
    return next();
  }

  logger.warn(`Blocked external IP: ${normalizedIP} attempting to access ${req.path}`);
  
  res.status(403).json({
    success: false,
    error: 'Access denied',
    message: 'This API is only accessible from local network'
  });
};

module.exports = {
  ipWhitelist,
  localNetworkOnly
};
```

### Apply Network Security

```javascript
// src/app.js - Add IP filtering
const { ipWhitelist, localNetworkOnly } = require('./middleware/ipFilter');

// Apply to all routes (choose one)
// app.use(ipWhitelist);        // Strict whitelist
app.use(localNetworkOnly);   // Allow all local network IPs

// Or apply selectively
app.use('/api/gpio', ipWhitelist, gpioRoutes);
```

## GPIO Security and Safety

### Hardware Protection Layer

```javascript
// src/security/pinValidator.js
const logger = require('../utils/logger');

/**
 * GPIO Pin Safety Rules
 * 
 * CRITICAL: Some pins can damage hardware if misconfigured!
 * - Pins 0, 1: I2C (3.3V only, has pull-up resistors)
 * - Pins 2, 3: I2C (3.3V only, has pull-up resistors)
 * - Pins 7-11: SPI interface
 * - Pins 14, 15: UART (console by default)
 * - Pin 18: Hardware PWM
 */

// Pins that should never be used without explicit override
const RESERVED_PINS = [0, 1, 2, 3];

// Pins that are generally safe for GPIO
const SAFE_PINS = [4, 17, 18, 22, 23, 24, 25, 27];

// Pins that require caution (used by SPI, UART, etc.)
const CAUTION_PINS = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 19, 20, 21, 26];

// Maximum concurrent pin operations to prevent resource exhaustion
const MAX_ACTIVE_PINS = 10;

class PinValidator {
  constructor() {
    this.activePins = new Set();
    this.pinConfig = new Map();
  }

  /**
   * Validate if pin can be used
   */
  validatePin(pinNumber, allowReserved = false) {
    const errors = [];

    // Check if pin number is valid
    if (!Number.isInteger(pinNumber) || pinNumber < 2 || pinNumber > 27) {
      errors.push(`Invalid pin number: ${pinNumber} (must be 2-27)`);
    }

    // Check if pin is reserved
    if (!allowReserved && RESERVED_PINS.includes(pinNumber)) {
      errors.push(`Pin ${pinNumber} is reserved for system use`);
    }

    // Check if pin requires caution
    if (CAUTION_PINS.includes(pinNumber)) {
      logger.warn(`Pin ${pinNumber} requires caution - used by SPI/UART/PWM`);
    }

    // Check maximum active pins
    if (this.activePins.size >= MAX_ACTIVE_PINS) {
      errors.push(`Maximum number of active pins (${MAX_ACTIVE_PINS}) reached`);
    }

    return {
      valid: errors.length === 0,
      errors,
      warnings: CAUTION_PINS.includes(pinNumber) ? 
        [`Pin ${pinNumber} may conflict with SPI/UART/PWM`] : []
    };
  }

  /**
   * Register pin as active
   */
  registerPin(pinNumber, direction, metadata = {}) {
    this.activePins.add(pinNumber);
    this.pinConfig.set(pinNumber, {
      direction,
      registered: new Date(),
      ...metadata
    });
    logger.info(`Pin ${pinNumber} registered as ${direction}`);
  }

  /**
   * Unregister pin
   */
  unregisterPin(pinNumber) {
    this.activePins.delete(pinNumber);
    this.pinConfig.delete(pinNumber);
    logger.info(`Pin ${pinNumber} unregistered`);
  }

  /**
   * Check if pin is in use
   */
  isPinActive(pinNumber) {
    return this.activePins.has(pinNumber);
  }

  /**
   * Get pin configuration
   */
  getPinConfig(pinNumber) {
    return this.pinConfig.get(pinNumber);
  }

  /**
   * List all active pins
   */
  getActivePins() {
    return Array.from(this.activePins);
  }

  /**
   * Safety check before write operation
   */
  validateWrite(pinNumber, value) {
    const errors = [];

    if (!this.isPinActive(pinNumber)) {
      errors.push(`Pin ${pinNumber} is not initialized`);
    }

    const config = this.getPinConfig(pinNumber);
    if (config && config.direction !== 'out') {
      errors.push(`Pin ${pinNumber} is configured as ${config.direction}, not output`);
    }

    if (value !== 0 && value !== 1) {
      errors.push(`Invalid value: ${value} (must be 0 or 1)`);
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }
}

module.exports = new PinValidator();
```

### Secure GPIO Manager with Safety Checks

```javascript
// src/hardware/gpioManager.js (security-enhanced version)
const Gpio = require('onoff').Gpio;
const logger = require('../utils/logger');
const pinValidator = require('../security/pinValidator');

class GpioManager {
  constructor() {
    this.pins = new Map();
    this.initialized = false;
  }

  /**
   * Initialize GPIO system
   */
  async initialize() {
    try {
      // Test GPIO access
      const testPin = new Gpio(4, 'out');
      testPin.unexport();
      
      this.initialized = true;
      logger.info('GPIO system initialized');
    } catch (error) {
      logger.error('GPIO initialization failed:', error);
      this.initialized = false;
      throw error;
    }
  }

  /**
   * Setup an output pin with safety validation
   */
  setupOutput(pinNumber, initialValue = 0) {
    // Validate pin
    const validation = pinValidator.validatePin(pinNumber);
    if (!validation.valid) {
      const error = new Error(`Pin validation failed: ${validation.errors.join(', ')}`);
      logger.error(error.message);
      throw error;
    }

    // Check if pin already in use
    if (pinValidator.isPinActive(pinNumber)) {
      throw new Error(`Pin ${pinNumber} is already in use`);
    }

    try {
      const pin = new Gpio(pinNumber, 'out');
      pin.writeSync(initialValue);
      this.pins.set(pinNumber, pin);
      
      pinValidator.registerPin(pinNumber, 'out', { initialValue });
      
      logger.info(`Output pin ${pinNumber} initialized (initial value: ${initialValue})`);
      return pin;
    } catch (error) {
      logger.error(`Failed to setup output pin ${pinNumber}:`, error);
      throw error;
    }
  }

  /**
   * Setup an input pin with safety validation
   */
  setupInput(pinNumber, edge = 'both', callback) {
    // Validate pin
    const validation = pinValidator.validatePin(pinNumber);
    if (!validation.valid) {
      const error = new Error(`Pin validation failed: ${validation.errors.join(', ')}`);
      logger.error(error.message);
      throw error;
    }

    // Check if pin already in use
    if (pinValidator.isPinActive(pinNumber)) {
      throw new Error(`Pin ${pinNumber} is already in use`);
    }

    try {
      const pin = new Gpio(pinNumber, 'in', edge);
      
      if (callback) {
        pin.watch((err, value) => {
          if (err) {
            logger.error(`Error reading pin ${pinNumber}:`, err);
            return;
          }
          callback(value);
        });
      }

      this.pins.set(pinNumber, pin);
      pinValidator.registerPin(pinNumber, 'in', { edge });
      
      logger.info(`Input pin ${pinNumber} initialized (edge: ${edge})`);
      return pin;
    } catch (error) {
      logger.error(`Failed to setup input pin ${pinNumber}:`, error);
      throw error;
    }
  }

  /**
   * Write to output pin with safety checks
   */
  writePin(pinNumber, value) {
    // Validate write operation
    const validation = pinValidator.validateWrite(pinNumber, value);
    if (!validation.valid) {
      const error = new Error(`Write validation failed: ${validation.errors.join(', ')}`);
      logger.error(error.message);
      throw error;
    }

    const pin = this.pins.get(pinNumber);
    
    try {
      pin.writeSync(value);
      logger.debug(`Wrote ${value} to pin ${pinNumber}`);
    } catch (error) {
      logger.error(`Failed to write to pin ${pinNumber}:`, error);
      throw error;
    }
  }

  /**
   * Read from input pin
   */
  readPin(pinNumber) {
    if (!pinValidator.isPinActive(pinNumber)) {
      throw new Error(`Pin ${pinNumber} is not initialized`);
    }

    const pin = this.pins.get(pinNumber);

    try {
      return pin.readSync();
    } catch (error) {
      logger.error(`Failed to read pin ${pinNumber}:`, error);
      throw error;
    }
  }

  /**
   * Cleanup all GPIO pins
   */
  cleanup() {
    logger.info('Cleaning up GPIO pins');
    for (const [pinNumber, pin] of this.pins.entries()) {
      try {
        pin.unexport();
        pinValidator.unregisterPin(pinNumber);
        logger.debug(`Pin ${pinNumber} unexported`);
      } catch (error) {
        logger.error(`Failed to unexport pin ${pinNumber}:`, error);
      }
    }
    this.pins.clear();
    this.initialized = false;
  }

  /**
   * Check if GPIO is available
   */
  isAvailable() {
    return this.initialized;
  }

  /**
   * Get statistics
   */
  getStatistics() {
    return {
      initialized: this.initialized,
      activePins: pinValidator.getActivePins(),
      pinCount: this.pins.size
    };
  }
}

// Singleton instance
const gpioManager = new GpioManager();

// Graceful shutdown
process.on('SIGINT', () => {
  gpioManager.cleanup();
  process.exit(0);
});

process.on('SIGTERM', () => {
  gpioManager.cleanup();
  process.exit(0);
});

module.exports = gpioManager;
```

## 📊 Security Logging and Monitoring

### Audit Logger

```javascript
// src/security/auditLogger.js
const winston = require('winston');
const path = require('path');

const auditLogPath = process.env.AUDIT_LOG_PATH || '/var/log/luigi/audit.log';

// Create audit logger (separate from application logger)
const auditLogger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({
      filename: auditLogPath,
      maxsize: 10485760, // 10MB
      maxFiles: 10
    }),
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    })
  ]
});

/**
 * Log security events
 */
class AuditLogger {
  /**
   * Log authentication attempt
   */
  logAuth(username, ip, success, reason = null) {
    auditLogger.info({
      event: 'authentication',
      username,
      ip,
      success,
      reason,
      timestamp: new Date().toISOString()
    });
  }

  /**
   * Log GPIO operation
   */
  logGpioOperation(user, pin, operation, value, ip) {
    auditLogger.info({
      event: 'gpio_operation',
      user: user.username,
      userId: user.id,
      pin,
      operation,
      value,
      ip,
      timestamp: new Date().toISOString()
    });
  }

  /**
   * Log security violation
   */
  logSecurityViolation(type, details, ip, user = null) {
    auditLogger.warn({
      event: 'security_violation',
      type,
      details,
      ip,
      user: user ? user.username : 'anonymous',
      timestamp: new Date().toISOString()
    });
  }

  /**
   * Log rate limit exceeded
   */
  logRateLimit(ip, endpoint, user = null) {
    auditLogger.warn({
      event: 'rate_limit_exceeded',
      ip,
      endpoint,
      user: user ? user.username : 'anonymous',
      timestamp: new Date().toISOString()
    });
  }

  /**
   * Log unauthorized access attempt
   */
  logUnauthorizedAccess(ip, endpoint, user = null, reason = null) {
    auditLogger.warn({
      event: 'unauthorized_access',
      ip,
      endpoint,
      user: user ? user.username : 'anonymous',
      reason,
      timestamp: new Date().toISOString()
    });
  }

  /**
   * Log configuration change
   */
  logConfigChange(user, setting, oldValue, newValue, ip) {
    auditLogger.info({
      event: 'config_change',
      user: user.username,
      userId: user.id,
      setting,
      oldValue,
      newValue,
      ip,
      timestamp: new Date().toISOString()
    });
  }
}

module.exports = new AuditLogger();
```

### Security Monitoring Middleware

```javascript
// src/middleware/securityMonitor.js
const auditLogger = require('../security/auditLogger');

/**
 * Log all API requests for security monitoring
 */
const securityMonitor = (req, res, next) => {
  const startTime = Date.now();

  // Log request
  const logData = {
    method: req.method,
    path: req.path,
    ip: req.ip,
    userAgent: req.get('user-agent'),
    user: req.user ? req.user.username : 'anonymous'
  };

  // Intercept response
  const originalSend = res.send;
  res.send = function(data) {
    res.send = originalSend;
    
    const duration = Date.now() - startTime;
    
    // Log suspicious activity
    if (res.statusCode === 401 || res.statusCode === 403) {
      auditLogger.logUnauthorizedAccess(
        req.ip,
        req.path,
        req.user,
        `Status: ${res.statusCode}`
      );
    }

    // Log long requests (potential DoS)
    if (duration > 5000) {
      auditLogger.logSecurityViolation(
        'slow_request',
        { path: req.path, duration },
        req.ip,
        req.user
      );
    }

    return res.send(data);
  };

  next();
};

module.exports = securityMonitor;
```

## Express.js Application Setup with Security

```javascript
// src/app.js - Complete secure setup
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const compression = require('compression');
const morgan = require('morgan');

const routes = require('./routes');
const errorHandler = require('./middleware/errorHandler');
const logger = require('./utils/logger');
const { apiLimiter } = require('./middleware/rateLimit');
const { localNetworkOnly } = require('./middleware/ipFilter');
const securityMonitor = require('./middleware/securityMonitor');

const app = express();

// Trust proxy (if behind nginx/apache)
app.set('trust proxy', 1);

// Security headers with Helmet
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", 'data:', 'https:'],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  },
  frameguard: {
    action: 'deny'
  },
  noSniff: true,
  xssFilter: true
}));

// Disable X-Powered-By header
app.disable('x-powered-by');

// CORS configuration (restrictive)
app.use(cors({
  origin: process.env.CORS_ORIGIN || false, // No origin by default
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-API-Key'],
  credentials: true,
  maxAge: 600 // 10 minutes
}));

// Compression
app.use(compression());

// Body parsing with size limits
app.use(express.json({ 
  limit: '1mb',
  strict: true
}));
app.use(express.urlencoded({ 
  extended: true, 
  limit: '1mb'
}));

// Request logging
const morganFormat = process.env.NODE_ENV === 'production' ? 'combined' : 'dev';
app.use(morgan(morganFormat, {
  stream: {
    write: (message) => logger.info(message.trim())
  },
  skip: (req) => req.path === '/health' // Skip health checks
}));

// Security monitoring
app.use(securityMonitor);

// IP filtering (local network only)
app.use(localNetworkOnly);

// Global rate limiting
app.use(apiLimiter);

// Routes
app.use('/api', routes);

// Health check (public, no auth)
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// 404 handler
app.use((req, res) => {
  logger.warn(`404 Not Found: ${req.method} ${req.path} from ${req.ip}`);
  res.status(404).json({
    success: false,
    error: 'Not Found',
    message: `Route ${req.method} ${req.path} not found`
  });
});

// Error handler (must be last)
app.use(errorHandler);

module.exports = app;
```

## Complete Route Setup

```javascript
// src/routes/index.js
const express = require('express');
const gpioRoutes = require('./gpio');
const sensorRoutes = require('./sensors');
const healthRoutes = require('./health');

const router = express.Router();

// Public routes (no authentication)
router.use('/health', healthRoutes);

// Protected routes (authentication required)
router.use('/gpio', gpioRoutes);
router.use('/sensors', sensorRoutes);

module.exports = router;
```

## Performance Optimization for Raspberry Pi Zero W

### Memory Management

```javascript
// src/utils/memoryMonitor.js
const os = require('os');
const logger = require('./logger');

class MemoryMonitor {
  constructor(options = {}) {
    this.warningThreshold = options.warningThreshold || 400 * 1024 * 1024; // 400MB
    this.criticalThreshold = options.criticalThreshold || 450 * 1024 * 1024; // 450MB
    this.checkInterval = options.checkInterval || 60000; // 1 minute
    this.intervalId = null;
  }

  /**
   * Start monitoring memory usage
   */
  start() {
    logger.info('Memory monitor started');
    
    this.intervalId = setInterval(() => {
      this.check();
    }, this.checkInterval);

    // Initial check
    this.check();
  }

  /**
   * Stop monitoring
   */
  stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
      logger.info('Memory monitor stopped');
    }
  }

  /**
   * Check current memory usage
   */
  check() {
    const used = process.memoryUsage();
    const systemFree = os.freemem();
    const systemTotal = os.totalmem();
    const systemUsed = systemTotal - systemFree;

    const stats = {
      process: {
        rss: used.rss,
        heapTotal: used.heapTotal,
        heapUsed: used.heapUsed,
        external: used.external
      },
      system: {
        free: systemFree,
        used: systemUsed,
        total: systemTotal,
        percentUsed: Math.round((systemUsed / systemTotal) * 100)
      }
    };

    // Check for memory warnings
    if (used.heapUsed > this.criticalThreshold) {
      logger.error('CRITICAL: Memory usage exceeded critical threshold', {
        heapUsed: `${Math.round(used.heapUsed / 1024 / 1024)}MB`,
        threshold: `${Math.round(this.criticalThreshold / 1024 / 1024)}MB`
      });
      
      // Force garbage collection if available
      if (global.gc) {
        logger.info('Forcing garbage collection');
        global.gc();
      }
    } else if (used.heapUsed > this.warningThreshold) {
      logger.warn('WARNING: Memory usage high', {
        heapUsed: `${Math.round(used.heapUsed / 1024 / 1024)}MB`,
        threshold: `${Math.round(this.warningThreshold / 1024 / 1024)}MB`
      });
    }

    return stats;
  }

  /**
   * Get formatted memory statistics
   */
  getStats() {
    const stats = this.check();
    
    return {
      process: {
        rss: `${Math.round(stats.process.rss / 1024 / 1024)}MB`,
        heapTotal: `${Math.round(stats.process.heapTotal / 1024 / 1024)}MB`,
        heapUsed: `${Math.round(stats.process.heapUsed / 1024 / 1024)}MB`,
        external: `${Math.round(stats.process.external / 1024 / 1024)}MB`
      },
      system: {
        free: `${Math.round(stats.system.free / 1024 / 1024)}MB`,
        used: `${Math.round(stats.system.used / 1024 / 1024)}MB`,
        total: `${Math.round(stats.system.total / 1024 / 1024)}MB`,
        percentUsed: `${stats.system.percentUsed}%`
      }
    };
  }
}

module.exports = MemoryMonitor;
```

### Performance Best Practices

**1. Use Streams for Large Data:**
```javascript
// Bad: Loading entire file into memory
const data = fs.readFileSync('large-file.json');
res.send(data);

// Good: Stream the file
const stream = fs.createReadStream('large-file.json');
stream.pipe(res);
```

**2. Implement Caching:**
```javascript
const NodeCache = require('node-cache');
const cache = new NodeCache({ stdTTL: 300, checkperiod: 60 });

app.get('/api/sensor/:id', async (req, res) => {
  const cacheKey = `sensor_${req.params.id}`;
  
  // Check cache
  const cached = cache.get(cacheKey);
  if (cached) {
    return res.json(cached);
  }
  
  // Get data
  const data = await getSensorData(req.params.id);
  
  // Cache it
  cache.set(cacheKey, data);
  
  res.json(data);
});
```

**3. Limit Concurrent Connections:**
```javascript
const server = app.listen(PORT);
server.maxConnections = 50; // Limit to 50 concurrent connections
```

**4. Use Connection Timeouts:**
```javascript
app.use((req, res, next) => {
  req.setTimeout(30000); // 30 second timeout
  res.setTimeout(30000);
  next();
});
```

**5. Debounce Events:**
```javascript
const debounce = require('lodash.debounce');

// Debounce sensor reads
const debouncedSensorRead = debounce(() => {
  const value = gpioManager.readPin(23);
  // Process value
}, 500); // Wait 500ms after last trigger
```

## Deployment and Service Management

### systemd Service Configuration

Create `/etc/systemd/system/luigi-api.service`:

```ini
[Unit]
Description=Luigi Node.js API Server
Documentation=https://github.com/pkathmann88/luigi
After=network.target

[Service]
Type=simple
User=pi
Group=pi
WorkingDirectory=/home/pi/luigi/api-server

# Environment
Environment="NODE_ENV=production"
Environment="PORT=8443"
Environment="USE_HTTPS=true"
EnvironmentFile=/etc/luigi/api-server/.env

# Execute
ExecStart=/usr/bin/node server.js

# Restart policy
Restart=always
RestartSec=10

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=luigi-api

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=/var/log/luigi /tmp

# Resource limits
LimitNOFILE=4096
MemoryMax=400M
CPUQuota=80%

[Install]
WantedBy=multi-user.target
```

### Service Management Commands

```bash
# Enable service
sudo systemctl enable luigi-api

# Start service
sudo systemctl start luigi-api

# Check status
sudo systemctl status luigi-api

# View logs
sudo journalctl -u luigi-api -f

# View logs from last boot
sudo journalctl -u luigi-api -b

# Restart service
sudo systemctl restart luigi-api

# Stop service
sudo systemctl stop luigi-api

# Disable service
sudo systemctl disable luigi-api
```

### Deployment Script

```bash
#!/bin/bash
# scripts/deploy.sh

set -e

PROJECT_DIR="/home/pi/luigi/api-server"
SERVICE_NAME="luigi-api"

echo "========================================="
echo "Luigi API Server Deployment"
echo "========================================="

# Check if running as correct user
if [ "$USER" != "pi" ]; then
    echo "Error: Must run as pi user"
    exit 1
fi

cd "$PROJECT_DIR"

# Update code
echo "Pulling latest code..."
git pull origin main

# Install dependencies
echo "Installing dependencies..."
npm ci --production

# Run security audit
echo "Running security audit..."
npm audit || true

# Generate certificates if not exist
if [ ! -f "/home/pi/certs/server.crt" ]; then
    echo "Generating SSL certificates..."
    bash scripts/generate-certs.sh
fi

# Restart service
echo "Restarting service..."
if systemctl is-active --quiet "$SERVICE_NAME"; then
    sudo systemctl restart "$SERVICE_NAME"
    echo "Service restarted"
else
    sudo systemctl start "$SERVICE_NAME"
    echo "Service started"
fi

# Wait for service to stabilize
sleep 3

# Check service status
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "✓ Deployment successful!"
    echo "Service status:"
    sudo systemctl status "$SERVICE_NAME" --no-pager -l
else
    echo "✗ Deployment failed - service not running"
    echo "Check logs with: sudo journalctl -u $SERVICE_NAME -n 50"
    exit 1
fi

echo "========================================="
echo "Deployment complete!"
echo "========================================="
```

## Security Testing

### Penetration Testing Checklist

```bash
#!/bin/bash
# scripts/security-test.sh
# Basic security testing for Luigi API

API_URL="https://localhost:8443"

echo "Luigi API Security Tests"
echo "========================"

# Test 1: Anonymous access blocked
echo -e "\nTest 1: Anonymous access to protected endpoint"
curl -k -s -w "\nHTTP Status: %{http_code}\n" \
  "$API_URL/api/gpio/pins"

# Test 2: Invalid JWT rejected
echo -e "\nTest 2: Invalid JWT token"
curl -k -s -w "\nHTTP Status: %{http_code}\n" \
  -H "Authorization: Bearer invalid_token" \
  "$API_URL/api/gpio/pins"

# Test 3: Rate limiting works
echo -e "\nTest 3: Rate limiting (sending 10 rapid requests)"
for i in {1..10}; do
  curl -k -s -w "Request $i - HTTP Status: %{http_code}\n" \
    "$API_URL/api/auth/login" \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{"username":"test","password":"test"}' \
    -o /dev/null
done

# Test 4: SQL injection attempt (should be blocked)
echo -e "\nTest 4: SQL injection attempt"
curl -k -s -w "\nHTTP Status: %{http_code}\n" \
  "$API_URL/api/gpio/output/18" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"value":"1 OR 1=1"}'

# Test 5: XSS attempt (should be sanitized)
echo -e "\nTest 5: XSS attempt"
curl -k -s -w "\nHTTP Status: %{http_code}\n" \
  "$API_URL/api/auth/login" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"<script>alert(1)</script>","password":"test"}'

# Test 6: Invalid GPIO pin
echo -e "\nTest 6: Invalid GPIO pin number"
curl -k -s -w "\nHTTP Status: %{http_code}\n" \
  "$API_URL/api/gpio/output/99" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"value":1}'

echo -e "\nTests complete!"
```

## Troubleshooting

### Common Security Issues

**1. Certificate Errors**
```bash
# Regenerate certificates
bash scripts/generate-certs.sh

# Check certificate
openssl x509 -in /home/pi/certs/server.crt -text -noout

# Verify certificate and key match
openssl x509 -noout -modulus -in /home/pi/certs/server.crt | openssl md5
openssl rsa -noout -modulus -in /home/pi/certs/server.key | openssl md5
```

**2. Authentication Failures**
```bash
# Check JWT secret is set
grep JWT_SECRET /etc/luigi/api-server/.env

# Test login endpoint
curl -k https://localhost:8443/api/auth/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

**3. GPIO Permission Denied**
```bash
# Add user to gpio group
sudo usermod -a -G gpio pi

# Verify group membership
groups pi

# Check GPIO directory permissions
ls -la /sys/class/gpio

# Reboot to apply changes
sudo reboot
```

**4. Port Access Denied**
```bash
# Check if port is in use
sudo lsof -i :8443

# Check firewall rules
sudo ufw status

# Allow port
sudo ufw allow 8443/tcp
```

**5. Out of Memory**
```bash
# Check memory usage
free -h

# Increase swap space
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile  # Set CONF_SWAPSIZE=1024
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# Run with memory limit
node --max-old-space-size=256 server.js
```

## Summary

This skill provides comprehensive guidance for developing **secure** Node.js backend APIs on Raspberry Pi Zero W with emphasis on:

### Security Layers Covered:
- ✅ **Authentication** - HTTP Basic Authentication with constant-time comparison
- ✅ **Input Validation** - Comprehensive validation and sanitization
- ✅ **Rate Limiting** - Multi-layer DoS protection (general API, GPIO operations)
- ✅ **HTTPS/TLS** - Encrypted communication (required for Basic Auth)
- ✅ **Network Security** - Firewall, IP filtering, local network isolation
- ✅ **GPIO Safety** - Hardware protection and pin validation
- ✅ **Audit Logging** - Security event tracking
- ✅ **Error Handling** - Safe error messages without information leakage
- ✅ **Security Headers** - Helmet.js protection
- ✅ **CORS** - Restrictive cross-origin policy
- ✅ **Dependency Auditing** - Regular vulnerability checks

### Development Patterns Covered:
- ✅ Node.js setup for Raspberry Pi Zero W
- ✅ Express.js REST API implementation
- ✅ GPIO integration with hardware abstraction
- ✅ Configuration management with environment variables
- ✅ Performance optimization for limited resources
- ✅ Testing strategies
- ✅ Deployment automation with systemd
- ✅ Service management
- ✅ Monitoring and logging with Winston
- ✅ Luigi module integration (MQTT publishing)

### Related Luigi Skills:
- `.github/skills/raspi-zero-w/` - Hardware details and GPIO pinout
- `.github/skills/python-development/` - Python alternative for hardware control
- `.github/skills/module-design/` - Module design principles
- `.github/skills/system-setup/` - Deployment automation

### Additional Resources:
See companion files in this directory:
- `nodejs-backend-example.js` - Complete example application
- `nodejs-patterns.md` - Advanced patterns and examples
- `package-example.json` - Example package.json with all dependencies

### Management-API Example:
The Luigi management-api module is a production-ready implementation that follows all patterns in this skill:
- **Location:** `system/management-api/`
- **API Documentation:** `system/management-api/docs/API.md` - Complete REST API reference
- **Features:** Module management, system operations, log access, configuration management, registry integration
- **Security:** HTTP Basic Auth, rate limiting, input validation, audit logging
- **Deployment:** systemd service, automated setup, credential management

Use the management-api as a reference implementation for building similar backend APIs. The API documentation (`system/management-api/docs/API.md`) serves as the interface contract and demonstrates best practices for API design, authentication, error handling, and response formatting.

Use this skill to build production-ready, **secure** Node.js backend applications for local network deployment on Raspberry Pi Zero W.
