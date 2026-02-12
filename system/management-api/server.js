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
    console.log('');
    console.log('==========================================');
    console.log('Luigi Management API - Server Startup');
    console.log('==========================================');
    
    logger.info('Starting Luigi Management API Server');
    logger.info(`Environment: ${config.env}`);
    logger.info(`Process ID: ${process.pid}`);
    logger.info(`Node Version: ${process.version}`);
    logger.info(`Working Directory: ${process.cwd()}`);

    let server;

    if (USE_HTTPS) {
      // HTTPS server
      const certPath = config.tls.certPath;
      const keyPath = config.tls.keyPath;

      console.log('------------------------------------------');
      console.log('TLS Configuration:');
      logger.info(`Using TLS certificates:`);
      logger.info(`  Cert: ${certPath}`);
      logger.info(`  Key: ${keyPath}`);

      console.log('Checking certificate files...');
      if (!fs.existsSync(certPath)) {
        console.error(`✗ Certificate file not found: ${certPath}`);
        logger.error('SSL certificate not found!');
        logger.error(`Expected location: ${certPath}`);
        logger.error('Run: bash scripts/generate-certs.sh');
        process.exit(1);
      }
      console.log(`✓ Certificate file found: ${certPath}`);
      
      if (!fs.existsSync(keyPath)) {
        console.error(`✗ Key file not found: ${keyPath}`);
        logger.error('SSL key not found!');
        logger.error(`Expected location: ${keyPath}`);
        logger.error('Run: bash scripts/generate-certs.sh');
        process.exit(1);
      }
      console.log(`✓ Key file found: ${keyPath}`);

      console.log('Reading certificate files...');
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
      console.log('✓ Certificate files loaded successfully');

      console.log('Creating HTTPS server...');
      server = https.createServer(httpsOptions, app);
      logger.info('HTTPS enabled');
      console.log('✓ HTTPS server created');
    } else {
      // HTTP server (development only!)
      console.log('------------------------------------------');
      console.log('⚠ WARNING: HTTPS is disabled!');
      console.log('Creating HTTP server...');
      server = http.createServer(app);
      logger.warn('HTTPS disabled - Use only for development!');
      console.log('✓ HTTP server created');
    }

    console.log('------------------------------------------');
    console.log(`Starting server on ${HOST}:${PORT}...`);
    
    // Start server
    server.listen(PORT, HOST, () => {
      const protocol = USE_HTTPS ? 'https' : 'http';
      console.log('✓ Server started successfully!');
      console.log('==========================================');
      console.log('Server Information:');
      logger.info(`Server running on ${protocol}://${HOST}:${PORT}`);
      logger.info(`Health check: ${protocol}://${HOST}:${PORT}/health`);
      logger.info(`API endpoints: ${protocol}://${HOST}:${PORT}/api/*`);
      console.log('==========================================');
      console.log('');
      console.log('Server is ready to accept connections.');
      console.log('Press Ctrl+C to stop the server.');
      console.log('');
    });

    // Set connection limits (Raspberry Pi Zero W constraints)
    server.maxConnections = 50;
    logger.info(`Max connections set to: ${server.maxConnections}`);

    // Graceful shutdown
    const shutdown = async (signal) => {
      console.log('');
      console.log('==========================================');
      console.log(`Shutdown Signal Received: ${signal}`);
      console.log('==========================================');
      logger.info(`${signal} received, shutting down gracefully`);
      
      server.close(() => {
        logger.info('HTTP server closed');
        console.log('✓ Server shut down gracefully');
        console.log('==========================================');
        process.exit(0);
      });

      // Force shutdown after 10 seconds
      setTimeout(() => {
        logger.error('Forced shutdown after timeout');
        console.error('✗ Forced shutdown - server did not close in time');
        process.exit(1);
      }, 10000);
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));

  } catch (error) {
    console.error('');
    console.error('==========================================');
    console.error('✗ FATAL ERROR: Failed to start server');
    console.error('==========================================');
    logger.error('Failed to start server:', error);
    console.error('Error details:', error.message);
    if (error.stack) {
      console.error('Stack trace:');
      console.error(error.stack);
    }
    console.error('==========================================');
    process.exit(1);
  }
}

startServer();
