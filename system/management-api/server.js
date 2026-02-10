/**
 * Server Entry Point
 * Creates HTTPS server and starts the application
 */

require('dotenv').config({ path: '/etc/luigi/system/management-api/.env' });

const fs = require('fs');
const https = require('https');
const http = require('http');
const app = require('./src/app');
const config = require('./config');
const logger = require('./src/utils/logger');

const PORT = config.port || 8443;
const HOST = config.host || '0.0.0.0';
const USE_HTTPS = config.useHttps;

async function startServer() {
  try {
    logger.info('Starting Luigi Management API Server');
    logger.info(`Environment: ${config.env}`);

    let server;

    if (USE_HTTPS) {
      // HTTPS server
      const certPath = config.tls.certPath;
      const keyPath = config.tls.keyPath;

      logger.info(`Using TLS certificates:`);
      logger.info(`  Cert: ${certPath}`);
      logger.info(`  Key: ${keyPath}`);

      if (!fs.existsSync(certPath) || !fs.existsSync(keyPath)) {
        logger.error('SSL certificate or key not found!');
        logger.error('Run: bash scripts/generate-certs.sh');
        process.exit(1);
      }

      const httpsOptions = {
        key: fs.readFileSync(keyPath),
        cert: fs.readFileSync(certPath),
        // TLS options for security
        minVersion: 'TLSv1.2',
        ciphers: [
          'ECDHE-ECDSA-AES128-GCM-SHA256',
          'ECDHE-RSA-AES128-GCM-SHA256',
          'ECDHE-ECDSA-AES256-GCM-SHA384',
          'ECDHE-RSA-AES256-GCM-SHA384',
        ].join(':'),
        honorCipherOrder: true,
      };

      server = https.createServer(httpsOptions, app);
      logger.info('HTTPS enabled');
    } else {
      // HTTP server (development only!)
      server = http.createServer(app);
      logger.warn('HTTPS disabled - Use only for development!');
    }

    // Start server
    server.listen(PORT, HOST, () => {
      const protocol = USE_HTTPS ? 'https' : 'http';
      logger.info(`Server running on ${protocol}://${HOST}:${PORT}`);
      logger.info(`Health check: ${protocol}://${HOST}:${PORT}/health`);
      logger.info(`API endpoints: ${protocol}://${HOST}:${PORT}/api/*`);
    });

    // Set connection limits (Raspberry Pi Zero W constraints)
    server.maxConnections = 50;

    // Graceful shutdown
    const shutdown = async (signal) => {
      logger.info(`${signal} received, shutting down gracefully`);
      
      server.close(() => {
        logger.info('HTTP server closed');
        process.exit(0);
      });

      // Force shutdown after 10 seconds
      setTimeout(() => {
        logger.error('Forced shutdown after timeout');
        process.exit(1);
      }, 10000);
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));

  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();
