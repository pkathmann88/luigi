# Management-API Service Restart Fix - Summary

## Problem Description

The management-api systemd service was experiencing continuous restart loops. The service would start, run for a brief moment, then exit and restart again. When running the service command manually, it worked correctly.

## Root Causes Identified

### 1. Relative Path in ExecStart (Minor Issue)
- **Issue**: Service file used `ExecStart=/usr/bin/node server.js` (relative path)
- **Impact**: While systemd sets WorkingDirectory, using relative paths is fragile
- **Fix**: Changed to absolute path: `ExecStart=/usr/bin/node ${APP_DIR}/server.js`

### 2. Hardcoded Installation Paths (Major Issue)
- **Issue**: Service file template used hardcoded `/home/pi/luigi/system/management-api`
- **Impact**: Service wouldn't work if repository was cloned to a different location
- **Fix**: 
  - Made APP_DIR dynamic using actual SCRIPT_DIR location
  - Added logic to support in-place installation (when APP_DIR equals SCRIPT_DIR)
  - Updated setup.sh to replace ALL paths in service file during installation

### 3. Missing TLS Certificate Handling (Root Cause of Restarts)
- **Issue**: Application exits immediately if TLS certificates don't exist when USE_HTTPS=true
- **Impact**: Service starts successfully but exits before listening, causing restart loop
- **Fix**:
  - Created pre-start validation script (`scripts/pre-start-check.sh`)
  - Added ExecStartPre directive to run validation before Node.js starts
  - Script checks certificates exist and are readable
  - Provides clear error messages with resolution steps

### 4. Insufficient Startup Logging (Debugging Issue)
- **Issue**: Minimal console output during startup made debugging difficult
- **Impact**: Hard to diagnose why service was failing when viewing journalctl logs
- **Fix**:
  - Added comprehensive logging to config loading phase
  - Enhanced server startup with step-by-step output
  - Added clear success (✓) and failure (✗) indicators
  - Shows exact file paths, configuration values, and error details

## Changes Made

### 1. `management-api.service` (Service File Template)
- Updated ExecStart to use absolute path placeholder
- Added ExecStartPre for pre-start validation
- Paths get replaced by setup.sh during installation

### 2. `setup.sh` (Installation Script)
- Changed APP_DIR from hardcoded path to dynamic SCRIPT_DIR
- Added conditional file copying (skip if APP_DIR equals SCRIPT_DIR)
- Enhanced sed replacements to update ALL paths in service file:
  - User and Group
  - WorkingDirectory
  - ExecStart
  - ExecStartPre
- Always reads template from SCRIPT_DIR, writes to system location

### 3. `scripts/pre-start-check.sh` (New)
- Loads configuration from .env file
- Validates TLS certificates when USE_HTTPS=true
- Checks file existence and readability
- Validates log directory is writable
- Provides actionable error messages
- Exits with error code if validation fails

### 4. `server.js` (Server Entry Point)
- Added detailed startup phase logging
- Configuration summary output
- TLS certificate checking with step-by-step validation
- Clear success/failure messages
- Process information (PID, Node version, working directory)
- Enhanced error handling with stack traces

### 5. `config/index.js` (Configuration Module)
- Added configuration loading output
- Shows all key configuration values
- Reports validation status clearly

### 6. `src/app.js` (Express Application)
- Added module loading indicators
- Shows initialization progress
- Confirms middleware registration

### 7. Documentation
- `docs/TROUBLESHOOTING_SERVICE_RESTART.md` - Complete troubleshooting guide
- `docs/STARTUP_OUTPUT_EXAMPLE.sh` - Shows what logs look like

## How It Works Now

### Installation Flow
1. User runs `sudo ./setup.sh install`
2. Setup script determines actual installation directory (SCRIPT_DIR)
3. Sets APP_DIR = SCRIPT_DIR (running in-place)
4. Builds application (npm install, frontend build)
5. Creates config directories, generates certificates if needed
6. Generates systemd service file with correct paths using sed
7. Installs and starts service

