# Luigi Documentation Skill

This directory contains the **Documentation Skill** for Luigi - a comprehensive guide for creating and maintaining documentation in the Luigi repository.

## Files in This Skill

- **SKILL.md** - Main skill file with complete documentation standards and best practices
- **documentation-patterns.md** - Detailed examples of common documentation patterns
- **module-readme-template.md** - Complete template for module documentation

## When to Use This Skill

Use this skill when:
- Creating documentation for a new Luigi module
- Updating existing module documentation
- Adding new modules to the main project README
- Creating API documentation for backend services
- Writing technical guides or troubleshooting documentation

## Quick Start

### Creating a New Module README

1. Copy the template:
   ```bash
   cp .github/skills/documentation/module-readme-template.md category/module-name/README.md
   ```

2. Fill in all sections with module-specific information

3. Reference `documentation-patterns.md` for examples of:
   - Hardware documentation
   - Configuration documentation
   - Troubleshooting sections
   - API documentation

4. Update main project README to include the new module

### Updating the Main README

When adding a new module, update `/README.md`:

1. Add a row to the "Current Modules" table:
   ```markdown
   | [Module Name](path/to/module/) | category | One-line description |
   ```

2. Keep the table organized (usually by category, then alphabetically)

3. Ensure the link points to the module's README

## Documentation Philosophy

Luigi follows a **decentralized documentation approach**:

- **Each module has ONE comprehensive README** in its directory
- **Main project README** provides overview and module directory
- **API documentation** is separate when serving as an interface contract
- **Documentation lives with code** for easy maintenance

## Key Principles

1. **Self-Contained** - Module READMEs should be complete and standalone
2. **User-Focused** - Write for end users installing and using the system
3. **Examples-First** - Show practical examples before theory
4. **Test Your Docs** - Run every command you document
5. **Keep Updated** - Update docs when code changes

## Resources

- Read `SKILL.md` for complete documentation standards
- Browse `documentation-patterns.md` for detailed examples
- Use `module-readme-template.md` as a starting point for new modules
- Study existing module READMEs as reference:
  - `motion-detection/mario/README.md` - Hardware module
  - `iot/ha-mqtt/README.md` - Integration module
  - `system/management-api/README.md` - Web service module
  - `system/management-api/docs/API.md` - API documentation

## Contact

Questions about documentation standards? Open an issue on GitHub.
