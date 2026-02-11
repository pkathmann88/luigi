# Luigi Management API

**Secure Node.js API server for Luigi system management and Raspberry Pi control**

A RESTful HTTPS API that provides centralized management of Luigi modules, system operations, log viewing, and configuration management without requiring SSH access.

**Includes a modern web-based frontend** for easy management through your browser.

## Features

- **Web Frontend** - Modern, responsive UI for managing Luigi system from any device
- **Module Management** - Start, stop, restart, and monitor Luigi modules
- **System Control** - Reboot, shutdown, update, and clean up the system
- **Log Viewing** - Access and search logs from all modules
- **Configuration Management** - View and update module configurations
- **System Monitoring** - Real-time system metrics (CPU, memory, disk, temperature)
- **Secure Authentication** - HTTP Basic Authentication over HTTPS/TLS
- **Comprehensive Security** - Rate limiting, input validation, audit logging, IP filtering
- **Local Network Optimized** - Designed for secure local network deployment

## Prerequisites

- Raspberry Pi Zero W (or compatible)
- Node.js >= 16.0.0
- npm >= 8.0.0
- Raspberry Pi OS (Debian-based)

## Installation

### Quick Install

```bash
# From repository root
cd system/management-api
sudo ./setup.sh install
```

The installer will:
1. Check prerequisites and install Node.js if needed
2. Install backend Node.js dependencies
3. Build the web frontend (React/TypeScript)
   - If a previous build exists, you'll be prompted whether to rebuild
   - Rebuilding can take 5-15 minutes on Raspberry Pi Zero W
4. Generate TLS certificates
5. Configure the service
6. Start the API server

**IMPORTANT:** After installation, edit the configuration file and set a strong password:

```bash
sudo nano /etc/luigi/system/management-api/.env
```

Change `AUTH_PASSWORD` to a secure password (minimum 12 characters).

### Build Only (Development)

To build the frontend and backend without full installation:

```bash
cd system/management-api
sudo ./setup.sh build
```

The build command:
- Installs Node.js dependencies (backend and frontend)
- Builds the React/TypeScript frontend
- Skips: configuration deployment, certificates, service installation

This is useful for:
- Development workflows
- CI/CD pipelines
- Pre-building before deployment
- Testing builds without affecting running services

After building, you can run the full `install` command to complete the deployment.

### Manual Installation

```bash
# 1. Install Node.js (if not already installed)
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs npm openssl curl

# 2. Copy application files
# Note: $USER and $HOME are environment variables that expand to your username and home directory
sudo mkdir -p $HOME/luigi/system/management-api
sudo cp -r ./* $HOME/luigi/system/management-api/
sudo chown -R $USER:$USER $HOME/luigi/system/management-api

# 3. Install backend dependencies
cd $HOME/luigi/system/management-api
npm install --production

# 4. Build frontend
cd $HOME/luigi/system/management-api/frontend
npm install
npm run build

# 5. Create configuration
sudo mkdir -p /etc/luigi/system/management-api
sudo cp .env.example /etc/luigi/system/management-api/.env
sudo chmod 600 /etc/luigi/system/management-api/.env
sudo nano /etc/luigi/system/management-api/.env  # Set AUTH_PASSWORD

# 6. Generate TLS certificates
bash scripts/generate-certs.sh

# 7. Install and start service
# Edit management-api.service to set correct User, Group, and WorkingDirectory
sudo cp management-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable management-api
sudo systemctl start management-api
```

**Note:** The automated installer (`./setup.sh install`) handles user detection and path configuration automatically.

## Web Frontend

The management API includes a modern, responsive web frontend for easy system management.

### Features

- **Login Page** - Secure login with static credentials
- **Dashboard** - Real-time system monitoring (CPU, memory, disk, uptime)
- **Module Management** - Start, stop, restart modules with a click
- **Log Viewer** - Browse and view logs from all modules
- **Configuration Editor** - Edit module configurations directly
- **Responsive Design** - Works on desktop, tablet, and mobile

### Accessing the Frontend

