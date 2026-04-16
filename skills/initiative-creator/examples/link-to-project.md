# Link Issue to Project Example

## Scenario

User has an existing issue that should be added to a GitHub Project board.

## Interactive Flow

```
User: /initiative-creator --issue eci-global/auth-service#456

Skill: Fetching issue eci-global/auth-service#456...

Issue found:
  Title: Fix authentication timeout error
  State: open
  Labels: bug, high-priority
  Assignee: @security-team

Skill: What should this issue be linked to?
A) GitHub Project
B) Initiative YAML
C) Both project and initiative
D) Milestone within repo

User: A

Skill: What's the GitHub Project? (provide org#number or URL)

User: eci-global#8

Skill: Verifying project eci-global#8 exists...

✓ Project found: "2026 Q1 - Coralogix Quota Manager"
  Status: Open
  Items: 45

Skill: Linking issue to project...

✅ Issue linked successfully!

Issue: https://github.com/eci-global/auth-service/issues/456
Project: https://github.com/orgs/eci-global/projects/8

You can view the issue on the project board now.
```

## Non-Interactive Flow

```
User: /initiative-creator --issue eci-global/auth-service#456 --project eci-global#8

Skill: Fetching issue and verifying project...
Skill: Linking issue to project...

✅ Linked eci-global/auth-service#456 to project eci-global#8
```

## GitHub Commands Used

```bash
# Verify project exists (via github-context-agent)
# (agent uses GraphQL internally)

# Link issue to project
gh project item-add 8 \
  --owner eci-global \
  --url https://github.com/eci-global/auth-service/issues/456
```

## Result

Issue #456 now appears in the GitHub Project #8 board.
