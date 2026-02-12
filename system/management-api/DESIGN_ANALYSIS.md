# Design Analysis: Management API

**Module:** system/management-api  
**Feature Request:** Add a webserver that exposes an API for secure maintenance and control of the Luigi installation and host  
**Analyst:** GitHub Copilot Agent  
**Date:** 2026-02-10  
**Status:** Analysis

---

## Purpose

This document captures the initial analysis for creating a secure Node.js-based management API that enables remote administration of the Luigi system and Raspberry Pi host.

**Workflow:**
```
Feature Request → DESIGN_ANALYSIS.md (Phases 1-3) → IMPLEMENTATION_PLAN.md (Phases 1-5)
```

---

## Phase 1: Requirements & Hardware Analysis

**Goal:** Understand requirements and design approach (software-only module, no GPIO hardware required).

**Skills Used:** `module-design`, `nodejs-backend-development`

### 1.1 Requirements Definition

**Feature Request Summary:**
Create a secure web API server that provides RESTful endpoints for managing Luigi modules, controlling the Raspberry Pi host, viewing logs, and monitoring system health. The API must be secure for local network access with proper authentication, rate limiting, and audit logging.

**Module Purpose:**
"Provide a secure HTTPS API server for remote administration of Luigi modules and Raspberry Pi system operations, enabling centralized management without SSH access while maintaining comprehensive security and audit trails."

**Key Features:**
- **Module Management API**: Start, stop, restart, status, install, and uninstall Luigi modules remotely
  - **WHY**: Eliminates need for SSH access and manual systemctl commands
  - **WHO**: System administrators managing Luigi deployments
  
- **System Control API**: Reboot, shutdown, system updates, disk cleanup operations
  - **WHY**: Enables safe remote maintenance operations with proper validation
  - **WHO**: Administrators performing system maintenance
  
- **Log Viewing API**: Stream and query module logs, system logs, and audit logs
  - **WHY**: Centralized log access for debugging without SSH
  - **WHO**: Developers troubleshooting issues
  
- **Configuration Management API**: View and update module configurations
  - **WHY**: Remote configuration changes without file editing
  - **WHO**: Administrators tuning module parameters
  
- **System Monitoring API**: CPU, memory, disk, network, temperature metrics
  - **WHY**: Real-time health monitoring and capacity planning
  - **WHO**: Operations teams monitoring system health
  
- **HTTP Basic Authentication**: Username/password authentication over HTTPS
  - **WHY**: Simple, proven security model suitable for local network deployment
  - **WHO**: All API consumers
  
- **Comprehensive Audit Logging**: All operations logged with timestamp, user, IP
  - **WHY**: Security compliance and forensic analysis
  - **WHO**: Security auditors and administrators

**Use Cases:**
1. **Remote Module Management**: Administrator uses API to restart the mario motion detection module after configuration change without SSH access
2. **System Maintenance**: Operations script calls API to check disk space, clean logs, and reboot system during maintenance window
3. **Log Troubleshooting**: Developer uses API to tail logs from multiple modules simultaneously to diagnose integration issue
4. **Health Monitoring**: Monitoring dashboard polls API every minute to display Luigi system health metrics
5. **Configuration Updates**: Administrator updates MQTT broker address across multiple modules via API calls

**Success Criteria:**
- [ ] All Luigi modules can be managed (start/stop/status) via API
- [ ] System operations (reboot/shutdown/update) execute safely with validation
- [ ] Logs from any module can be retrieved with filtering and pagination
- [ ] Module configurations can be viewed and updated via API
- [ ] System metrics are exposed via API endpoints
- [ ] HTTP Basic Authentication works with all endpoints
- [ ] All operations are logged to audit log with user and IP
- [ ] Rate limiting prevents DoS attacks (max 100 req/15min per IP)
- [ ] API runs on HTTPS with self-signed or custom certificates
- [ ] Service auto-starts on boot and auto-restarts on failure
- [ ] API responds within 500ms for status checks, 5s for operations
- [ ] Complete API documentation provided in README
- [ ] Security audit shows no critical vulnerabilities

**Requirements Clarity Checklist:**
- [x] Module purpose answers: What, Why, How, Who
- [x] Each feature explains its value/rationale
- [x] Use cases are concrete and realistic
- [x] Success criteria are measurable and testable
- [x] Requirements are clear enough for someone unfamiliar to understand

### 1.2 Hardware Component Analysis

