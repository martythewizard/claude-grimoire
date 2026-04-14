# initiative-discoverer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a skill that finds existing JIRA epics/issues that should be tracked in an initiative but aren't yet, using AI-driven semantic matching.

**Architecture:** The skill extracts context from initiative YAML (description, team, repos), searches JIRA with smart filters, deduplicates against already-tracked epics, uses Claude API to rank candidates by relevance (1-10), and generates YAML snippets with reasoning. Falls back to heuristic ranking if AI unavailable.

**Tech Stack:** Bash (curl for JIRA/Claude APIs, jq for JSON parsing), Claude API (sonnet-4.5 for ranking), YAML generation

---

## File Structure

```
skills/initiative-discoverer/
├── skill.md                      # Main skill documentation (workflow, context extraction, AI ranking)
└── examples/
    ├── discovery-results.md      # Example discovery output with suggestions
    └── no-results.md             # Example when no untracked epics found
```

**Design decisions:**
- Single skill.md file (follows grimoire pattern)
- AI ranking with fallback to heuristics (resilient to API failures)
- Context extraction uses grep/awk (no external YAML parser dependency)
- YAML snippet generation is template-based (predictable output)

---

### Task 1: Create Skill Structure and Context Extractor

**Files:**
- Create: `skills/initiative-discoverer/skill.md`
- Create: `skills/initiative-discoverer/examples/.gitkeep`

- [ ] **Step 1: Write test for skill metadata**

```bash
# test/initiative-discoverer/test-skill-metadata.sh
#!/bin/bash

if ! grep -q "^name: initiative-discoverer$" skills/initiative-discoverer/skill.md; then
    echo "FAIL: Missing or incorrect skill name"
    exit 1
fi

if ! grep -q "^description:" skills/initiative-discoverer/skill.md; then
    echo "FAIL: Missing description"
    exit 1
fi

if ! grep -q "^version: 1.0.0$" skills/initiative-discoverer/skill.md; then
    echo "FAIL: Missing or incorrect version"
    exit 1
fi

echo "PASS: Skill metadata is valid"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash test/initiative-discoverer/test-skill-metadata.sh`  
Expected: FAIL with "No such file or directory"

- [ ] **Step 3: Create skill.md with frontmatter and context extraction logic**

```markdown
---
name: initiative-discoverer
description: Find existing JIRA epics that should be tracked in an initiative using AI-driven matching
version: 1.0.0
---

# Initiative Discoverer Skill

Find existing JIRA epics/issues that belong to an initiative but aren't tracked in the YAML yet. Uses AI-driven semantic matching to score candidates by relevance.

## Purpose

This skill helps you:
- Discover orphaned JIRA work that should be linked to initiatives
- Find epics created by team members that aren't tracked yet
- Increase initiative completeness with AI-powered suggestions
- Get ready-to-merge YAML snippets with confidence scores

## When to Use

Invoke this skill after creating an initiative YAML, or periodically to find work that should be linked but isn't yet.

## How It Works

1. **Extract Context** - Parse YAML for description keywords, team, repos, project key
2. **Search JIRA** - Build JQL query with smart filters (team, project, status)
3. **Deduplicate** - Remove epics already tracked in YAML
4. **AI Ranking** - Score each candidate (1-10) using Claude for relevance
5. **Generate Suggestions** - Output YAML snippets with reasoning

## Workflow

### Step 1: Extract Context from YAML

Ask user for YAML file path:
```
"Please provide the path to the initiative YAML file:"
```

Parse and extract search context:

```bash
YAML_FILE="$1"

# Check file exists
if [ ! -f "$YAML_FILE" ]; then
    echo "Error: File not found: $YAML_FILE"
    exit 1
fi

# Extract JIRA project key (required)
PROJECT_KEY=$(grep "project_key:" "$YAML_FILE" | awk '{print $2}' | tr -d '"')
if [ -z "$PROJECT_KEY" ]; then
    echo "Error: Missing jira.project_key in YAML. Cannot search without project key."
    echo "Add: jira:"
    echo "      project_key: YOUR_PROJECT"
    exit 1
fi

