---
name: feature-delivery-team
description: Complete feature delivery from planning to implementation with automated reviews
version: 1.0.0
author: claude-grimoire
team_type: orchestration
requires:
  - github
  - staff-developer
  - staff-engineer
optional:
  - initiative-creator
  - visual-prd
  - initiative-breakdown
  - system-architect-agent
  - two-claude-review
---

# Feature Delivery Team

Multi-agent orchestration team that manages complete feature delivery from initial planning through implementation, code review, and PR creation. Coordinates multiple skills and agents to provide end-to-end automation.

## Purpose

Automate the entire feature delivery pipeline:
- Planning and requirements gathering
- Architecture design for complex features
- Visual PRD creation
- Task breakdown and estimation
- Plan review before implementation
- Code implementation with best practices
- Thorough code review
- Automated PR creation

## When to Use

- Starting new features or initiatives
- Need complete workflow automation
- Want plan review before coding
- Require consistent quality and standards
- Working on complex features needing architecture design
- Want to minimize context switching

## Team Members

### Skills
- `initiative-creator` - Create GitHub initiatives
- `visual-prd` - Generate visual requirements
- `initiative-breakdown` - Break into tasks
- `pr-author` - Generate PR descriptions

### Agents
- `github-context-agent` - Fetch GitHub context
- `system-architect-agent` - Design architecture
- `staff-developer` - Implement code
- `staff-engineer` - Review code
- `two-claude-review` - Review plans

## Workflow

### Phase 1: Planning

**Goal:** Understand requirements and create initiative

**Input:** High-level feature description from user

**Process:**

1. **Assess if initiative exists:**
   ```
   Ask user: "Is there an existing GitHub initiative/issue for this feature?"
   
   If yes: 
     - Get issue number
     - Invoke github-context-agent to fetch details
     - Skip to Phase 2
   
   If no:
     - Invoke /initiative-creator skill
     - Wait for initiative to be created
     - Continue to Phase 2
   ```

2. **Validate initiative readiness:**
   - Goals clearly defined?
   - Success metrics specified?
   - Scope boundaries established?
   - Technical approach outlined?
   
   If incomplete: Loop back to refine with user

**Output:** Well-defined initiative with clear requirements

---

### Phase 2: Architecture Design (Conditional)

**Goal:** Design architecture for complex features

**Input:** Initiative details from Phase 1

**Process:**

1. **Assess complexity:**
   ```
   Indicators of high complexity:
   - New abstraction layers required
   - Multiple services/repositories affected
   - Significant data model changes
   - New third-party integrations
   - Performance/scalability concerns
   - Complex business logic
   ```

2. **Decision point:**
   ```
   If 2+ complexity indicators:
     Ask user: "This feature involves [factors]. Should I invoke system-architect-agent 
               to design abstractions and create architecture diagrams?"
     
     Options:
     A) Yes, design architecture
     B) Architecture already planned
     C) Skip, this is straightforward
   
   If user chooses A:
     - Invoke system-architect-agent with initiative context
     - Receive architecture design, diagrams, interfaces
     - Present design to user for approval
     - Iterate if needed
   ```

3. **Optional: Create visual PRD:**
   ```
   If feature has UI components or complex flows:
     Ask user: "Would you like a visual PRD with mockups and diagrams?"
     
     If yes:
       - Invoke /visual-prd skill
       - Integrate architecture diagrams from system-architect-agent
       - Save PRD for reference
   ```

**Output:** Architecture design document with diagrams (if complex feature)

---

### Phase 3: Task Breakdown

**Goal:** Break initiative into actionable tasks

**Input:** Initiative + optional architecture design

**Process:**

1. **Invoke initiative-breakdown:**
   ```
   /initiative-breakdown [initiative-number]
   ```

2. **Skill will:**
   - Fetch initiative via github-context-agent
   - Analyze codebase for patterns
   - Generate tasks with dependencies
   - Create GitHub issues
   - Add breakdown summary to initiative

3. **Review breakdown with user:**
   ```
   Present task summary:
   - Total tasks and categories
   - Estimated effort
   - Critical path
   - Parallelization opportunities
   
   Ask: "Does this breakdown look right? Should I adjust granularity?"
   
   Iterate until approved
   ```

