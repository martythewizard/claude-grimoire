# PR Autopilot Auto-Merge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Phase 7 auto-merge functionality to pr-autopilot-team with `/check-and-merge` command

**Architecture:** Extract example workflows to references directory, then add Phase 7 that checks PR readiness criteria (approval, conversations resolved, CI/CD checks passing) and merges when all conditions met. User-triggered via command, not polling.

**Tech Stack:** Markdown (team documentation), GitHub CLI (`gh`), `jq` (JSON parsing), Git, Bash scripting examples

---

## File Structure

**Files to modify:**
- `teams/pr-autopilot-team/team.md` - Add Phase 7, update config, extract examples (lines 451-615)

**Files to create:**
- `teams/pr-autopilot-team/references/` - New directory
- `teams/pr-autopilot-team/references/examples.md` - Extracted examples

**Files to verify:**
- `.claude-grimoire/config.json` - Ensure exists or document structure (not modifying, just reference)

---

### Task 1: Create References Directory Structure

**Files:**
- Create: `teams/pr-autopilot-team/references/`
- Test: Directory exists check

- [ ] **Step 1: Create references directory**

```bash
mkdir -p teams/pr-autopilot-team/references
```

- [ ] **Step 2: Verify directory created**

Run: `ls -la teams/pr-autopilot-team/`

Expected output should include:
```
drwxr-xr-x references
-rw-r--r-- team.md
```

- [ ] **Step 3: Commit directory creation**

```bash
git add teams/pr-autopilot-team/references/.gitkeep
touch teams/pr-autopilot-team/references/.gitkeep
git add teams/pr-autopilot-team/references/.gitkeep
git commit -m "feat: add references directory to pr-autopilot-team

Prepare for extracting example workflows from main team.md

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 2: Extract Examples to References File

**Files:**
- Read: `teams/pr-autopilot-team/team.md:451-615`
- Create: `teams/pr-autopilot-team/references/examples.md`

- [ ] **Step 1: Read current examples section**

Run: `sed -n '450,615p' teams/pr-autopilot-team/team.md | head -20`

Expected: Should see "## Usage Examples" header

- [ ] **Step 2: Create examples.md with extracted content**

Create file `teams/pr-autopilot-team/references/examples.md`:

```markdown
# PR Autopilot Team - Usage Examples

This file contains example workflows demonstrating how pr-autopilot-team handles different scenarios.

## Example 1: Simple Feature - Clean Path

**Context:**
- Feature branch: `feature/add-dark-mode`
- Issue: #42 (Add dark mode toggle)
- Code reviewed: ✅ staff-engineer approved
- Tests: ✅ Passing

**Team workflow:**

\`\`\`
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
\`\`\`

**Result:** PR created in ~2 minutes, zero manual work

---

## Example 2: Complex Feature - With Fixes

**Context:**
- Feature branch: `feature/multi-tenant`
- Issue: #100 (Multi-tenant support)
- Code reviewed: ⚠️  Minor issues found
- Tests: ❌ Failing

**Team workflow:**

\`\`\`
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
\`\`\`

**Result:** PR created in ~15 minutes including fixes

---

## Example 3: Multiple Issues

**Context:**
- Feature branch: `feature/auth-improvements`
- Issues: #50 (Rate limiting), #51 (JWT refresh)
- Both issues partially addressed in this PR

**Team workflow:**

\`\`\`
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
\`\`\`

**Result:** Correct issue linking for partial work
```

- [ ] **Step 3: Verify examples.md created**

Run: `cat teams/pr-autopilot-team/references/examples.md | head -20`

Expected: Should see header "# PR Autopilot Team - Usage Examples"

- [ ] **Step 4: Commit examples.md**

```bash
git add teams/pr-autopilot-team/references/examples.md
git commit -m "docs: extract pr-autopilot-team examples to references

Move 3 example workflows from team.md to references/examples.md
to shorten main team file before adding Phase 7.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 3: Remove Examples from team.md

**Files:**
- Modify: `teams/pr-autopilot-team/team.md:450-617`

- [ ] **Step 1: Read current examples section**

Run: `sed -n '450,617p' teams/pr-autopilot-team/team.md`

Expected: Should see "## Usage Examples" through "**Result:** Correct issue linking"

- [ ] **Step 2: Remove examples section and add reference link**

In `teams/pr-autopilot-team/team.md`, find line ~450 (the "## Usage Examples" header).

Delete from "## Usage Examples" through the end of Example 3 (around line 615).

Replace with:

```markdown
## Usage Examples

