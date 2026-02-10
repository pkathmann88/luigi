/**
 * Logs Routes
 * Routes for log file access
 */

const express = require('express');
const { authenticate } = require('../middleware/authenticate');
const { logFileValidation, paginationValidation, searchValidation, handleValidationErrors } = require('../middleware/validateInput');
const logsController = require('../controllers/logsController');

const router = express.Router();

// Apply authentication to all routes
router.use(authenticate);

// GET /api/logs - List all log files
router.get('/', logsController.listLogFiles);

// GET /api/logs/:module - Get module logs
router.get('/:module', [
  logFileValidation,
  paginationValidation,
  searchValidation,
  handleValidationErrors,
], logsController.getModuleLogs);

// GET /api/logs/:module/tail - Tail module logs
router.get('/:module/tail', [
  logFileValidation,
  paginationValidation,
  handleValidationErrors,
], logsController.tailModuleLogs);

module.exports = router;
