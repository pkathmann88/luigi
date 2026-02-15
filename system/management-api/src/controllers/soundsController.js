/**
 * Sounds Controller
 * Handles HTTP requests for sound management
 */

const soundService = require('../services/soundService');
const logger = require('../utils/logger');

/**
 * List all modules with sound capability
 * GET /api/sounds
 */
async function listSoundModules(req, res) {
  try {
    const modules = await soundService.listSoundModules();
    
    res.json({
      success: true,
      data: {
        modules,
        count: modules.length,
      },
    });
  } catch (error) {
    logger.error(`Error in listSoundModules: ${error.message}`);
    res.status(500).json({
      success: false,
      error: 'Internal Server Error',
      message: error.message,
    });
  }
}

/**
 * Get sound files for a specific module
 * GET /api/sounds/:moduleName
 */
async function getModuleSounds(req, res) {
  try {
    const { moduleName } = req.params;
    
    const result = await soundService.getModuleSounds(moduleName);
    
    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    logger.error(`Error in getModuleSounds: ${error.message}`);
    
    // Determine appropriate status code
    const statusCode = error.message.includes('not found') ? 404 : 500;
    
    res.status(statusCode).json({
      success: false,
      error: statusCode === 404 ? 'Not Found' : 'Internal Server Error',
      message: error.message,
    });
  }
}

/**
 * Play a sound file
 * POST /api/sounds/:moduleName/play
 * Body: { file: "sound.wav" }
 */
async function playSound(req, res) {
  try {
    const { moduleName } = req.params;
    const { file } = req.body;
    
    if (!file) {
      return res.status(400).json({
        success: false,
        error: 'Validation Error',
        message: 'Missing required field: file',
      });
    }
    
    const result = await soundService.playSound(moduleName, file);
    
    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    logger.error(`Error in playSound: ${error.message}`);
    
    // Determine appropriate status code
    let statusCode = 500;
    if (error.message.includes('not found')) {
      statusCode = 404;
    } else if (error.message.includes('Invalid') || error.message.includes('does not have sound capability')) {
      statusCode = 400;
    }
    
    res.status(statusCode).json({
      success: false,
      error: statusCode === 404 ? 'Not Found' : statusCode === 400 ? 'Bad Request' : 'Internal Server Error',
      message: error.message,
    });
  }
}

module.exports = {
  listSoundModules,
  getModuleSounds,
  playSound,
};
