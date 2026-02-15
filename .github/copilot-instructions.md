# Luigi Repository - Copilot Agent Instructions

## Project Overview

**Luigi** is a Python-based motion detection system designed for Raspberry Pi Zero W. It uses PIR (Passive Infrared) sensors to detect motion and plays random sound effects via GPIO control. The project is currently **basic and intentionally simple**, with plans for future improvements and expansion.

**Current State:** The repository contains a single sample motion detection module (Mario) as a proof of concept. **Future development will expand functionality to add new modules** - either for different motion detection behaviors, environmental monitoring, automation, or entirely different hardware interaction use cases. The project structure is designed to be extensible and modular.

**Key Information:**
- **Primary Language:** Python (currently Python 2.x compatible, shebang: `#!/usr/bin/python`)
- **Target Platform:** Raspberry Pi Zero W running Raspberry Pi OS
- **Hardware:** PIR motion sensor on GPIO pin 23, audio output via ALSA
- **Size:** Small repository (~1.4MB total, mainly due to sound archive)
- **Structure:** Simple flat structure with one component; designed to grow

## Agent Skills Available

This repository includes **Agent Skills** that provide specialized guidance for common tasks. Copilot will automatically load these skills when relevant to your work.

### Development Skill (PRIMARY)

**Location:** `.github/skills/development/`

**Use when:**
- Starting any Luigi development task (module, feature, fix, enhancement)
- Planning complete development workflow from design to deployment
- Determining which specialized skills to use and in what order
- Understanding how different skills complement each other
- Making architectural or design decisions
- Following Luigi development best practices
- Working with agentic (AI-assisted) software development patterns

**Provides:**
- **Complete 7-phase development workflow** (Requirements → Design → Planning → Implementation → Testing → Documentation → Deployment)
- Integration guide for all specialized skills
- Agentic software development best practices
- Quick reference for common scenarios
- Success criteria and quality standards
- Phase-by-phase guidance with clear deliverables

**Key Phases:**
1. Requirements Analysis and Design
2. Implementation Planning
3. Implementation (Python/Node.js/Shell/React)
4. Testing and Validation
5. Documentation
6. Deployment and Integration
7. Maintenance and Evolution

**Note:** This is the **primary orchestration skill** that integrates all other skills below. Use it as your starting point for any development task, then follow its guidance to invoke specialized skills as needed.

---

### Module Design Skill

**Location:** `.github/skills/module-design/`

**Use when:**
- Designing a new Luigi module BEFORE implementation
- Planning hardware integration and component selection
- Evaluating GPIO pin assignments and wiring safety
- Architecting module structure and configuration
- Creating wiring diagrams and documentation structure
- Reviewing module designs before implementation
- Ensuring safe hardware connections and proper setup

**Provides:**
- Module design philosophy and principles
- Hardware design guidelines and safety checklists
- GPIO pin assignment strategies
- Wiring design and safety verification
- Software architecture patterns
- Configuration design standards
- Service integration design
- Setup script design patterns
- Testing strategy planning
- Documentation structure requirements
- Security design considerations
- Design review checklists and templates

### Shell Scripting Skill

**Location:** `.github/skills/shell-scripting/`

**Use when:**
- Creating or modifying shell scripts (setup.sh, installation scripts, utilities)
- Writing command-line tools for Luigi modules
- Debugging shell script issues
- Implementing service management scripts
- Creating test scripts for shell validation
- Working with bash patterns, arrays, or JSON parsing

**Provides:**
- Luigi shell scripting standards and templates
- **Shared setup helper library** (`util/setup-helpers.sh`) with common functions
- Standard logging functions and color output patterns
- Argument parsing and command-line interface patterns
- Package management with module.json integration
- Service management with systemd
- Configuration file handling (INI-style config parsing)
- File operations with error handling
- User input and prompt patterns
- Security considerations (input validation, credential handling)
- Advanced patterns (JSON with jq, arrays, string manipulation)
- Testing patterns and shellcheck validation
- Complete example setup script demonstrating best practices

**Important:** All module setup scripts MUST source `util/setup-helpers.sh` to use shared logging, package management, and utility functions.

### System Setup Skill

**Location:** `.github/skills/system-setup/`

**Use when:**
- Creating automation scripts to deploy the Luigi application
- Generating deployment scripts for dependencies and services
- Writing scripts to install and configure Luigi modules
- Automating service setup and management
- Creating update or maintenance scripts
- Building troubleshooting or verification scripts

