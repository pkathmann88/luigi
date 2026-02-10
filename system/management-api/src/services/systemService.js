/**
 * System Service
 * Business logic for system operations and monitoring
 */

const os = require('os');
const fs = require('fs').promises;
const logger = require('../utils/logger');
const { executeCommand, executeCommandForOutput } = require('../utils/commandExecutor');

/**
 * Get system metrics
 */
async function getSystemMetrics() {
  try {
    const metrics = {
      timestamp: new Date().toISOString(),
      uptime: os.uptime(),
      hostname: os.hostname(),
      platform: os.platform(),
      arch: os.arch(),
      cpu: {
        model: os.cpus()[0].model,
        cores: os.cpus().length,
        usage: await getCpuUsage(),
      },
      memory: {
        total: os.totalmem(),
        free: os.freemem(),
        used: os.totalmem() - os.freemem(),
        percentUsed: Math.round(((os.totalmem() - os.freemem()) / os.totalmem()) * 100),
      },
      disk: await getDiskUsage(),
      temperature: await getCpuTemperature(),
    };

    return metrics;
  } catch (error) {
    logger.error(`Error getting system metrics: ${error.message}`);
    throw error;
  }
}

/**
 * Get CPU usage percentage
 * Note: This returns a snapshot based on cumulative CPU time since boot.
 * For real-time usage, consider sampling twice with an interval.
 */
async function getCpuUsage() {
  try {
    // Read /proc/stat for CPU times
    const stat = await fs.readFile('/proc/stat', 'utf8');
    const cpuLine = stat.split('\n')[0];
    const times = cpuLine.split(/\s+/).slice(1, 8).map(Number);
    
    const idle = times[3];
    const total = times.reduce((a, b) => a + b, 0);
    
    // Calculate usage percentage (cumulative since boot)
    // Note: This is a snapshot, not current usage rate
    const usage = Math.round(((total - idle) / total) * 100);
    
    return Math.min(100, Math.max(0, usage));
  } catch (error) {
    logger.warn(`Failed to get CPU usage: ${error.message}`);
    return null;
  }
}

/**
 * Get disk usage
 */
async function getDiskUsage() {
  try {
    const result = await executeCommandForOutput('df', ['-h', '/']);
    const lines = result.split('\n');
    
    if (lines.length < 2) {
      throw new Error('Unexpected df output');
    }

    const parts = lines[1].split(/\s+/);
    
    return {
      filesystem: parts[0],
      size: parts[1],
      used: parts[2],
      available: parts[3],
      percentUsed: parseInt(parts[4], 10),
      mountPoint: parts[5],
    };
  } catch (error) {
    logger.warn(`Failed to get disk usage: ${error.message}`);
    return null;
  }
}

/**
 * Get CPU temperature (Raspberry Pi specific)
 */
async function getCpuTemperature() {
  try {
    // Try vcgencmd (Raspberry Pi)
    const result = await executeCommandForOutput('vcgencmd', ['measure_temp']);
    const match = result.match(/temp=([\d.]+)/);
    
    if (match) {
      return {
        celsius: parseFloat(match[1]),
        fahrenheit: parseFloat(match[1]) * 9 / 5 + 32,
      };
    }

    // Try reading thermal zone (alternative method)
    const tempStr = await fs.readFile('/sys/class/thermal/thermal_zone0/temp', 'utf8');
    const tempMilliC = parseInt(tempStr.trim(), 10);
    const tempC = tempMilliC / 1000;

    return {
      celsius: tempC,
      fahrenheit: tempC * 9 / 5 + 32,
    };
  } catch (error) {
    logger.warn(`Failed to get CPU temperature: ${error.message}`);
    return null;
  }
}

/**
 * Reboot system
 */
async function rebootSystem() {
  try {
    logger.warn('System reboot requested');
    
    const result = await executeCommand('reboot', [], { timeout: 5000 });
    
    return {
      success: result.success,
      message: 'System reboot initiated',
    };
  } catch (error) {
    logger.error(`Error rebooting system: ${error.message}`);
    throw error;
  }
}

/**
 * Shutdown system
 */
async function shutdownSystem() {
  try {
    logger.warn('System shutdown requested');
    
    const result = await executeCommand('shutdown', ['-h', 'now'], { timeout: 5000 });
    
    return {
      success: result.success,
      message: 'System shutdown initiated',
    };
  } catch (error) {
    logger.error(`Error shutting down system: ${error.message}`);
    throw error;
  }
}

/**
 * Update system packages
 */
async function updateSystem() {
  try {
    logger.info('System update requested');
    
    // Update package lists
    await executeCommand('apt-get', ['update'], { timeout: 120000 });
    
    // Upgrade packages (with -y for non-interactive)
    const result = await executeCommand('apt-get', ['upgrade', '-y'], { timeout: 600000 });
    
    return {
      success: result.success,
      message: 'System updated successfully',
      output: result.stdout,
    };
  } catch (error) {
    logger.error(`Error updating system: ${error.message}`);
    throw error;
  }
}

/**
 * Clean up system (remove old logs, temp files)
 */
async function cleanupSystem() {
  try {
    logger.info('System cleanup requested');
    
    const results = [];

    // Clean apt cache
    try {
      await executeCommand('apt-get', ['clean'], { timeout: 30000 });
      results.push('APT cache cleaned');
    } catch (err) {
      results.push(`APT cache clean failed: ${err.message}`);
    }

    // Remove old logs (older than 30 days)
    try {
      await executeCommand('find', ['/var/log', '-type', 'f', '-name', '*.log.*', '-mtime', '+30', '-delete'], { timeout: 60000 });
      results.push('Old log files removed');
    } catch (err) {
      results.push(`Log cleanup failed: ${err.message}`);
    }

    return {
      success: true,
      message: 'System cleanup completed',
      results,
    };
  } catch (error) {
    logger.error(`Error cleaning up system: ${error.message}`);
    throw error;
  }
}

module.exports = {
  getSystemMetrics,
  getCpuUsage,
  getDiskUsage,
  getCpuTemperature,
  rebootSystem,
  shutdownSystem,
  updateSystem,
  cleanupSystem,
};
