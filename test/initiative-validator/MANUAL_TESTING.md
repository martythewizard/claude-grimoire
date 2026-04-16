# initiative-validator Manual Testing Guide

This guide walks through manual testing of the initiative-validator skill.

## Prerequisites

1. GitHub CLI (`gh`) authenticated
2. JIRA API access (set `JIRA_URL` and `JIRA_API_TOKEN`)
3. Confluence API access (set `CONFLUENCE_URL` and `CONFLUENCE_API_TOKEN`)
4. Test YAML files in `test/initiative-validator/fixtures/`

## Test Scenarios

### Scenario 1: Valid Complete YAML

**File:** `test/initiative-validator/fixtures/valid-complete.yaml`

**Expected Result:**
- ✅ Schema validation passes
- ✅ GitHub milestones found (if they exist in test repo)
- ✅ JIRA epics accessible (if TEST-100, TEST-101 exist)
- ✅ Confluence page accessible (if page 123456789 exists)
- Report shows all green with no warnings

**Test Command:**
```bash
/initiative-validator test/initiative-validator/fixtures/valid-complete.yaml
```

### Scenario 2: Invalid Schema

**File:** `test/initiative-validator/fixtures/invalid-schema.yaml`

**Expected Result:**
- ❌ Schema validation fails
- Critical errors reported: missing owner, missing description, invalid status
- External validations skipped
- Exit code: 1

**Test Command:**
```bash
/initiative-validator test/initiative-validator/fixtures/invalid-schema.yaml
```

**Verify:**
- Report shows "Critical Issues" section with 3 errors
- External validations (GitHub, JIRA, Confluence) marked as "skipped"

### Scenario 3: Missing GitHub Milestone

**Setup:**
Create test YAML referencing non-existent milestone:

```yaml
schema_version: 1
name: "Test Missing Milestone"
description: "Testing milestone validation"
status: active
owner: testuser
repos:
  - name: eci-global/claude-grimoire
    milestones:
      - "NonExistent Milestone Q99"
```

**Expected Result:**
- ✅ Schema validation passes
- ⚠️ GitHub validation warns: milestone not found
- Report shows warning with actionable fix

**Test Command:**
```bash
/initiative-validator test/initiative-validator/fixtures/missing-milestone.yaml
```

### Scenario 4: API Authentication Failure

**Setup:**
Unset JIRA credentials:

```bash
unset JIRA_API_TOKEN
```

**Expected Result:**
- ✅ Schema validation passes
- ✅ GitHub validation completes
- ⚠️ JIRA validation skipped due to auth failure
- ✅ Confluence validation completes (if creds available)
- Exit code: 0 (partial success)

**Test Command:**
```bash
/initiative-validator test/initiative-validator/fixtures/valid-complete.yaml
```

**Verify:**
- Report shows "Warning: JIRA authentication failed - skipping JIRA validation"
- Other validations still run successfully

### Scenario 5: Real Initiative from eci-global/initiatives

**Setup:**
Clone real initiatives repo:

```bash
git clone https://github.com/eci-global/initiatives.git /tmp/test-initiatives
```

**Expected Result:**
Validates against actual production data, finds real issues if any exist

**Test Command:**
```bash
/initiative-validator /tmp/test-initiatives/initiatives/onecloud.yaml
```

**Verify:**
- Schema passes (production YAML should be valid)
- GitHub/JIRA/Confluence validations report actual state
- Any warnings indicate real stale references

## Pass Criteria

All scenarios should:
1. Not crash or throw unhandled errors
2. Generate markdown reports with correct structure
3. Return appropriate exit codes (1 for critical, 0 otherwise)
4. Handle API failures gracefully (skip and continue)
5. Provide actionable fix instructions in report

## Known Limitations

- Skill assumes `gh` CLI is authenticated (no OAuth flow)
- JIRA/Confluence require manual token setup (no interactive auth)
- Milestone name matching is case-sensitive
- Parallel API calls not implemented (sequential validation)
