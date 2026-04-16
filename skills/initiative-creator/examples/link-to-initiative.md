# Link Issue to Initiative YAML Example

## Scenario

User wants to associate an issue with an initiative YAML file for tracking.

## Interactive Flow

```
User: /initiative-creator --issue eci-global/auth-service#456

Skill: Fetching issue...

Issue found:
  Title: Fix authentication timeout error
  State: open

Skill: What should this issue be linked to?
A) GitHub Project
B) Initiative YAML
C) Both project and initiative
D) Milestone within repo

User: B

Skill: Which initiative? (provide YAML path or search term)

User: coralogix quota

Skill: Searching initiatives for "coralogix quota"...

Found: initiatives/2026-q1-coralogix-quota-manager.yaml
  Name: 2026 Q1 - Coralogix Quota Manager
  Status: active
  Owner: RustyAutopsy

Is this correct? (y/n)

User: y

Skill: Checking if initiative has a GitHub Project...

✓ Initiative references GitHub Project eci-global#8

Would you like to link the issue to the project as well? (y/n)

User: y

Skill: Linking issue to:
  - Initiative YAML (via comment)
  - GitHub Project #8

✅ Issue linked successfully!

Issue: https://github.com/eci-global/auth-service/issues/456
Initiative: initiatives/2026-q1-coralogix-quota-manager.yaml
Project: https://github.com/orgs/eci-global/projects/8

Added comment to issue with initiative reference.
```

## Non-Interactive Flow

```
User: /initiative-creator --issue eci-global/auth-service#456 --initiative initiatives/2026-q1-coralogix-quota-manager.yaml

Skill: Linking issue to initiative...

✅ Linked successfully
  - Comment added to issue referencing initiative
  - Also linked to GitHub Project #8 (from initiative YAML)
```

## GitHub Commands Used

```bash
# Add comment with initiative reference
gh issue comment 456 \
  --repo eci-global/auth-service \
  --body "Part of initiative: [2026 Q1 - Coralogix Quota Manager](https://github.com/eci-global/initiatives/blob/main/initiatives/2026-q1-coralogix-quota-manager.yaml)"

# Link to project (if initiative has github_project)
gh project item-add 8 \
  --owner eci-global \
  --url https://github.com/eci-global/auth-service/issues/456
```