**Provides:**
- Deployment script templates and patterns
- Service integration examples (init.d and systemd)
- Dependency installation scripts
- File deployment patterns
- Script generation best practices
- Multi-module deployment patterns
- System command reference

### Raspberry Pi Zero W Hardware Skill

**Location:** `.github/skills/raspi-zero-w/`

**Use when:**
- Working with GPIO pins and sensors
- Setting up or configuring Raspberry Pi Zero W hardware
- Implementing hardware interfaces (PIR sensors, buttons, LEDs, etc.)
- Debugging hardware connectivity issues
- Planning hardware wiring and connections

**Provides:**
- Complete GPIO pinout reference (40-pin header)
- Hardware wiring diagrams and safety guidelines
- PIR sensor setup instructions
- Audio configuration
- Troubleshooting guides for hardware issues
- Best practices for hardware projects

### Python Development Skill

**Location:** `.github/skills/python-development/`

**Use when:**
- Developing new Python code for GPIO or hardware interactions
- Debugging hardware-related Python applications
- Improving existing hardware control code
- Structuring Python projects for embedded systems
- Planning testing strategies for hardware-dependent code
- Deploying Python applications to Raspberry Pi

**Provides:**
- Code structure best practices and patterns
- Hardware abstraction layer examples
- Error handling and logging patterns
- Mock GPIO for development without hardware
- Testing strategies (syntax validation, unit tests, integration tests)
- Development workflow (local development → deployment)
- Complete example application demonstrating best practices

### Node.js Backend Development Skill

**Location:** `.github/skills/nodejs-backend-development/`

**Use when:**
- Developing Node.js backend APIs for Raspberry Pi Zero W
- Creating REST/HTTP services that interact with hardware
- Building IoT backend services with GPIO control exposed via API
- Implementing secure web APIs for sensor data and hardware control
- Deploying Node.js servers on local networks
- Integrating Express.js with hardware interactions

**Provides:**
- Node.js environment setup for Raspberry Pi Zero W
- HTTP Basic Authentication implementation (simple, secure for local networks)
- Express.js REST API patterns with GPIO integration
- Hardware abstraction layer for Node.js
- Input validation and rate limiting
- HTTPS/TLS configuration for secure communication
- Network security (firewall, IP filtering)
- GPIO safety and pin validation
- Performance optimization for resource-constrained devices
- Complete example backend application

### Web-Frontend Development Skill

**Location:** `.github/skills/web-frontend-development/`

**Use when:**
- Developing web-based user interfaces or dashboards
- Creating responsive, mobile-first web applications
- Building single-page applications (SPAs)
- Implementing progressive web apps (PWAs)
- Integrating frontend with backend APIs
- Optimizing web application performance
- Ensuring cross-browser compatibility (Chrome, Edge, Firefox - MANDATORY)
- Setting up modern build tooling and workflows

**Provides:**
- Modern tech stack (React, Vue, TypeScript, Vite)
- Cross-browser support requirements (Chrome, Edge, Firefox)
- Component development patterns (React, Vue, Web Components)
- State management solutions (Context, Zustand, Redux)
- API integration (Fetch, React Query, WebSocket)
- Responsive design patterns (mobile-first, CSS Grid, container queries)
- Performance optimization (code splitting, lazy loading, memoization)
- Security best practices (XSS prevention, CSP, authentication)
- Testing strategies (Vitest, Playwright, cross-browser E2E)
- Build and deployment (Vite, PWA, Docker, nginx)
- Complete React + TypeScript example application

### Documentation Skill

**Location:** `.github/skills/documentation/`

**Use when:**
- Creating documentation for a new Luigi module
- Updating existing module documentation
- Updating the main project README to include new modules
- Creating API documentation for backend services
- Writing technical guides or troubleshooting documentation
- Establishing documentation structure for new features
- Reviewing documentation for completeness and clarity

**Provides:**
- Luigi documentation philosophy and standards
- Main project README structure and best practices
- Module README template and structure
- API documentation patterns (interface contracts)
- Hardware documentation examples (wiring, GPIO, components)
- Configuration documentation patterns
- Troubleshooting section templates
- Integration documentation (MQTT, Home Assistant)
- Service management documentation
- Complete examples and patterns for all documentation types
- Documentation review checklist

