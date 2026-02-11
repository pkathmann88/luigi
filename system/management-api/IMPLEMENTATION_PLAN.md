# Implementation Plan: Management API

**Module:** system/management-api  
**Based on:** DESIGN_ANALYSIS.md (completed 2026-02-10)  
**Implementation Lead:** GitHub Copilot Agent  
**Start Date:** 2026-02-10  
**Target Completion:** 2026-02-10  
**Status:** In Progress

---

## Overview

This implementation plan translates the approved DESIGN_ANALYSIS.md into actionable implementation tasks following the Test-Driven Development (TDD) approach.

**Prerequisite:** ✅ DESIGN_ANALYSIS.md Phases 1-3 complete and approved.

**Workflow:**
```
Feature Request → DESIGN_ANALYSIS.md (✅ Approved) → IMPLEMENTATION_PLAN.md (This document)
```

---

## Design Summary (from DESIGN_ANALYSIS.md)

### Module Purpose
"Provide a secure HTTPS API server for remote administration of Luigi modules and Raspberry Pi system operations, enabling centralized management without SSH access while maintaining comprehensive security and audit trails."

### Hardware Approach
- **Components:** None (software-only module)
- **GPIO Pins:** None (no hardware interfacing)
- **Network:** Uses Raspberry Pi Zero W built-in Wi-Fi
- **Safety measures:** Software security only (no electrical concerns)

### Software Architecture
- **Technology Stack:** Node.js 16.x + Express.js 4.x
- **Authentication:** HTTP Basic Authentication over HTTPS/TLS
- **Components:**
  - Routes → Controllers → Services → Utils
  - Middleware: Authentication, Rate Limiting, Validation, Logging
  - Security: Audit logging, input validation, command injection prevention
- **Configuration:** `/etc/luigi/system/management-api/.env` (secrets), `management-api.conf` (settings)
- **Architecture pattern:** RESTful API with Controller-Service pattern

### Service & Deployment
- **Service type:** systemd (Type=simple, User=pi)
- **System Dependencies:** nodejs (>=16), npm (>=8), openssl, curl
- **Node Dependencies:** express, helmet, winston, express-validator, express-rate-limit
- **File locations:**
  - Application: `/home/pi/luigi/system/management-api/`
  - Configuration: `/etc/luigi/system/management-api/`
  - Certificates: `/home/pi/certs/`
  - Logs: `/var/log/luigi/management-api.log`, `/var/log/luigi/audit.log`

---

## Phase 1: Testing Strategy Implementation

**Goal:** Set up testing infrastructure and validation approach.

**Skills Used:** `nodejs-backend-development`, `module-design`

**Based on:** DESIGN_ANALYSIS.md Phases 1 & 2

### 1.1 Syntax Validation Scripts
- [ ] Document Node.js syntax check: `node --check server.js`
- [ ] Document npm audit: `npm audit --audit-level=moderate`
- [ ] Document shell script check: `shellcheck setup.sh scripts/*.sh`
- [ ] Create validation script: `scripts/validate-syntax.sh`

### 1.2 Security Testing
- [ ] Create security test script: `scripts/security-test.sh`
  - [ ] Test anonymous access (should return 401)
  - [ ] Test invalid credentials (should return 401)
  - [ ] Test rate limiting (should return 429 after limit)
  - [ ] Test command injection attempts (should be blocked)
  - [ ] Test path traversal attempts (should be blocked)
- [ ] Document expected security test results

### 1.3 API Endpoint Testing
- [ ] Define test cases for each endpoint:
  - [ ] GET /health (public, should return 200)
  - [ ] GET /api/modules (auth required, returns module list)
  - [ ] POST /api/modules/:name/start (auth required, starts module)
  - [ ] GET /api/system/status (auth required, returns metrics)
  - [ ] GET /api/logs/:module (auth required, returns logs)
- [ ] Create API test script: `scripts/test-api.sh`

### 1.4 Test Documentation
- [ ] Document how to run syntax validation
- [ ] Document how to run security tests
- [ ] Document how to run API tests
- [ ] Document expected test results

**Phase 1 Complete:** ____________ Date: __________

---

## Phase 2: Core Implementation

**Goal:** Implement the complete Node.js API application.

**Skills Used:** `nodejs-backend-development`, `system-setup`

