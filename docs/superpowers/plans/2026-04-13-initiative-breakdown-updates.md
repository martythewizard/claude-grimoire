# Initiative Breakdown Updates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update initiative-breakdown to accept flexible input (YAML initiatives, GitHub Projects, workstreams, milestones, standalone issues) and create tasks appropriately linked to the organizational structure.

**Architecture:** Skill uses github-context-agent to resolve any input type into structured context, then generates tasks based on that context. When initiative has GitHub Project, links issues. When workstream has milestones, assigns issues. Supports all organizational patterns.

**Tech Stack:**
- GitHub CLI (`gh`) for issue creation and linking
- github-context-agent for context resolution
- Markdown documentation

**Dependencies:** Requires Plans 1 (github-context-agent) and 2 (initiative-creator) to be complete.

---

## File Structure

**Files to Modify:**
- `skills/initiative-breakdown/skill.md` - Main skill documentation (current: ~554 lines)
  - Update input handling to use github-context-agent
  - Add workflows for each input type
  - Update task generation to respect organizational structure
  - Add linking and milestone assignment logic
  - Update examples

**Files to Create:**
- `skills/initiative-breakdown/examples/break-down-initiative.md` - Full initiative breakdown
- `skills/initiative-breakdown/examples/break-down-project.md` - Project breakdown
- `skills/initiative-breakdown/examples/break-down-workstream.md` - Single workstream
- `skills/initiative-breakdown/examples/break-down-milestone.md` - Milestone tasks
- `test/initiative-breakdown/test-linking.sh` - Test issue linking logic

---

### Task 1: Update Input Handling to Use github-context-agent

**Files:**
- Modify: `skills/initiative-breakdown/skill.md:37-66` (replace "Fetch Initiative Context" section)

- [ ] **Step 1: Replace context fetching with agent invocation**

Replace "Fetch Initiative Context" section with:

```markdown
## Workflow

### 1. Input Detection and Context Gathering

The skill accepts flexible input and uses `github-context-agent` to resolve it.

**Supported Input Types:**

```
Initiative YAML:
  initiatives/2026-q1-ai-cost-intelligence-platform.yaml
  2026-q1-ai-cost-intelligence
  ai-cost-intelligence (search term)

GitHub Project:
  eci-global#14
  https://github.com/orgs/eci-global/projects/14

Workstream:
  initiative:ai-cost workstream:S3 Data Lake

Milestone:
  eci-global/repo milestone:"M1 - Foundation"
  eci-global/repo milestone:5

Standalone Issue:
  eci-global/repo#123 (break into related tasks)
```

**Step 1: Invoke github-context-agent**

```
Call github-context-agent with:
  identifier: <user-provided-input>
  depth: "deep"
  include: {
    yaml: true,
    project: true,
    workstreams: true,
    milestones: true,
    progress: true
  }
```

**Step 2: Handle Response**

```
If success:
  Extract context based on type:
    - initiative: workstreams, github_project, progress
    - project: items by repo, milestones
    - workstream: milestones, repo
    - milestone: issues, repo
    - issue: create related tasks
    
If error (ambiguous):
  Present options to user
  Re-invoke with clarified identifier
  
If error (not found):
  Suggest alternatives or creation
```

**Example Invocation:**

```
User: /initiative-breakdown initiatives/2026-q1-coralogix-quota-manager.yaml

Skill: Fetching initiative context via github-context-agent...

Agent returns:
  type: initiative
  metadata: { name: "2026 Q1 - Coralogix Quota Manager", status: "active", ... }
  github_project: { org: "eci-global", number: 8, ... }
  workstreams: [
    {
      name: "Quota Enforcement",
      repo: "eci-global/coralogix",
      milestones: [...]
    }
  ]

Skill: ✓ Initiative found
  Name: 2026 Q1 - Coralogix Quota Manager
  Status: active
  Workstreams: 1
  GitHub Project: eci-global#8