**Required Components:**
| Component | Part Number | Voltage | Current | Qty | Purpose | Availability |
|-----------|-------------|---------|---------|-----|---------|--------------|
| None | N/A | N/A | N/A | N/A | Software-only module | N/A |

**Component Verification:**
- [x] No GPIO hardware required (software-only module)
- [x] No additional components needed
- [x] Estimated cost: $0 (uses existing Raspberry Pi)

### 1.3 GPIO Pin Strategy

**Pin Requirements:**
| Function | Type | Special Requirements | Proposed Pin |
|----------|------|---------------------|--------------|
| None | N/A | N/A | N/A |

**GPIO Verification:**
- [x] No GPIO pins required (software-only module)
- [x] No conflicts possible with other modules

### 1.4 Wiring Design

**Wiring Diagram:**
```
No physical wiring required - this is a software-only module.
Network connectivity provided by Raspberry Pi Zero W built-in Wi-Fi.
```

### 1.5 Power Budget

**Power Calculations:**
| Component | Voltage | Current | Notes |
|-----------|---------|---------|-------|
| Raspberry Pi Zero W | 5V | 150mA | Base |
| Node.js Application | N/A | ~50mA | CPU usage (estimated) |
| **TOTAL** |  | **~200mA** | Well within Pi Zero W capacity |

**Power Supply:**
- Minimum required: 1.2A (standard Pi Zero W requirement)
- Recommended: 2A (standard recommendation)
- External power needed: No

### 1.6 Safety Analysis

**Critical Safety Checks:**
- [x] No GPIO hardware involved
- [x] No electrical safety concerns
- [x] Software-only module

**Safety Concerns:**
1. **Command Injection via API**: Malicious API calls could execute arbitrary system commands
2. **Unauthorized Access**: Weak authentication could allow unauthorized control
3. **Data Exposure**: API errors might leak sensitive system information
4. **DoS Attacks**: Excessive API requests could overwhelm Raspberry Pi resources

**Mitigations:**
1. **Command Injection**: All system commands use subprocess with array arguments (no shell=True), strict input validation
2. **Unauthorized Access**: HTTP Basic Authentication required, HTTPS mandatory, strong password enforcement
3. **Data Exposure**: Sanitized error messages, no stack traces in production, audit logging
4. **DoS Attacks**: Multi-layer rate limiting (global, per-endpoint, per-user), connection limits, timeouts

### 1.7 Hardware Analysis Summary

**Hardware Approach:**
This is a pure software module with no GPIO hardware requirements. The module leverages the Raspberry Pi Zero W's existing network connectivity via built-in Wi-Fi. Network security is achieved through HTTPS/TLS, authentication, rate limiting, and IP filtering.

**Key Hardware Decisions:**
1. **No GPIO Hardware**: Software-only API server eliminates hardware complexity and safety concerns
2. **Network Only**: Uses existing Wi-Fi for local network API access
3. **Local Network Security Model**: Designed for trusted local network, not internet-facing

**Hardware Risks:**
| Risk | Severity | Mitigation |
|------|----------|------------|
| None | N/A | Software-only module |

**Phase 1 Sign-off:**
- [x] Requirements clearly defined
- [x] Hardware components selected (none required)
- [x] GPIO pins assigned (none required)
- [x] Wiring diagram created (N/A for software module)
- [x] Safety verified (software security focus)
- [x] Ready for Phase 2

**Approved by:** GitHub Copilot Agent **Date:** 2026-02-10

---

## Phase 2: Software Architecture Analysis

**Goal:** Design Node.js application structure and architecture.

**Skills Used:** `module-design`, `nodejs-backend-development`

### 2.1 Module Structure Design

