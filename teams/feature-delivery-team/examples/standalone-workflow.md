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