**Key Principles:**
- **Single Source of Truth** - Each module has ONE primary README
- **Self-Contained** - Module READMEs should be complete and standalone
- **User-Focused** - Write for end users installing and using the system
- **Examples-First** - Show practical examples before explaining theory
- **Maintenance-Friendly** - Keep documentation close to code it describes

**Special Cases:**
- **API Documentation** - Separate `docs/API.md` for backend/frontend interface contracts
- **Technical Guides** - Standalone documents for complex topics (e.g., `UNINSTALL_GUIDE.md`)
- **Category READMEs** - Optional overviews for module categories

### Module Management Skill

**Location:** `.github/skills/module-management/`

**Use when:**
- Installing new Luigi modules on a system
- Updating existing modules to new versions
- Removing or uninstalling modules
- Managing module dependencies
- Working with the centralized module registry (`/etc/luigi/modules/`)
- Tracking module versions and deployment status
- Querying which modules are installed on a system
- Resolving module conflicts or issues
- Implementing module management tools or APIs
- Creating automated module deployment scripts

**Provides:**
- Centralized module registry architecture and design
- Registry entry format and schema (`/etc/luigi/modules/*.json`)
- Module lifecycle management (install, update, remove)
- Dependency resolution algorithms
- Version management and comparison
- Module status tracking (active, installed, failed, removed)
- Registry maintenance utilities
- Integration patterns for management-api
- Best practices for module management
- Complete utility script examples
- Migration guide for existing installations

**Note:** These skills work together across the complete development lifecycle:

**The `development` skill** serves as the **primary orchestration skill** that:
- Provides the **complete 7-phase development workflow** from requirements to deployment
- Guides you on **which specialized skills to use and when**
- Integrates **all skills below into a cohesive workflow**
- Includes **agentic software development best practices**
- Offers **quick reference for common scenarios**

**Specialized skills** provide deep expertise for specific tasks:
- The `module-design` skill guides you through the **design phase** before implementation
- The `module-management` skill shows **how to manage module lifecycles** (install, update, remove)
- The `documentation` skill defines **documentation standards** for all modules and the main README
- The `shell-scripting` skill provides **shell scripting standards** for setup scripts, CLI tools, and automation
- The `raspi-zero-w` skill provides **hardware details** for wiring and GPIO during design and implementation
- The `python-development` skill shows **code patterns** for implementing modules in Python
- The `nodejs-backend-development` skill shows **how to create backend APIs** for hardware control
- The `web-frontend-development` skill shows **how to build modern web UIs** that interact with backend APIs
- The `system-setup` skill helps create **deployment automation** for the finished module

**Together they provide complete guidance:** Use the `development` skill as your starting point to understand the workflow, then follow its phase-based guidance to invoke specialized skills as needed for design → implementation (Python/Node.js/Shell/React) → testing → documentation → deployment → management of any Luigi module type.

## Repository Structure

