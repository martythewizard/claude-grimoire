# Schema v2 Initiative Skills Update

**Date:** 2026-04-15  
**Status:** Ready for Implementation  
**Skills:** initiative-validator, initiative-discoverer  
**Schema Version:** 2 (eci-global/initiatives)

## Overview

Update initiative-validator and initiative-discoverer to work with the actual schema v2 structure used in eci-global/initiatives. Focus on GitHub Project v2 and workstream-based organization as primary validation/discovery targets, with JIRA and Confluence as optional secondary systems.

## Current State

Both skills were built for a hypothetical schema v1:
- **initiative-validator:** Expects `repos:` array with milestone strings, validates basic GitHub/JIRA/Confluence
- **initiative-discoverer:** Searches JIRA for untracked epics using AI ranking

**Reality:** All 21 initiatives in eci-global/initiatives use schema v2 with:
- `workstreams:` array (not `repos:`)
- `github_project: {org, number, id}` (singular, not array)
- Milestone objects: `{title, number, due, status}`
- JIRA epic tasks with `github_issue` links

## Target State

Skills that validate/discover using the **actual schema v2 structure**:
- **initiative-validator:** Validates workstreams, github_project, milestone objects, JIRA epic tasks
- **initiative-discoverer:** Finds untracked GitHub issues in project, missing from JIRA epic tasks

## Goals

1. **Validate schema v2 structure:** Workstreams, github_project, milestone objects
2. **GitHub Project v2 validation:** Verify project exists and is accessible
3. **Milestone object validation:** Check milestone numbers exist in repos
4. **JIRA epic task validation:** Verify github_issue references are valid
5. **Discovery from GitHub Project:** Find issues in project not tracked in YAML
6. **Optional JIRA/Confluence:** Skip gracefully if not configured

## Non-Goals

- Supporting schema v1 (all initiatives are v2)
- Changing YAML schema structure (work with existing)
- Creating new GitHub Projects (validate existing only)

## Schema v2 Structure

### Complete Example

```yaml
schema_version: 2

name: "2026 Q1 - AI Cost Intelligence Platform"
description: >-
  Always-on agentic AI cost intelligence. Multi-line description
  using YAML folded scalar syntax.
status: active
phase: operational-go-live
owner: tedgar
team:
  - tedgar
  - mhoward

github_project:
  org: eci-global
  number: 14
  id: "PVT_kwDOBgqCFs4BSj3t"  # Optional: GraphQL global ID

progress:
  github_issues: 76/76
  jira_epics: 6/6
  jira_stories: 65/65
  tests: 471/471
  infrastructure: deployed
  data_pipelines: operational
  last_reconciled: "2026-03-23"

workstreams:
  - name: "S3 Unified FOCUS Data Lake"
    repo: eci-global/one-cloud-cloud-costs
    milestones:
      - title: "M0 — S3 Unified FOCUS Data Lake (DataSync)"
        number: 5
        due: "2026-03-31"
        status: deployed
      - title: "M5 — Terraform Infrastructure"
        number: 9
        due: "2026-03-31"
        status: deployed

  - name: "Intelligence System"
    repo: eci-global/one-cloud-cloud-costs
    milestones:
      - title: "M1 — Eyes Open: Automated Detection"
        number: 6
        due: "2026-04-14"
        status: code-complete
      - title: "M2 — Learning Normal: Baseline Intelligence"
        number: 7
        due: "2026-05-09"
        status: code-complete

jira:  # Optional
  project_key: ITPLAT01
  parent_key: ITPMO01-1702
  board_url: "https://jira.company.com/..."
  epics:
    - key: ITPLAT01-2258
      milestone: "M1 — Eyes Open: Automated Detection"
      status: Done
      tasks:
        - key: ITPLAT01-2260
          github_issue: 123
          status: Done
        - key: ITPLAT01-2261
          github_issue: 124
          status: In Progress

confluence:  # Optional
  space_key: CGIP
  page_id: "1879769202"
  page_version: "12"

steward:  # Optional
  enabled: true
  last_run: "2026-04-14T08:00:00Z"

tags:
  - observability
  - ai
  - cost-optimization
  - q1-2026

pulse:  # Optional
  scan_window: 24h
  channels:
    - teams
    - granola
  discussion_category: "Architectural Decisions"
```

