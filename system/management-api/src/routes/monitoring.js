/**
 * Monitoring Routes
 * Routes for system monitoring
 */

const express = require('express');
const { authenticate } = require('../middleware/authenticate');
const monitoringController = require('../controllers/monitoringController');

const router = express.Router();

// Apply authentication to all routes (except health)
router.use(authenticate);

// GET /api/monitoring/metrics - Get system metrics
router.get('/metrics', monitoringController.getMetrics);

module.exports = router;
