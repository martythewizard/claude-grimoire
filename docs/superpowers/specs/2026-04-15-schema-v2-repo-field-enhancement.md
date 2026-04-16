# Schema v2: Optional `repo` Field for JIRA Tasks

**Date:** 2026-04-15  
**Status:** Approved for Implementation  
**Schema Version:** 2.1 (backward compatible with 2.0)

## Overview

Add optional `repo` field to JIRA task structure in schema v2 to disambiguate GitHub issue numbers in multi-repo initiatives. Uses milestone-based inference when field is omitted, ensuring backward compatibility with existing schema v2 YAMLs.

## Problem Statement

**Current Issue**: Multi-repo initiatives cannot distinguish which repository a `github_issue` belongs to when the same issue number exists in multiple repos.

**Example**:
```yaml
workstreams:
  - name: "Core"
    repo: martythewizard/initiatives-test
  - name: "API"
    repo: martythewizard/initiatives-test-api

jira:
  epics:
    - key: TEST-101
      milestone: "M1 — Foundation"
      tasks:
        - key: TEST-201
          github_issue: 1  # Which repo? initiatives-test#1 or initiatives-test-api#1?
```

**Impact**: 
- initiative-validator cannot validate correct issue
- initiative-discoverer produces incorrect deduplication
- Users rely on comments to track repo (error-prone)

## Goals

