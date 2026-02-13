# Development Skill

The **development skill** is the primary orchestration skill for all Luigi development activities. It provides comprehensive guidance for the complete development workflow from initial requirements analysis through implementation to final deployment.

## Purpose

This skill serves as:
- **Entry point** for any Luigi development task
- **Workflow guide** covering all development phases
- **Integration hub** connecting all specialized skills
- **Best practices guide** for agentic software development

## When to Use

Use this skill when:
- Starting any new Luigi development task
- Planning the complete workflow for a feature or module
- Determining which specialized skills to use and when
- Following Luigi development best practices
- Working with AI coding agents (GitHub Copilot, Claude, etc.)

## Structure

### SKILL.md

The main skill file providing:
- Complete 7-phase development workflow
- Integration with all specialized skills
- Agentic software development best practices
- Common scenario quick references
- Success criteria and quality standards

## Workflow Phases

1. **Requirements Analysis and Design** - Understanding and planning
2. **Implementation Planning** - Detailed technical planning
3. **Implementation** - Writing code following patterns
4. **Testing and Validation** - Ensuring quality and correctness
5. **Documentation** - Creating comprehensive docs
6. **Deployment and Integration** - Deploying to target system
7. **Maintenance and Evolution** - Ongoing updates and fixes

## Integration with Other Skills

This skill references and integrates:

### Design Skills
- **module-design** - Architecture and hardware design
- **module-management** - Lifecycle and registry management

### Implementation Skills
- **python-development** - Python coding patterns
- **nodejs-backend-development** - Node.js API patterns
- **web-frontend-development** - React UI patterns
- **shell-scripting** - Setup scripts and utilities

### Infrastructure Skills
- **raspi-zero-w** - Hardware and GPIO details
- **system-setup** - Deployment automation

### Documentation Skills
- **documentation** - Documentation standards and templates

## Key Concepts

### Phase-Based Development
Each phase has clear objectives, activities, deliverables, and skills to use.

### Agentic Best Practices
Guidelines for effective AI-assisted development:
- Provide clear context
- Break down complex tasks
- Reference existing patterns
- Validate incrementally
- Maintain context with store_memory
- Communicate progress with report_progress

### Common Scenarios
Quick reference guides for:
- Creating new hardware modules
- Creating backend APIs
- Creating web frontends
- Fixing bugs
- Adding Home Assistant integration

## Usage Example

```
Task: Create a new DHT22 temperature sensor module

Step 1: Invoke development skill to understand workflow
Step 2: Follow Phase 1 - Use module-design skill for architecture
Step 3: Follow Phase 2 - Plan implementation with python-development
Step 4: Follow Phase 3 - Write code using patterns from skills
Step 5: Follow Phase 4 - Validate with syntax checks and tests
Step 6: Follow Phase 5 - Document using documentation skill
Step 7: Follow Phase 6 - Deploy using system-setup patterns
```

## Success Criteria

Development is complete when:
- All phases are completed
- Code follows Luigi conventions
- All validation passes
- Documentation is comprehensive
- Module is deployed and tested
- Integration verified

## Additional Resources

- Main README: `/README.md`
- Copilot Instructions: `/.github/copilot-instructions.md`
- All Skills: `/.github/skills/`
- Shared Helpers: `/util/setup-helpers.sh`

## Contributing

When updating this skill:
1. Maintain clear phase structure
2. Keep skill references current
3. Update examples to reflect best practices
4. Ensure integration with other skills
5. Test workflow guidance with real tasks
