/**
 * Module Service
 * Business logic for Luigi module management operations
 */

const logger = require('../utils/logger');
const { executeCommand, executeCommandForOutput } = require('../utils/commandExecutor');
const registryService = require('./registryService');

/**
 * Get basic status info for a module service
 * Returns null if service doesn't exist or can't be queried
 */
async function getServiceStatus(moduleName) {
  try {
    let serviceName = moduleName;
    if (!serviceName.endsWith('.service')) {
      serviceName += '.service';
    }

    const result = await executeCommand('systemctl', ['status', serviceName], { timeout: 5000 });
    const stdout = result.stdout || '';
    
    // Parse status
    const isActive = stdout.includes('Active: active');
    const isInactive = stdout.includes('Active: inactive');
    const isFailed = stdout.includes('Active: failed');
    
    let status = 'unknown';
    if (isActive) {
      status = 'active';
    } else if (isInactive) {
      status = 'inactive';
    } else if (isFailed) {
      status = 'failed';
    }
    
    // Try to extract PID from Main PID line
    let pid = null;
    const pidMatch = stdout.match(/Main PID: (\d+)/);
    if (pidMatch) {
      pid = parseInt(pidMatch[1], 10);
    }
    
    return { status, pid };
  } catch (error) {
    // Service doesn't exist or systemctl failed
    return { status: 'unknown', pid: null };
  }
}

/**
 * Find all Luigi modules using the centralized registry
 * Returns minimal data for list view (name, status, version, capabilities)
 * Registry is the single source of truth for installed modules
 */
async function listModules() {
  try {
    // Get registry entries
    const registryEntries = await registryService.listRegistry();
    logger.info(`Found ${registryEntries.length} modules in registry`);
    
    // Build minimal modules list from registry entries
    const modules = await Promise.all(
      registryEntries.map(async (registryEntry) => {
        const modulePath = registryEntry.module_path;
        const pathParts = modulePath.split('/');
        const moduleName = pathParts[pathParts.length - 1];
        
        // Get service status if module has service capability
        let status = 'installed';
        if (registryEntry.capabilities && registryEntry.capabilities.includes('service')) {
          const serviceStatus = await getServiceStatus(moduleName);
          status = serviceStatus.status;
        }
        
        // Return minimal data for list view
        return {
          name: moduleName,
          status,
          version: registryEntry.version,
          capabilities: registryEntry.capabilities || [],
        };
      })
    );
    
    return modules;
  } catch (error) {
    logger.error(`Error listing modules: ${error.message}`);
    throw error;
  }
}

/**
 * Get comprehensive details of a specific module
 * Returns all data including registry, status, runtime info
 */
async function getModuleStatus(moduleName) {
  try {
    // Get registry entries
    const registryEntries = await registryService.listRegistry();
    
    // Find the module's registry entry
    const registryEntry = registryEntries.find(entry => {
      const pathParts = entry.module_path.split('/');
      const name = pathParts[pathParts.length - 1];
      return name === moduleName;
    });

    if (!registryEntry) {
      throw new Error(`Module '${moduleName}' not found`);
    }

    const modulePath = registryEntry.module_path;
    const pathParts = modulePath.split('/');
    const category = pathParts[0];
    
    // Get service status if module has service capability
    let status = 'installed';
    let pid = null;
    let uptime = null;
    let memory = null;
    
    if (registryEntry.capabilities && registryEntry.capabilities.includes('service')) {
      const serviceStatus = await getServiceStatus(moduleName);
      status = serviceStatus.status;
      pid = serviceStatus.pid;
      
      // If service is active, try to get additional runtime info
      if (status === 'active' && pid) {
        try {
          // Get uptime from systemctl show
          const uptimeResult = await executeCommand('systemctl', ['show', `${moduleName}.service`, '--property=ActiveEnterTimestamp'], { timeout: 5000 });
          if (uptimeResult.stdout) {
            const timestampMatch = uptimeResult.stdout.match(/ActiveEnterTimestamp=(.+)/);
            if (timestampMatch && timestampMatch[1] !== 'n/a') {
              const startTime = new Date(timestampMatch[1]);
              uptime = Math.floor((Date.now() - startTime.getTime()) / 1000); // seconds
            }
          }
          
          // Get memory usage from /proc if PID exists
          const memResult = await executeCommand('cat', [`/proc/${pid}/status`], { timeout: 5000 });
          if (memResult.stdout) {
            const memMatch = memResult.stdout.match(/VmRSS:\s+(\d+)\s+kB/);
            if (memMatch) {
              memory = parseInt(memMatch[1], 10); // KB
            }
          }
        } catch (error) {
          // Non-critical - runtime info is optional
          logger.debug(`Could not get runtime info for ${moduleName}: ${error.message}`);
        }
      }
    }
    
    // Return comprehensive module data
    return {
      name: moduleName,
      path: modulePath,
      category,
      fullPath: `/home/pi/luigi/${modulePath}`, // Construct full path
      metadata: {
        name: registryEntry.name,
        version: registryEntry.version,
        description: registryEntry.description,
        capabilities: registryEntry.capabilities || [],
      },
      status,
      enabled: true, // All registry modules are considered enabled
      pid,
      uptime,
      memory,
      registry: registryEntry,
    };
  } catch (error) {
    logger.error(`Error getting module status: ${error.message}`);
    throw error;
  }
}

/**
 * Start a module service
 */
async function startModule(moduleName) {
  try {
    let serviceName = moduleName;
    if (!serviceName.endsWith('.service')) {
      serviceName += '.service';
    }

    const result = await executeCommand('systemctl', ['start', serviceName], { timeout: 30000 });
    
    return {
      success: result.success,
      module: moduleName,
      operation: 'start',
      message: result.success ? 'Module started successfully' : result.stderr,
    };
  } catch (error) {
    logger.error(`Error starting module: ${error.message}`);
    throw error;
  }
}

/**
 * Stop a module service
 */
async function stopModule(moduleName) {
  try {
    let serviceName = moduleName;
    if (!serviceName.endsWith('.service')) {
      serviceName += '.service';
    }

    const result = await executeCommand('systemctl', ['stop', serviceName], { timeout: 30000 });
    
    return {
      success: result.success,
      module: moduleName,
      operation: 'stop',
      message: result.success ? 'Module stopped successfully' : result.stderr,
    };
  } catch (error) {
    logger.error(`Error stopping module: ${error.message}`);
    throw error;
  }
}

/**
 * Restart a module service
 */
async function restartModule(moduleName) {
  try {
    let serviceName = moduleName;
    if (!serviceName.endsWith('.service')) {
      serviceName += '.service';
    }

    const result = await executeCommand('systemctl', ['restart', serviceName], { timeout: 30000 });
    
    return {
      success: result.success,
      module: moduleName,
      operation: 'restart',
      message: result.success ? 'Module restarted successfully' : result.stderr,
    };
  } catch (error) {
    logger.error(`Error restarting module: ${error.message}`);
    throw error;
  }
}

module.exports = {
  listModules,
  getModuleStatus,
  startModule,
  stopModule,
  restartModule,
};