1. **Disambiguate issue numbers** across multiple repos
2. **Maintain backward compatibility** with existing schema v2 YAMLs
3. **Minimize verbosity** through smart inference
4. **Warn on ambiguity** to guide users toward explicit tracking
5. **Support cross-repo tracking** (issue from repo not in milestone's workstream)

## Non-Goals

- Adding `repo` field to other parts of schema (only JIRA tasks)
- Breaking changes to schema v2
- Automatic migration of existing YAMLs (manual opt-in)
- Inferring repo from issue labels, assignees, or other heuristics

## Schema Changes

### JIRA Task Object (Updated)

**Before (Schema v2.0)**:
```yaml
tasks:
  - key: string         # JIRA task key
    github_issue: integer  # GitHub issue number
    status: string      # JIRA status
```

**After (Schema v2.1)**:
```yaml
tasks:
  - key: string         # JIRA task key
    github_issue: integer  # GitHub issue number
    status: string      # JIRA status
    repo: string        # NEW: Optional owner/repo format
```

### Field Specification

| Field | Type | Required | Format | Description |
|-------|------|----------|--------|-------------|
| `repo` | string | No | `owner/repo` | Explicitly specify which repository the `github_issue` belongs to |

**Format**: Must match `owner/repo` pattern (e.g., `martythewizard/initiatives-test`)
- Matches workstream `repo:` field format for consistency
- Allows tracking issues from repos not listed in workstreams

**When to use**:
- Multi-repo initiatives with potential issue number collisions
- Cross-repo tracking (issue from different repo than milestone's workstream)
- Explicit disambiguation preferred over inference

**When to omit**:
- Single-repo initiatives (inference always succeeds)
- Multi-repo with unique issue numbers (no collision)
- Milestone clearly maps to single workstream

## Inference Logic

### Repository Resolution Algorithm

When validating or discovering issues, resolve the repo using this precedence:

**1. Explicit `repo` field** (highest priority)
```yaml
- key: TEST-201
  github_issue: 1
  repo: martythewizard/initiatives-test  # Use this directly
```
→ Use the explicit `repo` value, no inference needed.

**2. Milestone-based inference** (fallback when `repo` omitted)
```yaml
- key: TEST-202
  github_issue: 5  # No repo specified

# Epic has: milestone: "M1 — Foundation Setup"
# Find workstream with milestone titled "M1 — Foundation Setup"
# Use that workstream's repo field
```
→ Lookup milestone title in workstreams, use matching workstream's `repo`.

**3. Ambiguity handling**
- **No matching milestone**: Warn "Cannot infer repo for task TEST-202, milestone 'M1' not found in workstreams"
- **Multiple workstreams match**: Warn "Ambiguous repo for task TEST-202, milestone 'M1' appears in multiple workstreams. Add explicit 'repo' field."
- **No workstreams defined**: Error "Cannot infer repo for task TEST-202, no workstreams defined in initiative"

### Resolution Pseudocode

```python
def resolve_repo(task, epic, workstreams):
    """
    Resolve which repository a JIRA task's github_issue belongs to.
    
    Returns:
        (repo: str | None, warnings: list[str])
    """
    warnings = []
    
    # Step 1: Check explicit repo field
    if 'repo' in task:
        return (task['repo'], warnings)
    
    # Step 2: Infer from milestone
    milestone_title = epic['milestone']
    
    if not workstreams:
        warnings.append(
            f"Error: Cannot infer repo for task {task['key']}, "
            f"no workstreams defined"
        )
        return (None, warnings)
    
    # Find workstreams with matching milestone
    matching_workstreams = []
    for ws in workstreams:
        for milestone in ws.get('milestones', []):
            if milestone['title'] == milestone_title:
                matching_workstreams.append(ws)
                break  # Only match each workstream once
    
    # Step 3: Handle results
    if len(matching_workstreams) == 0:
        warnings.append(
            f"Warning: Cannot infer repo for task {task['key']}, "
            f"milestone '{milestone_title}' not found in workstreams. "
            f"Add explicit 'repo' field."
        )
        return (None, warnings)
    
    if len(matching_workstreams) == 1:
        return (matching_workstreams[0]['repo'], warnings)
    
    # Multiple matches - ambiguous
    repos = [ws['repo'] for ws in matching_workstreams]
    warnings.append(
        f"Warning: Ambiguous repo for task {task['key']}, "
        f"milestone '{milestone_title}' appears in multiple workstreams: "
        f"{', '.join(repos)}. Using {repos[0]} but add explicit 'repo' field."
    )
    return (matching_workstreams[0]['repo'], warnings)
```

## Validation Behavior

### Cross-Repo Mismatch Detection

When a task has **explicit `repo`** that doesn't match the milestone's workstream repo:

```yaml
workstreams:
  - name: "Core"
    repo: martythewizard/initiatives-test
    milestones:
      - title: "M1 — Foundation Setup"

jira:
  epics:
    - key: TEST-101
      milestone: "M1 — Foundation Setup"  # Points to initiatives-test
      tasks:
        - key: TEST-201
          github_issue: 5
          repo: martythewizard/initiatives-test-api  # Different repo!
```

**Validator behavior**: **Warn** (not error)

**Rationale**: 
- May be intentional cross-repo tracking
- Issue could belong to API workstream but tracked under Core milestone
- Better to warn and let user decide than block valid configurations

**Warning message**:
```
Warning: Task TEST-201 explicitly uses repo 'martythewizard/initiatives-test-api'
but milestone 'M1 — Foundation Setup' belongs to workstream 'Core' with repo
'martythewizard/initiatives-test'. Verify this is intentional.
```

### Issue Number Validation

For each JIRA task, validator:
1. Resolves repo using algorithm above
2. Checks if `github_issue` exists in resolved repo: `GET /repos/{repo}/issues/{number}`
3. Reports if issue not found or repo resolution failed

**New validation output**:
```
✅ Issue #1 (martythewizard/initiatives-test): Setup project structure
✅ Issue #1 (martythewizard/initiatives-test-api): Create REST API endpoints
❌ Issue #999 (martythewizard/initiatives-test): NOT FOUND
⚠️  Issue #5 (repo: unknown): Cannot infer repo, milestone 'M99' not found
```

## Skill Changes

### initiative-validator Updates

**Step 6: Validate JIRA Epic Tasks** (enhanced)

Current implementation validates `github_issue` but doesn't track which repo.

**Changes needed**:
1. Add `resolve_repo()` function using pseudocode above
2. For each JIRA task:
   - Call `resolve_repo(task, epic, workstreams)`
   - Collect and display warnings
   - If repo resolved, validate issue exists in that repo
   - Report with format: `Issue #{num} ({repo}): {title}`
3. Add cross-repo mismatch detection
4. Update report format to show repo per issue

**New report section**:
```markdown
## JIRA Epic Tasks

### Epic TEST-101: M1 — Foundation Setup
- ✅ Issue #1 (martythewizard/initiatives-test): Setup project structure
- ✅ Issue #6 (martythewizard/initiatives-test): Add authentication layer

### Epic TEST-105: M2 — Feature Development  
- ✅ Issue #1 (martythewizard/initiatives-test-api): Create REST API endpoints
- ⚠️  Cross-repo tracking: Task in initiatives-test-api but milestone in Core workstream

## Warnings
- Cross-repo mismatch for task TEST-208 (see details above)
```

### initiative-discoverer Updates

**Step 4: Deduplication** (enhanced)

Current implementation extracts `github_issue` numbers but doesn't track repo.

**Changes needed**:
1. When extracting tracked issues, also resolve repo for each
2. Store as `repo|issue_num` pairs for deduplication (e.g., `"martythewizard/initiatives-test|1"`)
3. When checking candidates, format as `repo|num` and compare
4. Report untracked issues with repo: `Issue #1 (martythewizard/initiatives-test-api): Untracked`

**Deduplication logic**:
```python
# Extract tracked issues with repos
tracked = []
for epic in jira['epics']:
    for task in epic.get('tasks', []):
        repo, warnings = resolve_repo(task, epic, workstreams)
        if repo:
            tracked.append(f"{repo}|{task['github_issue']}")

# Check candidates
for candidate in project_candidates:
    candidate_key = f"{candidate['repo']}|{candidate['number']}"
    if candidate_key not in tracked:
        # Untracked - report it
```

## Migration Guide

### For Existing Schema v2 Initiatives

**No action required** if:
- Initiative tracks single repo
- No issue number collisions across repos
- Milestone inference is unambiguous

**Recommended updates** if:
- Multiple workstream repos exist
- Same issue numbers used in different repos
- Validator warnings about ambiguous repo inference

### Migration Example

**Before (schema v2.0)**:
```yaml
workstreams:
  - name: "Core"
    repo: martythewizard/initiatives-test
  - name: "API"  
    repo: martythewizard/initiatives-test-api

jira:
  epics:
    - key: TEST-101
      milestone: "M1 — Foundation"
      tasks:
        - key: TEST-201
          github_issue: 1  # Ambiguous!
          status: In Progress
```

**After (schema v2.1)**:
```yaml
jira:
  epics:
    - key: TEST-101
      milestone: "M1 — Foundation"
      tasks:
        - key: TEST-201
          github_issue: 1
          repo: martythewizard/initiatives-test  # Explicit
          status: In Progress
```

## Examples

### Example 1: Single Repo (No Change Needed)

```yaml
schema_version: 2

workstreams:
  - name: "Core"
    repo: martythewizard/initiatives-test
    milestones:
      - title: "M1 — Foundation"
        number: 1

jira:
  epics:
    - key: TEST-101
      milestone: "M1 — Foundation"
      tasks:
        - key: TEST-201
          github_issue: 1  # Inference works: only one repo
          status: Done
```

**Resolution**: `github_issue: 1` → `martythewizard/initiatives-test#1` (inferred)

### Example 2: Multi-Repo with Explicit Fields

```yaml
schema_version: 2

workstreams:
  - name: "Core"
    repo: martythewizard/initiatives-test
    milestones:
      - title: "M1 — Foundation"
  
  - name: "API"
    repo: martythewizard/initiatives-test-api
    milestones:
      - title: "M2 — API Development"

jira:
  epics:
    - key: TEST-101
      milestone: "M1 — Foundation"
      tasks:
        - key: TEST-201
          github_issue: 1
          repo: martythewizard/initiatives-test  # Explicit
        
        - key: TEST-202
          github_issue: 5
          # No repo → inferred from M1 milestone → initiatives-test
    
    - key: TEST-102
      milestone: "M2 — API Development"
      tasks:
        - key: TEST-203
          github_issue: 1
          repo: martythewizard/initiatives-test-api  # Explicit (same issue #!)
```

**Resolution**:
- TEST-201: `github_issue: 1` → `martythewizard/initiatives-test#1` (explicit)
- TEST-202: `github_issue: 5` → `martythewizard/initiatives-test#5` (inferred)
- TEST-203: `github_issue: 1` → `martythewizard/initiatives-test-api#1` (explicit)

### Example 3: Cross-Repo Tracking (with Warning)

```yaml
workstreams:
  - name: "Core"
    repo: martythewizard/initiatives-test
    milestones:
      - title: "M1 — Foundation"

jira:
  epics:
    - key: TEST-101
      milestone: "M1 — Foundation"
      tasks:
        - key: TEST-201
          github_issue: 10
          repo: martythewizard/initiatives-test-api  # Cross-repo!
```

**Validator output**:
```
✅ Issue #10 (martythewizard/initiatives-test-api): Add API authentication

⚠️  Warning: Task TEST-201 explicitly uses repo 'martythewizard/initiatives-test-api'
but milestone 'M1 — Foundation' belongs to workstream 'Core' with repo
'martythewizard/initiatives-test'. Verify this is intentional.
```

### Example 4: Ambiguous Milestone (Multiple Workstreams)

```yaml
workstreams:
  - name: "Core"
    repo: martythewizard/initiatives-test
    milestones:
      - title: "M2 — Feature Development"  # Same title!
  
  - name: "API"
    repo: martythewizard/initiatives-test-api
    milestones:
      - title: "M2 — Feature Development"  # Same title!

jira:
  epics:
    - key: TEST-102
      milestone: "M2 — Feature Development"
      tasks:
        - key: TEST-205
          github_issue: 8  # Which repo???
```

**Validator output**:
```
⚠️  Warning: Ambiguous repo for task TEST-205, milestone 'M2 — Feature Development'
appears in multiple workstreams: martythewizard/initiatives-test,
martythewizard/initiatives-test-api. Using martythewizard/initiatives-test
but add explicit 'repo' field.

✅ Issue #8 (martythewizard/initiatives-test): Add unit tests for core
```

**Fix**: Add explicit `repo` field:
```yaml
- key: TEST-205
  github_issue: 8
  repo: martythewizard/initiatives-test-api  # Explicit
```

## Testing Strategy

### Test Fixtures

Create test YAMLs in `test/initiative-validator/fixtures/`:

1. **`schema-v2.1-single-repo.yaml`**: Single repo, no `repo` fields (baseline)
2. **`schema-v2.1-multi-repo-explicit.yaml`**: Multi-repo, all tasks have explicit `repo`
3. **`schema-v2.1-multi-repo-inferred.yaml`**: Multi-repo, mixed explicit/inferred
4. **`schema-v2.1-issue-collision.yaml`**: Same issue number in different repos
5. **`schema-v2.1-ambiguous-milestone.yaml`**: Milestone appears in multiple workstreams
6. **`schema-v2.1-cross-repo.yaml`**: Task repo doesn't match milestone's workstream

### Test Scenarios

**For initiative-validator**:
1. Single repo, no `repo` fields → infers correctly
2. Multi-repo, explicit `repo` → validates correct repo
3. Multi-repo, inferred `repo` → uses milestone mapping
4. Issue number collision → both issues validated separately
5. Ambiguous milestone → warns, uses first match
6. Cross-repo tracking → warns, validates explicit repo
7. Missing milestone → warns, cannot infer
8. Invalid repo format → error on malformed `owner/repo`

**For initiative-discoverer**:
1. Single repo → deduplication works unchanged
2. Multi-repo, tracked issues have repos → dedup by `repo|num`
3. Issue collision → correctly deduplicates per-repo
4. Discovery output → shows repo for each untracked issue

### Integration Test

Use `initiatives-test` repository (already has multi-repo setup):
1. Update YAML with explicit `repo` fields
2. Run validator → verify all issues resolve correctly
3. Run discoverer → verify deduplication handles collision
4. Introduce ambiguous milestone → verify warning appears

## Success Criteria

- ✅ Schema v2.1 backward compatible with v2.0 (no breaking changes)
- ✅ Inference works for single-repo initiatives (no warnings)
- ✅ Inference works for multi-repo when milestone is unambiguous
- ✅ Warnings appear when inference is ambiguous
- ✅ Issue number collision resolved with explicit `repo` fields
- ✅ Validator validates issues in correct repo
- ✅ Discoverer deduplicates per-repo (not just by issue number)
- ✅ Cross-repo tracking allowed with warning
- ✅ All test scenarios pass
- ✅ Real `initiatives-test` YAML validates successfully with enhancements

## Open Questions

None - design approved by user.

## References

- Original spec: `docs/superpowers/specs/2026-04-15-schema-v2-initiative-skills.md`
- Test scenarios: `https://github.com/martythewizard/initiatives-test/blob/main/TEST_SCENARIOS.md`
- issue-validator skill: `skills/initiative-validator/skill.md`
- initiative-discoverer skill: `skills/initiative-discoverer/skill.md`
