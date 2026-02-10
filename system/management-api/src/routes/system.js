/**
 * System Routes
 * Routes for system operations
 */

const express = require('express');
const { authenticate } = require('../middleware/authenticate');
const { operationLimiter } = require('../middleware/rateLimit');
const { systemOperationValidation, handleValidationErrors } = require('../middleware/validateInput');
const systemController = require('../controllers/systemController');

const router = express.Router();

// Apply authentication to all routes
router.use(authenticate);

// Apply rate limiting for operations
router.use(operationLimiter);

// GET /api/system/status - Get system metrics
router.get('/status', systemController.getSystemStatus);

// POST /api/system/reboot - Reboot system
router.post('/reboot', [
  systemOperationValidation.reboot,
  handleValidationErrors,
], systemController.rebootSystem);

// POST /api/system/shutdown - Shutdown system
router.post('/shutdown', [
  systemOperationValidation.shutdown,
  handleValidationErrors,
], systemController.shutdownSystem);

// POST /api/system/update - Update system packages
router.post('/update', systemController.updateSystem);

// POST /api/system/cleanup - Clean up system
router.post('/cleanup', systemController.cleanupSystem);

module.exports = router;