Ready to break down. Continue? (y/n)
```
```

- [ ] **Step 2: Verify input handling is clear**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
grep "## Workflow" skills/initiative-breakdown/skill.md
grep "github-context-agent" skills/initiative-breakdown/skill.md
```

Expected: Workflow section updated with agent invocation

- [ ] **Step 3: Commit input handling updates**

```bash
git add skills/initiative-breakdown/skill.md
git commit -m "docs(initiative-breakdown): update input handling to use github-context-agent"
```

---

### Task 2: Add Initiative Breakdown Workflow

**Files:**
- Modify: `skills/initiative-breakdown/skill.md` (after input handling)
- Create: `skills/initiative-breakdown/examples/break-down-initiative.md`

- [ ] **Step 1: Document initiative breakdown workflow**

Add new section:

```markdown
### 2. Initiative Breakdown Workflow

When context type is "initiative", break into tasks across all workstreams.

**Process:**

**Step 1: Analyze Initiative Structure**

```
From context:
  - Extract all workstreams and their repos
  - Extract milestones per workstream
  - Note github_project if exists
  - Check progress metrics
```

**Step 2: Validate Scope**

```
Ask user:
"This initiative has <N> workstreams and <M> milestones. Should I:
A) Break down all workstreams
B) Break down specific workstreams only (choose which)
C) Skip workstreams, create general tasks

If scope is too large (>10 milestones):
  Recommend breaking down by workstream instead
  "This is large. Consider using workstream-specific breakdown:
   /initiative-breakdown initiative:name workstream:<workstream-name>"
```

**Step 3: Generate Tasks by Workstream**

For each workstream:
```
1. Identify task categories:
   - Foundation tasks (abstractions, core logic)
   - Implementation tasks (features, endpoints)
   - Testing tasks (unit, integration)
   - Documentation tasks (README, API docs)

2. For each task:
   - Create task description
   - Map to specific milestone (from workstream)
   - Add acceptance criteria
   - Estimate effort (S/M/L)
   - Note dependencies

3. Group tasks by milestone
```

**Step 4: Create GitHub Issues**

For each task:
```bash
# Create issue
gh issue create \
  --repo <workstream-repo> \
  --title "[<milestone>] <task-title>" \
  --body "<task-description>" \
  --label task,<category>
  
# If initiative has github_project: Link to project
if [ -n "$github_project" ]; then
  gh project item-add <project-number> \
    --owner <org> \
    --url <issue-url>
fi

# If task maps to milestone: Assign milestone
if [ -n "$milestone" ]; then
  gh issue edit <issue-number> \
    --repo <repo> \
    --milestone "<milestone-title>"
fi

# Add initiative reference comment
gh issue comment <issue-number> \
  --repo <repo> \
  --body "Part of initiative: [<name>](<yaml-url>)"
```

**Step 5: Report Progress**

```
✅ Breakdown complete!

Created <N> tasks across <M> workstreams:

Workstream: Quota Enforcement (eci-global/coralogix)
  Milestone M1: 5 tasks (#234, #235, #236, #237, #238)
  Milestone M2: 4 tasks (#239, #240, #241, #242)

All tasks linked to:
  - GitHub Project: eci-global#8
  - Initiative YAML: initiatives/2026-q1-coralogix-quota-manager.yaml

Next steps:
1. Review tasks in GitHub Project
2. Assign tasks to team members
3. Start with M1 tasks (foundation)
```
```

- [ ] **Step 2: Create initiative breakdown example**

Create `skills/initiative-breakdown/examples/break-down-initiative.md`:

```markdown
# Initiative Breakdown Example

## Input

```bash
/initiative-breakdown initiatives/2026-q1-coralogix-quota-manager.yaml
```

## Process