**File Structure:**
```
system/management-api/
├── README.md                    # Complete API documentation
├── module.json                  # Module metadata (dependencies: none)
├── setup.sh                     # Installation automation script
├── package.json                 # Node.js dependencies
├── package-lock.json            # Locked dependency versions
├── .env.example                 # Environment variables template
├── .gitignore                   # Git exclusions (node_modules, .env)
├── server.js                    # Main application entry point
├── management-api.service       # systemd service file
├── management-api.conf.example  # Configuration file example
├── config/
│   └── index.js                 # Configuration loader
├── src/
│   ├── app.js                   # Express app setup with security
│   ├── routes/
│   │   ├── index.js             # Route aggregator
│   │   ├── modules.js           # Module management endpoints
│   │   ├── system.js            # System control endpoints
│   │   ├── logs.js              # Log viewing endpoints
│   │   ├── config.js            # Configuration endpoints
│   │   ├── monitoring.js        # System monitoring endpoints
│   │   └── health.js            # Health check (public)
│   ├── controllers/
│   │   ├── modulesController.js # Module operations logic
│   │   ├── systemController.js  # System operations logic
│   │   ├── logsController.js    # Log retrieval logic
│   │   ├── configController.js  # Config management logic
│   │   └── monitoringController.js # Metrics collection logic
│   ├── middleware/
│   │   ├── authenticate.js      # HTTP Basic Auth middleware
│   │   ├── validateInput.js     # Input validation middleware
│   │   ├── rateLimit.js         # Rate limiting middleware
│   │   ├── ipFilter.js          # IP whitelist middleware
│   │   ├── errorHandler.js      # Error handling middleware
│   │   ├── logger.js            # Request logging middleware
│   │   └── securityMonitor.js   # Security monitoring
│   ├── services/
│   │   ├── moduleService.js     # systemctl operations
│   │   ├── systemService.js     # System commands
│   │   ├── logService.js        # Log file operations
│   │   └── configService.js     # Config file operations
│   ├── utils/
│   │   ├── logger.js            # Winston logger setup
│   │   ├── validator.js         # Input validation helpers
│   │   └── commandExecutor.js   # Safe command execution
│   └── security/
│       ├── commandValidator.js  # Command injection prevention
│       ├── pathValidator.js     # Path traversal prevention
│       └── auditLogger.js       # Security audit logging
├── scripts/
│   ├── generate-certs.sh        # Self-signed cert generator
│   └── test-api.sh              # API testing script
└── tests/
    ├── unit/                    # Unit tests (Jest)
    ├── integration/             # Integration tests
    └── security/                # Security tests
```

**Component Purpose Documentation:**

**server.js**
- **What:** Main application entry point that initializes HTTPS server
- **Why:** Centralizes server startup, HTTPS configuration, and graceful shutdown
- **How:** Loaded by systemd service, loads .env, creates HTTPS server with app
- **Who:** systemd service manager, administrators (manual start for testing)
- **Key Responsibilities:**
  1. Load environment configuration from .env file
  2. Initialize HTTPS server with TLS certificates
  3. Start Express application on configured port
  4. Handle SIGTERM/SIGINT for graceful shutdown
  5. Log startup and shutdown events

**src/app.js**
- **What:** Express application with all security middleware configured
- **Why:** Centralizes app configuration, middleware stack, and route mounting
- **How:** Imported by server.js, exports configured Express app
- **Who:** server.js (initialization), all routes (request handling)
- **Key Responsibilities:**
  1. Configure Helmet security headers
  2. Set up CORS, compression, body parsing
  3. Mount authentication, rate limiting, IP filtering
  4. Register all API routes
  5. Configure error handling middleware

**ModulesController**
- **What:** API controller for Luigi module management operations
- **Why:** Encapsulates module lifecycle operations (start/stop/status)
- **How:** Called by modules routes on authenticated requests
- **Who:** Authenticated API clients performing module management
- **Key Responsibilities:**
  1. List all available Luigi modules
  2. Get status of specific module (systemctl status)
  3. Start/stop/restart modules via moduleService
  4. Validate module names before operations
  5. Return structured JSON responses with proper error handling

**SystemController**
- **What:** API controller for Raspberry Pi system operations
- **Why:** Provides safe system administration capabilities
- **How:** Called by system routes on authenticated requests
- **Who:** Authenticated administrators performing maintenance
- **Key Responsibilities:**
  1. Execute system commands (reboot, shutdown) with safety checks
  2. Report system metrics (CPU, memory, disk, temperature)
  3. Trigger system updates (apt-get update/upgrade)
  4. Perform disk cleanup operations
  5. Validate all operations before execution

**LogsController**
- **What:** API controller for log file access and streaming
- **Why:** Provides centralized log viewing without SSH
- **How:** Called by logs routes on authenticated requests
- **Who:** Authenticated users troubleshooting issues
- **Key Responsibilities:**
  1. List available log files from /var/log/
  2. Stream log file contents with pagination
  3. Tail logs in real-time
  4. Filter logs by date range or search term
  5. Sanitize log output to prevent information leakage

**ConfigController**
- **What:** API controller for module configuration management
- **Why:** Enables remote configuration updates
- **How:** Called by config routes on authenticated requests
- **Who:** Authenticated administrators tuning modules
- **Key Responsibilities:**
  1. List all module configuration files
  2. Read configuration file contents (INI format)
  3. Update configuration values with validation
  4. Create backup before updating
  5. Trigger module restart after config change

