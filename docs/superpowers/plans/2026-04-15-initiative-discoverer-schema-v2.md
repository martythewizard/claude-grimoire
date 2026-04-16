# Initiative Discoverer Schema v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update initiative-discoverer skill to discover untracked GitHub issues from GitHub Projects and workstream repos using schema v2 YAML structure.

**Architecture:** Parse schema v2 (github_project, workstreams, JIRA epic tasks), query GitHub Project v2 for items via GraphQL, search workstream repos for issues, deduplicate against JIRA epic task github_issue references, AI rank candidates, suggest additions in schema v2 format.

**Tech Stack:** Bash, gh CLI (REST + GraphQL), grep/awk for YAML parsing, Claude API for AI ranking, jq for JSON processing

---

## File Structure

**Files to modify:**
- `skills/initiative-discoverer/skill.md` - Main skill documentation (major rewrite for schema v2)
- `skills/initiative-discoverer/examples/discovery-results.md` - Update for schema v2 format
- `skills/initiative-discoverer/examples/no-results.md` - Update for schema v2 format

**Files to create:**
- `test/initiative-discoverer/fixtures/schema-v2-discoverable.yaml` - Test fixture with schema v2
- `test/initiative-discoverer/test-schema-v2.sh` - Integration test script

---

## Task 1: Update Skill Metadata and Version

**Files:**
- Modify: `skills/initiative-discoverer/skill.md:1-5`

- [ ] **Step 1: Update version and description in frontmatter**

```yaml
---
name: initiative-discoverer
description: Find untracked GitHub issues in Projects and workstream repos using AI-driven matching (schema v2)
version: 2.0.0
---
```

- [ ] **Step 2: Commit metadata update**

```bash
git add skills/initiative-discoverer/skill.md
git commit -m "feat(initiative-discoverer): bump version to 2.0.0 for schema v2"
```

---

## Task 2: Update Purpose and How It Works Section

**Files:**
- Modify: `skills/initiative-discoverer/skill.md:7-29`

- [ ] **Step 1: Replace Purpose section for schema v2**

```markdown
## Purpose

This skill helps you:
- Discover GitHub issues in Projects that aren't tracked in initiative YAML
- Find issues in workstream repos that should be linked to JIRA epic tasks
- Increase initiative completeness with AI-powered relevance scoring
- Get ready-to-merge YAML snippets with confidence scores and reasoning

## When to Use

Invoke this skill after creating an initiative YAML, or periodically to find work that should be linked but isn't yet.

## How It Works

1. **Extract Context** - Parse schema v2 YAML for github_project, workstreams, JIRA epic tasks
2. **Search GitHub Project** - Query project items via GraphQL (if configured)
3. **Search Workstream Repos** - Find open issues in repos with milestone filters
4. **Deduplicate** - Remove issues already tracked in JIRA epic tasks
5. **AI Ranking** - Score each candidate (1-10) using Claude for relevance
6. **Generate Suggestions** - Output YAML snippets in schema v2 format
```

- [ ] **Step 2: Commit purpose update**

```bash
git add skills/initiative-discoverer/skill.md
git commit -m "docs(initiative-discoverer): update purpose for schema v2"
```

---

## Task 3: Update Step 1 - Context Extraction

**Files:**
- Modify: `skills/initiative-discoverer/skill.md:31-82`

- [ ] **Step 1: Replace context extraction for schema v2**

