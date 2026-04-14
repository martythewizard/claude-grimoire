---
name: pr-autopilot-team
description: Fully automated PR creation after code review passes - handles git operations and PR submission
version: 1.0.0
author: claude-grimoire
team_type: automation
requires:
  - github
  - pr-author
  - github-context-agent
optional:
  - staff-developer
  - staff-engineer
---

# PR Autopilot Team

Fully automated pull request creation team that handles the complete PR workflow after code has been reviewed and approved. Automates git operations, PR description generation, and PR submission with proper labels and reviewers.

## Purpose

Automate the final steps of feature delivery:
- Verify code has passed review
- Run final test suite
- Generate comprehensive PR description
- Create commit with proper formatting
- Push branch to remote
- Create GitHub PR with metadata
- Apply labels and assign reviewers

## When to Use

- After implementation is complete
- Code has passed staff-engineer review
- Tests are written and passing locally
- Ready to submit PR for human review
- Want to eliminate manual PR creation overhead

## Important Context

**This team assumes code review already happened.** It is NOT a substitute for:
- staff-developer implementation
- staff-engineer code review
- Iterative feedback loops

**This is the final automation step** after quality gates pass.

## Team Members

### Skills
- `pr-author` - Generate PR descriptions
- `github-context-agent` - Fetch related issues/initiatives

### Optional
- `staff-developer` - If minor fixes needed
- `staff-engineer` - If final verification needed

## Workflow

### Phase 1: Pre-flight Verification

**Goal:** Ensure code is ready for PR

**Process:**

1. **Verify git state:**
   ```bash
   # Check we're on a feature branch
   current_branch=$(git branch --show-current)
   
   if [[ "$current_branch" == "main" ]] || [[ "$current_branch" == "master" ]]; then
     Error: "Cannot create PR from main/master branch"
     Ask: "Would you like me to create a feature branch?"
   fi
   
   # Check for uncommitted changes
   if git status --porcelain | grep -q .; then
     Warning: "Uncommitted changes detected"
     Ask: "Should I commit these changes before creating PR?"
   fi
   ```

2. **Verify tests pass:**
   ```bash
   # Run test suite
   Ask user: "Should I run the test suite before creating PR? (Recommended)"
   
   If yes:
     # Run tests based on project type
     - Go: go test ./...
     - Node: npm test
     - Python: pytest
     - Etc.
     
     If tests fail:
       Error: "Tests failing. Cannot create PR."
       Options:
       A) Fix tests first (invoke staff-developer)
       B) User will fix manually
       C) Skip tests (not recommended, warn user)
   ```

3. **Verify review happened:**
   ```
   Ask user: "Has this code been reviewed by staff-engineer?"
   
   If no:
     Warning: "Code review recommended before PR submission"
     Options:
     A) Run staff-engineer review now
     B) Skip review (proceed anyway)
     C) Cancel PR creation
   
   If user chooses A:
     Invoke staff-engineer for quick review
     If issues found: Present to user, halt PR creation
   ```

**Output:** Verified code ready for PR

---

### Phase 2: Context Gathering

**Goal:** Collect information for PR description

**Process:**

1. **Analyze git history:**
   ```bash
   # Get commits on this branch
   git log main..HEAD --oneline
   
   # Get diff summary
   git diff main --stat
   git diff main --numstat | awk '{sum+=$1+$2} END {print "+/-", sum}'
   ```

2. **Identify related issues:**
   ```bash
   # Check commit messages for issue references
   git log main..HEAD --grep='#[0-9]' --oneline
   
   # Extract issue numbers
   issue_numbers=$(git log main..HEAD | grep -oE '#[0-9]+' | sort -u)
   ```

3. **Fetch issue context via github-context-agent:**
   ```
   For each issue number:
     Invoke github-context-agent({
       "type": "issue",
       "identifier": "owner/repo#[number]",
       "depth": "standard"
     })
     
     Collect:
     - Issue title and description
     - Acceptance criteria
     - Related initiative (if any)
     - Labels
   ```

4. **Determine PR scope:**
   ```
   Ask user:
   - "What issue(s) does this PR address?" (default: detected from commits)
   - "Does this fully close the issue or is it partial?" (Closes vs Part of)
   - "Any notable implementation decisions to highlight?"
   - "Any known limitations or follow-up work needed?"
   ```

**Output:** Complete context for PR description

---

### Phase 3: PR Description Generation

**Goal:** Create comprehensive PR description

**Process:**

1. **Invoke pr-author skill:**
   ```
   /pr-author
   
   Provide context:
   - Related issues from Phase 2
   - Commit history
   - Diff summary
   - User's answers to questions
   
   Skill generates:
   - Concise PR title (<70 chars)
   - Summary with bullet points
   - Related issues (Closes #X, Part of #Y)
   - Changes section (Added/Modified/Removed)
   - Test plan checklist
   - Implementation notes
   - Migration notes (if applicable)
   ```

