/**
 * Error Handler Middleware
 * Centralized error handling with sanitized responses
 */

const logger = require('../utils/logger');
const config = require('../../config');

/**
 * Error handler middleware (must be last in middleware chain)
 */
const errorHandler = (err, req, res, next) => {
  // Log the error
  logger.error('Error occurred:', {
    message: err.message,
    stack: config.isDevelopment ? err.stack : undefined,
    path: req.path,
    method: req.method,
    ip: req.ip,
    user: req.user ? req.user.username : 'anonymous',
  });

  // Determine status code
  const statusCode = err.statusCode || err.status || 500;

  // Prepare error response
  const errorResponse = {
    success: false,
    error: err.name || 'Error',
    message: err.message || 'An error occurred',
  };

  // Include stack trace only in development
  if (config.isDevelopment && err.stack) {
    errorResponse.stack = err.stack;
  }

  // Send error response
  res.status(statusCode).json(errorResponse);
};

/**
 * 404 Not Found handler
 */
const notFoundHandler = (req, res) => {
  logger.warn(`404 Not Found: ${req.method} ${req.path} from ${req.ip}`);
  res.status(404).json({
    success: false,
    error: 'Not Found',
    message: `Route ${req.method} ${req.path} not found`,
  });
};

module.exports = {
  errorHandler,
  notFoundHandler,
};