After installation, access the web interface at:

```
https://<raspberry-pi-ip>:8443/
```

Default credentials:
- Username: `admin`
- Password: `changeme123`

**Important:** Change the default password in `/etc/luigi/system/management-api/.env`

### Building the Frontend

The frontend is automatically built during installation by `setup.sh install`. 

If you need to rebuild it manually:

```bash
cd frontend
npm install
npm run build
```

The built files are automatically served by the backend at the root URL.

For frontend development, see [frontend/README.md](frontend/README.md).

## Configuration

Configuration file: `/etc/luigi/system/management-api/.env`

### Required Settings

```bash
# Authentication (MUST CHANGE!)
AUTH_USERNAME=admin
AUTH_PASSWORD=your-secure-password-here  # Minimum 12 characters

# HTTPS (Required for security)
USE_HTTPS=true
TLS_CERT_PATH=$HOME/certs/server.crt
TLS_KEY_PATH=$HOME/certs/server.key
```

**Note:** Default paths use `$HOME/certs/`. The installer creates certificates at this location for the user running the script.

### Optional Settings

```bash
# Server
PORT=8443                    # HTTPS port
HOST=0.0.0.0                 # Bind address

# IP Whitelist (comma-separated, empty = allow all local network)
ALLOWED_IPS=192.168.1.100,192.168.1.101

# Rate Limiting
RATE_LIMIT_WINDOW_MINUTES=15
RATE_LIMIT_MAX_REQUESTS=100

# Logging
LOG_LEVEL=INFO              # DEBUG, INFO, WARN, ERROR
LOG_FILE=/var/log/management-api.log
AUDIT_LOG_FILE=/var/log/luigi/audit.log
```

## API Reference

### Base URL

```
https://<raspberry-pi-ip>:8443
```

### Authentication

All endpoints (except `/health`) require HTTP Basic Authentication:

```bash
curl -u admin:password https://raspberry-pi:8443/api/modules
```

### Endpoints

#### Health Check (Public)

```
GET /health
```

Returns API health status. No authentication required.

**Example:**
```bash
curl -k https://192.168.1.10:8443/health
```

**Response:**
```json
{
  "success": true,
  "status": "ok",
  "timestamp": "2026-02-10T16:05:49.604Z",
  "uptime": 1234.56,
  "version": "1.0.0"
}
```

#### Module Management

**List all modules:**
```
GET /api/modules
```

**Get module status:**
```
GET /api/modules/:name
```

**Start module:**
```
POST /api/modules/:name/start
```

**Stop module:**
```
POST /api/modules/:name/stop
```

**Restart module:**
```
POST /api/modules/:name/restart
```

**Example:**
```bash
# List all modules
curl -k -u admin:password https://192.168.1.10:8443/api/modules

# Start mario module
curl -k -u admin:password -X POST https://192.168.1.10:8443/api/modules/mario/start

# Get mario status
curl -k -u admin:password https://192.168.1.10:8443/api/modules/mario
```

#### System Operations

**Get system metrics:**
```
GET /api/system/status
```

**Reboot system:**
```
POST /api/system/reboot
Body: { "confirm": true }
```

**Shutdown system:**
```
POST /api/system/shutdown
Body: { "confirm": true }
```

**Update system packages:**
```
POST /api/system/update
```

**Clean up system:**
```
POST /api/system/cleanup
```

**Example:**
```bash
# Get system status
curl -k -u admin:password https://192.168.1.10:8443/api/system/status

# Reboot (requires confirmation)
curl -k -u admin:password -X POST https://192.168.1.10:8443/api/system/reboot \
  -H "Content-Type: application/json" \
  -d '{"confirm":true}'
```

#### Log Viewing

**List log files:**
```
GET /api/logs
```

**Get module logs:**
```
GET /api/logs/:module?lines=100&search=error
```

**Tail module logs:**
```
GET /api/logs/:module/tail?lines=50
```

