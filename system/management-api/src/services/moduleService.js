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

/**
 * Find all Luigi modules by looking for setup.sh files
 */
async function listModules() {
  try {
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
      logger.warn(`No modules found in ${modulesPath}. Check MODULES_PATH configuration.`);
    }
    
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