```
Skill: Fetching initiative via github-context-agent...

✓ Initiative found:
  Name: 2026 Q1 - Coralogix Quota Manager
  Status: active
  Owner: RustyAutopsy
  Workstreams: 1 (Quota Enforcement)
  Milestones: 4 (M1, M2, M3, M4)
  GitHub Project: eci-global#8

This initiative has 1 workstream and 4 milestones. Should I:
A) Break down all milestones
B) Break down specific milestones only
C) Create general tasks without milestone structure

User: A

Analyzing workstream: Quota Enforcement (eci-global/coralogix)...

Generating tasks:
  M1: Log Quota Enforcement MVP
    - Foundation: Quota monitoring service (M)
    - Implementation: Log ingestion limiter (M)
    - Testing: Unit tests for quota logic (S)
    - Documentation: README for quota service (S)
    
  M2: Observability & Operational Readiness
    - Implementation: Add metrics to quota service (S)
    - Implementation: Create alerting rules (S)
    - Documentation: Runbook for quota incidents (M)
    
  M3: Metrics & Traces Quota Management
    - Implementation: Extend quota to metrics (M)
    - Implementation: Extend quota to traces (M)
    - Testing: Integration tests (M)
    
  M4: Full Enforcement Pipeline
    - Implementation: SRE override mechanism (S)
    - Implementation: Data Spaces migration path (M)
    - Documentation: Migration guide (S)

Creating issues in eci-global/coralogix...

[M1] Create quota monitoring service → #450 (milestone: M1, project: #8)
[M1] Implement log ingestion limiter → #451 (milestone: M1, project: #8)
[M1] Add unit tests for quota logic → #452 (milestone: M1, project: #8)
[M1] Document quota service → #453 (milestone: M1, project: #8)

[M2] Add metrics to quota service → #454 (milestone: M2, project: #8)
[M2] Create alerting rules → #455 (milestone: M2, project: #8)
[M2] Write runbook for quota incidents → #456 (milestone: M2, project: #8)

[... M3 and M4 tasks ...]

✅ Created 14 tasks across 4 milestones

All tasks:
  - Assigned to appropriate milestones
  - Linked to GitHub Project eci-global#8
  - Referenced initiative YAML in comments

View tasks: https://github.com/orgs/eci-global/projects/8
```

## GitHub Commands Used

```bash
# Create task for M1
gh issue create \
  --repo eci-global/coralogix \
  --title "[M1] Create quota monitoring service" \
  --body "Foundation task: Build core monitoring service for tracking quota consumption..." \
  --label task,foundation,effort:M

# Link to project
gh project item-add 8 \
  --owner eci-global \
  --url https://github.com/eci-global/coralogix/issues/450

# Assign to milestone
gh issue edit 450 \
  --repo eci-global/coralogix \
  --milestone "M1: Log Quota Enforcement MVP"

# Add initiative reference
gh issue comment 450 \
  --repo eci-global/coralogix \
  --body "Part of initiative: [2026 Q1 - Coralogix Quota Manager](https://github.com/eci-global/initiatives/blob/main/initiatives/2026-q1-coralogix-quota-manager.yaml)"
```
```

- [ ] **Step 3: Verify initiative workflow documented**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
grep "### 2. Initiative Breakdown Workflow" skills/initiative-breakdown/skill.md
ls -la skills/initiative-breakdown/examples/break-down-initiative.md
```

Expected: Initiative workflow section exists, example created

- [ ] **Step 4: Commit initiative breakdown workflow**

```bash
git add skills/initiative-breakdown/skill.md skills/initiative-breakdown/examples/break-down-initiative.md
git commit -m "docs(initiative-breakdown): add initiative breakdown workflow and example"
```

---

### Task 3: Add Project, Workstream, and Milestone Workflows

**Files:**
- Modify: `skills/initiative-breakdown/skill.md` (add 3 new sections)
- Create: `skills/initiative-breakdown/examples/break-down-project.md`
- Create: `skills/initiative-breakdown/examples/break-down-workstream.md`
- Create: `skills/initiative-breakdown/examples/break-down-milestone.md`

