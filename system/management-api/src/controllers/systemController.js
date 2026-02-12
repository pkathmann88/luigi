/**
 * System Controller
 * HTTP request handlers for system operation endpoints
 */

const systemService = require('../services/systemService');
const logger = require('../utils/logger');
const auditLogger = require('../security/auditLogger');

/**
 * GET /api/system/status
 * Get system metrics
 */
async function getSystemStatus(req, res, next) {
  try {
    const metrics = await systemService.getSystemMetrics();
    
    // Return metrics directly (not wrapped in 'metrics' field)
    // Frontend expects the response structure to match SystemStatus type
    res.json(metrics);
  } catch (error) {
    logger.error(`Error in getSystemStatus: ${error.message}`);
    next(error);
  }
}

/**
 * POST /api/system/reboot
 * Reboot the system
 */
async function rebootSystem(req, res, next) {
  try {
    const { confirm } = req.body;
    
    if (confirm !== 'true' && confirm !== true) {
      return res.status(400).json({
        success: false,
        error: 'Confirmation Required',
        message: 'Set "confirm": true to reboot the system',
      });
    }
    
    logger.warn(`System reboot requested by ${req.user.username} from ${req.ip}`);
    
    // Log to audit before reboot
    auditLogger.logSystemOperation(
      req.user,
      'reboot',
      { confirmed: true },
      'initiated',
      req.ip
    );
    
    const result = await systemService.rebootSystem();
    
    res.json({
      success: result.success,
      message: result.message,
    });
  } catch (error) {
    logger.error(`Error in rebootSystem: ${error.message}`);
    next(error);
  }
}

/**
 * POST /api/system/shutdown
 * Shutdown the system
 */
async function shutdownSystem(req, res, next) {
  try {
    const { confirm } = req.body;
    
    if (confirm !== 'true' && confirm !== true) {
      return res.status(400).json({
        success: false,
        error: 'Confirmation Required',
        message: 'Set "confirm": true to shutdown the system',
      });
    }
    
    logger.warn(`System shutdown requested by ${req.user.username} from ${req.ip}`);
    
    // Log to audit before shutdown
    auditLogger.logSystemOperation(
      req.user,
      'shutdown',
      { confirmed: true },
      'initiated',
      req.ip
    );
    
    const result = await systemService.shutdownSystem();
    
    res.json({
      success: result.success,
      message: result.message,
    });
  } catch (error) {
    logger.error(`Error in shutdownSystem: ${error.message}`);
    next(error);
  }
}

/**
 * POST /api/system/update
 * Update system packages
 */
async function updateSystem(req, res, next) {
  try {
    logger.info(`System update requested by ${req.user.username} from ${req.ip}`);
    
    auditLogger.logSystemOperation(
      req.user,
      'update',
      { action: 'apt-get update && upgrade' },
      'initiated',
      req.ip
    );
    
    const result = await systemService.updateSystem();
    
    auditLogger.logSystemOperation(
      req.user,
      'update',
      { action: 'apt-get update && upgrade' },
      result.success ? 'success' : 'failure',
      req.ip
    );
    
    res.json({
      success: result.success,
      message: result.message,
      output: result.output,
    });
  } catch (error) {
    logger.error(`Error in updateSystem: ${error.message}`);
    auditLogger.logSystemOperation(req.user, 'update', {}, 'error', req.ip);
    next(error);
  }
}

/**
 * POST /api/system/cleanup
 * Clean up system (logs, temp files)
 */
async function cleanupSystem(req, res, next) {
  try {
    logger.info(`System cleanup requested by ${req.user.username} from ${req.ip}`);
    
    auditLogger.logSystemOperation(
      req.user,
      'cleanup',
      { action: 'clean apt cache and old logs' },
      'initiated',
      req.ip
    );
    
    const result = await systemService.cleanupSystem();
    
    auditLogger.logSystemOperation(
      req.user,
      'cleanup',
      { results: result.results },
      result.success ? 'success' : 'failure',
      req.ip
    );
    
    res.json({
      success: result.success,
      message: result.message,
      results: result.results,
    });
  } catch (error) {
    logger.error(`Error in cleanupSystem: ${error.message}`);
    auditLogger.logSystemOperation(req.user, 'cleanup', {}, 'error', req.ip);
    next(error);
  }
}

module.exports = {
  getSystemStatus,
  rebootSystem,
  shutdownSystem,
  updateSystem,
  cleanupSystem,
};
