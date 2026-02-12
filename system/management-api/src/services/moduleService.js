/**
 * Module Service
 * Business logic for Luigi module management operations
 */

const fs = require('fs').promises;
const path = require('path');
const logger = require('../utils/logger');
const { executeCommand, executeCommandForOutput } = require('../utils/commandExecutor');
const { validateModulePath } = require('../security/pathValidator');
const config = require('../../config');
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
 * Find all Luigi modules using the centralized registry as primary source
 * Falls back to filesystem scanning if registry is empty (development mode)
 */
async function listModules() {
  try {
    // Get registry entries (primary source)
    let registryEntries = [];
    try {
      registryEntries = await registryService.listRegistry();
      logger.info(`Found ${registryEntries.length} modules in registry`);
    } catch (err) {
      logger.warn(`Failed to load registry data: ${err.message}`);
    }
    
    // If registry has entries, use it as the primary source
    if (registryEntries.length > 0) {
      logger.info('Using registry as primary source for module list');
      
      // Build modules list from registry entries
      const modules = await Promise.all(
        registryEntries.map(async (registryEntry) => {
          const modulePath = registryEntry.module_path;
          const pathParts = modulePath.split('/');
          const moduleName = pathParts[pathParts.length - 1];
          const category = pathParts[0];
          
          // Get service status if module has service capability
          let serviceStatus = { status: 'unknown', pid: null };
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
    }
    
    // Fallback: scan filesystem if registry is empty (development mode)
    logger.warn('Registry is empty, falling back to filesystem scan');
    const modulesPath = config.paths.modules;
    const modules = [];

    // Check if modules directory exists
    try {
      await fs.access(modulesPath);
    } catch (err) {
      logger.error(`Modules directory not found: ${modulesPath}`);
      return modules; // Return empty array if directory doesn't exist
    }

    // Helper function to search directories recursively
    async function searchDirectory(dir, depth = 0) {
      if (depth > 3) return; // Limit depth to prevent excessive scanning

      try {
        const entries = await fs.readdir(dir, { withFileTypes: true });

        for (const entry of entries) {
          if (entry.isDirectory()) {
            const subPath = path.join(dir, entry.name);
            
            // Check if setup.sh exists in this directory
            const setupPath = path.join(subPath, 'setup.sh');
            try {
              await fs.access(setupPath);
              
              // This is a module directory
              const relativePath = path.relative(modulesPath, subPath);
              const category = relativePath.split(path.sep)[0];
              const moduleName = path.basename(subPath);

              // Try to read module.json if it exists
              let metadata = null;
              try {
                const moduleJsonPath = path.join(subPath, 'module.json');
                const moduleJson = await fs.readFile(moduleJsonPath, 'utf8');
                metadata = JSON.parse(moduleJson);
              } catch (err) {
                // module.json doesn't exist or is invalid
              }

              modules.push({
                name: moduleName,
                path: relativePath,
                category,
                fullPath: subPath,
                metadata,
              });
            } catch (err) {
              // setup.sh doesn't exist, search subdirectories
              await searchDirectory(subPath, depth + 1);
            }
          }
        }
      } catch (err) {
        logger.warn(`Error reading directory ${dir}: ${err.message}`);
      }
    }

    await searchDirectory(modulesPath);
    
    if (modules.length === 0) {
      logger.warn(`No modules found. Registry is empty and no setup.sh files found in ${modulesPath}.`);
      return modules;
    }
    
    // Enrich modules with status information
    const enrichedModules = await Promise.all(
      modules.map(async (module) => {
        const serviceStatus = await getServiceStatus(module.name);
        
        return {
          ...module,
          status: serviceStatus.status,
          pid: serviceStatus.pid,
          registry: null, // No registry data in fallback mode
        };
      })
    );
    
    return enrichedModules;
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