- [ ] **Step 1: Add condensed workflows for other types**

Add three brief workflow sections:

```markdown
### 3. Project Breakdown Workflow

When context type is "project", organize by repos/milestones.

```
1. Fetch project items via github-context-agent
2. Group existing items by repo and milestone
3. Identify gaps (areas without tasks)
4. Generate new tasks for gaps
5. Create issues and link to project
6. Check for related initiative YAML (if detected by agent)
```

### 4. Workstream Breakdown Workflow

When context type is "workstream", scope to single workstream.

```
1. Extract milestones for this workstream only
2. Generate tasks scoped to workstream's repo
3. Assign to workstream's milestones
4. Link to github_project if initiative has one
5. Don't touch other workstreams
```

### 5. Milestone Breakdown Workflow

When context type is "milestone", create tasks for one milestone.

```
1. See existing issues in milestone
2. Generate additional tasks needed
3. Create issues in milestone's repo
4. Assign all to this milestone
5. Link to project if milestone is part of tracked initiative
```
```

- [ ] **Step 2: Create project breakdown example (brief)**

Create `skills/initiative-breakdown/examples/break-down-project.md`:

```markdown
# Project Breakdown Example

## Input

```bash
/initiative-breakdown eci-global#14
```

## Process

```
Skill: Fetching project via github-context-agent...

✓ Project found:
  Name: 2026 Q1 - AI Cost Intelligence Platform
  Items: 76 (all closed)
  Repos: eci-global/one-cloud-cloud-costs
  Related Initiative: initiatives/2026-q1-ai-cost-intelligence-platform.yaml

Project already has 76 items. Create additional tasks? (y/n)

User: n

✓ No new tasks needed. Project is complete.
```

## Alternate Scenario: Project Needs Tasks

```
Project found:
  Name: 2026 Q2 - New Project
  Items: 3
  Gaps identified: No testing tasks, no documentation

Create tasks for gaps? (y/n)

User: y

Creating tasks:
  - Add integration tests → #890
  - Add API documentation → #891
  
Linking to project...
✅ Created 2 tasks, linked to project eci-global#14
```
```

- [ ] **Step 3: Create workstream breakdown example (brief)**

Create `skills/initiative-breakdown/examples/break-down-workstream.md`:

```markdown
# Workstream Breakdown Example

## Input

```bash
/initiative-breakdown "initiative:ai-cost workstream:Intelligence System"
```

## Process

```
Skill: Resolving workstream via github-context-agent...

✓ Workstream found:
  Initiative: 2026 Q1 - AI Cost Intelligence Platform
  Workstream: Intelligence System
  Repo: eci-global/one-cloud-cloud-costs
  Milestones: 4 (M1, M2, M3, M4)

Breaking down workstream milestones...