See [examples.md](./references/examples.md) for detailed workflow examples including:
- Example 1: Simple Feature - Clean Path
- Example 2: Complex Feature - With Fixes
- Example 3: Multiple Issues
```

- [ ] **Step 3: Verify examples removed**

Run: `grep -n "## Usage Examples" teams/pr-autopilot-team/team.md`

Expected: Should show single line with reference link to examples.md

- [ ] **Step 4: Verify file still valid**

Run: `head -50 teams/pr-autopilot-team/team.md && tail -50 teams/pr-autopilot-team/team.md`

Expected: Should see proper YAML frontmatter at start, and decision trees/best practices at end

- [ ] **Step 5: Commit removal**

```bash
git add teams/pr-autopilot-team/team.md
git commit -m "refactor: move pr-autopilot-team examples to references

Replace inline examples with reference link to
teams/pr-autopilot-team/references/examples.md

Reduces main team.md from 769 to ~620 lines before adding Phase 7.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 4: Add Phase 7 Section to team.md

**Files:**
- Modify: `teams/pr-autopilot-team/team.md` (after Phase 6, before Decision Trees)

- [ ] **Step 1: Find insertion point**

Run: `grep -n "## Decision Trees" teams/pr-autopilot-team/team.md`

Expected: Should show line number where Decision Trees section starts (was ~620, now ~467 after example removal)

- [ ] **Step 2: Insert Phase 7 content before Decision Trees**

In `teams/pr-autopilot-team/team.md`, find the line before "## Decision Trees".

Insert the following Phase 7 section:

```markdown
---

### Phase 7: Monitor and Auto-Merge

**Goal:** Check PR readiness and merge when all criteria are met

**Trigger Options:**
1. After Phase 6 completion - team asks user if they want to check and merge
2. User runs `/check-and-merge` from any branch with a PR
3. User runs `/check-and-merge #123` to check specific PR

**Process:**

#### 1. Verify PR Exists

