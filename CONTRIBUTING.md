# Contributing to Claude Grimoire

Thank you for considering contributing to Claude Grimoire! This document provides guidelines and instructions for contributing.

## Code of Conduct

Be respectful, inclusive, and constructive. We're all here to build better tools for Product Engineers.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Your environment (OS, Claude Code version, etc.)

### Suggesting Features

Feature suggestions are welcome! Please:
- Check if the feature already exists or is planned
- Describe the use case and problem it solves
- Propose how it might work
- Consider if it fits the plugin's scope

### Contributing Code

1. **Fork and Clone**
   ```bash
   git clone https://github.com/yourusername/claude-grimoire
   cd claude-grimoire
   ```

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Changes**
   - Follow existing code style
   - Update documentation
   - Add examples if applicable

4. **Test Your Changes**
   - Test the skill/agent/team works as expected
   - Verify documentation is accurate
   - Check for any breaking changes

5. **Commit with Descriptive Messages**
   ```bash
   git commit -m "Add feature: concise description
   
   - Detailed point 1
   - Detailed point 2
   
   Closes #123"
   ```

6. **Push and Create PR**
   ```bash
   git push origin feature/your-feature-name
   gh pr create
   ```

## Development Guidelines

### Project Structure

```
claude-grimoire/
├── skills/          # User-invocable workflows
├── agents/          # Autonomous subagents
├── teams/           # Multi-agent orchestration
├── docs/            # Documentation
└── plugin.json      # Plugin registry
```

### Skill Development

Skills should:
- Have clear, descriptive names
- Include comprehensive documentation
- Use structured workflows (step-by-step)
- Integrate with existing agents when appropriate
- Follow the skill template format

**Skill Template:**
```markdown
---
name: skill-name
description: Brief description
version: 1.0.0
---

# Skill Name

## Purpose
[What problem does this solve?]

## When to Use
[When should users invoke this skill?]

## How It Works
[Step-by-step workflow]

## Configuration
[Config options]

## Examples
[Usage examples]
```

### Agent Development

Agents should:
- Have clear input/output contracts
- Handle errors gracefully
- Return structured data
- Be stateless when possible
- Document integration patterns

**Agent Template:**
```markdown
---
name: agent-name
description: Brief description
version: 1.0.0
type: agent
---

# Agent Name

## Purpose
[What does this agent do?]

## Capabilities
[What can it do?]

## Input Contract
[Expected input format]

## Output Contract
[Return value format]

## Error Handling
[How it handles failures]

## Invoked By
[Which skills/teams use this?]
```

### Team Development

Teams should:
- Orchestrate multiple agents/skills
- Have clear phase transitions
- Provide progress indicators
- Handle workflow branching
- Document decision points

### Documentation

- Keep README.md up to date
- Add examples for new features
- Update getting-started.md if setup changes
- Include troubleshooting tips
- Use clear, concise language

## Testing

### Manual Testing Checklist

Before submitting a PR:

- [ ] Skill invokes correctly
- [ ] Agent returns expected output
- [ ] Error handling works
- [ ] Documentation is accurate
- [ ] Examples work as described
- [ ] No sensitive data exposed

### Integration Testing

Test how your component integrates:
- Skills calling agents
- Teams orchestrating workflows
- Config options work correctly
- GitHub API integration functions

## Style Guide

### Markdown
- Use ATX-style headers (`#` not `===`)
- Include blank lines around code blocks
- Use relative links for internal docs
- Keep lines under 120 characters when possible

### Code Blocks
- Always specify language for syntax highlighting
- Include descriptive comments
- Use realistic examples

### Naming Conventions
- Skills: `kebab-case` (e.g., `pr-author`)
- Agents: `kebab-case-agent` (e.g., `github-context-agent`)
- Teams: `kebab-case-team` (e.g., `feature-delivery-team`)
- Files: Match the component name

## Pull Request Process

1. **Update Documentation**
   - README.md with new features
   - plugin.json with new components
   - Relevant docs/ files

2. **Add Examples**
   - Create docs/examples/your-feature.md
   - Show realistic usage

3. **Request Review**
   - Assign relevant reviewers
   - Link related issues
   - Describe what changed and why

4. **Address Feedback**
   - Respond to review comments
   - Make requested changes
   - Re-request review

5. **Merge**
   - Squash commits if appropriate
   - Ensure CI passes
   - Celebrate! 🎉

## Version Scheme

We follow semantic versioning:
- **Major (1.0.0)**: Breaking changes
- **Minor (0.1.0)**: New features, backwards compatible
- **Patch (0.0.1)**: Bug fixes

## Questions?

- Open a discussion: [GitHub Discussions](https://github.com/martythewizard/claude-grimoire/discussions)
- File an issue: [GitHub Issues](https://github.com/martythewizard/claude-grimoire/issues)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for making Claude Grimoire better! 🔮