**AuthenticateMiddleware**
- **What:** HTTP Basic Authentication middleware
- **Why:** Secures all API endpoints, prevents unauthorized access
- **How:** Applied to protected routes, validates Authorization header
- **Who:** All API requests to protected endpoints
- **Key Responsibilities:**
  1. Parse and decode Basic Auth credentials
  2. Validate username and password (constant-time comparison)
  3. Log authentication attempts (success and failure)
  4. Return 401 Unauthorized for invalid credentials
  5. Attach user object to request for authorized requests

**RateLimitMiddleware**
- **What:** Multi-layer rate limiting middleware
- **Why:** Prevents DoS attacks and brute force attempts
- **How:** Applied globally and per-route based on sensitivity
- **Who:** All API requests
- **Key Responsibilities:**
  1. Track request counts per IP address
  2. Enforce global limit (100 req/15min)
  3. Enforce strict limits for sensitive operations
  4. Return 429 Too Many Requests when limit exceeded
  5. Log rate limit violations to audit log

**ModuleService**
- **What:** Service layer for systemctl module operations
- **Why:** Abstracts systemctl commands, provides error handling
- **How:** Called by ModulesController for module operations
- **Who:** ModulesController
- **Key Responsibilities:**
  1. Execute systemctl commands safely (subprocess with array args)
  2. Parse systemctl output to JSON
  3. Validate module names against known modules
  4. Handle systemctl errors gracefully
  5. Return structured operation results

**AuditLogger**
- **What:** Security audit logging service
- **Why:** Comprehensive audit trail for compliance and forensics
- **How:** Called by controllers and middleware on security events
- **Who:** All security-relevant operations
- **Key Responsibilities:**
  1. Log authentication attempts (success/failure)
  2. Log all module operations with user and IP
  3. Log system commands with full context
  4. Log security violations (invalid input, rate limits)
  5. Rotate audit logs with size limits

### 2.2 Configuration Design

**Configuration File Location:**
`/etc/luigi/system/management-api/management-api.conf`

**Configuration Structure:**
```ini
[Server]
# Server configuration
PORT=8443
HOST=0.0.0.0
USE_HTTPS=true

[Security]
# Authentication
AUTH_USERNAME=admin
AUTH_PASSWORD=change-me-in-production

# Allowed IPs (comma-separated, empty = allow all local network)
ALLOWED_IPS=

# Rate limiting
RATE_LIMIT_WINDOW_MINUTES=15
RATE_LIMIT_MAX_REQUESTS=100

[TLS]
# SSL/TLS configuration
CERT_PATH=/etc/luigi/system/management-api/certs/server.crt
KEY_PATH=/etc/luigi/system/management-api/certs/server.key

[Logging]
# Logging configuration
LOG_FILE=/var/log/luigi/management-api.log
LOG_LEVEL=INFO
LOG_MAX_BYTES=10485760
LOG_BACKUP_COUNT=5
AUDIT_LOG_FILE=/var/log/luigi/audit.log

[Paths]
# System paths
MODULES_PATH=/home/pi/luigi
CONFIG_PATH=/etc/luigi
LOGS_PATH=/var/log
```

**Environment Variables (.env for sensitive data):**
```bash
# NEVER commit this file to git!
NODE_ENV=production
PORT=8443
HOST=0.0.0.0

# Authentication (REQUIRED - change these!)
AUTH_USERNAME=admin
AUTH_PASSWORD=your-secure-password-here

# TLS Certificates (REQUIRED for HTTPS)
USE_HTTPS=true
TLS_CERT_PATH=/etc/luigi/system/management-api/certs/server.crt
TLS_KEY_PATH=/etc/luigi/system/management-api/certs/server.key

# Optional: IP whitelist (comma-separated)
ALLOWED_IPS=192.168.1.100,192.168.1.101
```