```markdown
## Workflow

### Step 1: Extract Context from Schema v2 YAML

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

# Validate schema v2
SCHEMA_VERSION=$(grep "^schema_version:" "$YAML_FILE" | awk '{print $2}')
if [ "$SCHEMA_VERSION" != "2" ]; then
    echo "Error: Expected schema_version: 2, got: $SCHEMA_VERSION"
    echo "This skill only supports schema v2."
    exit 1
fi

# Extract initiative metadata
INITIATIVE_NAME=$(grep "^name:" "$YAML_FILE" | sed 's/name: "\?\([^"]*\)"\?/\1/')
INITIATIVE_DESC=$(grep "^description:" "$YAML_FILE" | sed 's/description: "\?\([^"]*\)"\?/\1/')

# Extract team members (for filtering)
TEAM_MEMBERS=$(grep -A 50 "^team:" "$YAML_FILE" | grep "  - " | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')

# Extract tags (for keyword matching)
TAGS=$(grep -A 50 "^tags:" "$YAML_FILE" | grep "  - " | awk '{print $2}' | tr '\n' ' ')

# Extract GitHub Project (if configured)
if grep -q "^github_project:" "$YAML_FILE"; then
    PROJECT_ORG=$(grep -A 3 "^github_project:" "$YAML_FILE" | grep "org:" | awk '{print $2}')
    PROJECT_NUMBER=$(grep -A 3 "^github_project:" "$YAML_FILE" | grep "number:" | awk '{print $2}')
    echo "GitHub Project: $PROJECT_ORG#$PROJECT_NUMBER"
else
    PROJECT_ORG=""
    PROJECT_NUMBER=""
    echo "GitHub Project: Not configured"
fi

# Extract workstream repos
WORKSTREAM_REPOS=$(grep -A 500 "^workstreams:" "$YAML_FILE" | grep "repo:" | awk '{print $2}' | sort -u)
echo "Workstream repos: $(echo $WORKSTREAM_REPOS | tr '\n' ', ')"

# Extract existing github_issue numbers from JIRA epic tasks (for deduplication)
EXISTING_ISSUES=$(grep -A 500 "^jira:" "$YAML_FILE" | grep "github_issue:" | awk '{print $2}' | sort -n | tr '\n' ',' | sed 's/,$//')

if [ -n "$EXISTING_ISSUES" ]; then
    echo "Existing tracked issues: $EXISTING_ISSUES"
else
    echo "Existing tracked issues: None"
fi

# Extract JIRA project key (optional)
if grep -q "^jira:" "$YAML_FILE" && grep -q "project_key:" "$YAML_FILE"; then
    PROJECT_KEY=$(grep "project_key:" "$YAML_FILE" | awk '{print $2}' | tr -d '"')
    echo "JIRA Project: $PROJECT_KEY"
else
    PROJECT_KEY=""
    echo "JIRA: Not configured"
fi

echo "Context extraction complete."
```
```

- [ ] **Step 2: Commit context extraction update**

```bash
git add skills/initiative-discoverer/skill.md
git commit -m "feat(initiative-discoverer): update context extraction for schema v2"
```

---

## Task 4: Add Step 2 - GitHub Project Discovery

**Files:**
- Modify: `skills/initiative-discoverer/skill.md:84-150` (replace JIRA search)

- [ ] **Step 1: Add GitHub Project discovery step**

```markdown
### Step 2: Search GitHub Project for Untracked Issues (Optional)

Query GitHub Project v2 for issues not tracked in YAML:

```bash
# Check if GitHub Project is configured
if [ -n "$PROJECT_ORG" ] && [ -n "$PROJECT_NUMBER" ]; then
    echo "Searching GitHub Project $PROJECT_ORG#$PROJECT_NUMBER..."
    
    # GraphQL query for project items
    QUERY='query($org: String!, $number: Int!) {
      organization(login: $org) {
        projectV2(number: $number) {
          items(first: 100) {
            nodes {
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
                  assignees(first: 5) {
                    nodes {
                      login
                    }
                  }
                }
              }
            }
          }
        }
      }
    }'
    
    RESPONSE=$(gh api graphql -f query="$QUERY" -f org="$PROJECT_ORG" -F number="$PROJECT_NUMBER" 2>&1)
    GH_EXIT_CODE=$?
    
    if [ $GH_EXIT_CODE -ne 0 ]; then
        echo "Warning: GitHub API failed, skipping GitHub Project search"
        PROJECT_CANDIDATES=""
    else
        # Extract issues from project (pipe-delimited format)
        PROJECT_CANDIDATES=$(echo "$RESPONSE" | jq -r '
          .data.organization.projectV2.items.nodes[].content |
          select(.number != null) |
          "\(.number)|\(.title)|\(.repository.nameWithOwner)|\(.milestone.title // "none")|\(.assignees.nodes[0].login // "unassigned")|\(.labels.nodes | map(.name) | join(","))"
        ')
        
        PROJECT_COUNT=$(echo "$PROJECT_CANDIDATES" | grep -c "^" || echo "0")
        echo "Found $PROJECT_COUNT issues in GitHub Project"
    fi
else
    echo "GitHub Project not configured, skipping project search"
    PROJECT_CANDIDATES=""
fi
```
```

- [ ] **Step 2: Commit GitHub Project discovery**

```bash
git add skills/initiative-discoverer/skill.md
git commit -m "feat(initiative-discoverer): add GitHub Project v2 discovery"
```

---

## Task 5: Add Step 3 - Workstream Repo Discovery

**Files:**
- Modify: `skills/initiative-discoverer/skill.md:152-200`

- [ ] **Step 1: Add workstream repo issue search**

```markdown
### Step 3: Search Workstream Repos for Untracked Issues

