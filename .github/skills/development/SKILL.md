---
name: development
description: Comprehensive guide for the complete Luigi development workflow. Use this skill as the primary entry point for any Luigi development task, from initial design analysis through implementation to documentation. Encompasses all phases of development and references all specialized skills.
license: MIT
---

# Luigi Development Workflow

This skill provides a **comprehensive guide for the entire Luigi development lifecycle**, serving as the primary orchestration point for all development activities. It encompasses design analysis, implementation planning, coding, testing, documentation, and deployment—integrating guidance from all specialized skills.

## When to Use This Skill

**Use this skill as your PRIMARY REFERENCE when:**
- Starting any new Luigi development task (module, feature, fix, or enhancement)
- Planning the complete development workflow from design to deployment
- Determining which specialized skills to use and in what order
- Understanding how different skills complement each other
- Making architectural or design decisions
- Following Luigi's development best practices
- Working with agentic (AI-assisted) software development patterns

**This skill integrates and orchestrates:**
- Module Design → Python/Node.js/Shell Implementation → Testing → Documentation → Deployment

## Development Philosophy

### Core Principles

Luigi development follows these fundamental principles:

1. **Design Before Implementation**
   - Analyze requirements thoroughly before coding
   - Use module-design skill to validate hardware and architecture
   - Document design decisions and rationale

2. **Modularity and Independence**
   - Each module is self-contained and independently deployable
   - Minimal coupling between modules
   - Clear, well-defined interfaces

3. **Safety and Security**
   - Hardware safety is paramount (prevent component damage)
   - Secure coding practices (input validation, sanitization)
   - Graceful error handling without system crashes

4. **Configuration Over Code**
   - User-modifiable settings in config files
   - Sensible defaults with override capability
   - Clear configuration documentation

5. **Documentation as Code**
   - Documentation lives with the code
   - Keep documentation current with changes
   - Examples-first approach

6. **Testability and Quality**
   - Design for testing without full hardware
   - Validate syntax and structure before deployment
   - Use mock GPIO for development

7. **Maintainability and Clarity**
   - Follow established patterns and conventions
   - Code should be self-documenting
   - Comments explain "why," not "what"

## Complete Development Workflow

The Luigi development lifecycle follows a **structured, phase-based approach** that ensures quality, safety, and maintainability:

### Phase 1: Requirements Analysis and Design

**Objective:** Understand requirements, plan architecture, and validate design before writing code.

**Activities:**
1. **Requirement Gathering**
   - What problem are you solving?
   - Who are the users?
   - What are the success criteria?
   - What are the constraints (hardware, performance, compatibility)?

2. **Design Planning**
   - **Use the module-design skill** (`.github/skills/module-design/`)
   - Select appropriate module category (motion-detection, sensors, automation, iot, system)
   - Plan hardware integration (GPIO pins, sensors, components)
   - Design software architecture (components, responsibilities, interfaces)
   - Plan configuration structure
   - Identify dependencies on other modules

3. **Safety and Security Review**
   - Validate hardware wiring safety
   - Check GPIO pin conflicts
   - Review security implications
   - Plan error handling strategy

4. **Documentation Planning**
   - Plan README structure
   - Identify wiring diagrams needed
   - Plan API documentation if applicable

**Deliverables:**
- Design document or design notes
- Hardware wiring plan
- Module structure outline
- Configuration schema
- Dependency list

**Skills to Use:**
- **module-design** - Primary skill for this phase
- **raspi-zero-w** - Hardware details and GPIO planning
- **documentation** - Planning documentation structure

---

### Phase 2: Implementation Planning

**Objective:** Create detailed implementation plan, select technologies, and set up development environment.

**Activities:**
1. **Technology Selection**
   - Choose implementation language:
     - **Python** - Hardware control, sensors, motion detection
     - **Node.js** - Backend APIs, web services
     - **Shell Scripts** - Setup, deployment, utilities
     - **React/TypeScript** - Web frontends and dashboards
   - Select libraries and dependencies
   - Plan testing approach

2. **Module Structure Setup**
   - Create directory structure
   - Set up module.json with metadata
   - Plan file organization

3. **Development Environment**
   - Set up mock GPIO if developing without hardware
   - Install required tools (shellcheck, python3, node/npm)
   - Configure IDE/editor

4. **Implementation Task Breakdown**
   - Break work into small, testable units
   - Identify critical path
   - Plan incremental development approach

**Deliverables:**
- Implementation checklist
- Module directory structure
- Development environment configured
- Task breakdown with priorities

