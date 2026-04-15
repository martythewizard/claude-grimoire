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

## Examples

See `examples/` directory for:
- `discovery-results.md` - Found untracked epics with suggestions
- `no-results.md` - All epics already tracked
