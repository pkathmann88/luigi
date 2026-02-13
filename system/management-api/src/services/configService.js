/**
 * Config Service
 * Business logic for module configuration management
 */

const fs = require('fs').promises;
const path = require('path');
const logger = require('../utils/logger');
const { validateConfigPath } = require('../security/pathValidator');
const config = require('../../config');
const registryService = require('./registryService');

/**
 * List all module configuration files
 */
async function listConfigs() {
  try {
    const configPath = config.paths.config;
    const configs = [];

    // Helper function to scan directory
    async function scanDirectory(dir, depth = 0) {
      if (depth > 3) return;

      try {
        const entries = await fs.readdir(dir, { withFileTypes: true });

        for (const entry of entries) {
          const fullPath = path.join(dir, entry.name);
          const relativePath = path.relative(configPath, fullPath);

          if (entry.isFile() && (entry.name.endsWith('.conf') || entry.name.endsWith('.json') || entry.name === '.env')) {
            try {
              const stats = await fs.stat(fullPath);
              configs.push({
                name: entry.name,
                path: relativePath,
                fullPath,
                size: stats.size,
                modified: stats.mtime,
              });
            } catch (err) {
              // Skip files we can't stat
            }
          } else if (entry.isDirectory()) {
            await scanDirectory(fullPath, depth + 1);
          }
        }
      } catch (err) {
        logger.warn(`Error reading directory ${dir}: ${err.message}`);
      }
    }

    await scanDirectory(configPath);
    return configs.sort((a, b) => a.path.localeCompare(b.path));
  } catch (error) {
    logger.error(`Error listing configs: ${error.message}`);
    throw error;
  }
}

/**
 * Resolve module name or path to actual config file path
 * Tries multiple strategies:
 * 1. Use path as-is if it looks like a full file path
 * 2. Look up module in registry to get config_path
 * 3. Check if config_path is a directory and find config file within it
 * 4. Try common config file patterns
 */
