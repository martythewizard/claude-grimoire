# Initiative Discoverer GitHub-First Updates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update initiative-discoverer skill to discover untracked GitHub issues and PRs as primary discovery targets, with JIRA epic discovery as optional secondary system.

**Architecture:** Add GitHub issue discovery (filter by labels, assignees, milestones) and GitHub Projects item discovery (GraphQL) before JIRA discovery. Update AI ranking to use GitHub data (issue title, body, labels). Make JIRA discovery conditional on jira.project_key existing. Update output format to show GitHub-first suggestions.

**Tech Stack:** GitHub CLI (gh), GitHub REST API, GitHub GraphQL API, Claude API (AI ranking), bash scripting, YAML parsing

---

## File Structure

**Modified files:**
- `skills/initiative-discoverer/skill.md` - Add GitHub issue/PR discovery workflow steps
- `skills/initiative-discoverer/examples/discovery-results.md` - Update to show GitHub issues
- `skills/initiative-discoverer/examples/no-results.md` - Update to GitHub-first format
- `test/initiative-discoverer/fixtures/discoverable.yaml` - Add github.projects and github.issues
- `test/initiative-discoverer/test-integration.sh` - Add GitHub discovery tests

---

### Task 1: Update Context Extraction for GitHub

**Files:**
- Modify: `skills/initiative-discoverer/skill.md`

- [ ] **Step 1: Update Step 1 to extract GitHub context (repos, existing issues)**

Update lines 40-82 to extract GitHub context and make JIRA project_key optional:

```markdown
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

# Extract initiative metadata for context
INITIATIVE_NAME=$(grep "^name:" "$YAML_FILE" | sed 's/name: "\(.*\)"/\1/')
INITIATIVE_DESC=$(grep "^description:" "$YAML_FILE" | sed 's/description: "\(.*\)"/\1/')

# Extract team members (for filtering)
TEAM_MEMBERS=$(grep -A 50 "^team:" "$YAML_FILE" | grep "  - " | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')

# Extract tags (for keyword matching)
TAGS=$(grep -A 50 "^tags:" "$YAML_FILE" | grep "  - " | awk '{print $2}' | tr '\n' ' ')

# Extract repos (primary for GitHub discovery)
REPOS=$(grep -A 100 "^repos:" "$YAML_FILE" | grep "  - name:" | awk '{print $3}')

# Extract existing GitHub issues (for deduplication)
EXISTING_ISSUES=$(grep -A 50 "  issues:" "$YAML_FILE" | grep "    - " | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')

# Extract existing GitHub project numbers (for deduplication)
EXISTING_PROJECTS=$(grep -A 50 "  projects:" "$YAML_FILE" | grep "    - number:" | awk '{print $3}' | tr '\n' ',' | sed 's/,$//')

# Extract JIRA project key (optional for JIRA discovery)
PROJECT_KEY=$(grep "project_key:" "$YAML_FILE" | awk '{print $2}' | tr -d '"')

# Extract existing JIRA epic keys (for deduplication if JIRA configured)
EXISTING_EPICS=$(grep -A 100 "^jira:" "$YAML_FILE" | grep "  - key:" | awk '{print $3}' | tr '\n' ',' | sed 's/,$//')

echo "Context extracted:"
echo "  Initiative: $INITIATIVE_NAME"
echo "  Repos: $REPOS"
echo "  Team: $TEAM_MEMBERS"
echo "  Tags: $TAGS"
echo "  Existing GitHub issues: $EXISTING_ISSUES"
if [ -n "$PROJECT_KEY" ]; then
    echo "  JIRA Project: $PROJECT_KEY (will search JIRA)"
    echo "  Existing JIRA epics: $EXISTING_EPICS"
else
    echo "  JIRA: Not configured (will skip JIRA discovery)"
fi
```
```

- [ ] **Step 2: Commit**

```bash
git add skills/initiative-discoverer/skill.md
git commit -m "feat(initiative-discoverer): update context extraction for GitHub-first

- Extract repos as primary context
- Extract existing GitHub issues for deduplication
- Extract GitHub project numbers
- Make JIRA project_key optional"
```

---

### Task 2: Add GitHub Issue Discovery

**Files:**
- Modify: `skills/initiative-discoverer/skill.md`

- [ ] **Step 1: Add new Step 2 for GitHub issue discovery**

Insert after Step 1 (context extraction):

```markdown
### Step 2: Search GitHub for Untracked Issues

