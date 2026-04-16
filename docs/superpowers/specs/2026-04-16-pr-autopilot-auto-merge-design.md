# PR Autopilot Auto-Merge Design

**Date:** 2026-04-16  
**Status:** Approved  
**Scope:** Add Phase 7 auto-merge functionality to pr-autopilot-team

## Overview

Extend the pr-autopilot-team with automated merge capabilities that check PR readiness and merge when all criteria are met. This eliminates the final manual step in the PR workflow while maintaining safety through strict merge criteria.

## Requirements

### Merge Criteria
- ✅ At least 1 approval
- ✅ All review conversations resolved
- ✅ All required CI/CD checks passing
- ✅ No merge conflicts
- ✅ PR state is OPEN

### Merge Strategy
- Read from repository settings (respects branch protection rules)
- Allow user override per-PR (squash, merge, rebase)

### Monitoring Approach
- User-triggered via `/check-and-merge` command
- No background polling or long-running processes
- Can check current branch or specific PR number

### Error Handling
- Abort and notify on any failure
- Provide clear error messages with actionable details
- Do not retry or attempt automatic recovery

## Architecture

### File Structure Changes

**Before:**
```
teams/pr-autopilot-team/
└── team.md (770 lines)
```

**After:**
```
teams/pr-autopilot-team/
├── team.md (~500 lines - core workflow)
└── references/
    └── examples.md (~130 lines - example workflows)
```

**What moves to references/:**
- Example 1: Simple Feature - Clean Path
- Example 2: Complex Feature - With Fixes  
- Example 3: Multiple Issues

