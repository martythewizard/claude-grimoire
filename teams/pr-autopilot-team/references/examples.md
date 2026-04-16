# PR Autopilot Team - Usage Examples

This file contains example workflows demonstrating how pr-autopilot-team handles different scenarios.

## Example 1: Simple Feature - Clean Path

**Context:**
- Feature branch: `feature/add-dark-mode`
- Issue: #42 (Add dark mode toggle)
- Code reviewed: ✅ staff-engineer approved
- Tests: ✅ Passing

**Team workflow:**

```
User: "Create PR for dark mode feature"

Team: [Phase 1] Pre-flight verification
  ✅ On feature branch
  ✅ No uncommitted changes
  ✅ Tests passing
  ✅ Code reviewed

Team: [Phase 2] Context gathering
  Found commits: 3 commits on feature/add-dark-mode
  Found issues: #42 (Add dark mode toggle)
  Fetched issue context via github-context-agent

Team: [Phase 3] PR description
  Invoked pr-author
  Generated description with:
  - Summary: Add dark mode toggle to settings
  - Closes: #42
  - Changes: Added ThemeToggle component, persistence logic
  - Test plan: ✓ Toggle switches themes, ✓ Preference persisted

Team: [Phase 4] Git operations
  ✅ All changes staged
  ✅ Commit created
  ✅ Pushed to origin/feature/add-dark-mode

Team: [Phase 5] PR creation
  ✅ Created PR #55
  ✅ Applied labels: needs-review, enhancement
  ✅ Assigned reviewers: @team-lead (from CODEOWNERS)
  
Team: [Phase 6] Report
  ✅ PR #55 created successfully
  URL: https://github.com/owner/repo/pull/55
  Next: Wait for human review
```

**Result:** PR created in ~2 minutes, zero manual work

---

## Example 2: Complex Feature - With Fixes

**Context:**
- Feature branch: `feature/multi-tenant`
- Issue: #100 (Multi-tenant support)
- Code reviewed: ⚠️  Minor issues found
- Tests: ❌ Failing

**Team workflow:**

```
User: "Create PR for multi-tenant support"

Team: [Phase 1] Pre-flight verification
  ✅ On feature branch
  ✅ No uncommitted changes
  ⚠️  Tests failing (2 tests)
  
  → Halt: Cannot create PR with failing tests
  Options: 
  A) Fix tests with staff-developer
  B) User will fix
  C) Skip tests (not recommended)

User: "A - Fix the tests"

Team: Invoking staff-developer to fix failing tests
  [staff-developer fixes tests]
  ✅ Tests now passing

Team: Continuing pre-flight...
  ⚠️  Code not reviewed by staff-engineer
  
  → Recommend review before PR
  Options:
  A) Run staff-engineer review now
  B) Skip review
  C) Cancel

User: "A - Review the code"

Team: Invoking staff-engineer
  [staff-engineer reviews]
  ⚠️  Found 2 minor improvements
  - Add comment explaining RLS policy
  - Extract magic number to constant
  
  → Not critical, but recommended
  Options:
  A) Have staff-developer fix
  B) Proceed anyway
  C) User will fix

User: "A - Fix those"

Team: Invoking staff-developer with feedback
  [staff-developer applies improvements]
  ✅ Improvements applied

Team: [Phase 1] Re-verifying...
  ✅ Tests still passing
  ✅ Code reviewed and issues addressed
  ✅ Ready for PR

Team: [Phase 2-6] Continue workflow...
  [Creates PR successfully]
  
Team: [Phase 6] Report
  ✅ PR #101 created
  Note: Had to fix 2 failing tests and apply 2 code review improvements
  Ready for human review
```

**Result:** PR created in ~15 minutes including fixes

---

## Example 3: Multiple Issues

**Context:**
- Feature branch: `feature/auth-improvements`
- Issues: #50 (Rate limiting), #51 (JWT refresh)
- Both issues partially addressed in this PR

**Team workflow:**

```
User: "Create PR for auth improvements"

Team: [Phase 2] Context gathering
  Found commits: 8 commits on feature/auth-improvements
  Found issues: #50, #51
  
  → Question: Does this PR fully close these issues?

User: "#50 is fully closed, #51 is partial (only refresh endpoint, logout still TODO)"

Team: [Phase 3] PR description
  Generated description with:
  - Summary: Improve auth with rate limiting and token refresh
  - Closes: #50
  - Part of: #51 (refresh endpoint implemented, logout deferred)
  
Team: [Phase 4-6] Continue...
  ✅ PR #102 created
  
  Links:
  - Will auto-close #50 when merged
  - Will add comment to #51 (partial progress)
```

**Result:** Correct issue linking for partial work