\`\`\`bash
# Get PR for current branch
pr_number=$(gh pr view --json number -q .number 2>/dev/null)

if [ -z "$pr_number" ]; then
  Error: "No PR found for current branch"
  
  Suggest:
  - Run this command from the branch with a PR
  - Or specify PR number: /check-and-merge #123
  
  Exit Phase 7
fi
\`\`\`

**If PR number provided:** Use provided number instead of detecting from branch

#### 2. Fetch PR Status

\`\`\`bash
# Get comprehensive PR status
gh pr view $pr_number --json \
  state,mergeable,reviewDecision,statusCheckRollup,reviews,reviewThreads \
  > /tmp/pr_status_$pr_number.json

# Verify fetch succeeded
if [ $? -ne 0 ]; then
  Error: "Failed to fetch PR status from GitHub"
  
  Possible causes:
  - GitHub API rate limit exceeded
  - Network timeout
  - Invalid PR number
  - No GitHub authentication (run: gh auth login)
  
  Exit Phase 7
fi
\`\`\`

#### 3. Check Merge Criteria

Check each criterion in order, tracking status:

**A) PR State = OPEN**

\`\`\`bash
state=$(jq -r .state /tmp/pr_status_$pr_number.json)

if [ "$state" != "OPEN" ]; then
  Error: "PR is $state, cannot merge"
  
  If state = "CLOSED":
    - PR was closed without merging
  If state = "MERGED":
    - PR already merged
  
  Exit Phase 7
fi

✅ State: Open
\`\`\`

**B) No Merge Conflicts**

\`\`\`bash
mergeable=$(jq -r .mergeable /tmp/pr_status_$pr_number.json)

if [ "$mergeable" != "MERGEABLE" ]; then
  Error: "PR has merge conflicts"
  
  Resolution steps:
  1. Pull latest main: git checkout main && git pull
  2. Rebase your branch: git checkout [branch] && git rebase main
  3. Resolve conflicts in files listed by git
  4. Continue rebase: git rebase --continue
  5. Force push: git push --force-with-lease
  6. Run /check-and-merge again
  
  Exit Phase 7
fi

✅ Conflicts: None
\`\`\`

**C) At Least 1 Approval**

\`\`\`bash
review_decision=$(jq -r .reviewDecision /tmp/pr_status_$pr_number.json)

if [ "$review_decision" != "APPROVED" ]; then
  # Count current approvals
  current_approvals=$(jq '[.reviews[] | select(.state == "APPROVED")] | length' \
    /tmp/pr_status_$pr_number.json)
  
  Error: "PR not approved (current: $current_approvals, required: 1)"
  
  # Show reviewer status
  Assigned reviewers:
  $(jq -r '.reviews[] | "- @\(.author.login): \(.state)"' \
    /tmp/pr_status_$pr_number.json)
  
  Resolution steps:
  1. Address any requested changes
  2. Request review from assigned reviewers
  3. Wait for approval
  4. Run /check-and-merge again
  
  Exit Phase 7
fi

✅ Approvals: [count] approved
\`\`\`

**D) All Conversations Resolved**

\`\`\`bash
unresolved=$(jq '[.reviewThreads[] | select(.isResolved == false)] | length' \
  /tmp/pr_status_$pr_number.json)

if [ "$unresolved" -gt 0 ]; then
  Error: "$unresolved unresolved conversation(s)"
  
  # List unresolved threads
  Unresolved threads:
  $(jq -r '.reviewThreads[] | select(.isResolved == false) | 
    "- \(.comments[0].path):\(.comments[0].position) - \(.comments[0].body[0:80])..."' \
    /tmp/pr_status_$pr_number.json)
  
  Resolution steps:
  1. Address each conversation thread in the PR
  2. Click "Resolve conversation" when addressed
  3. Run /check-and-merge again
  
  Exit Phase 7
fi

✅ Conversations: All resolved (0 unresolved)
\`\`\`

**E) All Required Checks Passing**

\`\`\`bash
# Get status check rollup
checks=$(jq -r '.statusCheckRollup' /tmp/pr_status_$pr_number.json)

# If no checks configured, skip
if [ "$checks" = "null" ] || [ -z "$checks" ]; then
  ⚠️  No CI/CD checks configured
  Warning: "No status checks found - merge protection may be disabled"
else
  # Check each status
  failing_checks=$(jq -r '[.statusCheckRollup[] | 
    select(.conclusion != "SUCCESS" and .status != "COMPLETED")] | length' \
    /tmp/pr_status_$pr_number.json)
  
  if [ "$failing_checks" -gt 0 ]; then
    Error: "$failing_checks check(s) not passing"
    
    # Show check status
    Check status:
    $(jq -r '.statusCheckRollup[] | 
      if .conclusion == "SUCCESS" then
        "- ✅ \(.name): SUCCESS"
      elif .status == "IN_PROGRESS" then
        "- ⏳ \(.name): IN_PROGRESS"
      else
        "- ❌ \(.name): \(.conclusion // .status)"
      end' /tmp/pr_status_$pr_number.json)
    
    Resolution steps:
    1. Review check logs for failures
    2. Fix issues locally
    3. Push fixes to branch
    4. Wait for checks to re-run
    5. Run /check-and-merge again
    
    Exit Phase 7
  fi
  
  ✅ CI/CD Checks: All required checks passing
fi
\`\`\`

#### 4. Display Status Summary

**If all criteria met (ready to merge):**

\`\`\`
PR #$pr_number Ready to Merge! ✅

✅ State: Open
✅ Conflicts: None
✅ Approvals: [count] approved
✅ Conversations: All resolved
✅ CI/CD Checks: All [count] required checks passing

Detected merge method: [method] (from repo settings)

Proceed with merge?
A) Yes, merge now with [method]
B) Use different method (squash/merge/rebase)
C) Cancel
\`\`\`

**If not ready to merge:**

\`\`\`
PR #$pr_number Status Check

[Status indicators for each criterion]

Not ready to merge yet.

What would you like to do?
A) I'll run /check-and-merge again when ready
B) Show me detailed status for each check
C) Cancel
\`\`\`

#### 5. Determine Merge Method

**Detect from repository settings:**

\`\`\`bash
# Query repo settings
repo_settings=$(gh repo view --json \
  squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed)

# Determine default method
if [ "$(echo $repo_settings | jq -r .squashMergeAllowed)" = "true" ]; then
  default_method="squash"
elif [ "$(echo $repo_settings | jq -r .rebaseMergeAllowed)" = "true" ]; then
  default_method="rebase"
else
  default_method="merge"
fi

# Check config override
config_method=$(jq -r '.prAutopilot.autoMerge.defaultMergeMethod // null' \
  .claude-grimoire/config.json 2>/dev/null)

if [ "$config_method" != "null" ]; then
  default_method="$config_method"
fi
\`\`\`

**Allow user override:**

\`\`\`
Ask user: "Merge using [$default_method]? 
Options:
- squash: Combine all commits into one
- merge: Create merge commit preserving history
- rebase: Replay commits onto main
- default: Use [$default_method]

Enter method or press Enter for default:"

merge_method=${user_choice:-$default_method}
\`\`\`

#### 6. Execute Merge

\`\`\`bash
# Merge the PR
gh pr merge $pr_number --$merge_method --auto

if [ $? -ne 0 ]; then
  Error: "Merge failed"
  
  Common causes:
  - Branch protection rules not met
  - Insufficient permissions
  - PR state changed (new commits, conflicts)
  
  Show error output:
  [Error message from gh command]
  
  Suggestion: "Run /check-and-merge again to see updated status"
  
  Exit Phase 7
fi

✅ Merge initiated
\`\`\`

#### 7. Post-Merge Actions

**Branch cleanup (if configured):**

\`\`\`bash
# Check config
delete_branch=$(jq -r '.prAutopilot.autoMerge.deleteBranchAfterMerge // false' \
  .claude-grimoire/config.json 2>/dev/null)

if [ "$delete_branch" = "true" ]; then
  branch_name=$(gh pr view $pr_number --json headRefName -q .headRefName)
  
  Ask user: "Delete branch '$branch_name'? (Y/n)"
  
  if [ "$response" != "n" ]; then
    # Switch to main if on the branch
    current_branch=$(git branch --show-current)
    if [ "$current_branch" = "$branch_name" ]; then
      git checkout main
    fi
    
    # Delete local branch
    git branch -D $branch_name 2>/dev/null
    
    # Delete remote branch (GitHub may auto-delete)
    git push origin --delete $branch_name 2>/dev/null || true
    
    ✅ Branch $branch_name deleted
  fi
fi
\`\`\`

**Success notification:**

\`\`\`
✅ PR #$pr_number Merged Successfully!

Details:
- Merge method: $merge_method
- Merged into: main
- Branch deleted: [yes/no]
- Merge commit: $(gh pr view $pr_number --json mergeCommit -q .mergeCommit.oid)

Next steps:
1. ✅ Changes are now in main
2. 🚀 Check deployment status (if applicable)
3. 📊 Monitor production metrics

View merged PR: $(gh pr view $pr_number --json url -q .url)
\`\`\`

**Optional deployment check:**

\`\`\`
auto_check_deploy=$(jq -r '.prAutopilot.autoMerge.autoCheckDeployment // false' \
  .claude-grimoire/config.json 2>/dev/null)

if [ "$auto_check_deploy" = "true" ]; then
  Ask user: "Check deployment status? (Y/n)"
  
  if [ "$response" != "n" ]; then
    # Query deployment status
    gh api repos/{owner}/{repo}/deployments \
      --jq '.[] | select(.ref == "main") | 
      "Environment: \(.environment), State: \(.state)"' | head -5
  fi
fi
\`\`\`

**Output:** Successfully merged PR with all safety checks validated

---
```

