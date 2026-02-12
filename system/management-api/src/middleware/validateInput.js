/**
 * Input Validation Middleware
 * Comprehensive validation and sanitization using express-validator
 */

const { body, param, query, validationResult } = require('express-validator');
const logger = require('../utils/logger');

/**
 * Validation error handler
 */
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  
  if (!errors.isEmpty()) {
    logger.warn(`Validation failed for ${req.method} ${req.path}:`, errors.array());
    return res.status(400).json({
      success: false,
      error: 'Validation failed',
      details: errors.array(),
    });
  }
  
  next();
};

/**
 * Module name validation
 * Ensures module names are safe and valid
 */
const moduleNameValidation = param('name')
  .trim()
  .isLength({ min: 1, max: 100 })
  .withMessage('Module name must be 1-100 characters')
  .matches(/^[a-zA-Z0-9_-]+$/)
  .withMessage('Module name can only contain letters, numbers, hyphens, and underscores');

/**
 * System operation validation
 */
const systemOperationValidation = {
  reboot: [
    body('confirm')
      .equals('true')
      .withMessage('Confirmation required for reboot'),
  ],
  shutdown: [
    body('confirm')
      .equals('true')
      .withMessage('Confirmation required for shutdown'),
  ],
};

/**
 * Log file validation
 * Allows module names or log filenames (with .log extension)
 */
const logFileValidation = param('module')
  .trim()
  .matches(/^[a-zA-Z0-9_.-]+$/)
  .withMessage('Invalid module or log file name')
  .isLength({ min: 1, max: 100 })
  .withMessage('Module name must be 1-100 characters');

/**
 * Configuration validation
 * Allows paths with slashes and file extensions
 * Blocks path traversal attempts
 */
const configValidation = {
  module: param('module')
    .trim()
    .matches(/^[a-zA-Z0-9_/.-]+$/)
    .withMessage('Invalid module or config path')
    .not().matches(/\.\./)
    .withMessage('Path traversal not allowed')
    .isLength({ min: 1, max: 200 })
    .withMessage('Module path must be 1-200 characters'),
  
  update: [
    body('setting')
      .trim()
      .isLength({ min: 1, max: 100 })
      .withMessage('Setting name must be 1-100 characters'),
    body('value')
      .trim()
      .isLength({ min: 0, max: 1000 })
      .withMessage('Value must be 0-1000 characters'),
  ],
};

/**
 * Pagination validation
 */
const paginationValidation = [
  query('page')
    .optional()
    .isInt({ min: 1, max: 1000 })
    .withMessage('Page must be between 1 and 1000'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100'),
  query('lines')
    .optional()
    .isInt({ min: 1, max: 1000 })
    .withMessage('Lines must be between 1 and 1000'),
];

/**
 * Search query validation
 */
const searchValidation = [
  query('search')
    .optional()
    .trim()
    .isLength({ min: 1, max: 200 })
    .withMessage('Search query must be 1-200 characters'),
];

module.exports = {
  handleValidationErrors,
  moduleNameValidation,
  systemOperationValidation,
  logFileValidation,
  configValidation,
  paginationValidation,
  searchValidation,
};