### Service Startup Flow
1. systemd loads service file from `/etc/systemd/system/management-api.service`
2. Creates log directory: `/bin/mkdir -p /var/log/luigi`
3. Runs pre-start validation: `${APP_DIR}/scripts/pre-start-check.sh`
   - Loads .env configuration
   - Checks TLS certificates if HTTPS enabled
   - Validates log directory writable
   - Exits with error if any check fails
4. If validation passes, starts Node.js: `/usr/bin/node ${APP_DIR}/server.js`
5. Node.js application starts:
   - Loads configuration (with detailed output)
   - Loads Express modules (with progress indicators)
   - Checks TLS certificates again (with step-by-step validation)
   - Creates HTTP/HTTPS server
   - Starts listening on configured port
   - Logs success message

### Monitoring
```bash
# View real-time logs
sudo journalctl -u management-api -f

# View recent logs
sudo journalctl -u management-api -n 50

# Check service status
sudo systemctl status management-api
```

## Benefits of These Changes

### 1. Portability
- Service works regardless of where repository is cloned
- No hardcoded paths to specific users or directories
- Supports different installation layouts

### 2. Early Error Detection
- Pre-start validation catches configuration issues before Node.js starts
- Prevents restart loops due to missing certificates
- Clear error messages guide users to solutions

### 3. Better Debugging
- Comprehensive startup logs show exactly what's happening
- Easy to identify which phase failed
- Visual indicators make logs easier to read
- Exact file paths and values shown in output

### 4. Maintainability
- Single source of truth (SCRIPT_DIR) for installation location
- Template-based service file with dynamic path replacement
- Consistent error handling and logging patterns

## Testing Recommendations

### Test Case 1: Normal Installation
1. Clone repository to non-standard location (not /home/pi/luigi)
2. Run setup.sh install
3. Verify service starts successfully
4. Check logs show proper paths

### Test Case 2: Missing Certificates
1. Delete certificate files from ~/certs/
2. Try to start service
3. Verify pre-start validation fails with clear error
4. Generate certificates and restart
5. Verify service starts successfully

### Test Case 3: In-Place Operation
1. Install service with setup.sh
2. Make code changes in the repository
3. Restart service
4. Verify changes are reflected (no file copy needed)

### Test Case 4: Log Analysis
1. Start service
2. Review journalctl output
3. Verify all startup phases are visible
4. Check success indicators are present

## Migration for Existing Installations

If you have an existing management-api installation:

1. Stop the service:
   ```bash
   sudo systemctl stop management-api
   ```

2. Pull the latest changes:
   ```bash
   cd ~/luigi
   git pull
   ```

3. Re-run the setup:
   ```bash
   cd system/management-api
   sudo ./setup.sh install
   ```

4. Check the service starts correctly:
   ```bash
   sudo systemctl status management-api
   sudo journalctl -u management-api -n 50
   ```

## Future Enhancements

Consider these improvements for future work:

1. **Certificate Auto-Renewal**: Automatically regenerate certificates before expiry
2. **Health Monitoring**: Add startup health check endpoint
3. **Configuration Validation**: Validate .env file format and values during pre-start
4. **Rollback Support**: Keep previous version of service file for quick rollback
5. **Installation Log**: Keep detailed log of installation process for debugging

## Related Documentation

- `docs/TROUBLESHOOTING_SERVICE_RESTART.md` - Comprehensive troubleshooting guide
- `docs/STARTUP_OUTPUT_EXAMPLE.sh` - Example startup output
- `README.md` - Main documentation
- `docs/API.md` - API documentation

## Lessons Learned

1. **Always use absolute paths in systemd service files**
2. **Implement pre-start validation for critical dependencies**
3. **Add comprehensive logging to aid debugging**
4. **Avoid hardcoded paths - use dynamic detection**
5. **Test services in non-standard installation locations**
6. **Provide clear error messages with resolution steps**
