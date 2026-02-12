/**
 * Registry Routes
 * Routes for module registry access (read-only)
 */

const express = require('express');
const { authenticate } = require('../middleware/authenticate');
const registryController = require('../controllers/registryController');

const router = express.Router();

// Apply authentication to all routes
router.use(authenticate);

// GET /api/registry - List all registry entries
router.get('/', registryController.listRegistry);

// GET /api/registry/:modulePath(*) - Get specific registry entry (supports multi-segment paths)
router.get('/:modulePath(*)', registryController.getRegistryEntry);

module.exports = router;
