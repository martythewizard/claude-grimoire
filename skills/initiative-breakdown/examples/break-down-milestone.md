# Milestone Breakdown Example

## Input

```bash
/initiative-breakdown 'eci-global/coralogix milestone:"M1: Log Quota Enforcement MVP"'
```

## Process

```
Skill: Fetching milestone via github-context-agent...

✓ Milestone found:
  Repo: eci-global/coralogix
  Milestone: M1: Log Quota Enforcement MVP
  Due: 2026-06-01
  Current issues: 5 (3 open, 2 closed)
  Related initiative: 2026 Q1 - Coralogix Quota Manager

Current tasks:
  #450: Create quota monitoring service
  #451: Implement log ingestion limiter
  #452: Add unit tests
  #453: Document quota service
  #454: Add integration tests

Create additional tasks for M1? (y/n)

User: y

What additional work is needed?

User: Need tasks for error handling and deployment

Creating tasks:
  [M1] Add error handling to quota service → #460
  [M1] Create deployment runbook → #461

✅ Created 2 tasks, assigned to M1
```