2. **Review with user:**
   ```
   Present generated PR description
   
   Ask: "Does this PR description look good?"
   
   Options:
   A) Looks good, proceed
   B) Let me adjust [section]
   C) Start over with different context
   
   Iterate until approved
   ```

**Output:** Approved PR description

---

### Phase 4: Git Operations

**Goal:** Commit changes and push to remote

**Process:**

1. **Stage changes:**
   ```bash
   # Check what needs staging
   unstaged=$(git status --porcelain | grep -E '^ M|^??')
   
   if [ -n "$unstaged" ]; then
     Ask: "Stage all changes? Or select specific files?"
     
     If all:
       git add -A
     
     If specific:
       Present file list
       User selects files
       git add [selected files]
   fi
   ```

2. **Create commit:**
   ```bash
   # Generate commit message from PR description
   commit_message="[PR title from pr-author]
   
   [First paragraph of summary]
   
   Related: #[issue numbers]
   
   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
   
   # Commit with message
   git commit -m "$commit_message"
   ```

3. **Push to remote:**
   ```bash
   # Check if branch exists on remote
   if git ls-remote --heads origin $current_branch | grep -q $current_branch; then
     # Branch exists, push updates
     git push origin $current_branch
   else
     # New branch, set upstream
     git push -u origin $current_branch
   fi
   ```

4. **Handle push failures:**
   ```
   If push fails (behind remote):
     Warning: "Local branch behind remote"
     Options:
     A) Pull with rebase (git pull --rebase)
     B) Force push (dangerous, confirm first)
     C) Cancel PR creation
   
   If push fails (authentication):
     Error: "Git authentication failed"
     Suggest: "Run 'gh auth login' or set up SSH keys"
     Cancel PR creation
   ```

**Output:** Changes pushed to remote branch

---

### Phase 5: PR Creation

**Goal:** Create GitHub PR with proper metadata

**Process:**

1. **Create PR:**
   ```bash
   gh pr create \
     --title "[PR title from pr-author]" \
     --body "[PR description from pr-author]" \
     --base main \
     --head $current_branch
   ```

2. **Apply labels:**
   ```bash
   # Get labels from config and issue context
   labels=$(get_labels_from_config)  # e.g., "needs-review"
   issue_labels=$(get_labels_from_issue)  # e.g., "enhancement", "security"
   
   # Combine and apply
   all_labels=$(echo "$labels $issue_labels" | tr ' ' '\n' | sort -u)
   
   for label in $all_labels; do
     gh pr edit --add-label "$label"
   done
   ```

3. **Assign reviewers:**
   ```bash
   # Option 1: Parse CODEOWNERS
   if [ -f ".github/CODEOWNERS" ]; then
     # Get reviewers for changed files
     reviewers=$(get_reviewers_from_codeowners)
     
     for reviewer in $reviewers; do
       gh pr edit --add-reviewer "$reviewer"
     done
   fi
   
   # Option 2: Use default reviewers from config
   default_reviewers=$(get_default_reviewers_from_config)
   
   for reviewer in $default_reviewers; do
     gh pr edit --add-reviewer "$reviewer"
   done
   
   # Option 3: Ask user
   Ask: "Add any specific reviewers? (Leave empty for defaults)"
   ```

4. **Set draft status:**
   ```bash
   # Check config for default draft status
   set_as_draft=$(get_config "prAutopilot.setAsDraft")
   
   if [ "$set_as_draft" == "true" ]; then
     gh pr ready --undo  # Mark as draft
   fi
   ```

5. **Link to issues:**
   ```bash
   # GitHub automatically links "Closes #X" and "Part of #Y" in PR body
   # No additional action needed
   ```

**Output:** Created PR with all metadata

---

### Phase 6: Completion Report

**Goal:** Inform user of success and next steps

**Process:**

1. **Gather PR details:**
   ```bash
   pr_url=$(gh pr view --json url -q .url)
   pr_number=$(gh pr view --json number -q .number)
   pr_checks=$(gh pr view --json statusCheckRollup -q .statusCheckRollup)
   ```

2. **Generate report:**
   ```markdown
   ✅ Pull Request Created Successfully!
   
   **PR #[number]:** [URL]
   **Title:** [PR title]
   
   **Status:**
   - Branch: [branch name]
   - Base: main
   - Commits: [N commits]
   - Files changed: [N files]
   - Insertions: +[X] lines
   - Deletions: -[Y] lines
   
   **Metadata:**
   - Labels: [list of labels]
   - Reviewers: [list of reviewers]
   - Draft: [Yes/No]
   
   **Related:**
   - Closes: #[issue numbers]
   - Part of: #[initiative numbers]
   
   **CI/CD Status:**
   - [Check 1]: [status]
   - [Check 2]: [status]
   
   **Next Steps:**
   1. ⏳ Wait for CI/CD checks to pass
   2. 👀 Address reviewer feedback if any
   3. ✅ Merge when approved
   4. 🚀 Deploy to production
   
   **Timeline Estimate:**
   - Review time: 1-2 days (typical)
   - CI/CD time: 5-10 minutes
   ```

