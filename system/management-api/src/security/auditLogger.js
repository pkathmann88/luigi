/**
 * Security Audit Logger
 * Separate logging for security events, authentication, and operations
 */

const winston = require('winston');
const path = require('path');
const fs = require('fs');
const config = require('../../config');

// Ensure audit log directory exists
const auditLogDir = path.dirname(config.logging.auditFile);
if (!fs.existsSync(auditLogDir)) {
  fs.mkdirSync(auditLogDir, { recursive: true, mode: 0o755 });
}

// Custom format for console output
const consoleFormat = winston.format.combine(
  winston.format.colorize(),
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.printf(({ timestamp, level, message, ...meta }) => {
    // If message is an object, extract meaningful info
    let msg = message;
    if (typeof message === 'object' && message !== null) {
      // Extract event type and other key fields
      const { event, username, user, ip, success, operation, module: moduleName, ...rest } = message;
      msg = event || 'audit';
      if (username) msg += ` user=${username}`;
      if (user) msg += ` user=${user}`;
      if (ip) msg += ` ip=${ip}`;
      if (success !== undefined) msg += ` success=${success}`;
      if (operation) msg += ` operation=${operation}`;
      if (moduleName) msg += ` module=${moduleName}`;
      if (Object.keys(rest).length > 0) {
        msg += ` ${JSON.stringify(rest)}`;
      }
    }
    
    let output = `${timestamp} [${level}] ${msg}`;
    if (Object.keys(meta).length > 0) {
      output += ` ${JSON.stringify(meta)}`;
    }
    return output;
  })
);

// Audit logger configuration
const auditLogger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({
      filename: config.logging.auditFile,
      maxsize: config.logging.maxBytes,
      maxFiles: config.logging.backupCount * 2, // Keep more audit logs
      tailable: true,
    }),
    new winston.transports.Console({
      format: consoleFormat,
    }),
  ],
});

/**
 * Audit Logger Class
 * Provides methods for logging security-relevant events
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
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Log module operation
   */
  logModuleOperation(user, operation, module, result, ip) {
    auditLogger.info({
      event: 'module_operation',
      user: user.username,
      operation,
      module,
      result,
      ip,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Log system operation
   */
  logSystemOperation(user, operation, details, result, ip) {
    auditLogger.info({
      event: 'system_operation',
      user: user.username,
      operation,
      details,
      result,
      ip,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Log configuration change
   */
  logConfigChange(user, module, setting, oldValue, newValue, ip) {
    auditLogger.info({
      event: 'config_change',
      user: user.username,
      module,
      setting,
      oldValue,
      newValue,
      ip,
      timestamp: new Date().toISOString(),
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
      timestamp: new Date().toISOString(),
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
      timestamp: new Date().toISOString(),
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
      timestamp: new Date().toISOString(),
    });
  }
}

module.exports = new AuditLogger();