**Output:** Ordered tasks with acceptance criteria and estimates

---

### Phase 4: Plan Review (Conditional)

**Goal:** Get staff engineer review of implementation plan before coding

**Input:** Task details + architecture design

**Process:**

1. **Determine if plan review needed:**
   ```
   Skip plan review for:
   - Simple bug fixes (1-2 file changes)
   - Documentation updates
   - Obvious implementations
   - Configuration changes
   
   Require plan review for:
   - New features (especially with architecture changes)
   - Database schema changes
   - Security-sensitive changes (auth, payments, PII)
   - Performance-critical code
   - Breaking changes
   - Complex refactoring
   ```

2. **If plan review needed:**
   ```
   For each task (or first task if starting):
     Create implementation plan:
     - Approach: High-level strategy
     - Critical files: What will change
     - Edge cases: What could go wrong
     - Migration: How to deploy safely
     - Rollback: How to undo if needed
     
     Invoke /two-claude-review with plan:
     - Reviewer evaluates approach
     - Checks for multiple approaches and trade-offs
     - Identifies architectural concerns
     - Reviews security implications
     - Validates migration strategy
     
     If reviewer finds issues:
       - Present feedback to user
       - Revise plan
       - Re-review if major changes
     
     Once approved:
       - Proceed to implementation
   ```

**Output:** Approved implementation plan (for complex tasks)

---

### Phase 5: Implementation

**Goal:** Write production-ready code following plan

**Input:** Task details + approved plan + architecture design

**Process:**

1. **Prepare context for staff-developer:**
   ```
   Gather for developer:
   - Task acceptance criteria
   - Implementation plan (if reviewed)
   - Architecture design (if exists)
   - Related files from codebase
   - Existing patterns to follow (from CLAUDE.md/AGENTS.md)
   ```

2. **Invoke staff-developer:**
   ```
   Provide comprehensive context:
   
   "Implement task #[number]: [title]
   
   Context:
   - Initiative: #[initiative-number]
   - Acceptance criteria: [list]
   - Architecture: [link to design doc if exists]
   - Implementation approach: [from plan review]
   - Files to modify: [specific paths]
   - Patterns to follow: [from CLAUDE.md]
   
   Requirements:
   - Read CLAUDE.md and AGENTS.md first
   - Follow existing code patterns
   - Consider failure modes proactively
   - Write production-ready code
   - Include tests
   - Add comments only where logic isn't self-evident
   
   Report back with:
   - Summary of changes
   - Any concerns or decisions made
   - Test coverage
   - Files modified"
   ```

3. **Developer implements:**
   - Reads codebase and conventions
   - Follows existing patterns
   - Implements feature
   - Writes tests
   - Reports completion

4. **Capture implementation notes:**
   ```
   Ask developer:
   - What was implemented?
   - Any notable decisions or trade-offs?
   - Any concerns or technical debt introduced?
   - Test coverage achieved?
   ```

**Output:** Implemented code with tests

---

### Phase 6: Code Review

**Goal:** Thorough review of implementation by staff engineer

**Input:** Implemented code from Phase 5

**Process:**

1. **Invoke staff-engineer for code review:**
   ```
   "Review the implementation of task #[number]: [title]
   
   Context:
   - Original plan: [link to plan if reviewed]
   - Architecture design: [link if exists]
   - Acceptance criteria: [list]
   
   Review for:
   - Architecture quality: Clean abstractions, proper boundaries
   - Edge cases: Error handling, validation, boundary conditions
   - Security: Auth, input validation, sensitive data handling
   - Maintainability: Code clarity, testability, documentation
   - Performance: Algorithmic complexity, database queries, caching
   - Standards compliance: Follows project conventions
   - Test coverage: Adequate tests for critical paths
   
   Provide:
   - Critical issues (must fix before merging)
   - Important improvements (should fix)
   - Optional suggestions (nice to have)
   - Positive feedback (what was done well)"
   ```

