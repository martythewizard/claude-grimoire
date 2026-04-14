# Configuration Guide

This guide explains all configuration options for Claude Grimoire and how to use them effectively.

## Configuration Hierarchy

Claude Grimoire uses a hierarchical configuration system:

1. **Environment Variables** (highest priority)
2. **Per-Repository Config** (`.claude-grimoire/config.json`)
3. **Global Config** (`~/.claude/claude-grimoire/config.json`)
4. **Default Values** (lowest priority)

## Configuration Files

### Global Configuration

Location: `~/.claude/claude-grimoire/config.json`

Used for settings that apply across all repositories:
- API keys and credentials
- Organization defaults
- Service URLs

Example: [global-config-example.json](examples/config/global-config-example.json)

### Per-Repository Configuration

Location: `.claude-grimoire/config.json` (in repository root)

Used for repository-specific settings:
- PR title prefixes
- Default labels and reviewers
- Test plan requirements

Example: [repo-config-example.json](examples/config/repo-config-example.json)

## Configuration Schema

Full JSON schema: [config/schema.json](../config/schema.json)

Use this schema for validation and IDE autocomplete.

## Configuration Options

### GitHub Settings

```json
{
  "github": {
    "org": "your-org",                    // Default organization
    "defaultRepos": ["repo1", "repo2"],   // Commonly used repos
    "defaultLabels": ["needs-review"],    // Labels for PRs
    "defaultReviewers": ["user1"],        // Default reviewers
    "codeownersPath": ".github/CODEOWNERS", // CODEOWNERS path
    "apiUrl": "https://api.github.com",   // GitHub API URL
    "token": "${GITHUB_TOKEN}",           // API token
    "cacheEnabled": true,                 // Enable response caching
    "cacheTTL": 300,                      // Cache duration (seconds)
    "defaultDepth": "standard",           // Context depth (shallow/standard/deep)
    "includeArchivedIssues": false        // Include archived issues
  }
}
```

**Key Options:**

- **org**: Your default GitHub organization name
- **defaultRepos**: Frequently used repos for quick access
- **defaultLabels**: Labels automatically applied to PRs
- **defaultReviewers**: Default reviewers for PRs (can be overridden by CODEOWNERS)
- **codeownersPath**: Path to CODEOWNERS file for auto-reviewer assignment
- **apiUrl**: For GitHub Enterprise, use your instance URL
- **token**: Use `${GITHUB_TOKEN}` to reference environment variable
- **cacheEnabled**: Cache GitHub API responses (recommended)
- **cacheTTL**: How long to cache responses (300 = 5 minutes)
- **defaultDepth**: How much context to gather by default
  - `shallow`: Fast, basic info only
  - `standard`: Balanced (recommended)
  - `deep`: Comprehensive, slower
- **includeArchivedIssues**: Whether to include archived issues in searches

### PR Author Settings

```json
{
  "prAuthor": {
    "titlePrefix": "[FEAT]",              // PR title prefix
    "requireIssueReference": true,        // Require issue #
    "includeTestPlan": true,              // Include test plan section
    "includeVisualChanges": true,         // Include visual changes section
    "templatePath": ".github/PULL_REQUEST_TEMPLATE.md" // PR template path
  }
}
```

**Key Options:**

- **titlePrefix**: Added to all PR titles (e.g., `[FEAT]`, `[FIX]`, `[DOCS]`)
- **requireIssueReference**: Force PRs to reference an issue
- **includeTestPlan**: Add test plan checklist to PRs
- **includeVisualChanges**: Add visual changes section for UI PRs
- **templatePath**: Custom PR template location

### PR Autopilot Settings

```json
{
  "prAutopilot": {
    "autoAssignReviewers": true,          // Auto-assign from CODEOWNERS
    "setAsDraft": false,                  // Create as draft PR
    "runTests": true                      // Run tests before creating PR
  }
}
```

**Key Options:**

- **autoAssignReviewers**: Parse CODEOWNERS and assign reviewers automatically
- **setAsDraft**: Create PRs as drafts (for WIP)
- **runTests**: Run test suite before PR creation (prevents broken PRs)

### Firehydrant Settings

```json
{
  "firehydrant": {
    "apiUrl": "https://api.firehydrant.io", // Firehydrant API URL
    "orgSlug": "your-org",                  // Organization slug
    "apiKey": "${FIREHYDRANT_API_KEY}"      // API key
  }
}
```

**Key Options:**

- **orgSlug**: Your Firehydrant organization identifier
- **apiKey**: Use `${FIREHYDRANT_API_KEY}` to reference environment variable

### Coralogix Settings

