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
