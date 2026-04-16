# Claude Grimoire Plugin Structure

This document explains how claude-grimoire is structured as a Claude Code plugin.

## Directory Structure

```
claude-grimoire/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata for Claude Code
├── skills/
│   ├── pr-author/
│   │   └── SKILL.md         # Skill content (uppercase required)
│   ├── initiative-creator/
│   │   └── SKILL.md
│   └── [other-skills]/
├── agents/
│   └── [agent-name]/
│       └── agent.md
├── teams/
│   └── [team-name]/
│       └── team.md
└── plugin.json              # Full plugin manifest (optional for reference)
```

## Key Requirements

### 1. `.claude-plugin/plugin.json` (Required)

Must exist for Claude Code to recognize the plugin. Minimal structure:

```json
{
  "name": "claude-grimoire",
  "version": "2.0.0",
  "description": "...",
  "author": "...",
  "license": "MIT"
}
```

Skills, agents, and teams are **auto-discovered** from their directories.

### 2. Skill Files Must Be Named `SKILL.md` (Uppercase)

Each skill directory must contain a `SKILL.md` file (not `skill.md`).

Example: `skills/pr-author/SKILL.md`

### 3. Skill Frontmatter (Required)

Each SKILL.md must have YAML frontmatter:

```yaml
---
name: pr-author
description: Generate comprehensive PR descriptions with GitHub issue references
version: 1.0.0
---
```

## Installation

When installed as a local plugin:

```bash
# Claude Code automatically loads from:
~/.claude/plugins/installed_plugins.json

# Points to:
{
  "claude-grimoire@local": {
    "installPath": "/path/to/claude-grimoire"
  }
}
```

## Skill Invocation

Skills are invoked by name:

```bash
# In Claude Code:
/pr-author

# Or via Skill tool:
Skill({ skill: "pr-author" })
```

## Verification

After changes, reload plugins:

```bash
/reload-plugins
```

Skills should appear in the system-reminder's available skills list.

## Comparison with Superpowers

claude-grimoire follows the same pattern as the superpowers plugin:

| Feature | Superpowers | Claude Grimoire |
|---------|-------------|-----------------|
| Plugin metadata | `.claude-plugin/plugin.json` | `.claude-plugin/plugin.json` |
| Skill files | `SKILL.md` (uppercase) | `SKILL.md` (uppercase) |
| Auto-discovery | ✅ Yes | ✅ Yes |
| Explicit skill list | ❌ No (auto-discovers) | ❌ No (auto-discovers) |

## Troubleshooting

**Skills not loading?**

1. Verify `.claude-plugin/plugin.json` exists
2. Check skill files are named `SKILL.md` (uppercase)
3. Verify frontmatter has `name` and `description`
4. Run `/reload-plugins`
5. Restart Claude Code if needed

**Case-insensitive filesystems (Windows/WSL)?**

Git may track `skill.md` even after renaming to `SKILL.md`. This is fine - the filesystem sees them as the same file and Claude Code will load SKILL.md correctly.