**Configurable Parameters:**
| Parameter | Section | Type | Default | Description |
|-----------|---------|------|---------|-------------|
| PORT | Server | int | 8443 | HTTPS port for API |
| HOST | Server | string | 0.0.0.0 | Bind address (0.0.0.0 = all interfaces) |
| USE_HTTPS | Server | boolean | true | Enable HTTPS (required for security) |
| AUTH_USERNAME | Security | string | admin | Basic Auth username |
| AUTH_PASSWORD | Security | string | (required) | Basic Auth password (minimum 12 chars) |
| ALLOWED_IPS | Security | string | "" | Comma-separated IP whitelist |
| RATE_LIMIT_MAX_REQUESTS | Security | int | 100 | Max requests per window |
| CERT_PATH | TLS | string | /etc/luigi/system/management-api/certs/server.crt | TLS certificate path |
| KEY_PATH | TLS | string | /etc/luigi/system/management-api/certs/server.key | TLS private key path |
| LOG_LEVEL | Logging | string | INFO | Log level (DEBUG/INFO/WARN/ERROR) |

**Configuration Verification:**
- [x] All user-changeable settings identified
- [x] Sensible defaults chosen
- [x] Configuration location follows Luigi standard
- [x] INI format for config file, .env for secrets
- [x] Sensitive data (passwords) in .env, not tracked in git

### 2.3 Error Handling Strategy

**Error Handling Plan:**

**API Errors:**
- Approach: Custom error handler middleware catches all errors, logs them, returns sanitized JSON response
- Response format: `{ success: false, error: "Error type", message: "Safe description" }`
- Stack traces: Never returned in production (NODE_ENV=production check)

**Subprocess Errors (systemctl, apt-get, etc.):**
- Approach: Wrap all subprocess.run() in try/catch, check return codes, timeout after 30s
- Error parsing: Parse stderr for user-friendly messages
- Logging: Log full command and output for debugging

**File System Errors:**
- Approach: Check file existence before operations, create directories as needed
- Path validation: Use pathValidator to prevent traversal attacks
- Permissions: Catch EACCES, ENOENT errors with helpful messages

**Authentication Errors:**
- Approach: Return generic "Invalid credentials" message (no user enumeration)
- Rate limiting: Apply strict limits to login attempts (5/15min)
- Audit logging: Log all failed attempts with IP

**Validation Errors:**
- Approach: express-validator middleware catches invalid input
- Response: Return 400 Bad Request with specific validation failures
- Sanitization: Trim, escape, and validate all user input

**Network Errors:**
- Approach: Timeouts on all HTTP requests, graceful degradation
- HTTPS errors: Check certificate validity on startup, fail fast if missing

**Reference:** See `.github/skills/nodejs-backend-development/SKILL.md` (Error Handling)

### 2.4 Logging Strategy

**Logging Configuration:**
- Application log: `/var/log/luigi/management-api.log` (Winston, rotating 10MB x 5 files)
- Audit log: `/var/log/luigi/audit.log` (Security events, rotating 10MB x 10 files)
- System log: journalctl (systemd captures stdout/stderr)
- Levels used: DEBUG (development), INFO (operations), WARN (issues), ERROR (failures)

**Key Log Points:**

**Application Log (Winston):**
1. Server startup/shutdown (port, environment)
2. Configuration loaded (sources, missing values)
3. API requests (via Morgan middleware - combined format)
4. Module operations (start/stop/restart with result)
5. System operations (reboot/shutdown with user)
6. Errors and warnings with context
7. Performance metrics (slow requests >5s)

**Audit Log (Separate File):**
1. Authentication attempts (success/failure, username, IP, timestamp)
2. Module operations (user, operation, module, result, IP)
3. System commands (user, command, result, IP)
4. Configuration changes (user, file, setting, old/new value)
5. Security violations (invalid input, path traversal, rate limit)
6. Unauthorized access attempts (IP, endpoint, reason)

**Log Format:**
```json
{
  "timestamp": "2026-02-10T16:05:49.604Z",
  "level": "info",
  "message": "Module operation",
  "user": "admin",
  "ip": "192.168.1.100",
  "operation": "start",
  "module": "mario",
  "result": "success"
}
```

**Log Sanitization:**
- [x] Length limits on logged data (1000 chars max)
- [x] No passwords or tokens logged
- [x] Newlines removed from user input
- [x] IP addresses normalized (IPv4 only, no IPv6 prefix)
- [x] Error stack traces only in development mode

### 2.5 Security Design

**Security Measures:**

**Authentication & Authorization:**
- [x] HTTP Basic Authentication (username/password)
- [x] Constant-time password comparison (prevent timing attacks)
- [x] Strong password requirement (minimum 12 characters)
- [x] HTTPS mandatory (no plaintext credential transmission)
- [x] WWW-Authenticate header for browser support

