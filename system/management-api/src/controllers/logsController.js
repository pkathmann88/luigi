/**
 * Logs Controller
 * HTTP request handlers for log viewing endpoints
 */

const logService = require('../services/logService');
const logger = require('../utils/logger');

/**
 * GET /api/logs
 * List available log files
 */
async function listLogFiles(req, res, next) {
  try {
    const files = await logService.listLogFiles();
    
    res.json({
      success: true,
      count: files.length,
      files,
    });
  } catch (error) {
    logger.error(`Error in listLogFiles: ${error.message}`);
    next(error);
  }
}

/**
 * GET /api/logs/:module
 * Get logs for a specific module or file
 */
async function getModuleLogs(req, res, next) {
  try {
    const { module } = req.params;
    const { lines, search } = req.query;
    
    const options = {
      lines: lines ? parseInt(lines, 10) : 100,
      search: search || null,
    };
    
    const logs = await logService.getModuleLogs(module, options);
    
    res.json({
      success: true,
      ...logs,
    });
  } catch (error) {
    logger.error(`Error in getModuleLogs: ${error.message}`);
    if (error.message.includes('not found')) {
      return res.status(404).json({
        success: false,
        error: 'Not Found',
        message: error.message,
      });
    }
    next(error);
  }
}

/**
 * GET /api/logs/:module/tail
 * Tail (last N lines) of a module log
 */
async function tailModuleLogs(req, res, next) {
  try {
    const { module } = req.params;
    const { lines } = req.query;
    
    const numLines = lines ? parseInt(lines, 10) : 50;
    
    const logs = await logService.getModuleLogs(module, { lines: numLines });
    
    res.json({
      success: true,
      ...logs,
    });
  } catch (error) {
    logger.error(`Error in tailModuleLogs: ${error.message}`);
    next(error);
  }
}

module.exports = {
  listLogFiles,
  getModuleLogs,
  tailModuleLogs,
};
