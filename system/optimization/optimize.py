#!/usr/bin/python3
################################################################################
# System Optimization Script
#
# This script optimizes the Raspberry Pi Zero W for performance by:
# - Disabling unnecessary systemd services
# - Configuring boot parameters
# - Blacklisting unused kernel modules
# - Removing unnecessary packages
#
# Configuration: /etc/luigi/system/optimization/optimize.conf
#
# Author: Luigi Project
# License: MIT
################################################################################

import os
import sys
import subprocess
import logging
import configparser
import re
from pathlib import Path

class Config:
    """Configuration management for system optimization"""
    
    DEFAULT_CONFIG = {
        'Services': {
            'disable_services': 'bluetooth,hciuart,ModemManager,triggerhappy,console-setup',
            'mask_services': 'apt-daily-upgrade.timer,apt-daily.timer'
        },
        'Boot': {
            'disable_i2c': 'no',
            'disable_i2s': 'yes',
            'disable_spi': 'no',
            'disable_audio': 'no',
            'disable_camera': 'yes',
            'disable_wifi': 'no',
            'disable_bluetooth': 'no',
            'gpu_mem': '16'
        },
        'Kernel': {
            'blacklist_modules': ''
        },
        'Packages': {
            'remove_packages': ''
        },
        'Logging': {
            'log_file': '/var/log/system-optimization.log',
            'log_level': 'INFO'
        }
    }
    
    def __init__(self, config_path='/etc/luigi/system/optimization/optimize.conf'):
        self.config_path = config_path
        self.config = configparser.ConfigParser()
        
        # Load defaults
        self.config.read_dict(self.DEFAULT_CONFIG)
        
        # Try to load config file
        if os.path.exists(config_path):
            try:
                self.config.read(config_path)
            except Exception as e:
                print(f"Warning: Could not read config file {config_path}: {e}")
                print("Using default configuration")
        else:
            print(f"Info: Config file {config_path} not found, using defaults")
    
    def get(self, section, option):
        """Get configuration value"""
        return self.config.get(section, option)
    
    def get_list(self, section, option):
        """Get configuration value as a list (comma-separated)"""
        value = self.get(section, option).strip()
        if not value:
            return []
        return [item.strip() for item in value.split(',') if item.strip()]
    
    def get_bool(self, section, option):
        """Get configuration value as boolean"""
        value = self.get(section, option).lower()
        return value in ('yes', 'true', '1', 'on')