**Input Validation:**
- [x] express-validator on all endpoints
- [x] Module name validation (alphanumeric, hyphens only)
- [x] Path validation (prevent directory traversal)
- [x] Command validation (whitelist of allowed commands)
- [x] JSON schema validation for request bodies

**Rate Limiting:**
- [x] Global rate limit (100 req/15min per IP)
- [x] Strict auth limit (5 attempts/15min per IP)
- [x] Operation-specific limits (module ops 20/min)
- [x] Slow-down middleware (progressive delay)

**Network Security:**
- [x] HTTPS/TLS 1.2+ only
- [x] Strong cipher suites configured
- [x] IP filtering middleware (local network only by default)
- [x] CORS restricted (no cross-origin by default)
- [x] Security headers (Helmet.js)

**Command Injection Prevention:**
- [x] subprocess with array arguments (never shell=True)
- [x] Command whitelist validation
- [x] No user input in command strings
- [x] Timeout protection (30s max)

**Path Traversal Prevention:**
- [x] All file paths validated with os.path.commonpath()
- [x] Whitelist of allowed directories
- [x] No symbolic link following

**Information Disclosure Prevention:**
- [x] Sanitized error messages (no stack traces)
- [x] Generic authentication errors
- [x] Version headers disabled (X-Powered-By)
- [x] No directory listings

**Audit & Monitoring:**
- [x] Comprehensive audit logging
- [x] Security event monitoring
- [x] Failed authentication tracking
- [x] Rate limit violation logging

**Reference:** See `.github/skills/nodejs-backend-development/SKILL.md` (Security Implementation)

### 2.6 Software Architecture Summary

**Architecture Pattern:**
RESTful API with Express.js following the Controller-Service-Repository pattern:
- **Routes**: Define API endpoints and apply middleware
- **Controllers**: Handle HTTP request/response, input validation
- **Services**: Business logic and systemctl/system operations
- **Utils**: Shared functionality (logging, validation, command execution)
- **Middleware**: Cross-cutting concerns (auth, rate limiting, logging)

**Key Software Decisions:**

1. **Node.js with Express.js**: Lightweight, event-driven architecture perfect for I/O-bound API operations on Raspberry Pi Zero W
   - Rationale: Low memory footprint, excellent HTTP/REST support, large ecosystem

2. **HTTP Basic Authentication**: Simple username/password auth over HTTPS
   - Rationale: Adequate security for local network, no complex token management, browser-compatible

3. **Multi-layer Security**: Defense in depth with authentication, rate limiting, input validation, audit logging
   - Rationale: No single point of failure, multiple barriers for attackers

4. **Synchronous subprocess operations**: All systemctl and system commands executed synchronously with timeouts
   - Rationale: Prevents race conditions, ensures operations complete before returning, easier error handling

5. **Separate audit log**: Security events logged to dedicated file separate from application log
   - Rationale: Easier compliance auditing, prevents log pollution, longer retention

6. **No database**: All state retrieved from system commands and file system
   - Rationale: Reduces complexity, no data persistence needed, real-time system state

**Software Risks:**
| Risk | Severity | Mitigation |
|------|----------|------------|
| Command injection via API | High | Whitelist commands, array arguments, input validation |
| Brute force authentication | Medium | Rate limiting, audit logging, strong password requirement |
| DoS via resource exhaustion | Medium | Connection limits, timeouts, rate limiting, memory monitoring |
| Information disclosure | Low | Sanitized errors, no stack traces, generic auth messages |
| Privilege escalation | Medium | Run as limited user (pi), validate all operations, audit logging |

**Phase 2 Sign-off:**
- [x] Module structure designed (Node.js/Express)
- [x] Class architecture defined (Controllers, Services, Middleware)
- [x] Configuration designed (.env for secrets, .conf for settings)
- [x] Error handling planned (comprehensive try/catch, sanitized responses)
- [x] Logging strategy defined (Winston + audit log)
- [x] Security measures planned (multi-layer defense)
- [x] Ready for Phase 3

**Approved by:** GitHub Copilot Agent **Date:** 2026-02-10

---

## Phase 3: Service & Deployment Analysis

**Goal:** Design systemd service integration and deployment strategy.

**Skills Used:** `module-design`, `system-setup`, `nodejs-backend-development`

### 3.1 systemd Service Design

