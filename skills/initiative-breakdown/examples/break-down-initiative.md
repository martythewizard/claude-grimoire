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

[M3] Extend quota to metrics → #457 (milestone: M3, project: #8)
[M3] Extend quota to traces → #458 (milestone: M3, project: #8)
[M3] Add integration tests → #459 (milestone: M3, project: #8)

[M4] Implement SRE override mechanism → #460 (milestone: M4, project: #8)
[M4] Create Data Spaces migration path → #461 (milestone: M4, project: #8)
[M4] Write migration guide → #462 (milestone: M4, project: #8)

✅ Created 13 tasks across 4 milestones

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
  --body "Foundation task: Build core monitoring service for tracking quota consumption across log streams..." \
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