**Based on:** DESIGN_ANALYSIS.md (all phases)

### 2.1 Project Initialization
- [ ] Create package.json with all dependencies
- [ ] Create package-lock.json (npm install)
- [ ] Create .gitignore (node_modules, .env, *.log)
- [ ] Create .env.example template
- [ ] Run npm audit to check for vulnerabilities

### 2.2 Configuration System
- [ ] Create config/index.js (configuration loader)
- [ ] Implement environment variable loading (dotenv)
- [ ] Implement configuration validation
- [ ] Implement secure defaults
- [ ] Test configuration loading

### 2.3 Security Middleware
- [ ] Implement src/middleware/authenticate.js
  - [ ] HTTP Basic Auth parsing
  - [ ] Constant-time password comparison
  - [ ] WWW-Authenticate header
  - [ ] Audit logging integration
- [ ] Implement src/middleware/validateInput.js
  - [ ] Module name validation
  - [ ] Path validation
  - [ ] Command validation
  - [ ] JSON schema validation
- [ ] Implement src/middleware/rateLimit.js
  - [ ] Global rate limiter (100/15min)
  - [ ] Auth rate limiter (5/15min)
  - [ ] Operation rate limiter (20/min)
- [ ] Implement src/middleware/ipFilter.js
  - [ ] IP whitelist checking
  - [ ] Local network validation
- [ ] Implement src/middleware/errorHandler.js
  - [ ] Safe error messages
  - [ ] Error logging
  - [ ] Stack trace control
- [ ] Implement src/middleware/logger.js
  - [ ] Morgan request logging
  - [ ] Custom format configuration
- [ ] Implement src/middleware/securityMonitor.js
  - [ ] Request monitoring
  - [ ] Suspicious activity detection

### 2.4 Logging Infrastructure
- [ ] Implement src/utils/logger.js
  - [ ] Winston logger setup
  - [ ] File transport with rotation
  - [ ] Console transport
  - [ ] Log formatting
- [ ] Implement src/security/auditLogger.js
  - [ ] Separate audit log file
  - [ ] Authentication logging
  - [ ] Operation logging
  - [ ] Security violation logging

### 2.5 Service Layer (Business Logic)
- [ ] Implement src/services/moduleService.js
  - [ ] List all modules (find setup.sh files)
  - [ ] Get module status (systemctl status)
  - [ ] Start module (systemctl start)
  - [ ] Stop module (systemctl stop)
  - [ ] Restart module (systemctl restart)
  - [ ] Parse systemctl output to JSON
- [ ] Implement src/services/systemService.js
  - [ ] Get system metrics (CPU, memory, disk, temp)
  - [ ] Execute reboot (with confirmation)
  - [ ] Execute shutdown (with confirmation)
  - [ ] System update (apt-get update/upgrade)
  - [ ] Disk cleanup operations
- [ ] Implement src/services/logService.js
  - [ ] List available log files
  - [ ] Read log file with pagination
  - [ ] Tail log file (last N lines)
  - [ ] Filter logs by date/search term
  - [ ] Sanitize log output
- [ ] Implement src/services/configService.js
  - [ ] List module configurations
  - [ ] Read configuration file
  - [ ] Update configuration (with backup)
  - [ ] Validate configuration changes

### 2.6 Utilities
- [ ] Implement src/utils/commandExecutor.js
  - [ ] Safe subprocess execution
  - [ ] Command whitelist validation
  - [ ] Timeout protection
  - [ ] Error handling
- [ ] Implement src/security/commandValidator.js
  - [ ] Command injection prevention
  - [ ] Whitelist checking
  - [ ] Argument validation
- [ ] Implement src/security/pathValidator.js
  - [ ] Path traversal prevention
  - [ ] Allowed directory checking
  - [ ] Symbolic link protection

### 2.7 Controllers (HTTP Request Handlers)
- [ ] Implement src/controllers/modulesController.js
  - [ ] GET /api/modules (list all)
  - [ ] GET /api/modules/:name (get status)
  - [ ] POST /api/modules/:name/start
  - [ ] POST /api/modules/:name/stop
  - [ ] POST /api/modules/:name/restart
- [ ] Implement src/controllers/systemController.js
  - [ ] GET /api/system/status (metrics)
  - [ ] POST /api/system/reboot
  - [ ] POST /api/system/shutdown
  - [ ] POST /api/system/update
  - [ ] POST /api/system/cleanup