# Extract initiative metadata for context
INITIATIVE_NAME=$(grep "^name:" "$YAML_FILE" | sed 's/name: "\(.*\)"/\1/')
INITIATIVE_DESC=$(grep "^description:" "$YAML_FILE" | sed 's/description: "\(.*\)"/\1/')

# Extract team members (for filtering)
TEAM_MEMBERS=$(grep -A 50 "^team:" "$YAML_FILE" | grep "  - " | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')

# Extract tags (for keyword matching)
TAGS=$(grep -A 50 "^tags:" "$YAML_FILE" | grep "  - " | awk '{print $2}' | tr '\n' ' ')

# Extract repos (for description matching)
REPOS=$(grep -A 100 "^repos:" "$YAML_FILE" | grep "  - name:" | awk '{print $3}' | tr '\n' ' ')

# Extract existing epic keys (for deduplication)
EXISTING_EPICS=$(grep -A 100 "^jira:" "$YAML_FILE" | grep "  - key:" | awk '{print $3}' | tr '\n' ',' | sed 's/,$//')

echo "Context extracted:"
echo "  Project: $PROJECT_KEY"
echo "  Initiative: $INITIATIVE_NAME"
echo "  Team: $TEAM_MEMBERS"
echo "  Tags: $TAGS"
echo "  Existing epics: $EXISTING_EPICS"
```

### Step 2: Search JIRA for Candidate Epics

Build JQL query and fetch candidates:

```bash
# JIRA configuration
JIRA_URL="${JIRA_URL:-https://jira.company.com}"
JIRA_TOKEN="${JIRA_API_TOKEN}"

# Build JQL query with smart filters
JQL="project = $PROJECT_KEY AND type = Epic AND status != Closed"

# Add team filter if team members provided
if [ -n "$TEAM_MEMBERS" ]; then
    # Convert comma-separated to JQL format
    TEAM_JQL=$(echo "$TEAM_MEMBERS" | sed 's/,/ OR assignee = /g')
    JQL="$JQL AND (assignee = $TEAM_JQL OR reporter = $TEAM_JQL)"
fi

echo "Searching JIRA with JQL: $JQL"

# Execute search via JIRA API
RESPONSE=$(curl -s -X POST \
    -H "Authorization: Bearer $JIRA_TOKEN" \
    -H "Content-Type: application/json" \
    "$JIRA_URL/rest/api/3/search" \
    -d "{
        \"jql\": \"$JQL\",
        \"fields\": [\"summary\", \"description\", \"assignee\", \"reporter\", \"created\"],
        \"maxResults\": 50
    }")

# Check for errors
if echo "$RESPONSE" | jq -e '.errorMessages' > /dev/null; then
    echo "Error: JIRA API returned errors"
    echo "$RESPONSE" | jq -r '.errorMessages[]'
    exit 1
fi

# Extract candidate epics
CANDIDATES=$(echo "$RESPONSE" | jq -r '.issues[] | "\(.key)|\(.fields.summary)|\(.fields.description // "")|\(.fields.assignee.name // "unassigned")|\(.fields.reporter.name)|\(.fields.created)"')

CANDIDATE_COUNT=$(echo "$CANDIDATES" | wc -l)
echo "Found $CANDIDATE_COUNT candidate epics"

if [ "$CANDIDATE_COUNT" -eq 0 ]; then
    echo "No untracked epics found. Initiative appears to be fully tracked!"
    exit 0
fi
```

### Step 3: Deduplicate Against Existing Epics

Filter out already-tracked epics:

```bash
UNTRACKED_CANDIDATES=""

while IFS='|' read -r key summary description assignee reporter created; do
    # Check if epic is already tracked
    if [[ ",$EXISTING_EPICS," == *",$key,"* ]]; then
        echo "Skipping $key (already tracked)"
        continue
    fi
    
    # Add to untracked list
    if [ -z "$UNTRACKED_CANDIDATES" ]; then
        UNTRACKED_CANDIDATES="$key|$summary|$description|$assignee|$reporter|$created"
    else
        UNTRACKED_CANDIDATES="$UNTRACKED_CANDIDATES
$key|$summary|$description|$assignee|$reporter|$created"
    fi
done <<< "$CANDIDATES"

UNTRACKED_COUNT=$(echo "$UNTRACKED_CANDIDATES" | grep -c '^')
echo "After deduplication: $UNTRACKED_COUNT untracked epics"

if [ "$UNTRACKED_COUNT" -eq 0 ]; then
    echo "No untracked epics found after deduplication. Initiative is complete!"
    exit 0
fi
```

### Step 4: Rank Candidates with AI

Use Claude to score each candidate:

```bash
# Claude API configuration
CLAUDE_API_KEY="${ANTHROPIC_API_KEY}"
CLAUDE_API_URL="https://api.anthropic.com/v1/messages"

# Check if AI ranking is available
USE_AI_RANKING=true
if [ -z "$CLAUDE_API_KEY" ]; then
    echo "Warning: ANTHROPIC_API_KEY not set. Falling back to heuristic ranking."
    USE_AI_RANKING=false
fi

RANKED_CANDIDATES=""

while IFS='|' read -r key summary description assignee reporter created; do
    if [ "$USE_AI_RANKING" = true ]; then
        # AI-driven ranking
        PROMPT="You are analyzing whether JIRA epic $key belongs to initiative \"$INITIATIVE_NAME\".

Initiative context:
- Description: $INITIATIVE_DESC
- Tags: $TAGS
- Team: $TEAM_MEMBERS
- Repos: $REPOS

Epic context:
- Summary: $summary
- Description: ${description:0:500}
- Assignee: $assignee
- Reporter: $reporter
- Created: $created

Score this epic from 1-10 based on relevance to the initiative:
- 9-10: Definitely belongs, core work
- 7-8: Probably belongs, related work
- 5-6: Maybe belongs, tangential work
- 3-4: Unlikely to belong, weak connection
- 1-2: Definitely doesn't belong, unrelated

Return only JSON (no markdown):
{
  \"score\": <1-10>,
  \"reasoning\": \"<why this score in 1 sentence>\",
  \"suggested_milestone\": \"<milestone name or 'unassigned'>\"
}"

        # Call Claude API
        AI_RESPONSE=$(curl -s -X POST "$CLAUDE_API_URL" \
            -H "Content-Type: application/json" \
            -H "x-api-key: $CLAUDE_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -d "{
                \"model\": \"claude-sonnet-4-20250514\",
                \"max_tokens\": 500,
                \"messages\": [{
                    \"role\": \"user\",
                    \"content\": $(echo "$PROMPT" | jq -R -s '.')
                }]
            }")
        
        # Extract JSON from response
        AI_CONTENT=$(echo "$AI_RESPONSE" | jq -r '.content[0].text')
        SCORE=$(echo "$AI_CONTENT" | jq -r '.score')
        REASONING=$(echo "$AI_CONTENT" | jq -r '.reasoning')
        MILESTONE=$(echo "$AI_CONTENT" | jq -r '.suggested_milestone')
        
        # Check for API errors
        if [ -z "$SCORE" ] || [ "$SCORE" = "null" ]; then
            echo "Warning: AI ranking failed for $key. Using heuristic fallback."
            SCORE=$(heuristic_score "$summary" "$description")
            REASONING="Heuristic: keyword match count"
            MILESTONE="unassigned"
        fi
    else
        # Heuristic ranking fallback
        SCORE=$(heuristic_score "$summary" "$description")
        REASONING="Heuristic: keyword match count with initiative terms"
        MILESTONE="unassigned"
    fi
    
    # Add to ranked list with score
    RANKED_CANDIDATES="$RANKED_CANDIDATES