```
luigi/
├── .github/
│   ├── copilot-instructions.md     # This file
│   └── skills/                      # Agent Skills for specialized guidance
│       ├── development/             # PRIMARY: Complete workflow orchestration
│       │   ├── SKILL.md             # Main workflow skill (7 phases)
│       │   └── README.md            # Skill overview
│       ├── documentation/           # Documentation standards and templates
│       │   ├── SKILL.md             # Main documentation skill
│       │   ├── documentation-patterns.md  # Detailed examples and patterns
│       │   ├── module-readme-template.md  # Module README template
│       │   └── README.md            # Skill overview
│       ├── module-design/           # Module design guidance (PRE-implementation)
│       │   ├── SKILL.md             # Main design skill
│       │   ├── hardware-design-checklist.md  # Hardware verification checklist
│       │   ├── design-review-checklist.md    # Complete design review
│       │   └── module-design-template.md     # Module design template
│       ├── module-management/       # Module lifecycle management
│       │   ├── SKILL.md             # Main management skill
│       │   ├── registry-schema.md   # Registry entry format and schema
│       │   └── utility-scripts.md   # Utility script examples
│       ├── shell-scripting/         # Shell scripting standards and patterns
│       │   ├── SKILL.md             # Main skill file
│       │   ├── shell-scripting-patterns.md   # Advanced patterns
│       │   └── example-setup.sh     # Complete example
│       ├── python-development/      # Python development patterns
│       │   ├── SKILL.md             # Main skill file
│       │   ├── python-patterns.md   # Advanced patterns
│       │   └── example_application.py  # Complete example
│       ├── nodejs-backend-development/ # Node.js backend API development
│       │   ├── SKILL.md             # Main skill file
│       │   ├── nodejs-patterns.md   # Advanced patterns
│       │   ├── nodejs-backend-example.js # Complete example
│       │   └── package-example.json # Example dependencies
│       ├── raspi-zero-w/            # Raspberry Pi hardware guidance
│       │   ├── SKILL.md             # Main skill file
│       │   ├── gpio-pinout.md       # GPIO reference
│       │   └── wiring-diagram.md    # Hardware wiring
│       ├── system-setup/            # System setup and configuration
│       │   ├── SKILL.md             # Main skill file
│       │   └── system-reference.md  # System commands reference
│       └── web-frontend-development/ # Modern web UI development
│           ├── SKILL.md             # Main skill file
│           └── ...                  # Additional resources
├── .gitignore                       # Python, IDE, and OS exclusions
├── README.md                        # Main project documentation
├── motion-detection/                # Motion detection components
│   ├── README.md                    # Component overview
│   └── mario/                       # Mario-themed motion detector
│       ├── README.md                # Component-specific docs
│       ├── mario                    # POSIX shell init.d service script
│       ├── mario.py                 # Main Python motion detection script
│       └── mario-sounds.tar.gz      # Audio files (10 WAV files, ~1.3MB)
├── iot/                             # IoT integration modules
│   └── ha-mqtt/                     # Home Assistant MQTT integration
│       ├── README.md                # User documentation
│       ├── setup.sh                 # Installation script
│       ├── bin/                     # Command-line tools
│       ├── lib/                     # Shared libraries
│       ├── config/                  # Configuration templates
│       ├── examples/                # Integration examples
│       └── tests/                   # Test infrastructure
└── system/                          # System-level modules
    ├── optimization/                # System optimization
    └── management-api/              # Web-based management interface
        ├── README.md                # User documentation
        ├── setup.sh                 # Installation script
        ├── server.js                # Express.js server entry point
        ├── docs/
        │   └── API.md               # Complete REST API documentation
        ├── src/                     # Backend source code
        │   ├── routes/              # API route handlers
        │   ├── controllers/         # Request controllers
        │   ├── services/            # Business logic (moduleService, registryService, etc.)
        │   ├── middleware/          # Auth, validation, rate limiting
        │   └── utils/               # Utilities and helpers
        └── frontend/                # React + TypeScript frontend
            ├── src/
            │   ├── pages/           # Page components (Dashboard, Modules, etc.)
            │   ├── components/      # Reusable UI components
            │   ├── services/        # API service layer
            │   └── types/           # TypeScript type definitions
            └── package.json         # Frontend dependencies
```

**Key Files:**
- **mario.py:** Core logic - GPIO setup, motion detection callback, cooldown management, sound playback
- **mario:** Init.d service script for system daemon control (start/stop)
- **mario-sounds.tar.gz:** Contains 10 WAV files (callingmario1.wav through callingmario10.wav)

## Management-API Module

**Location:** `system/management-api/`

The management-api provides a web-based interface for managing Luigi modules and system operations. It serves as a reference implementation for Node.js backend development with React frontend.

### Backend API Documentation

**Location:** `system/management-api/docs/API.md`

This document is the **single source of truth** for the management-api interface contract. It provides:

- **Complete endpoint reference** - All available REST API endpoints
- **Request/response schemas** - Detailed structure with TypeScript types
- **Authentication** - HTTP Basic Auth requirements
- **Error handling** - Standard error responses and status codes
- **Module registry integration** - Read-only access to `/etc/luigi/modules/`
- **Examples** - curl and JavaScript/TypeScript usage examples

**When working with management-api:**
1. **Backend changes:** Update `docs/API.md` to reflect any API modifications
2. **Frontend integration:** Reference `docs/API.md` for correct endpoint usage and response types
3. **New endpoints:** Document in `docs/API.md` following existing patterns

### Key API Endpoints

**Module Management:**
- `GET /api/modules` - List all modules with registry data
- `GET /api/modules/:name` - Get specific module status
- `POST /api/modules/:name/start|stop|restart` - Control module services

**Module Registry (Read-Only):**
- `GET /api/registry` - List all registry entries with statistics
- `GET /api/registry/:modulePath(*)` - Get specific registry entry