2. **Handle review feedback:**
   ```
   If critical issues found:
     Present feedback to user
     
     Options:
     A) Have staff-developer fix issues (iterate)
     B) User will fix manually
     C) Acceptable, proceed anyway (only if user overrides)
     
     If A: Loop back to Phase 5 with specific feedback
   
   If only improvements/suggestions:
     Ask user: "Staff engineer found [N] improvement suggestions. 
               Should staff-developer address these before PR?"
     
     If yes: Loop to Phase 5 with feedback
     If no: Proceed to Phase 7
   
   If no issues:
     Proceed to Phase 7
   ```

3. **Approval gate:**
   ```
   Do not proceed to PR creation until:
   - Staff engineer has reviewed code
   - Critical issues resolved
   - User approves proceeding
   ```

**Output:** Reviewed and approved code

---

### Phase 7: PR Creation

**Goal:** Create comprehensive PR with proper description

**Input:** Approved code from Phase 6

**Process:**

1. **Gather PR context:**
   ```
   - Implemented task(s)
   - Related initiative
   - Changes made (git diff)
   - Commit history
   - Implementation notes from developer
   - Review feedback (if any)
   ```

2. **Invoke /pr-author:**
   ```
   /pr-author
   
   Skill will:
   - Analyze git state
   - Fetch related GitHub issues via github-context-agent
   - Ask clarifying questions
   - Generate PR description:
     - Summary
     - Related issues (Closes #[task], Part of #[initiative])
     - Changes (Added/Modified/Removed)
     - Test plan
     - Implementation notes
   ```

3. **Create PR:**
   ```
   - Push branch if needed
   - Create PR with generated description
   - Apply labels (from config)
   - Assign reviewers (from CODEOWNERS)
   - Link to initiative and task
   ```

4. **Report completion:**
   ```
   "✅ Feature implementation complete!
   
   PR: [URL]
   Task: Closes #[number]
   Initiative: Part of #[number]
   
   What was delivered:
   - [Summary of implementation]
   - [Test coverage: X%]
   - [Files changed: N files, +X/-Y lines]
   
   Next steps:
   - Human code review and approval
   - CI/CD pipeline passes
   - Merge to main
   - Deploy to production"
   ```

**Output:** Pull request ready for human review

---

## Configuration

The team respects configuration from `.claude-grimoire/config.json`:

```json
{
  "featureDeliveryTeam": {
    "alwaysCreateInitiative": false,
    "alwaysCreateVisualPRD": false,
    "alwaysInvokeArchitect": false,
    "alwaysReviewPlan": true,
    "skipSimpleTaskReview": true,
    "autoCreatePR": true
  },
  "github": {
    "defaultLabels": ["needs-review"],
    "defaultReviewers": ["team-lead"]
  }
}
```

## Usage Examples

### Example 1: Simple Feature - No Architecture Needed

**User:** "Add dark mode toggle to settings page"

**Team workflow:**
1. **Planning:** Create initiative or use existing issue
2. **Architecture:** Skip (simple UI feature)
3. **Breakdown:** Generate 3 tasks (toggle component, persist preference, apply theme)
4. **Plan review:** Skip (straightforward implementation)
5. **Implementation:** staff-developer builds toggle
6. **Code review:** staff-engineer reviews
7. **PR:** pr-author creates PR

**Timeline:** 1-2 days for implementation, PR ready same day as code complete

---

### Example 2: Complex Feature - Full Workflow

**User:** "Add multi-tenant support to SaaS application"

**Team workflow:**
1. **Planning:** Create initiative with requirements, goals, constraints
2. **Architecture:** 
   - Invoke system-architect-agent
   - Design tenant context, isolation strategy, RLS
   - Create architecture diagrams
   - Optionally create visual PRD
3. **Breakdown:** Generate 8 tasks (foundation, implementation, testing, migration)
4. **Plan review:** 
   - Review migration strategy (critical, complex)
   - Review RLS implementation (security-sensitive)
   - Approve phased rollout plan
5. **Implementation:** 
   - staff-developer implements Task 1 (tenant context)
   - Iterates based on review feedback