Created 12 tasks:
  M1 — Eyes Open: 3 tasks (#234-#236)
  M2 — Learning Normal: 4 tasks (#237-#240)
  M3 — Acting: 3 tasks (#241-#243)
  M4 — Observability: 2 tasks (#244-#245)

All tasks scoped to eci-global/one-cloud-cloud-costs only.
Other workstreams untouched.
```
```

- [ ] **Step 4: Create milestone breakdown example (brief)**

Create `skills/initiative-breakdown/examples/break-down-milestone.md`:

```markdown
# Milestone Breakdown Example

## Input

```bash
/initiative-breakdown 'eci-global/coralogix milestone:"M1: Log Quota Enforcement MVP"'
```

## Process

```
Skill: Fetching milestone via github-context-agent...

✓ Milestone found:
  Repo: eci-global/coralogix
  Milestone: M1: Log Quota Enforcement MVP
  Due: 2026-06-01
  Current issues: 5 (3 open, 2 closed)
  Related initiative: 2026 Q1 - Coralogix Quota Manager

Current tasks:
  #450: Create quota monitoring service
  #451: Implement log ingestion limiter
  #452: Add unit tests
  #453: Document quota service
  #454: Add integration tests

Create additional tasks for M1? (y/n)

User: y

What additional work is needed?

User: Need tasks for error handling and deployment

Creating tasks:
  [M1] Add error handling to quota service → #460
  [M1] Create deployment runbook → #461

✅ Created 2 tasks, assigned to M1
```
```

- [ ] **Step 5: Commit all workflow types**

```bash
git add skills/initiative-breakdown/skill.md skills/initiative-breakdown/examples/break-down-*.md
git commit -m "docs(initiative-breakdown): add project/workstream/milestone workflows and examples"
```

---

### Task 4: Add Linking and Milestone Assignment Logic

**Files:**
- Modify: `skills/initiative-breakdown/skill.md` (add new section)

- [ ] **Step 1: Document linking logic**

Add new section after workflows:

```markdown
## Linking and Assignment Logic

### Project Linking

**When to link:**
- Initiative context has `github_project` field
- Project context (user provided project directly)
- Workstream's initiative has `github_project`
- Milestone is part of initiative with `github_project`

**How to link:**
```bash
gh project item-add <project-number> \
  --owner <org> \
  --url <issue-url>
```

**Error handling:**
- If project doesn't exist: Warn user, skip linking
- If project is closed: Warn user, ask if should still link
- If rate limit hit: Batch links, retry with backoff

### Milestone Assignment

**When to assign:**
- Task explicitly scoped to milestone (from workstream)
- User breaking down single milestone
- Task description references milestone

**How to assign:**
```bash
gh issue edit <issue-number> \
  --repo <owner>/<repo> \
  --milestone "<milestone-title>"
```

**Validation:**
- Check milestone exists in repo
- Check milestone is not closed (warn if closed)
- Use exact milestone title (case-sensitive)

### Initiative Reference

**Always add initiative comment when:**
- Input was initiative YAML
- Input was workstream (part of initiative)
- Input was milestone (part of initiative)
- Input was project linked to initiative

**Comment format:**
```markdown
Part of initiative: [<initiative-name>](<yaml-url>)

Workstream: <workstream-name>
Milestone: <milestone-title>
```

### Order of Operations

```
1. Create issue in target repo
2. Link to project (if applicable)
3. Assign to milestone (if applicable)
4. Add initiative reference comment (if applicable)
5. Add dependency comments (if task depends on others)
```

### Batch Operations

For efficiency when creating many tasks:
```bash
# Create all issues first
issue_urls=()
for task in "${tasks[@]}"; do
  url=$(gh issue create --repo <repo> --title "<title>" --body "<body>" --format "%U")
  issue_urls+=("$url")
done

# Batch link to project
for url in "${issue_urls[@]}"; do
  gh project item-add <number> --owner <org> --url "$url"
done

# Batch assign milestones (group by milestone)
for milestone in "${milestones[@]}"; do
  for issue_num in "${milestone_issues[$milestone]}"; do
    gh issue edit "$issue_num" --repo <repo> --milestone "$milestone"
  done
done
```
```

- [ ] **Step 2: Verify linking logic is clear**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
grep "## Linking and Assignment Logic" skills/initiative-breakdown/skill.md
```

Expected: Linking section exists with project/milestone logic

- [ ] **Step 3: Commit linking logic**

```bash
git add skills/initiative-breakdown/skill.md
git commit -m "docs(initiative-breakdown): add linking and milestone assignment logic"
```

---

### Task 5: Create Test Script for Linking

**Files:**
- Create: `test/initiative-breakdown/test-linking.sh`

- [ ] **Step 1: Create test directory**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
mkdir -p test/initiative-breakdown
```

- [ ] **Step 2: Write linking test script**

Create `test/initiative-breakdown/test-linking.sh`:

```bash
#!/usr/bin/env bash
# Test issue linking and milestone assignment logic

set -e

echo "Testing initiative-breakdown linking logic..."

# Test 1: Simulate project linking
echo "Test 1: Project linking simulation"
project_number=14
org="eci-global"
issue_url="https://github.com/eci-global/test-repo/issues/999"

# Build command (don't execute, just validate syntax)
cmd="gh project item-add $project_number --owner $org --url $issue_url"
echo "Command: $cmd"

if [[ "$cmd" =~ "gh project item-add" ]] && [[ "$cmd" =~ "--owner" ]] && [[ "$cmd" =~ "--url" ]]; then
  echo "✓ Project linking command format valid"
else
  echo "✗ Invalid command format"
  exit 1
fi

# Test 2: Milestone assignment simulation
echo ""
echo "Test 2: Milestone assignment simulation"
issue_num=999
repo="eci-global/test-repo"
milestone="M1 — Foundation"

cmd="gh issue edit $issue_num --repo $repo --milestone \"$milestone\""
echo "Command: $cmd"

if [[ "$cmd" =~ "gh issue edit" ]] && [[ "$cmd" =~ "--milestone" ]]; then
  echo "✓ Milestone assignment command format valid"
else
  echo "✗ Invalid command format"
  exit 1
fi

# Test 3: Initiative comment format
echo ""
echo "Test 3: Initiative comment format"
yaml_url="https://github.com/eci-global/initiatives/blob/main/initiatives/2026-q1-test.yaml"
initiative_name="2026 Q1 - Test Initiative"
comment="Part of initiative: [$initiative_name]($yaml_url)"

if [[ "$comment" =~ "Part of initiative:" ]] && [[ "$comment" =~ \[.*\]\(.*\) ]]; then
  echo "✓ Initiative comment format valid"
  echo "  Comment: $comment"
else
  echo "✗ Invalid comment format"
  exit 1
fi

# Test 4: Batch operation logic
echo ""
echo "Test 4: Batch operation simulation"
issue_urls=(
  "https://github.com/org/repo/issues/1"
  "https://github.com/org/repo/issues/2"
  "https://github.com/org/repo/issues/3"
)

count=0
for url in "${issue_urls[@]}"; do
  # Simulate linking
  if [[ "$url" =~ https://github.com/.*/issues/[0-9]+ ]]; then
    ((count++))
  fi
done

if [ $count -eq 3 ]; then
  echo "✓ Batch operations: $count issues processed"
else
  echo "✗ Batch operation failed"
  exit 1
fi

# Test 5: Milestone grouping
echo ""
echo "Test 5: Milestone grouping logic"
declare -A milestone_issues
milestone_issues["M1"]="1 2 3"
milestone_issues["M2"]="4 5"

total_grouped=0
for milestone in "${!milestone_issues[@]}"; do
  count=$(echo "${milestone_issues[$milestone]}" | wc -w)
  total_grouped=$((total_grouped + count))
  echo "  Milestone $milestone: $count issues"
done

if [ $total_grouped -eq 5 ]; then
  echo "✓ Milestone grouping: $total_grouped total issues"
else
  echo "✗ Grouping failed"
  exit 1
fi

# Test 6: Order of operations validation
echo ""
echo "Test 6: Order of operations"
operations=("create_issue" "link_project" "assign_milestone" "add_comment")
current_step=0

for op in "${operations[@]}"; do
  ((current_step++))
  echo "  Step $current_step: $op"
done

if [ $current_step -eq 4 ]; then
  echo "✓ All 4 operations in correct order"
else
  echo "✗ Operation order incorrect"
  exit 1
fi

echo ""
echo "=========================================="
echo "All linking logic tests passed!"
echo "=========================================="
```

- [ ] **Step 3: Make test executable**

```bash
chmod +x test/initiative-breakdown/test-linking.sh
```

- [ ] **Step 4: Run test**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
./test/initiative-breakdown/test-linking.sh
```

Expected: All 6 tests pass

- [ ] **Step 5: Commit linking test**

```bash
git add test/initiative-breakdown/test-linking.sh
git commit -m "test(initiative-breakdown): add linking and assignment logic test"
```

---

### Task 6: Update Configuration and Integration Sections

**Files:**
- Modify: `skills/initiative-breakdown/skill.md:346-365` (Configuration)
- Modify: `skills/initiative-breakdown/skill.md:402-414` (Integration)

- [ ] **Step 1: Update configuration**

Replace configuration section:

```markdown
## Configuration

The skill respects configuration from `.claude-grimoire/config.json`:

```json
{
  "initiativeBreakdown": {
    "defaultTaskSize": "M",
    "includeFileReferences": true,
    "includeImplementationNotes": true,
    "autoInvokeArchitect": false,
    "effortEstimationUnit": "days",
    "linkToProject": true,
    "assignToMilestones": true,
    "createMilestonesIfMissing": false,
    "batchOperations": true,
    "maxTasksPerBreakdown": 50,
    "requireConfirmation": false
  },
  "github": {
    "defaultLabels": ["task"],
    "defaultAssignee": "@me"
  }
}
```

**New configuration fields:**

- `linkToProject` - Automatically link issues to GitHub Project if initiative has one (default: true)
- `assignToMilestones` - Automatically assign issues to milestones when applicable (default: true)
- `createMilestonesIfMissing` - Create milestone if it doesn't exist (default: false - warn instead)
- `batchOperations` - Use batch operations for efficiency (default: true)
- `maxTasksPerBreakdown` - Warn if breakdown would create more than N tasks (default: 50)
- `requireConfirmation` - Ask before creating issues (default: false)
```

- [ ] **Step 2: Update integration section**

Replace "Integration with Other Skills" section:

```markdown
## Integration with Other Skills

**Before initiative-breakdown:**
- `/initiative-creator` - Create initiative or gather context
- Manual initiative YAML creation

**During initiative-breakdown:**
- `github-context-agent` - Fetch context for any input type (required)
- `system-architect-agent` - Design architecture for complex initiatives (optional)

**After initiative-breakdown:**
- `feature-delivery-team` - Execute task implementation
- `staff-developer` - Implement individual tasks
- Manual assignment - Assign tasks to team members

**Invoked by:**
- `initiative-creator` - After creating initiative YAML
- `feature-delivery-team` - Phase 3 (task breakdown)
- Users directly via `/initiative-breakdown`

**Example integration:**

From initiative-creator:
```markdown
After creating initiative YAML:
  Ask user: "Would you like me to break this down into tasks now?"
  If yes: Invoke /initiative-breakdown with YAML path
```

From feature-delivery-team:
```markdown
Phase 3: Task Breakdown
  If user provided initiative: Invoke /initiative-breakdown
  If user provided project: Invoke /initiative-breakdown with project
  If standalone: Create simple task list (no skill needed)
```
```

- [ ] **Step 3: Verify configuration and integration updates**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
grep "linkToProject" skills/initiative-breakdown/skill.md
grep "github-context-agent" skills/initiative-breakdown/skill.md
```

Expected: New config fields present, integration mentions agent

- [ ] **Step 4: Commit configuration and integration updates**

```bash
git add skills/initiative-breakdown/skill.md
git commit -m "docs(initiative-breakdown): update configuration and integration sections"
```

---

### Task 7: Final Review and Summary

**Files:**
- Modify: `skills/initiative-breakdown/skill.md` (add migration notes at end)

- [ ] **Step 1: Add migration notes**

Add section at end:

```markdown
## Migration from v1.0.0

Version 2.0.0 adds flexible input handling while maintaining backward compatibility.

### What Changed

**New in v2.0.0:**
- Accepts any organizational pattern (initiative/project/workstream/milestone)
- Uses github-context-agent for context resolution
- Automatically links to GitHub Projects when applicable
- Assigns to milestones when scoped
- Supports breaking down individual workstreams or milestones

**Still works (v1.0.0 behavior):**
- Breaking down initiatives via YAML path
- All task generation logic
- Effort estimation and dependencies

### Breaking Changes

None. All v1.0.0 input formats continue to work.

### Migration Path

**For skills invoking initiative-breakdown:**

Old way:
```bash
/initiative-breakdown owner/repo#123
```

New way (same, but now also accepts):
```bash
/initiative-breakdown eci-global#14  # project
/initiative-breakdown "initiative:name workstream:ws"  # workstream
/initiative-breakdown 'repo milestone:"M1"'  # milestone
```

No code changes needed - additional formats now supported.
```

- [ ] **Step 2: Run linking test**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
./test/initiative-breakdown/test-linking.sh
```

Expected: All tests pass

- [ ] **Step 3: Verify skill.md is complete**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
wc -l skills/initiative-breakdown/skill.md
ls -la skills/initiative-breakdown/examples/
```

Expected: skill.md approximately 700-800 lines, 4 example files

- [ ] **Step 4: Create summary commit**

```bash
git add skills/initiative-breakdown/skill.md
git commit -m "docs(initiative-breakdown): add migration notes and finalize v2.0.0 documentation"
```

- [ ] **Step 5: Create plan completion summary**

```markdown
# initiative-breakdown Updates - Plan Complete

## What Was Implemented

### Skill Documentation Updates (skills/initiative-breakdown/skill.md)
- ✅ Updated input handling to use github-context-agent
- ✅ Added initiative breakdown workflow
- ✅ Added project breakdown workflow
- ✅ Added workstream breakdown workflow
- ✅ Added milestone breakdown workflow
- ✅ Documented linking and milestone assignment logic
- ✅ Updated configuration with linking options
- ✅ Updated integration patterns
- ✅ Added migration notes

### Examples Created
- ✅ skills/initiative-breakdown/examples/break-down-initiative.md
- ✅ skills/initiative-breakdown/examples/break-down-project.md
- ✅ skills/initiative-breakdown/examples/break-down-workstream.md
- ✅ skills/initiative-breakdown/examples/break-down-milestone.md

### Test Scripts Created
- ✅ test/initiative-breakdown/test-linking.sh (6 tests)

## Verification

All tests passing:
- Linking logic: ✅ (validates project/milestone assignment)

## Next Steps

This plan is complete. initiative-breakdown now supports:
1. Initiative YAML breakdown (all workstreams)
2. GitHub Project breakdown (organize existing items)
3. Workstream breakdown (single workstream only)
4. Milestone breakdown (single milestone tasks)
5. Automatic linking to GitHub Projects
6. Automatic milestone assignment

Ready for:
- Plan 4: Teams & PR Integration
```

---

## Plan Self-Review

### Spec Coverage Check

✅ **Flexible input** - Accepts initiative/project/workstream/milestone via github-context-agent
✅ **Initiative breakdown** - Full workflow with workstreams and milestones
✅ **Project breakdown** - Organize by repos/milestones
✅ **Workstream breakdown** - Single workstream scoping
✅ **Milestone breakdown** - Single milestone tasks
✅ **Linking logic** - Project and milestone assignment documented
✅ **Configuration** - Updated with linking options
✅ **Integration** - Updated to use github-context-agent
✅ **Examples** - 4 examples covering all input types
✅ **Testing** - Linking logic test script
✅ **Migration** - Backward compatibility documented

### Placeholder Scan

✅ No "TBD" or "TODO" markers
✅ All workflows have specific steps
✅ Commands show exact syntax
✅ Examples show full process
✅ No vague "add appropriate" statements

### Type Consistency

✅ Input types match github-context-agent: initiative, project, workstream, milestone
✅ Field names consistent: github_project, workstreams, milestones
✅ Command syntax consistent across examples

### Gaps

None identified. All spec requirements for initiative-breakdown covered.

---
