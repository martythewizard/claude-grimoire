---
name: pr-author
description: Generate comprehensive PR descriptions with GitHub issue/initiative references
version: 1.0.0
---

# PR Author Skill

Generate comprehensive, well-structured PR descriptions that properly reference GitHub issues and initiatives.

## Purpose

This skill helps you create pull request descriptions that:
- Clearly communicate what changed and why
- Reference related GitHub issues and initiatives
- Include proper test plans
- Follow your team's PR conventions
- Save time while maintaining quality

## When to Use

Invoke this skill when you're ready to create a pull request and need help writing a clear, comprehensive description.

## How It Works

1. **Analyzes your changes** - Reviews git diff and commit history on your current branch
2. **Gathers context** - Fetches related GitHub issues/initiatives using the `github-context-agent`
3. **Generates description** - Creates a structured PR description with:
   - Concise, descriptive title
   - Summary of changes in bullet points
   - References to related issues (e.g., "Closes #123", "Part of initiative #456")
   - Test plan checklist
   - Visual changes section (if applicable)

## Workflow

### Step 1: Verify Git State

First, I'll check your current branch and changes:

```bash
git status
git diff --stat
git log --oneline -10
```

### Step 2: Identify Related Issues

Ask you:
- "Are there any GitHub issues this PR addresses?"
- "Is this part of a larger initiative?"

If you provide issue/initiative numbers, I'll invoke the `github-context-agent` to fetch:
- Issue titles and descriptions
- Acceptance criteria
- Related PRs
- Stakeholders

### Enhanced Context Gathering (NEW)

After gathering basic PR context (commits, issues), I'll check for initiative/project linkage:

**Check for Initiative/Project Linkage:**

For each issue referenced in commits:
1. Invoke `github-context-agent` with `type="issue"` and the issue number
2. Extract from response:
   - `related_initiative` (if issue is part of initiative)
   - `related_project` (if issue is in project)
   - `related_workstream` (if part of workstream)
   - `related_milestone` (if assigned to milestone)
3. Collect all linkage information

If any linkage is found, I'll add a new "Related Work" section to the PR description with this information.

**Note:** When initiative/project linkage is found, the "Related Work" section replaces the "Related Issues" section from the standard template. When no linkage is found, fall back to the standard "Related Issues" section.

**Enhanced PR Description Template:**

When linkage is detected, use this template:

```markdown
## Summary
[existing summary]

## Related Work

**Issues:**
- Closes #[number] - [title]

**Initiative:** (if applicable)
[Initiative Name](yaml-url)

**Project:** (if applicable)
https://github.com/orgs/[org]/projects/[number]

**Workstream:** (if applicable)
[Workstream Name]

**Milestone:** (if applicable)
[Milestone Title] ([repo])

## Changes
[existing changes section]

[... rest of template ...]
```

### Step 4: Analyze Changes

Review the actual code changes:
```bash
git diff origin/main...HEAD
```

Identify:
- Files modified
- Nature of changes (feature, fix, refactor, docs)
- Scope and complexity

### Step 5: Ask Clarifying Questions

One question at a time:
- "What problem does this solve?"
- "Are there any breaking changes?"
- "What testing have you done?"
- "Are there visual changes?" (if frontend code detected)
- "Any migration steps needed?"

### Step 6: Generate PR Title

Create a concise title (under 70 characters) that:
- Follows your repo's convention (check config for prefixes like "[FEAT]")
- Clearly states what the PR does
- Uses imperative mood ("Add", "Fix", "Update")

Examples:
- ✅ "Add user authentication with JWT tokens"
- ✅ "Fix memory leak in websocket connections"
- ❌ "Updated some files" (too vague)
- ❌ "This PR adds a new feature for handling user authentication using JWT tokens and also refactors..." (too long)

### Step 7: Generate PR Description

Create a structured description:

````markdown
## Summary

- [Bullet point 1: main change]
- [Bullet point 2: related change]
- [Bullet point 3: additional context]

## Related Issues

Closes #123
Part of initiative #456

## Changes

### Added
- New feature X
- API endpoint Y

### Modified
- Updated component Z for better performance

### Removed
- Deprecated function A

## Test Plan

- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed for [scenario]
- [ ] Edge cases verified: [list edge cases]

## Visual Changes

[If applicable]
- Screenshots or video links
- Before/after comparisons

## Migration Notes

