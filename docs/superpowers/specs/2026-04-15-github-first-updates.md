# GitHub-First Updates for Initiative Management Skills

**Date:** 2026-04-15  
**Status:** Ready for Implementation  
**Skills:** initiative-validator, initiative-discoverer

## Overview

Update both initiative management skills to focus on GitHub Projects and GitHub issues as primary validation/discovery targets, with JIRA and Confluence as optional secondary systems. This aligns with the actual workflow at ECI Global where GitHub is the primary tool.

## Current State

Both skills were built with JIRA/Confluence as primary focus:
- **initiative-validator:** Requires JIRA project_key, validates JIRA epics, Confluence pages
- **initiative-discoverer:** Searches JIRA for untracked epics using AI ranking

## Target State

GitHub-first with optional JIRA/Confluence:
- **initiative-validator:** Validates GitHub Projects, issues, milestones; optionally validates JIRA/Confluence if configured
- **initiative-discoverer:** Finds untracked GitHub issues/PRs in Projects; optionally searches JIRA if configured

## Goals

1. **GitHub-first validation:** Focus on GitHub Projects v2, issues, milestones as primary validation targets
2. **Optional JIRA/Confluence:** Make these validations skip gracefully if not configured
3. **GitHub discovery:** Find untracked GitHub issues/PRs that should be linked to initiatives
4. **Maintain backward compatibility:** Existing YAML files with JIRA/Confluence should still work

## Non-Goals

- Removing JIRA/Confluence support entirely (keep as optional)
- Changing YAML schema structure (work with existing schema)
- Adding GitHub authentication complexity (rely on gh CLI)

## YAML Schema Support

Support both GitHub-only and hybrid patterns:

**GitHub-only initiative:**
```yaml
schema_version: 1
name: "Firehydrant Improvements"
description: "Enhance firehydrant management"
status: active
owner: mhoward
repos:
  - name: eci-global/firehydrant
    milestones:
      - "Q1 2026"
      - "Q2 2026"
github:
  projects:
    - number: 25
      title: "AI-First FireHydrant Management"
  issues:
    - 205
    - 202
    - 200
tags:
  - firehydrant
  - automation
```

**Hybrid initiative (GitHub + JIRA):**
```yaml
schema_version: 1
name: "Platform Infrastructure"
description: "Core platform work"
status: active
owner: platform-team
repos:
  - name: eci-global/ember
    milestones:
      - "M6: Data Platform Integration"
github:
  projects:
    - number: 30
  issues:
    - 84
    - 70
jira:  # Optional
  project_key: ITPLAT01
  epics:
    - key: ITPLAT01-2258
confluence:  # Optional
  space_key: PLATFORM
  page_id: "123456789"
```

## Design Changes

### initiative-validator Changes

**Current workflow:**
1. Parse YAML (requires jira.project_key)
2. Validate GitHub milestones
3. Validate JIRA epics (required)
4. Validate Confluence page (required)
5. Generate report

**New workflow:**
1. Parse YAML (no required external fields)
2. **Validate GitHub Projects** (if github.projects exists)
   - Check project exists via `gh api graphql`
   - Verify project is accessible
3. **Validate GitHub issues** (if github.issues exists)
   - Check each issue exists via `gh api repos/{owner}/{repo}/issues/{number}`
   - Verify issues are open/closed appropriately
4. Validate GitHub milestones (existing, works fine)
5. **Validate JIRA epics** (if jira section exists) - OPTIONAL
   - Skip entire JIRA validation if jira.project_key missing
   - Report: "JIRA: Not configured (skipped)"
6. **Validate Confluence page** (if confluence section exists) - OPTIONAL
   - Skip if confluence.page_id missing
   - Report: "Confluence: Not configured (skipped)"
7. Generate report with GitHub as primary section

**New Report Format:**
```markdown
# Validation Report: firehydrant.yaml

## Summary
- ✅ Schema: Valid
- ✅ GitHub Projects: 1/1 found
- ✅ GitHub Issues: 3/3 accessible
- ✅ GitHub Milestones: 2/2 found
- ⚠️ JIRA: Not configured (skipped)
- ⚠️ Confluence: Not configured (skipped)

## Critical Issues
None

## Warnings

### GitHub Issue Not Found
- **Issue:** #999
- **Repo:** eci-global/firehydrant
- **Action:** Verify issue number is correct, or remove from YAML if closed/deleted

## Info
- JIRA validation skipped (no jira.project_key configured)
- Confluence validation skipped (no confluence.page_id configured)
- Consider adding github.projects to track work in GitHub Projects

## Action Items for Initiative Owner
1. Verify GitHub issue #999 exists or remove from YAML
2. All other validations passed
```

### initiative-discoverer Changes

**Current workflow:**
1. Extract context from YAML (requires jira.project_key)
2. Search JIRA for epics with JQL
3. Deduplicate against tracked epics
4. AI rank candidates (JIRA data)
5. Generate YAML snippets for JIRA epics

