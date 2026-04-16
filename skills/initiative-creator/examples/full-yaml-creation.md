# Full Initiative YAML Creation Example

## Scenario

User is starting a large multi-month initiative that needs comprehensive tracking.

## Interactive Flow (Abbreviated)

```
User: /initiative-creator

Skill: What would you like to create?
A) Standalone issue
B) Issue linked to existing initiative or project
C) New comprehensive initiative with YAML file

User: C

Skill: Let's create a comprehensive initiative. I'll ask some questions about scope, goals, and structure.

What problem are you solving?

User: Need to modernize our authentication service to support OAuth2 and SSO

Skill: Who are the primary stakeholders?

User: Security team, all engineering teams using auth

[... more questions about goals, scope, constraints ...]

Skill: Does a GitHub Project already exist for this initiative?
A) Yes (provide project number)
B) No, create one
C) No project needed

User: A

Skill: What's the project number or URL?

User: eci-global#15

Skill: Verifying project exists...
✓ Project found: "2026 Q2 - Auth Service Modernization"

Skill: Does this initiative span multiple repos or have distinct workstreams?

User: Yes, two workstreams

Skill: Name of workstream 1?

User: OAuth2 Implementation

Skill: Which repository?

User: eci-global/auth-service

Skill: Any milestones for this workstream?

User: Yes - "M1 - OAuth2 Core" due 2026-06-01, "M2 - Client Integration" due 2026-07-01

[... gather workstream 2 ...]

Skill: Is this tracked in JIRA?

User: Yes - project ITPLAT01, parent epic ITPMO01-1650

[... gather optional fields ...]

Skill: Generating YAML file...

✓ YAML generated: initiatives/2026-q2-auth-service-modernization.yaml

Skill: Validating YAML structure...
✓ Valid schema v2
✓ All required fields present
✓ Status is valid enum value
✓ Dates are ISO 8601 format

Skill: Committing to eci-global/initiatives...

git clone https://github.com/eci-global/initiatives.git
cp initiatives/2026-q2-auth-service-modernization.yaml initiatives/
git add initiatives/2026-q2-auth-service-modernization.yaml
git commit -m "Add initiative: 2026 Q2 - Auth Service Modernization"
git push origin main

✅ Initiative created successfully!

YAML: https://github.com/eci-global/initiatives/blob/main/initiatives/2026-q2-auth-service-modernization.yaml
Name: 2026 Q2 - Auth Service Modernization
Status: planning
Owner: @security-team
GitHub Project: https://github.com/orgs/eci-global/projects/15
Workstreams: 2 (OAuth2 Implementation, SSO Integration)

What's next?
1. Review the YAML file in eci-global/initiatives
2. Use /initiative-breakdown to create tasks
3. Share with stakeholders for feedback

Would you like me to break this initiative down into tasks now? (y/n)

User: y

Skill: Invoking /initiative-breakdown...
```

## Generated YAML File

```yaml
schema_version: 2
name: 2026 Q2 - Auth Service Modernization
description: >-
  Modernize authentication service to support OAuth2 and SSO across all
  ECI products. Includes OAuth2 core implementation, client SDK updates,
  and SSO provider integrations (Okta, Azure AD).
status: planning
owner: security-team
team:
  - security-lead
  - auth-engineer-1
  - auth-engineer-2

github_project:
  org: eci-global
  number: 15

workstreams:
  - name: OAuth2 Implementation
    repo: eci-global/auth-service
    milestones:
      - title: "M1 — OAuth2 Core"
        number: 10
        due: "2026-06-01"
        status: planning
      - title: "M2 — Client Integration"
        number: 11
        due: "2026-07-01"
        status: planning
  - name: SSO Integration
    repo: eci-global/auth-service
    milestones:
      - title: "M3 — Okta Integration"
        number: 12
        due: "2026-07-15"
        status: planning
      - title: "M4 — Azure AD Integration"
        number: 13
        due: "2026-08-01"
        status: planning

jira:
  project_key: ITPLAT01
  parent_key: ITPMO01-1650

steward:
  enabled: true

tags:
  - auth
  - oauth2
  - sso
  - security
  - q2-2026
```
