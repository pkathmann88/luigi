---
name: documentation
description: Comprehensive guide for writing documentation in the Luigi repository. Use this skill when creating module READMEs, updating the main project README, or creating technical documentation following Luigi standards and best practices.
license: MIT
---

# Documentation for Luigi Repository

This skill provides comprehensive guidance for writing documentation in the Luigi repository, including module-specific READMEs, the main project README, API documentation, and other technical documentation following established patterns and best practices.

## When to Use This Skill

Use this skill when:
- Creating documentation for a new Luigi module
- Updating existing module documentation
- Updating the main project README to include new modules
- Creating API documentation for backend services
- Writing technical guides or troubleshooting documentation
- Establishing documentation structure for new features
- Reviewing documentation for completeness and clarity

## Luigi Documentation Standards

### Documentation Philosophy

Luigi follows a **decentralized documentation approach** where each module maintains its own comprehensive README while the main project README provides an overview and directory of all modules:

- **Main Project README** (`/README.md`) - Platform overview, quick start, module listing
- **Module READMEs** - Complete documentation for each specific module
- **API Documentation** - Separate interface contracts for backend APIs (e.g., `docs/API.md`)
- **Technical Guides** - Standalone documents for complex topics (e.g., `UNINSTALL_GUIDE.md`)

**Key Principles:**
1. **Single Source of Truth** - Each module has ONE primary README
2. **Self-Contained** - Module READMEs should be complete and standalone
3. **User-Focused** - Write for end users installing and using the system
4. **Examples-First** - Show practical examples before explaining theory
5. **Maintenance-Friendly** - Keep documentation close to code it describes

### Documentation Hierarchy

```
luigi/
├── README.md                    # Main project overview and module directory
├── MODULE_SCHEMA.md             # Technical reference for module.json format
├── UNINSTALL_GUIDE.md          # Standalone operational guide
├── motion-detection/
│   ├── README.md               # Category overview (optional)
│   └── mario/
│       └── README.md           # Complete module documentation
├── iot/
│   └── ha-mqtt/
│       ├── README.md           # Complete module documentation
│       └── examples/
│           └── integration-guide.md  # Supplementary guide
└── system/
    └── management-api/
        ├── README.md           # User-facing module documentation
        └── docs/
            └── API.md          # Technical API reference (interface contract)
```

## Main Project README Structure

The main project README (`/README.md`) serves as the **entry point** and **module directory** for Luigi. It should provide:

### Required Sections

1. **Project Title and Description**
   - Clear one-line description
   - Key features summary
   - Target audience

2. **Quick Start**
   - Installation commands
   - Basic setup steps
   - Link to detailed guides if needed

3. **Current Modules**
   - **Table listing ALL modules** with links to module READMEs
   - Organized by category
   - Brief one-line description per module
   - Link to module-specific README for details

   Example format:
   ```markdown
   | Module | Category | Description |
   |--------|----------|-------------|
   | [Module Name](path/to/module/) | category | One-line description |
   ```

4. **Platform Information**
   - Target hardware
   - Operating system
   - Language and key dependencies

5. **Architecture Overview**
   - Module categories explanation
   - Module structure
   - Installation locations

6. **Usage Basics**
   - Common commands
   - Service management
   - Links to module-specific usage

7. **Development Guidelines**
   - Creating new modules
   - Agent Skills reference
   - Code quality standards

8. **Contributing**
   - How to contribute
   - Testing requirements
   - Documentation requirements

### Main README Best Practices

- **Keep it high-level** - Link to module READMEs for details
- **Update module table** - When adding/removing modules, update the table
- **Link extensively** - Point readers to specific documentation
- **Show, don't tell** - Use code examples and command snippets
- **Maintain consistency** - Follow existing formatting and tone

## Module README Structure

Each Luigi module **must** have a comprehensive README.md in its directory. This is the **primary documentation** for the module.

### Standard Module README Template

