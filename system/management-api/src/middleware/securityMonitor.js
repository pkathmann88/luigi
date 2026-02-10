/**
 * Security Monitoring Middleware
 * Monitors requests for suspicious activity
 */

const auditLogger = require('../security/auditLogger');

/**
 * Log all API requests for security monitoring
 */
const securityMonitor = (req, res, next) => {
  const startTime = Date.now();

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

    // Log slow requests (potential DoS)
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