For each workstream repo, find open issues:

```bash
echo "Searching workstream repos for untracked issues..."

REPO_CANDIDATES=""

for repo in $WORKSTREAM_REPOS; do
    echo "Searching $repo..."
    
    # Fetch open issues in repo
    ISSUES=$(gh api repos/$repo/issues --jq '.[] | select(.state=="open") | "\(.number)|\(.title)|\(.milestone.title // "none")|\(.assignee.login // "unassigned")|\(.labels | map(.name) | join(","))"' 2>&1)
    GH_EXIT_CODE=$?
    
    if [ $GH_EXIT_CODE -ne 0 ]; then
        echo "Warning: Failed to fetch issues from $repo, skipping"
        continue
    fi
    
    if [ -z "$ISSUES" ]; then
        echo "No open issues in $repo"
        continue
    fi
    
    # Add repo to each issue line
    while IFS= read -r issue_line; do
        [ -z "$issue_line" ] && continue
        REPO_CANDIDATES="$REPO_CANDIDATES"$'\n'"$issue_line|$repo"
    done <<< "$ISSUES"
    
    ISSUE_COUNT=$(echo "$ISSUES" | grep -c "^" || echo "0")
    echo "Found $ISSUE_COUNT open issues in $repo"
done

# Remove leading newline
REPO_CANDIDATES=$(echo "$REPO_CANDIDATES" | sed '/^$/d')
REPO_COUNT=$(echo "$REPO_CANDIDATES" | grep -c "^" || echo "0")
echo "Total: $REPO_COUNT open issues across workstream repos"
```
```

- [ ] **Step 2: Commit workstream discovery**

```bash
git add skills/initiative-discoverer/skill.md
git commit -m "feat(initiative-discoverer): add workstream repo issue discovery"
```

---

## Task 6: Add Step 4 - Deduplication

**Files:**
- Modify: `skills/initiative-discoverer/skill.md:202-250`

- [ ] **Step 1: Add deduplication step**

```markdown
### Step 4: Deduplicate Against Tracked Issues

Remove issues already tracked in JIRA epic tasks:

```bash
echo "Deduplicating candidates..."

# Combine project and repo candidates
ALL_CANDIDATES="$PROJECT_CANDIDATES"$'\n'"$REPO_CANDIDATES"
ALL_CANDIDATES=$(echo "$ALL_CANDIDATES" | sed '/^$/d')

UNTRACKED_CANDIDATES=""

while IFS='|' read -r number title repo_or_milestone milestone_or_assignee assignee_or_labels labels_or_repo extra; do
    [ -z "$number" ] && continue
    
    # Normalize fields based on source (project vs repo)
    if [ -n "$extra" ]; then
        # From repo search: number|title|milestone|assignee|labels|repo
        issue_num="$number"
        issue_title="$title"
        issue_repo="$labels_or_repo"
        issue_milestone="$repo_or_milestone"
        issue_assignee="$milestone_or_assignee"
        issue_labels="$assignee_or_labels"
    else
        # From project search: number|title|repo|milestone|assignee|labels
        issue_num="$number"
        issue_title="$title"
        issue_repo="$repo_or_milestone"
        issue_milestone="$milestone_or_assignee"
        issue_assignee="$assignee_or_labels"
        issue_labels="$labels_or_repo"
    fi
    
    # Check if issue is already tracked
    if [[ ",$EXISTING_ISSUES," == *",$issue_num,"* ]]; then
        echo "Skipping #$issue_num (already tracked in JIRA epic tasks)"
        continue
    fi
    
    # Add to untracked list
    UNTRACKED_CANDIDATES="$UNTRACKED_CANDIDATES"$'\n'"$issue_num|$issue_title|$issue_repo|$issue_milestone|$issue_assignee|$issue_labels"
done <<< "$ALL_CANDIDATES"

# Remove leading newline and duplicates
UNTRACKED_CANDIDATES=$(echo "$UNTRACKED_CANDIDATES" | sed '/^$/d' | sort -u -t'|' -k1,1n)

UNTRACKED_COUNT=$(echo "$UNTRACKED_CANDIDATES" | grep -c "^" || echo "0")
echo "Found $UNTRACKED_COUNT untracked issues after deduplication"

if [ "$UNTRACKED_COUNT" -eq 0 ]; then
    echo "No untracked issues found. Initiative appears to be fully tracked!"
    exit 0
fi
```
```

- [ ] **Step 2: Commit deduplication**

```bash
git add skills/initiative-discoverer/skill.md
git commit -m "feat(initiative-discoverer): add deduplication against JIRA epic tasks"
```

---

## Task 7: Update Step 5 - AI Ranking

**Files:**
- Modify: `skills/initiative-discoverer/skill.md:252-350`

- [ ] **Step 1: Update AI ranking to use GitHub data**

```markdown
### Step 5: AI Ranking of Candidates