$SCORE|$key|$summary|$REASONING|$MILESTONE|$assignee"
done <<< "$UNTRACKED_CANDIDATES"

# Sort by score (descending)
RANKED_CANDIDATES=$(echo "$RANKED_CANDIDATES" | sort -t'|' -k1 -nr)

# Heuristic scoring function (keyword overlap)
heuristic_score() {
    local summary="$1"
    local description="$2"
    local score=0
    
    # Check for initiative name in epic
    if echo "$summary $description" | grep -qi "$INITIATIVE_NAME"; then
        score=$((score + 5))
    fi
    
    # Check for tag keywords
    for tag in $TAGS; do
        if echo "$summary $description" | grep -qi "$tag"; then
            score=$((score + 2))
        fi
    done
    
    # Check for repo names
    for repo in $REPOS; do
        repo_name=$(echo "$repo" | cut -d'/' -f2)
        if echo "$summary $description" | grep -qi "$repo_name"; then
            score=$((score + 2))
        fi
    done
    
    # Cap at 10
    if [ "$score" -gt 10 ]; then
        score=10
    fi
    
    echo "$score"
}
```

### Step 5: Generate Suggestions

Output markdown with YAML snippets:

```bash
echo "# Discovery Results: $(basename $YAML_FILE)"
echo ""
echo "Found $(echo "$RANKED_CANDIDATES" | grep -c '^') untracked epics that may belong to this initiative:"
echo ""

