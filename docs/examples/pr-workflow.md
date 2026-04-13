# Example: PR Workflow with pr-author

This example demonstrates using the `pr-author` skill to generate a comprehensive PR description.

## Scenario

You're working on adding JWT authentication to your application. There's an existing GitHub issue #125 that describes the requirements.

## Step-by-Step Workflow

### 1. Create Feature Branch

```bash
git checkout -b feature/jwt-authentication
```

### 2. Implement the Feature

Make your changes:

```bash
# Created files
touch src/auth/jwt.ts
touch src/auth/middleware.ts
touch src/auth/__tests__/jwt.test.ts

# Modified files
# - src/api/routes.ts (added auth middleware)
# - src/config/index.ts (added JWT config)
# - package.json (added jsonwebtoken dependency)
```

### 3. Commit Your Work

```bash
git add .
git commit -m "Add JWT authentication system (#125)

- Implement JWT token generation and validation
- Add auth middleware for protected routes
- Add comprehensive unit tests
- Update API routes to use auth middleware"
```

### 4. Invoke pr-author Skill

```bash
/pr-author
```

### 5. Skill Workflow

The skill will guide you through these steps:

#### Step 1: Verify Git State

```
Let me check your current branch and changes...

✓ Current branch: feature/jwt-authentication
✓ 5 files changed, 347 insertions(+), 12 deletions(-)
✓ 1 commit ahead of main
```

#### Step 2: Identify Related Issues

```
Are there any GitHub issues this PR addresses?
```

**Your response:** `#125`

The skill invokes `github-context-agent` to fetch issue details:

```
✓ Fetched issue #125: "Add user authentication system"
✓ Found acceptance criteria:
  - User can login with email/password
  - JWT token issued on successful login
  - Protected routes require valid token
  - Token refresh mechanism
✓ Identified 2 related comments
```

#### Step 3: Analyze Changes

```
Analyzing your code changes...

✓ Detected: Authentication feature implementation
✓ Files modified: 5
✓ New dependencies: jsonwebtoken
✓ Tests added: Yes (jwt.test.ts)
```

#### Step 4: Ask Clarifying Questions

```
What testing have you done?
```

**Your response:** `Unit tests with 95% coverage, manual testing of login/logout flow, tested edge cases like expired tokens`

```
Are there any breaking changes?
```

**Your response:** `No, this is a new feature`

```
Any migration or deployment notes?
```

**Your response:** `Need to set JWT_SECRET environment variable before deployment`

#### Step 5: Generate PR Title

```
Suggested PR title:

"Add JWT-based user authentication"

Does this look good? (yes/no)
```

**Your response:** `yes`

#### Step 6: Generate PR Description

```markdown
# Generated PR Description:

Add JWT-based user authentication

## Summary

- Implemented JWT token generation and validation
- Added auth middleware for protected routes
- Created login/logout API endpoints
- Added comprehensive unit tests (95% coverage)
- Updated API routes to use authentication

## Related Issues

Closes #125

## Changes

### Added
- `src/auth/jwt.ts`: JWT token generation and validation
- `src/auth/middleware.ts`: Express middleware for route protection
- `src/auth/__tests__/jwt.test.ts`: Unit tests for JWT functionality

### Modified
- `src/api/routes.ts`: Applied auth middleware to protected endpoints
- `src/config/index.ts`: Added JWT configuration options
- `package.json`: Added `jsonwebtoken` dependency

## Test Plan

- [x] Unit tests pass (95% coverage)
- [x] Manual testing: successful login flow
- [x] Manual testing: successful logout flow
- [x] Manual testing: token refresh mechanism
- [x] Edge case: expired token correctly rejected
- [x] Edge case: invalid token correctly rejected
- [x] Edge case: missing token returns 401

## Migration Notes

**Before Deployment:**
- Set `JWT_SECRET` environment variable
- Set `JWT_EXPIRY` (optional, defaults to 24h)

Example:
```bash
export JWT_SECRET=your-secret-key-here
export JWT_EXPIRY=86400
```

## Reviewer Notes

- Token expiry is set to 24 hours by default
- Refresh token mechanism included but not yet hooked up to frontend
- Consider reviewing the secret key management approach

🤖 Generated with [claude-grimoire](https://github.com/yourusername/claude-grimoire)
```

#### Step 7: Review and Refine

```
Does this accurately capture your changes? (yes/no/edit)
```

**Your response:** `yes`

#### Step 8: Create PR

```
Would you like me to create the PR for you? (yes/no)
```

**Your response:** `yes`

The skill runs:

```bash
gh pr create \
  --title "Add JWT-based user authentication" \
  --body "$(cat generated-description.md)" \
  --label "feature" \
  --label "needs-review"
```

```
✓ PR created: https://github.com/org/repo/pull/456
✓ Reviewers assigned based on CODEOWNERS: @security-team, @backend-lead
✓ Labels applied: feature, needs-review
```

## Result

You now have a comprehensive PR with:

- Clear, descriptive title
- Structured description with summary
- Proper issue reference (will close #125 on merge)
- Detailed test plan showing what was verified
- Migration notes for deployment
- Reviewer notes highlighting areas needing attention

All generated in under 2 minutes with the `pr-author` skill!

## Tips for This Workflow

1. **Reference issues in commits** - Include `(#125)` in commit messages so the skill auto-detects related issues

2. **Commit descriptively** - Better commit messages = better PR descriptions

3. **Test first** - Complete your testing before invoking the skill so you can provide accurate test results

4. **Use CODEOWNERS** - The skill will auto-assign reviewers based on your `.github/CODEOWNERS` file

5. **Customize per-repo** - Add `.claude-grimoire/config.json` to set repo-specific defaults:
   ```json
   {
     "prAuthor": {
       "titlePrefix": "[AUTH]",
       "requireIssueReference": true,
       "includeTestPlan": true
     }
   }
   ```

## Advanced: Custom Templates

If you have a `.github/PULL_REQUEST_TEMPLATE.md`, the skill will merge its output with your template:

```markdown
<!-- .github/PULL_REQUEST_TEMPLATE.md -->

## Summary
<!-- Auto-filled by pr-author -->

## Security Checklist
- [ ] No credentials in code
- [ ] Input validation added
- [ ] Error messages don't leak sensitive info

## Related Issues
<!-- Auto-filled by pr-author -->
```

The skill will preserve your custom sections while filling in the standard ones.

## Next Steps

After your PR is created:

1. **Respond to review feedback** - Address comments from reviewers
2. **Update based on CI** - Fix any failing tests or linting issues
3. **Use pr-autopilot-team** (Phase 4) - For future PRs, automate the entire process after code review

## Variations

### Variation 1: Bug Fix PR

For bug fixes, the workflow is similar but the skill adapts:

- Title uses "Fix" instead of "Add"
- Includes reproduction steps
- Emphasizes what broke and why
- Links with "Fixes #234" instead of "Closes"

### Variation 2: Multiple Issues

If your PR addresses multiple issues:

```
Are there any GitHub issues this PR addresses?
> #125, #130, #132

The PR description will include:
Closes #125, #130, #132
```

### Variation 3: Part of Initiative

If part of a larger initiative:

```
Is this part of a larger initiative?
> #100

The PR description will include:
Closes #125
Part of initiative #100
```

---

**Time Saved:** 10-15 minutes per PR × multiple PRs per week = Hours saved monthly! 🚀
