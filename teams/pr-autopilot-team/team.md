---
name: pr-autopilot-team
description: Fully automated PR creation and merging - handles git operations, PR submission, and auto-merge when approved
version: 2.0.0
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

Fully automated pull request creation and merging team that handles the complete PR workflow from creation to merge. Automates git operations, PR description generation, PR submission with metadata, and auto-merge when all approval criteria are met.

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
   
   Would you like me to:
   A) Check and merge when approved (/check-and-merge)
   B) Monitor CI/CD status and notify on failure
   C) Open PR in browser
   D) Nothing, I'm done here
   
   If user chooses A: Proceed to Phase 7
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

**Auto-Merge Configuration:**

- `enabled` - Enable/disable Phase 7 functionality (default: true)
- `deleteBranchAfterMerge` - Prompt to delete branch after successful merge (default: true)
- `requireAllConversationsResolved` - Block merge if review threads unresolved (default: true)
- `minApprovals` - Minimum approvals required (overridden by branch protection) (default: 1)
- `respectBranchProtection` - Honor GitHub branch protection rules (default: true)
- `defaultMergeMethod` - Override repo default: "squash", "merge", "rebase", or null for auto-detect (default: null)
- `autoCheckDeployment` - Query deployment status after merge (default: false)

## Usage Examples

See [examples.md](./references/examples.md) for detailed workflow examples including:
- Example 1: Simple Feature - Clean Path
- Example 2: Complex Feature - With Fixes
- Example 3: Multiple Issues

---

### Phase 7: Monitor and Auto-Merge

**Goal:** Check PR readiness and merge when all criteria are met

**Trigger Options:**
1. After Phase 6 completion - team asks user if they want to check and merge
2. User runs `/check-and-merge` from any branch with a PR
3. User runs `/check-and-merge #123` to check specific PR

**Process:**

#### 1. Verify PR Exists

```bash
# Get PR for current branch
pr_number=$(gh pr view --json number -q .number 2>/dev/null)

if [ -z "$pr_number" ]; then
  Error: "No PR found for current branch"
  
  Suggest:
  - Run this command from the branch with a PR
  - Or specify PR number: /check-and-merge #123
  
  Exit Phase 7
fi
```

**If PR number provided:** Use provided number instead of detecting from branch

#### 2. Fetch PR Status

```bash
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
```

#### 3. Check Merge Criteria

Check each criterion in order, tracking status:

**A) PR State = OPEN**

```bash
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
```

**B) No Merge Conflicts**

```bash
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
```

**C) At Least 1 Approval**

```bash
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
```

**D) All Conversations Resolved**

```bash
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
```

**E) All Required Checks Passing**

```bash
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
```

#### 4. Display Status Summary

**If all criteria met (ready to merge):**

```
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
```

**If not ready to merge:**

```
PR #$pr_number Status Check

[Status indicators for each criterion]

Not ready to merge yet.

What would you like to do?
A) I'll run /check-and-merge again when ready
B) Show me detailed status for each check
C) Cancel
```

#### 5. Determine Merge Method

**Detect from repository settings:**

```bash
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
```

**Allow user override:**

```
Ask user: "Merge using [$default_method]? 
Options:
- squash: Combine all commits into one
- merge: Create merge commit preserving history
- rebase: Replay commits onto main
- default: Use [$default_method]

Enter method or press Enter for default:"

merge_method=${user_choice:-$default_method}
```

#### 6. Execute Merge

```bash
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
```

#### 7. Post-Merge Actions

**Branch cleanup (if configured):**

```bash
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
```

**Success notification:**

```
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
```

**Optional deployment check:**

```
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
```

**Output:** Successfully merged PR with all safety checks validated

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
- ✅ Use /check-and-merge to eliminate manual merge steps
- ✅ Verify all conversations resolved before merge
- ✅ Let CI/CD checks complete before merging

### Don't:
- ❌ Create PRs with failing tests
- ❌ Skip code review for features
- ❌ Create vague PR descriptions
- ❌ Force push without confirmation
- ❌ Commit secrets or sensitive data
- ❌ Create PRs from main/master branch
- ❌ Bypass branch protection to force merge
- ❌ Merge with unresolved review conversations
- ❌ Merge before CI/CD checks complete

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
- ✅ Auto-merge works when all criteria met
- ✅ Clear status reporting at each check
- ✅ Safe merge validation (no bypassing checks)
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