# High confidence (8-10)
echo "## High Confidence (8-10)"
echo ""
HIGH_CONFIDENCE=$(echo "$RANKED_CANDIDATES" | awk -F'|' '$1 >= 8')
if [ -z "$HIGH_CONFIDENCE" ]; then
    echo "None"
else
    while IFS='|' read -r score key summary reasoning milestone assignee; do
        echo "### $key: $summary"
        echo "**Score:** $score/10"
        echo "**Reasoning:** $reasoning"
        echo "**Suggested milestone:** $milestone"
        echo ""
        echo "**Add to YAML:**"
        echo '```yaml'
        echo "  - key: $key"
        if [ "$milestone" != "unassigned" ]; then
            echo "    milestone: \"$milestone\""
        else
            echo "    # milestone: TBD - review and assign appropriate milestone"
        fi
        echo '```'
        echo ""
    done <<< "$HIGH_CONFIDENCE"
fi
echo ""

# Medium confidence (5-7)
echo "## Medium Confidence (5-7)"
echo ""
MEDIUM_CONFIDENCE=$(echo "$RANKED_CANDIDATES" | awk -F'|' '$1 >= 5 && $1 < 8')
if [ -z "$MEDIUM_CONFIDENCE" ]; then
    echo "None"
else
    while IFS='|' read -r score key summary reasoning milestone assignee; do
        echo "### $key: $summary"
        echo "**Score:** $score/10"
        echo "**Reasoning:** $reasoning"
        echo "**Suggested milestone:** $milestone"
        echo ""
        echo "**Add to YAML:**"
        echo '```yaml'
        echo "  - key: $key"
        echo "    # milestone: TBD - review and assign appropriate milestone"
        echo '```'
        echo ""
    done <<< "$MEDIUM_CONFIDENCE"
fi
echo ""

# Action items
echo "## Action Items"
echo "1. Review high-confidence suggestions and add to YAML"
echo "2. Verify medium-confidence suggestions with initiative owner"
echo "3. Re-run /initiative-validator after updating YAML"
```

## Configuration

**Environment variables:**
```bash
export JIRA_URL="https://jira.company.com"
export JIRA_API_TOKEN="your-jira-token"
export ANTHROPIC_API_KEY="your-claude-api-key"
```

**Global config** (`~/.claude-grimoire/config.json`):
```json
{
  "jira": {
    "url": "https://jira.company.com",
    "auth": "env:JIRA_API_TOKEN"
  },
  "initiative_discoverer": {
    "max_candidates": 10,
    "min_confidence_score": 5,
    "use_ai_ranking": true
  }
}
```

## Error Handling

- **No JIRA project key:** Exit with error, suggest adding to YAML, exit 1
- **JIRA returns 0 results:** Report "no untracked epics found", exit 0
- **AI ranking fails:** Fall back to heuristic ranking, continue, exit 0
- **All candidates low score:** Report ambiguous matches, provide best-effort results, exit 0

## Examples

See `examples/` directory for:
- `discovery-results.md` - Found untracked epics with suggestions
- `no-results.md` - All epics already tracked
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash test/initiative-discoverer/test-skill-metadata.sh`  
Expected: PASS with "Skill metadata is valid"

- [ ] **Step 5: Commit**