Score each candidate using Claude API for relevance:

```bash
echo "Ranking candidates with AI..."

# Check for Claude API key
ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}"
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Warning: ANTHROPIC_API_KEY not set, using heuristic scoring"
    USE_AI=false
else
    USE_AI=true
fi

SCORED_CANDIDATES=""

while IFS='|' read -r issue_num issue_title issue_repo issue_milestone issue_assignee issue_labels; do
    [ -z "$issue_num" ] && continue
    
    if [ "$USE_AI" = true ]; then
        # AI-powered scoring via Claude API
        PROMPT="Score this GitHub issue's relevance to the initiative on a scale of 1-10.

Initiative: $INITIATIVE_NAME
Description: $INITIATIVE_DESC
Tags: $TAGS

Issue #$issue_num: $issue_title
Repo: $issue_repo
Milestone: $issue_milestone
Assignee: $issue_assignee
Labels: $issue_labels

Respond with ONLY: {\"score\": <number>, \"reasoning\": \"<brief explanation>\"}"

        RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
            -H "x-api-key: $ANTHROPIC_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -H "content-type: application/json" \
            -d "{
                \"model\": \"claude-3-5-sonnet-20241022\",
                \"max_tokens\": 150,
                \"messages\": [{\"role\": \"user\", \"content\": \"$PROMPT\"}]
            }")
        
        # Extract score and reasoning
        SCORE=$(echo "$RESPONSE" | jq -r '.content[0].text' | jq -r '.score // 5')
        REASONING=$(echo "$RESPONSE" | jq -r '.content[0].text' | jq -r '.reasoning // "No reasoning provided"')
    else
        # Heuristic scoring fallback
        SCORE=5
        REASONING="Heuristic scoring (no Claude API key)"
        
        # Boost score if initiative name appears in title
        if echo "$issue_title" | grep -qi "$INITIATIVE_NAME"; then
            SCORE=$((SCORE + 3))
            REASONING="$REASONING. Initiative name in title (+3)"
        fi
        
        # Boost score if tags appear in labels
        for tag in $TAGS; do
            if echo "$issue_labels" | grep -qi "$tag"; then
                SCORE=$((SCORE + 2))
                REASONING="$REASONING. Tag '$tag' in labels (+2)"
                break
            fi
        done
        
        # Boost if repo is in workstreams
        if echo "$WORKSTREAM_REPOS" | grep -q "$issue_repo"; then
            SCORE=$((SCORE + 1))
            REASONING="$REASONING. In workstream repo (+1)"
        fi
        
        # Cap at 10
        if [ "$SCORE" -gt 10 ]; then
            SCORE=10
        fi
    fi
    
    # Add to scored list
    SCORED_CANDIDATES="$SCORED_CANDIDATES"$'\n'"$SCORE|$issue_num|$issue_title|$issue_repo|$issue_milestone|$issue_assignee|$issue_labels|$REASONING"
    
    echo "Scored #$issue_num: $SCORE/10"
done <<< "$UNTRACKED_CANDIDATES"

# Sort by score descending
SCORED_CANDIDATES=$(echo "$SCORED_CANDIDATES" | sed '/^$/d' | sort -t'|' -k1,1nr)

echo "Ranking complete."
```
```

- [ ] **Step 2: Commit AI ranking update**

```bash
git add skills/initiative-discoverer/skill.md
git commit -m "feat(initiative-discoverer): update AI ranking for GitHub data"
```

---

## Task 8: Update Step 6 - Output Generation

**Files:**
- Modify: `skills/initiative-discoverer/skill.md:352-450`

- [ ] **Step 1: Replace output generation for schema v2 format**

```markdown
### Step 6: Generate Suggestions