- [ ] **Step 3: Verify Phase 7 inserted**

Run: `grep -n "### Phase 7: Monitor and Auto-Merge" teams/pr-autopilot-team/team.md`

Expected: Should show line number where Phase 7 starts

- [ ] **Step 4: Verify section order**

Run: `grep -n "^### Phase" teams/pr-autopilot-team/team.md`

Expected output:
```
[line]: ### Phase 1: Pre-flight Verification
[line]: ### Phase 2: Context Gathering
[line]: ### Phase 3: PR Description Generation
[line]: ### Phase 4: Git Operations
[line]: ### Phase 5: PR Creation
[line]: ### Phase 6: Completion Report
[line]: ### Phase 7: Monitor and Auto-Merge
```

- [ ] **Step 5: Commit Phase 7 addition**

```bash
git add teams/pr-autopilot-team/team.md
git commit -m "feat: add Phase 7 auto-merge to pr-autopilot-team

Add Phase 7 that checks PR readiness (approvals, conversations,
CI/CD checks) and merges when all criteria met.

Supports:
- /check-and-merge command (current branch)
- /check-and-merge #123 (specific PR)
- Configurable merge strategy
- Branch cleanup after merge
- Comprehensive error messages

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 5: Update Phase 6 to Offer Phase 7

**Files:**
- Modify: `teams/pr-autopilot-team/team.md` (Phase 6 completion message)

- [ ] **Step 1: Find Phase 6 completion message**

Run: `grep -n "Completion Report" teams/pr-autopilot-team/team.md`

Expected: Should show line number of Phase 6 section

- [ ] **Step 2: Read current Phase 6 completion**

Run: `sed -n '/Phase 6/,/^---$/p' teams/pr-autopilot-team/team.md | tail -30`

Expected: Should see "Next Steps:" section at end of Phase 6

- [ ] **Step 3: Update Phase 6 completion to offer Phase 7**

Find the end of Phase 6 (after the completion report example), before the "---" separator.

Update the "Present to user" section to include Phase 7 option:

```markdown
3. **Present to user:**
   \`\`\`
   Show report
   
   Would you like me to:
   A) Check and merge when approved (/check-and-merge)
   B) Monitor CI/CD status and notify on failure
   C) Open PR in browser
   D) Nothing, I'm done here
   
   If user chooses A: Proceed to Phase 7
   \`\`\`
```

