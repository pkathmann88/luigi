/**
 * Configuration Loader
 * Loads configuration from environment variables and provides defaults
 */

require('dotenv').config({ path: '/etc/luigi/system/management-api/.env' });

const config = {
  // Environment
  env: process.env.NODE_ENV || 'production',
  isDevelopment: process.env.NODE_ENV === 'development',
  isProduction: process.env.NODE_ENV === 'production',

  // Server
  port: parseInt(process.env.PORT, 10) || 8443,
  host: process.env.HOST || '0.0.0.0',
  useHttps: process.env.USE_HTTPS === 'true',

  // Authentication
  auth: {
    username: process.env.AUTH_USERNAME,
    password: process.env.AUTH_PASSWORD,
  },

  // TLS
  tls: {
    certPath: process.env.TLS_CERT_PATH || '/home/pi/certs/server.crt',
    keyPath: process.env.TLS_KEY_PATH || '/home/pi/certs/server.key',
  },

  // Rate Limiting
  rateLimit: {
    windowMinutes: parseInt(process.env.RATE_LIMIT_WINDOW_MINUTES, 10) || 15,
    maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS, 10) || 100,
  },

  // IP Filtering
  allowedIPs: process.env.ALLOWED_IPS ? process.env.ALLOWED_IPS.split(',').map(ip => ip.trim()) : [],

  // Logging
  logging: {
    file: process.env.LOG_FILE || '/var/log/management-api.log',
    level: process.env.LOG_LEVEL || 'info',
    maxBytes: parseInt(process.env.LOG_MAX_BYTES, 10) || 10485760,
    backupCount: parseInt(process.env.LOG_BACKUP_COUNT, 10) || 5,
    auditFile: process.env.AUDIT_LOG_FILE || '/var/log/luigi/audit.log',
  },

  // System Paths
  paths: {
    modules: process.env.MODULES_PATH || '/home/pi/luigi',
    config: process.env.CONFIG_PATH || '/etc/luigi',
    logs: process.env.LOGS_PATH || '/var/log',
  },
};

// Validation
function validateConfig() {
  const errors = [];

  // Required: Authentication credentials
  if (!config.auth.username) {
    errors.push('AUTH_USERNAME is required');
  }
  if (!config.auth.password) {
    errors.push('AUTH_PASSWORD is required');
  } else if (config.auth.password.length < 12) {
    console.warn('WARNING: AUTH_PASSWORD is less than 12 characters. Use a stronger password!');
  }

  // Required for HTTPS
  if (config.useHttps && !config.tls.certPath) {
    errors.push('TLS_CERT_PATH is required when USE_HTTPS=true');
  }
  if (config.useHttps && !config.tls.keyPath) {
    errors.push('TLS_KEY_PATH is required when USE_HTTPS=true');
  }

  // Warnings
  if (!config.useHttps) {
    console.warn('WARNING: HTTPS is disabled. This is insecure for production!');
  }
  if (config.allowedIPs.length === 0) {
    console.warn('WARNING: IP whitelist is empty. All local network IPs will be allowed.');
  }

  if (errors.length > 0) {
    throw new Error(`Configuration errors:\n${errors.join('\n')}`);
  }
}

// Validate on load
try {
  validateConfig();
} catch (error) {
  console.error('Configuration validation failed:', error.message);
  process.exit(1);
}

module.exports = config;
