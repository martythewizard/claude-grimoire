---
name: initiative-discoverer
description: Find untracked GitHub issues in Projects and workstream repos using AI-driven matching (schema v2)
version: 2.0.0
---

# Initiative Discoverer Skill

Discover GitHub issues in Projects and workstream repos that should be linked to initiatives. Uses AI-driven semantic matching to score candidates by relevance.

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
3. **Search Workstream Repos** - Find open issues in workstream repos
4. **Deduplicate** - Remove issues already tracked in JIRA epic tasks
5. **AI Ranking** - Score each candidate (1-10) using Claude for relevance
6. **Generate Suggestions** - Output YAML snippets in schema v2 format

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
    elif echo "$RESPONSE" | jq -e '.errors' > /dev/null 2>&1; then
        echo "Warning: GraphQL errors in response, skipping GitHub Project search"
        echo "$RESPONSE" | jq -r '.errors[].message' 2>/dev/null || echo "Unknown GraphQL error"
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

### Step 4: Deduplicate Against Existing Epics

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

### Step 5: Rank Candidates with AI

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

### Step 6: Generate Suggestions

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