```markdown
# Module Name

Brief one-line description of what the module does.

## Overview

Detailed description of the module's purpose, functionality, and use cases.

## Features

- Feature 1
- Feature 2
- Feature 3

## Hardware Requirements

List all required hardware components:
- Component name (with links to purchase if helpful)
- GPIO pins used (with BCM numbering)
- Wiring requirements
- Power requirements

Include wiring diagrams if complex (markdown table or image).

## Software Requirements

- Operating System
- Python version
- Required system packages
- Dependencies on other Luigi modules

## Installation

Step-by-step installation instructions:

### Automatic Installation (Recommended)

```bash
# Install from repository root
sudo ./setup.sh install category/module-name
```

### Manual Installation

Only if manual steps are needed. Include all commands.

## Configuration

Detail all configuration options:

**Configuration File:** `/etc/luigi/category/module-name/module.conf`

```ini
# Example configuration
OPTION_1=value1
OPTION_2=value2
```

**Configuration Options:**
- `OPTION_1` - Description (default: value)
- `OPTION_2` - Description (default: value)

## Usage

How to use the module after installation:

### Starting/Stopping the Service

```bash
sudo systemctl start module-name
sudo systemctl stop module-name
sudo systemctl restart module-name
```

### Checking Status

```bash
sudo systemctl status module-name
journalctl -u module-name -f
```

### Common Operations

Include practical examples of using the module.

## Integration with Other Modules

If the module integrates with other Luigi modules (especially ha-mqtt), document:
- What integration is available
- How to enable integration
- Configuration required
- Example usage

## Logs

Where logs are written and how to access them:
- Log file location
- Journalctl commands
- Log rotation settings

## Troubleshooting

Common issues and solutions:

### Issue 1
**Symptom:** Description
**Cause:** Why it happens
**Solution:** How to fix it

### Issue 2
[Continue pattern]

## Uninstallation

```bash
sudo ./setup.sh uninstall category/module-name
```

Include any special notes about data preservation or cleanup.

## Technical Details

For developers who want to understand or modify the module:
- Code structure
- Key functions/classes
- Hardware abstraction patterns
- Testing approach

## Contributing

How to contribute to this specific module.

## License

License information.
```

### Module README Best Practices

- **Complete and Self-Contained** - User should find everything they need
- **Hardware First** - Show wiring and GPIO before code
- **Command Examples** - Always show actual commands with output
- **Real-World Scenarios** - Include practical use cases
- **Troubleshooting** - Anticipate common problems
- **Keep Updated** - Update when features change
- **Screenshots** - Include for GUI components or complex output
- **Configuration Examples** - Show real config file snippets

## API Documentation (Special Case)

Backend API documentation serves as an **interface contract** between frontend and backend. It should be separate from the module README.

### When to Create Separate API Documentation

Create a separate API documentation file when:
- The module provides a REST API or web service
- Frontend and backend need a clear interface contract
- The API is complex with multiple endpoints
- API documentation would overwhelm the module README

### API Documentation Location

Place API documentation in a `docs/` subdirectory:
```
module-name/
├── README.md          # User-facing documentation
└── docs/
    └── API.md         # Technical API reference
```

### API Documentation Structure

Follow the pattern in `system/management-api/docs/API.md`:

1. **Header with Version and Base URL**
2. **Table of Contents**
3. **Authentication** - How to authenticate
4. **Response Format** - Standard response structure
5. **Error Handling** - Error codes and formats
6. **Endpoint Groups** - Organized by functionality
   - Endpoint description
   - HTTP method and path
   - Request parameters
   - Response schema with TypeScript types
   - Example requests (curl, JavaScript)
   - Example responses

### API Documentation Best Practices

- **TypeScript Types** - Use TypeScript for response schemas
- **Complete Examples** - Show both curl and code examples
- **Error Cases** - Document all possible errors
- **Status Codes** - List all HTTP status codes used
- **Version It** - Include API version in documentation
- **Keep Synchronized** - Update when API changes
- **Interface Contract** - Treat as binding agreement between frontend/backend

## Category README (Optional)

Category-level READMEs (e.g., `motion-detection/README.md`) are optional and should only be created if:
- The category has multiple modules
- There's category-specific information to share
- You want to provide a category overview

If created, keep them brief:
- List modules in the category with links
- Explain the category purpose
- Link to individual module READMEs for details

## Technical Guides and Standalone Documents

For complex topics that don't fit in module READMEs, create standalone guides:

