# Shell Scripting Skill for Luigi Repository

This skill provides comprehensive guidance for shell scripting in the Luigi repository, adapted to the existing patterns and best practices observed across all shell scripts in the project.

## Files in This Skill

### SKILL.md (Main Skill File)

The main skill file that Copilot will load when working with shell scripts. Contains:

- **Luigi Shell Scripting Standards**: Template structure, bash options, safety guidelines
- **Standard Patterns**: Logging functions, script directory detection, file paths, argument parsing
- **Core Operations**: File operations, command availability checking, package management
- **Service Management**: Systemd service operations and patterns
- **Configuration Handling**: INI-style config files and parsing
- **Error Handling**: Function error checking and graceful failure patterns
- **Validation**: Shellcheck integration and testing patterns
- **Security**: Input validation, shell injection prevention, credential handling
- **Common Issues**: Troubleshooting guide for frequent problems

**Size**: 1121 lines | 25KB

### shell-scripting-patterns.md (Advanced Patterns)

Advanced shell scripting techniques used in Luigi:

- **JSON Parsing**: Using jq for reading/writing/validating JSON
- **Array Operations**: Creating, iterating, and manipulating arrays
- **String Manipulation**: Substring operations, pattern matching, trimming
- **Library Sourcing**: Creating and using reusable shell libraries
- **Subprocess Management**: Background processes, monitoring, timeouts
- **Signal Handling**: Trap for cleanup and signal handling
- **Logging to Files**: File-based logging and rotation
- **Testing Frameworks**: Test helpers, functional tests, integration tests with Docker
- **Multi-Script Architectures**: Organizing complex modules with multiple scripts
- **Performance Optimization**: Avoiding subshells, using built-ins

**Size**: 817 lines | 17KB

### example-setup.sh (Complete Example)

A complete, working example of a Luigi module setup script demonstrating all best practices:

- Standard structure and organization
- All logging functions implemented
- Root permission checking
- Package management with module.json integration
- Python script installation
- Configuration file handling
- Systemd service management
- Full install/uninstall/status actions
- SKIP_PACKAGES and LUIGI_PURGE_MODE support
- Proper error handling throughout

**Size**: 515 lines | 14KB

**Validation**: Passes shellcheck with zero errors

## Usage

This skill will be automatically loaded by Copilot when:

- Creating new shell scripts
- Modifying existing shell scripts
- Debugging shell script issues
- Writing command-line tools
- Implementing service management scripts
- Creating test scripts

You can also explicitly reference patterns from this skill when asking Copilot to:

- "Follow Luigi shell scripting standards when creating this script"
- "Use the standard logging functions from the shell-scripting skill"
- "Implement package management following Luigi patterns"
- "Create a setup script using the shell-scripting skill template"

## Key Features

### Comprehensive Coverage

This skill is based on analysis of:

- 21 shell scripts across the Luigi repository
- 2765+ lines of setup script code (setup.sh, mario/setup.sh, ha-mqtt/setup.sh)
- Testing infrastructure from iot/ha-mqtt module
- Command-line tools from iot/ha-mqtt/bin/

### Luigi-Specific Patterns

All patterns are adapted to Luigi's existing conventions:

- Exact logging function definitions used throughout the repository
- Script directory detection pattern used in all scripts
- File path conventions following Luigi's `/etc/luigi/{module-path}/` structure
- Package management using module.json
- SKIP_PACKAGES and LUIGI_PURGE_MODE flags
- ha-mqtt integration patterns (graceful failure)
- User detection patterns (not hardcoding 'pi:pi')

### Best Practices Integration

Combines Luigi patterns with industry best practices:

- Shellcheck validation requirements
- Security considerations (input validation, credential handling)
- Error handling patterns
- Testing strategies
- Performance optimization
- Code organization

### Complete Examples

Every pattern includes:

- ✅ Working code examples
- ✅ Do's and Don'ts
- ✅ Common pitfalls and solutions
- ✅ Security considerations
- ✅ Testing approaches

## Integration with Other Skills

The shell-scripting skill complements other Luigi skills:

- **module-design**: Provides design guidance; shell-scripting shows how to implement setup scripts
- **system-setup**: Focuses on deployment automation; shell-scripting provides the implementation patterns
- **python-development**: Python code patterns; shell-scripting handles installation and service management
- **nodejs-backend-development**: Node.js backend patterns; shell-scripting for deployment
- **web-frontend-development**: Frontend patterns; shell-scripting for build and deployment scripts

## Validation

All examples in this skill have been validated:

- ✅ Shellcheck: example-setup.sh passes with zero errors
- ✅ Pattern accuracy: All patterns extracted from real Luigi scripts
- ✅ Completeness: Covers all major scripting scenarios in Luigi
- ✅ GitHub Agent Skills format: Follows official documentation structure

## Maintenance

When updating this skill:

1. Verify patterns against current Luigi scripts
2. Run shellcheck on all example code
3. Test patterns in actual Luigi module development
4. Update references in copilot-instructions.md if structure changes

## References

- Luigi repository scripts: `setup.sh`, `motion-detection/mario/setup.sh`, `iot/ha-mqtt/setup.sh`
- Testing examples: `iot/ha-mqtt/tests/`
- Command-line tools: `iot/ha-mqtt/bin/`
- GitHub Agent Skills: https://docs.github.com/copilot/concepts/agents/about-agent-skills
- shellcheck: https://www.shellcheck.net/

---

**Created**: 2026-02-11  
**Based on**: Luigi repository v1.0 shell scripts (21 scripts analyzed)  
**Skill Version**: 1.0  
**License**: MIT
