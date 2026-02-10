/**
 * Request Logger Middleware
 * HTTP request logging using Morgan
 */

const morgan = require('morgan');
const logger = require('../utils/logger');
const config = require('../../config');

// Morgan format
const morganFormat = config.isProduction ? 'combined' : 'dev';

// Create morgan middleware with Winston stream
const requestLogger = morgan(morganFormat, {
  stream: {
    write: (message) => logger.info(message.trim()),
  },
  skip: (req) => req.path === '/health', // Skip health checks
});

module.exports = requestLogger;
