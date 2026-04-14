# Initiative Management Skills Design

**Date:** 2026-04-14  
**Status:** Approved for Implementation  
**Skills:** initiative-validator, initiative-discoverer

## Overview

Two complementary skills for managing the ECI Global initiatives registry (https://github.com/eci-global/initiatives). The registry tracks cross-repository work using YAML files that link GitHub milestones, JIRA epics, and Confluence pages. Current pain points: manual validation is time-consuming, and existing JIRA work often goes untracked.

**initiative-validator** validates initiative YAML files end-to-end against GitHub, JIRA, and Confluence, generating reports for initiative owners to fix issues.

**initiative-discoverer** finds existing JIRA epics/issues that should be tracked in an initiative but aren't yet, using AI-driven semantic matching.

## Goals

1. **Reduce validation time:** Automate the manual checking of milestone names, JIRA keys, and Confluence pages (currently hours of work per quarter)
2. **Increase initiative completeness:** Discover orphaned JIRA work that belongs to initiatives but isn't tracked
3. **Provide actionable reports:** Generate clear findings with action items for initiative owners
4. **Safe and non-destructive:** Read-only operations, never auto-fix or auto-update systems
5. **Portable and reusable:** Work globally or as local project copies

## Non-Goals

- Auto-fixing validation issues (humans decide corrections)
- Creating new JIRA epics or GitHub milestones
- Modifying existing YAML files automatically
- Real-time sync between systems (periodic validation is sufficient)
- Replacing the initiatives registry dashboard

## Success Metrics

- **Time savings:** Reduce validation time from 2-3 hours to 5-10 minutes per initiative
- **Coverage improvement:** Increase tracked JIRA epic coverage by 20-30% through discovery
- **Adoption:** 80% of initiative owners use validator before committing YAML changes
- **Error reduction:** 90% fewer invalid YAML merges that break the dashboard

## User Personas

**Primary:** Platform engineers maintaining the initiatives registry
- Need to validate YAML before committing
- Want confidence that dashboard will render correctly
- Responsible for keeping initiatives synced with JIRA/GitHub

**Secondary:** Initiative owners creating new initiatives
- Need to find related JIRA work to link
- Want to ensure their initiative YAML is complete
- May not know all the JIRA epics their team has created

## Architecture

### initiative-validator

**Input:** Path to initiative YAML file  
**Output:** Markdown validation report

**Components:**

1. **YAML Parser**
   - Validates against schema (schema_version: 1)
   - Checks required fields: name, description, status, owner
   - Validates status enum: active, planning, paused, completed, cancelled
   - Validates repo format: org/repo-name
   - Returns structured validation result

2. **GitHub Validator**
   - For each repo in `repos:`, calls `gh api repos/{owner}/{repo}/milestones`
   - Checks if milestone names in YAML exist in GitHub
   - Handles private repos (checks accessibility)
   - Reports: milestone exists, milestone missing, repo inaccessible

3. **JIRA Validator**
   - For each epic in `jira.epics:`, calls JIRA API `/rest/api/3/issue/{key}`
   - Verifies epic key format (PROJECT-123)
   - Checks epic exists and is accessible
   - Reports: epic exists, epic missing, epic inaccessible (permissions)

4. **Confluence Validator**
   - For `confluence.page_id`, calls Confluence API `/rest/api/content/{pageId}`
   - Verifies page exists and is accessible
   - Reports: page exists, page missing, page inaccessible

5. **Report Generator**
   - Aggregates findings from all validators
   - Organizes by severity:
     - **Critical:** Missing required fields, malformed data, blocks dashboard rendering
     - **Warning:** Resources not found (milestones, epics, pages), may indicate stale data
     - **Info:** Suggestions for improvement, optional fields that could add value
   - Outputs markdown with:
     - Summary (pass/fail counts)
     - Findings by severity
     - Action items for initiative owner

**Error Handling:**

- **YAML parse failure:** Stop immediately, report syntax error with line number, exit 1
- **API auth failure:** Skip that validator, report auth issue, continue others, exit 0
- **API rate limit:** Report items skipped due to rate limit, suggest retry time, exit 0
- **Network timeout:** Mark specific checks as "unable to verify", continue others, exit 0
- **Resource not found:** Normal validation finding (not an error), report in warnings, exit 0

**Example Report:**

```markdown
# Validation Report: onecloud.yaml

## Summary
- ✅ Schema: Valid
- ✅ GitHub: 8/8 milestones found
- ⚠️ JIRA: 3/5 epics found (2 missing)
- ✅ Confluence: Page exists

## Critical Issues
None

## Warnings

### JIRA Epic Not Found
- **Epic:** ITPMO01-1234
- **Action:** Verify epic key is correct, or remove from YAML if epic was deleted

### JIRA Epic Not Found
- **Epic:** ITPLAT01-5678
- **Action:** Check if epic moved to different project, update key in YAML

## Info

### Optional Fields
- Consider adding `tags:` for better discoverability
- Consider adding `team:` to track all contributors

## Action Items for Initiative Owner
1. Verify JIRA epic keys ITPMO01-1234 and ITPLAT01-5678
2. Update YAML or confirm epics were intentionally removed
```

---

### initiative-discoverer

**Input:** Path to initiative YAML file  
**Output:** Suggested YAML additions (epics to add)

**Components:**

1. **Context Extractor**
   - Parses YAML to build search context:
     - Description keywords (extract nouns, verbs, tech terms)
     - Team members from `team:` field
     - Repository names from `repos:`
     - Existing epic keys to understand patterns
     - JIRA project key from `jira.project_key`
   - Returns structured context object

2. **JIRA Searcher**
   - Builds smart JQL query using extracted context:
     - `project = {project_key}`
     - `type = Epic`
     - `assignee IN ({team_members}) OR reporter IN ({team_members})`
     - `status != Closed` (focus on active work)
     - `created >= {initiative_start_date}` (if available)
   - Executes query via JIRA API `/rest/api/3/search`
   - Returns list of candidate epics

3. **Deduplication Filter**
   - Removes epics already in YAML `jira.epics:` list
   - Handles partial matches (epic in YAML but assigned to different milestone)
   - Returns only untracked epics

4. **AI Ranker**
   - For each candidate epic, scores relevance (1-10) using Claude:
     - Description similarity to initiative description (keyword overlap, semantic similarity)
     - Team overlap (epic assignee/reporter in initiative team)
     - Temporal relevance (created/updated during initiative timeframe)
     - Repository mentions (epic description mentions initiative repos)
   - Sorts candidates by score (high to low)
   - Returns top N candidates (default: 10)

5. **Suggestion Generator**
   - For each high-scoring candidate, generates YAML snippet:
     ```yaml
     - key: ITPLAT01-2345
       milestone: "Q2 Infrastructure"  # Best guess based on epic labels/components
     ```
   - Includes reasoning for each suggestion:
     - Confidence score
     - Why it matches (team member, keyword overlap, etc.)
     - Suggested milestone (or "unassigned" if unclear)
   - Outputs valid YAML ready to copy into initiative file

**AI Ranking Prompt Template:**

```
You are analyzing whether JIRA epic {epic_key} belongs to initiative "{initiative_name}".

Initiative context:
- Description: {initiative_description}
- Tags: {tags}
- Team: {team_members}
- Repos: {repos}

Epic context:
- Summary: {epic_summary}
- Description: {epic_description}
- Assignee: {assignee}
- Reporter: {reporter}
- Created: {created_date}

Score this epic from 1-10 based on relevance to the initiative:
- 9-10: Definitely belongs, core work
- 7-8: Probably belongs, related work
- 5-6: Maybe belongs, tangential work
- 3-4: Unlikely to belong, weak connection
- 1-2: Definitely doesn't belong, unrelated

Return JSON:
{
  "score": <1-10>,
  "reasoning": "<why this score>",
  "suggested_milestone": "<milestone name or 'unassigned'>"
}
```

**Error Handling:**

- **No JIRA project key in YAML:** Report error, suggest adding `jira.project_key`, exit 1
- **JIRA returns 0 results:** Report "No untracked epics found", exit 0
- **AI ranking fails:** Fall back to heuristic ranking (keyword match count), continue, exit 0
- **Ambiguous matches:** Report "Unable to confidently match candidates", provide best-effort results, exit 0

**Example Output:**

```markdown
# Discovery Results: onecloud.yaml

Found 3 untracked epics that may belong to this initiative:

## High Confidence (8-10)

### ITPLAT01-2345: OneCloud API Gateway Migration
**Score:** 9/10  
**Reasoning:** Epic description mentions "OneCloud platform" (exact match with initiative name), assigned to @jsmith (initiative team member), created during initiative timeframe (2026-Q1)  
**Suggested milestone:** "Q2 Infrastructure"

**Add to YAML:**
```yaml
- key: ITPLAT01-2345
  milestone: "Q2 Infrastructure"
```

## Medium Confidence (5-7)

### ITPLAT01-2401: Service Mesh Integration
**Score:** 6/10  
**Reasoning:** Epic mentions "platform services" (related to initiative tags), assigned to @jdoe (not on initiative team but same org), created during initiative timeframe  
**Suggested milestone:** unassigned (no clear milestone match)

**Add to YAML:**
```yaml
- key: ITPLAT01-2401
  # milestone: TBD - review and assign appropriate milestone
```

## Action Items
1. Review high-confidence suggestions and add to YAML
2. Verify medium-confidence suggestions with initiative owner
3. Re-run validator after updating YAML
```

---

## Data Flow

### initiative-validator Flow

```
User invokes: /initiative-validator initiatives/myproject.yaml
    ↓
YAML Parser: Validate schema, extract references
    ↓
Parallel validation:
    ├─ GitHub Validator: Check milestones exist
    ├─ JIRA Validator: Check epics exist
    └─ Confluence Validator: Check page exists
    ↓
Report Generator: Aggregate findings, organize by severity
    ↓
Output: Markdown report to stdout
```

### initiative-discoverer Flow

```
User invokes: /initiative-discoverer initiatives/myproject.yaml
    ↓
Context Extractor: Parse YAML, extract search context
    ↓
JIRA Searcher: Build JQL query, fetch candidate epics
    ↓
Deduplication Filter: Remove already-tracked epics
    ↓
AI Ranker: Score each candidate (1-10)
    ↓
Suggestion Generator: Generate YAML snippets with reasoning
    ↓
Output: Suggested additions to stdout
```

### Combined Workflow

```
1. /initiative-validator initiatives/myproject.yaml
   → Identifies missing epics, broken references

2. User fixes critical issues in YAML

3. /initiative-discoverer initiatives/myproject.yaml
   → Suggests untracked epics to add

4. User reviews suggestions, adds to YAML

5. /initiative-validator initiatives/myproject.yaml
   → Confirms YAML is complete and valid

6. Commit to git, dashboard updates automatically
```

---

## Implementation Details

### File Structure

```
skills/
├── initiative-validator/
│   ├── skill.md              # Main skill documentation
│   └── examples/
│       ├── valid-report.md   # Example report for valid YAML
│       └── invalid-report.md # Example report with issues
└── initiative-discoverer/
    ├── skill.md              # Main skill documentation
    └── examples/
        └── discovery-results.md # Example discovery output
```

### Dependencies

**Both skills:**
- GitHub CLI (`gh`) with authenticated access
- JIRA REST API access (credentials via environment or config)
- Confluence REST API access (credentials via environment or config)
- YAML parser (built-in or library)

**initiative-discoverer only:**
- Claude API access for AI ranking
- Fallback heuristic ranker (no external dependencies)

### Configuration

**Global config** (`~/.claude-grimoire/config.json`):
```json
{
  "jira": {
    "url": "https://jira.company.com",
    "auth": "env:JIRA_API_TOKEN"
  },
  "confluence": {
    "url": "https://confluence.company.com",
    "auth": "env:CONFLUENCE_API_TOKEN"
  },
  "initiative_discoverer": {
    "max_candidates": 10,
    "min_confidence_score": 5,
    "use_ai_ranking": true
  }
}
```

**Per-project config** (`.claude-grimoire/config.json` - optional):
```json
{
  "initiative_validator": {
    "strict_mode": true,
    "fail_on_warnings": false
  },
  "initiative_discoverer": {
    "jira_projects": ["ITPLAT01", "ITPMO01"],
    "date_range_days": 365
  }
}
```

### API Usage

**GitHub:**
- `gh api repos/{owner}/{repo}/milestones` - List milestones
- Rate limit: 5000 requests/hour (authenticated)

**JIRA:**
- `POST /rest/api/3/search` - JQL search
- `GET /rest/api/3/issue/{key}` - Get issue details
- Rate limit: Varies by instance (typically 100-300 req/min)

**Confluence:**
- `GET /rest/api/content/{pageId}` - Get page by ID
- Rate limit: Varies by instance (typically 100 req/min)

**Claude (initiative-discoverer only):**
- Model: claude-sonnet-4.5
- Tokens per epic: ~500-800 (context + epic + response)
- Cost estimate: $0.003-$0.005 per epic ranked

---

## Testing Strategy

### Test Repository

Create separate test repo: `eci-global/test-initiatives` (or similar)

```
test-initiatives/
├── initiatives/
│   ├── valid-complete.yaml          # Perfect YAML, all resources exist
│   ├── valid-missing-milestone.yaml # Valid YAML, milestone doesn't exist
│   ├── valid-missing-jira.yaml      # Valid YAML, JIRA epic doesn't exist
│   ├── valid-missing-confluence.yaml # Valid YAML, Confluence page missing
│   ├── invalid-schema.yaml          # Missing required fields
│   ├── malformed.yaml               # Invalid YAML syntax
│   └── discoverable.yaml            # Has missing epics discoverer should find
└── README.md                        # Documents test scenarios
```

### Test Data Setup

**GitHub:**
- Create test repo with known milestones: "Q1 Release", "Q2 Release", "Backlog"

**JIRA:**
- Create test project: TEST
- Create tracked epics: TEST-100, TEST-101 (referenced in YAML)
- Create untracked epics: TEST-200, TEST-201 (should be discovered)

**Confluence:**
- Create test space: TEST
- Create test page with known ID: 123456789

### Test Cases

**initiative-validator:**

| Test Case | Input | Expected Output |
|-----------|-------|-----------------|
| Valid complete | valid-complete.yaml | All checks pass, exit 0 |
| Missing milestone | valid-missing-milestone.yaml | Warning: milestone not found, exit 0 |
| Missing JIRA epic | valid-missing-jira.yaml | Warning: epic not found, exit 0 |
| Missing Confluence page | valid-missing-confluence.yaml | Warning: page not found, exit 0 |
| Invalid schema | invalid-schema.yaml | Critical: missing required field 'owner', exit 1 |
| Malformed YAML | malformed.yaml | Critical: YAML parse error at line X, exit 1 |
| API auth failure | valid-complete.yaml (bad JIRA creds) | Warning: JIRA validation skipped, exit 0 |

**initiative-discoverer:**

| Test Case | Input | Expected Output |
|-----------|-------|-----------------|
| Untracked epics exist | discoverable.yaml | Suggests TEST-200, TEST-201 with scores, exit 0 |
| All epics tracked | valid-complete.yaml | "No untracked epics found", exit 0 |
| No JIRA project key | no-jira-key.yaml | Error: add jira.project_key, exit 1 |
| AI ranking fails | discoverable.yaml (no API key) | Falls back to heuristic ranking, exit 0 |

### Integration Testing

1. Run validator against real initiative from `eci-global/initiatives`
2. Run discoverer against same initiative
3. Verify results match manual inspection
4. Test error handling with invalid credentials
5. Test rate limiting with large batch of initiatives

---

## Distribution Model

### Global Installation (Default)

```bash
# Install claude-grimoire plugin
/plugin install claude-grimoire

# Skills available globally
/initiative-validator ~/projects/eci-global/initiatives/initiatives/onecloud.yaml
/initiative-discoverer ~/projects/eci-global/initiatives/initiatives/firehydrant.yaml
```

### Local Copy (Optional Customization)

```bash
# Copy to project for customization
cd ~/projects/eci-global/initiatives
mkdir -p .claude/skills
cp -r ~/.claude/plugins/claude-grimoire/skills/initiative-validator .claude/skills/
cp -r ~/.claude/plugins/claude-grimoire/skills/initiative-discoverer .claude/skills/

# Customize for project-specific needs
# Local version takes precedence over global
```

**Use cases for local copies:**
- Custom validation rules specific to your schema extensions
- Modified JIRA queries for specific project keys
- Tweaked AI prompts for team terminology
- Experimental changes before contributing upstream

---

## Security Considerations

**Authentication:**
- GitHub: Uses `gh` CLI (user's existing auth)
- JIRA: API token via environment variable or config file (never hardcoded)
- Confluence: API token via environment variable or config file
- Claude: API key via environment or grimoire config

**Data Handling:**
- YAML files may contain sensitive initiative names/descriptions
- JIRA epic descriptions may contain confidential information
- Skills never log full YAML or epic contents
- AI ranking prompts include only necessary fields (summary, not full description)

**Permissions:**
- Skills inherit user's permissions (read-only access sufficient)
- No write operations to GitHub/JIRA/Confluence
- No YAML file modifications (output suggestions only)
- Users control when/if suggestions are applied

**Rate Limiting:**
- Respect API rate limits (pause/retry if hit)
- Batch operations to minimize API calls
- Cache results within single validation run (don't re-query same resource)

---

## Future Enhancements

**Phase 2 (not in initial scope):**
- **Batch validation:** `/initiative-validator --all` validates entire directory
- **CI/CD integration:** GitHub Action to validate on PR
- **Auto-suggest milestones:** When discoverer finds epic, suggest which milestone it belongs to
- **Dashboard integration:** Link from dashboard to validation report
- **JIRA sync:** Create missing epics in YAML from JIRA (with confirmation)
- **Confluence sync:** Auto-generate Confluence page from YAML

**Considered but deferred:**
- Auto-fixing YAML (too risky, humans should decide)
- Creating GitHub milestones (out of scope, manual process)
- Real-time monitoring (periodic validation sufficient)
- Slack/email notifications (can wrap skills in scripts)

---

## Success Criteria

**Must have for v1.0:**
- ✅ initiative-validator validates schema, GitHub, JIRA, Confluence
- ✅ initiative-validator generates clear markdown reports
- ✅ initiative-discoverer finds untracked epics using AI ranking
- ✅ initiative-discoverer outputs valid YAML snippets
- ✅ Both skills handle errors gracefully (partial results, no crashes)
- ✅ Both skills work globally and as local copies
- ✅ Documentation includes usage examples and test data
- ✅ Integration tested against real eci-global/initiatives repo

**Nice to have for v1.0:**
- Configuration file support for JIRA/Confluence URLs
- Colorized output for better readability
- JSON output mode for scripting
- Verbose/debug mode for troubleshooting

**Deferred to v1.1+:**
- Batch validation across multiple files
- CI/CD GitHub Action
- Auto-suggest milestones
- Dashboard integration

---

## Open Questions

None - design approved by user 2026-04-14.

---

## References

- **Initiatives Registry:** https://github.com/eci-global/initiatives
- **GitHub Pages Dashboard:** https://legendary-guide-e4r8lmy.pages.github.io/
- **YAML Schema Documentation:** eci-global/initiatives README.md
- **Related Issue:** eci-global/initiatives#15 (Validate end-to-end)