3. **Present to user:**
   ```
   Show report
   
   Additional options:
   "Would you like me to:
   A) Monitor CI/CD status and notify on failure
   B) Open PR in browser
   C) Nothing, I'm done here"
   ```

**Output:** User informed of PR status

---

## Configuration

The team respects configuration from `.claude-grimoire/config.json`:

```json
{
  "prAutopilot": {
    "autoAssignReviewers": true,
    "setAsDraft": false,
    "runTests": true,
    "requireReview": true,
    "defaultLabels": ["needs-review", "automated"]
  },
  "github": {
    "defaultReviewers": ["team-lead", "senior-dev"],
    "codeownersPath": ".github/CODEOWNERS"
  }
}
```

## Usage Examples

### Example 1: Simple Feature - Clean Path

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

### Example 2: Complex Feature - With Fixes

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

### Example 3: Multiple Issues

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

---

## Decision Trees

### Should we run tests?

```
Config: prAutopilot.runTests = true → Yes, run tests
  ↓ false
User preference → Ask user
  ↓ Skip
Proceed without tests (warn user)
```

### Should we require code review?

```
Config: prAutopilot.requireReview = true → Yes, verify review
  ↓ false
Optional, ask user → User decides
  ↓ Skip
Proceed without review (not recommended)
```

### What commit message format?

```
Single commit on branch → Use that commit message
  ↓ Multiple commits
Generate from PR description → Use PR title + summary
  ↓ Squash merge expected
Short message OK → PR title only
```

## Best Practices

### Do:
- ✅ Always verify tests pass before PR
- ✅ Always confirm code review happened
- ✅ Generate comprehensive PR descriptions
- ✅ Apply appropriate labels automatically
- ✅ Assign reviewers from CODEOWNERS
- ✅ Link to all related issues
- ✅ Use proper issue references (Closes vs Part of)

### Don't:
- ❌ Create PRs with failing tests
- ❌ Skip code review for features
- ❌ Create vague PR descriptions
- ❌ Force push without confirmation
- ❌ Commit secrets or sensitive data
- ❌ Create PRs from main/master branch

## Error Handling

### Tests Failing
```
Error: Tests failing (2 failed)

Options:
A) Show test output and fix
B) Skip tests (warn: not recommended)
C) Cancel PR creation

Recommend: A
```

### Push Rejected
```
Error: Push rejected (branch behind remote)

Options:
A) Pull with rebase
B) Force push (confirm first!)
C) Cancel PR creation

Recommend: A
```

### No Issues Found
```
Warning: No issue references found in commits

Options:
A) Specify issue manually
B) Create PR without issue link
C) Cancel PR creation

Recommend: A
```

### CODEOWNERS Not Found
```
Warning: .github/CODEOWNERS not found

Options:
A) Use default reviewers from config
B) Specify reviewers manually  
C) Skip auto-assign reviewers

Recommend: A
```

## Integration with Other Components

### Phase 1 Components
- `pr-author` - Generates PR descriptions (required)
- `github-context-agent` - Fetches issue context (required)

### External Skills
- `staff-developer` - Fixes issues if tests fail (optional)
- `staff-engineer` - Reviews code if not yet reviewed (optional)

### Git Tools
- `git` - All git operations (required)
- `gh` - GitHub CLI for PR creation (required)

## Success Criteria

The team is successful when:
- ✅ PRs created in <5 minutes
- ✅ Zero manual git operations needed
- ✅ Comprehensive PR descriptions
- ✅ Proper issue linking (auto-close when merged)
- ✅ Appropriate reviewers assigned
- ✅ Labels applied correctly
- ✅ No failed PRs due to test/review skipping
- ✅ User confidence in automated process

## Time Savings

**Traditional PR creation time:**
- Stage changes: 30 seconds
- Write commit message: 2-3 minutes
- Push to remote: 30 seconds
- Navigate to GitHub: 30 seconds
- Fill PR form: 5-10 minutes
- Add labels: 30 seconds
- Assign reviewers: 1 minute
- **Total: 10-15 minutes per PR**

**With pr-autopilot-team:**
- Invoke team: 10 seconds
- Answer questions: 1-2 minutes
- Team executes: 1-2 minutes
- **Total: 2-4 minutes per PR**

**Savings:** 6-11 minutes per PR (60-75% reduction)

**Additional benefits:**
- Zero mistakes in issue references
- Consistent PR description quality
- Never forget to assign reviewers
- Always includes proper test plan