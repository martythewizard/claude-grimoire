---
name: initiative-discoverer
description: Find untracked GitHub issues in Projects and workstream repos using AI-driven matching (schema v2)
version: 2.0.0
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