- [ ] **Step 4: Verify Phase 6 updated**

Run: `sed -n '/Phase 6/,/^---$/p' teams/pr-autopilot-team/team.md | grep -A 3 "Would you like me to"`

Expected: Should see option A mentions "Check and merge when approved"

- [ ] **Step 5: Commit Phase 6 update**

```bash
git add teams/pr-autopilot-team/team.md
git commit -m "feat: integrate Phase 7 offer into Phase 6 completion

After PR creation, offer user option to check and merge when
approved, connecting Phase 6 to new Phase 7 workflow.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 6: Update Configuration Section

**Files:**
- Modify: `teams/pr-autopilot-team/team.md:430-448` (Configuration section)

- [ ] **Step 1: Find configuration section**

Run: `grep -n "^## Configuration" teams/pr-autopilot-team/team.md`

Expected: Should show line number (~430 before changes, will shift after Phase 7 addition)

- [ ] **Step 2: Update configuration JSON**

In `teams/pr-autopilot-team/team.md`, find the Configuration section.

Update the JSON example to include autoMerge settings:

```json
{
  "prAutopilot": {
    "autoAssignReviewers": true,
    "setAsDraft": false,
    "runTests": true,
    "requireReview": true,
    "defaultLabels": ["needs-review", "automated"],
    "autoMerge": {
      "enabled": true,
      "deleteBranchAfterMerge": true,
      "requireAllConversationsResolved": true,
      "minApprovals": 1,
      "respectBranchProtection": true,
      "defaultMergeMethod": null,
      "autoCheckDeployment": false
    }
  },
  "github": {
    "defaultReviewers": ["team-lead", "senior-dev"],
    "codeownersPath": ".github/CODEOWNERS"
  }
}
```

- [ ] **Step 3: Add configuration option descriptions**

After the JSON example, add:

```markdown

**Auto-Merge Configuration:**

- `enabled` - Enable/disable Phase 7 functionality (default: true)
- `deleteBranchAfterMerge` - Prompt to delete branch after successful merge (default: true)
- `requireAllConversationsResolved` - Block merge if review threads unresolved (default: true)
- `minApprovals` - Minimum approvals required (overridden by branch protection) (default: 1)
- `respectBranchProtection` - Honor GitHub branch protection rules (default: true)
- `defaultMergeMethod` - Override repo default: "squash", "merge", "rebase", or null for auto-detect (default: null)
- `autoCheckDeployment` - Query deployment status after merge (default: false)
```

- [ ] **Step 4: Verify configuration updated**

Run: `sed -n '/^## Configuration/,/^## /p' teams/pr-autopilot-team/team.md | grep -A 5 "autoMerge"`

Expected: Should see autoMerge object with 7 properties

- [ ] **Step 5: Commit configuration update**

```bash
git add teams/pr-autopilot-team/team.md
git commit -m "docs: add Phase 7 autoMerge configuration options