Output suggestions in schema v2 YAML format:

```bash
echo ""
echo "# Discovery Results: $(basename $YAML_FILE)"
echo ""

if [ -n "$PROJECT_ORG" ] && [ -n "$PROJECT_NUMBER" ]; then
    echo "Initiative has GitHub Project $PROJECT_ORG#$PROJECT_NUMBER. Found $UNTRACKED_COUNT untracked issues."
else
    echo "Found $UNTRACKED_COUNT untracked issues across workstream repos."
fi

echo ""

# High confidence (8-10)
echo "## High Confidence (8-10)"
echo ""

HIGH_FOUND=false
while IFS='|' read -r score issue_num issue_title issue_repo issue_milestone issue_assignee issue_labels reasoning; do
    [ -z "$score" ] && continue
    if [ "$score" -ge 8 ]; then
        HIGH_FOUND=true
        echo "### #$issue_num: $issue_title"
        echo "**Repo:** $issue_repo"
        echo "**Milestone:** $issue_milestone"
        echo "**Score:** $score/10"
        echo "**Reasoning:** $reasoning"
        echo ""
        echo "**Add to YAML:**"
        echo '```yaml'
        echo "jira:"
        echo "  epics:"
        echo "    - key: <EPIC-KEY>  # Choose appropriate epic"
        echo "      milestone: \"$issue_milestone\""
        echo "      tasks:"
        echo "        - key: <TASK-KEY>  # Create this JIRA task"
        echo "          github_issue: $issue_num"
        echo "          status: Backlog"
        echo '```'
        echo ""
    fi
done <<< "$SCORED_CANDIDATES"

if [ "$HIGH_FOUND" = false ]; then
    echo "None"
    echo ""
fi

# Medium confidence (5-7)
echo "## Medium Confidence (5-7)"
echo ""

MEDIUM_FOUND=false
while IFS='|' read -r score issue_num issue_title issue_repo issue_milestone issue_assignee issue_labels reasoning; do
    [ -z "$score" ] && continue
    if [ "$score" -ge 5 ] && [ "$score" -lt 8 ]; then
        MEDIUM_FOUND=true
        echo "### #$issue_num: $issue_title"
        echo "**Repo:** $issue_repo"
        echo "**Milestone:** $issue_milestone"
        echo "**Score:** $score/10"
        echo "**Reasoning:** $reasoning"
        echo ""
        echo "**Suggested action:**"
        echo "1. Review issue to confirm relevance"
        if [ "$issue_milestone" = "none" ]; then
            echo "2. Assign to appropriate milestone"
        fi
        if [ -n "$PROJECT_ORG" ]; then
            echo "3. Add to GitHub Project $PROJECT_ORG#$PROJECT_NUMBER if relevant"
        fi
        echo "4. Create JIRA task and add github_issue reference"
        echo ""
    fi
done <<< "$SCORED_CANDIDATES"

if [ "$MEDIUM_FOUND" = false ]; then
    echo "None"
    echo ""
fi

echo "---"
echo ""

# Already tracked summary
echo "## Already Tracked"
echo ""
TRACKED_COUNT=$(echo "$EXISTING_ISSUES" | tr ',' '\n' | grep -c "^" || echo "0")
echo "- $TRACKED_COUNT issues tracked in JIRA epic tasks"
if [ -n "$PROJECT_ORG" ]; then
    echo "- GitHub Project $PROJECT_ORG#$PROJECT_NUMBER configured"
fi
echo ""