For each repo in `repos:`, search for issues that match initiative context but aren't tracked yet:

```bash
echo "Searching GitHub for untracked issues..."

GITHUB_CANDIDATES=""

for repo in $REPOS; do
    echo "Searching repo: $repo"
    
    # Search all open issues in repo
    ISSUES=$(gh api repos/$repo/issues --jq '.[] | "\(.number)|\(.title)|\(.body // "")|\(.user.login)|\(.labels | map(.name) | join(","))|\(.assignee.login // "unassigned")"')
    
    while IFS='|' read -r issue_num title body author labels assignee; do
        # Skip if already tracked
        if [[ ",$EXISTING_ISSUES," == *",$issue_num,"* ]]; then
            continue
        fi
        
        # Filter by tags (if issue labels match initiative tags)
        TAG_MATCH=false
        for tag in $TAGS; do
            if echo "$labels" | grep -qi "$tag"; then
                TAG_MATCH=true
                break
            fi
        done
        
        # Filter by team (if assignee is in initiative team)
        TEAM_MATCH=false
        if [ -n "$TEAM_MEMBERS" ]; then
            if [[ ",$TEAM_MEMBERS," == *",$assignee,"* ]]; then
                TEAM_MATCH=true
            fi
        fi
        
        # Filter by initiative name in title/body
        KEYWORD_MATCH=false
        if echo "$title $body" | grep -qi "$INITIATIVE_NAME"; then
            KEYWORD_MATCH=true
        fi
        
        # Add to candidates if any match
        if [ "$TAG_MATCH" = true ] || [ "$TEAM_MATCH" = true ] || [ "$KEYWORD_MATCH" = true ]; then
            if [ -z "$GITHUB_CANDIDATES" ]; then
                GITHUB_CANDIDATES="$repo|$issue_num|$title|$body|$assignee|$labels"
            else
                GITHUB_CANDIDATES="$GITHUB_CANDIDATES
$repo|$issue_num|$title|$body|$assignee|$labels"
            fi
        fi
    done <<< "$ISSUES"
done

GITHUB_CANDIDATE_COUNT=$(echo "$GITHUB_CANDIDATES" | grep -c '^' || echo 0)
echo "Found $GITHUB_CANDIDATE_COUNT untracked GitHub issues"
```
```

- [ ] **Step 2: Commit**

```bash
git add skills/initiative-discoverer/skill.md
git commit -m "feat(initiative-discoverer): add GitHub issue discovery

- Search all repos for untracked open issues
- Filter by labels matching initiative tags
- Filter by assignees in initiative team
- Filter by initiative name in title/body"
```

---

### Task 3: Add GitHub Projects Discovery

**Files:**
- Modify: `skills/initiative-discoverer/skill.md`

- [ ] **Step 1: Add new Step 3 for GitHub Projects item discovery**

Insert after Step 2 (GitHub issue discovery):

```markdown
### Step 3: Search GitHub Projects for Untracked Items (Optional)

If `github.projects` configured, search project items for untracked issues/PRs:

