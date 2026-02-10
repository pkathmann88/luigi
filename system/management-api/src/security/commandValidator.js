/**
 * Command Validator
 * Prevents command injection by validating commands against whitelist
 */

const logger = require('../utils/logger');

// Whitelist of allowed commands
const ALLOWED_COMMANDS = [
  'systemctl',
  'journalctl',
  'apt-get',
  'df',
  'free',
  'uptime',
  'cat',
  'tail',
  'head',
  'grep',
  'reboot',
  'shutdown',
  'vcgencmd',
];

// Whitelist of allowed systemctl subcommands
const ALLOWED_SYSTEMCTL_SUBCOMMANDS = [
  'status',
  'start',
  'stop',
  'restart',
  'enable',
  'disable',
  'is-active',
  'is-enabled',
];

/**
 * Validate command is in whitelist
 */
function validateCommand(command) {
  if (!ALLOWED_COMMANDS.includes(command)) {
    logger.warn(`Command not in whitelist: ${command}`);
    return false;
  }
  return true;
}

/**
 * Validate systemctl subcommand
 */
function validateSystemctlSubcommand(subcommand) {
  if (!ALLOWED_SYSTEMCTL_SUBCOMMANDS.includes(subcommand)) {
    logger.warn(`Systemctl subcommand not in whitelist: ${subcommand}`);
    return false;
  }
  return true;
}

/**
 * Validate full command with arguments
 * Returns error if invalid, null if valid
 */
function validateFullCommand(command, args = []) {
  // Check command is whitelisted
  if (!validateCommand(command)) {
    return `Command '${command}' is not allowed`;
  }

  // Additional validation for systemctl
  if (command === 'systemctl' && args.length > 0) {
    const subcommand = args[0];
    if (!validateSystemctlSubcommand(subcommand)) {
      return `Systemctl subcommand '${subcommand}' is not allowed`;
    }
  }

  // Check for shell metacharacters in arguments
  const dangerousChars = /[;&|`$()<>]/;
  for (const arg of args) {
    if (dangerousChars.test(arg)) {
      logger.warn(`Dangerous characters detected in argument: ${arg}`);
      return 'Invalid characters detected in command arguments';
    }
  }

  return null;
}

module.exports = {
  validateCommand,
  validateSystemctlSubcommand,
  validateFullCommand,
  ALLOWED_COMMANDS,
  ALLOWED_SYSTEMCTL_SUBCOMMANDS,
};
