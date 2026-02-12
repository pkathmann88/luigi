/**
 * Path Validator
 * Prevents path traversal attacks
 */

const path = require('path');
const logger = require('../utils/logger');
const config = require('../../config');

// Allowed base directories
const ALLOWED_DIRECTORIES = [
  config.paths.config,
  config.paths.logs,
  '/etc/luigi/system/management-api/certs',
  '/tmp',
];

/**
 * Validate file path is within allowed directories
 * Returns validated absolute path or throws error
 */
function validatePath(filePath, baseDir = null) {
  // Resolve to absolute path
  const absolutePath = path.resolve(filePath);
  
  // Check if path is within baseDir (if specified)
  if (baseDir) {
    const resolvedBase = path.resolve(baseDir);
    if (!absolutePath.startsWith(resolvedBase)) {
      logger.warn(`Path traversal attempt: ${filePath} outside ${baseDir}`);
      throw new Error('Path traversal detected');
    }
    return absolutePath;
  }

  // Check if path is within any allowed directory
  const isAllowed = ALLOWED_DIRECTORIES.some((allowedDir) => {
    const resolvedAllowed = path.resolve(allowedDir);
    return absolutePath.startsWith(resolvedAllowed);
  });

  if (!isAllowed) {
    logger.warn(`Path not in allowed directories: ${absolutePath}`);
    throw new Error('Path not in allowed directories');
  }

  return absolutePath;
}

/**
 * Validate config path is within Luigi config directory
 */
function validateConfigPath(configPath) {
  return validatePath(path.join(config.paths.config, configPath), config.paths.config);
}

/**
 * Validate log path is within logs directory
 */
function validateLogPath(logPath) {
  return validatePath(path.join(config.paths.logs, logPath), config.paths.logs);
}

module.exports = {
  validatePath,
  validateConfigPath,
  validateLogPath,
  ALLOWED_DIRECTORIES,
};