**New workflow:**
1. Extract context from YAML (no required fields)
2. **Search GitHub for untracked issues/PRs:**
   - For each repo in `repos:`, search issues: `gh api repos/{owner}/{repo}/issues`
   - Filter by labels matching initiative tags
   - Filter by assignees in initiative team
   - Filter by milestone if specified
   - Find issues NOT in `github.issues` list
3. **Search GitHub Projects for untracked items** (if projects configured):
   - Query project items: `gh api graphql` with ProjectV2 query
   - Find items not referenced in YAML
4. Deduplicate against tracked issues
5. **AI rank candidates using GitHub data:**
   - Issue title, body, labels, assignees
   - Score 1-10 based on relevance to initiative
6. Generate YAML snippets for GitHub issues
7. **Optionally search JIRA** (if jira.project_key exists)
   - Run JIRA discovery as secondary
   - Separate section in output

**New Output Format:**
```markdown
# Discovery Results: firehydrant.yaml

Found 4 untracked GitHub issues that may belong to this initiative:

## High Confidence (8-10)

### #210: Automate FireHydrant team rotation
**Score:** 9/10  
**Reasoning:** Issue mentions "FireHydrant" and "automation" (exact tag match), assigned to @mhoward (initiative owner), in repo eci-global/firehydrant  
**Suggested milestone:** "Q2 2026"

**Add to YAML:**
```yaml
github:
  issues:
    - 210
```

### #208: Add Coralogix integration to FH alerts
**Score:** 8/10  
**Reasoning:** Related to FireHydrant, mentions Coralogix (related system), assigned to team member  
**Suggested milestone:** "Q2 2026"

**Add to YAML:**
```yaml
github:
  issues:
    - 208
```

## Medium Confidence (5-7)

### #195: Incident response workflow improvements
**Score:** 6/10  
**Reasoning:** Related to incident management (FireHydrant domain), but no direct FH mention. Reporter is team adjacent.  
**Suggested milestone:** unassigned

**Add to YAML:**
```yaml
github:
  issues:
    - 195
    # milestone: TBD - review and assign
```

---

## JIRA Discovery (Optional)

JIRA discovery skipped (no jira.project_key configured). To enable JIRA discovery, add:
```yaml
jira:
  project_key: YOUR_PROJECT
```

## Action Items
1. Review high-confidence GitHub issue suggestions and add to YAML
2. Verify medium-confidence suggestions with initiative owner
3. Re-run /initiative-validator after updating YAML
```

## API Usage

**New GitHub API calls:**

**Projects v2 (GraphQL):**
```graphql
query($org: String!, $number: Int!) {
  organization(login: $org) {
    projectV2(number: $number) {
      id
      title
      items(first: 100) {
        nodes {
          content {
            ... on Issue {
              number
              title
            }
            ... on PullRequest {
              number
              title
            }
          }
        }
      }
    }
  }
}
```

**Issue validation:**
```bash
gh api repos/{owner}/{repo}/issues/{number}
```

**Issue search for discovery:**
```bash
gh api repos/{owner}/{repo}/issues --jq '.[] | select(.labels[].name | contains("tag")) | {number, title, assignee: .assignee.login}'
```

## Implementation Approach

**Option A: Modify in place** - Update existing skill.md files directly
- Faster, maintains git history
- May confuse users who already read old docs

**Option B: Create v2 files** - New skill files, deprecate old ones
- Cleaner separation
- More files to maintain

**Recommendation:** Option A (modify in place) with clear changelog in skill.md

## Testing Strategy

**Update existing tests:**
1. Update fixtures to use GitHub Projects/issues instead of JIRA
2. Add GitHub Projects validation tests
3. Add GitHub issues validation tests
4. Update example reports to show GitHub-first format
5. Keep JIRA/Confluence tests as optional scenarios

**New test scenarios:**
- GitHub-only YAML (no JIRA/Confluence)
- Hybrid YAML (GitHub + JIRA)
- GitHub Projects v2 validation
- GitHub issue discovery with label filtering

## Migration Guide for Users

**For existing YAML files:**
- No changes required - JIRA/Confluence still work
- Skills will warn if GitHub Projects not configured

**For new YAML files:**
- Use GitHub Projects and issues as primary
- Optionally add JIRA/Confluence if using those systems

**Recommended migration:**
1. Add `github.projects` section to existing YAML
2. Add `github.issues` list for tracked issues
3. Keep `jira` section if using JIRA
4. Re-run validator to confirm

## Success Criteria

- ✅ GitHub Projects validation works
- ✅ GitHub issues validation works
- ✅ JIRA/Confluence validation optional (skips gracefully)
- ✅ GitHub-only YAML validates successfully
- ✅ Hybrid YAML (GitHub + JIRA) validates successfully
- ✅ Discovery finds untracked GitHub issues
- ✅ AI ranking works with GitHub data
- ✅ All existing tests still pass
- ✅ New GitHub-focused tests pass