Document 7 new configuration options for Phase 7 auto-merge
functionality including merge strategy, branch cleanup, and
deployment checking.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 7: Update Team Description and Purpose

**Files:**
- Modify: `teams/pr-autopilot-team/team.md:1-46` (frontmatter and header sections)

- [ ] **Step 1: Update frontmatter description**

In `teams/pr-autopilot-team/team.md`, find the YAML frontmatter (lines 1-14).

Update the description:

```yaml
description: Fully automated PR creation and merging - handles git operations, PR submission, and auto-merge when approved
```

- [ ] **Step 2: Update main header description**

Find the paragraph after "# PR Autopilot Team" (line ~17).

Update to:

```markdown
Fully automated pull request creation and merging team that handles the complete PR workflow from creation to merge. Automates git operations, PR description generation, PR submission with metadata, and auto-merge when all approval criteria are met.
```

- [ ] **Step 3: Update Purpose section**

Find the "## Purpose" section (line ~20).

Update to include Phase 7:

```markdown
## Purpose

Automate the complete PR workflow:
- Verify code has passed review
- Run final test suite
- Generate comprehensive PR description
- Create commit with proper formatting
- Push branch to remote
- Create GitHub PR with metadata
- Apply labels and assign reviewers
- Monitor and auto-merge when approved
```

- [ ] **Step 4: Update version number**

In the YAML frontmatter, update version:

```yaml
version: 2.0.0
```

- [ ] **Step 5: Verify updates**

Run: `head -50 teams/pr-autopilot-team/team.md`

Expected: Should see version 2.0.0, updated description mentioning "merging"

- [ ] **Step 6: Commit metadata updates**

```bash
git add teams/pr-autopilot-team/team.md
git commit -m "docs: update pr-autopilot-team metadata for v2.0.0

Update version to 2.0.0 reflecting Phase 7 auto-merge capability.
Update description and purpose to include auto-merge functionality.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 8: Update Best Practices Section

**Files:**
- Modify: `teams/pr-autopilot-team/team.md` (Best Practices section)

- [ ] **Step 1: Find Best Practices section**

Run: `grep -n "^## Best Practices" teams/pr-autopilot-team/team.md`

Expected: Should show line number of Best Practices section

- [ ] **Step 2: Add Phase 7 best practices**

In the "### Do:" subsection, add:

```markdown
- ✅ Use /check-and-merge to eliminate manual merge steps
- ✅ Verify all conversations resolved before merge
- ✅ Let CI/CD checks complete before merging
```

In the "### Don't:" subsection, add:

```markdown
- ❌ Bypass branch protection to force merge
- ❌ Merge with unresolved review conversations
- ❌ Merge before CI/CD checks complete
```

- [ ] **Step 3: Verify best practices updated**

Run: `sed -n '/^## Best Practices/,/^## /p' teams/pr-autopilot-team/team.md | grep "check-and-merge"`

Expected: Should see /check-and-merge mentioned in Do section

- [ ] **Step 4: Commit best practices update**

```bash
git add teams/pr-autopilot-team/team.md
git commit -m "docs: add Phase 7 best practices to pr-autopilot-team

Document best practices for /check-and-merge command including
conversation resolution and CI/CD check verification.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 9: Add Phase 7 to Success Criteria

**Files:**
- Modify: `teams/pr-autopilot-team/team.md` (Success Criteria section)

- [ ] **Step 1: Find Success Criteria section**

Run: `grep -n "^## Success Criteria" teams/pr-autopilot-team/team.md`

Expected: Should show line number of Success Criteria section

- [ ] **Step 2: Update success criteria**

Find the success criteria list and update to:

