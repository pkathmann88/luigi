/**
 * Sound Service
 * Business logic for managing module sound files and playback
 */

const fs = require('fs').promises;
const path = require('path');
const logger = require('../utils/logger');
const { executeCommand } = require('../utils/commandExecutor');
const registryService = require('./registryService');

/**
 * Get all modules with sound capability
 * @returns {Promise<Array>} Array of modules with sound capability
 */
async function listSoundModules() {
  try {
    // Get all registry entries
    const registryEntries = await registryService.listRegistry();
    
    // Filter modules with sound capability
    const soundModules = registryEntries
      .filter(entry => {
        return entry.capabilities && entry.capabilities.includes('sound');
      })
      .map(entry => {
        const pathParts = entry.module_path.split('/');
        const moduleName = pathParts[pathParts.length - 1];
        
        return {
          name: moduleName,
          module_path: entry.module_path,
          sound_directory: entry.sound_directory || null,
          version: entry.version,
          description: entry.description,
        };
      });
    
    logger.info(`Found ${soundModules.length} modules with sound capability`);
    return soundModules;
  } catch (error) {
    logger.error(`Error listing sound modules: ${error.message}`);
    throw error;
  }
}

/**
 * Get sound files for a specific module
 * @param {string} moduleName - Name of the module
 * @returns {Promise<Object>} Object with module info and sound files
 */
async function getModuleSounds(moduleName) {
  try {
    // Find module in registry
    const registryEntry = await registryService.getRegistryByModuleName(moduleName);
    
    if (!registryEntry) {
      throw new Error(`Module not found in registry: ${moduleName}`);
    }
    
    // Check if module has sound capability
    if (!registryEntry.capabilities || !registryEntry.capabilities.includes('sound')) {
      throw new Error(`Module ${moduleName} does not have sound capability`);
    }
    
    // Get sound directory from registry
    const soundDirectory = registryEntry.sound_directory;
    
    if (!soundDirectory) {
      throw new Error(`Module ${moduleName} has sound capability but no sound_directory configured`);
    }
    
    // Check if directory exists
    try {
      await fs.access(soundDirectory);
    } catch (error) {
      logger.warn(`Sound directory does not exist: ${soundDirectory}`);
      return {
        module: moduleName,
        sound_directory: soundDirectory,
        exists: false,
        files: [],
      };
    }
    
    // Read sound files from directory
    const files = await fs.readdir(soundDirectory);
    
    // Filter for audio files (wav, mp3, ogg)
    const audioExtensions = ['.wav', '.mp3', '.ogg', '.flac'];
    const soundFiles = files
      .filter(file => {
        const ext = path.extname(file).toLowerCase();
        return audioExtensions.includes(ext);
      })
      .sort();
    
    // Get file details
    const fileDetails = await Promise.all(
      soundFiles.map(async (file) => {
        const filePath = path.join(soundDirectory, file);
        try {
          const stats = await fs.stat(filePath);
          return {
            name: file,
            path: filePath,
            size: stats.size,
            modified: stats.mtime.toISOString(),
            extension: path.extname(file).toLowerCase().slice(1),
          };
        } catch (error) {
          logger.warn(`Could not stat file ${filePath}: ${error.message}`);
          return null;
        }
      })
    );
    
    // Filter out null entries (files that couldn't be stat'd)
    const validFiles = fileDetails.filter(f => f !== null);
    
    logger.info(`Found ${validFiles.length} sound files for module ${moduleName}`);
    
    return {
      module: moduleName,
      sound_directory: soundDirectory,
      exists: true,
      files: validFiles,
      count: validFiles.length,
    };
  } catch (error) {
    logger.error(`Error getting sounds for module ${moduleName}: ${error.message}`);
    throw error;
  }
}

/**
 * Play a sound file using aplay
 * @param {string} moduleName - Name of the module
 * @param {string} soundFile - Name of the sound file to play
 * @returns {Promise<Object>} Result of play operation
 */
async function playSound(moduleName, soundFile) {
  try {
    // Get module sounds to verify file exists
    const moduleSounds = await getModuleSounds(moduleName);
    
    if (!moduleSounds.exists) {
      throw new Error(`Sound directory does not exist for module ${moduleName}`);
    }
    
    // Find the requested sound file
    const soundFileInfo = moduleSounds.files.find(f => f.name === soundFile);
    
    if (!soundFileInfo) {
      throw new Error(`Sound file not found: ${soundFile}`);
    }
    
    // Validate file path (security check - ensure it's within sound directory)
    const soundPath = soundFileInfo.path;
    const soundDir = moduleSounds.sound_directory;
    const resolvedPath = path.resolve(soundPath);
    const resolvedDir = path.resolve(soundDir);
    
    if (!resolvedPath.startsWith(resolvedDir)) {
      throw new Error('Invalid sound file path');
    }
    
    // Play sound using aplay (non-blocking)
    logger.info(`Playing sound: ${soundPath}`);
    
    // Use aplay for WAV files, mpg123 for MP3 (if available)
    const extension = path.extname(soundFile).toLowerCase();
    let command, args;
    
    if (extension === '.wav') {
      command = 'aplay';
      args = ['-q', soundPath];  // -q for quiet mode
    } else if (extension === '.mp3') {
      // Try mpg123, fall back to aplay
      command = 'mpg123';
      args = ['-q', soundPath];  // -q for quiet mode
    } else {
      // For other formats, try aplay
      command = 'aplay';
      args = ['-q', soundPath];
    }
    
    // Execute command in background (don't wait for completion)
    // Use timeout to prevent hanging
    executeCommand(command, args, { 
      timeout: 30000,  // 30 second timeout
      detached: true,  // Run in background
    }).catch(error => {
      logger.error(`Error playing sound: ${error.message}`);
    });
    
    logger.info(`Started playback of ${soundFile} for module ${moduleName}`);
    
    return {
      success: true,
      module: moduleName,
      file: soundFile,
      message: 'Sound playback started',
    };
  } catch (error) {
    logger.error(`Error playing sound for module ${moduleName}: ${error.message}`);
    throw error;
  }
}

module.exports = {
  listSoundModules,
  getModuleSounds,
  playSound,
};
