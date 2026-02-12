/**
 * Monitoring Controller
 * HTTP request handlers for system monitoring endpoints
 */

const systemService = require('../services/systemService');
const logger = require('../utils/logger');

/**
 * GET /api/monitoring/metrics
 * Get system metrics (same as system status, but designed for polling)
 */
async function getMetrics(req, res, next) {
  try {
    const metrics = await systemService.getSystemMetrics();
    
    // Return metrics directly (not wrapped in 'metrics' field)
    // Frontend expects the response structure to match SystemStatus type
    res.json(metrics);
  } catch (error) {
    logger.error(`Error in getMetrics: ${error.message}`);
    next(error);
  }
}

/**
 * GET /api/monitoring/health
 * Health check endpoint (lightweight, no authentication required)
 */
function getHealth(req, res) {
  res.json({
    success: true,
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: '1.0.0',
  });
}

module.exports = {
  getMetrics,
  getHealth,
};
