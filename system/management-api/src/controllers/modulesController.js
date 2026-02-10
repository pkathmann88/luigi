/**
 * Modules Controller
 * HTTP request handlers for module management endpoints
 */

const moduleService = require('../services/moduleService');
const logger = require('../utils/logger');
const auditLogger = require('../security/auditLogger');

/**
 * GET /api/modules
 * List all Luigi modules
 */
async function listModules(req, res, next) {
  try {
    const modules = await moduleService.listModules();
    
    res.json({
      success: true,
      count: modules.length,
      modules,
    });
  } catch (error) {
    logger.error(`Error in listModules: ${error.message}`);
    next(error);
  }
}

/**
 * GET /api/modules/:name
 * Get status of a specific module
 */
async function getModuleStatus(req, res, next) {
  try {
    const { name } = req.params;
    
    const status = await moduleService.getModuleStatus(name);
    
    res.json({
      success: true,
      ...status,
    });
  } catch (error) {
    logger.error(`Error in getModuleStatus: ${error.message}`);
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
 * POST /api/modules/:name/start
 * Start a module service
 */
async function startModule(req, res, next) {
  try {
    const { name } = req.params;
    
    logger.info(`Starting module: ${name} (requested by ${req.user.username})`);
    
    const result = await moduleService.startModule(name);
    
    // Log to audit
    auditLogger.logModuleOperation(
      req.user,
      'start',
      name,
      result.success ? 'success' : 'failure',
      req.ip
    );
    
    res.json({
      success: result.success,
      ...result,
    });
  } catch (error) {
    logger.error(`Error in startModule: ${error.message}`);
    auditLogger.logModuleOperation(req.user, 'start', req.params.name, 'error', req.ip);
    next(error);
  }
}

/**
 * POST /api/modules/:name/stop
 * Stop a module service
 */
async function stopModule(req, res, next) {
  try {
    const { name } = req.params;
    
    logger.info(`Stopping module: ${name} (requested by ${req.user.username})`);
    
    const result = await moduleService.stopModule(name);
    
    // Log to audit
    auditLogger.logModuleOperation(
      req.user,
      'stop',
      name,
      result.success ? 'success' : 'failure',
      req.ip
    );
    
    res.json({
      success: result.success,
      ...result,
    });
  } catch (error) {
    logger.error(`Error in stopModule: ${error.message}`);
    auditLogger.logModuleOperation(req.user, 'stop', req.params.name, 'error', req.ip);
    next(error);
  }
}

/**
 * POST /api/modules/:name/restart
 * Restart a module service
 */
async function restartModule(req, res, next) {
  try {
    const { name } = req.params;
    
    logger.info(`Restarting module: ${name} (requested by ${req.user.username})`);
    
    const result = await moduleService.restartModule(name);
    
    // Log to audit
    auditLogger.logModuleOperation(
      req.user,
      'restart',
      name,
      result.success ? 'success' : 'failure',
      req.ip
    );
    
    res.json({
      success: result.success,
      ...result,
    });
  } catch (error) {
    logger.error(`Error in restartModule: ${error.message}`);
    auditLogger.logModuleOperation(req.user, 'restart', req.params.name, 'error', req.ip);
    next(error);
  }
}

module.exports = {
  listModules,
  getModuleStatus,
  startModule,
  stopModule,
  restartModule,
};