**System Operations:**
- `GET /api/system/status` - System metrics (CPU, memory, disk, uptime)
- `POST /api/system/reboot|shutdown|update|cleanup` - System operations

**Configuration:**
- `GET /api/config` - List all config files
- `GET /api/config/:module(*)` - Read config file
- `PUT /api/config/:module(*)` - Update config file

**Logs:**
- `GET /api/logs` - List log files
- `GET /api/logs/:module` - Read module logs with filtering

**Monitoring:**
- `GET /health` - Health check (no auth required)
- `GET /api/monitoring/metrics` - Detailed metrics

See `system/management-api/docs/API.md` for complete documentation with examples and schemas.

## Build, Test, and Validation

### Python Syntax Validation

**ALWAYS validate Python files after making changes:**

```bash
python3 -m py_compile motion-detection/mario/mario.py
```

This command checks syntax without execution. **Exit code 0 = success, no output expected.**

### Shell Script Validation

**ALWAYS validate shell scripts using shellcheck:**

```bash
shellcheck motion-detection/mario/mario
shellcheck iot/ha-mqtt/bin/luigi-publish
shellcheck iot/ha-mqtt/bin/luigi-discover
shellcheck iot/ha-mqtt/bin/luigi-mqtt-status
```

**Exit code 0 = success, no output expected.** Shellcheck is available in the environment.

**ha-mqtt Testing:**
The ha-mqtt module includes comprehensive test infrastructure:
```bash
# Run all tests (syntax, functional, integration)
iot/ha-mqtt/tests/run-all-tests.sh

# Run specific test layers
iot/ha-mqtt/tests/syntax/validate-all.sh      # Syntax validation only
iot/ha-mqtt/tests/functional/run-functional-tests.sh  # Functional tests
iot/ha-mqtt/tests/integration/run-integration-tests.sh  # Integration tests with Docker
```

### No Traditional Build Process

**Important:** This project has NO build, compile, or package steps. Changes to Python or shell scripts are immediately usable after syntax validation.

### Testing Infrastructure

**Motion Detection Modules:** No automated tests - validation is syntax-only.

**ha-mqtt Module:** Comprehensive 4-layer test infrastructure:
- Layer 1: Syntax validation (shellcheck)
- Layer 2: Functional tests (without MQTT broker)
- Layer 3: Integration tests (Docker-based with real MQTT broker)
- Layer 4: E2E scenario documentation

See `iot/ha-mqtt/tests/README.md` for complete testing documentation.

**When adding tests to other modules:**
- Follow shell script patterns (see ha-mqtt/tests/ as reference)
- Use shellcheck for syntax validation
- Create functional tests that work without hardware when possible
- Place tests in a `tests/` directory within the module
- Document test execution commands clearly
- Consider Docker-based integration tests for complex scenarios

### No CI/CD Workflows

**No GitHub Actions or CI pipelines exist.** There are no `.github/workflows/` files. Validation is manual only.

## Development Guidelines

### Making Changes to Python Files

1. **Edit the file** using standard Python syntax
2. **Validate syntax immediately:**
   ```bash
   python3 -m py_compile motion-detection/mario/mario.py
   ```
3. **Expected result:** Exit code 0, no output
4. **On error:** Fix syntax issues before committing

### Making Changes to Shell Scripts

1. **Edit the file** (POSIX shell syntax)
2. **Validate with shellcheck:**
   ```bash
   shellcheck motion-detection/mario/mario
   ```
3. **Expected result:** Exit code 0, no output
4. **On error:** Fix issues reported by shellcheck

### Python Version Compatibility

- **Shebang:** Scripts use `#!/usr/bin/python` (points to Python 2.x on Raspberry Pi OS)
- **Development Environment:** Python 3.x is available (`python3`)
- **Target Environment:** Raspberry Pi OS typically has both Python 2.x and 3.x
- **Compatibility Note:** Current code is Python 2.x compatible but runs on Python 3.x

**When writing new code:** Prefer Python 3.x syntax but test compatibility if targeting Raspberry Pi.

### Dependencies

**Runtime Dependencies (on Raspberry Pi):**
- `python-rpi.gpio` or `python3-rpi.gpio` - GPIO control library
- `alsa-utils` - Audio playback (`aplay` command)
- `mosquitto-clients` - MQTT client tools (required for ha-mqtt module)
- `jq` - JSON processing (required for ha-mqtt module)

