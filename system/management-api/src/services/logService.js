/**
 * Log Service
 * Business logic for log file access and streaming
 */

const fs = require('fs').promises;
const path = require('path');
const logger = require('../utils/logger');
const { executeCommandForOutput } = require('../utils/commandExecutor');
const { validateLogPath } = require('../security/pathValidator');
const config = require('../../config');

/**
 * List available log files
 */
async function listLogFiles() {
  try {
    const logsPath = config.paths.logs;
    const files = [];

    // Helper function to scan directory
    async function scanDirectory(dir, depth = 0) {
      if (depth > 2) return; // Limit depth

      try {
        const entries = await fs.readdir(dir, { withFileTypes: true });

        for (const entry of entries) {
          const fullPath = path.join(dir, entry.name);
          const relativePath = path.relative(logsPath, fullPath);

          if (entry.isFile() && entry.name.endsWith('.log')) {
            try {
              const stats = await fs.stat(fullPath);
              files.push({
                name: entry.name,
                path: relativePath,
                fullPath,
                size: stats.size,
                modified: stats.mtime,
              });
            } catch (err) {
              // Skip files we can't stat
            }
          } else if (entry.isDirectory() && entry.name !== 'journal') {
            await scanDirectory(fullPath, depth + 1);
          }
        }
      } catch (err) {
        logger.warn(`Error reading directory ${dir}: ${err.message}`);
      }
    }

    await scanDirectory(logsPath);
    return files.sort((a, b) => b.modified - a.modified);
  } catch (error) {
    logger.error(`Error listing log files: ${error.message}`);
    throw error;
  }
}

/**
 * Read log file with pagination
 */
async function readLogFile(filePath, options = {}) {
  try {
    const {
      lines = 100,
      search = null,
    } = options;

    // Validate path
    const validatedPath = validateLogPath(filePath);

    // Check if file exists
    try {
      await fs.access(validatedPath);
    } catch (err) {
      throw new Error(`Log file not found: ${filePath}`);
    }

    // Read file (last N lines)
    let content;
    if (search) {
      // Use grep for search
      content = await executeCommandForOutput('grep', ['-i', search, validatedPath], { timeout: 30000 });
    } else {
      // Use tail for last N lines
      content = await executeCommandForOutput('tail', ['-n', String(lines), validatedPath], { timeout: 30000 });
    }

    const logLines = content.split('\n').filter(line => line.trim());

    return {
      file: path.basename(filePath),
      path: filePath,
      lines: logLines,
      count: logLines.length,
      search: search || null,
    };
  } catch (error) {
    logger.error(`Error reading log file: ${error.message}`);
    throw error;
  }
}

/**
 * Tail log file (get last N lines)
 */
async function tailLogFile(filePath, lines = 50) {
  return readLogFile(filePath, { lines });
}

/**
 * Get logs for a specific module
 */
async function getModuleLogs(moduleName, options = {}) {
  try {
    const { lines = 100 } = options;

    // Try to read from /var/log/{module}.log
    const logFile = path.join(config.paths.logs, `${moduleName}.log`);

    try {
      return await readLogFile(logFile, { lines });
    } catch (err) {
      // Log file doesn't exist, try journalctl
      try {
        const serviceName = moduleName.endsWith('.service') ? moduleName : `${moduleName}.service`;
        const content = await executeCommandForOutput('journalctl', ['-u', serviceName, '-n', String(lines), '--no-pager'], { timeout: 30000 });
        
        const logLines = content.split('\n').filter(line => line.trim());

        return {
          file: `journalctl -u ${serviceName}`,
          path: serviceName,
          lines: logLines,
          count: logLines.length,
          source: 'journalctl',
        };
      } catch (journalErr) {
        throw new Error(`No logs found for module '${moduleName}'`);
      }
    }
  } catch (error) {
    logger.error(`Error getting module logs: ${error.message}`);
    throw error;
  }
}

module.exports = {
  listLogFiles,
  readLogFile,
  tailLogFile,
  getModuleLogs,
};
