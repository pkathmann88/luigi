/**
 * Health Routes
 * Public health check endpoint
 */

const express = require('express');
const monitoringController = require('../controllers/monitoringController');

const router = express.Router();

// GET /health - Health check (no authentication required)
router.get('/', monitoringController.getHealth);

module.exports = router;
