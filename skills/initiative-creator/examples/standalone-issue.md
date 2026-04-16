# Standalone Issue Creation Example

## Scenario

User wants to create a quick bug fix issue without any initiative/project context.

## Interactive Flow

```
User: /initiative-creator

Skill: What would you like to create?
A) Standalone issue (no initiative or project)
B) Issue linked to existing initiative or project  
C) New comprehensive initiative with YAML file

User: A

Skill: What's the issue title?

User: Fix authentication timeout error

Skill: Describe the issue:

User: Users are getting logged out after 5 minutes instead of 30 minutes

Skill: Which repository?

User: eci-global/auth-service

Skill: Any labels? (or 'none')

User: bug, high-priority

Skill: Assignee? (or 'none')

User: @security-team

Skill: Creating issue in eci-global/auth-service...

✅ Issue created: https://github.com/eci-global/auth-service/issues/456

Title: Fix authentication timeout error
Labels: bug, high-priority
Assignee: @security-team
Milestone: none

This is a standalone issue (not linked to any initiative or project).

To link it later, run:
  /initiative-creator --issue eci-global/auth-service#456 --project org#14
```

## Non-Interactive Flow

```
User: /initiative-creator --title "Fix auth timeout" --body "Users logged out after 5 min instead of 30" --repo eci-global/auth-service --label bug,high-priority --assignee security-team

Skill: Creating issue...

✅ Issue created: https://github.com/eci-global/auth-service/issues/456
```

## GitHub Command Used

```bash
gh issue create \
  --repo eci-global/auth-service \
  --title "Fix authentication timeout error" \
  --body "Users are getting logged out after 5 minutes instead of 30 minutes" \
  --label bug,high-priority \
  --assignee security-team
```