**Skills to Use:**
- **python-development** - For Python modules
- **nodejs-backend-development** - For Node.js APIs
- **web-frontend-development** - For web UIs
- **shell-scripting** - For setup scripts and CLI tools
- **system-setup** - For deployment planning

---

### Phase 3: Implementation

**Objective:** Write clean, tested, maintainable code following Luigi conventions.

**Activities:**

#### 3.1 Core Application Code

**For Python Modules:**
- Follow patterns from **python-development skill** (`.github/skills/python-development/`)
- Use hardware abstraction layer pattern
- Implement graceful GPIO cleanup
- Add comprehensive error handling
- Use logging (to `/var/log/luigi/`)
- Support configuration files in `/etc/luigi/{module-path}/`

**For Node.js Backend APIs:**
- Follow patterns from **nodejs-backend-development skill** (`.github/skills/nodejs-backend-development/`)
- Implement HTTP Basic Auth for security
- Add input validation and sanitization
- Implement rate limiting
- Use Express.js with middleware pattern
- Document API endpoints in `docs/API.md`

**For Web Frontends:**
- Follow patterns from **web-frontend-development skill** (`.github/skills/web-frontend-development/`)
- Use React + TypeScript
- Ensure cross-browser compatibility (Chrome, Edge, Firefox)
- Implement responsive design
- Add loading states and error handling
- Use modern build tooling (Vite)

**For Shell Scripts:**
- Follow patterns from **shell-scripting skill** (`.github/skills/shell-scripting/`)
- **MUST source `util/setup-helpers.sh`** for shared functions
- Use consistent logging (log_info, log_warn, log_error)
- Validate all inputs
- Use `set -e` for error handling
- Follow POSIX compliance where possible

#### 3.2 Configuration Management

- Create config files in `/etc/luigi/{module-path}/`
- Use `.conf` extension with INI or key=value format
- Provide sensible defaults
- Document all configuration options
- Support runtime configuration reload when feasible

#### 3.3 Service Integration

- Create systemd service unit (`.service` file)
- Configure automatic restart on failure
- Set up proper logging to `/var/log/luigi/`
- Implement graceful shutdown handling
- Test service start/stop/restart

#### 3.4 Setup Script

- Create `setup.sh` following Luigi patterns
- **Source `util/setup-helpers.sh`** for shared functions
- Implement install/uninstall/status modes
- Read dependencies from `module.json`
- Use `read_apt_packages()` for package management
- Update module registry using `update_module_registry_full()`
- Handle rollback on installation failure

**Best Practices:**
- Make small, incremental changes
- Validate syntax frequently (python3 -m py_compile, shellcheck)
- Test each component in isolation
- Use version control effectively (commit often)
- Write self-documenting code
- Add comments only for complex logic

**Skills to Use:**
- **python-development** - Python implementation patterns
- **nodejs-backend-development** - Node.js API patterns
- **web-frontend-development** - React UI patterns
- **shell-scripting** - Setup scripts and utilities
- **raspi-zero-w** - Hardware integration code
- **module-management** - Registry integration

---

### Phase 4: Testing and Validation

**Objective:** Ensure code quality, correctness, and safety before deployment.

**Activities:**

#### 4.1 Syntax Validation

**Python:**
```bash
python3 -m py_compile module.py
```

**Shell Scripts:**
```bash
shellcheck setup.sh
shellcheck bin/utility-script
```

**Node.js/TypeScript:**
```bash
npm run type-check  # TypeScript
npm run lint        # ESLint
```

#### 4.2 Functional Testing

- Test with mock GPIO (if hardware module)
- Test error handling paths
- Test configuration loading and validation
- Test service lifecycle (start/stop/restart)
- Test setup script modes (install/uninstall/status)

#### 4.3 Integration Testing

- Test with actual hardware (if available)
- Test module dependencies
- Test interaction with other modules
- Test MQTT integration (if IoT module)
- Test API endpoints (if backend module)

#### 4.4 Security Review

- Run security checks for new dependencies (gh-advisory-database)
- Validate input sanitization
- Check for command injection vulnerabilities
- Review file permissions and ownership
- Test with malicious inputs

#### 4.5 Cross-Browser Testing (Web UIs only)

- Test in Chrome/Chromium
- Test in Firefox
- Test in Edge
- Test responsive design on mobile
- Verify accessibility

**Deliverables:**
- All syntax checks passing
- Functional tests documented
- Security review completed
- Known issues documented

