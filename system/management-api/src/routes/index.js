/**
 * Routes Index
 * Aggregates all route modules
 */

const express = require('express');
const modulesRoutes = require('./modules');
const systemRoutes = require('./system');
const logsRoutes = require('./logs');
const configRoutes = require('./config');
const monitoringRoutes = require('./monitoring');

const router = express.Router();

// Mount route modules
router.use('/modules', modulesRoutes);
router.use('/system', systemRoutes);
router.use('/logs', logsRoutes);
router.use('/config', configRoutes);
router.use('/monitoring', monitoringRoutes);

module.exports = router;