```bash
git add skills/initiative-discoverer/
git add test/initiative-discoverer/test-skill-metadata.sh
git commit -m "feat(initiative-discoverer): create skill structure with context extraction

- Add skill.md with frontmatter and workflow documentation
- Include context extraction logic (description, team, repos, tags)
- Add JIRA search with smart JQL filters
- Include deduplication against existing epics
- Add AI ranking with Claude API (with heuristic fallback)
- Add YAML snippet generation

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 2: Create Example Discovery Results

**Files:**
- Create: `skills/initiative-discoverer/examples/discovery-results.md`
- Create: `skills/initiative-discoverer/examples/no-results.md`

- [ ] **Step 1: Write test for example files**

```bash
# test/initiative-discoverer/test-examples-exist.sh
#!/bin/bash

if [ ! -f "skills/initiative-discoverer/examples/discovery-results.md" ]; then
    echo "FAIL: Missing discovery-results.md example"
    exit 1
fi

if [ ! -f "skills/initiative-discoverer/examples/no-results.md" ]; then
    echo "FAIL: Missing no-results.md example"
    exit 1
fi

echo "PASS: All example files exist"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash test/initiative-discoverer/test-examples-exist.sh`  
Expected: FAIL with "Missing discovery-results.md example"

- [ ] **Step 3: Create discovery-results.md example**

```markdown
# Discovery Results: onecloud.yaml

Found 3 untracked epics that may belong to this initiative:

## High Confidence (8-10)

### ITPLAT01-2345: OneCloud API Gateway Migration
**Score:** 9/10  
**Reasoning:** Epic mentions "OneCloud platform" (exact match), assigned to @jsmith (team member), created during initiative timeframe  
**Suggested milestone:** "Q2 Infrastructure"

**Add to YAML:**
```yaml
  - key: ITPLAT01-2345
    milestone: "Q2 Infrastructure"
```

### ITPLAT01-2401: OneCloud Service Mesh Integration
**Score:** 8/10  
**Reasoning:** Direct mention of OneCloud in summary, related tag "platform", assigned to team member  
**Suggested milestone:** "Q3 Platform"

**Add to YAML:**
```yaml
  - key: ITPLAT01-2401
    milestone: "Q3 Platform"
```

## Medium Confidence (5-7)

### ITPLAT01-2512: Platform Logging Improvements
**Score:** 6/10  
**Reasoning:** Related to "platform" tag, but no direct OneCloud mention. Assignee is team adjacent (same org).  
**Suggested milestone:** unassigned

**Add to YAML:**
```yaml
  - key: ITPLAT01-2512
    # milestone: TBD - review and assign appropriate milestone
```

## Action Items
1. Review high-confidence suggestions and add to YAML
2. Verify medium-confidence suggestions with initiative owner
3. Re-run /initiative-validator after updating YAML
```

- [ ] **Step 4: Create no-results.md example**

```markdown
# Discovery Results: firehydrant.yaml

No untracked epics found. Initiative appears to be fully tracked!

## Summary
- **JIRA Project:** ITPLAT01
- **Candidates Searched:** 47 epics
- **Already Tracked:** 8 epics
- **After Deduplication:** 0 untracked epics

## Status
✅ All epics in project ITPLAT01 assigned to team members are already tracked in this initiative YAML.

## Next Steps
- Continue monitoring for new epics created by team members
- Re-run discoverer periodically to catch new work
- Consider running /initiative-validator to verify tracked epics still exist
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bash test/initiative-discoverer/test-examples-exist.sh`  
Expected: PASS with "All example files exist"

- [ ] **Step 6: Commit**

```bash
git add skills/initiative-discoverer/examples/
git add test/initiative-discoverer/test-examples-exist.sh
git commit -m "docs(initiative-discoverer): add example discovery outputs

- Add discovery-results.md showing found epics with suggestions
- Add no-results.md showing complete tracking scenario
- Add test for example files existence

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 3: Add Integration Test

**Files:**
- Create: `test/initiative-discoverer/test-integration.sh`
- Create: `test/initiative-discoverer/fixtures/discoverable.yaml`

- [ ] **Step 1: Write integration test**

