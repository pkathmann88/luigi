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
    logger.info('='.repeat(70));
    logger.info(`SOUND PLAYBACK REQUEST: module=${moduleName}, file=${soundFile}`);
    logger.info('='.repeat(70));
    
    // Log process information
    logger.info(`Process UID: ${process.getuid()}, GID: ${process.getgid()}`);
    logger.info(`Process user: ${process.env.USER || 'unknown'}`);
    logger.info(`Groups: ${process.getgroups ? process.getgroups().join(', ') : 'unavailable'}`);
    
    // Check audio group membership
    const { execSync } = require('child_process');
    try {
      const groups = execSync('groups', { encoding: 'utf8' }).trim();
      logger.info(`Current user groups: ${groups}`);
      const hasAudioGroup = groups.includes('audio');
      logger.info(`Audio group membership: ${hasAudioGroup ? 'YES' : 'NO (PROBLEM!)'}`);
      if (!hasAudioGroup) {
        logger.warn('WARNING: Process user is not in audio group - sound playback will likely fail!');
      }
    } catch (err) {
      logger.warn(`Could not check group membership: ${err.message}`);
    }
    
    // Check audio devices
    logger.info('Checking audio device availability...');
    try {
      const devices = execSync('ls -la /dev/snd/ 2>&1', { encoding: 'utf8' });
      logger.info(`Audio devices:\n${devices}`);
    } catch (err) {
      logger.error(`Cannot access audio devices: ${err.message}`);
    }
    
    // Get module sounds to verify file exists
    logger.info(`Retrieving sound files for module: ${moduleName}`);
    const moduleSounds = await getModuleSounds(moduleName);
    
    if (!moduleSounds.exists) {
      logger.error(`Sound directory does not exist: ${moduleSounds.sound_directory}`);
      throw new Error(`Sound directory does not exist for module ${moduleName}`);
    }
    
    logger.info(`Sound directory exists: ${moduleSounds.sound_directory}`);
    logger.info(`Available sound files: ${moduleSounds.files.map(f => f.name).join(', ')}`);
    
    // Find the requested sound file
    const soundFileInfo = moduleSounds.files.find(f => f.name === soundFile);
    
    if (!soundFileInfo) {
      logger.error(`Requested file not found: ${soundFile}`);
      logger.error(`Available files: ${moduleSounds.files.map(f => f.name).join(', ')}`);
      throw new Error(`Sound file not found: ${soundFile}`);
    }
    
    logger.info(`Found sound file: ${soundFileInfo.name} (${soundFileInfo.size} bytes)`);
    
    // Validate file path (security check - ensure it's within sound directory)
    const soundPath = soundFileInfo.path;
    const soundDir = moduleSounds.sound_directory;
    const resolvedPath = path.resolve(soundPath);
    const resolvedDir = path.resolve(soundDir);
    
    logger.info(`Resolved sound path: ${resolvedPath}`);
    logger.info(`Resolved sound directory: ${resolvedDir}`);
    
    if (!resolvedPath.startsWith(resolvedDir)) {
      logger.error(`Security violation: Path traversal detected!`);
      logger.error(`  Resolved path: ${resolvedPath}`);
      logger.error(`  Allowed directory: ${resolvedDir}`);
      throw new Error('Invalid sound file path');
    }
    
    logger.info('Path validation: PASSED');
    
    // Check file permissions
    try {
      const stats = await fs.stat(soundPath);
      logger.info(`File permissions: ${stats.mode.toString(8)}`);
      logger.info(`File owner: uid=${stats.uid}, gid=${stats.gid}`);
      logger.info(`File readable: ${(stats.mode & 0o004) ? 'YES' : 'NO'}`);
    } catch (err) {
      logger.error(`Could not stat file: ${err.message}`);
    }
    
    // Use aplay for WAV files, mpg123 for MP3 (if available)
    const extension = path.extname(soundFile).toLowerCase();
    let command, args;
    
    if (extension === '.wav') {
      command = 'aplay';
      args = [soundPath];  // Remove -q to see output
    } else if (extension === '.mp3') {
      command = 'mpg123';
      args = [soundPath];  // Remove -q to see output
    } else {
      command = 'aplay';
      args = [soundPath];  // Remove -q to see output
    }
    
    logger.info(`Command to execute: ${command} ${args.join(' ')}`);
    
    // Check if command exists
    try {
      const commandPath = execSync(`which ${command} 2>&1`, { encoding: 'utf8' }).trim();
      logger.info(`Command found at: ${commandPath}`);
    } catch (err) {
      logger.error(`Command not found: ${command}`);
      logger.error(`Error: ${err.message}`);
    }
    
    // Log environment
    logger.info('Relevant environment variables:');
    logger.info(`  HOME: ${process.env.HOME || 'not set'}`);
    logger.info(`  USER: ${process.env.USER || 'not set'}`);
    logger.info(`  PATH: ${process.env.PATH || 'not set'}`);
    logger.info(`  AUDIODEV: ${process.env.AUDIODEV || 'not set'}`);
    logger.info(`  ALSA_CARD: ${process.env.ALSA_CARD || 'not set'}`);
    
    logger.info('-'.repeat(70));
    logger.info('Executing sound playback command...');
    logger.info('-'.repeat(70));
    
    // Execute command and check result
    // Don't wait for completion (audio plays in background)
    // but do check if command starts successfully
    executeCommand(command, args, { 
      timeout: 30000,  // 30 second timeout
    }).then(result => {
      logger.info('='.repeat(70));
      logger.info('SOUND PLAYBACK RESULT');
      logger.info('='.repeat(70));
      logger.info(`Success: ${result.success}`);
      logger.info(`Exit code: ${result.exitCode}`);
      logger.info(`Duration: ${result.duration}ms`);
      
      if (result.stdout) {
        logger.info(`STDOUT:\n${result.stdout}`);
      } else {
        logger.info('STDOUT: (empty)');
      }
      
      if (result.stderr) {
        logger.info(`STDERR:\n${result.stderr}`);
      } else {
        logger.info('STDERR: (empty)');
      }
      
      if (result.success) {
        logger.info(`✓ Successfully played sound: ${soundFile}`);
      } else {
        logger.error(`✗ Sound playback failed with exit code ${result.exitCode}`);
        if (result.stderr) {
          logger.error(`Error output: ${result.stderr}`);
        }
        if (result.stdout) {
          logger.error(`Standard output: ${result.stdout}`);
        }
      }
      logger.info('='.repeat(70));
    }).catch(error => {
      logger.error('='.repeat(70));
      logger.error('SOUND PLAYBACK EXCEPTION');
      logger.error('='.repeat(70));
      logger.error(`Exception: ${error.message}`);
      logger.error(`Stack trace:\n${error.stack}`);
      logger.error('='.repeat(70));
    });
    
    logger.info(`Playback request initiated for ${soundFile}`);
    
    return {
      success: true,
      module: moduleName,
      file: soundFile,
      message: 'Sound playback started (check logs for detailed output)',
    };
  } catch (error) {
    logger.error('='.repeat(70));
    logger.error('SOUND PLAYBACK ERROR (BEFORE EXECUTION)');
    logger.error('='.repeat(70));
    logger.error(`Module: ${moduleName}`);
    logger.error(`File: ${soundFile}`);
    logger.error(`Error: ${error.message}`);
    logger.error(`Stack trace:\n${error.stack}`);
    logger.error('='.repeat(70));
    throw error;
  }
}

module.exports = {
  listSoundModules,
  getModuleSounds,
  playSound,
};