```markdown
## Success Criteria

The team is successful when:
- ✅ PRs created in <5 minutes
- ✅ Zero manual git operations needed
- ✅ Comprehensive PR descriptions
- ✅ Proper issue linking (auto-close when merged)
- ✅ Appropriate reviewers assigned
- ✅ Labels applied correctly
- ✅ Auto-merge works when all criteria met
- ✅ Clear status reporting at each check
- ✅ Safe merge validation (no bypassing checks)
- ✅ No failed PRs due to test/review skipping
- ✅ User confidence in automated process
```

- [ ] **Step 3: Verify success criteria updated**

Run: `sed -n '/^## Success Criteria/,/^## /p' teams/pr-autopilot-team/team.md | grep "Auto-merge"`

Expected: Should see "Auto-merge works when all criteria met"

- [ ] **Step 4: Commit success criteria update**

```bash
git add teams/pr-autopilot-team/team.md
git commit -m "docs: add Phase 7 to pr-autopilot-team success criteria

Include auto-merge, status reporting, and merge validation in
success criteria for complete workflow coverage.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 10: Update Time Savings Section

**Files:**
- Modify: `teams/pr-autopilot-team/team.md` (Time Savings section at end)

- [ ] **Step 1: Find Time Savings section**

Run: `grep -n "^## Time Savings" teams/pr-autopilot-team/team.md`

Expected: Should show line number of Time Savings section (near end of file)

- [ ] **Step 2: Update time savings to include Phase 7**

Update the time savings section:

```markdown
## Time Savings

**Traditional PR workflow:**
- Stage changes: 30 seconds
- Write commit message: 2-3 minutes
- Push to remote: 30 seconds
- Navigate to GitHub: 30 seconds
- Fill PR form: 5-10 minutes
- Add labels: 30 seconds
- Assign reviewers: 1 minute
- Wait for approval: (varies)
- Check approval status: 1-2 minutes
- Verify CI/CD passed: 1-2 minutes
- Click merge button: 30 seconds
- **Total: 13-20 minutes per PR**

**With pr-autopilot-team (Phases 1-7):**
- Invoke team: 10 seconds
- Answer questions: 1-2 minutes
- Team executes Phases 1-6: 1-2 minutes
- Wait for approval: (varies)
- Run /check-and-merge: 30 seconds
- **Total: 2-5 minutes active time per PR**

**Savings:** 11-15 minutes per PR (70-80% reduction in active time)

**Breakdown by phase:**
- Phases 1-6 (PR creation): 6-11 minutes saved (60-75% reduction)
- Phase 7 (auto-merge): 4-5 minutes saved (80-90% reduction)

**Additional benefits:**
- Zero mistakes in issue references
- Consistent PR description quality
- Never forget to assign reviewers
- Always includes proper test plan
- Never merge without required approvals
- Never merge with failing CI/CD checks
- Automatic branch cleanup (optional)
```

- [ ] **Step 3: Verify time savings updated**

Run: `sed -n '/^## Time Savings/,$p' teams/pr-autopilot-team/team.md | grep "Phase 7"`

Expected: Should see "Phase 7 (auto-merge): 4-5 minutes saved"

- [ ] **Step 4: Commit time savings update**

```bash
git add teams/pr-autopilot-team/team.md
git commit -m "docs: update time savings to include Phase 7 benefits

Document 70-80% total time savings including 4-5 minutes saved
from Phase 7 auto-merge functionality.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 11: Verify Complete Implementation

**Files:**
- Test: All modified files

- [ ] **Step 1: Verify file structure**

Run: `tree teams/pr-autopilot-team/`

Expected output:
```
teams/pr-autopilot-team/
├── references/
│   └── examples.md
└── team.md
```

- [ ] **Step 2: Verify team.md phases**

Run: `grep "^### Phase" teams/pr-autopilot-team/team.md`

Expected: Should show Phases 1-7 in order

- [ ] **Step 3: Verify examples extracted**

Run: `grep -c "Example 1" teams/pr-autopilot-team/team.md`

Expected: 1 (only the reference link, not full example)

Run: `grep -c "Example 1" teams/pr-autopilot-team/references/examples.md`

Expected: 1 (full example exists in references)

- [ ] **Step 4: Verify configuration complete**

Run: `grep -A 10 "autoMerge" teams/pr-autopilot-team/team.md | head -12`

Expected: Should see autoMerge object with all 7 properties

