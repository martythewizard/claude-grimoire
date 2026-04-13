# Getting Started with Claude Grimoire

Welcome! This guide will help you set up and start using Claude Grimoire to streamline your Product Engineering workflows.

## Prerequisites

Before you begin, ensure you have:

- **Claude Code** installed (CLI, desktop app, or IDE extension)
- **Git** installed and configured
- **GitHub account** with repositories you want to work on
- **GitHub Personal Access Token** with appropriate permissions

### Optional (for advanced features)
- **GitHub CLI (`gh`)** for PR creation
- **Firehydrant API key** (for incident-handler skill)
- **Coralogix API key** (for log analysis)
- **Company CLI** (if applicable)

## Installation

### Option 1: Install as Plugin (Recommended)

```bash
# From Claude Code
/plugin install claude-grimoire
```

This installs the plugin globally and makes all skills available in any project.

### Option 2: Clone for Customization

```bash
# Clone the repository
git clone https://github.com/yourusername/claude-grimoire
cd claude-grimoire

# Link it to Claude Code (if using local development)
ln -s $(pwd) ~/.claude/plugins/claude-grimoire
```

## Configuration

### Step 1: GitHub Token

Create a GitHub Personal Access Token:

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Select scopes:
   - `repo` (for private repositories)
   - `read:org` (for organization data)
   - `read:project` (for project boards)
4. Generate and copy the token

Set the token in your environment:

```bash
# Linux/Mac - Add to ~/.bashrc or ~/.zshrc
export GITHUB_TOKEN=ghp_your_token_here

# Windows - PowerShell
$env:GITHUB_TOKEN = "ghp_your_token_here"
```

### Step 2: Global Configuration

Create `~/.claude/claude-grimoire/config.json`:

```json
{
  "github": {
    "org": "your-github-org",
    "defaultRepos": ["repo1", "repo2"]
  }
}
```

This sets default values for your most common repositories.

### Step 3: Per-Repository Configuration (Optional)

For repo-specific customization, create `.claude-grimoire/config.json` in your repository:

```json
{
  "github": {
    "defaultLabels": ["needs-review"],
    "defaultReviewers": ["team-lead"],
    "codeownersPath": ".github/CODEOWNERS"
  },
  "prAuthor": {
    "titlePrefix": "[FEAT]",
    "requireIssueReference": true,
    "includeTestPlan": true
  }
}
```

## Your First PR Description

Let's use the `pr-author` skill to generate your first comprehensive PR description.

### Step 1: Make Changes

```bash
# Create a feature branch
git checkout -b feature/add-login

# Make your changes
# ... edit files ...

# Commit your changes
git add .
git commit -m "Add login functionality"
```

### Step 2: Invoke pr-author

```bash
# In Claude Code
/pr-author
```

The skill will:
1. Analyze your git changes
2. Ask if there are related GitHub issues
3. Generate a comprehensive PR description

### Step 3: Review and Use

The skill presents:
- A concise PR title
- Structured description with summary
- References to issues (e.g., "Closes #123")
- Test plan checklist

You can:
- Copy the description and create the PR manually
- Let the skill create the PR for you (if `gh` CLI is installed)

### Example Output

```markdown
Add JWT-based user authentication

## Summary

- Implemented JWT authentication for API endpoints
- Added login/logout endpoints
- Created auth middleware for protected routes
- Added unit tests for auth service

## Related Issues

Closes #125

## Test Plan

- [x] Unit tests pass (95% coverage)
- [x] Integration tests for login/logout flow
- [x] Manual testing: successful login, token refresh, logout
- [x] Edge cases: expired tokens, invalid credentials

🤖 Generated with claude-grimoire
```

## Common Workflows

### Workflow 1: Feature Development

```bash
# 1. Create initiative (Phase 2+)
/initiative-creator

# 2. Break down into tasks (Phase 2+)
/initiative-breakdown https://github.com/org/repo/issues/123

# 3. Generate visual PRD (Phase 2+)
/visual-prd

# 4. Implement (use staff-developer skill)

# 5. Generate PR description
/pr-author

# 6. Automated PR creation (Phase 4+)
# Invoked by pr-autopilot-team after code review
```

### Workflow 2: Bug Fix

```bash
# 1. Reproduce and fix the bug

# 2. Generate PR description
/pr-author
# (Mention the issue number when prompted)

# 3. PR description will include:
# - "Fixes #234"
# - Description of the bug
# - How it was fixed
# - Test plan
```