```json
{
  "coralogix": {
    "apiUrl": "https://api.coralogix.com", // Coralogix API URL
    "region": "us",                        // Region (us/eu/ap/in)
    "apiKey": "${CORALOGIX_API_KEY}"       // API key
  }
}
```

**Key Options:**

- **region**: Your Coralogix region (`us`, `eu`, `ap`, `in`)
- **apiKey**: Use `${CORALOGIX_API_KEY}` to reference environment variable

## Environment Variables

Recommended approach for sensitive data:

```bash
# GitHub
export GITHUB_TOKEN=ghp_your_token_here

# Firehydrant (for incident-handler)
export FIREHYDRANT_API_KEY=your_key_here

# Coralogix (for log analysis)
export CORALOGIX_API_KEY=your_key_here

# Company CLI path (if applicable)
export COMPANY_CLI_PATH=/path/to/cli
```

Add these to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.)

## Examples by Use Case

### Use Case 1: Basic Setup

**Goal**: Minimal config just to get started

```json
{
  "github": {
    "org": "mycompany"
  }
}
```

**Result**: Everything else uses sensible defaults

---

### Use Case 2: Team Standardization

**Goal**: Enforce team conventions on PRs

**Per-repo config** (`.claude-grimoire/config.json`):
```json
{
  "prAuthor": {
    "titlePrefix": "[TEAM-NAME]",
    "requireIssueReference": true,
    "includeTestPlan": true
  },
  "github": {
    "defaultLabels": ["needs-review", "team-name"],
    "defaultReviewers": ["team-lead"]
  }
}
```

**Result**: All PRs follow team conventions automatically

---

### Use Case 3: GitHub Enterprise

**Goal**: Use with GitHub Enterprise instance

**Global config** (`~/.claude/claude-grimoire/config.json`):
```json
{
  "github": {
    "apiUrl": "https://github.company.com/api/v3",
    "org": "company-org",
    "token": "${GITHUB_TOKEN}"
  }
}
```

**Result**: Points to your GHE instance

---

### Use Case 4: Incident Response

**Goal**: Enable incident-handler skill with Firehydrant

**Global config**:
```json
{
  "firehydrant": {
    "orgSlug": "my-company",
    "apiKey": "${FIREHYDRANT_API_KEY}"
  },
  "coralogix": {
    "region": "us",
    "apiKey": "${CORALOGIX_API_KEY}"
  }
}
```

**Environment**:
```bash
export FIREHYDRANT_API_KEY=fhb_...
export CORALOGIX_API_KEY=cx_...
```

**Result**: incident-handler can access logs and incidents

## Troubleshooting

### "Config file not found"

**Problem**: Config file missing or in wrong location

**Solutions**:
1. Create config file in correct location
2. Use minimal config to start
3. Check file permissions

### "Invalid configuration"

**Problem**: Config doesn't match schema

**Solutions**:
1. Validate against [schema.json](../config/schema.json)
2. Check for typos in property names
3. Ensure JSON is valid (no trailing commas, proper quotes)
4. Use example configs as reference

### "API authentication failed"

**Problem**: Invalid or missing API keys

**Solutions**:
1. Verify `GITHUB_TOKEN` is set and valid
2. Check token has required scopes
3. Ensure environment variables are loaded
4. Test with `echo $GITHUB_TOKEN`

### "Config not taking effect"

**Problem**: Changes not being applied

**Solutions**:
1. Check configuration hierarchy (env > repo > global > defaults)
2. Restart Claude Code
3. Verify JSON syntax is correct
4. Check for typos in config keys

## Best Practices

### Security

- ✅ Use environment variables for secrets (`${GITHUB_TOKEN}`)
- ✅ Add config files with secrets to `.gitignore`
- ✅ Never commit actual API keys
- ✅ Use minimal token scopes needed

### Organization

- ✅ Keep global config minimal (only shared settings)
- ✅ Use per-repo config for team conventions
- ✅ Document custom settings in repo README
- ✅ Share example configs with team

### Performance

- ✅ Enable caching for faster API responses
- ✅ Use `shallow` depth for quick checks
- ✅ Use `deep` depth only when necessary
- ✅ Set reasonable cache TTL (300s = 5min)

## Validation

To validate your configuration:

```bash
# Using a JSON schema validator
npm install -g ajv-cli
ajv validate -s config/schema.json -d ~/.claude/claude-grimoire/config.json
```

Or use IDE validation:
- VS Code: Install "JSON Schema" extension
- Add `"$schema": "./config/schema.json"` to your config

## Further Reading

- [Getting Started Guide](getting-started.md)
- [Configuration Examples](examples/config/)
- [Plugin Architecture](../README.md#architecture)
- [Skill-Specific Docs](../skills/)