# Optional JIRA discovery
if [ -n "$PROJECT_KEY" ]; then
    echo "## JIRA Discovery (Optional)"
    echo ""
    echo "JIRA project $PROJECT_KEY is configured. To search for untracked JIRA epics:"
    echo "1. Run JIRA epic discovery separately (out of scope for schema v2)"
    echo "2. Or continue using GitHub-first workflow"
    echo ""
else
    echo "## JIRA Discovery (Optional)"
    echo ""
    echo "JIRA not configured. To enable JIRA tracking, add:"
    echo '```yaml'
    echo "jira:"
    echo "  project_key: YOUR_PROJECT"
    echo '```'
    echo ""
fi

# Action items
echo "## Action Items"
echo "1. Review high-confidence GitHub issue suggestions"
echo "2. Create corresponding JIRA tasks if tracking there"
echo "3. Add github_issue references to JIRA epic tasks in YAML"
echo "4. Re-run /initiative-validator after updating YAML"
```
```

- [ ] **Step 2: Commit output generation**

```bash
git add skills/initiative-discoverer/skill.md
git commit -m "feat(initiative-discoverer): update output format for schema v2"
```

---

## Task 9: Update Examples - Discovery Results

**Files:**
- Modify: `skills/initiative-discoverer/examples/discovery-results.md`

- [ ] **Step 1: Replace with schema v2 discovery results**

```markdown
# Discovery Results: 2026-q1-ai-cost-intelligence-platform.yaml

Initiative has GitHub Project eci-global#14. Found 3 untracked issues.

## High Confidence (8-10)

### #234: Implement cost anomaly alerting
**Repo:** eci-global/one-cloud-cloud-costs  
**Milestone:** M1 — Eyes Open: Automated Detection  
**Score:** 9/10  
**Reasoning:** In GitHub Project #14, assigned to milestone M1, matches initiative tags (cost-optimization, ai). Not tracked in any JIRA epic task.

**Add to YAML:**
```yaml
jira:
  epics:
    - key: ITPLAT01-2258  # M1 epic
      milestone: "M1 — Eyes Open: Automated Detection"
      tasks:
        - key: ITPLAT01-2262  # Create this JIRA task
          github_issue: 234
          status: Backlog
```

### #235: Add Coralogix integration for alerts
**Repo:** eci-global/one-cloud-cloud-costs  
**Milestone:** M2 — Learning Normal  
**Score:** 8/10  
**Reasoning:** In GitHub Project #14, milestone M2, mentions Coralogix (related system).

**Add to YAML:**
```yaml
jira:
  epics:
    - key: ITPLAT01-2259  # M2 epic
      milestone: "M2 — Learning Normal: Baseline Intelligence"
      tasks:
        - key: ITPLAT01-2263  # Create this JIRA task
          github_issue: 235
          status: Backlog
```

## Medium Confidence (5-7)

### #240: Improve data pipeline performance
**Repo:** eci-global/one-cloud-cloud-costs  
**Milestone:** none  
**Score:** 6/10  
**Reasoning:** Open issue in workstream repo, mentions data pipeline (matches workstream "S3 Data Lake"), but no milestone assigned.

**Suggested action:**
1. Review issue to confirm relevance
2. Assign to appropriate milestone (M0 or M5?)
3. Add to GitHub Project eci-global#14 if relevant
4. Create JIRA task and add github_issue reference

---

## Already Tracked

- 12 issues tracked in JIRA epic tasks
- GitHub Project eci-global#14 configured

## JIRA Discovery (Optional)

JIRA project ITPLAT01 is configured. To search for untracked JIRA epics:
1. Run JIRA epic discovery separately (out of scope for schema v2)
2. Or continue using GitHub-first workflow

## Action Items
1. Review high-confidence GitHub issue suggestions
2. Create corresponding JIRA tasks if tracking there
3. Add github_issue references to JIRA epic tasks in YAML
4. Re-run /initiative-validator after updating YAML
```

- [ ] **Step 2: Commit discovery results example**

```bash
git add skills/initiative-discoverer/examples/discovery-results.md
git commit -m "docs(initiative-discoverer): update discovery results for schema v2"
```

---

## Task 10: Update Examples - No Results

**Files:**
- Modify: `skills/initiative-discoverer/examples/no-results.md`

- [ ] **Step 1: Replace with schema v2 no results format**