**Example:**
```bash
# List all log files
curl -k -u admin:password https://192.168.1.10:8443/api/logs

# Get last 100 lines of mario logs
curl -k -u admin:password https://192.168.1.10:8443/api/logs/mario?lines=100

# Search for errors in logs
curl -k -u admin:password https://192.168.1.10:8443/api/logs/mario?search=error
```

#### Configuration Management

**List all configs:**
```
GET /api/config
```

**Read config:**
```
GET /api/config/:module
```

**Update config:**
```
PUT /api/config/:module
Body: { "SETTING_NAME": "new_value" }
```

**Example:**
```bash
# List all configuration files
curl -k -u admin:password https://192.168.1.10:8443/api/config

# Read mario configuration
curl -k -u admin:password https://192.168.1.10:8443/api/config/motion-detection/mario/mario.conf

# Update configuration (creates backup automatically)
curl -k -u admin:password -X PUT https://192.168.1.10:8443/api/config/motion-detection/mario/mario.conf \
  -H "Content-Type: application/json" \
  -d '{"COOLDOWN_SECONDS":"3600"}'
```

#### Monitoring

**Get system metrics:**
```
GET /api/monitoring/metrics
```

Returns real-time system metrics including CPU, memory, disk, and temperature.

## Service Management

```bash
# Start service
sudo systemctl start management-api

# Stop service
sudo systemctl stop management-api

# Restart service
sudo systemctl restart management-api

# Check status
sudo systemctl status management-api

# Enable auto-start on boot
sudo systemctl enable management-api

# View logs
sudo journalctl -u management-api -f

# View last 100 log lines
sudo journalctl -u management-api -n 100
```

## Security

### Authentication

- HTTP Basic Authentication required for all API endpoints (except `/health`)
- Credentials configured in `/etc/luigi/system/management-api/.env`
- Use strong passwords (minimum 12 characters)

### HTTPS/TLS

- **HTTPS is required** - HTTP Basic Auth sends credentials in base64 (not encrypted)
- Self-signed certificates generated automatically during installation
- Custom certificates can be used by replacing files in `$HOME/certs/` (default location)

### Rate Limiting

- Global: 100 requests per 15 minutes per IP
- Authentication attempts: 5 per 15 minutes per IP
- Operations: 20 per minute per IP

### IP Filtering