**Skills to Use:**
- All implementation skills have testing sections
- **python-development** - Python testing strategies
- **nodejs-backend-development** - API testing patterns
- **web-frontend-development** - Frontend testing
- **shell-scripting** - Shell script testing

---

### Phase 5: Documentation

**Objective:** Create comprehensive, user-friendly documentation following Luigi standards.

**Activities:**

#### 5.1 Module README

- **Use documentation skill** (`.github/skills/documentation/`)
- Follow module README template
- Include all required sections:
  - Overview and purpose
  - Features
  - Hardware requirements
  - Installation instructions
  - Configuration
  - Usage
  - Troubleshooting
  - Integration (MQTT, Home Assistant)

#### 5.2 Hardware Documentation

- Create wiring diagrams
- Document GPIO pin assignments
- Include component specifications
- Add safety warnings

#### 5.3 API Documentation (if applicable)

- Create `docs/API.md` for backend APIs
- Document all endpoints
- Include request/response schemas
- Provide curl and code examples
- Document authentication requirements

#### 5.4 Code Documentation

- Add docstrings to Python functions/classes
- Add JSDoc comments to JavaScript/TypeScript
- Document complex algorithms
- Explain non-obvious design decisions

#### 5.5 Main README Update

- Add module to main README.md module table
- Update category descriptions if new category
- Link to module README

**Deliverables:**
- Complete module README
- Wiring diagrams (if hardware)
- API documentation (if backend)
- Main README updated

**Skills to Use:**
- **documentation** - Primary skill for this phase
- **raspi-zero-w** - Hardware wiring diagrams
- **module-design** - Documentation planning

---

### Phase 6: Deployment and Integration

**Objective:** Deploy module to target system and integrate with Luigi platform.

**Activities:**

#### 6.1 Module Registry Integration

- Ensure setup.sh updates module registry
- Use `update_module_registry_full()` from setup-helpers.sh
- Test registry queries via management-api

#### 6.2 Dependency Management

- Document dependencies in module.json
- Test dependency resolution
- Ensure proper installation order

#### 6.3 Service Deployment

- Test service installation
- Verify automatic startup on boot
- Check service logs
- Test service restart on failure

#### 6.4 System Integration

- Test interaction with other modules
- Verify MQTT integration (if IoT module)
- Test Home Assistant discovery (if sensor module)
- Verify management-api integration

#### 6.5 Verification

- Run complete installation via setup.sh
- Verify all files in correct locations
- Check file permissions
- Test uninstall and reinstall
- Document any manual steps required

**Deliverables:**
- Module deployed and running
- Registry entry created
- Service active and logging
- Integration verified

**Skills to Use:**
- **system-setup** - Deployment automation
- **module-management** - Registry integration
- **shell-scripting** - Setup script patterns

---

### Phase 7: Maintenance and Evolution

**Objective:** Keep module updated, fix issues, and evolve functionality.

**Activities:**

#### 7.1 Issue Resolution

- Monitor logs for errors
- Respond to user bug reports
- Prioritize safety and security issues
- Test fixes thoroughly before deployment

#### 7.2 Feature Enhancement

- Follow full workflow for new features
- Maintain backward compatibility
- Update documentation with changes
- Increment version in module.json

#### 7.3 Dependency Updates

- Monitor for security vulnerabilities
- Test dependency updates before deploying
- Document breaking changes

#### 7.4 Documentation Maintenance

- Keep README current with code changes
- Update examples when APIs change
- Add troubleshooting entries for common issues
- Remove obsolete documentation

**Skills to Use:**
- All skills as appropriate for the change
- **module-management** - Version management
- **documentation** - Documentation updates

---

## Skill Reference Guide

Luigi includes specialized skills for different aspects of development. Use this guide to know when to invoke each skill:

### Design and Planning Skills

#### module-design
**Use when:** Designing new modules BEFORE implementation
**Provides:** Hardware design, architecture patterns, safety checklists, design templates
**Path:** `.github/skills/module-design/`

#### module-management
**Use when:** Planning module lifecycle, registry integration, dependency management
**Provides:** Registry schema, lifecycle patterns, version management
**Path:** `.github/skills/module-management/`

### Implementation Skills

#### python-development
**Use when:** Writing Python code for hardware control, sensors, automation
**Provides:** Code patterns, GPIO abstraction, error handling, testing strategies
**Path:** `.github/skills/python-development/`

#### nodejs-backend-development
**Use when:** Creating REST APIs, backend services, web servers
**Provides:** Express patterns, authentication, validation, API design
**Path:** `.github/skills/nodejs-backend-development/`