**Installation commands:**
```bash
# Core dependencies
sudo apt-get update && sudo apt-get install python3-rpi.gpio alsa-utils

# ha-mqtt dependencies
sudo apt-get install mosquitto-clients jq
```

**Note:** RPi.GPIO does NOT work in standard Linux environments without Raspberry Pi hardware. Do not attempt to run modules outside of a Raspberry Pi or emulated environment.

### Code Style

**No linters or formatters are configured.** Follow these conventions observed in the existing code:

- **Indentation:** 4 spaces (not tabs)
- **Naming:** snake_case for variables and functions, UPPER_CASE for constants
- **String quotes:** Single quotes preferred
- **Line length:** No strict limit, keep reasonable (~80-100 characters)
- **Comments:** Minimal; only where necessary
- **Imports:** Standard library first, then third-party (RPi.GPIO)

### Adding New Components

The project is designed for extensibility. When adding new modules (whether for motion detection, environmental monitoring, automation, or other hardware interactions):

1. **Create subdirectory** under appropriate category (e.g., `motion-detection/`, `sensors/`, `automation/`)
2. **Include README.md** documenting purpose, hardware requirements, setup, configuration, and usage
3. **Document GPIO pins** and any hardware connections required
4. **Follow existing patterns:** 
   - Python script structure (GPIO setup, callbacks, cleanup)
   - Service script structure (init.d or systemd)
   - Stop file mechanism for graceful shutdown
   - Logging to `/var/log/luigi/`
   - Configuration via constants or config files
5. **Update parent READMEs** to reference new component
6. **Consider modularity:** Make components independent when possible, shared libraries when needed
7. **Consider IoT integration:** For sensor modules, integrate with Home Assistant via ha-mqtt (see below)

### Service User Convention

**CRITICAL: All services MUST run as dedicated system users, NEVER as root.**

This is a mandatory security requirement for all Luigi modules with service capability.

**User Naming Convention:**
- Format: `luigi-{module-name}`
- Examples: `luigi-mario`, `luigi-sysinfo`, `luigi-api`

**Group Membership:**
- **REQUIRED:** All service users MUST be members of `luigi` group (for shared file access)
- **OPTIONAL:** Add hardware groups as needed: `gpio`, `spi`, `i2c`

**User Properties:**
- System user (UID < 1000)
- No password (passwordless)
- Login shell: `/usr/sbin/nologin` (prevents interactive login)
- Home directory: `/var/lib/luigi-{module-name}`

**Implementation:**

In your module's `setup.sh`:
```bash
# Create dedicated service user
create_service_user() {
    log_step "Creating dedicated service user..."
    
    # Args: username, description, home_dir, additional_groups
    create_service_user "luigi-mario" \
                        "Mario Motion Detection Service" \
                        "/var/lib/luigi-mario" \
                        "gpio" || {
        log_error "Failed to create service user"
        exit 1
    }
    
    log_success "Service user created and configured"
}

install() {
    check_root
    check_files
    install_dependencies
    create_service_user      # Create user BEFORE installing files
    install_script
    install_config
    install_service
    start_service
}
```

In your systemd service file:
```ini
[Service]
Type=simple
# Service runs as dedicated user (member of luigi + hardware groups)
User=luigi-mario
Group=luigi-mario
# User has GPIO access via gpio group membership (no root needed)
```

**Security Benefits:**
- ✅ Principle of least privilege - only necessary permissions
- ✅ Process isolation - each module has dedicated user
- ✅ Contained security breaches - limited blast radius
- ✅ No unnecessary root access
- ✅ Shared file access via luigi group membership
- ✅ Hardware access via group membership (gpio, spi, i2c) instead of root

**Helper Function:**

The `create_service_user()` helper function is provided in `util/setup-helpers.sh`:
- Creates system user if it doesn't exist
- Adds user to luigi group automatically
- Optionally adds user to hardware groups (gpio, spi, i2c)
- Creates home directory with proper permissions
- Handles idempotent installation (safe to run multiple times)

See `.github/skills/shell-scripting/SKILL.md` for complete documentation.

### Integrating Modules with Home Assistant (ha-mqtt)

