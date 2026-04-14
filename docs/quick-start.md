# Quick Start Guide

Get started with Claude Grimoire in 5 minutes.

## Prerequisites

- Claude Code CLI or Desktop app
- GitHub account and repository access
- Git configured locally
- `gh` CLI installed (for GitHub operations)

## Installation

### Option 1: Clone for Use (Recommended)

```bash
# Clone the repository
git clone https://github.com/martythewizard/claude-grimoire
cd claude-grimoire

# Review the components
ls skills/     # User-invocable workflows
ls agents/     # Autonomous workers
ls teams/      # Multi-agent orchestration
```

### Option 2: Marketplace Install (When Available)

```bash
/plugin install claude-grimoire
```

## Setup

### 1. Configure GitHub Access

```bash
# Authenticate with GitHub CLI
gh auth login

# Verify authentication
gh auth status

# Set your GitHub token as environment variable
export GITHUB_TOKEN=$(gh auth token)
```

### 2. Create Configuration (Optional)

**Global config** (`~/.claude/claude-grimoire/config.json`):

```json
{
  "github": {
    "org": "your-github-org",
    "defaultRepos": ["repo1", "repo2"]
  }
}
```

**Per-repo config** (`.claude-grimoire/config.json`):

```json
{
  "github": {
    "defaultLabels": ["needs-review"],
    "defaultReviewers": ["team-lead"],
    "codeownersPath": ".github/CODEOWNERS"
  },
  "prAuthor": {
    "requireIssueReference": true,
    "includeTestPlan": true
  }
}
```

## Your First PR Description

The quickest way to see value from Claude Grimoire.

### 1. Make a Change

```bash
cd your-project
git checkout -b feature/add-feature
# ... make changes ...
git add .
git commit -m "Add new feature"
```

### 2. Generate PR Description

In Claude Code, invoke the pr-author skill:

```
/pr-author
```

or if skills aren't registered yet, reference the skill file directly:

```
Read skills/pr-author/skill.md and follow its workflow
```

### 3. Review Generated Description

The skill will:
1. Analyze your git changes
2. Fetch related GitHub issues (if any)
3. Ask clarifying questions
4. Generate a comprehensive PR description

**Example output:**

```markdown
## Summary
Add user authentication with JWT tokens for secure API access.

## Related Issues
Closes #42

## Changes

### Added
- `pkg/auth/jwt.go` - JWT token generation and validation
- `api/handlers/auth_handler.go` - Login/logout endpoints
- `api/middleware/auth_middleware.go` - Token validation middleware

### Modified
- `api/router/router.go` - Added auth routes

## Test Plan
- [x] Unit tests for JWT generation
- [x] Integration tests for auth endpoints
- [x] Token expiry validation
- [x] Invalid token handling

---
🤖 Generated with claude-grimoire
```

### 4. Create PR

```bash
# Push branch
git push -u origin feature/add-feature

# Create PR with generated description
gh pr create --title "Add user authentication" --body "[paste description]"
```

**Result:** Professional PR in 3 minutes (vs 15 minutes manual)

---

## Your First Initiative Planning

Use the planning and breakdown tools to turn ideas into actionable tasks.

### 1. Create an Initiative

Invoke the initiative-creator skill:

```
/initiative-creator
```

The skill will interview you:

**Q:** What problem are you trying to solve?  
**A:** "Users can't filter large datasets in the UI"

**Q:** Who are the primary stakeholders?  
**A:** "Product team and end users"

**Q:** What are the primary goals?  
**A:** "1. Add filtering UI 2. Implement backend filtering 3. Performance <500ms"

*... continues with more questions ...*

**Result:** Well-structured GitHub initiative created with:
- Clear goals and success metrics
- Defined scope (in/out)
- Timeline and milestones
- Risk assessment

### 2. Break Down the Initiative

Once the initiative is created (e.g., #100):

```
/initiative-breakdown owner/repo#100
```

The skill will:
1. Fetch initiative details via github-context-agent
2. Analyze your codebase for patterns
3. Optionally invoke system-architect-agent for complex features
4. Generate ordered tasks with dependencies
5. Create GitHub issues for each task

**Result:** 8 actionable tasks in 15 minutes:

```
Foundation:
- #101: Create filter interface (M, 3 days)
- #102: Add filter config (S, 1 day)

Implementation:
- #103: Add UI filter component (M, 3 days)
- #104: Add backend filter endpoint (M, 3 days)
- #105: Integrate UI with backend (S, 2 days)

Testing:
- #106: Integration tests (M, 2 days)

Documentation:
- #107: Update API docs (S, 1 day)
- #108: Add user guide (S, 1 day)

Total: 16 days (can parallelize to 2 weeks)
Critical path: #101 → #104 → #106
```

---

## Your First Complete Feature Delivery

Use the feature-delivery-team for end-to-end automation.

### 1. Invoke the Team

```
feature-delivery-team
```

**Team:** "Let's start by understanding this feature. Is there an existing GitHub initiative?"

**You:** "No, let's create one"

### 2. Planning Phase

The team invokes `/initiative-creator` and walks you through planning.

**Result:** Initiative #110 created

### 3. Architecture Phase (if complex)

**Team:** "This feature involves creating a new data model. Should I invoke system-architect-agent?"

**You:** "Yes"

**Result:** Architecture designed with:
- Component diagram
- Sequence diagram
- Interface definitions
- Trade-off analysis

### 4. Task Breakdown

The team invokes `/initiative-breakdown #110`

**Result:** 9 tasks created with acceptance criteria

### 5. Implementation Loop

For each task:

**a) Plan Review (if complex)**
- Team creates implementation plan
- Invokes `/two-claude-review` to validate approach
- Iterates on feedback

