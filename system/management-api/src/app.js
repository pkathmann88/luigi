/**
 * Express Application Setup
 * Configures Express with all middleware and routes
 */

const express = require('express');
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

// 404 handler
app.use(notFoundHandler);

// Error handler (must be last)
app.use(errorHandler);

module.exports = app;