- [ ] Implement src/controllers/logsController.js
  - [ ] GET /api/logs (list files)
  - [ ] GET /api/logs/:module (get logs)
  - [ ] GET /api/logs/:module/tail
- [ ] Implement src/controllers/configController.js
  - [ ] GET /api/config/:module (read config)
  - [ ] PUT /api/config/:module (update config)
- [ ] Implement src/controllers/monitoringController.js
  - [ ] GET /api/monitoring/metrics
  - [ ] GET /api/monitoring/health

### 2.8 Routes
- [ ] Implement src/routes/health.js (public routes)
- [ ] Implement src/routes/modules.js (protected)
- [ ] Implement src/routes/system.js (protected)
- [ ] Implement src/routes/logs.js (protected)
- [ ] Implement src/routes/config.js (protected)
- [ ] Implement src/routes/monitoring.js (protected)
- [ ] Implement src/routes/index.js (route aggregator)

### 2.9 Express Application Setup
- [ ] Implement src/app.js
  - [ ] Configure Helmet security headers
  - [ ] Configure CORS
  - [ ] Configure compression
  - [ ] Configure body parsing (1MB limit)
  - [ ] Mount request logging
  - [ ] Mount security monitoring
  - [ ] Mount IP filtering
  - [ ] Mount global rate limiting
  - [ ] Mount all routes
  - [ ] Mount error handler
- [ ] Validate: `node --check src/app.js`

### 2.10 Server Entry Point
- [ ] Implement server.js
  - [ ] Load environment configuration
  - [ ] Create HTTPS server (or HTTP for dev)
  - [ ] Start server on configured port
  - [ ] Implement graceful shutdown (SIGTERM/SIGINT)
  - [ ] Log startup information
- [ ] Validate: `node --check server.js`

### 2.11 Service File
- [ ] Create management-api.service
  - [ ] Configure Type=simple, User=pi
  - [ ] Configure environment file loading
  - [ ] Configure restart policy (always, 10s)
  - [ ] Configure security hardening
  - [ ] Configure resource limits (200MB RAM, 80% CPU)
- [ ] Validate: systemd-analyze verify management-api.service (after install)

### 2.12 Integration Testing
- [ ] Manual test: Run server locally (npm start)
- [ ] Test: Health endpoint returns 200
- [ ] Test: Protected endpoints require auth
- [ ] Test: Authentication with valid credentials works
- [ ] Test: Rate limiting triggers after threshold
- [ ] Test: Module operations work (list, start, stop)
- [ ] Test: System metrics endpoint returns data
- [ ] Test: Log viewing endpoint works
- [ ] Test: Graceful shutdown works

**Phase 2 Complete:** ____________ Date: __________

---

## Phase 3: Documentation Implementation

**Goal:** Create comprehensive user and developer documentation.

**Skills Used:** `module-design`, `nodejs-backend-development`

**Based on:** DESIGN_ANALYSIS.md (all phases) + implemented code

### 3.1 README.md Creation
- [ ] Create module README with these sections:
  - [ ] Title and brief description
  - [ ] Features list (with WHY each feature is valuable)
  - [ ] Architecture overview
  - [ ] Security features
  - [ ] Prerequisites (Node.js version, system packages)
  - [ ] Installation (automated and manual)
  - [ ] Configuration (all settings documented)
  - [ ] API Reference (all endpoints with examples)
  - [ ] Authentication guide
  - [ ] Usage examples (curl commands)
  - [ ] Service management commands
  - [ ] Troubleshooting guide
  - [ ] Security best practices
  - [ ] Performance tuning for Pi Zero W
  - [ ] Development setup
  - [ ] Testing guide

### 3.2 API Documentation
- [ ] Document all endpoints with:
  - [ ] HTTP method and path
  - [ ] Authentication requirement
  - [ ] Request parameters/body
  - [ ] Response format (success and error)
  - [ ] Example curl commands
  - [ ] Example responses
- [ ] Create API quick reference table

### 3.3 Security Documentation
- [ ] Document authentication setup
- [ ] Document password requirements
- [ ] Document certificate generation
- [ ] Document IP whitelisting
- [ ] Document rate limiting configuration
- [ ] Document audit log format
- [ ] Document security best practices