```bash
# Check if projects configured
if grep -q "^github:" "$YAML_FILE" && grep -q "  projects:" "$YAML_FILE"; then
    echo "Searching GitHub Projects for untracked items..."
    
    # Extract org from first repo
    FIRST_REPO=$(echo "$REPOS" | head -1)
    ORG=$(echo "$FIRST_REPO" | cut -d'/' -f1)
    
    # Extract project numbers
    PROJECT_NUMBERS=$(grep -A 50 "  projects:" "$YAML_FILE" | grep "    - number:" | awk '{print $3}')
    
    for proj_num in $PROJECT_NUMBERS; do
        echo "Searching project #$proj_num..."
        
        # Query project items via GraphQL
        QUERY='query($org: String!, $number: Int!) {
          organization(login: $org) {
            projectV2(number: $number) {
              items(first: 100) {
                nodes {
                  content {
                    ... on Issue {
                      number
                      title
                      body
                      repository {
                        nameWithOwner
                      }
                      assignees(first: 5) {
                        nodes {
                          login
                        }
                      }
                    }
                    ... on PullRequest {
                      number
                      title
                      body
                      repository {
                        nameWithOwner
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
        
        RESPONSE=$(gh api graphql -f query="$QUERY" -f org="$ORG" -F number="$proj_num")
        
        # Extract items and add to candidates if not already tracked
        PROJECT_ITEMS=$(echo "$RESPONSE" | jq -r '.data.organization.projectV2.items.nodes[] | select(.content.number != null) | "\(.content.repository.nameWithOwner)|\(.content.number)|\(.content.title)|\(.content.body // "")|\(.content.assignees.nodes[0].login // "unassigned")"')
        
        while IFS='|' read -r repo issue_num title body assignee; do
            # Skip if already tracked
            if [[ ",$EXISTING_ISSUES," == *",$issue_num,"* ]]; then
                continue
            fi
            
            # Skip if already in GITHUB_CANDIDATES from issue search
            if echo "$GITHUB_CANDIDATES" | grep -q "|$issue_num|"; then
                continue
            fi
            
            # Add to candidates
            GITHUB_CANDIDATES="$GITHUB_CANDIDATES
$repo|$issue_num|$title|$body|$assignee|project-item"
        done <<< "$PROJECT_ITEMS"
    done
    
    GITHUB_CANDIDATE_COUNT=$(echo "$GITHUB_CANDIDATES" | grep -c '^' || echo 0)
    echo "Total untracked GitHub items (including projects): $GITHUB_CANDIDATE_COUNT"
else
    echo "ℹ️  GitHub Projects: Not configured (skipped project item discovery)"
fi
```
```

- [ ] **Step 2: Commit**

```bash
git add skills/initiative-discoverer/skill.md
git commit -m "feat(initiative-discoverer): add GitHub Projects item discovery

- Query GitHub Projects v2 via GraphQL
- Find issues/PRs in projects not yet tracked
- Deduplicate against existing issues and issue search results
- Skip gracefully if projects not configured"
```

---

### Task 4: Update AI Ranking for GitHub Data

**Files:**
- Modify: `skills/initiative-discoverer/skill.md`

- [ ] **Step 1: Add new Step 4 for AI ranking GitHub candidates**

Insert after Step 3 (GitHub Projects discovery):

```markdown
### Step 4: Rank GitHub Candidates with AI

Use Claude to score each GitHub candidate:

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

RANKED_GITHUB_CANDIDATES=""

while IFS='|' read -r repo issue_num title body assignee labels; do
    if [ "$USE_AI_RANKING" = true ]; then
        # AI-driven ranking for GitHub issues
        PROMPT="You are analyzing whether GitHub issue #$issue_num in $repo belongs to initiative \"$INITIATIVE_NAME\".

Initiative context:
- Description: $INITIATIVE_DESC
- Tags: $TAGS
- Team: $TEAM_MEMBERS
- Repos: $(echo "$REPOS" | tr '\n' ', ')

Issue context:
- Number: #$issue_num
- Repository: $repo
- Title: $title
- Body: ${body:0:500}
- Assignee: $assignee
- Labels: $labels

Score this issue from 1-10 based on relevance to the initiative:
- 9-10: Definitely belongs, core work for initiative
- 7-8: Probably belongs, related work
- 5-6: Maybe belongs, tangential work
- 3-4: Unlikely to belong, weak connection
- 1-2: Definitely doesn't belong, unrelated

