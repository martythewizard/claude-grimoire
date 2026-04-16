# Schema v2.1 User Guide: Optional `repo` Field

## Overview

Schema v2.1 adds an optional `repo` field to JIRA task objects for disambiguating GitHub issue numbers in multi-repo initiatives.

## When to Use

**Use explicit `repo` field when:**
- Multiple repos have the same issue number
- Tracking cross-repo dependencies
- Clarity is preferred over inference

**Omit `repo` field when:**
- Single-repo initiative
- Milestone unambiguously maps to one workstream
- Issue numbers are unique across repos

## Syntax

```yaml
jira:
  epics:
    - key: PROJ-101
      milestone: "M1 — Foundation"
      tasks:
        - key: PROJ-201
          github_issue: 1
          repo: owner/repo  # NEW: Optional repo field
          status: In Progress
```

## Inference Behavior

When `repo` is omitted, the validator infers it from:
1. Epic's milestone
2. Workstream containing that milestone
3. That workstream's `repo` field

**Example:**
```yaml
workstreams:
  - name: "Core"
    repo: org/main-repo
    milestones:
      - title: "M1 — Foundation"

jira:
  epics:
    - key: PROJ-101
      milestone: "M1 — Foundation"
      tasks:
        - key: PROJ-201
          github_issue: 5
          # No repo field → infers org/main-repo
```

## Warnings

**Ambiguous Milestone:**
When the same milestone title appears in multiple workstreams:
```
⚠️ Warning: Ambiguous repo for task PROJ-201, milestone 'M1' 
appears in multiple workstreams: org/repo-a, org/repo-b. 
Using org/repo-a but add explicit 'repo' field.
```

**Fix:** Add explicit `repo` field to the task.

**Cross-Repo Tracking:**
When explicit repo doesn't match milestone's workstream:
```
⚠️ Warning: Task PROJ-201 explicitly uses repo 'org/api-repo'
but milestone 'M1' belongs to workstream 'Core' with repo 'org/main-repo'.
Verify this is intentional.
```

This is allowed (for cross-repo dependencies) but validator warns to confirm intent.

## Examples

See test fixtures:
- `test/initiative-validator/fixtures/schema-v2.1-single-repo.yaml`
- `test/initiative-validator/fixtures/schema-v2.1-multi-repo-explicit.yaml`
- `test/initiative-validator/fixtures/schema-v2.1-multi-repo-inferred.yaml`

## Migration from v2.0

No migration required. Schema v2.1 is backward compatible with v2.0:
- Existing YAMLs without `repo` fields work unchanged
- Add `repo` fields only where needed for clarity
