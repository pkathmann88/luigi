# Node.js Backend Development Skill

This Agent Skill provides comprehensive guidance for developing **secure** Node.js backend applications on Raspberry Pi Zero W that provide REST APIs and interact with GPIO hardware.

## What's Included

### 📘 SKILL.md (2,278 lines)
The main skill file with comprehensive documentation covering:

- **Node.js Environment Setup** - Installation and configuration for Raspberry Pi Zero W
- **HTTP Basic Authentication** - Simple, secure authentication for local networks
- **Express.js REST API** - Complete API server implementation with GPIO control
- **Security Best Practices** - Input validation, rate limiting, HTTPS, audit logging
- **GPIO Integration** - Hardware abstraction layer with safety validation
- **Network Security** - Firewall configuration, IP filtering, local network isolation
- **Performance Optimization** - Memory management and resource optimization for 512MB RAM
- **Deployment Guide** - systemd service configuration and management
- **Testing Strategies** - Security testing and validation
- **Troubleshooting** - Common issues and solutions

### 📄 nodejs-patterns.md (852 lines)
Advanced patterns and examples:

- **WebSocket Integration** - Real-time GPIO updates with Socket.IO
- **Scheduled Tasks** - Periodic operations with node-cron
- **Event-Driven Architecture** - EventEmitter patterns for hardware events
- **Graceful Shutdown** - Comprehensive cleanup handling
- **Error Recovery** - Automatic retry and recovery patterns
- **Database Integration** - SQLite for local data storage
- **API Versioning** - Version-based routing
- **Performance Monitoring** - Request timing and memory tracking
- **Circuit Breaker Pattern** - Fault tolerance implementation

### 💻 nodejs-backend-example.js (300+ lines)
A complete, working example application demonstrating:

- HTTP Basic Authentication with proper security
- GPIO control via REST API endpoints
- Input validation on all routes
- Rate limiting to prevent abuse
- Error handling and logging
- Mock GPIO support for development without hardware
- Graceful shutdown handling

**Run the example:**
```bash
npm install express dotenv helmet cors express-rate-limit express-validator winston onoff
node nodejs-backend-example.js
```

### 📦 package-example.json
Example package.json file with all required dependencies and scripts for a production-ready Node.js API server.

## When to Use This Skill

Use this skill when you need to:

- ✅ Create a REST API for controlling Raspberry Pi GPIO
- ✅ Build a web-based interface for hardware control
- ✅ Expose sensor data via HTTP endpoints
- ✅ Integrate hardware control with web applications
- ✅ Provide remote access to GPIO functionality
- ✅ Build IoT backend services on Raspberry Pi
- ✅ Create secure APIs accessible on local networks

## Key Features

### Security-First Approach

This skill emphasizes security for local network deployments:

- **HTTP Basic Authentication** - Simple username/password authentication
- **HTTPS/TLS Required** - Encrypted communication (even on local network)
- **Rate Limiting** - Multi-layer protection against abuse
- **Input Validation** - Comprehensive validation on all inputs
- **GPIO Safety** - Pin validation to prevent hardware damage
- **Audit Logging** - Security event tracking
- **IP Filtering** - Network access controls

### Performance Optimized

Designed specifically for Raspberry Pi Zero W's constraints:

- Memory-efficient patterns for 512MB RAM
- Request timeout handling
- Connection limits
- Stream-based operations for large data
- Caching strategies
- Resource monitoring

### Production Ready

Complete deployment guidance:

- systemd service configuration
- Automatic restart on failure
- Log management
- Certificate generation for HTTPS
- Firewall setup
- Health monitoring

## Quick Start

1. **Read SKILL.md** - Comprehensive guide with all patterns
2. **Review nodejs-patterns.md** - Advanced patterns for specific needs
3. **Run nodejs-backend-example.js** - See it in action
4. **Use package-example.json** - Bootstrap your own project

## Related Skills

This skill works together with other Luigi skills:

- **raspi-zero-w** - Hardware details, GPIO pinout, wiring diagrams
- **python-development** - Alternative implementation language
- **module-design** - Design principles before implementation
- **system-setup** - Deployment automation

## Security Note

⚠️ **HTTPS is required when using Basic Authentication!** Credentials are base64-encoded (not encrypted) and will be visible if transmitted over HTTP. This skill emphasizes HTTPS configuration and certificate generation.

## Example Usage

```bash
# Test health endpoint (public)
curl http://localhost:3000/health

# List GPIO pins (authenticated)
curl http://localhost:3000/api/gpio/pins \
  -u admin:your-password

# Setup output pin
curl http://localhost:3000/api/gpio/setup/output \
  -u admin:your-password \
  -H "Content-Type: application/json" \
  -d '{"pin": 18, "initialValue": 0}'

# Control GPIO pin
curl http://localhost:3000/api/gpio/output/18 \
  -u admin:your-password \
  -H "Content-Type: application/json" \
  -d '{"value": 1}'
```

## Architecture Overview

```
┌─────────────────────────────────────────┐
│         Client (Browser/App)            │
└──────────────┬──────────────────────────┘
               │ HTTPS + Basic Auth
               ▼
┌─────────────────────────────────────────┐
│       Express.js API Server              │
│  ┌──────────────────────────────────┐   │
│  │ Security Middleware              │   │
│  │ - Basic Auth                     │   │
│  │ - Rate Limiting                  │   │
│  │ - Input Validation               │   │
│  │ - IP Filtering                   │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │ REST API Routes                  │   │
│  │ - GET /api/gpio/pins             │   │
│  │ - POST /api/gpio/setup/*         │   │
│  │ - POST /api/gpio/output/:pin     │   │
│  │ - GET /api/gpio/input/:pin       │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │ GPIO Manager                     │   │
│  │ - Hardware abstraction           │   │
│  │ - Pin validation                 │   │
│  │ - Safety checks                  │   │
│  └──────────────────────────────────┘   │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│   Raspberry Pi GPIO Hardware            │
│   (LEDs, Sensors, Relays, etc.)         │
└─────────────────────────────────────────┘
```

## File Sizes

- SKILL.md: ~60KB (2,278 lines)
- nodejs-patterns.md: ~20KB (852 lines)
- nodejs-backend-example.js: ~10KB (300+ lines)
- package-example.json: ~1.4KB
- **Total: ~91KB of documentation and examples**

## License

MIT License - Same as the Luigi project

## Contributing

Improvements to this skill are welcome! If you find issues or have suggestions, please contribute to the Luigi project.

---

**Built for Luigi** - A modular IoT platform for Raspberry Pi Zero W