[If applicable]
- Any breaking changes
- Required database migrations
- Environment variable changes
- Deployment considerations

## Reviewer Notes

[Any specific areas that need attention]

🤖 Generated with [claude-grimoire](https://github.com/yourusername/claude-grimoire)
````

### Step 8: Review and Refine

Present the generated title and description. Ask:
- "Does this accurately capture your changes?"
- "Any adjustments needed?"

Iterate until you're satisfied.

### Step 9: Optional - Create PR

Ask if you want me to:
- Just provide the description (you create the PR manually)
- Create the PR for you using `gh` CLI

If creating the PR:
```bash
gh pr create --title "Your Title" --body "$(cat <<'EOF'
[Generated description]
EOF
)"
```

## Configuration

### Per-Repo Config (`.claude-grimoire/config.json`)

```json
{
  "prAuthor": {
    "titlePrefix": "[FEAT]",
    "requireIssueReference": true,
    "includeTestPlan": true,
    "includeVisualChanges": true,
    "defaultLabels": ["needs-review"],
    "templatePath": ".github/PULL_REQUEST_TEMPLATE.md"
  }
}
```

### Environment Requirements

- Git repository with remote configured
- GitHub CLI (`gh`) installed (optional, for PR creation)
- GitHub token with appropriate permissions

## Examples

### Example 1: Feature PR

**Input:**
- Changes: Added new authentication system
- Issue: #125
- Manual testing completed

**Output:**
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
- [x] Edge cases: expired tokens, invalid credentials, missing tokens

🤖 Generated with claude-grimoire
```

### Example 2: Bug Fix PR

**Input:**
- Changes: Fixed memory leak in WebSocket handler
- Issue: #234
- Initiative: #100 (Performance improvements)

**Output:**
```markdown
Fix memory leak in WebSocket connection handler

## Summary

- Fixed memory leak caused by unclosed WebSocket connections
- Added connection cleanup on client disconnect
- Implemented connection timeout mechanism

## Related Issues

Closes #234
Part of initiative #100

## Changes

### Modified
- `src/websocket/handler.ts`: Added cleanup logic
- `src/websocket/connection.ts`: Implemented timeout

### Added
- Unit tests for connection lifecycle

## Test Plan

- [x] Memory usage verified under load (no leak detected)
- [x] Connection cleanup confirmed on disconnect
- [x] Timeout mechanism works correctly

## Reviewer Notes

Please pay attention to the timeout value (currently 30s) - may need adjustment based on production usage.

🤖 Generated with claude-grimoire
```

## Tips for Best Results

1. **Commit often** - Better git history = better PR descriptions
2. **Reference issues early** - Link issues in commits for automatic context
3. **Test first** - Complete testing before generating PR description
4. **Be specific** - The more context you provide, the better the description
5. **Review carefully** - Always review and refine the generated description

## Troubleshooting

**"Can't find related issues"**
- Verify issue numbers are correct
- Check GitHub token has read permissions
- Ensure you're in the correct repository

**"PR description is too generic"**
- Provide more context about the changes
- Reference specific issues/initiatives
- Describe the "why" not just the "what"

**"Missing test plan"**
- Set `includeTestPlan: true` in config
- Describe your testing approach when asked

## Integration with Other Components

### Used By
- `pr-autopilot-team` - For automated PR creation after code review

### Uses
- `github-context-agent` - To fetch issue/initiative context

## Advanced Usage

### Custom Templates

Create `.github/PULL_REQUEST_TEMPLATE.md` in your repo:

```markdown
## Summary
<!-- Auto-filled by pr-author -->

## Related Issues
<!-- Auto-filled by pr-author -->

## Custom Section
<!-- Your team-specific section -->
```

The skill will merge its output with your template.

### Multiple Issue References

Support various formats:
- `Closes #123` - Will close the issue when PR merges
- `Fixes #123` - Same as Closes
- `Resolves #123` - Same as Closes
- `Part of #456` - References without closing
- `Related to #789` - Loose reference

### Visual Changes

For frontend PRs, the skill will:
- Detect UI-related file changes
- Prompt for screenshots
- Generate before/after sections
- Include accessibility notes

## Future Enhancements

- Auto-detect breaking changes from API analysis
- Suggest reviewers based on CODEOWNERS and file changes
- Generate release notes from PR descriptions
- Integration with Jira/Linear for cross-tool references
