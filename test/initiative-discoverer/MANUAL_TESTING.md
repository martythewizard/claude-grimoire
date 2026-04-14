# initiative-discoverer Manual Testing Guide

This guide walks through manual testing of the initiative-discoverer skill.

## Prerequisites

1. JIRA API access (set `JIRA_URL` and `JIRA_API_TOKEN`)
2. Claude API key (set `ANTHROPIC_API_KEY`) - optional for AI ranking
3. Test YAML with partially tracked epics

## Test Scenarios

### Scenario 1: Discover Untracked Epics (AI Ranking)

**Setup:**
```bash
export JIRA_URL="https://jira.company.com"
export JIRA_API_TOKEN="your-token"
export ANTHROPIC_API_KEY="your-claude-key"
```

**File:** `test/initiative-discoverer/fixtures/discoverable.yaml`

**Expected Result:**
- ✅ Context extracted: project=TEST, team members, tags
- ✅ JIRA search finds epics in TEST project
- ✅ Deduplication removes TEST-100 (already tracked)
- ✅ AI ranks TEST-200, TEST-201 with scores
- ✅ Output shows high/medium confidence sections
- ✅ YAML snippets generated for untracked epics

**Test Command:**
```bash
/initiative-discoverer test/initiative-discoverer/fixtures/discoverable.yaml
```

**Verify:**
- Report shows discovered epics with reasoning
- Confidence scores (1-10) are present
- YAML snippets are valid and ready to merge

### Scenario 2: Heuristic Fallback (No AI)

**Setup:**
```bash
export JIRA_URL="https://jira.company.com"
export JIRA_API_TOKEN="your-token"
unset ANTHROPIC_API_KEY  # Force heuristic mode
```

**Expected Result:**
- ⚠️ Warning: "Falling back to heuristic ranking"
- ✅ Heuristic scores based on keyword matches
- ✅ Output still generates suggestions
- ✅ Exit code: 0 (degraded but functional)

**Test Command:**
```bash
/initiative-discoverer test/initiative-discoverer/fixtures/discoverable.yaml
```

**Verify:**
- Warning about AI unavailable
- Scores based on keyword matching
- Reasoning says "Heuristic: keyword match count"

### Scenario 3: No Project Key in YAML

**Setup:**
Create YAML without `jira.project_key`:

```yaml
schema_version: 1
name: "No Project Key"
description: "Missing JIRA project key"
status: active
owner: testuser
# Missing jira.project_key
```

**Expected Result:**
- ❌ Error: "Missing jira.project_key in YAML"
- Suggestion to add project_key
- Exit code: 1

**Test Command:**
```bash
/initiative-discoverer test/initiative-discoverer/fixtures/no-project-key.yaml
```

**Verify:**
- Clear error message
- Helpful suggestion to add project_key
- Script exits immediately

### Scenario 4: All Epics Already Tracked

**Setup:**
Create YAML where all JIRA epics are already tracked:

```yaml
schema_version: 1
name: "Complete Tracking"
description: "All work is tracked"
status: active
owner: testuser
jira:
  project_key: TEST
  epics:
    - key: TEST-100
    - key: TEST-200
    - key: TEST-201
```

**Expected Result:**
- ✅ JIRA search finds epics
- ✅ Deduplication removes all candidates
- ✅ Report: "No untracked epics found after deduplication"
- Exit code: 0

**Test Command:**
```bash
/initiative-discoverer test/initiative-discoverer/fixtures/complete-tracking.yaml
```

**Verify:**
- Report confirms initiative is complete
- No suggestions provided
- Positive message about completeness

### Scenario 5: JIRA Authentication Failure

**Setup:**
```bash
export JIRA_URL="https://jira.company.com"
export JIRA_API_TOKEN="invalid-token"
```

**Expected Result:**
- ❌ JIRA API returns authentication error
- Error reported with JIRA response
- Exit code: 1

**Test Command:**
```bash
/initiative-discoverer test/initiative-discoverer/fixtures/discoverable.yaml
```

**Verify:**
- Clear error message about authentication
- JIRA error details shown
- No partial results (fail fast)

### Scenario 6: Real Initiative Discovery

**Setup:**
Use real initiative from `eci-global/initiatives`:

```bash
git clone https://github.com/eci-global/initiatives.git /tmp/test-initiatives
```

**Expected Result:**
- Discovers actual untracked JIRA epics
- AI ranks by real relevance
- Suggestions reflect actual work

**Test Command:**
```bash
/initiative-discoverer /tmp/test-initiatives/initiatives/onecloud.yaml
```

**Verify:**
- Context extraction matches real YAML
- JIRA search finds real epics
- AI reasoning makes sense for real data

## Pass Criteria

All scenarios should:
1. Not crash or throw unhandled errors
2. Generate markdown output with proper structure
3. Return appropriate exit codes (1 for errors, 0 otherwise)
4. Provide actionable YAML snippets
5. Include clear reasoning for each suggestion
6. Fall back gracefully when AI unavailable

## Performance

- Context extraction: < 1 second
- JIRA search: 1-3 seconds (depends on project size)
- AI ranking: 2-5 seconds per epic (batching not implemented)
- Total time for 10 epics: 20-50 seconds

## Known Limitations

- No batch AI ranking (sequential calls, can be slow)
- Heuristic fallback is simple keyword matching
- JQL query limited to 50 results (configurable)
- Team member filtering requires exact usernames