6. **Code review:** 
   - staff-engineer reviews for cross-tenant data leaks
   - Validates RLS policies
   - Checks query performance
7. **PR:** pr-author creates PR for Task 1

**Timeline:** 3-4 weeks for full initiative, 1 PR per task

---

### Example 3: Bug Fix - Minimal Workflow

**User:** "Fix memory leak in image processing worker"

**Team workflow:**
1. **Planning:** Use existing bug issue
2. **Architecture:** Skip (bug fix)
3. **Breakdown:** Skip (single task)
4. **Plan review:** Skip (bug fix)
5. **Implementation:** staff-developer fixes leak
6. **Code review:** staff-engineer verifies fix
7. **PR:** pr-author creates PR

**Timeline:** Hours to 1 day, PR ready immediately after fix

---

## Decision Trees

### Should we invoke system-architect-agent?

```
Is this a new feature? → No → Skip
  ↓ Yes
Does it involve 2+ of:
  - New abstraction layers
  - Multiple services
  - Data model changes
  - External integrations
  - Performance concerns
  → No → Skip
  ↓ Yes
Invoke system-architect-agent
```

### Should we review the plan with two-claude-review?

```
Is this a simple bug fix? → Yes → Skip
  ↓ No
Is this documentation only? → Yes → Skip
  ↓ No
Is this an obvious implementation? → Yes → Skip
  ↓ No
Does it involve any of:
  - Database schema changes
  - Security-sensitive code
  - Breaking changes
  - Complex architecture
  → Yes → Review plan
  ↓ No (but still a feature)
Review plan (default for features)
```

### Should we create a visual PRD?

```
Does feature have UI components? → No → Skip
  ↓ Yes
Is it a simple UI change? → Yes → Skip
  ↓ No
Are there multiple user flows? → Yes → Create PRD
  ↓ No
User requested visual PRD? → Yes → Create PRD
  ↓ No
Skip (optional)
```

## Best Practices

### Do:
- ✅ Always validate initiative readiness before proceeding
- ✅ Invoke system-architect-agent for complex features
- ✅ Review plans for features, skip for simple fixes
- ✅ Let staff-engineer review code thoroughly before PR
- ✅ Iterate based on review feedback
- ✅ Provide comprehensive context to each team member
- ✅ Link PRs to tasks and initiatives

### Don't:
- ❌ Skip architecture design for complex features
- ❌ Proceed to PR without code review approval
- ❌ Over-engineer simple features
- ❌ Create PRs without staff-engineer sign-off
- ❌ Skip plan review for security-sensitive changes
- ❌ Ignore review feedback

## Integration with Other Components

### Phase 1 Components
- `pr-author` - Creates final PR description
- `github-context-agent` - Fetches initiative/task context throughout

### Phase 2 Components
- `initiative-creator` - Creates initiative if needed
- `initiative-breakdown` - Breaks initiative into tasks
- `visual-prd` - Creates visual requirements (optional)
- `system-architect-agent` - Designs architecture (optional)

### External Skills
- `staff-developer` - Implements code
- `staff-engineer` - Reviews code
- `two-claude-review` - Reviews implementation plans

## Success Criteria

The team is successful when:
- ✅ Features are fully planned before implementation
- ✅ Complex features have architecture design
- ✅ Implementation follows approved plan
- ✅ Code passes staff-engineer review
- ✅ PRs are comprehensive and well-documented
- ✅ No rework due to architectural issues
- ✅ High code quality and test coverage
- ✅ Minimal back-and-forth on reviews

## Time Savings

**Traditional workflow time:**
- Planning: 2-4 hours
- Architecture (if needed): 4-8 hours
- Implementation: Variable
- Code review cycles: 2-4 hours
- PR description: 15-30 minutes
- **Total overhead:** 8-16 hours per feature

**With feature-delivery-team:**
- Planning: 30 minutes (automated)
- Architecture: 30 minutes (automated, if needed)
- Implementation: Variable (same)
- Code review: 1 hour (automated first pass)
- PR description: 5 minutes (automated)
- **Total overhead:** 2-3 hours per feature

**Savings:** 6-13 hours per feature (60-80% reduction in overhead)