**When to use iot/ha-mqtt:**
- Your module generates sensor data (temperature, humidity, motion, door state, etc.)
- You want to view sensor data in Home Assistant dashboards
- You want to create automations based on sensor readings
- You want centralized monitoring of multiple Luigi sensors

**Zero-Coupling Integration Pattern:**

The ha-mqtt module provides a generic interface that allows **any Luigi module to publish sensor data** without modifying ha-mqtt code. Integration is a 4-step process:

1. **Create a sensor descriptor** - JSON file describing your sensor:
   ```json
   {
     "sensor_id": "mario_motion",
     "name": "Mario Motion Sensor",
     "module": "motion-detection/mario",
     "device_class": "motion",
     "icon": "mdi:motion-sensor"
   }
   ```

2. **Install descriptor** to `/etc/luigi/iot/ha-mqtt/sensors.d/mario_motion.json`

3. **Run discovery once** to register sensor in Home Assistant:
   ```bash
   sudo /usr/local/bin/luigi-discover
   ```

4. **Publish sensor values** from your module code:
   ```bash
   /usr/local/bin/luigi-publish --sensor mario_motion --value ON --binary
   ```

**Key Benefits:**
- **Zero modifications to ha-mqtt** - No code changes needed in the ha-mqtt module
- **Self-registration** - Sensors automatically appear in Home Assistant
- **Generic interface** - Single `luigi-publish` command works for all sensor types
- **Module independence** - ha-mqtt is optional; modules work standalone

