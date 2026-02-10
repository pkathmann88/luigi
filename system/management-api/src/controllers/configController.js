/**
 * Config Controller
 * HTTP request handlers for configuration management endpoints
 */

const configService = require('../services/configService');
const logger = require('../utils/logger');
const auditLogger = require('../security/auditLogger');

/**
 * GET /api/config
 * List all configuration files
 */
async function listConfigs(req, res, next) {
  try {
    const configs = await configService.listConfigs();
    
    res.json({
      success: true,
      count: configs.length,
      configs,
    });
  } catch (error) {
    logger.error(`Error in listConfigs: ${error.message}`);
    next(error);
  }
}

/**
 * GET /api/config/:module
 * Read configuration for a module
 */
async function readConfig(req, res, next) {
  try {
    const { module } = req.params;
    
    const config = await configService.readConfig(module);
    
    res.json({
      success: true,
      ...config,
    });
  } catch (error) {
    logger.error(`Error in readConfig: ${error.message}`);
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
 * PUT /api/config/:module
 * Update configuration for a module
 */
async function updateConfig(req, res, next) {
  try {
    const { module } = req.params;
    const updates = req.body;
    
    logger.info(`Config update requested for ${module} by ${req.user.username}`);
    
    const result = await configService.updateConfig(module, updates);
    
    // Log to audit
    auditLogger.logConfigChange(
      req.user,
      module,
      'multiple',
      'various',
      updates,
      req.ip
    );
    
    res.json({
      success: result.success,
      ...result,
    });
  } catch (error) {
    logger.error(`Error in updateConfig: ${error.message}`);
    next(error);
  }
}

module.exports = {
  listConfigs,
  readConfig,
  updateConfig,
};
