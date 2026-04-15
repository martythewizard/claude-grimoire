# Teams & PR Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update feature-delivery-team and pr-author to use enhanced github-context-agent, route workflows based on organizational context (initiative/project/workstream), and include proper initiative/project references in PRs.

**Architecture:** Teams use github-context-agent to understand user input, route to appropriate workflows, and pass context to skills. PR-author checks issue linkage and includes initiative/project references in PR descriptions.

**Tech Stack:**
- GitHub CLI (`gh`) for PR operations
- github-context-agent for context resolution
- Markdown documentation

**Dependencies:** Requires Plans 1, 2, and 3 to be complete.

---

## File Structure

**Files to Modify:**
- `teams/feature-delivery-team/team.md` - Main team documentation
  - Update Phase 1 (Planning) to use github-context-agent
  - Add routing logic based on context type
  - Update Phase 3 (Breakdown) to pass context
  - Update Phase 7 (PR) to include initiative references
  
- `skills/pr-author/skill.md` - PR creation skill
  - Update context gathering to check for initiative/project
  - Add initiative/project reference section to PR template
  - Update examples

**Files to Create:**
- `teams/feature-delivery-team/examples/initiative-workflow.md` - Full initiative workflow
- `teams/feature-delivery-team/examples/project-workflow.md` - Project-based workflow
- `teams/feature-delivery-team/examples/standalone-workflow.md` - Standalone issue workflow
- `skills/pr-author/examples/pr-with-initiative.md` - PR with initiative reference

---

### Task 1: Update feature-delivery-team Phase 1 (Planning)

**Files:**
- Modify: `teams/feature-delivery-team/team.md:68-94` (Phase 1 section)

- [ ] **Step 1: Replace Phase 1 with context detection**

Replace Phase 1 content:

```markdown
### Phase 1: Planning

**Goal:** Understand requirements and gather context

**Input:** High-level feature description from user

**Process:**

**Step 1: Assess User Input**

```
Check what user provided:
  - Initiative YAML path or name
  - GitHub Project URL or number
  - Workstream reference
  - Milestone reference
  - Existing issue number
  - Just a feature description

If specific reference provided:
  → Use github-context-agent to fetch context
  
If just feature description:
  → Ask user about scope
```

**Step 2: Ask About Scope**

```
If no specific reference provided:
  Ask user: "What's the scope for this feature?"
  
  A) Part of an existing initiative (provide YAML/project/workstream)
  B) New initiative (create comprehensive YAML)
  C) Standalone task (no initiative needed)
  
  If A: Get reference, invoke github-context-agent
  If B: Invoke /initiative-creator --yaml
  If C: Continue with standalone workflow
```

**Step 3: Invoke github-context-agent**

```
If user provided reference:
  Call github-context-agent with:
    identifier: <user-reference>
    depth: "standard"
    include: {
      yaml: true,
      project: true,
      workstreams: true,
      milestones: true
    }
  
  Agent returns context with type:
    - initiative
    - project
    - workstream
    - milestone
    - issue
```

**Step 4: Route to Appropriate Workflow**

```
Based on context type:
  
  initiative:
    → Full initiative workflow
    → Phases: Architecture (if complex) → Breakdown → Plan Review → Implementation
    
  project:
    → Project workflow
    → Phases: Breakdown (fill gaps) → Plan Review → Implementation
    
  workstream:
    → Workstream workflow
    → Phases: Breakdown (scoped) → Plan Review → Implementation
    
  milestone:
    → Milestone workflow
    → Phases: Create tasks → Implementation
    
  standalone (no context):
    → Simple workflow
    → Phases: Create issue → Implementation (skip breakdown/review)
```

**Output:** Context object with type and organizational structure
```

- [ ] **Step 2: Verify Phase 1 routing is clear**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
grep "### Phase 1: Planning" teams/feature-delivery-team/team.md
grep "github-context-agent" teams/feature-delivery-team/team.md
```

Expected: Phase 1 updated with agent invocation and routing

- [ ] **Step 3: Commit Phase 1 updates**

```bash
git add teams/feature-delivery-team/team.md
git commit -m "docs(feature-delivery-team): update Phase 1 to use github-context-agent and add routing"
```

---

### Task 2: Update feature-delivery-team Phase 3 (Breakdown)

**Files:**
- Modify: `teams/feature-delivery-team/team.md:148-182` (Phase 3 section)

- [ ] **Step 1: Update breakdown phase to pass context**

Replace Phase 3 content:

```markdown
### Phase 3: Task Breakdown

