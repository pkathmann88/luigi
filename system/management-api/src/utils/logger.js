/**
 * Winston Logger Configuration
 * Provides structured logging with file rotation
 */

const winston = require('winston');
const path = require('path');
const fs = require('fs');
const config = require('../../config');

// Ensure log directory exists
const logDir = path.dirname(config.logging.file);
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true, mode: 0o755 });
}

// Custom format for console output
const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    let msg = `${timestamp} [${level}] ${message}`;
    if (Object.keys(meta).length > 0) {
      msg += ` ${JSON.stringify(meta)}`;
    }
    return msg;
  })
);

// Custom format for file output
const fileFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.json()
);

// Create logger
const logger = winston.createLogger({
  level: config.logging.level,
  format: fileFormat,
  transports: [
    // File transport with rotation
    new winston.transports.File({
      filename: config.logging.file,
      maxsize: config.logging.maxBytes,
      maxFiles: config.logging.backupCount,
      tailable: true,
    }),
    // Console transport
    new winston.transports.Console({
      format: consoleFormat,
    }),
  ],
  // Handle uncaught exceptions
  exceptionHandlers: [
    new winston.transports.File({
      filename: path.join(logDir, 'exceptions.log'),
    }),
  ],
  // Handle unhandled rejections
  rejectionHandlers: [
    new winston.transports.File({
      filename: path.join(logDir, 'rejections.log'),
    }),
  ],
});

module.exports = logger;
