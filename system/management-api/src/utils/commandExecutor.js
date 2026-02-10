/**
 * Command Executor Utility
 * Safe subprocess execution with validation and error handling
 */

const { spawn } = require('child_process');
const logger = require('./logger');
const { validateFullCommand } = require('../security/commandValidator');

/**
 * Execute command safely with timeout and validation
 * 
 * @param {string} command - Command to execute
 * @param {Array} args - Command arguments
 * @param {Object} options - Execution options
 * @returns {Promise} - Resolves with { success, stdout, stderr, exitCode }
 */
async function executeCommand(command, args = [], options = {}) {
  const {
    timeout = 30000, // 30 second default timeout
    cwd = undefined,
    env = process.env,
  } = options;

  // Validate command
  const validationError = validateFullCommand(command, args);
  if (validationError) {
    logger.error(`Command validation failed: ${validationError}`);
    throw new Error(validationError);
  }

  logger.debug(`Executing command: ${command} ${args.join(' ')}`);

  return new Promise((resolve, reject) => {
    const startTime = Date.now();
    let stdout = '';
    let stderr = '';
    let timedOut = false;

    // Spawn process
    const proc = spawn(command, args, {
      cwd,
      env,
      shell: false, // Never use shell!
    });

    // Set timeout
    const timeoutId = setTimeout(() => {
      timedOut = true;
      proc.kill('SIGTERM');
      
      // Force kill after 5 seconds if still running
      setTimeout(() => {
        if (!proc.killed) {
          proc.kill('SIGKILL');
        }
      }, 5000);
    }, timeout);

    // Collect stdout
    proc.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    // Collect stderr
    proc.stderr.on('data', (data) => {
      stderr += data.toString();
    });

    // Handle errors
    proc.on('error', (error) => {
      clearTimeout(timeoutId);
      logger.error(`Command execution error: ${error.message}`);
      reject(new Error(`Failed to execute command: ${error.message}`));
    });

    // Handle exit
    proc.on('close', (exitCode) => {
      clearTimeout(timeoutId);
      const duration = Date.now() - startTime;

      logger.debug(`Command completed in ${duration}ms with exit code ${exitCode}`);

      if (timedOut) {
        logger.warn(`Command timed out after ${timeout}ms`);
        reject(new Error(`Command timed out after ${timeout}ms`));
        return;
      }

      resolve({
        success: exitCode === 0,
        stdout: stdout.trim(),
        stderr: stderr.trim(),
        exitCode,
        duration,
      });
    });
  });
}

/**
 * Execute command and return stdout (throws on error)
 */
async function executeCommandForOutput(command, args = [], options = {}) {
  const result = await executeCommand(command, args, options);
  
  if (!result.success) {
    throw new Error(result.stderr || `Command failed with exit code ${result.exitCode}`);
  }

  return result.stdout;
}

module.exports = {
  executeCommand,
  executeCommandForOutput,
};