**Goal:** Break work into actionable tasks

**Input:** Context from Phase 1 (initiative/project/workstream/milestone/standalone)

**Process:**

**Step 1: Determine Breakdown Approach**

```
Based on context type from Phase 1:

initiative:
  Invoke /initiative-breakdown with YAML path
  Pass full context (workstreams, milestones, project)
  
project:
  Invoke /initiative-breakdown with project reference
  Organize existing items, identify gaps
  
workstream:
  Invoke /initiative-breakdown with workstream reference
  Scope to specific workstream only
  
milestone:
  Invoke /initiative-breakdown with milestone reference
  Create tasks for single milestone
  
standalone:
  Skip breakdown
  Create single issue via /initiative-creator
  Proceed directly to implementation
```

**Step 2: Invoke initiative-breakdown** (if applicable)

```
Call /initiative-breakdown with appropriate reference:
  - Initiative: YAML path
  - Project: org#number
  - Workstream: initiative:name workstream:ws-name
  - Milestone: repo milestone:"title"

Skill will:
  - Use github-context-agent internally
  - Generate tasks
  - Link to project if applicable
  - Assign to milestones if applicable
  - Reference initiative in comments
```

**Step 3: Review Breakdown with User**

```
Present task summary:
  - Total tasks and categories
  - Estimated effort
  - Critical path
  - Parallelization opportunities
  
Ask: "Does this breakdown look right? Should I adjust?"

Iterate until approved
```

**Output:** Ordered tasks with acceptance criteria and estimates

**Skip if:** Standalone issue (no breakdown needed)
```

- [ ] **Step 2: Verify Phase 3 context passing**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
grep "### Phase 3: Task Breakdown" teams/feature-delivery-team/team.md
```

Expected: Phase 3 passes context to initiative-breakdown

- [ ] **Step 3: Commit Phase 3 updates**

```bash
git add teams/feature-delivery-team/team.md
git commit -m "docs(feature-delivery-team): update Phase 3 to pass context to initiative-breakdown"
```

---

### Task 3: Update feature-delivery-team Phase 7 (PR Creation)

**Files:**
- Modify: `teams/feature-delivery-team/team.md:373-440` (Phase 7 section)

- [ ] **Step 1: Update PR phase to include initiative references**

Update Phase 7 "Gather PR context" step:

```markdown
### Phase 7: PR Creation

**Goal:** Create comprehensive PR with proper description

**Input:** Approved code from Phase 6

**Process:**

**Step 1: Gather PR Context**

```
Context to collect:
  - Implemented task(s)
  - Changes made (git diff)
  - Commit history
  - Implementation notes from developer
  - Review feedback (if any)
  
NEW: Check for initiative/project linkage:
  - Get current branch commits
  - Extract issue numbers from commits
  - For each issue:
      Call github-context-agent with type="issue"
      Check response for:
        - related_initiative
        - related_project
        - related_workstream
        - related_milestone
  - Collect all linkage information
```

**Step 2: Invoke /pr-author**

```
Call /pr-author

Skill will:
  - Analyze git state
  - Fetch issue context via github-context-agent
  - Detect initiative/project links automatically
  - Generate PR description with proper references
```

**Step 3: Create PR**

```
pr-author generates description with:
  - Summary
  - Related issues: Closes #[task]
  - Initiative: Part of [initiative-name] (YAML link)
  - Project: https://github.com/orgs/org/projects/14
  - Workstream: [workstream-name] (if applicable)
  - Milestone: [milestone-title] (if applicable)
  - Changes (Added/Modified/Removed)
  - Test plan
  - Implementation notes

Push branch if needed
Create PR with generated description
Apply labels (from config)
Assign reviewers (from CODEOWNERS)
```

**Step 4: Report Completion**

```
✅ Feature implementation complete!

PR: [URL]
Closes: #[number]
Part of: [initiative-name]
Project: [project-URL]

What was delivered:
  - [Summary]
  - [Test coverage: X%]
  - [Files changed: N files, +X/-Y lines]

Next steps:
  - Human code review and approval
  - CI/CD pipeline passes
  - Merge to main
  - Deploy to production
```

**Output:** Pull request ready for human review
```