async function resolveConfigPath(moduleNameOrPath) {
  // If it already has a file extension, use as-is
  if (moduleNameOrPath.includes('.conf') || moduleNameOrPath.includes('.json') || moduleNameOrPath.includes('.env')) {
    return moduleNameOrPath;
  }

  // Try to find module in registry and get config_path
  try {
    // First, try as module name directly (e.g., "ha-mqtt" or "mario")
    let modulePath = moduleNameOrPath;
    let moduleName = moduleNameOrPath;
    
    // If it's just a simple name, try to find it in the registry
    // by searching through registry entries
    if (!moduleNameOrPath.includes('/')) {
      // Simple module name - need to search registry
      const entries = await registryService.listRegistry();
      const matchingEntry = entries.find(entry => entry.name === moduleNameOrPath);
      
      if (matchingEntry && matchingEntry.module_path) {
        modulePath = matchingEntry.module_path;
      }
    } else {
      // Extract module name from path (e.g., "iot/ha-mqtt" -> "ha-mqtt")
      moduleName = path.basename(modulePath);
    }
    
    // Try to get registry entry
    const entry = await registryService.getRegistryEntry(modulePath);
    
    if (entry && entry.config_path) {
      // Extract relative path from absolute config_path
      // e.g., "/etc/luigi/iot/ha-mqtt/ha-mqtt.conf" -> "iot/ha-mqtt/ha-mqtt.conf"
      // or "/etc/luigi/iot/ha-mqtt" -> "iot/ha-mqtt"
      const configBase = config.paths.config; // "/etc/luigi"
      let relativePath = entry.config_path;
      
      if (entry.config_path.startsWith(configBase)) {
        relativePath = entry.config_path.substring(configBase.length).replace(/^\//, '');
      }
      
      // Check if this path is a directory
      const fullPath = path.join(configBase, relativePath);
      try {
        const stats = await fs.stat(fullPath);
        
        if (stats.isDirectory()) {
          // Path is a directory - need to find config file within it
          logger.debug(`Config path is directory: ${relativePath}, searching for config files`);
          
          // Try to find a config file in the directory
          const files = await fs.readdir(fullPath);
          
          // Preferred patterns in order of priority
          const patterns = [
            `${moduleName}.conf`,           // e.g., ha-mqtt.conf
            `${moduleName}.json`,           // e.g., ha-mqtt.json
            '.env',                         // .env file
            'config.conf',                  // generic config.conf
            'config.json',                  // generic config.json
          ];
          
          // Find first matching file
          for (const pattern of patterns) {
            if (files.includes(pattern)) {
              const configFile = path.join(relativePath, pattern);
              logger.info(`Resolved module '${moduleNameOrPath}' to config file: ${configFile}`);
              return configFile;
            }
          }
          
          // No specific pattern matched, try any .conf, .json, or .env file
          const configFile = files.find(f => 
            f.endsWith('.conf') || f.endsWith('.json') || f === '.env'
          );
          
          if (configFile) {
            const fullConfigPath = path.join(relativePath, configFile);
            logger.info(`Resolved module '${moduleNameOrPath}' to config file: ${fullConfigPath}`);
            return fullConfigPath;
          }
          
          // No config files found in directory
          throw new Error(`No config files found in directory: ${relativePath}`);
        } else {
          // Path is a file - use it directly
          logger.info(`Resolved module '${moduleNameOrPath}' to config path: ${relativePath}`);
          return relativePath;
        }
      } catch (statErr) {
        // Path doesn't exist or can't be accessed, return as-is and let validation handle it
        logger.debug(`Could not stat config path ${fullPath}: ${statErr.message}`);
        return relativePath;
      }
    }
  } catch (err) {
    // Registry lookup failed, continue with fallback strategies
    logger.debug(`Registry lookup failed for '${moduleNameOrPath}': ${err.message}`);
  }

  // Fallback: try common patterns
  // Pattern 1: module/module.conf (e.g., "ha-mqtt" -> "iot/ha-mqtt/ha-mqtt.conf")
  // Pattern 2: module.conf (e.g., "ha-mqtt" -> "ha-mqtt.conf")
  
  // If path contains slashes, assume it's a partial path and try adding extensions
  if (moduleNameOrPath.includes('/')) {
    const baseName = path.basename(moduleNameOrPath);
    return `${moduleNameOrPath}/${baseName}.conf`;
  }

  // Simple name without slashes - cannot reliably determine path
  // Return as-is and let the error message be clear
  return moduleNameOrPath;
}

/**
 * Read configuration file
 */
async function readConfig(configPath) {
  try {
    // Resolve module name to actual config file path
    const resolvedPath = await resolveConfigPath(configPath);
    
    // Validate path
    const validatedPath = validateConfigPath(resolvedPath);

    // Check if file exists
    try {
      await fs.access(validatedPath);
    } catch (err) {
      throw new Error(`Config file not found: ${configPath}`);
    }

    // Read file content
    const content = await fs.readFile(validatedPath, 'utf8');

    // Parse based on file type
    let parsed = null;
    const ext = path.extname(validatedPath);

    if (ext === '.json') {
      try {
        parsed = JSON.parse(content);
      } catch (err) {
        // Invalid JSON
      }
    } else if (ext === '.conf' || validatedPath.endsWith('.env')) {
      // Parse INI/ENV format
      parsed = parseIniFormat(content);
    }

    return {
      file: path.basename(resolvedPath),
      path: resolvedPath,
      content,
      parsed,
      format: ext === '.json' ? 'json' : 'ini',
    };
  } catch (error) {
    logger.error(`Error reading config: ${error.message}`);
    throw error;
  }
}

/**
 * Update configuration file
 */
async function updateConfig(configPath, updates) {
  try {
    // Resolve module name to actual config file path
    const resolvedPath = await resolveConfigPath(configPath);
    
    // Validate path
    const validatedPath = validateConfigPath(resolvedPath);

    // Check if file exists
    try {
      await fs.access(validatedPath);
    } catch (err) {
      throw new Error(`Config file not found: ${configPath}`);
    }

    // Create backup
    const backupPath = `${validatedPath}.backup`;
    await fs.copyFile(validatedPath, backupPath);

    logger.info(`Created config backup: ${backupPath}`);

    // Read current content
    const current = await readConfig(configPath);

    let newContent;
    if (current.format === 'json') {
      // Update JSON
      const config = JSON.parse(current.content);
      Object.assign(config, updates);
      newContent = JSON.stringify(config, null, 2);
    } else {
      // Update INI/ENV format
      newContent = updateIniFormat(current.content, updates);
    }

    // Write new content
    await fs.writeFile(validatedPath, newContent, 'utf8');

    logger.info(`Updated config file: ${configPath}`);

    return {
      success: true,
      file: path.basename(resolvedPath),
      path: resolvedPath,
      backup: backupPath,
      updates,
    };
  } catch (error) {
    logger.error(`Error updating config: ${error.message}`);
    throw error;
  }
}

/**
 * Parse INI/ENV format into object
 */
function parseIniFormat(content) {
  const parsed = {};
  let currentSection = 'default';
  parsed[currentSection] = {};

  const lines = content.split('\n');

  for (const line of lines) {
    const trimmed = line.trim();

    // Skip comments and empty lines
    if (!trimmed || trimmed.startsWith('#') || trimmed.startsWith(';')) {
      continue;
    }

    // Check for section header [Section]
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      currentSection = trimmed.slice(1, -1);
      parsed[currentSection] = {};
      continue;
    }

    // Parse key=value
    const equalIndex = trimmed.indexOf('=');
    if (equalIndex > 0) {
      const key = trimmed.slice(0, equalIndex).trim();
      const value = trimmed.slice(equalIndex + 1).trim();
      parsed[currentSection][key] = value;
    }
  }

  return parsed;
}

/**
 * Update INI/ENV format with new values
 */
function updateIniFormat(content, updates) {
  const lines = content.split('\n');
  const newLines = [];
  let currentSection = 'default';

  for (const line of lines) {
    const trimmed = line.trim();

    // Preserve comments and empty lines
    if (!trimmed || trimmed.startsWith('#') || trimmed.startsWith(';')) {
      newLines.push(line);
      continue;
    }

    // Check for section header
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      currentSection = trimmed.slice(1, -1);
      newLines.push(line);
      continue;
    }

    // Parse key=value
    const equalIndex = trimmed.indexOf('=');
    if (equalIndex > 0) {
      const key = trimmed.slice(0, equalIndex).trim();
      
      // Check if this key should be updated
      if (updates[key] !== undefined) {
        newLines.push(`${key}=${updates[key]}`);
      } else {
        newLines.push(line);
      }
    } else {
      newLines.push(line);
    }
  }

  return newLines.join('\n');
}

module.exports = {
  listConfigs,
  readConfig,
  updateConfig,
};