### Workflow 3: Incident Response (Phase 3+)

```bash
# 1. Receive Firehydrant alert

# 2. Start incident response
/incident-handler

# 3. Skill will:
# - Gather logs and context
# - Guide diagnosis
# - Help implement fix
# - Generate post-mortem
```

## Tips for Success

### 1. Reference Issues Early

Include issue numbers in your commit messages:

```bash
git commit -m "Add login endpoint (#125)"
```

The `pr-author` skill will automatically detect and fetch context.

### 2. Commit Frequently

Better commit history = better PR descriptions. The skill analyzes your commits to understand what changed.

### 3. Test Before PR

Complete your testing before invoking `pr-author`. The skill will ask about your testing approach.

### 4. Use Descriptive Branch Names

```bash
# Good
git checkout -b feature/jwt-authentication
git checkout -b fix/memory-leak-websocket

# Not as good
git checkout -b feature
git checkout -b bugfix
```

### 5. Configure Per-Repo Settings

Different repos may have different conventions. Use `.claude-grimoire/config.json` to customize:

- PR title prefixes
- Default labels
- Required reviewers
- Test plan requirements

## Troubleshooting

### "Can't access GitHub API"

**Problem:** Skills can't fetch GitHub data

**Solutions:**
1. Verify `GITHUB_TOKEN` is set: `echo $GITHUB_TOKEN`
2. Check token has correct scopes
3. Try `gh auth status` to verify GitHub CLI auth
4. Verify network connectivity to GitHub

### "Issue #123 not found"

**Problem:** Agent can't find referenced issue

**Solutions:**
1. Verify issue number is correct
2. Check you're in the correct repository
3. Ensure the issue isn't in a different org/repo
4. Verify token has access to the repository

### "Rate limit exceeded"

**Problem:** GitHub API rate limit hit

**Solutions:**
1. Wait for rate limit to reset (shown in error message)
2. Use authenticated requests (personal access token)
3. Enable caching in config
4. Reduce depth of context gathering (use "shallow")

### "PR description is too generic"

**Problem:** Generated description lacks detail

**Solutions:**
1. Provide more context when prompted
2. Reference specific issues/initiatives
3. Describe the "why" not just the "what"
4. Use better commit messages

## Next Steps

### Explore More Skills

- **initiative-creator** - Plan new initiatives (Phase 2)
- **visual-prd** - Create visual requirements (Phase 2)
- **incident-handler** - Handle production incidents (Phase 3)

### Customize Your Setup

- Add repo-specific configurations
- Customize PR templates
- Set up Firehydrant integration (for incidents)
- Configure Coralogix access (for log analysis)

### Learn Advanced Features

- **Teams** - Multi-agent workflows (Phase 4)
- **Custom templates** - Match your team's conventions
- **Integration patterns** - How skills call agents

### Join the Community

- Report issues: [GitHub Issues](https://github.com/yourusername/claude-grimoire/issues)
- Share workflows: [Discussions](https://github.com/yourusername/claude-grimoire/discussions)
- Contribute: [CONTRIBUTING.md](../CONTRIBUTING.md)

## FAQ

### Q: Can I use this with private repositories?

**A:** Yes! Ensure your GitHub token has the `repo` scope for private repository access.

### Q: Does this work with GitHub Enterprise?

**A:** Yes! Set the `apiUrl` in your global config:

```json
{
  "github": {
    "apiUrl": "https://github.your-company.com/api/v3"
  }
}
```

### Q: Can I customize the PR description format?

**A:** Yes! Create a `.github/PULL_REQUEST_TEMPLATE.md` in your repo. The skill will merge its output with your template.

### Q: What about other Git platforms (GitLab, Bitbucket)?

**A:** Currently GitHub only, but the architecture supports extensions. Contributions welcome!

### Q: How much does this cost?

**A:** Claude Grimoire is free and open-source (MIT license). You only need Claude Code access and a GitHub account.

### Q: Will this work with my existing workflows?

**A:** Yes! Skills are opt-in. Use them when helpful, continue your existing workflow when not.

### Q: Can I contribute new skills?

**A:** Absolutely! See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## Support

Need help?

- **Documentation:** Check the [full documentation](../README.md)
- **Issues:** [Report a bug](https://github.com/yourusername/claude-grimoire/issues/new)
- **Discussions:** [Ask questions](https://github.com/yourusername/claude-grimoire/discussions)

---

Ready to streamline your workflows? Start with `/pr-author` and go from there! 🚀