- [ ] **Step 5: Verify no broken references**

Run: `grep -E "\[.*\]\(.*\)" teams/pr-autopilot-team/team.md | grep -v "references/examples.md"`

Expected: No broken markdown links (all should be valid)

- [ ] **Step 6: Count total lines**

Run: `wc -l teams/pr-autopilot-team/team.md teams/pr-autopilot-team/references/examples.md`

Expected: 
- team.md: ~650-700 lines (was 769, extracted ~130, added ~150 for Phase 7)
- examples.md: ~130-140 lines

- [ ] **Step 7: Verify version updated**

Run: `grep "^version:" teams/pr-autopilot-team/team.md`

Expected: `version: 2.0.0`

- [ ] **Step 8: Final commit with verification**

```bash
git status
```

Expected: Should show "nothing to commit, working tree clean"

If there are uncommitted changes:
```bash
git add -A
git commit -m "chore: final verification of pr-autopilot-team v2.0.0

All tasks complete:
- Examples extracted to references/
- Phase 7 auto-merge added
- Configuration updated
- Documentation updated
- Version bumped to 2.0.0

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Self-Review

### 1. Spec Coverage Check

Reviewing spec at `docs/superpowers/specs/2026-04-16-pr-autopilot-auto-merge-design.md`:

**Architecture - File Structure Changes:**
- ✅ Task 1: Create references directory
- ✅ Task 2: Extract examples to references/examples.md
- ✅ Task 3: Remove examples from team.md and add reference link

**Phase 7 Workflow:**
- ✅ Task 4: Add complete Phase 7 section with all 7 steps
  - Step 1: Verify PR exists ✅
  - Step 2: Fetch PR status ✅
  - Step 3: Check merge criteria (5 checks) ✅
  - Step 4: Display status ✅
  - Step 5: Execute merge ✅
  - Step 6: Post-merge actions ✅
  - Step 7: Error handling ✅

**Command Interface:**
- ✅ Task 5: Update Phase 6 to offer Phase 7

**Configuration:**
- ✅ Task 6: Add autoMerge configuration section

**Documentation Updates:**
- ✅ Task 7: Update team description, version to 2.0.0
- ✅ Task 8: Update best practices
- ✅ Task 9: Update success criteria
- ✅ Task 10: Update time savings

**Verification:**
- ✅ Task 11: Complete verification of all changes

All spec requirements covered.

### 2. Placeholder Scan

Searching for red flag patterns:

- No "TBD" or "TODO" in any task
- No "Add appropriate error handling" - all error handling explicitly shown in Phase 7 Step 3
- No "Write tests for the above" - this is documentation, no code tests needed
- No "Similar to Task N" - each task fully specified
- All code blocks contain actual bash/markdown content, not descriptions
- All file paths are exact (teams/pr-autopilot-team/team.md, etc.)

No placeholders found.

### 3. Type Consistency

Checking consistency across tasks:

- Configuration field names:
  - Task 6: `autoMerge.deleteBranchAfterMerge`
  - Task 4 Phase 7: `deleteBranchAfterMerge` ✅ Consistent
  
- PR status field names:
  - Task 4 Phase 7 uses: `state`, `mergeable`, `reviewDecision`, `statusCheckRollup`, `reviewThreads`
  - All referenced consistently in checks ✅

- Command name:
  - Task 4: `/check-and-merge` ✅
  - Task 5: `/check-and-merge` ✅
  - Task 8: `/check-and-merge` ✅
  - Consistent throughout

- File references:
  - Task 2 creates: `references/examples.md`
  - Task 3 references: `./references/examples.md` ✅ Consistent

All types and names consistent across tasks.

---

## Plan Complete

This plan implements Phase 7 auto-merge functionality for pr-autopilot-team following the approved spec. The plan:

1. **Maintains existing functionality** - Phases 1-6 unchanged except for Phase 7 offer
2. **Adds /check-and-merge command** - User-triggered merge validation
3. **Comprehensive error handling** - Clear messages for all failure scenarios
4. **Safe by default** - Validates all criteria before merge
5. **Configurable** - 7 configuration options for customization
6. **Well documented** - Updated all sections including best practices and time savings

Each task is small (2-5 minutes), has explicit file paths, complete code examples, and verification steps with expected output.