**What stays in team.md:**
- Phases 1-7 (complete workflow)
- Configuration section
- Decision trees (inline execution guidance)
- Best practices (Do/Don't lists)
- Error handling (within phase descriptions)
- Integration notes
- Success criteria

**Rationale:**
- Examples are learning material, not execution guidance
- Decision trees and error handling are actively used during execution
- Project-specific decisions tracked via PR comments, not in team file

### Phase 7 Workflow

**Phase 7: Monitor and Auto-Merge**

**Goal:** Check PR readiness and merge when all criteria are met

**Trigger Options:**
1. After Phase 6 completion - team asks user if they want to check and merge
2. User runs `/check-and-merge` from any branch with a PR
3. User runs `/check-and-merge #123` to check specific PR

**Process Steps:**

#### Step 1: Verify PR Exists
```bash
# Get PR for current branch
pr_number=$(gh pr view --json number -q .number 2>/dev/null)

if [ -z "$pr_number" ]; then
  Error: "No PR found for current branch"
  Exit Phase 7
fi
```

#### Step 2: Fetch PR Status
```bash
# Get all PR status information
gh pr view $pr_number --json \
  state,mergeable,reviewDecision,statusCheckRollup,reviews \
  > pr_status.json

# Extract key fields
state=$(jq -r .state pr_status.json)
mergeable=$(jq -r .mergeable pr_status.json)
review_decision=$(jq -r .reviewDecision pr_status.json)
checks=$(jq -r .statusCheckRollup pr_status.json)
```

#### Step 3: Check Merge Criteria

Check each criterion and track status:

**1. PR State = OPEN**
```bash
if [ "$state" != "OPEN" ]; then
  Error: "PR is $state, cannot merge"
  Exit Phase 7
fi
```

**2. No Merge Conflicts**
```bash
if [ "$mergeable" != "MERGEABLE" ]; then
  Error: "PR has merge conflicts"
  Show: Conflicting files list
  Exit Phase 7
fi
```

**3. At Least 1 Approval**
```bash
if [ "$review_decision" != "APPROVED" ]; then
  current_approvals=$(count_approvals)
  Error: "PR not approved (current: $current_approvals, required: 1)"
  Exit Phase 7
fi
```

**4. All Conversations Resolved**
```bash
unresolved=$(gh pr view $pr_number --json reviewThreads \
  -q '.reviewThreads | map(select(.isResolved == false)) | length')

if [ "$unresolved" -gt 0 ]; then
  Error: "$unresolved unresolved conversation(s)"
  Show: List of unresolved threads with links
  Exit Phase 7
fi
```

**5. All Required Checks Passing**
```bash
# Get required checks from branch protection
required_checks=$(gh api repos/{owner}/{repo}/branches/{base}/protection \
  -q '.required_status_checks.contexts[]')

# Check each required check
for check in $required_checks; do
  status=$(jq -r ".statusCheckRollup[] | select(.context == \"$check\") | .state")
  
  if [ "$status" != "SUCCESS" ]; then
    Error: "Required check '$check' is $status"
    Exit Phase 7
  fi
done
```

#### Step 4: Display Status to User

**If not ready to merge:**
```
PR #123 Status Check

✅ State: Open
✅ Conflicts: None
✅ Approvals: 2 approved (requires 1)
✅ Conversations: All resolved (0 unresolved)
⏳ CI/CD Checks: 2/3 required checks passing
   - ✅ tests: SUCCESS (2m 34s)
   - ✅ lint: SUCCESS (45s)
   - ⏳ build: IN_PROGRESS (running for 3m 12s)

Not ready to merge yet.

What would you like to do?
A) I'll run /check-and-merge again when ready
B) Show me the full check logs
C) Cancel
```

**If ready to merge:**
```
PR #123 Ready to Merge! ✅

✅ State: Open
✅ Conflicts: None  
✅ Approvals: 2 approved
✅ Conversations: All resolved
✅ CI/CD Checks: All 3 required checks passing

Detected merge method: squash (from repo settings)

Proceed with merge?
A) Yes, merge now with squash
B) Use different method (squash/merge/rebase)
C) Cancel
```

#### Step 5: Execute Merge

**Determine merge method:**
```bash
# Option 1: Detect from repo settings
default_method=$(gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed \
  -q 'if .squashMergeAllowed then "squash" elif .rebaseMergeAllowed then "rebase" else "merge" end')

# Option 2: User override
Ask: "Merge using [$default_method]? Or specify: squash/merge/rebase"
merge_method=${user_choice:-$default_method}
```

**Execute merge:**
```bash
# Merge the PR
gh pr merge $pr_number --$merge_method --auto

if [ $? -ne 0 ]; then
  Error: "Merge failed"
  Show: Error output from gh command
  Exit Phase 7
fi
```

#### Step 6: Post-Merge Actions

**Branch cleanup:**
```bash
# Check config for branch deletion
if [ "$config_deleteBranchAfterMerge" = "true" ]; then
  branch_name=$(git branch --show-current)
  
  # Delete local branch
  git checkout main
  git branch -d $branch_name
  
  # Delete remote branch
  git push origin --delete $branch_name
  
  echo "✅ Branch $branch_name deleted"
fi
```

**Success notification:**
```
✅ PR #123 Merged Successfully!

Details:
- Merge method: squash
- Merged into: main
- Branch deleted: yes
- Merge commit: abc123f

Next steps:
1. ✅ Changes are now in main
2. 🚀 Check deployment status (if configured)
3. 📊 Monitor production metrics

Would you like me to check deployment status?
```

#### Step 7: Error Handling

**Merge Conflicts:**
```
❌ Cannot merge - conflicts detected

Conflicting files:
- src/components/Header.tsx
- src/styles/theme.css

Resolution steps:
1. Pull latest main: git checkout main && git pull
2. Rebase your branch: git checkout [branch] && git rebase main
3. Resolve conflicts in listed files
4. Continue rebase: git rebase --continue
5. Force push: git push --force-with-lease
6. Run /check-and-merge again
```

**Failed Checks:**
```
❌ Cannot merge - required checks failing

Failed checks:
- tests: FAILURE (12 tests failed)
  View logs: [URL]
- build: ERROR (webpack compilation failed)
  View logs: [URL]

Resolution steps:
1. Review check logs above
2. Fix failing tests/builds locally
3. Push fixes to branch
4. Wait for checks to re-run
5. Run /check-and-merge again
```

**Missing Approvals:**
```
❌ Cannot merge - approval required

Current approvals: 0
Required approvals: 1

Assigned reviewers:
- @senior-dev (not yet reviewed)
- @team-lead (requested changes)

Resolution steps:
1. Address requested changes from @team-lead
2. Request re-review after changes
3. Wait for approval
4. Run /check-and-merge again
```

**Unresolved Conversations:**
```
❌ Cannot merge - unresolved conversations

Unresolved threads: 3

1. [Line 45 in auth.ts] @reviewer: "Should we add rate limiting here?"
   [Link to thread]

2. [Line 102 in api.ts] @security: "Potential SQL injection risk"
   [Link to thread]
   
3. [General] @team-lead: "What's the rollback plan?"
   [Link to thread]

Resolution steps:
1. Address each conversation thread
2. Click "Resolve conversation" when addressed
3. Run /check-and-merge again
```

**GitHub API Errors:**
```
❌ Error checking PR status

Error: API rate limit exceeded (403)
Retry after: 2024-04-16 15:30:00 UTC

Or:

Error: GitHub API timeout (504)
This is usually temporary.

Resolution:
- Wait a few minutes and try again
- Check GitHub status: https://www.githubstatus.com
```

**Branch Protection Violations:**
```
❌ Cannot merge - branch protection rules not met

Violations:
- Requires 2 approvals (current: 1)
- Requires code owner approval (not met)
- Requires linear history (merge commits not allowed)

Resolution steps:
1. Get additional required approvals
2. Ensure code owners have approved
3. Update branch protection settings (if appropriate)
4. Run /check-and-merge again
```

## Configuration

Add to `.claude-grimoire/config.json`:

```json
{
  "prAutopilot": {
    "autoMerge": {
      "enabled": true,
      "deleteBranchAfterMerge": true,
      "requireAllConversationsResolved": true,
      "minApprovals": 1,
      "respectBranchProtection": true,
      "defaultMergeMethod": null,
      "autoCheckDeployment": false
    }
  }
}
```

**Configuration Options:**

- `enabled` - Enable/disable Phase 7 functionality
- `deleteBranchAfterMerge` - Automatically delete branch after successful merge
- `requireAllConversationsResolved` - Block merge if any review threads unresolved
- `minApprovals` - Minimum number of approvals required (overridden by branch protection)
- `respectBranchProtection` - Honor GitHub branch protection rules
- `defaultMergeMethod` - Override repo default (null = use repo settings)
- `autoCheckDeployment` - Query deployment status after merge

## Command Interface

### Integration with pr-autopilot-team

**After Phase 6 (PR Creation):**
```
✅ Pull Request Created Successfully!

PR #123: Add dark mode toggle
URL: https://github.com/owner/repo/pull/123

Would you like me to check and merge when approved?
A) Yes, check now
B) No, I'll merge manually
```

If user chooses A: Execute Phase 7

### Standalone Invocation

**Current branch:**
```
User: /check-and-merge
Team: [Detects PR for current branch, executes Phase 7]
```

**Specific PR:**
```
User: /check-and-merge #456
Team: [Checks PR #456, executes Phase 7]
```

## Team File Format Clarification

**Skills use:** `SKILL.md` (uppercase)
- Location: `skills/[skill-name]/SKILL.md`
- Invoked via: `/skill-name` or `Skill({ skill: "skill-name" })`
- Auto-discovered by Claude Code

**Teams use:** `team.md` (lowercase)
- Location: `teams/[team-name]/team.md`
- Invoked via: team name reference in conversation
- Not invoked via Skill tool
- Auto-discovered by Claude Code

**Current pr-autopilot-team structure is correct:**
```
teams/pr-autopilot-team/
└── team.md ✅ (correct - lowercase)
```

Teams are workflow orchestrators that may invoke multiple skills, agents, and tools. They are not themselves skills.

## Success Criteria

Phase 7 is successful when:

1. **Safety preserved:**
   - ✅ Never merges without all criteria met
   - ✅ Provides clear status at each check
   - ✅ Aborts immediately on any failure
   - ✅ Gives actionable error messages

2. **User experience:**
   - ✅ Single command to check and merge
   - ✅ Clear status display (checkmarks, in-progress indicators)
   - ✅ Helpful error messages with resolution steps
   - ✅ Respects user merge method preferences

3. **Integration:**
   - ✅ Works with Phase 6 (PR creation)
   - ✅ Works standalone on any branch with PR
   - ✅ Works with specific PR numbers
   - ✅ Respects repository settings and branch protection

4. **Time savings:**
   - Traditional manual merge: 2-5 minutes (check status, click merge, verify)
   - With Phase 7: 30 seconds (run command, confirm)
   - **Savings:** 1.5-4.5 minutes per PR (60-90% reduction)

## Implementation Notes

### GitHub CLI Commands Used

```bash
# Get PR number for current branch
gh pr view --json number -q .number

# Get comprehensive PR status
gh pr view $pr_number --json state,mergeable,reviewDecision,statusCheckRollup,reviews

# Check unresolved conversations
gh pr view $pr_number --json reviewThreads -q '.reviewThreads | map(select(.isResolved == false))'

# Get branch protection rules
gh api repos/{owner}/{repo}/branches/{base}/protection

# Merge PR
gh pr merge $pr_number --squash|--merge|--rebase --auto

# Get repo merge settings
gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed
```

### Dependencies

- `gh` CLI (GitHub CLI) - version 2.0+
- `jq` - JSON parsing
- Git 2.0+
- GitHub repository with PR capabilities
- Appropriate GitHub permissions (merge access)

### Limitations

- Requires GitHub CLI authentication (`gh auth login`)
- Requires merge permissions on repository
- Cannot bypass branch protection rules
- Does not support draft PRs (they must be marked ready first)
- Does not support merging PRs from forks (security restriction)

## Testing Plan

### Manual Test Cases

1. **Happy path:**
   - Create PR with Phase 1-6
   - Get approval and passing checks
   - Run `/check-and-merge`
   - Verify merge succeeds

2. **Missing approval:**
   - Create PR
   - Run `/check-and-merge` without approval
   - Verify clear error message

3. **Failing checks:**
   - Create PR with failing tests
   - Run `/check-and-merge`
   - Verify check status displayed correctly

4. **Unresolved conversations:**
   - Create PR with review comments
   - Don't resolve threads
   - Run `/check-and-merge`
   - Verify lists unresolved threads

5. **Merge conflicts:**
   - Create PR with conflicts
   - Run `/check-and-merge`
   - Verify conflict detection and guidance

6. **Different merge methods:**
   - Test squash, merge, rebase
   - Verify correct method used
   - Verify user override works

7. **Branch deletion:**
   - Enable `deleteBranchAfterMerge`
   - Merge PR
   - Verify local and remote branches deleted

8. **Specific PR number:**
   - Run `/check-and-merge #456`
   - Verify works from any branch

## Migration Path

### Phase 1: Refactor Existing team.md
1. Extract examples to `references/examples.md`
2. Update internal references
3. Test all existing phases still work

### Phase 2: Add Phase 7
1. Add Phase 7 section to team.md
2. Add configuration options
3. Update Phase 6 to offer Phase 7

### Phase 3: Add Command Interface
1. Add standalone `/check-and-merge` invocation
2. Add specific PR number support
3. Test all invocation methods

### Phase 4: Documentation
1. Update README with Phase 7 examples
2. Update configuration guide
3. Add troubleshooting section

## Future Enhancements (Out of Scope)

- Background polling/webhook monitoring (current: user-triggered only)
- Automatic retry on transient failures (current: abort and notify)
- Smart rebase on conflicts (current: notify user to fix manually)
- Deployment tracking integration (current: manual check)
- Slack/email notifications on merge (current: terminal output only)
- Support for multiple approval tiers (current: single approval count)

These enhancements can be added in future iterations based on user feedback.