### 3.4 Code Documentation
- [ ] Add JSDoc comments to all functions
- [ ] Add module-level comments
- [ ] Add inline comments for complex logic
- [ ] Document environment variables
- [ ] Document configuration options

### 3.5 Operational Documentation
- [ ] Document service management (start/stop/restart)
- [ ] Document log viewing (journalctl + file logs)
- [ ] Document backup procedures
- [ ] Document upgrade procedures
- [ ] Document common maintenance tasks

**Phase 3 Complete:** ____________ Date: __________

---

## Phase 4: Setup & Deployment Implementation

**Goal:** Create installation automation and deployment tools.

**Skills Used:** `system-setup`, `module-design`

**Based on:** DESIGN_ANALYSIS.md Phase 3

### 4.1 Create setup.sh Script
- [ ] Implement script structure with functions
- [ ] Implement install() function:
  - [ ] Check prerequisites (root, Node.js >= 16)
  - [ ] Install system dependencies (nodejs, npm, openssl)
  - [ ] Create directory structure
  - [ ] Copy application files to /home/pi/luigi/system/management-api/
  - [ ] Install Node.js dependencies (npm install --production)
  - [ ] Run npm audit
  - [ ] Create configuration directory
  - [ ] Deploy .env file with secure permissions (600)
  - [ ] Prompt for AUTH_PASSWORD (must be 12+ chars)
  - [ ] Generate TLS certificates if not exist
  - [ ] Deploy systemd service file
  - [ ] Reload systemd daemon
  - [ ] Enable and start service
  - [ ] Verify service is running
  - [ ] Display access information
- [ ] Implement uninstall() function:
  - [ ] Stop and disable service
  - [ ] Remove service file
  - [ ] Remove application directory
  - [ ] Ask about configuration removal (y/n)
  - [ ] Ask about log removal (y/n)
  - [ ] Ask about certificate removal (y/n)
  - [ ] Verify clean removal
