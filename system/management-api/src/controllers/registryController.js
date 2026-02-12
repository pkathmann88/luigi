/**
 * Registry Controller
 * HTTP request handlers for module registry endpoints
 */

const registryService = require('../services/registryService');
const logger = require('../utils/logger');

/**
 * GET /api/registry
 * List all module registry entries
 */
async function listRegistry(req, res, next) {
  try {
    const entries = await registryService.listRegistry();
    const stats = await registryService.getRegistryStats();
    
    res.json({
      success: true,
      count: entries.length,
      stats,
      entries,
    });
  } catch (error) {
    logger.error(`Error in listRegistry: ${error.message}`);
    next(error);
  }
}

/**
 * GET /api/registry/:modulePath(*)
 * Get a specific module's registry entry
 * Supports multi-segment paths (e.g., motion-detection/mario)
 */
async function getRegistryEntry(req, res, next) {
  try {
    const modulePath = req.params.modulePath;
    
    if (!modulePath) {
      return res.status(400).json({
        success: false,
        error: 'Bad Request',
        message: 'Module path is required',
      });
    }
    
    const entry = await registryService.getRegistryEntry(modulePath);
    
    res.json({
      success: true,
      entry,
    });
  } catch (error) {
    logger.error(`Error in getRegistryEntry: ${error.message}`);
    if (error.message.includes('not found in registry')) {
      return res.status(404).json({
        success: false,
        error: 'Not Found',
        message: error.message,
      });
    }
    next(error);
  }
}

module.exports = {
  listRegistry,
  getRegistryEntry,
};