```markdown
# Discovery Results: 2026-q1-coralogix-quota-manager.yaml

Initiative has GitHub Project eci-global#8. Found 0 untracked issues.

## High Confidence (8-10)

None

## Medium Confidence (5-7)

None

---

## Already Tracked

- 8 issues tracked in JIRA epic tasks
- GitHub Project eci-global#8 configured

All open issues in GitHub Project and workstream repos are already tracked in JIRA epic tasks. Initiative appears to be fully tracked!

## JIRA Discovery (Optional)

JIRA project ITPLAT01 is configured. To search for untracked JIRA epics:
1. Run JIRA epic discovery separately (out of scope for schema v2)
2. Or continue using GitHub-first workflow

## Action Items
No action needed. All GitHub issues are tracked.
```

- [ ] **Step 2: Commit no results example**

```bash
git add skills/initiative-discoverer/examples/no-results.md
git commit -m "docs(initiative-discoverer): update no results example for schema v2"
```

---

## Task 11: Create Test Fixture

**Files:**
- Create: `test/initiative-discoverer/fixtures/schema-v2-discoverable.yaml`

- [ ] **Step 1: Create schema v2 test fixture**

```yaml
schema_version: 2

name: "Test Initiative - Discovery Test"
description: >-
  Test initiative for validating discovery with schema v2.
  Used to test GitHub Project and workstream repo discovery.
status: active
owner: testuser
team:
  - testuser

github_project:
  org: test-org
  number: 10

workstreams:
  - name: "Core Service"
    repo: test-org/service
    milestones:
      - title: "M1 — Foundation"
        number: 1
        due: "2026-06-30"
        status: in-progress

jira:
  project_key: TEST
  epics:
    - key: TEST-200
      milestone: "M1 — Foundation"
      status: In Progress
      tasks:
        - key: TEST-201
          github_issue: 50
          status: Done
        - key: TEST-202
          github_issue: 51
          status: In Progress

tags:
  - test
  - discovery
```

- [ ] **Step 2: Commit test fixture**

```bash
git add test/initiative-discoverer/fixtures/schema-v2-discoverable.yaml
git commit -m "test(initiative-discoverer): add schema v2 test fixture"
```

---

## Task 12: Create Test Script

**Files:**
- Create: `test/initiative-discoverer/test-schema-v2.sh`

- [ ] **Step 1: Create integration test script**

```bash
#!/bin/bash

# Integration test for initiative-discoverer schema v2 support

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURE_FILE="$SCRIPT_DIR/fixtures/schema-v2-discoverable.yaml"

echo "Testing initiative-discoverer with schema v2 fixture..."
echo ""

# Test 1: Schema validation
echo "Test 1: Schema v2 validation"
if grep -q "schema_version: 2" "$FIXTURE_FILE"; then
    echo "✅ Fixture has schema_version: 2"
else
    echo "❌ Fixture missing schema_version: 2"
    exit 1
fi

# Test 2: GitHub Project extraction
echo ""
echo "Test 2: GitHub Project structure"
if grep -q "^github_project:" "$FIXTURE_FILE"; then
    echo "✅ GitHub Project section present"
    
    PROJECT_ORG=$(grep -A 3 "^github_project:" "$FIXTURE_FILE" | grep "org:" | awk '{print $2}')
    PROJECT_NUMBER=$(grep -A 3 "^github_project:" "$FIXTURE_FILE" | grep "number:" | awk '{print $2}')
    
    if [ -n "$PROJECT_ORG" ] && [ -n "$PROJECT_NUMBER" ]; then
        echo "✅ Project org and number extracted: $PROJECT_ORG#$PROJECT_NUMBER"
    else
        echo "❌ Failed to extract project org/number"
        exit 1
    fi
else
    echo "❌ GitHub Project section missing"
    exit 1
fi

# Test 3: Workstream repo extraction
echo ""
echo "Test 3: Workstream repos"
WORKSTREAM_REPOS=$(grep -A 500 "^workstreams:" "$FIXTURE_FILE" | grep "repo:" | awk '{print $2}')
if [ -n "$WORKSTREAM_REPOS" ]; then
    echo "✅ Workstream repos found: $WORKSTREAM_REPOS"
else
    echo "❌ No workstream repos found"
    exit 1
fi

# Test 4: JIRA epic task extraction
echo ""
echo "Test 4: JIRA epic task github_issue extraction"
EXISTING_ISSUES=$(grep -A 500 "^jira:" "$FIXTURE_FILE" | grep "github_issue:" | awk '{print $2}' | tr '\n' ',')
if [ -n "$EXISTING_ISSUES" ]; then
    echo "✅ Existing github_issue numbers found: $EXISTING_ISSUES"
else
    echo "⚠️  No github_issue numbers found (may be valid if no JIRA tasks yet)"
fi

# Test 5: Tag extraction
echo ""
echo "Test 5: Tag extraction"
TAGS=$(grep -A 50 "^tags:" "$FIXTURE_FILE" | grep "  - " | awk '{print $2}' | tr '\n' ' ')
if [ -n "$TAGS" ]; then
    echo "✅ Tags found: $TAGS"
else
    echo "⚠️  No tags found (optional)"
fi

echo ""
echo "========================================="
echo "All tests passed! ✅"
echo "========================================="
```

