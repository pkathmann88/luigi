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

**Note:** These skills complement each other. The `system-setup` skill helps create deployment automation scripts for Luigi modules, the `raspi-zero-w` skill focuses on hardware setup and wiring, while the `python-development` skill focuses on code structure and software development patterns. Together they provide complete guidance for developing and deploying any type of Luigi module (motion detection, sensors, automation, etc.).

## Repository Structure

```
luigi/
├── .github/
│   ├── copilot-instructions.md     # This file
│   └── skills/                      # Agent Skills for specialized guidance
│       ├── python-development/      # Python development patterns
│       │   ├── SKILL.md             # Main skill file
│       │   ├── python-patterns.md   # Advanced patterns
│       │   └── example_application.py  # Complete example
│       ├── raspi-zero-w/            # Raspberry Pi hardware guidance
│       │   ├── SKILL.md             # Main skill file
│       │   ├── gpio-pinout.md       # GPIO reference
│       │   └── wiring-diagram.md    # Hardware wiring
│       └── system-setup/            # System setup and configuration
│           ├── SKILL.md             # Main skill file
│           └── system-reference.md  # System commands reference
├── .gitignore                       # Python, IDE, and OS exclusions
├── README.md                        # Main project documentation
└── motion-detection/                # Motion detection components
    ├── README.md                    # Component overview
    └── mario/                       # Mario-themed motion detector
        ├── README.md                # Component-specific docs
        ├── mario                    # POSIX shell init.d service script
        ├── mario.py                 # Main Python motion detection script
        └── mario-sounds.tar.gz      # Audio files (10 WAV files, ~1.3MB)
```

**Key Files:**
- **mario.py:** Core logic - GPIO setup, motion detection callback, cooldown management, sound playback
- **mario:** Init.d service script for system daemon control (start/stop)
- **mario-sounds.tar.gz:** Contains 10 WAV files (callingmario1.wav through callingmario10.wav)

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
```

**Exit code 0 = success, no output expected.** Shellcheck is available in the environment.

### No Traditional Build Process

**Important:** This project has NO build, compile, or package steps. Changes to Python or shell scripts are immediately usable after syntax validation.

### No Automated Tests

**Critical:** There are currently NO test files, NO test framework (pytest, unittest), and NO CI/CD pipelines. Do NOT attempt to run tests like `pytest` or `python -m unittest` - they will fail.

**When adding tests in the future:**
- Follow Python best practices (use pytest or unittest)
- Place tests in a `tests/` directory or use `test_*.py` naming
- Document test execution commands clearly

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
- `python-rpi.gpio` - GPIO control library
- `alsa-utils` - Audio playback (`aplay` command)

**Installation command:**
```bash
sudo apt-get update && sudo apt-get install python-rpi.gpio alsa-utils
```

**Note:** RPi.GPIO does NOT work in standard Linux environments without Raspberry Pi hardware. Do not attempt to run mario.py outside of a Raspberry Pi or emulated environment.

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
   - Logging to `/var/log/`
   - Configuration via constants or config files
5. **Update parent READMEs** to reference new component
6. **Consider modularity:** Make components independent when possible, shared libraries when needed

### File Organization

- **Configuration:** Config files in `/etc/luigi/{module-path}/` (e.g., `/etc/luigi/motion-detection/mario/mario.conf`)
  - For modules under `motion-detection/mario/`, config path is `/etc/luigi/motion-detection/mario/`
  - For modules under `sensors/temp/`, config path is `/etc/luigi/sensors/temp/`
  - Config files should use `.conf` extension with INI or key=value format
  - Legacy modules may still use hardcoded constants (transitioning to config files)
- **Logs:** Written to `/var/log/motion.log` on Raspberry Pi
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
- For hardware setup and wiring questions → Use `.github/skills/raspi-zero-w/`
- For Python code development patterns → Use `.github/skills/python-development/`

The skills provide deeper, specialized guidance beyond these general instructions.