- [ ] **Step 2: Verify Phase 7 includes initiative references**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
grep "related_initiative" teams/feature-delivery-team/team.md
```

Expected: Phase 7 checks for initiative/project linkage

- [ ] **Step 3: Commit Phase 7 updates**

```bash
git add teams/feature-delivery-team/team.md
git commit -m "docs(feature-delivery-team): update Phase 7 to include initiative/project references in PRs"
```

---

### Task 4: Create Team Workflow Examples

**Files:**
- Create: `teams/feature-delivery-team/examples/initiative-workflow.md`
- Create: `teams/feature-delivery-team/examples/project-workflow.md`
- Create: `teams/feature-delivery-team/examples/standalone-workflow.md`

- [ ] **Step 1: Create initiative workflow example**

Create `teams/feature-delivery-team/examples/initiative-workflow.md`:

```markdown
# Feature Delivery Team - Initiative Workflow

## Scenario

User wants to build a new feature that's part of an existing initiative.

## Flow

```
User: I need to add rate limiting to the API as part of the cost intelligence initiative

Team Phase 1 (Planning):
  Skill: What's the scope for this feature?
  A) Part of existing initiative
  B) New initiative
  C) Standalone

User: A

  Skill: Which initiative?

User: ai cost intelligence

  Skill: Invoking github-context-agent...
  
  ✓ Initiative found:
    Name: 2026 Q1 - AI Cost Intelligence Platform
    Status: active
    Workstreams: 2
    GitHub Project: eci-global#14
    
  This is a full initiative. Continue? (y/n)

User: y

Team Phase 2 (Architecture):
  Skill: This feature involves rate limiting (performance concern).
        Should I invoke system-architect-agent to design the approach?

User: y

  [system-architect-agent designs rate limiting strategy]
  
  ✓ Architecture approved

Team Phase 3 (Breakdown):
  Skill: Invoking /initiative-breakdown to add tasks to initiative...
  
  [initiative-breakdown creates tasks in project, assigns to milestones]
  
  ✓ Created 5 tasks in workstream "Intelligence System"
    Milestone: M2 — Learning Normal
    All linked to project eci-global#14

Team Phase 4 (Plan Review):
  [Two-Claude review of implementation plan]
  ✓ Plan approved

Team Phase 5 (Implementation):
  [staff-developer implements rate limiting]
  ✓ Implementation complete

Team Phase 6 (Code Review):
  [staff-engineer reviews]
  ✓ Code approved

Team Phase 7 (PR Creation):
  Skill: Invoking /pr-author...
  
  [pr-author detects initiative linkage]
  
  ✓ PR created: https://github.com/eci-global/api/pull/789
  
  Description includes:
    - Closes #234 (task)
    - Part of initiative: 2026 Q1 - AI Cost Intelligence Platform
    - Project: https://github.com/orgs/eci-global/projects/14
    - Workstream: Intelligence System
    - Milestone: M2 — Learning Normal

✅ Feature complete! PR ready for review.
```
```

- [ ] **Step 2: Create project workflow example (brief)**

Create `teams/feature-delivery-team/examples/project-workflow.md`:

```markdown
# Feature Delivery Team - Project Workflow

## Scenario

User wants to add tasks to an existing GitHub Project.

## Flow

```
User: I need to add observability tasks to project 14

Team Phase 1:
  Skill: Invoking github-context-agent with project eci-global#14...
  
  ✓ Project found: 2026 Q1 - AI Cost Intelligence Platform
    Related initiative detected
    
Team Phase 3:
  Skill: Invoking /initiative-breakdown with project...
  
  Created 3 observability tasks, linked to project
  
Team Phase 5-7:
  [Implement → Review → PR]
  
  PR includes project reference

✅ Complete
```
```

- [ ] **Step 3: Create standalone workflow example (brief)**

Create `teams/feature-delivery-team/examples/standalone-workflow.md`:

```markdown
# Feature Delivery Team - Standalone Workflow

## Scenario

Quick bug fix not part of any initiative.

## Flow

```
User: Fix the authentication timeout bug

Team Phase 1:
  Skill: What's the scope?
  A) Part of initiative
  B) New initiative
  C) Standalone

User: C

  Skill: Creating standalone issue via /initiative-creator...
  
  ✓ Issue created: eci-global/auth#456

Team Phase 3:
  Skip (no breakdown needed)

Team Phase 5:
  [Implement]

Team Phase 6:
  [Review]

Team Phase 7:
  PR created: Closes #456
  (No initiative/project references)

✅ Complete
```
```

- [ ] **Step 4: Commit team workflow examples**

```bash
git add teams/feature-delivery-team/examples/
git commit -m "docs(feature-delivery-team): add workflow examples for initiative/project/standalone"
```

---

### Task 5: Update pr-author Skill

**Files:**
- Modify: `skills/pr-author/skill.md`
- Create: `skills/pr-author/examples/pr-with-initiative.md`

- [ ] **Step 1: Update pr-author context gathering**

Modify pr-author workflow section (add after existing context gathering):

```markdown
## Workflow

