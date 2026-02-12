/**
 * Registry Service
 * Business logic for module registry operations
 * Provides read-only access to the centralized module registry at /etc/luigi/modules/
 */

const fs = require('fs').promises;
const path = require('path');
const logger = require('../utils/logger');
const config = require('../../config');

// Registry path from config
const REGISTRY_PATH = config.paths.registry;

/**
 * Decode module path from registry filename
 * Converts double underscores (__) back to forward slashes (/)
 * @param {string} filename - Registry filename (e.g., "motion-detection__mario.json")
 * @returns {string} Module path (e.g., "motion-detection/mario")
 */
function decodeModulePath(filename) {
  // Remove .json extension
  const withoutExt = filename.replace(/\.json$/, '');
  // Replace __ with /
  return withoutExt.replace(/__/g, '/');
}

/**
 * Encode module path to registry filename format
 * Converts forward slashes (/) to double underscores (__)
 * @param {string} modulePath - Module path (e.g., "motion-detection/mario")
 * @returns {string} Registry filename (e.g., "motion-detection__mario.json")
 */
function encodeModulePath(modulePath) {
  return modulePath.replace(/\//g, '__') + '.json';
}

/**
 * List all module registry entries
 * @returns {Promise<Array>} Array of registry entries
 */
async function listRegistry() {
  try {
    // Check if registry directory exists
    try {
      await fs.access(REGISTRY_PATH);
    } catch (err) {
      logger.warn(`Registry directory not found: ${REGISTRY_PATH}`);
      return [];
    }

    // Read all .json files from registry
    const files = await fs.readdir(REGISTRY_PATH);
    const jsonFiles = files.filter(f => f.endsWith('.json'));

    if (jsonFiles.length === 0) {
      logger.info('No registry entries found');
      return [];
    }

    // Read and parse each registry file
    const entries = await Promise.all(
      jsonFiles.map(async (filename) => {
        try {
          const filePath = path.join(REGISTRY_PATH, filename);
          const content = await fs.readFile(filePath, 'utf8');
          const entry = JSON.parse(content);
          
          // Add computed filename for reference
          entry._registryFile = filename;
          
          return entry;
        } catch (err) {
          logger.error(`Error reading registry file ${filename}: ${err.message}`);
          return null;
        }
      })
    );

    // Filter out failed reads and sort by module_path
    const validEntries = entries
      .filter(e => e !== null)
      .sort((a, b) => a.module_path.localeCompare(b.module_path));

    return validEntries;
  } catch (error) {
    logger.error(`Error listing registry: ${error.message}`);
    throw error;
  }
}

/**
 * Get a specific module's registry entry
 * @param {string} modulePath - Module path (e.g., "motion-detection/mario")
 * @returns {Promise<Object>} Registry entry
 * @throws {Error} If module not found in registry
 */
async function getRegistryEntry(modulePath) {
  try {
    const filename = encodeModulePath(modulePath);
    const filePath = path.join(REGISTRY_PATH, filename);

    // Check if file exists
    try {
      await fs.access(filePath);
    } catch (err) {
      throw new Error(`Module '${modulePath}' not found in registry`);
    }

    // Read and parse registry file
    const content = await fs.readFile(filePath, 'utf8');
    const entry = JSON.parse(content);
    
    // Add computed filename for reference
    entry._registryFile = filename;

    return entry;
  } catch (error) {
    if (error.message.includes('not found in registry')) {
      throw error;
    }
    logger.error(`Error reading registry entry for ${modulePath}: ${error.message}`);
    throw new Error(`Failed to read registry entry for '${modulePath}'`);
  }
}

/**
 * Get registry statistics
 * @returns {Promise<Object>} Registry statistics
 */
async function getRegistryStats() {
  try {
    const entries = await listRegistry();
    
    // Count by status
    const statusCounts = entries.reduce((acc, entry) => {
      const status = entry.status || 'unknown';
      acc[status] = (acc[status] || 0) + 1;
      return acc;
    }, {});

    // Count by category
    const categoryCounts = entries.reduce((acc, entry) => {
      const category = entry.category || 'unknown';
      acc[category] = (acc[category] || 0) + 1;
      return acc;
    }, {});

    // Count modules with capabilities
    const capabilityCounts = entries.reduce((acc, entry) => {
      if (entry.capabilities && Array.isArray(entry.capabilities)) {
        entry.capabilities.forEach(cap => {
          acc[cap] = (acc[cap] || 0) + 1;
        });
      }
      return acc;
    }, {});

    return {
      total: entries.length,
      byStatus: statusCounts,
      byCategory: categoryCounts,
      byCapability: capabilityCounts,
    };
  } catch (error) {
    logger.error(`Error getting registry stats: ${error.message}`);
    throw error;
  }
}

module.exports = {
  listRegistry,
  getRegistryEntry,
  getRegistryStats,
  encodeModulePath,
  decodeModulePath,
};