**Implementation Guidelines:**
- Call `luigi-publish` from your module's Python code using `subprocess.run()`
- Use `--binary` flag for ON/OFF sensors (motion, door, button)
- Omit `--binary` for measurement sensors (temperature, humidity, light)
- Include `--unit` for measurement sensors (e.g., `--unit "°C"`)
- Handle MQTT connection failures gracefully (log but don't crash)

**Documentation References:**
- **Full integration guide:** `iot/ha-mqtt/examples/integration-guide.md`
- **Sensor descriptor format:** `iot/ha-mqtt/examples/sensors.d/README.md`
- **Command reference:** `iot/ha-mqtt/README.md`
- **Testing:** `iot/ha-mqtt/tests/` contains comprehensive test infrastructure

**Example Integration (Motion Detection):**
```python
import subprocess

def publish_motion_detected():
    """Publish motion event to Home Assistant via MQTT."""
    try:
        subprocess.run([
            '/usr/local/bin/luigi-publish',
            '--sensor', 'mario_motion',
            '--value', 'ON',
            '--binary'
        ], check=True, timeout=5)
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
        # Log but don't crash - module should work without MQTT
        logger.warning(f"Failed to publish MQTT: {e}")
```

### File Organization

- **Configuration:** Config files in `/etc/luigi/{module-path}/` (e.g., `/etc/luigi/motion-detection/mario/mario.conf`)
  - For modules under `motion-detection/mario/`, config path is `/etc/luigi/motion-detection/mario/`
  - For modules under `sensors/temp/`, config path is `/etc/luigi/sensors/temp/`
  - Config files should use `.conf` extension with INI or key=value format
  - Legacy modules may still use hardcoded constants (transitioning to config files)
- **Logs:** Written to `/var/log/luigi/{module-name}.log` on Raspberry Pi
- **Temp files:** Use `/tmp/` for runtime state (e.g., `/tmp/stop_mario`, `/tmp/mario_timer`)
- **Sound files:** Install to `/usr/share/sounds/mario/` on target system
- **Module resources:** Install to `/usr/share/{module-name}/` on target system

## Hardware-Specific Notes

**This code is designed for Raspberry Pi hardware:**
- GPIO pin access requires physical hardware or emulation
- Audio playback uses ALSA (`aplay` command)
- Service scripts use init.d (sysvinit style)

**Do NOT attempt to execute mario.py** in development environments without proper setup. Validation is syntax-only.

## Common Pitfalls and Workarounds

### Import Errors (RPi.GPIO)

**Problem:** `import RPi.GPIO` fails in non-Raspberry Pi environments.

**Solution:** This is expected. Only validate syntax with `python3 -m py_compile`. Do NOT run the script.

### No Testing Infrastructure

**Problem:** Cannot test changes functionally without hardware.

**Solution:** Focus on syntax validation and code review. Functional testing requires Raspberry Pi hardware.

### Python 2 vs Python 3

**Problem:** Shebang points to Python 2 but development uses Python 3.

**Solution:** Code is currently compatible with both. When making changes:
- Test syntax with `python3 -m py_compile`
- Avoid Python 3-only features unless explicitly updating for Python 3

### File Paths for Development

**Problem:** Hardcoded paths like `/usr/share/sounds/mario/` don't exist in dev environment.

**Solution:** Paths are for target Raspberry Pi deployment. For new modules, consider using configurable paths or environment variables for better flexibility.

## Project Expansion Guidelines

**This project is intentionally basic and designed for extensibility.** The current implementation (Mario motion detection) is a proof of concept. The architecture supports:

**Adding New Modules:**
1. **Motion Detection Variants:** Different sound effects, behaviors, cooldown strategies
2. **Environmental Monitoring:** Temperature, humidity, light sensors
3. **Automation:** Relay control, motor control, LED patterns
4. **Security:** Door/window sensors, cameras, alerts
5. **IoT Integration:** MQTT, webhooks, cloud services

**When Contributing:**
1. **Maintain simplicity:** Keep the barrier to entry low for embedded/IoT projects
2. **Document thoroughly:** Each component should have clear README with setup steps
3. **Preserve existing functionality:** Existing modules should continue to work
4. **Consider modularity:** Design new features as separate, independent modules
5. **Use standard patterns:** Follow GPIO setup, cleanup, logging conventions from existing code
6. **Hardware compatibility:** Test on actual Raspberry Pi hardware when possible
7. **Generalize when useful:** Create shared libraries for common operations

**Configuration Standard:**
All modules MUST be configured via config files in `/etc/luigi/{module-path}/`:
- Path structure matches repository structure: `/etc/luigi/motion-detection/mario/` for `motion-detection/mario/` module
- Use simple `.conf` files with key=value format (INI-style) for ease of editing
- Python modules should read config on startup with fallback to defaults
- Example: `/etc/luigi/motion-detection/mario/mario.conf` contains `GPIO_PIN=23`, `COOLDOWN_SECONDS=1800`

**Potential Improvements (Applicable to All Modules):**
- Web interface for remote monitoring/control
- Multiple sensor support per module
- Integration with home automation platforms (Home Assistant, OpenHAB)
- Enhanced logging and statistics
- Proper Python package structure (setup.py, requirements.txt)
- Module dependency management
- Plugin architecture for dynamic module loading

## Quick Reference Commands

### Validation (ALWAYS run after changes)
```bash
# Python syntax
python3 -m py_compile motion-detection/mario/mario.py

# Shell script
shellcheck motion-detection/mario/mario
```

### File Inspection
```bash
# View main Python script
cat motion-detection/mario/mario.py

# View init.d script
cat motion-detection/mario/mario

# List sound files in archive
tar -tzf motion-detection/mario/mario-sounds.tar.gz
```

### Repository Status
```bash
# Check git status
git status

# View current branch
git branch --show-current

# Show uncommitted changes
git diff
```

## Critical Instructions for Agents

1. **ALWAYS validate Python syntax** with `python3 -m py_compile` after editing `.py` files
2. **ALWAYS validate shell scripts** with `shellcheck` after editing shell scripts
3. **DO NOT attempt to run mario.py** - it requires Raspberry Pi hardware
4. **DO NOT attempt to run tests** - no test infrastructure exists yet
5. **DO NOT assume CI/CD exists** - no automated validation pipelines are configured
6. **DO add .gitignore entries** for Python artifacts (__pycache__, *.pyc)
7. **FOCUS on syntax correctness** - functional testing requires target hardware
8. **READ all three README.md files** before making structural changes
9. **PRESERVE the simple structure** - avoid over-engineering improvements
10. **DOCUMENT all changes thoroughly** in README files

## Trust These Instructions

These instructions have been validated through exploration and testing. **Only perform additional searches if:**
- Information here is incomplete for your specific task
- You encounter errors not described in this document
- You need to understand code logic in detail beyond structural overview

For most code changes, **syntax validation is sufficient**. Save exploration time by following the validation commands documented above.

### When to Use Agent Skills

**Copilot will automatically load relevant skills** based on your task, but you can also reference them directly:
- For module documentation → Use `.github/skills/documentation/`
- For hardware setup and wiring questions → Use `.github/skills/raspi-zero-w/`
- For Python code development patterns → Use `.github/skills/python-development/`

The skills provide deeper, specialized guidance beyond these general instructions.