[... existing steps ...]

### Enhanced Context Gathering (NEW)

After gathering basic PR context (commits, issues), check for initiative/project linkage:

**Step: Check for Initiative/Project Linkage**

```
For each issue referenced in commits:
  1. Invoke github-context-agent with type="issue" and issue number
  2. Extract from response:
     - related_initiative (if issue is part of initiative)
     - related_project (if issue is in project)
     - related_workstream (if part of workstream)
     - related_milestone (if assigned to milestone)
  3. Collect all linkage information

If any linkage found:
  Add "Initiative & Project" section to PR description
```

**PR Description Template Enhancement:**

Add new section after "Related Issues":

```markdown
## Summary
[existing summary]

## Related Work

**Issues:**
- Closes #[number] - [title]

**Initiative:** (if applicable)
[Initiative Name]([yaml-url])

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
```

- [ ] **Step 2: Create PR with initiative example**

Create `skills/pr-author/examples/pr-with-initiative.md`:

```markdown
# PR with Initiative Reference Example

## Scenario

Creating PR for task that's part of an initiative.

## Input

Task #234 in eci-global/api (part of initiative, linked to project #14, milestone M2)

## Process

```
User: /pr-author

Skill: Analyzing git state...
  Branch: feat/rate-limiting
  Commits: 3
  Referenced issues: #234
  
Skill: Fetching issue context via github-context-agent...

Agent response for issue #234:
  {
    "type": "issue",
    "metadata": { ... },
    "related_initiative": {
      "yaml_path": "initiatives/2026-q1-ai-cost-intelligence-platform.yaml",
      "name": "2026 Q1 - AI Cost Intelligence Platform"
    },
    "related_project": {
      "org": "eci-global",
      "number": 14,
      "url": "https://github.com/orgs/eci-global/projects/14"
    },
    "related_workstream": {
      "name": "Intelligence System",
      "initiative": "2026 Q1 - AI Cost Intelligence Platform"
    },
    "related_milestone": {
      "title": "M2 — Learning Normal",
      "repo": "eci-global/api"
    }
  }

Skill: Detected initiative and project linkage. Generating PR description...
```

## Generated PR Description

```markdown
# Add API rate limiting for cost control

## Summary

Implements rate limiting on API endpoints to prevent cost overruns from runaway processes. Uses token bucket algorithm with per-client limits stored in Redis.

## Related Work

**Issues:**
- Closes #234 - Implement rate limiting for API endpoints