#### web-frontend-development
**Use when:** Building web UIs, dashboards, SPAs
**Provides:** React/TypeScript patterns, responsive design, cross-browser support
**Path:** `.github/skills/web-frontend-development/`

#### shell-scripting
**Use when:** Creating setup scripts, CLI tools, deployment scripts
**Provides:** Shell standards, shared helpers library, service management
**Path:** `.github/skills/shell-scripting/`

### Infrastructure Skills

#### raspi-zero-w
**Use when:** Working with GPIO, hardware wiring, Raspberry Pi setup
**Provides:** GPIO pinout, wiring diagrams, hardware troubleshooting
**Path:** `.github/skills/raspi-zero-w/`

#### system-setup
**Use when:** Creating deployment automation, service integration
**Provides:** Deployment templates, systemd patterns, multi-module setup
**Path:** `.github/skills/system-setup/`

### Documentation Skills

#### documentation
**Use when:** Writing any documentation (READMEs, API docs, guides)
**Provides:** Documentation standards, templates, patterns, examples
**Path:** `.github/skills/documentation/`

## Agentic Software Development Best Practices

When working with AI coding agents (like GitHub Copilot), follow these patterns for optimal results:

### 1. Provide Clear Context

**Do:**
- Describe the problem and desired outcome clearly
- Reference existing patterns and files
- Specify constraints and requirements
- Indicate which skills are relevant

**Example:**
```
Create a new temperature sensor module following Luigi conventions.
Use the module-design skill to plan the architecture first.
Hardware: DHT22 sensor on GPIO pin 4
Integration: Publish to Home Assistant via ha-mqtt
```

### 2. Break Down Complex Tasks

**Do:**
- Divide large tasks into phases
- Complete one phase before moving to next
- Validate each phase before proceeding
- Use report_progress after each phase

**Example:**
```
Phase 1: Design and validate hardware wiring
Phase 2: Implement Python sensor reading code
Phase 3: Create setup.sh and service file
Phase 4: Write documentation
Phase 5: Test and deploy
```

### 3. Reference Existing Patterns

**Do:**
- Point to similar existing modules
- Reference skill documentation
- Indicate which patterns to follow
- Specify files to use as templates

**Example:**
```
Model the setup script after iot/ha-mqtt/setup.sh
Use python-development skill patterns for sensor reading
Follow documentation skill template for README
```

### 4. Validate Incrementally

**Do:**
- Run syntax checks after each change
- Test components in isolation
- Fix issues immediately
- Commit working code frequently

**Example:**
```
After writing sensor.py:
1. Run: python3 -m py_compile sensor.py
2. Test with mock GPIO
3. Commit if working
4. Move to next component
```

### 5. Maintain Context

**Do:**
- Use the store_memory tool for important facts
- Reference repository memories when relevant
- Keep the agent informed of progress
- Report blockers and issues clearly

**Example:**
```
When discovering a new convention:
store_memory(
  subject="GPIO pin usage",
  fact="GPIO pins 23-27 are reserved for motion sensors",
  citations="motion-detection/mario/README.md, design review"
)
```

### 6. Follow the Workflow

**Do:**
- Use the complete development workflow (phases 1-7)
- Don't skip design phase for complex modules
- Always document before considering complete
- Test thoroughly before deployment

**Don't:**
- Jump straight to coding without design
- Skip documentation ("will do later")
- Deploy without testing
- Ignore security review

### 7. Leverage Specialized Skills

**Do:**
- Invoke relevant skills explicitly when needed
- Use skills as reference documentation
- Follow skill guidance precisely
- Cross-reference between skills

**Example:**
```
For a new sensor module:
1. Invoke module-design skill for architecture
2. Invoke python-development skill for coding
3. Invoke raspi-zero-w skill for wiring
4. Invoke documentation skill for README
5. Invoke system-setup skill for deployment
```

### 8. Communicate Progress

**Do:**
- Use report_progress frequently
- Update checklists as work completes
- Commit working code often
- Document blockers and decisions

**Example:**
```
After each major milestone:
report_progress(
  commitMessage="Implement sensor reading with DHT22",
  prDescription="- [x] Design sensor architecture
                 - [x] Implement sensor.py
                 - [x] Validate syntax
                 - [ ] Create setup.sh
                 - [ ] Write documentation"
)
```

### 9. Handle Errors Gracefully

**Do:**
- Acknowledge when stuck or uncertain
- Ask for clarification on requirements
- Propose alternatives when blocked
- Document known issues

