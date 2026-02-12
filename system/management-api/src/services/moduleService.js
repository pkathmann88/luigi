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
 * Registry is the single source of truth for installed modules
 */
async function listModules() {
  try {
    // Get registry entries
    const registryEntries = await registryService.listRegistry();
    logger.info(`Found ${registryEntries.length} modules in registry`);
    
    // Build modules list from registry entries
    const modules = await Promise.all(
      registryEntries.map(async (registryEntry) => {
        const modulePath = registryEntry.module_path;
        const pathParts = modulePath.split('/');
        const moduleName = pathParts[pathParts.length - 1];
        const category = pathParts[0];
        
        // Get service status if module has service capability
        let serviceStatus = { status: 'installed', pid: null };
        if (registryEntry.capabilities && registryEntry.capabilities.includes('service')) {
          serviceStatus = await getServiceStatus(moduleName);
        }
        
        return {
          name: moduleName,
          path: modulePath,
          category,
          metadata: {
            name: registryEntry.name,
            version: registryEntry.version,
            description: registryEntry.description,
            capabilities: registryEntry.capabilities || [],
          },
          status: serviceStatus.status,
          pid: serviceStatus.pid,
          registry: registryEntry,
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
 * Get status of a specific module
 */
async function getModuleStatus(moduleName) {
  try {
    // Find the module
    const modules = await listModules();
    const module = modules.find(m => m.name === moduleName);

    if (!module) {
      throw new Error(`Module '${moduleName}' not found`);
    }

    // Try to get systemd service status
    // Service name might be the module name or have .service suffix
    let serviceName = moduleName;
    if (!serviceName.endsWith('.service')) {
      serviceName += '.service';
    }

    try {
      const result = await executeCommand('systemctl', ['status', serviceName], { timeout: 10000 });
      
      return {
        module: module.name,
        category: module.category,
        path: module.path,
        service: {
          name: serviceName,
          active: result.stdout.includes('Active: active'),
          enabled: result.stdout.includes('Loaded:') && result.stdout.includes('enabled'),
          status: result.stdout,
        },
        metadata: module.metadata,
      };
    } catch (error) {
      // Service might not exist
      return {
        module: module.name,
        category: module.category,
        path: module.path,
        service: {
          name: serviceName,
          active: false,
          enabled: false,
          status: 'Service not found or not installed',
        },
        metadata: module.metadata,
      };
    }
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