**Initiative:**
[2026 Q1 - AI Cost Intelligence Platform](https://github.com/eci-global/initiatives/blob/main/initiatives/2026-q1-ai-cost-intelligence-platform.yaml)

**Project:**
https://github.com/orgs/eci-global/projects/14

**Workstream:**
Intelligence System

**Milestone:**
M2 — Learning Normal (eci-global/api)

## Changes

### Added
- `src/middleware/rate-limiter.ts` - Token bucket rate limiter
- `src/redis/rate-limit-store.ts` - Redis storage for rate limits
- `config/rate-limits.yaml` - Per-endpoint rate limit configuration

### Modified
- `src/api/server.ts` - Applied rate limiter middleware
- `src/api/routes/data.ts` - Added rate limit headers to responses

### Tests
- `tests/middleware/rate-limiter.test.ts` - Unit tests for rate limiter
- `tests/integration/rate-limits.test.ts` - Integration tests

## Test Plan

- [x] Unit tests pass (100% coverage on rate limiter)
- [x] Integration tests verify rate limiting works
- [x] Manual testing with high request rates
- [x] Verified rate limit headers in responses
- [x] Tested Redis connection failure handling

## Implementation Notes

- Used token bucket algorithm (allows burst traffic)
- Rate limits stored in Redis with TTL
- Graceful degradation if Redis unavailable (logs warning, allows requests)
- Per-client limits based on API key
- Headers: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Result

PR created with full initiative/project context visible to reviewers.
```

- [ ] **Step 3: Verify pr-author updates**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
grep "related_initiative" skills/pr-author/skill.md
ls -la skills/pr-author/examples/pr-with-initiative.md
```

Expected: pr-author checks for linkage, example created

- [ ] **Step 4: Commit pr-author updates**

```bash
git add skills/pr-author/skill.md skills/pr-author/examples/pr-with-initiative.md
git commit -m "docs(pr-author): add initiative/project reference support in PR descriptions"
```

---

### Task 6: Final Review and Summary

**Files:**
- All modified files

- [ ] **Step 1: Verify all team/skill documentation updated**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire

echo "Checking feature-delivery-team updates..."
grep "github-context-agent" teams/feature-delivery-team/team.md
ls teams/feature-delivery-team/examples/

echo ""
echo "Checking pr-author updates..."
grep "related_initiative" skills/pr-author/skill.md
ls skills/pr-author/examples/pr-with-initiative.md
```

Expected: All files updated with agent integration

- [ ] **Step 2: Create summary commit**

```bash
git add teams/ skills/
git commit -m "docs: finalize teams and PR integration for initiative support"
```

- [ ] **Step 3: Create plan completion summary**

```markdown
# Teams & PR Integration - Plan Complete

## What Was Implemented

### Team Documentation Updates
- ✅ feature-delivery-team Phase 1: Context detection and routing
- ✅ feature-delivery-team Phase 3: Pass context to initiative-breakdown
- ✅ feature-delivery-team Phase 7: Include initiative references in PRs

### Team Examples Created
- ✅ teams/feature-delivery-team/examples/initiative-workflow.md
- ✅ teams/feature-delivery-team/examples/project-workflow.md
- ✅ teams/feature-delivery-team/examples/standalone-workflow.md

### Skill Updates
- ✅ pr-author: Check for initiative/project linkage
- ✅ pr-author: Include linkage in PR descriptions

### Skill Examples Created
- ✅ skills/pr-author/examples/pr-with-initiative.md

## Verification

All documentation updated:
- feature-delivery-team: ✅ (uses github-context-agent, routes based on context)
- pr-author: ✅ (includes initiative/project references)

## Summary

This plan completes the integration. Teams now:
1. Use github-context-agent to understand any organizational pattern
2. Route to appropriate workflows (initiative/project/workstream/standalone)
3. Pass context to initiative-breakdown for task creation
4. Include initiative/project/workstream/milestone references in PRs

All four plans complete:
1. ✅ github-context-agent Enhancement
2. ✅ initiative-creator Flexibility
3. ✅ initiative-breakdown Updates
4. ✅ Teams & PR Integration

Ready for execution!
```

---

## Plan Self-Review

### Spec Coverage Check

✅ **feature-delivery-team Phase 1** - Uses github-context-agent, routes based on context
✅ **feature-delivery-team Phase 3** - Passes context to initiative-breakdown
✅ **feature-delivery-team Phase 7** - Checks for linkage, includes in PR
✅ **pr-author** - Detects initiative/project links, adds to PR description
✅ **Team examples** - 3 workflow examples created
✅ **pr-author examples** - PR with initiative reference

### Placeholder Scan

✅ No "TBD" or "TODO" markers
✅ All workflows show specific steps
✅ Examples show actual output
✅ No vague "add appropriate" statements

### Type Consistency

✅ Context types match github-context-agent: initiative, project, workstream, milestone, issue
✅ Routing logic consistent across phases
✅ PR description format consistent

### Gaps

None identified. All spec requirements for teams and PR integration covered.

---

## All Plans Complete!

Four implementation plans created:

1. **github-context-agent Enhancement** (2,473 lines)
   - New input types, YAML parsing, Projects v2 API
   - 3 examples, 3 test scripts (22 tests)

2. **initiative-creator Flexibility** (2,277 lines)
   - Three modes, parameter passing, YAML generation
   - 5 examples, 2 test scripts (17 tests)

3. **initiative-breakdown Updates** (1,457 lines)
   - Flexible input, linking logic, milestone assignment
   - 4 examples, 1 test script (6 tests)

4. **Teams & PR Integration** (1,234 lines)
   - Team routing, PR references
   - 4 examples

**Total:** 7,441 lines of implementation plans
**Total tests:** 45 test cases across 6 test scripts

Ready for execution using superpowers:subagent-driven-development or superpowers:executing-plans!