**Examples:**
- `UNINSTALL_GUIDE.md` - Complete uninstallation procedures
- `MODULE_SCHEMA.md` - Technical reference for module.json
- `MIGRATION_GUIDE.md` - Upgrading between versions
- `SECURITY.md` - Security policy and reporting

**Guidelines:**
- Place in repository root if project-wide
- Place in module directory if module-specific
- Use descriptive ALL_CAPS names
- Link from relevant READMEs
- Keep focused on single topic

## Documentation Writing Style

### Tone and Voice

- **Clear and Direct** - Use simple language, avoid jargon
- **Action-Oriented** - Use imperative mood ("Install the module", not "The module can be installed")
- **Professional but Friendly** - Technical but approachable
- **Consistent Terminology** - Use same terms throughout

### Formatting Guidelines

**Code Blocks:**
- Always specify language: ```bash, ```python, ```json
- Include command prompts when showing terminal commands
- Show expected output when helpful
- Use comments to explain complex commands

**Links:**
- Use relative links within repository: `[Module](../module/)`
- Use descriptive link text: `[Mario module README](motion-detection/mario/)` not `[click here]`
- Verify links work after changes

**Lists:**
- Use `-` for unordered lists (not `*`)
- Use numbered lists for sequential steps
- Keep list items parallel in structure

**Headers:**
- Use ATX-style headers: `## Header` (not underline style)
- Don't skip header levels
- Use Title Case for main headers

**Emphasis:**
- Use **bold** for UI elements, filenames, important terms
- Use `code` for commands, code elements, paths
- Use *italics* sparingly for subtle emphasis

## Documentation Maintenance

### When to Update Documentation

Update documentation when:
- Adding new features or capabilities
- Changing configuration options
- Modifying installation procedures
- Adding dependencies
- Discovering common issues (add to troubleshooting)
- Improving examples based on user feedback

### Documentation Review Checklist

Before considering documentation complete:

- [ ] README exists in module directory
- [ ] Main project README updated if new module
- [ ] All code examples tested and work
- [ ] All commands verified on target platform
- [ ] Links checked and valid
- [ ] Configuration examples match actual config files
- [ ] GPIO pins documented with BCM numbering
- [ ] Dependencies listed completely
- [ ] Troubleshooting section includes common issues
- [ ] Installation and uninstallation procedures tested
- [ ] Integration with other modules documented if applicable
- [ ] API documentation updated if endpoints changed
- [ ] Spelling and grammar checked
- [ ] Formatting consistent with existing docs

## Examples and References

### Exemplar Module Documentation

**Best Examples in Luigi:**
- `motion-detection/mario/README.md` - Complete hardware module documentation
- `iot/ha-mqtt/README.md` - Complex integration module
- `system/management-api/README.md` - Web service module
- `system/management-api/docs/API.md` - Separate API documentation

Study these for patterns and structure.

### Common Documentation Patterns

See `documentation-patterns.md` for detailed examples of:
- Wiring diagrams in markdown
- Configuration documentation
- Troubleshooting sections
- Integration guides
- Installation procedures
- Service management

## Quick Reference

### New Module Checklist

When creating a new module:

1. Create module directory: `category/module-name/`
2. Create `README.md` using template above
3. Document all hardware requirements and GPIO pins
4. Document all configuration options
5. Include installation and usage examples
6. Add troubleshooting section
7. Update main project README module table
8. Test all documented commands
9. Add screenshots if module has GUI

### Updating Main README

When adding a module to the project:

1. Add row to "Current Modules" table
2. Include module name with link to README
3. Specify category
4. Write one-line description
5. Maintain alphabetical or logical ordering
6. Update module counts if mentioned elsewhere

### Quick Tips

- **Start with examples** - Show before explaining
- **Test everything** - Run every command you document
- **Be specific** - Include actual paths, pins, values
- **Link liberally** - Help users navigate documentation
- **Update proactively** - Don't let docs drift from code
- **Think user-first** - What would someone new need to know?

## See Also

- **Module Design Skill** (`.github/skills/module-design/`) - Designing modules before implementation
- **Shell Scripting Skill** (`.github/skills/shell-scripting/`) - Writing setup scripts
- **Main Project README** (`/README.md`) - Documentation structure example
- **Module README Template** (`documentation-patterns.md`) - Detailed examples