### Required Fields (Schema v2)

- `schema_version: 2`
- `name: string`
- `description: string` (prefer `>-` folded scalar for multi-line)
- `status: active | planning | paused | completed | cancelled`
- `owner: string` (GitHub username)

### Optional Fields

- `phase: string` (freeform)
- `team: string[]` (GitHub usernames)
- `github_project: {org, number, id?}`
- `workstreams: WorkstreamObject[]`
- `progress: object` (freeform metrics)
- `jira: JiraObject`
- `confluence: ConfluenceObject`
- `steward: {enabled, last_run?}`
- `tags: string[]`
- `pulse: PulseObject`

### Workstream Object

```yaml
name: string          # Workstream name
repo: string          # owner/repo format
milestones:           # Optional array
  - title: string     # Milestone title (as in GitHub)
    number: integer   # Milestone number (GitHub milestone ID)
    due: string       # ISO 8601 date: YYYY-MM-DD
    status: string    # Freeform: deployed, code-complete, in-progress, etc.
    adrs:             # Optional: ADR references
      - number: integer
        title: string
```

### JIRA Object

```yaml
project_key: string         # Required if jira section present
parent_key: string          # Optional: Parent epic/initiative
board_url: string           # Optional: JIRA board URL
epics:                      # Optional array
  - key: string             # JIRA epic key (PROJ-123)
    milestone: string       # Maps to workstream milestone title
    status: string          # JIRA status
    tasks:                  # Optional: Subtasks/stories
      - key: string         # JIRA task key
        github_issue: integer  # GitHub issue number
        status: string      # JIRA status
```

### GitHub Project Object

```yaml
org: string           # GitHub organization
number: integer       # Project number (as in URL: /orgs/{org}/projects/{number})
id: string            # Optional: GraphQL global ID (PVT_...)
```

## Design Changes

### initiative-validator Changes

**Current workflow:**
1. Parse YAML (expects repos array)
2. Validate GitHub milestones (string titles)
3. Validate JIRA epics
4. Validate Confluence page
5. Generate report

**New workflow:**
1. Parse YAML and detect schema version
2. **Validate schema v2 required fields**
3. **Validate github_project** (if present)
   - GraphQL query: `organization(login: $org) { projectV2(number: $number) { id, title } }`
   - Check project exists and is accessible
4. **Validate workstreams** (if present)
   - For each workstream: check repo exists
   - For each milestone: check milestone number exists in repo
   - Validate milestone objects have required fields (title, number)
5. **Validate JIRA epic tasks** (if jira present)
   - Check epic keys exist
   - Validate github_issue numbers reference real issues in workstream repos
   - Cross-check: do github_issue numbers exist in GitHub?
6. **Validate Confluence** (if present) - OPTIONAL
7. Generate GitHub-first report with workstream organization

**New Report Format:**

```markdown
# Validation Report: 2026-q1-ai-cost-intelligence-platform.yaml

## Summary
- ✅ Schema v2: Valid
- ✅ GitHub Project: Found (eci-global#14)
- ✅ Workstreams: 2/2 validated
- ✅ Milestones: 4/4 found in repos
- ⚠️ JIRA Epic Tasks: 1 issue not found
- ✅ Confluence: Page found

## Critical Issues
None

## Warnings

### GitHub Issue Not Found (JIRA Reference)
- **Epic:** ITPLAT01-2258
- **Task:** ITPLAT01-2260 (github_issue: 999)
- **Repo:** eci-global/one-cloud-cloud-costs
- **Action:** Issue #999 not found. Update JIRA task or create missing issue.

## Info
- Workstream "S3 Data Lake" has 2 milestones (all deployed)
- Workstream "Intelligence System" has 2 milestones (all code-complete)
- 2 JIRA epics tracked with 12 tasks
- GitHub Project #14 has 76 items

## Workstream Details

### S3 Unified FOCUS Data Lake (eci-global/one-cloud-cloud-costs)
- ✅ M0 — S3 Unified FOCUS Data Lake (milestone #5, due 2026-03-31, status: deployed)
- ✅ M5 — Terraform Infrastructure (milestone #9, due 2026-03-31, status: deployed)

### Intelligence System (eci-global/one-cloud-cloud-costs)
- ✅ M1 — Eyes Open (milestone #6, due 2026-04-14, status: code-complete)
- ✅ M2 — Learning Normal (milestone #7, due 2026-05-09, status: code-complete)

## Action Items for Initiative Owner
1. Verify JIRA task ITPLAT01-2260 github_issue reference (issue #999 not found)
2. All other validations passed
```

