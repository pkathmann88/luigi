/**
 * Sounds Routes
 * Routes for Luigi module sound management
 */

const express = require('express');
const { authenticate } = require('../middleware/authenticate');
const { operationLimiter } = require('../middleware/rateLimit');
const { moduleNameValidation, handleValidationErrors } = require('../middleware/validateInput');
const soundsController = require('../controllers/soundsController');

const router = express.Router();

// Apply authentication to all routes
router.use(authenticate);

// Apply rate limiting
router.use(operationLimiter);

// GET /api/sounds - List all modules with sound capability
router.get('/', soundsController.listSoundModules);

// GET /api/sounds/:moduleName - Get sound files for a module
router.get('/:moduleName', [
  moduleNameValidation,
  handleValidationErrors,
], soundsController.getModuleSounds);

// POST /api/sounds/:moduleName/play - Play a sound file
router.post('/:moduleName/play', [
  moduleNameValidation,
  handleValidationErrors,
], soundsController.playSound);

module.exports = router;