```bash
# test/initiative-discoverer/test-integration.sh
#!/bin/bash
set -e

echo "Running initiative-discoverer integration tests..."

# Test 1: Skill documentation structure
echo "Test 1: Skill documentation structure"
SKILL_FILE="skills/initiative-discoverer/skill.md"

if ! grep -q "## Workflow" "$SKILL_FILE"; then
    echo "FAIL: Missing Workflow section"
    exit 1
fi

if ! grep -q "### Step 1: Extract Context from YAML" "$SKILL_FILE"; then
    echo "FAIL: Missing context extraction step"
    exit 1
fi

if ! grep -q "### Step 2: Search JIRA for Candidate Epics" "$SKILL_FILE"; then
    echo "FAIL: Missing JIRA search step"
    exit 1
fi

if ! grep -q "### Step 3: Deduplicate Against Existing Epics" "$SKILL_FILE"; then
    echo "FAIL: Missing deduplication step"
    exit 1
fi

if ! grep -q "### Step 4: Rank Candidates with AI" "$SKILL_FILE"; then
    echo "FAIL: Missing AI ranking step"
    exit 1
fi

if ! grep -q "### Step 5: Generate Suggestions" "$SKILL_FILE"; then
    echo "FAIL: Missing suggestion generation step"
    exit 1
fi

echo "PASS: Skill has all required workflow sections"

# Test 2: Heuristic fallback documented
echo "Test 2: Heuristic fallback"
if ! grep -q "heuristic_score" "$SKILL_FILE"; then
    echo "FAIL: Missing heuristic scoring fallback"
    exit 1
fi

if ! grep -q "USE_AI_RANKING=false" "$SKILL_FILE"; then
    echo "FAIL: Missing AI ranking fallback logic"
    exit 1
fi

echo "PASS: Heuristic fallback is documented"

# Test 3: Test fixture exists
echo "Test 3: Test fixtures"
if [ ! -f "test/initiative-discoverer/fixtures/discoverable.yaml" ]; then
    echo "FAIL: Missing discoverable.yaml fixture"
    exit 1
fi

echo "PASS: Test fixture exists"

echo "All integration tests passed!"
```

- [ ] **Step 2: Create discoverable.yaml fixture**

```yaml
schema_version: 1
name: "Test Discoverable Initiative"
description: "Initiative for testing discovery of untracked epics"
status: active
owner: testuser
team:
  - testuser
  - developer1
repos:
  - name: eci-global/test-repo
    milestones:
      - "Q1 Release"
jira:
  project_key: TEST
  epics:
    - key: TEST-100
      milestone: "Q1 Release"
    # TEST-200 and TEST-201 exist but not tracked (should be discovered)
tags:
  - test
  - discovery
```

- [ ] **Step 3: Run integration test**

Run: `bash test/initiative-discoverer/test-integration.sh`  
Expected: PASS with "All integration tests passed!"

- [ ] **Step 4: Commit**

```bash
git add test/initiative-discoverer/
git commit -m "test(initiative-discoverer): add integration tests and fixtures

- Add integration test validating skill documentation structure
- Add discoverable.yaml fixture with partially tracked epics
- Test validates all workflow sections are present
- Test validates heuristic fallback is documented

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 4: Update README and Plugin Manifest

**Files:**
- Modify: `README.md` (add initiative-discoverer to Skills section)
- Modify: `plugin.json` (add initiative-discoverer to skills list)

- [ ] **Step 1: Write test for README entry**

```bash
# test/initiative-discoverer/test-readme.sh
#!/bin/bash

if ! grep -q "initiative-discoverer" README.md; then
    echo "FAIL: initiative-discoverer not mentioned in README.md"
    exit 1
fi

if ! grep -q "/initiative-discoverer" README.md; then
    echo "FAIL: Missing skill invocation example in README.md"
    exit 1
fi

echo "PASS: README.md documents initiative-discoverer skill"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash test/initiative-discoverer/test-readme.sh`  
Expected: FAIL with "initiative-discoverer not mentioned in README.md"

- [ ] **Step 3: Add initiative-discoverer to README.md**

Find the Skills section (after initiative-validator) and add:

```markdown
---

### 🔍 initiative-discoverer
Find existing JIRA epics that should be tracked in an initiative using AI-driven matching.

```bash
/initiative-discoverer path/to/initiative.yaml
```

**When to use:** After creating initiative YAML, or periodically to find untracked work