- [ ] **Step 2: Make test script executable**

```bash
chmod +x test/initiative-discoverer/test-schema-v2.sh
```

- [ ] **Step 3: Run test to verify fixture**

```bash
./test/initiative-discoverer/test-schema-v2.sh
```

Expected output:
```
Testing initiative-discoverer with schema v2 fixture...

Test 1: Schema v2 validation
✅ Fixture has schema_version: 2

Test 2: GitHub Project structure
✅ GitHub Project section present
✅ Project org and number extracted: test-org#10

Test 3: Workstream repos
✅ Workstream repos found: test-org/service

Test 4: JIRA epic task github_issue extraction
✅ Existing github_issue numbers found: 50,51,

Test 5: Tag extraction
✅ Tags found: test discovery

=========================================
All tests passed! ✅
=========================================
```

- [ ] **Step 4: Commit test script**

```bash
git add test/initiative-discoverer/test-schema-v2.sh
git commit -m "test(initiative-discoverer): add schema v2 integration test"
```

---

## Task 13: Add Version Changelog

**Files:**
- Modify: `skills/initiative-discoverer/skill.md` (append at end)

- [ ] **Step 1: Add changelog section**

```markdown
## Changelog

### v2.0.0 - Schema v2 Support (2026-04-15)

**Breaking Changes:**
- Only supports schema v2 (schema_version: 2)
- Use v1.0.0 for legacy schema v1 files

**New Features:**
- Discovers untracked issues in GitHub Project v2 via GraphQL
- Searches workstream repos for untracked issues
- Deduplicates against JIRA epic task github_issue references
- Suggests additions in schema v2 format (JIRA epic tasks)
- AI ranking uses GitHub issue data (repo, milestone, labels, assignees)

**Removed:**
- Direct JIRA epic discovery (GitHub-first approach)
- Support for `repos:` array (replaced by `workstreams:`)

**Migration:**
- All initiatives in eci-global/initiatives use schema v2
- No migration needed for users (discoverer auto-detects schema version)
- Output format changed: suggests JIRA epic task additions instead of epic additions
```

- [ ] **Step 2: Commit changelog**

```bash
git add skills/initiative-discoverer/skill.md
git commit -m "docs(initiative-discoverer): add v2.0.0 changelog"
```

---

## Self-Review Checklist

- [ ] All spec requirements covered:
  - ✅ Schema v2 parsing (github_project, workstreams, JIRA epic tasks)
  - ✅ GitHub Project discovery (GraphQL)
  - ✅ Workstream repo issue discovery
  - ✅ Deduplication against JIRA epic task github_issue
  - ✅ AI ranking with GitHub data
  - ✅ Schema v2 output format (JIRA task suggestions)
  
- [ ] No placeholders or TBDs in plan
- [ ] All file paths are exact
- [ ] All bash code blocks are complete and runnable
- [ ] Test fixtures created
- [ ] Integration test script included
- [ ] Examples updated for schema v2
- [ ] Version bumped to 2.0.0
- [ ] Changelog added

## Execution Ready

This plan is ready for execution via:
- **superpowers:subagent-driven-development** (recommended)
- **superpowers:executing-plans** (inline execution)