- By default, only local network IPs are allowed (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
- Configure `ALLOWED_IPS` in `.env` for stricter whitelisting

### Audit Logging

All security events are logged to `/var/log/luigi/audit.log`:
- Authentication attempts (success/failure)
- Module operations
- System commands
- Configuration changes
- Security violations

## Troubleshooting

### Service won't start

```bash
# Check service status
sudo systemctl status management-api

# View detailed logs
sudo journalctl -u management-api -n 100

# Check configuration
cat /etc/luigi/system/management-api/.env

# Verify TLS certificates exist
ls -la $HOME/certs/
```

### Certificate errors

```bash
# Regenerate certificates
bash $HOME/luigi/system/management-api/scripts/generate-certs.sh

# Restart service
sudo systemctl restart management-api
```

### Authentication fails

```bash
# Verify credentials in config
sudo cat /etc/luigi/system/management-api/.env | grep AUTH_

# Check audit log for failed attempts
sudo tail -50 /var/log/luigi/audit.log | grep authentication
```

### Port already in use

```bash
# Check what's using port 8443
sudo lsof -i :8443

# Change port in configuration
sudo nano /etc/luigi/system/management-api/.env
# Update PORT=8444

# Restart service
sudo systemctl restart management-api
```

### API not responding

```bash
# Check if service is running
sudo systemctl is-active management-api

# Check if port is accessible
curl -k https://localhost:8443/health

# Check firewall rules
sudo ufw status

# Allow port through firewall
sudo ufw allow 8443/tcp
```

## Development

### Running Locally (Development Mode)

```bash
# Set development environment
export NODE_ENV=development
export PORT=8443
export USE_HTTPS=false  # Use HTTP for dev (HTTPS requires certs)

# Run server
node server.js
```

### Testing

```bash
# Validate syntax
bash scripts/validate-syntax.sh

# Test API endpoints
bash scripts/test-api.sh

# Manual testing with curl
curl -k -u admin:password https://localhost:8443/health
```

## Performance Considerations

The API is optimized for Raspberry Pi Zero W constraints:

- **Memory Limit:** 200MB (enforced by systemd)
- **CPU Limit:** 80% of single core
- **Connection Limit:** 50 concurrent connections
- **Request Timeout:** 30 seconds
- **Log Rotation:** 10MB per log file, 5 backups

## Architecture

```
server.js (Entry point)
    ↓
src/app.js (Express setup)
    ↓
Middleware Stack:
  - Security headers (Helmet)
  - CORS
  - Request logging (Morgan → Winston)
  - Security monitoring
  - IP filtering (local network)
  - Rate limiting
  - Authentication (HTTP Basic)
  - Input validation
    ↓
Routes:
  /health → Health Controller
  /api/modules → Modules Controller → Module Service
  /api/system → System Controller → System Service
  /api/logs → Logs Controller → Log Service
  /api/config → Config Controller → Config Service
  /api/monitoring → Monitoring Controller
    ↓
Services (Business Logic):
  - moduleService: systemctl operations
  - systemService: system metrics, operations
  - logService: log file access
  - configService: config file management
    ↓
Utilities:
  - commandExecutor: safe subprocess execution
  - logger: Winston logging
  - auditLogger: security event logging
    ↓
Security:
  - commandValidator: whitelist validation
  - pathValidator: traversal prevention
```

## Troubleshooting

### "Illegal instruction" Error During Frontend Build

**Problem:** Installation fails with "Illegal instruction" error during `npm run build` in the frontend step.

**Cause:** This occurs on Raspberry Pi Zero W (ARMv6 architecture) when using build tools with native binaries compiled for newer ARM architectures.

**Solution:** The frontend build configuration automatically detects ARMv6 and uses appropriate tools:
- **ARMv6 (Pi Zero W):** Uses Terser (pure JavaScript) for minification - slower but compatible
- **Other architectures:** Uses esbuild (native binaries) for minification - faster

The detection is automatic. No manual configuration needed.

**Note:** If you still encounter this issue, verify you're using the latest version of the frontend configuration (`vite.config.ts` and `package.json`).

### Frontend Build Takes Long Time

**Expected:** Frontend build on Raspberry Pi Zero W can take 5-15 minutes due to limited CPU resources. This is normal. The build automatically uses pure JavaScript tools (Terser) on ARMv6 for compatibility, which are slower than native alternatives.

On more modern systems (ARMv7, ARMv8, x86_64), the build uses faster esbuild and completes in 1-3 minutes.

## Dependencies

### Runtime
- express: Web framework
- helmet: Security headers
- winston: Logging
- express-validator: Input validation
- express-rate-limit: Rate limiting
- dotenv: Environment configuration

### System
- Node.js >= 16.0.0
- OpenSSL (for certificates)
- systemctl (for module management)

## Files

```
system/management-api/
├── server.js                 # Entry point
├── package.json              # Dependencies
├── setup.sh                  # Installation script
├── management-api.service    # systemd service
├── .env.example              # Configuration template
├── config/
│   └── index.js              # Config loader
├── src/
│   ├── app.js                # Express app
│   ├── routes/               # API routes
│   ├── controllers/          # Request handlers
│   ├── services/             # Business logic
│   ├── middleware/           # Security, auth, validation
│   ├── utils/                # Logging, command execution
│   └── security/             # Validators, audit logging
└── scripts/
    ├── generate-certs.sh     # Certificate generation
    ├── test-api.sh           # API testing
    └── validate-syntax.sh    # Syntax validation
```

## License

MIT

## Support

For issues, questions, or contributions, see the main Luigi repository:
https://github.com/pkathmann88/luigi

## Security Notice

This API is designed for local network deployment. Do not expose directly to the internet without additional security measures (VPN, reverse proxy with additional authentication, etc.).

Always use HTTPS and strong passwords. Regularly review audit logs for suspicious activity.