**Service Unit File Design:**
```ini
[Unit]
Description=Luigi Management API Server
Documentation=https://github.com/pkathmann88/luigi
After=network.target

[Service]
Type=simple
User=pi
Group=pi
WorkingDirectory=/home/pi/luigi/system/management-api

# Environment
Environment="NODE_ENV=production"
EnvironmentFile=/etc/luigi/system/management-api/.env

# Execute
ExecStart=/usr/bin/node server.js

# Restart policy
Restart=always
RestartSec=10

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=management-api

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=/var/log/luigi /tmp

# Resource limits (Raspberry Pi Zero W constraints)
LimitNOFILE=1024
MemoryMax=200M
CPUQuota=80%

[Install]
WantedBy=multi-user.target
```

**Service Characteristics:**
- **Type**: simple (foreground Node.js application)
- **User**: pi (non-root, uses sudo for system operations)
- **Restart**: always with 10s delay (critical system service)
- **Logging**: journalctl + application file logs
- **Security**: ProtectSystem, NoNewPrivileges, PrivateTmp
- **Resources**: Limited to 200MB RAM, 80% CPU (single core)

**Graceful Shutdown:**
- Node.js application handles SIGTERM signal
- Closes HTTPS server gracefully
- Waits for in-flight requests (10s timeout)
- Logs shutdown event
- Exits cleanly

### 3.2 Setup Script Design

**setup.sh Functions:**

**install():**
1. Check prerequisites (root, Node.js version)
2. Install system dependencies (nodejs, build-essential)
3. Create directory structure
   - `/home/pi/luigi/system/management-api/` (application)
   - `/etc/luigi/system/management-api/` (configuration)
   - `/var/log/luigi/` (audit logs)
4. Copy application files
   - Copy all source files to application directory
   - Install Node.js dependencies (npm install --production)
5. Deploy configuration
   - Copy .env.example to /etc/luigi/system/management-api/.env
   - Set secure permissions (chmod 600 .env)
   - Prompt for AUTH_PASSWORD change
6. Generate TLS certificates
   - Run scripts/generate-certs.sh if not exists
   - Store in /etc/luigi/system/management-api/certs/
7. Deploy systemd service
   - Copy service file to /etc/systemd/system/
   - systemctl daemon-reload
8. Enable and start service
   - systemctl enable management-api.service
   - systemctl start management-api.service
9. Verify installation
   - Check service status
   - Test API health endpoint
   - Display access URL and credentials

**uninstall():**
1. Stop and disable service
2. Remove service file
3. Remove application files
4. Ask about configuration removal (preserve by default)
5. Ask about log removal (preserve by default)
6. Ask about certificate removal (preserve by default)

**status():**
1. Check service status (systemctl status)
2. Check if API is responding (curl health endpoint)
3. Display configuration location
4. Show recent logs (journalctl -n 20)
5. Display API access information

**Dependencies:**
- nodejs (>= 16.x)
- npm (>= 8.x)
- openssl (for certificate generation)
- curl (for health checks)

### 3.3 File Deployment Strategy

**Application Files:**
```
Source: system/management-api/
Destination: /home/pi/luigi/system/management-api/
Permissions: 755 (directories), 644 (files), 755 (scripts)
Owner: pi:pi
```

**Configuration Files:**
```
Source: .env.example
Destination: /etc/luigi/system/management-api/.env
Permissions: 600 (contains secrets!)
Owner: pi:pi
Action: Prompt user to set AUTH_PASSWORD
```

**Service File:**
```
Source: management-api.service
Destination: /etc/systemd/system/management-api.service
Permissions: 644
Owner: root:root
Action: systemctl daemon-reload after copy
```

**TLS Certificates:**
```
Source: Generated by scripts/generate-certs.sh
Destination: /etc/luigi/system/management-api/certs/server.{crt,key}
Permissions: 644 (cert), 640 (key)
Owner: root:pi
Action: Generate if not exists, skip if exists
```

**Log Files:**
```
Created by application (Winston)
Location: /var/log/luigi/management-api.log, /var/log/luigi/audit.log
Permissions: 644
Owner: pi:pi
Rotation: Handled by Winston (10MB x 5 files, 10MB x 10 files)
```

### 3.4 Configuration Management

**Configuration Sources (Priority Order):**
1. Environment variables (.env file)
2. Configuration file (.conf file)
3. Built-in defaults

**Configuration Validation:**
- Check required settings on startup (AUTH_PASSWORD, TLS_CERT_PATH)
- Fail fast if missing required configuration
- Log configuration sources (which settings from which source)
- Warn about insecure settings (HTTP mode, default password, no IP whitelist)