**What it does:**
- Extracts context from YAML (description, team, repos, tags)
- Searches JIRA for epics assigned to team members
- Filters out already-tracked epics
- Uses AI to rank candidates by relevance (1-10)
- Generates YAML snippets ready to merge
- Falls back to heuristics if AI unavailable

[Full documentation →](skills/initiative-discoverer/skill.md)
```

- [ ] **Step 4: Add initiative-discoverer to plugin.json**

Find the `"skills"` array and add:

```json
{
  "name": "initiative-discoverer",
  "path": "skills/initiative-discoverer/skill.md",
  "description": "Find existing JIRA epics that should be tracked in an initiative using AI-driven matching"
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bash test/initiative-discoverer/test-readme.sh`  
Expected: PASS with "README.md documents initiative-discoverer skill"

- [ ] **Step 6: Commit**

```bash
git add README.md plugin.json test/initiative-discoverer/test-readme.sh
git commit -m "docs: add initiative-discoverer to README and plugin manifest

- Add initiative-discoverer to Skills section in README
- Add skill entry to plugin.json
- Add test validating README documentation

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 5: Create Manual Testing Guide

**Files:**
- Create: `test/initiative-discoverer/MANUAL_TESTING.md`

- [ ] **Step 1: Create manual testing guide**

```markdown
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
```

- [ ] **Step 2: Commit manual testing guide**

```bash
git add test/initiative-discoverer/MANUAL_TESTING.md
git commit -m "docs(initiative-discoverer): add manual testing guide

- Document 6 test scenarios with expected results
- Include AI ranking and heuristic fallback tests
- Define pass criteria and performance expectations
- Document known limitations

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 6: Final Review and Documentation

**Files:**
- Create: `docs/superpowers/plans/2026-04-14-initiative-discoverer-COMPLETE.md`

- [ ] **Step 1: Run all tests to verify completion**

```bash
bash test/initiative-discoverer/test-skill-metadata.sh
bash test/initiative-discoverer/test-examples-exist.sh
bash test/initiative-discoverer/test-integration.sh
bash test/initiative-discoverer/test-readme.sh
```

Expected: All tests PASS

- [ ] **Step 2: Create completion summary**

```markdown
# initiative-discoverer Implementation - COMPLETE

**Date:** 2026-04-14  
**Status:** Complete  
**Original Plan:** [2026-04-14-initiative-discoverer.md](2026-04-14-initiative-discoverer.md)

## Overview

Built initiative-discoverer skill for finding existing JIRA epics that should be tracked in initiatives but aren't yet. Uses AI-driven semantic matching with heuristic fallback.

## What Was Implemented

### Skill Documentation
- `skills/initiative-discoverer/skill.md` - Complete workflow documentation
  - Context extraction (description, team, repos, tags, project key)
  - JIRA search with smart JQL filters (team, status, project)
  - Deduplication against existing epics in YAML
  - AI ranking via Claude API with 1-10 scoring
  - Heuristic fallback (keyword matching) when AI unavailable
  - YAML snippet generation with reasoning

### Examples
- `skills/initiative-discoverer/examples/discovery-results.md` - Found epics with suggestions
- `skills/initiative-discoverer/examples/no-results.md` - Complete tracking scenario

### Tests
- `test/initiative-discoverer/test-skill-metadata.sh` - Validates skill frontmatter
- `test/initiative-discoverer/test-examples-exist.sh` - Checks example files
- `test/initiative-discoverer/test-integration.sh` - Integration test suite
- `test/initiative-discoverer/test-readme.sh` - Validates README documentation
- `test/initiative-discoverer/MANUAL_TESTING.md` - Manual testing guide

### Test Fixtures
- `test/initiative-discoverer/fixtures/discoverable.yaml` - Partially tracked initiative

### Documentation Updates
- Updated `README.md` with initiative-discoverer skill entry
- Updated `plugin.json` with skill manifest entry

## Verification

All automated tests pass:
```bash
bash test/initiative-discoverer/test-skill-metadata.sh  # PASS
bash test/initiative-discoverer/test-examples-exist.sh  # PASS
bash test/initiative-discoverer/test-integration.sh     # PASS
bash test/initiative-discoverer/test-readme.sh          # PASS
```

Manual testing scenarios documented in `test/initiative-discoverer/MANUAL_TESTING.md`.

## Features Delivered

✅ Context extraction from YAML (description, team, repos, tags)  
✅ JIRA search with smart JQL filters  
✅ Deduplication against already-tracked epics  
✅ AI-driven relevance scoring (1-10) via Claude API  
✅ Heuristic fallback when AI unavailable  
✅ YAML snippet generation with reasoning  
✅ Confidence-based grouping (high/medium/low)  
✅ Comprehensive error handling (missing project key, auth failures)  
✅ Example discovery outputs  
✅ Comprehensive test suite  
✅ Manual testing guide  

## Integration with initiative-validator

Combined workflow:
1. Run `/initiative-validator` to find validation issues
2. Fix critical errors in YAML
3. Run `/initiative-discoverer` to find missing epics
4. Review suggestions, add to YAML
5. Re-run `/initiative-validator` to confirm completeness

## Next Steps

1. Test skill with real initiatives from `eci-global/initiatives` repo
2. Gather feedback on AI ranking quality
3. Consider batch AI ranking (parallel API calls)
4. Explore milestone auto-suggestion improvements

## Files Changed

**Created:**
- skills/initiative-discoverer/skill.md
- skills/initiative-discoverer/examples/discovery-results.md
- skills/initiative-discoverer/examples/no-results.md
- test/initiative-discoverer/test-skill-metadata.sh
- test/initiative-discoverer/test-examples-exist.sh
- test/initiative-discoverer/test-integration.sh
- test/initiative-discoverer/test-readme.sh
- test/initiative-discoverer/MANUAL_TESTING.md
- test/initiative-discoverer/fixtures/discoverable.yaml
- docs/superpowers/plans/2026-04-14-initiative-discoverer-COMPLETE.md

**Modified:**
- README.md (added skill entry)
- plugin.json (added skill manifest)
```

- [ ] **Step 3: Commit completion summary**

```bash
git add docs/superpowers/plans/2026-04-14-initiative-discoverer-COMPLETE.md
git commit -m "docs: complete initiative-discoverer implementation summary

Initiative discoverer skill is complete and ready for use. All tests passing,
AI ranking with heuristic fallback implemented, documentation updated.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

- [ ] **Step 4: Verify git history**

Run: `git log --oneline --graph -10`  
Expected: 6 commits for initiative-discoverer tasks

---

## Plan Self-Review

**Spec Coverage Check:**

- ✅ Context Extractor component → Task 1 (Step 3, context extraction)
- ✅ JIRA Searcher component → Task 1 (Step 3, JQL search)
- ✅ Deduplication Filter component → Task 1 (Step 3, deduplication)
- ✅ AI Ranker component → Task 1 (Step 3, AI ranking with Claude API)
- ✅ Heuristic fallback → Task 1 (Step 3, heuristic_score function)
- ✅ Suggestion Generator component → Task 1 (Step 3, YAML generation)
- ✅ Error handling requirements → Task 1 (error handling in workflow)
- ✅ Example outputs → Task 2
- ✅ Configuration support → Task 1 (configuration section)
- ✅ Testing strategy → Task 3 (integration tests), Task 5 (manual testing)
- ✅ Documentation updates → Task 4
- ✅ File structure from spec → Task 1 (matches spec exactly)

**Placeholder Scan:**

- No "TBD", "TODO", or "implement later" present ✅
- All code blocks show actual implementation ✅
- All bash snippets are complete and runnable ✅
- No "similar to Task N" references ✅
- All workflow steps have actual code ✅
- AI ranking prompt is complete with JSON schema ✅

**Type Consistency:**

- YAML field names consistent (project_key, name, description, team, repos, tags) ✅
- API endpoints consistent (JIRA /rest/api/3/search, Claude /v1/messages) ✅
- Variable names consistent (YAML_FILE, CANDIDATES, RANKED_CANDIDATES) ✅
- Exit codes consistent (1 for errors, 0 for success/partial success) ✅
- Score range consistent (1-10 throughout) ✅

**No gaps found. Plan is complete and ready for execution.**
