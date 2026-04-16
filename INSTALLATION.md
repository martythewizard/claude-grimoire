# Claude Grimoire Installation Guide

## Quick Install (User Scope)

Install claude-grimoire globally so all skills, agents, and teams are available in any project.

### Method 1: Manual Installation

1. **Register the plugin:**

```bash
# Add to installed plugins
cat >> ~/.claude/plugins/installed_plugins.json <<EOF
    "claude-grimoire@local": [
      {
        "scope": "user",
        "installPath": "/path/to/claude-grimoire",
        "version": "2.0.0",
        "installedAt": "$(date -Iseconds)",
        "lastUpdated": "$(date -Iseconds)"
      }
    ]
EOF
```

2. **Create symlink in cache:**

```bash
mkdir -p ~/.claude/plugins/cache/local
ln -sf /path/to/claude-grimoire ~/.claude/plugins/cache/local/claude-grimoire
```

3. **Restart Claude Code**

The plugin will be loaded on next Claude Code session.

### Method 2: Project Scope (Optional)

Install only for the current project:

```bash
# From within your project directory
claude code plugins install --local /path/to/claude-grimoire
```

## Verify Installation

After restarting Claude Code, verify skills are available:

```
You: /pr-author
Claude: [loads pr-author skill]
```

Available skills:
- `/pr-author` - Generate PR descriptions
- `/initiative-creator` - Create GitHub initiatives
- `/initiative-breakdown` - Break initiatives into tasks
- `/initiative-validator` - Validate initiative YAML files
- `/initiative-discoverer` - Find untracked JIRA epics
- `/incident-handler` - Handle incidents end-to-end
- `/visual-prd` - Create visual PRDs

Available agents:
- `github-context-agent` - GitHub context gathering
- `incident-context-agent` - Incident intelligence
- `documentation-agent` - Generate documentation
- `system-architect-agent` - Architecture design

Available teams:
- `feature-delivery-team` - Complete feature delivery
- `incident-response-team` - Incident response
- `pr-autopilot-team` - Automated PR creation

## Troubleshooting

### Skills not showing up

1. Verify plugin.json exists in installation path
2. Check symlink is correct: `ls -la ~/.claude/plugins/cache/local/`
3. Restart Claude Code completely
4. Check Claude Code logs for plugin loading errors

### Permission errors

Ensure the installation directory is readable:
```bash
chmod -R a+r /path/to/claude-grimoire
```

## Uninstallation

```bash
# Remove from installed plugins
# Edit ~/.claude/plugins/installed_plugins.json and remove claude-grimoire entry

# Remove symlink
rm ~/.claude/plugins/cache/local/claude-grimoire

# Restart Claude Code
```

## Development Mode

For plugin development, use symlink method so changes are reflected immediately:

```bash
# Link to your development directory
ln -sf ~/dev/claude-grimoire ~/.claude/plugins/cache/local/claude-grimoire

# Changes to skills/agents/teams will be picked up on next session
```

## Configuration

See [docs/getting-started.md](docs/getting-started.md) for configuration options.