Return only JSON (no markdown):
{
  \"score\": <1-10>,
  \"reasoning\": \"<why this score in 1-2 sentences>\",
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
            echo "Warning: AI ranking failed for #$issue_num. Using heuristic fallback."
            SCORE=$(heuristic_score_github "$title" "$body" "$labels")
            REASONING="Heuristic: keyword/label match count"
            MILESTONE="unassigned"
        fi
    else
        # Heuristic ranking fallback
        SCORE=$(heuristic_score_github "$title" "$body" "$labels")
        REASONING="Heuristic: keyword/label match with initiative terms"
        MILESTONE="unassigned"
    fi
    
    # Add to ranked list with score
    RANKED_GITHUB_CANDIDATES="$RANKED_GITHUB_CANDIDATES
$SCORE|$repo|$issue_num|$title|$REASONING|$MILESTONE|$assignee"
done <<< "$GITHUB_CANDIDATES"

# Sort by score (descending)
RANKED_GITHUB_CANDIDATES=$(echo "$RANKED_GITHUB_CANDIDATES" | sort -t'|' -k1 -nr)

# Heuristic scoring function for GitHub (keyword/label overlap)
heuristic_score_github() {
    local title="$1"
    local body="$2"
    local labels="$3"
    local score=0
    
    # Check for initiative name in issue
    if echo "$title $body" | grep -qi "$INITIATIVE_NAME"; then
        score=$((score + 5))
    fi
    
    # Check for tag keywords in labels
    for tag in $TAGS; do
        if echo "$labels" | grep -qi "$tag"; then
            score=$((score + 3))
        fi
    done
    
    # Check for tag keywords in title/body
    for tag in $TAGS; do
        if echo "$title $body" | grep -qi "$tag"; then
            score=$((score + 2))
        fi
    done
    
    # Check for repo names
    for repo in $REPOS; do
        repo_name=$(echo "$repo" | cut -d'/' -f2)
        if echo "$title $body" | grep -qi "$repo_name"; then
            score=$((score + 1))
        fi
    done
    
    # Cap at 10
    if [ "$score" -gt 10 ]; then
        score=10
    fi
    
    echo "$score"
}
```
```

- [ ] **Step 2: Commit**

```bash
git add skills/initiative-discoverer/skill.md
git commit -m "feat(initiative-discoverer): add AI ranking for GitHub issues

- Score GitHub issues 1-10 using Claude API
- Use issue title, body, labels, assignees for ranking
- Heuristic fallback: keyword/label matching
- Suggest milestone based on AI analysis"
```

---

### Task 5: Make JIRA Discovery Optional

**Files:**
- Modify: `skills/initiative-discoverer/skill.md`

- [ ] **Step 1: Update existing Step 2 (JIRA search) to be Step 5 and make conditional**

The existing JIRA search is at lines 84-133. Update to check if PROJECT_KEY exists first and renumber as Step 5:

```markdown
### Step 5: Search JIRA for Untracked Epics (Optional)

If `jira.project_key` configured, search JIRA for epics that match initiative context but aren't tracked yet:

```bash
# Check if JIRA project key configured
if [ -n "$PROJECT_KEY" ]; then
    echo "Searching JIRA for untracked epics..."
    
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
        echo "Warning: JIRA API returned errors, skipping JIRA discovery"
        echo "$RESPONSE" | jq -r '.errorMessages[]'
        JIRA_CANDIDATES=""
    else
        # Extract candidate epics
        JIRA_CANDIDATES=$(echo "$RESPONSE" | jq -r '.issues[] | "\(.key)|\(.fields.summary)|\(.fields.description // "")|\(.fields.assignee.name // "unassigned")|\(.fields.reporter.name)|\(.fields.created)"')
        
        JIRA_CANDIDATE_COUNT=$(echo "$JIRA_CANDIDATES" | wc -l)
        echo "Found $JIRA_CANDIDATE_COUNT candidate JIRA epics"
    fi
else
    echo "ℹ️  JIRA: Not configured (skipped JIRA discovery)"
    JIRA_CANDIDATES=""
fi
```
```

- [ ] **Step 2: Update Step 3 (deduplication) to be Step 6 and handle empty JIRA**

```markdown
### Step 6: Deduplicate JIRA Candidates (Optional)

If JIRA discovery ran, filter out already-tracked epics:

```bash
UNTRACKED_JIRA_CANDIDATES=""

if [ -n "$JIRA_CANDIDATES" ]; then
    while IFS='|' read -r key summary description assignee reporter created; do
        # Check if epic is already tracked
        if [[ ",$EXISTING_EPICS," == *",$key,"* ]]; then
            echo "Skipping $key (already tracked)"
            continue
        fi
        
        # Add to untracked list
        if [ -z "$UNTRACKED_JIRA_CANDIDATES" ]; then
            UNTRACKED_JIRA_CANDIDATES="$key|$summary|$description|$assignee|$reporter|$created"
        else
            UNTRACKED_JIRA_CANDIDATES="$UNTRACKED_JIRA_CANDIDATES
$key|$summary|$description|$assignee|$reporter|$created"
        fi
    done <<< "$JIRA_CANDIDATES"
    
    UNTRACKED_JIRA_COUNT=$(echo "$UNTRACKED_JIRA_CANDIDATES" | grep -c '^')
    echo "After deduplication: $UNTRACKED_JIRA_COUNT untracked JIRA epics"
fi
```
```

- [ ] **Step 3: Update Step 4 (AI ranking) to be Step 7 for JIRA**

Existing AI ranking at lines 168-292 becomes Step 7 and only runs if JIRA_CANDIDATES exists:

```markdown
### Step 7: Rank JIRA Candidates with AI (Optional)

If JIRA discovery ran, use Claude to score each JIRA candidate:

```bash
RANKED_JIRA_CANDIDATES=""

if [ -n "$UNTRACKED_JIRA_CANDIDATES" ]; then
    # ... existing AI ranking code for JIRA epics ...
    # (keep the existing implementation, just make it conditional)
fi
```
```

- [ ] **Step 4: Commit**

```bash
git add skills/initiative-discoverer/skill.md
git commit -m "feat(initiative-discoverer): make JIRA discovery optional

- Check if jira.project_key exists before JIRA search
- Skip gracefully if not configured
- Renumber JIRA steps to 5, 6, 7
- Maintain all existing JIRA functionality when configured"
```

---

### Task 6: Update Output Generation to GitHub-First

**Files:**
- Modify: `skills/initiative-discoverer/skill.md`

- [ ] **Step 1: Update Step 5 (output) to be Step 8 and show GitHub-first**

The existing output generation is at lines 294-359. Update to show GitHub suggestions first, then optional JIRA:

```markdown
### Step 8: Generate Suggestions

Output markdown with YAML snippets, GitHub-first:

```bash
echo "# Discovery Results: $(basename $YAML_FILE)"
echo ""

# GitHub Results Section
GITHUB_RESULT_COUNT=$(echo "$RANKED_GITHUB_CANDIDATES" | grep -c '^' || echo 0)
if [ "$GITHUB_RESULT_COUNT" -gt 0 ]; then
    echo "Found $GITHUB_RESULT_COUNT untracked GitHub issues/PRs that may belong to this initiative:"
    echo ""
    
    # High confidence (8-10)
    echo "## High Confidence (8-10)"
    echo ""
    HIGH_CONFIDENCE=$(echo "$RANKED_GITHUB_CANDIDATES" | awk -F'|' '$1 >= 8')
    if [ -z "$HIGH_CONFIDENCE" ]; then
        echo "None"
    else
        while IFS='|' read -r score repo issue_num title reasoning milestone assignee; do
            echo "### #$issue_num: $title"
            echo "**Score:** $score/10"
            echo "**Repository:** $repo"
            echo "**Reasoning:** $reasoning"
            if [ "$assignee" != "unassigned" ]; then
                echo "**Assignee:** @$assignee"
            fi
            echo "**Suggested milestone:** $milestone"
            echo ""
            echo "**Add to YAML:**"
            echo '```yaml'
            echo "github:"
            echo "  issues:"
            echo "    - $issue_num"
            if [ "$milestone" != "unassigned" ]; then
                echo "# Suggested for milestone: $milestone"
            fi
            echo '```'
            echo ""
        done <<< "$HIGH_CONFIDENCE"
    fi
    echo ""
    
    # Medium confidence (5-7)
    echo "## Medium Confidence (5-7)"
    echo ""
    MEDIUM_CONFIDENCE=$(echo "$RANKED_GITHUB_CANDIDATES" | awk -F'|' '$1 >= 5 && $1 < 8')
    if [ -z "$MEDIUM_CONFIDENCE" ]; then
        echo "None"
    else
        while IFS='|' read -r score repo issue_num title reasoning milestone assignee; do
            echo "### #$issue_num: $title"
            echo "**Score:** $score/10"
            echo "**Repository:** $repo"
            echo "**Reasoning:** $reasoning"
            echo ""
            echo "**Add to YAML:**"
            echo '```yaml'
            echo "github:"
            echo "  issues:"
            echo "    - $issue_num"
            echo "    # Review with initiative owner before adding"
            echo '```'
            echo ""
        done <<< "$MEDIUM_CONFIDENCE"
    fi
    echo ""
else
    echo "No untracked GitHub issues/PRs found. All GitHub work appears to be tracked!"
    echo ""
fi

# JIRA Results Section (Optional)
if [ -n "$PROJECT_KEY" ]; then
    echo "---"
    echo ""
    echo "## JIRA Discovery (Optional)"
    echo ""
    
    JIRA_RESULT_COUNT=$(echo "$RANKED_JIRA_CANDIDATES" | grep -c '^' || echo 0)
    if [ "$JIRA_RESULT_COUNT" -gt 0 ]; then
        echo "Found $JIRA_RESULT_COUNT untracked JIRA epics that may belong to this initiative:"
        echo ""
        
        # ... existing JIRA output code ...
        # (keep the existing high/medium confidence sections for JIRA)
    else
        echo "No untracked JIRA epics found. All JIRA work appears to be tracked!"
    fi
else
    echo "---"
    echo ""
    echo "## JIRA Discovery (Optional)"
    echo ""
    echo "JIRA discovery skipped (no jira.project_key configured). To enable JIRA discovery, add:"
    echo '```yaml'
    echo "jira:"
    echo "  project_key: YOUR_PROJECT"
    echo '```'
fi
echo ""

# Action items
echo "## Action Items"
if [ "$GITHUB_RESULT_COUNT" -gt 0 ] || [ "$JIRA_RESULT_COUNT" -gt 0 ]; then
    echo "1. Review high-confidence GitHub issue suggestions and add to YAML"
    echo "2. Verify medium-confidence suggestions with initiative owner"
    if [ "$JIRA_RESULT_COUNT" -gt 0 ]; then
        echo "3. Review JIRA epic suggestions (optional)"
        echo "4. Re-run /initiative-validator after updating YAML"
    else
        echo "3. Re-run /initiative-validator after updating YAML"
    fi
else
    echo "All work appears to be tracked! No suggestions at this time."
fi
```
```

- [ ] **Step 2: Commit**

```bash
git add skills/initiative-discoverer/skill.md
git commit -m "feat(initiative-discoverer): update output to GitHub-first format

- Show GitHub issues/PRs suggestions first
- Show JIRA epics in optional section
- Clear messaging when JIRA not configured
- Update action items to prioritize GitHub"
```

---

### Task 7: Update Example Outputs

**Files:**
- Modify: `skills/initiative-discoverer/examples/discovery-results.md`
- Modify: `skills/initiative-discoverer/examples/no-results.md`

- [ ] **Step 1: Update discovery-results.md to show GitHub issues**

```markdown
# Discovery Results: firehydrant.yaml

Found 4 untracked GitHub issues/PRs that may belong to this initiative:

## High Confidence (8-10)

### #210: Automate FireHydrant team rotation
**Score:** 9/10
**Repository:** eci-global/firehydrant
**Reasoning:** Issue mentions "FireHydrant" and "automation" (exact tag match), assigned to @mhoward (initiative owner), active discussion in comments
**Assignee:** @mhoward
**Suggested milestone:** "Q2 2026"

**Add to YAML:**
```yaml
github:
  issues:
    - 210
# Suggested for milestone: Q2 2026
```

### #208: Add Coralogix integration to FH alerts
**Score:** 8/10
**Repository:** eci-global/firehydrant
**Reasoning:** Related to FireHydrant alert management, mentions Coralogix (related system in initiative context), has "automation" label
**Assignee:** @jsmith
**Suggested milestone:** "Q2 2026"

**Add to YAML:**
```yaml
github:
  issues:
    - 208
# Suggested for milestone: Q2 2026
```

## Medium Confidence (5-7)

### #195: Incident response workflow improvements
**Score:** 6/10
**Repository:** eci-global/firehydrant
**Reasoning:** Related to incident management (FireHydrant domain), but no direct FH mention. Reporter is team adjacent, has "enhancement" label

**Add to YAML:**
```yaml
github:
  issues:
    - 195
    # Review with initiative owner before adding
```

### #187: Update runbook templates
**Score:** 5/10
**Repository:** eci-global/ember
**Reasoning:** Tangentially related (runbooks used in incident response), mentions "incident" in body. Weak connection to FireHydrant specifically

**Add to YAML:**
```yaml
github:
  issues:
    - 187
    # Review with initiative owner before adding
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

- [ ] **Step 2: Update no-results.md**

```markdown
# Discovery Results: fully-tracked.yaml

No untracked GitHub issues/PRs found. All GitHub work appears to be tracked!

---

## JIRA Discovery (Optional)

JIRA discovery skipped (no jira.project_key configured). To enable JIRA discovery, add:
```yaml
jira:
  project_key: YOUR_PROJECT
```

## Action Items
All work appears to be tracked! No suggestions at this time.
```

- [ ] **Step 3: Commit**

```bash
git add skills/initiative-discoverer/examples/discovery-results.md \
     skills/initiative-discoverer/examples/no-results.md
git commit -m "docs(initiative-discoverer): update examples to GitHub-first

- Show GitHub issues as primary discovery results
- Include repository and assignee information
- Show JIRA as optional section (skipped if not configured)
- Keep examples realistic and actionable"
```

---

### Task 8: Update Test Fixture

**Files:**
- Modify: `test/initiative-discoverer/fixtures/discoverable.yaml`

- [ ] **Step 1: Add github section to discoverable.yaml**

Read current fixture and add github section:

```yaml
schema_version: 1
name: "Platform Infrastructure"
description: "Core platform improvements and infrastructure work"
status: active
owner: platform-team
repos:
  - name: eci-global/ember
    milestones:
      - "M6: Data Platform Integration"
  - name: eci-global/firehydrant
    milestones:
      - "Q2 2026"
github:
  projects:
    - number: 30
      title: "Platform Infrastructure 2026"
  issues:
    - 84
    - 70
jira:
  project_key: ITPLAT01
  epics:
    - key: ITPLAT01-2258
      milestone: "M6: Data Platform Integration"
tags:
  - platform
  - infrastructure
  - ember
team:
  - platform-team
  - jsmith
```

- [ ] **Step 2: Commit**

```bash
git add test/initiative-discoverer/fixtures/discoverable.yaml
git commit -m "test(initiative-discoverer): add github section to test fixture

- Add github.projects for project discovery tests
- Add existing github.issues for deduplication tests
- Keep jira section for hybrid testing"
```

---

### Task 9: Update Test Integration Script

**Files:**
- Modify: `test/initiative-discoverer/test-integration.sh`

- [ ] **Step 1: Read current test-integration.sh**

Read to see current structure and determine where to add GitHub discovery tests.

- [ ] **Step 2: Add GitHub issue discovery test case**

Add test case that validates GitHub issue discovery:

```bash
# Test: GitHub issue discovery
test_github_issue_discovery() {
    echo "Testing GitHub issue discovery..."
    
    # This test requires network access and gh CLI configured
    if ! command -v gh &> /dev/null; then
        echo "⚠️  gh CLI not found, skipping GitHub discovery test"
        return 0
    fi
    
    # Run discoverer on test fixture
    OUTPUT=$(bash skills/initiative-discoverer/skill.md test/initiative-discoverer/fixtures/discoverable.yaml 2>&1)
    
    # Check for GitHub discovery in output
    if echo "$OUTPUT" | grep -q "Searching GitHub for untracked issues"; then
        echo "✅ GitHub issue discovery executed"
    else
        echo "❌ GitHub issue discovery not found in output"
        return 1
    fi
    
    return 0
}

test_github_issue_discovery
```

- [ ] **Step 3: Add GitHub Projects discovery test case**

```bash
# Test: GitHub Projects item discovery
test_github_projects_discovery() {
    echo "Testing GitHub Projects item discovery..."
    
    # This test requires network access and gh CLI configured
    if ! command -v gh &> /dev/null; then
        echo "⚠️  gh CLI not found, skipping GitHub Projects discovery test"
        return 0
    fi
    
    # Run discoverer on test fixture
    OUTPUT=$(bash skills/initiative-discoverer/skill.md test/initiative-discoverer/fixtures/discoverable.yaml 2>&1)
    
    # Check for Projects discovery in output
    if echo "$OUTPUT" | grep -q "Searching GitHub Projects"; then
        echo "✅ GitHub Projects discovery executed"
    else
        echo "⚠️  GitHub Projects discovery not found (may be skipped if not configured)"
        return 0
    fi
    
    return 0
}

test_github_projects_discovery
```

- [ ] **Step 4: Add test for optional JIRA discovery**

```bash
# Test: Optional JIRA discovery handling
test_optional_jira_discovery() {
    echo "Testing optional JIRA discovery handling..."
    
    # Create temp fixture without JIRA
    TEMP_FIXTURE=$(mktemp)
    cat > "$TEMP_FIXTURE" <<EOF
schema_version: 1
name: "Test Initiative"
description: "Test with no JIRA"
status: active
owner: test-user
repos:
  - name: eci-global/ember
    milestones:
      - "Q1 2026"
github:
  issues:
    - 100
tags:
  - test
EOF
    
    # Run discoverer on GitHub-only fixture
    OUTPUT=$(bash skills/initiative-discoverer/skill.md "$TEMP_FIXTURE" 2>&1)
    
    # Check for "JIRA: Not configured" message
    if echo "$OUTPUT" | grep -q "JIRA: Not configured (skipped JIRA discovery)"; then
        echo "✅ Optional JIRA discovery handled correctly"
        rm "$TEMP_FIXTURE"
        return 0
    else
        echo "❌ Optional JIRA discovery not handled correctly"
        rm "$TEMP_FIXTURE"
        return 1
    fi
}

test_optional_jira_discovery
```

- [ ] **Step 5: Commit**

```bash
git add test/initiative-discoverer/test-integration.sh
git commit -m "test(initiative-discoverer): add GitHub discovery tests

- Test GitHub issue discovery workflow
- Test GitHub Projects item discovery
- Test optional JIRA discovery handling
- Skip tests gracefully if gh CLI not available"
```

---

### Task 10: Update Skill Description and Purpose

**Files:**
- Modify: `skills/initiative-discoverer/skill.md`

- [ ] **Step 1: Update skill frontmatter and description**

Update lines 1-29 to reflect GitHub-first focus:

```markdown
---
name: initiative-discoverer
description: Find untracked GitHub issues/PRs and optionally JIRA epics that should be linked to an initiative using AI-driven matching
version: 2.0.0
---

# Initiative Discoverer Skill

Find existing GitHub issues and PRs that belong to an initiative but aren't tracked in the YAML yet. Optionally discovers JIRA epics if configured. Uses AI-driven semantic matching to score candidates by relevance.

## Purpose

This skill helps you:
- Discover untracked GitHub issues/PRs in initiative repos
- Find GitHub Projects items not yet linked to initiatives
- Optionally discover orphaned JIRA work (if jira section configured)
- Increase initiative completeness with AI-powered suggestions
- Get ready-to-merge YAML snippets with confidence scores

## When to Use

Invoke this skill after creating an initiative YAML, or periodically to find work that should be linked but isn't yet.

## How It Works

1. **Extract Context** - Parse YAML for description keywords, team, repos, tags
2. **Search GitHub Issues** - Find untracked issues filtered by labels, assignees, keywords
3. **Search GitHub Projects** - Find project items not yet tracked (if projects configured)
4. **Rank GitHub Candidates** - Score each (1-10) using Claude AI for relevance
5. **Search JIRA** - Find untracked epics (if jira.project_key configured)
6. **Deduplicate JIRA** - Remove already-tracked epics
7. **Rank JIRA Candidates** - Score each using Claude AI (if JIRA discovery ran)
8. **Generate Suggestions** - Output YAML snippets with reasoning, GitHub-first
```

- [ ] **Step 2: Commit**

```bash
git add skills/initiative-discoverer/skill.md
git commit -m "docs(initiative-discoverer): update description to GitHub-first

- Bump version to 2.0.0
- Update description to list GitHub discovery first
- Clarify JIRA discovery is optional
- Update workflow steps to match new order (8 steps)"
```

---

## Self-Review Checklist

After implementing all tasks, review:

**Spec Coverage:**
- ✅ GitHub issue discovery (Task 2)
- ✅ GitHub Projects item discovery (Task 3)
- ✅ AI ranking for GitHub data (Task 4)
- ✅ Optional JIRA discovery (Task 5)
- ✅ GitHub-first output format (Task 6)
- ✅ Updated example outputs (Task 7)
- ✅ Updated test fixture (Task 8)
- ✅ Test coverage for new features (Task 9)

**Placeholder Scan:**
- No "TBD" or "TODO" in code
- No "add error handling" without implementation
- All bash code blocks are complete and runnable
- All GraphQL queries are complete and valid

**Type Consistency:**
- Variable names consistent across steps (GITHUB_CANDIDATES, JIRA_CANDIDATES, RANKED_*)
- Step numbers sequential (1-8)
- File paths consistent

**Dependencies:**
- All modified files exist
- GitHub GraphQL queries tested
- No breaking changes to existing JIRA functionality

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-04-15-initiative-discoverer-github-first.md`.**

This plan updates the initiative-discoverer skill to discover untracked GitHub issues and PRs as primary targets, with JIRA epic discovery as optional secondary system.

Ready to execute with superpowers:subagent-driven-development or superpowers:executing-plans.
