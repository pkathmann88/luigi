/**
 * IP Filtering Middleware
 * Restricts access based on IP address
 */

const logger = require('../utils/logger');
const config = require('../../config');

/**
 * IP Whitelist middleware
 * Only allows requests from specified IP addresses
 */
const ipWhitelist = (req, res, next) => {
  const allowedIPs = config.allowedIPs;
  
  // If no whitelist configured, allow all (log warning)
  if (allowedIPs.length === 0) {
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
    message: 'Your IP address is not authorized to access this API',
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
    message: 'This API is only accessible from local network',
  });
};

module.exports = {
  ipWhitelist,
  localNetworkOnly,
};
