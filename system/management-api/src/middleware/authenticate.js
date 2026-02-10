/**
 * HTTP Basic Authentication Middleware
 * Implements secure Basic Auth with constant-time comparison
 */

const logger = require('../utils/logger');
const auditLogger = require('../security/auditLogger');
const config = require('../../config');

const AUTH_USERNAME = config.auth.username;
const AUTH_PASSWORD = config.auth.password;

if (!AUTH_USERNAME || !AUTH_PASSWORD) {
  throw new Error('AUTH_USERNAME and AUTH_PASSWORD must be set!');
}

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
 * HTTP Basic Authentication Middleware
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
      error: 'Authentication required',
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
      message: 'Expected "Basic base64(username:password)"',
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
      password: decoded.substring(colonIndex + 1),
    };
  } catch (error) {
    logger.warn(`Failed to decode credentials from ${req.ip}`);
    auditLogger.logSecurityViolation('invalid_credentials_encoding', {}, req.ip);
    
    return res.status(401).json({
      success: false,
      error: 'Invalid credentials format',
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
      error: 'Invalid credentials',
    });
  }

  // Authentication successful
  req.user = {
    username: credentials.username,
    authenticated: true,
  };

  logger.debug(`Authenticated request from user: ${credentials.username}`);
  auditLogger.logAuth(credentials.username, req.ip, true);

  next();
};

/**
 * Optional authentication middleware
 * Doesn't require auth but attaches user if authenticated
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
  optionalAuth,
};
