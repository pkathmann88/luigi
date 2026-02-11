/**
 * Express Application Setup
 * Configures Express with all middleware and routes
 */

const express = require('express');
const path = require('path');
const helmet = require('helmet');
const cors = require('cors');
const compression = require('compression');

const routes = require('./routes');
const healthRoutes = require('./routes/health');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');
const requestLogger = require('./middleware/requestLogger');
const securityMonitor = require('./middleware/securityMonitor');
const { apiLimiter } = require('./middleware/rateLimit');
const { localNetworkOnly } = require('./middleware/ipFilter');
const config = require('../config');

const app = express();

// Trust proxy (if behind nginx/apache)
app.set('trust proxy', 1);

// Security headers with Helmet
// NOTE: 'unsafe-inline' for scriptSrc is required for Vite's dev mode HMR
// In production, Vite generates external scripts, but we keep this for compatibility
// Consider implementing nonce-based CSP in production for better security
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", 'data:', 'https:'],
      connectSrc: ["'self'"],
      fontSrc: ["'self'", 'data:'],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
  frameguard: {
    action: 'deny',
  },
  noSniff: true,
  xssFilter: true,
}));

// Disable X-Powered-By header
app.disable('x-powered-by');

// CORS configuration (restrictive)
app.use(cors({
  origin: config.isDevelopment ? '*' : false, // No origin by default in production
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 600, // 10 minutes
}));

// Compression
app.use(compression());

// Body parsing with size limits
app.use(express.json({ 
  limit: '1mb',
  strict: true,
}));
app.use(express.urlencoded({ 
  extended: true, 
  limit: '1mb',
}));

// Request logging (Morgan → Winston)
app.use(requestLogger);

// Security monitoring
app.use(securityMonitor);

// IP filtering (local network only)
app.use(localNetworkOnly);

// Global rate limiting
app.use(apiLimiter);

// Public routes (no authentication)
app.use('/health', healthRoutes);

// Protected API routes (authentication required)
app.use('/api', routes);

// Serve static frontend files
const frontendPath = path.join(__dirname, '../frontend/dist');
app.use(express.static(frontendPath));

// Serve index.html for all non-API routes (SPA routing)
app.get('*', (req, res, next) => {
  // Skip if it's an API route or health check
  if (req.path.startsWith('/api') || req.path.startsWith('/health')) {
    return next();
  }
  
  // Serve index.html for SPA
  res.sendFile(path.join(frontendPath, 'index.html'), (err) => {
    if (err) {
      next(); // Fall through to 404 handler if frontend not built
    }
  });
});

// 404 handler
app.use(notFoundHandler);

// Error handler (must be last)
app.use(errorHandler);

module.exports = app;