**b) Implementation**
- Team invokes `staff-developer` with context
- Developer implements following best practices
- Reports completion

**c) Code Review**
- Team invokes `staff-engineer` for review
- If issues found, loops back to staff-developer
- Continues until review passes

**d) PR Creation**
- Team invokes `pr-autopilot-team`
- Automated PR creation with comprehensive description

### 6. Result

- Feature planned, designed, and first task completed in 2-3 hours
- Quality gates caught issues before PR submission
- Comprehensive documentation generated automatically

---

## Common Workflows

### Workflow 1: Simple Bug Fix

```bash
# 1. Fix the bug
git checkout -b fix/memory-leak
# ... fix code ...
git add . && git commit -m "Fix memory leak"

# 2. Generate PR
/pr-author

# 3. Create PR
gh pr create --title "[generated title]" --body "[generated body]"
```

**Time:** 5-10 minutes including PR description

---

### Workflow 2: Feature with Architecture

```bash
# 1. Plan feature
/initiative-creator
# Creates initiative #200

# 2. Break down
/initiative-breakdown owner/repo#200
# Creates 8 tasks

# 3. Design architecture (for task #201)
feature-delivery-team
# Invokes system-architect-agent, staff-developer, staff-engineer

# 4. Automated PR
# pr-autopilot-team creates PR automatically
```

**Time:** 2-3 hours for complete planning and first task

---

### Workflow 3: Automated PR After Manual Implementation

If you prefer to code manually but want automated PR creation:

```bash
# 1. Implement feature manually
git checkout -b feature/my-feature
# ... write code ...
git add . && git commit -m "Implement feature"

# 2. Optional: Get code review
staff-engineer "Review the implementation of feature XYZ"

# 3. Automated PR
pr-autopilot-team
```

**Time:** Variable coding + 3 minutes for PR

---

## Tips for Success

### 1. Link to Issues Early

When starting work, reference the issue in your commit:

```bash
git commit -m "Add pagination (#42)"
```

The pr-author skill will automatically detect and fetch context from #42.

### 2. Use Descriptive Branch Names

```bash
# Good
git checkout -b feature/add-pagination
git checkout -b fix/memory-leak-in-worker

# Less descriptive
git checkout -b feature-1
git checkout -b fix
```

Better branch names help generate better PR titles.

### 3. Configure Per-Repository

Create `.claude-grimoire/config.json` in each repository:

```json
{
  "prAuthor": {
    "titlePrefix": "[TEAM-NAME]",
    "requireIssueReference": true
  },
  "github": {
    "defaultLabels": ["team-label"],
    "defaultReviewers": ["team-lead"]
  }
}
```

Ensures consistency across the team.

### 4. Start with pr-author

Before diving into teams, get comfortable with pr-author:
- Fastest value
- Easiest to understand
- No complex orchestration

Once comfortable, add initiative-creator and initiative-breakdown.

Finally, use feature-delivery-team for complete automation.

### 5. Review Generated Content

Always review:
- PR descriptions before creating PR
- Task breakdowns before creating issues
- Architecture designs before implementing

The tools are very good, but human judgment is still valuable.

---

## Troubleshooting

### "GitHub API authentication failed"

```bash
# Re-authenticate
gh auth login

# Verify
gh auth status

# Set token
export GITHUB_TOKEN=$(gh auth token)
```

### "Issue not found"

Ensure you're using the correct format:

```bash
# Correct
/initiative-breakdown owner/repo#123

# Incorrect
/initiative-breakdown #123
/initiative-breakdown 123
```

### "pr-author can't find related issues"

The skill looks for issue references in:
- Commit messages
- Branch names
- Recent commits

Add references explicitly:

```bash
git commit -m "Add feature (Part of #100)"
```

### "Tests failing in pr-autopilot-team"

The team won't create PRs with failing tests. Either:

```bash
# Fix tests
# ... fix issues ...

# Or skip tests (not recommended)
# Answer "skip tests" when team asks
```

---

## Next Steps

### Learn More

- [Full README](../README.md) - Complete overview
- [Configuration Guide](configuration-guide.md) - All config options
- [Example Workflows](examples/) - Real-world scenarios

### Try Advanced Features

- Use `feature-delivery-team` for complete automation
- Try `visual-prd` for complex features with UI
- Experiment with `system-architect-agent` for architecture design

### Contribute

- Report issues on [GitHub](https://github.com/martythewizard/claude-grimoire/issues)
- Submit improvements via PR
- Share your workflows and examples

---

**You're ready to go!** Start with `/pr-author` and work your way up to complete feature delivery automation.