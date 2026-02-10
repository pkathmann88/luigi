/**
 * Config Service
 * Business logic for module configuration management
 */

const fs = require('fs').promises;
const path = require('path');
const logger = require('../utils/logger');
const { validateConfigPath } = require('../security/pathValidator');
const config = require('../../config');

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
 * Read configuration file
 */
async function readConfig(configPath) {
  try {
    // Validate path
    const validatedPath = validateConfigPath(configPath);

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
      file: path.basename(configPath),
      path: configPath,
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
    // Validate path
    const validatedPath = validateConfigPath(configPath);

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
      file: path.basename(configPath),
      path: configPath,
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