class SystemOptimizer:
    """Main system optimization class"""
    
    def __init__(self, config, dry_run=False):
        self.config = config
        self.dry_run = dry_run
        self.logger = None
        self._setup_logging()
    
    def _setup_logging(self):
        """Configure logging"""
        log_file = self.config.get('Logging', 'log_file')
        log_level = self.config.get('Logging', 'log_level')
        
        # Create log directory if it doesn't exist
        log_dir = os.path.dirname(log_file)
        if log_dir and not os.path.exists(log_dir):
            try:
                os.makedirs(log_dir, mode=0o755)
            except Exception as e:
                print(f"Warning: Could not create log directory {log_dir}: {e}")
                log_file = '/tmp/system-optimization.log'
        
        # Configure logging
        self.logger = logging.getLogger('SystemOptimizer')
        self.logger.setLevel(getattr(logging, log_level, logging.INFO))
        
        # File handler
        try:
            handler = logging.FileHandler(log_file)
            handler.setFormatter(logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            ))
            self.logger.addHandler(handler)
        except Exception as e:
            print(f"Warning: Could not set up file logging: {e}")
        
        # Console handler
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(logging.Formatter(
            '%(levelname)s: %(message)s'
        ))
        self.logger.addHandler(console_handler)
    
    def run_command(self, cmd, check=True):
        """Run a system command"""
        if self.dry_run:
            self.logger.info(f"[DRY RUN] Would execute: {' '.join(cmd)}")
            return True
        
        try:
            result = subprocess.run(
                cmd,
                check=check,
                capture_output=True,
                text=True,
                timeout=30
            )
            if result.stdout:
                self.logger.debug(f"Command output: {result.stdout.strip()}")
            return True
        except subprocess.CalledProcessError as e:
            self.logger.error(f"Command failed: {' '.join(cmd)}")
            self.logger.error(f"Error: {e.stderr}")
            return False
        except subprocess.TimeoutExpired:
            self.logger.error(f"Command timed out: {' '.join(cmd)}")
            return False
        except Exception as e:
            self.logger.error(f"Unexpected error running command: {e}")
            return False
    
    def service_exists(self, service_name):
        """Check if a systemd service exists"""
        try:
            result = subprocess.run(
                ['systemctl', 'list-unit-files', service_name],
                capture_output=True,
                text=True,
                timeout=10
            )
            return service_name in result.stdout
        except Exception:
            return False
    
    def disable_services(self):
        """Disable unnecessary systemd services"""
        self.logger.info("=== Disabling Services ===")
        
        disable_list = self.config.get_list('Services', 'disable_services')
        mask_list = self.config.get_list('Services', 'mask_services')
        
        success_count = 0
        fail_count = 0
        
        # Disable services
        for service in disable_list:
            if not service:
                continue
            
            # Check if service exists before trying to disable
            if not self.service_exists(service):
                self.logger.info(f"Service {service} not found, skipping")
                continue
            
            self.logger.info(f"Disabling service: {service}")
            if self.run_command(['systemctl', 'disable', '--now', service], check=False):
                success_count += 1
            else:
                fail_count += 1
        
        # Mask services
        for service in mask_list:
            if not service:
                continue
            
            self.logger.info(f"Masking service: {service}")
            if self.run_command(['systemctl', 'mask', service], check=False):
                success_count += 1
            else:
                fail_count += 1
        
        self.logger.info(f"Services: {success_count} succeeded, {fail_count} failed")
        return fail_count == 0
    
    def optimize_boot_config(self):
        """Optimize boot configuration in /boot/firmware/config.txt"""
        self.logger.info("=== Optimizing Boot Configuration ===")
        
        config_paths = [
            '/boot/firmware/config.txt',
            '/boot/config.txt'
        ]
        
        config_path = None
        for path in config_paths:
            if os.path.exists(path):
                config_path = path
                break
        
        if not config_path:
            self.logger.warning("Boot config file not found, skipping boot optimization")
            return False
        
        self.logger.info(f"Using boot config: {config_path}")
        
        if self.dry_run:
            self.logger.info("[DRY RUN] Would modify boot configuration")
            return True
        
        # Read existing config
        try:
            with open(config_path, 'r') as f:
                lines = f.readlines()
        except Exception as e:
            self.logger.error(f"Could not read boot config: {e}")
            return False
        
        # Create backup
        backup_path = f"{config_path}.bak"
        try:
            with open(backup_path, 'w') as f:
                f.writelines(lines)
            self.logger.info(f"Created backup: {backup_path}")
        except Exception as e:
            self.logger.error(f"Could not create backup: {e}")
            return False
        
        # Prepare optimizations
        optimizations = []
        
        if self.config.get_bool('Boot', 'disable_i2c'):
            optimizations.append('dtparam=i2c_arm=off')
        if self.config.get_bool('Boot', 'disable_i2s'):
            optimizations.append('dtparam=i2s=off')
        if self.config.get_bool('Boot', 'disable_spi'):
            optimizations.append('dtparam=spi=off')
        if self.config.get_bool('Boot', 'disable_audio'):
            optimizations.append('dtparam=audio=off')
        if self.config.get_bool('Boot', 'disable_camera'):
            optimizations.append('camera_auto_detect=0')
        if self.config.get_bool('Boot', 'disable_wifi'):
            optimizations.append('dtoverlay=disable-wifi')
        if self.config.get_bool('Boot', 'disable_bluetooth'):
            optimizations.append('dtoverlay=disable-bt')
        
        gpu_mem = self.config.get('Boot', 'gpu_mem')
        if gpu_mem:
            optimizations.append(f'gpu_mem={gpu_mem}')
        
        if not optimizations:
            self.logger.info("No boot optimizations configured")
            return True
        
        # Add optimization section to config
        new_lines = lines.copy()
        
        # Check if our section already exists
        section_marker = '# Luigi System Optimization'
        has_section = any(section_marker in line for line in lines)
        
        if has_section:
            self.logger.info("Optimization section already exists, updating")
            # Remove old section
            new_lines = []
            skip = False
            optimization_prefixes = ('dtparam', 'dtoverlay', 'gpu_mem', 'camera', 'display_auto_detect')
            
            for line in lines:
                if section_marker in line:
                    skip = True
                elif skip and line.strip():
                    # Check if this line is NOT an optimization line
                    if not line.startswith('#') and not line.startswith(optimization_prefixes):
                        skip = False
                
                if not skip:
                    new_lines.append(line)
        
        # Add new section
        new_lines.append('\n')
        new_lines.append(f'{section_marker}\n')
        for opt in optimizations:
            new_lines.append(f'{opt}\n')
        
        # Write updated config
        try:
            with open(config_path, 'w') as f:
                f.writelines(new_lines)
            self.logger.info(f"Updated boot config with {len(optimizations)} optimizations")
            self.logger.info("Reboot required for boot config changes to take effect")
            return True
        except Exception as e:
            self.logger.error(f"Could not write boot config: {e}")
            # Restore from backup
            try:
                with open(backup_path, 'r') as f:
                    backup_lines = f.readlines()
                with open(config_path, 'w') as f:
                    f.writelines(backup_lines)
                self.logger.info("Restored from backup")
            except Exception as e2:
                self.logger.error(f"Could not restore from backup: {e2}")
            return False
    
    def blacklist_modules(self):
        """Blacklist kernel modules"""
        self.logger.info("=== Blacklisting Kernel Modules ===")
        
        modules = self.config.get_list('Kernel', 'blacklist_modules')
        
        if not modules:
            self.logger.info("No modules configured for blacklisting")
            return True
        
        blacklist_file = '/etc/modprobe.d/luigi-blacklist.conf'
        
        if self.dry_run:
            self.logger.info(f"[DRY RUN] Would blacklist modules: {', '.join(modules)}")
            return True
        
        try:
            with open(blacklist_file, 'w') as f:
                f.write("# Luigi System Optimization - Blacklisted Kernel Modules\n")
                f.write("# This file is managed by the Luigi system optimization module\n\n")
                for module in modules:
                    f.write(f"blacklist {module}\n")
            
            self.logger.info(f"Blacklisted {len(modules)} kernel modules in {blacklist_file}")
            self.logger.info("Reboot required for module blacklist to take effect")
            return True
        except Exception as e:
            self.logger.error(f"Could not write blacklist file: {e}")
            return False
    
    def remove_packages(self):
        """Remove unnecessary packages"""
        self.logger.info("=== Removing Unnecessary Packages ===")
        
        packages = self.config.get_list('Packages', 'remove_packages')
        
        if not packages:
            self.logger.info("No packages configured for removal")
            return True
        
        self.logger.info(f"Removing packages: {', '.join(packages)}")
        
        # Build apt-get command
        cmd = ['apt-get', 'remove', '--purge', '-y'] + packages
        
        if not self.run_command(cmd, check=False):
            self.logger.error("Package removal failed")
            return False
        
        # Run autoremove
        self.logger.info("Running autoremove to clean up dependencies")
        if not self.run_command(['apt-get', 'autoremove', '-y'], check=False):
            self.logger.warning("Autoremove failed, but continuing")
        
        return True
    
    def optimize(self):
        """Run all optimizations"""
        self.logger.info("Starting system optimization")
        
        results = {
            'services': self.disable_services(),
            'boot_config': self.optimize_boot_config(),
            'modules': self.blacklist_modules(),
            'packages': self.remove_packages()
        }
        
        self.logger.info("\n=== Optimization Summary ===")
        for name, success in results.items():
            status = "SUCCESS" if success else "FAILED"
            self.logger.info(f"{name}: {status}")
        
        if all(results.values()):
            self.logger.info("\nAll optimizations completed successfully!")
            self.logger.info("Note: A reboot is recommended for all changes to take effect")
            return 0
        else:
            self.logger.warning("\nSome optimizations failed. Check logs for details.")
            return 1