**Example:**
```
I'm unable to determine the correct GPIO pin for this sensor.
Options:
1. Use GPIO pin 4 (commonly used for DHT sensors)
2. Wait for user specification
3. Make it configurable

Which approach would you prefer?
```

### 10. Maintain Code Quality

**Do:**
- Follow existing code style
- Use established patterns
- Keep changes minimal and focused
- Validate with all available tools

**Example:**
```
Before committing:
✓ python3 -m py_compile *.py
✓ shellcheck *.sh
✓ npm run lint (for frontend)
✓ Test installation with setup.sh
✓ Review git diff for unintended changes
```

## Quick Reference: Common Scenarios

### Scenario: Create New Hardware Module

1. **Design:** Use module-design skill → Create design document
2. **Plan:** Determine GPIO pins, components, dependencies
3. **Implement:** Use python-development skill → Write module.py
4. **Setup:** Use shell-scripting skill → Create setup.sh
5. **Document:** Use documentation skill → Write README
6. **Deploy:** Use system-setup skill → Test installation

### Scenario: Create Backend API

1. **Design:** Use module-design skill → Plan API structure
2. **Implement:** Use nodejs-backend-development skill → Write server.js
3. **Setup:** Use shell-scripting skill → Create setup.sh
4. **Document:** Use documentation skill → Write README + docs/API.md
5. **Deploy:** Use system-setup skill → Test installation

### Scenario: Create Web Frontend

1. **Design:** Plan UI/UX, components, routes
2. **Implement:** Use web-frontend-development skill → Write React components
3. **Setup:** Use shell-scripting skill → Create setup.sh with build steps
4. **Document:** Use documentation skill → Write README
5. **Deploy:** Use system-setup skill → Test nginx deployment

### Scenario: Fix Bug in Existing Module

1. **Analyze:** Review logs, reproduce issue, identify root cause
2. **Fix:** Modify code following appropriate skill guidance
3. **Validate:** Run syntax checks and tests
4. **Document:** Update README if user-facing change
5. **Deploy:** Test fix in target environment

### Scenario: Add Home Assistant Integration

1. **Design:** Plan sensor descriptors and data flow
2. **Implement:** Add luigi-publish calls to module
3. **Create:** Sensor descriptor JSON in /etc/luigi/iot/ha-mqtt/sensors.d/
4. **Document:** Update module README with HA integration section
5. **Test:** Run luigi-discover and verify in Home Assistant

## Success Criteria

A Luigi development task is complete when:

- ✅ Design is documented and validated (for new modules)
- ✅ Code follows Luigi conventions and patterns
- ✅ All syntax validation passes (py_compile, shellcheck, lint)
- ✅ Functional testing completed
- ✅ Security review completed
- ✅ Documentation is comprehensive and accurate
- ✅ Setup script works (install/uninstall/status)
- ✅ Service starts and logs correctly
- ✅ Module registry entry created
- ✅ Integration tested (MQTT, management-api)
- ✅ Main README updated with new module
- ✅ All changes committed and pushed

## Additional Resources

### Luigi Repository Structure
- Main README: `/README.md`
- Module schema: `/MODULE_SCHEMA.md`
- Uninstall guide: `/UNINSTALL_GUIDE.md`
- Copilot instructions: `/.github/copilot-instructions.md`
- Skills directory: `/.github/skills/`
- Shared helpers: `/util/setup-helpers.sh`

### Key Directories
- Module registry: `/etc/luigi/modules/` (on target system)
- Configuration: `/etc/luigi/{module-path}/` (on target system)
- Logs: `/var/log/luigi/` (on target system)
- Module categories: `motion-detection/`, `sensors/`, `automation/`, `security/`, `iot/`, `system/`

### Important Patterns
- All setup scripts MUST source `util/setup-helpers.sh`
- All modules MUST update registry via `update_module_registry_full()`
- All services MUST log to `/var/log/luigi/`
- All config files MUST be in `/etc/luigi/{module-path}/`
- All IoT sensors SHOULD integrate with ha-mqtt for Home Assistant

## Conclusion

This skill provides the complete roadmap for Luigi development. Use it as your primary guide, invoking specialized skills as needed for specific tasks. Follow the workflow, maintain quality standards, and leverage the power of all available skills to build robust, maintainable Luigi modules.

**Remember:** Design first, implement incrementally, test thoroughly, document comprehensively, and deploy confidently.

For questions or clarifications about any phase of the workflow, reference the appropriate specialized skill or ask for guidance.
