/**
 * Config Routes
 * Routes for configuration management
 */

const express = require('express');
const { authenticate } = require('../middleware/authenticate');
const { operationLimiter } = require('../middleware/rateLimit');
const { configValidation, handleValidationErrors } = require('../middleware/validateInput');
const configController = require('../controllers/configController');

const router = express.Router();

// Apply authentication to all routes
router.use(authenticate);

// Apply rate limiting for operations
router.use(operationLimiter);

// GET /api/config - List all configs
router.get('/', configController.listConfigs);

// GET /api/config/:module - Read config
router.get('/:module', [
  configValidation.module,
  handleValidationErrors,
], configController.readConfig);

// PUT /api/config/:module - Update config
router.put('/:module', [
  configValidation.module,
  configValidation.update,
  handleValidationErrors,
], configController.updateConfig);

module.exports = router;