def print_usage():
    """Print usage information"""
    print("Usage: optimize.py [--dry-run] [--config CONFIG_FILE]")
    print("")
    print("Options:")
    print("  --dry-run          Show what would be done without making changes")
    print("  --config FILE      Use alternative config file")
    print("  --help             Show this help message")


def main():
    """Main entry point"""
    
    # Check if running as root
    if os.geteuid() != 0:
        print("ERROR: This script must be run as root")
        print("Please run: sudo optimize.py")
        return 1
    
    # Parse arguments
    dry_run = False
    config_path = '/etc/luigi/system/optimization/optimize.conf'
    
    for arg in sys.argv[1:]:
        if arg == '--dry-run':
            dry_run = True
        elif arg == '--help' or arg == '-h':
            print_usage()
            return 0
        elif arg == '--config':
            # Next argument should be the config file
            idx = sys.argv.index(arg)
            if idx + 1 < len(sys.argv):
                config_path = sys.argv[idx + 1]
        elif arg.startswith('--config='):
            config_path = arg.split('=', 1)[1]
    
    # Load configuration
    config = Config(config_path)
    
    # Create optimizer and run
    optimizer = SystemOptimizer(config, dry_run=dry_run)
    return optimizer.optimize()


if __name__ == '__main__':
    sys.exit(main())