**Configuration Updates:**
- Manual: Edit /etc/luigi/system/management-api/.env
- Via API: ConfigController updates .env file (with backup)
- Restart required: systemctl restart management-api

### 3.5 Dependency Management

**System Dependencies:**
```bash
# Required
nodejs (>= 16.x)  # Node.js runtime
npm (>= 8.x)      # Package manager

# For certificate generation
openssl           # TLS certificate generation

# For testing
curl              # API health checks
```

**Node.js Dependencies (package.json):**
```json
{
  "dependencies": {
    "express": "^4.18.2",
    "dotenv": "^16.0.3",
    "helmet": "^7.0.0",
    "cors": "^2.8.5",
    "compression": "^1.7.4",
    "express-rate-limit": "^6.7.0",
    "express-slow-down": "^1.6.0",
    "express-validator": "^7.0.1",
    "winston": "^3.8.2",
    "morgan": "^1.10.0",
    "joi": "^17.9.2"
  },
  "devDependencies": {
    "jest": "^29.5.0",
    "supertest": "^6.3.3"
  }
}
```

**Module Dependencies (module.json):**
```json
{
  "name": "management-api",
  "version": "1.0.0",
  "description": "Secure Node.js API for Luigi system management",
  "category": "system",
  "dependencies": []
}
```

**Dependency Installation:**
- Automated: npm install --production (in setup.sh)
- Security: Run npm audit after install
- Updates: Manual via setup.sh update function

### 3.6 Service & Deployment Summary

**Deployment Strategy:**
Single-command automated installation via setup.sh that:
1. Validates prerequisites (Node.js, permissions)
2. Installs system and Node.js dependencies
3. Deploys application and configuration files
4. Generates TLS certificates if needed
5. Installs and starts systemd service
6. Verifies successful deployment

**Service Management:**
```bash
# Install
sudo system/management-api/setup.sh install

# Check status
system/management-api/setup.sh status

# Restart after config change
sudo systemctl restart management-api

# View logs
sudo journalctl -u management-api -f

# Uninstall
sudo system/management-api/setup.sh uninstall
```

**Key Deployment Decisions:**

1. **systemd service**: Industry-standard service management with auto-restart and resource limits
   - Rationale: Reliable, well-integrated, standard Linux service management

2. **Node.js as pi user**: Non-root execution for security, uses sudo for privileged operations
   - Rationale: Principle of least privilege, reduces attack surface

3. **Environment file for secrets**: Passwords and keys in .env, not in tracked config files
   - Rationale: Security best practice, prevents credential leakage in git

4. **Self-signed certificates**: Generated automatically during installation
   - Rationale: Works out-of-box, users can replace with custom certs if needed

5. **Separate audit log**: Security events in dedicated file with longer retention
   - Rationale: Compliance requirements, easier auditing, prevents log pollution

**Deployment Risks:**
| Risk | Severity | Mitigation |
|------|----------|------------|
| Missing Node.js dependencies | Medium | Automated apt-get install, version checking |
| Port 8443 already in use | Low | Check port availability, allow custom port |
| Certificate generation fails | Low | Check OpenSSL installed, fallback to HTTP (dev only) |
| Default password unchanged | High | Prompt during install, warn on service start |
| Insufficient RAM | Medium | systemd MemoryMax limit, monitoring alerts |

**Phase 3 Sign-off:**
- [x] systemd service designed
- [x] Setup script designed (install/uninstall/status)
- [x] File deployment strategy defined
- [x] Configuration management planned
- [x] Dependencies identified and managed
- [x] Ready for IMPLEMENTATION_PLAN.md creation

**Approved by:** GitHub Copilot Agent **Date:** 2026-02-10

---

## Design Analysis Complete

**Summary:**
This design analysis defines a comprehensive Node.js-based management API for the Luigi system. The module provides secure REST API access for module management, system control, log viewing, configuration updates, and system monitoring.

**Key Design Highlights:**
- Software-only module (no GPIO hardware)
- Node.js with Express.js for lightweight API server
- HTTP Basic Authentication over HTTPS/TLS
- Multi-layer security (auth, rate limiting, input validation, audit logging)
- systemd service with resource limits for Raspberry Pi Zero W
- Automated deployment via setup.sh
- Comprehensive API documentation

**Next Steps:**
1. Create IMPLEMENTATION_PLAN.md with 5 implementation phases
2. Execute implementation following TDD approach
3. Complete testing and verification
4. Deploy to production

**Status:** ✅ Design Analysis Complete - Ready for Implementation Planning
