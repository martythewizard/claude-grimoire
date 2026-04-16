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
✅ Created 2 tasks, linked to project eci-global#22
```