### initiative-discoverer Changes

**Current workflow:**
1. Extract context from YAML
2. Search JIRA for epics
3. Deduplicate against tracked epics
4. AI rank candidates
5. Generate YAML snippets

**New workflow:**
1. Parse YAML (schema v2)
2. **Extract existing tracking:**
   - github_project items (if present)
   - JIRA epic tasks with github_issue numbers (if present)
   - Workstream milestones
3. **Search GitHub Project for untracked issues** (if github_project exists):
   - Query project items via GraphQL
   - Filter out issues already in JIRA epic tasks
   - Find issues not referenced anywhere in YAML
4. **Search workstream repos for untracked issues:**
   - For each workstream repo, fetch open issues
   - Filter by milestone (match workstream milestones)
   - Find issues not in JIRA epic tasks
   - Find issues not in GitHub Project
5. **Deduplicate candidates**
6. **AI rank candidates** (same logic, GitHub data)
7. Generate suggestions in schema v2 format
8. **Optionally search JIRA** (if jira section exists)

**New Output Format:**

```markdown
# Discovery Results: 2026-q1-ai-cost-intelligence-platform.yaml

Initiative has GitHub Project #14 with 76 items. Found 3 untracked issues.

## High Confidence (8-10)

### #234: Implement cost anomaly alerting
**Repo:** eci-global/one-cloud-cloud-costs  
**Milestone:** M1 — Eyes Open: Automated Detection (#6)  
**Score:** 9/10  
**Reasoning:** In GitHub Project #14, assigned to milestone M1, matches initiative tags (cost-optimization, ai). Not tracked in any JIRA epic task.

**Add to YAML:**
```yaml
jira:
  epics:
    - key: ITPLAT01-2258
      milestone: "M1 — Eyes Open: Automated Detection"
      tasks:
        - key: ITPLAT01-2262  # Create this JIRA task
          github_issue: 234
          status: Backlog
```

### #235: Add Coralogix integration for alerts
**Repo:** eci-global/one-cloud-cloud-costs  
**Milestone:** M2 — Learning Normal (#7)  
**Score:** 8/10  
**Reasoning:** In GitHub Project #14, milestone M2, mentions Coralogix (related system).

**Add to YAML:**
```yaml
jira:
  epics:
    - key: ITPLAT01-2259  # Second epic
      milestone: "M2 — Learning Normal: Baseline Intelligence"
      tasks:
        - key: ITPLAT01-2263  # Create this JIRA task
          github_issue: 235
          status: Backlog
```

## Medium Confidence (5-7)

### #240: Improve data pipeline performance
**Repo:** eci-global/one-cloud-cloud-costs  
**Milestone:** None  
**Score:** 6/10  
**Reasoning:** Open issue in workstream repo, mentions data pipeline (matches workstream "S3 Data Lake"), but no milestone assigned.

**Suggested action:**
1. Assign to milestone (M0 or M5?)
2. Add to GitHub Project #14
3. Create JIRA task if tracking there

---

## Already Tracked

- 12 JIRA epic tasks with github_issue references (all validated)
- GitHub Project #14 has 76 items (73 already tracked)

## JIRA Discovery (Optional)

JIRA discovery is configured. Found 0 additional untracked epics in project ITPLAT01.

## Action Items
1. Review high-confidence GitHub issue suggestions
2. Create corresponding JIRA tasks if tracking there
3. Add github_issue references to existing JIRA epics
4. Re-run /initiative-validator after updating YAML
```

