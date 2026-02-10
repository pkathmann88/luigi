/**
 * Rate Limiting Middleware
 * Multi-layer rate limiting to prevent DoS and brute force attacks
 */

const rateLimit = require('express-rate-limit');
const slowDown = require('express-slow-down');
const logger = require('../utils/logger');
const auditLogger = require('../security/auditLogger');
const config = require('../../config');

/**
 * General API rate limiter
 * 100 requests per 15 minutes per IP
 */
const apiLimiter = rateLimit({
  windowMs: config.rateLimit.windowMinutes * 60 * 1000,
  max: config.rateLimit.maxRequests,
  message: {
    success: false,
    error: 'Too many requests',
    message: 'Please try again later',
  },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    logger.warn(`Rate limit exceeded for IP: ${req.ip} on ${req.path}`);
    auditLogger.logRateLimit(req.ip, req.path, req.user);
    res.status(429).json({
      success: false,
      error: 'Rate limit exceeded',
      message: 'Too many requests. Please try again later.',
    });
  },
});

/**
 * Strict limiter for authentication attempts
 * 5 attempts per 15 minutes per IP
 */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  skipSuccessfulRequests: true, // Don't count successful logins
  message: {
    success: false,
    error: 'Too many login attempts',
    message: 'Account temporarily locked. Try again in 15 minutes.',
  },
  handler: (req, res) => {
    logger.warn(`Auth rate limit exceeded for IP: ${req.ip}`);
    auditLogger.logRateLimit(req.ip, 'authentication', req.user);
    res.status(429).json({
      success: false,
      error: 'Too many login attempts',
      message: 'Account temporarily locked. Try again in 15 minutes.',
    });
  },
});

/**
 * Module/System operation rate limiter
 * 20 requests per minute per IP
 */
const operationLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 20,
  message: {
    success: false,
    error: 'Operation rate limit exceeded',
    message: 'Too many operations. Please slow down.',
  },
  handler: (req, res) => {
    logger.warn(`Operation rate limit exceeded for IP: ${req.ip}`);
    auditLogger.logRateLimit(req.ip, req.path, req.user);
    res.status(429).json({
      success: false,
      error: 'Operation rate limit exceeded',
      message: 'Too many operations. Please slow down.',
    });
  },
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
  },
});

module.exports = {
  apiLimiter,
  authLimiter,
  operationLimiter,
  speedLimiter,
};
