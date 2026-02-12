# Luigi Management API Documentation

**Version:** 1.0.0  
**Base URL:** `http://<raspberry-pi-ip>:3000`  
**Authentication:** HTTP Basic Authentication

---

## Table of Contents

1. [Authentication](#authentication)
2. [Response Format](#response-format)
3. [Error Handling](#error-handling)
4. [Module Management](#module-management)
5. [Module Registry](#module-registry)
6. [System Operations](#system-operations)
7. [Log Management](#log-management)
8. [Configuration Management](#configuration-management)
9. [Monitoring](#monitoring)

---

## Authentication

All API endpoints (except `/health`) require HTTP Basic Authentication.

**Headers:**
```
Authorization: Basic <base64-encoded-credentials>
```

**Credentials:**
- Username and password are configured during setup
- Default development credentials: `admin` / `changeme123` (change in production!)

**Example:**
```bash
curl -u admin:changeme123 http://localhost:3000/api/modules
```

---

## Response Format

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "count": 5,
  "...": "additional fields"
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error Type",
  "message": "Detailed error message"
}
```

### HTTP Status Codes
- `200 OK` - Request succeeded
- `400 Bad Request` - Invalid input
- `401 Unauthorized` - Authentication failed
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error

---

## Error Handling

### Rate Limiting
- **Module operations:** 20 requests per minute
- **Other endpoints:** Standard rate limiting applies

### Common Error Codes
- `AUTHENTICATION_FAILED` - Invalid credentials
- `VALIDATION_FAILED` - Input validation error
- `MODULE_NOT_FOUND` - Module doesn't exist
- `SERVICE_ERROR` - System service error
- `PERMISSION_DENIED` - Operation not permitted

---

## Module Management

### List All Modules

**GET** `/api/modules`

Returns a list of all Luigi modules found in the system.

**Response:**
```json
{
  "success": true,
  "count": 3,
  "modules": [
    {
      "name": "mario",
      "path": "motion-detection/mario",
      "category": "motion-detection",
      "fullPath": "/home/pi/luigi/motion-detection/mario",
      "metadata": {
        "name": "mario",
        "version": "1.0.0",
        "description": "Mario-themed motion detection module",
        "capabilities": ["service", "hardware", "sensor", "config"]
      },
      "status": "active",
      "pid": 1234,
      "registry": {
        "module_path": "motion-detection/mario",
        "name": "mario",
        "version": "1.0.0",
        "category": "motion-detection",
        "installed_at": "2024-01-15T10:30:00.000Z",
        "updated_at": "2024-01-15T10:30:00.000Z",
        "status": "active",
        "capabilities": ["service", "hardware", "sensor", "config"],
        "dependencies": ["iot/ha-mqtt"],
        "service_name": "mario.service"
      }
    }
  ]
}
```

**Fields:**
- `name` (string) - Module name (directory name)
- `path` (string) - Relative path from modules root
- `category` (string) - Module category
- `fullPath` (string) - Absolute filesystem path
- `metadata` (object|null) - Contents of module.json if exists
- `status` (string) - Service status: `active`, `inactive`, `failed`, `unknown`
- `pid` (number|null) - Process ID if service is running
- `registry` (object|null) - Registry entry if module is installed

---

### Get Module Status

**GET** `/api/modules/:name`

Get detailed status of a specific module.

**Parameters:**
- `name` (path) - Module name (e.g., `mario`)

**Response:**
```json
{
  "success": true,
  "module": "mario",
  "category": "motion-detection",
  "path": "motion-detection/mario",
  "service": {
    "name": "mario.service",
    "active": true,
    "enabled": true,
    "status": "● mario.service - Mario Motion Detection\n   Loaded: loaded (/etc/systemd/system/mario.service; enabled)\n   Active: active (running) since...\n   Main PID: 1234"
  },
  "metadata": {
    "name": "mario",
    "version": "1.0.0",
    "description": "Mario-themed motion detection module"
  }
}
```

---

### Start Module

**POST** `/api/modules/:name/start`

Start a module's systemd service.

**Parameters:**
- `name` (path) - Module name

**Response:**
```json
{
  "success": true,
  "module": "mario",
  "operation": "start",
  "message": "Module started successfully"
}
```

**Error Response:**
```json
{
  "success": false,
  "module": "mario",
  "operation": "start",
  "message": "Failed to start mario.service: Unit not found"
}
```

---

### Stop Module

**POST** `/api/modules/:name/stop`

Stop a module's systemd service.

**Parameters:**
- `name` (path) - Module name

**Response:**
```json
{
  "success": true,
  "module": "mario",
  "operation": "stop",
  "message": "Module stopped successfully"
}
```

---

### Restart Module

**POST** `/api/modules/:name/restart`

Restart a module's systemd service.

**Parameters:**
- `name` (path) - Module name

**Response:**
```json
{
  "success": true,
  "module": "mario",
  "operation": "restart",
  "message": "Module restarted successfully"
}
```

---

## Module Registry

The registry endpoints provide read-only access to the centralized module registry at `/etc/luigi/modules/`. This registry tracks all installed modules with their metadata, version information, dependencies, and installation status.

### List All Registry Entries

**GET** `/api/registry`

Returns all module registry entries with aggregated statistics.

**Response:**
```json
{
  "success": true,
  "count": 5,
  "stats": {
    "total": 5,
    "byStatus": {
      "active": 3,
      "installed": 2
    },
    "byCategory": {
      "motion-detection": 1,
      "iot": 1,
      "system": 3
    },
    "byCapability": {
      "service": 4,
      "api": 1,
      "config": 5,
      "hardware": 1,
      "sensor": 1
    }
  },
  "entries": [
    {
      "module_path": "iot/ha-mqtt",
      "name": "ha-mqtt",
      "version": "1.0.0",
      "category": "iot",
      "description": "Home Assistant MQTT integration for Luigi sensors",
      "installed_at": "2024-01-15T10:00:00.000Z",
      "updated_at": "2024-01-15T10:00:00.000Z",
      "installed_by": "setup.sh",
      "install_method": "manual",
      "status": "active",
      "capabilities": ["cli-tools", "config", "integration"],
      "dependencies": [],
      "apt_packages": ["mosquitto-clients", "jq"],
      "author": "Luigi Project",
      "provides": ["luigi-publish", "luigi-discover", "luigi-mqtt-status"],
      "service_name": "ha-mqtt.service",
      "config_path": "/etc/luigi/iot/ha-mqtt",
      "log_path": "/var/log/luigi/ha-mqtt.log",
      "_registryFile": "iot__ha-mqtt.json"
    }
  ]
}
```

**Fields:**
- `module_path` (string) - Full module path (e.g., "motion-detection/mario")
- `name` (string) - Module name
- `version` (string) - Semantic version
- `category` (string) - Module category
- `description` (string) - Module description
- `installed_at` (string) - ISO 8601 timestamp of installation
- `updated_at` (string) - ISO 8601 timestamp of last update
- `installed_by` (string) - What installed the module ("setup.sh", "management-api", "manual")
- `install_method` (string) - How installed ("manual", "auto", "api", "script")
- `status` (string) - Module status: `active`, `installed`, `failed`, `removed`
- `capabilities` (array) - Module capabilities (see [Capabilities](#capabilities))
- `dependencies` (array) - List of module paths this depends on
- `apt_packages` (array) - Required system packages
- `author` (string) - Module author
- `provides` (array) - Commands/utilities/services provided
- `service_name` (string|null) - Systemd service name
- `config_path` (string|null) - Configuration directory path
- `log_path` (string|null) - Log file path
- `_registryFile` (string) - Registry filename (internal)

#### Capabilities

Standard capability types:
- `service` - Provides a systemd service
- `cli-tools` - Provides command-line tools
- `api` - Provides HTTP API endpoints
- `config` - Has configuration files
- `hardware` - Interacts with GPIO/hardware
- `sensor` - Provides sensor data
- `integration` - Integrates with external systems

---

### Get Specific Registry Entry

**GET** `/api/registry/:modulePath(*)`

Get registry entry for a specific module. Supports multi-segment paths.

**Parameters:**
- `modulePath` (path) - Module path with forward slashes (e.g., `motion-detection/mario`)

**Examples:**
```bash
GET /api/registry/motion-detection/mario
GET /api/registry/iot/ha-mqtt
GET /api/registry/system/management-api
```

**Response:**
```json
{
  "success": true,
  "entry": {
    "module_path": "motion-detection/mario",
    "name": "mario",
    "version": "1.0.0",
    "category": "motion-detection",
    "description": "Mario-themed motion detection module using PIR sensors",
    "installed_at": "2024-01-15T10:30:00.000Z",
    "updated_at": "2024-01-15T10:30:00.000Z",
    "installed_by": "setup.sh",
    "install_method": "manual",
    "status": "active",
    "capabilities": ["service", "hardware", "sensor", "config"],
    "dependencies": ["iot/ha-mqtt"],
    "apt_packages": ["python3-rpi-lgpio", "alsa-utils"],
    "author": "Luigi Project",
    "hardware": {
      "gpio_pins": [23],
      "sensors": ["HC-SR501"]
    },
    "service_name": "mario.service",
    "config_path": "/etc/luigi/motion-detection/mario",
    "log_path": "/var/log/luigi/mario.log",
    "_registryFile": "motion-detection__mario.json"
  }
}
```

**Error Response (404):**
```json
{
  "success": false,
  "error": "Not Found",
  "message": "Module 'motion-detection/mario' not found in registry"
}
```

---

## System Operations

### Get System Status

**GET** `/api/system/status`

Get current system metrics.

**Response:**
```json
{
  "uptime": 86400,
  "cpu": {
    "usage": 15.5,
    "temperature": 45.2
  },
  "memory": {
    "total": 1073741824,
    "used": 536870912,
    "free": 536870912,
    "percent": 50
  },
  "disk": {
    "total": 32212254720,
    "used": 10737418240,
    "free": 21474836480,
    "percent": 33
  },
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

**Fields:**
- `uptime` (number) - System uptime in seconds
- `cpu.usage` (number) - CPU usage percentage (0-100)
- `cpu.temperature` (number) - CPU temperature in Celsius
- `memory.total` (number) - Total memory in bytes
- `memory.used` (number) - Used memory in bytes
- `memory.free` (number) - Free memory in bytes
- `memory.percent` (number) - Memory usage percentage (0-100)
- `disk.total` (number) - Total disk space in bytes
- `disk.used` (number) - Used disk space in bytes
- `disk.free` (number) - Free disk space in bytes
- `disk.percent` (number) - Disk usage percentage (0-100)

---

### Reboot System

**POST** `/api/system/reboot`

Reboot the Raspberry Pi.

**Request Body:**
```json
{
  "confirm": true
}
```

**Response:**
```json
{
  "success": true,
  "message": "System reboot initiated"
}
```

---

### Shutdown System

**POST** `/api/system/shutdown`

Shutdown the Raspberry Pi.

**Request Body:**
```json
{
  "confirm": true
}
```

**Response:**
```json
{
  "success": true,
  "message": "System shutdown initiated"
}
```

---

### Update System

**POST** `/api/system/update`

Run system updates (apt-get update && apt-get upgrade).

**Response:**
```json
{
  "success": true,
  "message": "System update initiated"
}
```

---

### Clean System

**POST** `/api/system/cleanup`

Clean up system (remove old packages, clear caches).

**Response:**
```json
{
  "success": true,
  "message": "System cleanup completed"
}
```

---

## Log Management

### List Log Files

**GET** `/api/logs`

List all available log files.

**Response:**
```json
{
  "success": true,
  "count": 3,
  "files": [
    {
      "name": "mario.log",
      "path": "mario.log",
      "fullPath": "/var/log/luigi/mario.log",
      "size": 12345,
      "modified": "2024-01-15T10:30:00.000Z"
    }
  ]
}
```

---

### Get Module Logs

**GET** `/api/logs/:module`

Get log content for a specific module.

**Parameters:**
- `module` (path) - Module name (with or without .log extension)
- `lines` (query) - Number of lines to return (default: 100)
- `search` (query) - Optional search term to filter logs

**Examples:**
```bash
GET /api/logs/mario?lines=50
GET /api/logs/mario.log?search=ERROR
```

**Response:**
```json
{
  "success": true,
  "file": "mario.log",
  "count": 50,
  "lines": [
    "[2024-01-15 10:30:00] INFO: Motion detected",
    "[2024-01-15 10:30:01] INFO: Playing sound: callingmario1.wav"
  ]
}
```

---

## Configuration Management

### List Configuration Files

**GET** `/api/config`

List all configuration files for all modules.

**Response:**
```json
{
  "success": true,
  "count": 5,
  "configs": [
    {
      "name": "mario.conf",
      "path": "motion-detection/mario/mario.conf",
      "fullPath": "/etc/luigi/motion-detection/mario/mario.conf",
      "size": 512,
      "modified": "2024-01-15T10:00:00.000Z"
    }
  ]
}
```

---

### Read Configuration

**GET** `/api/config/:module(*)`

Read configuration file content. Supports multi-segment paths.

**Parameters:**
- `module` (path) - Configuration file path relative to /etc/luigi/

**Examples:**
```bash
GET /api/config/motion-detection/mario/mario.conf
GET /api/config/iot/ha-mqtt/ha-mqtt.conf
```

**Response:**
```json
{
  "success": true,
  "file": "mario.conf",
  "path": "motion-detection/mario/mario.conf",
  "content": "GPIO_PIN=23\nCOOLDOWN_SECONDS=1800\n",
  "parsed": {
    "GPIO_PIN": "23",
    "COOLDOWN_SECONDS": "1800"
  },
  "format": "ini"
}
```

---

### Update Configuration

**PUT** `/api/config/:module(*)`

Update configuration file. Supports multi-segment paths.

**Parameters:**
- `module` (path) - Configuration file path relative to /etc/luigi/

**Request Body:**
```json
{
  "GPIO_PIN": "23",
  "COOLDOWN_SECONDS": "3600"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Configuration updated successfully"
}
```

---

## Monitoring

### Health Check

**GET** `/health`

Public health check endpoint (no authentication required).

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "uptime": 86400,
  "version": "1.0.0"
}
```

---

### Get Metrics

**GET** `/api/monitoring/metrics`

Get detailed system metrics (same as `/api/system/status`).

**Response:** See [System Status](#get-system-status)

---

## Rate Limiting

All authenticated endpoints are rate-limited to prevent abuse:

- **Module operations** (start/stop/restart): 20 requests per minute
- **Other operations**: Configurable per endpoint

When rate limit is exceeded:
```json
{
  "success": false,
  "error": "Too Many Requests",
  "message": "Rate limit exceeded. Please try again later.",
  "retryAfter": 60
}
```

---

## Security Considerations

1. **Always use HTTPS in production** - Configure with SSL/TLS certificates
2. **Change default credentials** - Set strong username/password during setup
3. **Network isolation** - Run on local network only, use firewall rules
4. **Regular updates** - Keep system and dependencies up to date
5. **Input validation** - All inputs are validated and sanitized
6. **Path traversal protection** - File operations are restricted to safe paths
7. **Audit logging** - All operations are logged for security auditing

---

## Examples

### Using curl

```bash
# List all modules
curl -u admin:password http://localhost:3000/api/modules

# Get module status
curl -u admin:password http://localhost:3000/api/modules/mario

# Start a module
curl -u admin:password -X POST http://localhost:3000/api/modules/mario/start

# Get registry entries
curl -u admin:password http://localhost:3000/api/registry

# Get specific registry entry
curl -u admin:password http://localhost:3000/api/registry/motion-detection/mario

# Get system status
curl -u admin:password http://localhost:3000/api/system/status

# Read logs
curl -u admin:password "http://localhost:3000/api/logs/mario?lines=100"

# Read config
curl -u admin:password http://localhost:3000/api/config/motion-detection/mario/mario.conf

# Update config
curl -u admin:password -X PUT \
  -H "Content-Type: application/json" \
  -d '{"GPIO_PIN":"24"}' \
  http://localhost:3000/api/config/motion-detection/mario/mario.conf
```

### Using JavaScript/TypeScript

```typescript
const API_BASE_URL = 'http://raspberry-pi.local:3000';
const credentials = btoa('admin:password');

async function getModules() {
  const response = await fetch(`${API_BASE_URL}/api/modules`, {
    headers: {
      'Authorization': `Basic ${credentials}`
    }
  });
  return response.json();
}

async function getRegistry() {
  const response = await fetch(`${API_BASE_URL}/api/registry`, {
    headers: {
      'Authorization': `Basic ${credentials}`
    }
  });
  return response.json();
}

async function startModule(name: string) {
  const response = await fetch(`${API_BASE_URL}/api/modules/${name}/start`, {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${credentials}`
    }
  });
  return response.json();
}
```

---

## Version History

- **1.0.0** (2024-02) - Initial release with registry integration
  - Added `/api/registry` endpoints
  - Enhanced `/api/modules` with registry data
  - Complete API documentation

---

## Support

For issues, questions, or contributions, please visit:
- Repository: https://github.com/pkathmann88/luigi
- Documentation: `.github/skills/` in the repository