## API Usage

### GitHub Project v2 GraphQL

**Fetch project metadata:**
```graphql
query($org: String!, $number: Int!) {
  organization(login: $org) {
    projectV2(number: $number) {
      id
      title
      url
      closed
      items(first: 100) {
        totalCount
        nodes {
          id
          content {
            ... on Issue {
              number
              title
              state
              repository {
                nameWithOwner
              }
              milestone {
                title
                number
              }
              labels(first: 10) {
                nodes {
                  name
                }
              }
            }
          }
        }
      }
    }
  }
}
```

**Execution:**
```bash
gh api graphql -f query="$QUERY" -f org="eci-global" -F number=14
```

### Milestone Validation (REST)

**Fetch milestone by number:**
```bash
gh api repos/eci-global/one-cloud-cloud-costs/milestones/6 --jq '{title: .title, number: .number, state: .state}'
```

**List all milestones:**
```bash
gh api repos/eci-global/one-cloud-cloud-costs/milestones --jq '.[] | {number, title, state}'
```

### Issue Validation (REST)

**Check github_issue exists:**
```bash
gh api repos/eci-global/one-cloud-cloud-costs/issues/123 --jq '{number: .number, title: .title, state: .state}'
```

### Workstream Repo Validation

**Check repo exists:**
```bash
gh api repos/eci-global/one-cloud-cloud-costs --jq '{name: .name, private: .private}'
```

## Implementation Approach

**Option A: Modify in place** - Update existing skill.md files for schema v2
- Faster, maintains git history
- Version bump to 2.0.0

**Option B: Create v2 files** - New skill files, deprecate old ones
- Cleaner separation
- More files to maintain

**Recommendation:** Option A (modify in place) with clear version bump and changelog

## Testing Strategy

**Test fixtures:**
1. Create `test/initiative-validator/fixtures/schema-v2-valid.yaml`
2. Create `test/initiative-discoverer/fixtures/schema-v2-discoverable.yaml`
3. Use real eci-global/initiatives files as fixtures (anonymize if needed)

**Test scenarios:**
- Schema v2 with github_project validation
- Workstream milestone validation (object format)
- JIRA epic tasks with github_issue validation
- Discovery from GitHub Project items
- Optional JIRA/Confluence (skip gracefully)

**Test data requirements:**
- Real GitHub Project with items
- Real milestones in repos
- Real issues referenced in JIRA tasks
- May require test repo setup in eci-global

## Migration Guide for Users

**For existing skills/teams using these:**
- No API changes - skills accept same input (YAML file path)
- Output format changes - reports now show workstreams instead of repos
- Discovery output suggests JIRA epic task format (not just epic)

**No user action required** - skills automatically detect and validate schema v2

## Success Criteria

- ✅ Validator correctly parses schema v2 YAML
- ✅ GitHub Project validation works (GraphQL)
- ✅ Workstream milestone validation works (object format)
- ✅ JIRA epic task github_issue validation works
- ✅ Discoverer finds untracked issues in GitHub Project
- ✅ Discoverer suggests github_issue additions to JIRA tasks
- ✅ Optional JIRA/Confluence skip gracefully
- ✅ All 21 initiatives in eci-global/initiatives validate successfully
- ✅ Reports organized by workstream (not flat repo list)
- ✅ AI ranking works with GitHub Project data

## Open Questions

1. **Validate github_project.id field?** (GraphQL global ID) - Nice to have, not critical
2. **Handle pagination for projects >100 items?** - Warn if totalCount > 100, suggest manual review
3. **Validate workstream.name uniqueness?** - Yes, warn if duplicate names
4. **Check milestone.due dates for past-due?** - Yes, add Info section noting overdue milestones
5. **Validate JIRA epic.milestone matches workstream milestone titles?** - Yes, warn if mismatch