- [ ] Implement status() function:
  - [ ] Check service status (systemctl status)
  - [ ] Check API health (curl https://localhost:8443/health)
  - [ ] Display configuration location
  - [ ] Display log locations
  - [ ] Show recent log entries
  - [ ] Display access URL
- [ ] Add colored output functions (log_info, log_error, log_warn)
- [ ] Add root privilege checking
- [ ] Add error handling (set -euo pipefail)
- [ ] Validate: `shellcheck setup.sh`

### 4.2 Certificate Generation Script
- [ ] Create scripts/generate-certs.sh
  - [ ] Generate private key (2048-bit RSA)
  - [ ] Generate CSR with appropriate subject
  - [ ] Generate self-signed certificate (365 days)
  - [ ] Set proper permissions (600 key, 644 cert)
  - [ ] Display certificate information
- [ ] Validate: `shellcheck scripts/generate-certs.sh`

### 4.3 Configuration Files
- [ ] Create .env.example
  - [ ] All required environment variables
  - [ ] Comments explaining each variable
  - [ ] Security warnings for sensitive values
  - [ ] Example values (non-sensitive)
- [ ] Create management-api.conf.example
  - [ ] All configuration sections
  - [ ] Default values
  - [ ] Detailed comments

### 4.4 Module Metadata
- [ ] Create module.json
  - [ ] Module name, version, description
  - [ ] Category: "system"
  - [ ] Dependencies: [] (no module dependencies)
  - [ ] Author information

### 4.5 Testing Scripts
- [ ] Create scripts/validate-syntax.sh
  - [ ] Check all JavaScript files
  - [ ] Run shellcheck on all shell scripts
  - [ ] Run npm audit
- [ ] Create scripts/test-api.sh
  - [ ] Test all API endpoints
  - [ ] Test authentication
  - [ ] Test error cases
  - [ ] Display results
- [ ] Create scripts/security-test.sh
  - [ ] Test security controls
  - [ ] Test injection attempts
  - [ ] Test rate limiting
  - [ ] Display results
- [ ] Validate all scripts: `shellcheck scripts/*.sh`

### 4.6 Git Configuration
- [ ] Create/update .gitignore:
  - [ ] node_modules/
  - [ ] .env
  - [ ] *.log
  - [ ] package-lock.json (optional - we'll include it)
  - [ ] certs/*.key

**Phase 4 Complete:** ____________ Date: __________

---

## Phase 5: Final Verification & Integration

**Goal:** Complete testing, verification, and production approval.

**Skills Used:** `module-design`, `nodejs-backend-development`

**Based on:** Complete implementation (Phases 1-4)

### 5.1 Syntax and Security Validation
- [ ] Run `scripts/validate-syntax.sh` - all checks pass
- [ ] Run `npm audit` - no high/critical vulnerabilities
- [ ] Run `shellcheck setup.sh scripts/*.sh` - no errors
- [ ] Run `node --check` on all JavaScript files - no syntax errors

### 5.2 Installation Testing
- [ ] Clean system test: `sudo ./setup.sh install`
- [ ] Verify all files deployed correctly
- [ ] Verify service installed and running
- [ ] Verify certificates generated
- [ ] Verify logs created
- [ ] Test API health endpoint responds

### 5.3 API Functionality Testing
- [ ] Run `scripts/test-api.sh` - all tests pass
- [ ] Test each module management endpoint
- [ ] Test each system control endpoint
- [ ] Test log viewing endpoints
- [ ] Test configuration endpoints
- [ ] Test monitoring endpoints
- [ ] Verify all responses are JSON formatted
- [ ] Verify error handling works correctly

### 5.4 Security Testing
- [ ] Run `scripts/security-test.sh` - all security controls work
- [ ] Verify authentication is required (401 without auth)
- [ ] Verify rate limiting works (429 after limit)
- [ ] Verify command injection blocked
- [ ] Verify path traversal blocked
- [ ] Verify audit logging works
- [ ] Verify HTTPS works (not HTTP)
- [ ] Verify IP filtering works (if configured)

### 5.5 Service Management Testing
- [ ] Test service start: `sudo systemctl start management-api`
- [ ] Test service stop: `sudo systemctl stop management-api`
- [ ] Test service restart: `sudo systemctl restart management-api`
- [ ] Test service enable: `sudo systemctl enable management-api`
- [ ] Test service status: `sudo systemctl status management-api`
- [ ] Test auto-start on boot (reboot and verify)
- [ ] Test auto-restart on failure (kill process, verify restart)
- [ ] Verify logs in journalctl

### 5.6 Performance Testing
- [ ] Monitor CPU usage during operation (should be <20% idle)
- [ ] Monitor memory usage (should be <200MB)
- [ ] Test response times (should be <500ms for status checks)
- [ ] Test concurrent requests (should handle 10 simultaneous)
- [ ] Verify no memory leaks (monitor over 1 hour)

### 5.7 Configuration Testing
- [ ] Test configuration changes via .env file
- [ ] Test service restart applies configuration
- [ ] Test invalid configuration handled gracefully
- [ ] Test missing configuration uses defaults
- [ ] Test configuration validation catches errors

### 5.8 Log Testing
- [ ] Verify application log rotation works
- [ ] Verify audit log rotation works
- [ ] Verify journalctl captures service logs
- [ ] Verify log levels work correctly
- [ ] Verify no sensitive data in logs

### 5.9 Uninstallation Testing
- [ ] Test `./setup.sh status` shows installation
- [ ] Test `sudo ./setup.sh uninstall` removes everything
- [ ] Verify service removed
- [ ] Verify files removed (optional kept if requested)
- [ ] Verify clean state achieved

### 5.10 Luigi System Integration
- [ ] Test installation via root setup.sh (if applicable)
- [ ] Verify module appears in system listing
- [ ] Verify no conflicts with other modules
- [ ] Test module works alongside other Luigi modules
- [ ] Verify system remains stable with API running

### 5.11 Documentation Verification
- [ ] README is complete and accurate
- [ ] All API endpoints documented with examples
- [ ] Configuration options all documented
- [ ] Troubleshooting section covers common issues
- [ ] Security best practices documented
- [ ] Installation instructions work as written

### 5.12 Code Quality Review
- [ ] Code follows Node.js best practices
- [ ] Error handling is comprehensive
- [ ] Security measures implemented correctly
- [ ] Logging is appropriate and useful
- [ ] Comments are clear and helpful
- [ ] No hardcoded secrets or credentials
- [ ] No TODO or FIXME comments remain

### 5.13 Design Review Checklist
- [ ] Implementation matches DESIGN_ANALYSIS Phase 1 requirements
- [ ] Implementation matches DESIGN_ANALYSIS Phase 2 architecture
- [ ] Implementation matches DESIGN_ANALYSIS Phase 3 deployment plan
- [ ] All success criteria from DESIGN_ANALYSIS met
- [ ] No security concerns identified
- [ ] Performance meets requirements
- [ ] Documentation is complete

### 5.14 Final Approval
- [ ] All phases complete (1-5) ✓
- [ ] All tests passed ✓
- [ ] Documentation complete ✓
- [ ] Security verified ✓
- [ ] Performance verified ✓
- [ ] Ready for production deployment ✓

**Phase 5 Complete:** ____________ Date: __________

---

## Implementation Status Summary

### Completion Tracking

| Phase | Description | Status | Completion Date |
|-------|-------------|--------|-----------------|
| 1 | Testing Strategy | Not Started | |
| 2 | Core Implementation | Not Started | |
| 3 | Documentation | Not Started | |
| 4 | Setup & Deployment | Not Started | |
| 5 | Final Verification | Not Started | |

### Deliverables

**Core Application:**
- [ ] server.js (main entry point)
- [ ] src/app.js (Express application)
- [ ] package.json (dependencies)
- [ ] All middleware files (9 files)
- [ ] All controller files (5 files)
- [ ] All service files (4 files)
- [ ] All utility files (3 files)
- [ ] All security files (3 files)
- [ ] All route files (7 files)
- [ ] config/index.js (configuration)

**Total: ~30 JavaScript files + package.json**

**Deployment Files:**
- [ ] setup.sh (installation automation)
- [ ] management-api.service (systemd service)
- [ ] .env.example (environment template)
- [ ] management-api.conf.example (config template)
- [ ] module.json (module metadata)

**Scripts:**
- [ ] scripts/generate-certs.sh
- [ ] scripts/validate-syntax.sh
- [ ] scripts/test-api.sh
- [ ] scripts/security-test.sh

**Documentation:**
- [ ] README.md (comprehensive user guide)
- [ ] DESIGN_ANALYSIS.md (✅ complete)
- [ ] IMPLEMENTATION_PLAN.md (this file)

**Tests:**
- [ ] Syntax validation
- [ ] Security tests
- [ ] API endpoint tests
- [ ] Integration tests

### Risk Assessment

| Risk | Impact | Mitigation | Status |
|------|--------|------------|--------|
| Node.js compatibility issues | Medium | Use Node.js 16.x LTS with known Pi Zero W support | Planned |
| Memory constraints | Medium | Implement strict resource limits, monitor usage | Planned |
| Security vulnerabilities in dependencies | High | Run npm audit, use latest stable versions | Planned |
| Certificate management complexity | Low | Automate generation, document custom cert usage | Planned |
| Performance on single-core CPU | Medium | Optimize for I/O operations, implement caching | Planned |

---

## Notes and Decisions

### Technical Decisions Made
1. **Node.js vs Python**: Chose Node.js for excellent HTTP/REST support and event-driven architecture
2. **HTTP Basic Auth vs JWT**: Chose Basic Auth for simplicity on local network
3. **systemd vs init.d**: Chose systemd for better resource management and monitoring
4. **Winston vs Bunyan**: Chose Winston for better documentation and community support
5. **Express.js vs Fastify**: Chose Express for maturity and middleware ecosystem

### Implementation Priorities
1. **Security First**: All security features (auth, validation, rate limiting) before functionality
2. **TDD Approach**: Tests defined before implementation where possible
3. **Documentation**: Comprehensive docs to prevent support burden
4. **Performance**: Optimize for Raspberry Pi Zero W constraints throughout

### Success Criteria Validation
Based on DESIGN_ANALYSIS.md success criteria, track completion:
- [ ] All Luigi modules can be managed via API
- [ ] System operations execute safely
- [ ] Logs can be retrieved with filtering
- [ ] Configurations can be managed
- [ ] System metrics exposed
- [ ] Authentication works
- [ ] All operations audited
- [ ] Rate limiting prevents DoS
- [ ] HTTPS enabled
- [ ] Service auto-starts and auto-restarts
- [ ] Response times acceptable
- [ ] Documentation complete
- [ ] Security audit passed

---

## Implementation Plan Complete

**Status:** Ready for Phase 1 execution

**Next Action:** Begin Phase 1 - Testing Strategy Implementation

