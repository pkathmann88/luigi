/**
 * Modules Routes
 * Routes for Luigi module management
 */

const express = require('express');
const { authenticate } = require('../middleware/authenticate');
const { operationLimiter } = require('../middleware/rateLimit');
const { moduleNameValidation, handleValidationErrors } = require('../middleware/validateInput');
const modulesController = require('../controllers/modulesController');

const router = express.Router();

// Apply authentication to all routes
router.use(authenticate);

// Apply rate limiting for operations
router.use(operationLimiter);

// GET /api/modules - List all modules
router.get('/', modulesController.listModules);

// GET /api/modules/:name - Get module status
router.get('/:name', [
  moduleNameValidation,
  handleValidationErrors,
], modulesController.getModuleStatus);

// POST /api/modules/:name/start - Start module
router.post('/:name/start', [
  moduleNameValidation,
  handleValidationErrors,
], modulesController.startModule);

// POST /api/modules/:name/stop - Stop module
router.post('/:name/stop', [
  moduleNameValidation,
  handleValidationErrors,
], modulesController.stopModule);

// POST /api/modules/:name/restart - Restart module
router.post('/:name/restart', [
  moduleNameValidation,
  handleValidationErrors,
], modulesController.restartModule);

module.exports = router;
