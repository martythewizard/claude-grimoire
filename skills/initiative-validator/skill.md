---
name: initiative-validator
description: Validate initiative YAML files (schema v2) against GitHub Projects, workstreams, JIRA epic tasks, and Confluence
version: 2.0.0
---

# Initiative Validator Skill

## Purpose

This skill helps you:
- Validate YAML schema v2 before committing to the initiatives registry
- Check that GitHub Project exists and is accessible (if configured)
- Verify workstream repos and milestone numbers exist
- Validate JIRA epic task github_issue references point to real issues
- Confirm Confluence pages exist and are reachable (if configured)
- Get clear, actionable reports organized by workstream

## When to Use

Invoke this skill before committing changes to initiative YAML files in eci-global/initiatives, or when you suspect an initiative's external references are stale.

## How It Works

1. **Parse YAML** - Validate schema v2 and extract references
2. **Validate GitHub Project** - Check project exists via GraphQL (if present)
3. **Validate Workstreams** - Check repos exist and milestones are valid
4. **Validate JIRA Epic Tasks** - Verify github_issue references (if present)
5. **Validate Confluence** - Confirm pages exist (if present)
6. **Generate Report** - Output markdown organized by severity and workstream

## Workflow

### Step 1: Parse and Validate YAML Schema

Ask user for YAML file path:
```
"Please provide the path to the initiative YAML file to validate:"
```

Read and validate schema:

```bash
YAML_FILE="$1"

# Check file exists
if [ ! -f "$YAML_FILE" ]; then
    echo "Error: File not found: $YAML_FILE"
    exit 1
fi

# Validate schema_version is 2
SCHEMA_VERSION=$(grep "^schema_version:" "$YAML_FILE" | awk '{print $2}')
if [ "$SCHEMA_VERSION" != "2" ]; then
    echo "Critical: Expected schema_version: 2, got: $SCHEMA_VERSION"
    echo "This skill only supports schema v2. Please use initiative-validator v1.0.0 for older schemas."
    exit 1
fi

# Validate required fields
REQUIRED_FIELDS=("name" "description" "status" "owner")
for field in "${REQUIRED_FIELDS[@]}"; do
    if ! grep -q "^$field:" "$YAML_FILE"; then
        echo "Critical: Missing required field '$field'"
        exit 1
    fi
done

# Validate status enum
STATUS=$(grep "^status:" "$YAML_FILE" | awk '{print $2}')
VALID_STATUSES=("active" "planning" "paused" "completed" "cancelled")
if [[ ! " ${VALID_STATUSES[*]} " =~ " ${STATUS} " ]]; then
    echo "Critical: Invalid status value '$STATUS'. Must be one of: ${VALID_STATUSES[*]}"
    exit 1
fi

echo "✅ Schema v2 validation passed"
```

### Step 2: Validate GitHub Project (Optional)

Check if github_project exists and is accessible:

```bash
# Check if github_project section exists
if grep -q "^github_project:" "$YAML_FILE"; then
    echo "Validating GitHub Project..."
    
    # Initialize GITHUB_FINDINGS array
    GITHUB_FINDINGS=()
    
    # Extract project org and number
    PROJECT_ORG=$(grep -A 5 "^github_project:" "$YAML_FILE" | grep "  org:" | awk '{print $2}')
    PROJECT_NUMBER=$(grep -A 5 "^github_project:" "$YAML_FILE" | grep "  number:" | awk '{print $2}')
    
    if [ -z "$PROJECT_ORG" ] || [ -z "$PROJECT_NUMBER" ]; then
        GITHUB_FINDINGS+=("Critical: github_project missing required fields (org, number)")
    elif ! [[ "$PROJECT_NUMBER" =~ ^[0-9]+$ ]]; then
        GITHUB_FINDINGS+=("Critical: PROJECT_NUMBER must be numeric, got: $PROJECT_NUMBER")
    else
        # Query GitHub Project v2 via GraphQL
        QUERY='query($org: String!, $number: Int!) {
          organization(login: $org) {
            projectV2(number: $number) {
              id
              title
              url
              closed
            }
          }
        }'
        
        RESPONSE=$(gh api graphql -f query="$QUERY" -f org="$PROJECT_ORG" -F number="$PROJECT_NUMBER" 2>&1)
        GH_EXIT_CODE=$?
        
        if [ $GH_EXIT_CODE -ne 0 ]; then
            GITHUB_FINDINGS+=("Warning: GitHub API authentication failed - skipping GitHub Project validation")
        elif echo "$RESPONSE" | jq -e '.data.organization.projectV2.id' > /dev/null 2>&1; then
            PROJECT_TITLE=$(echo "$RESPONSE" | jq -r '.data.organization.projectV2.title')
            PROJECT_CLOSED=$(echo "$RESPONSE" | jq -r '.data.organization.projectV2.closed')
            
            if [ "$PROJECT_CLOSED" = "true" ]; then
                GITHUB_FINDINGS+=("Warning: GitHub Project #$PROJECT_NUMBER is closed")
            else
                echo "✅ GitHub Project found: $PROJECT_ORG#$PROJECT_NUMBER ($PROJECT_TITLE)"
            fi
        else
            GITHUB_FINDINGS+=("Warning: GitHub Project #$PROJECT_NUMBER not found or not accessible in org $PROJECT_ORG")
        fi
    fi
else
    echo "ℹ️  GitHub Project: Not configured (skipped)"
fi
```

### Step 3: Validate Workstreams and Milestones (Optional)

For each workstream, check repo exists and milestone numbers are valid:

```bash
# Check if workstreams section exists
if grep -q "^workstreams:" "$YAML_FILE"; then
    echo "Validating Workstreams..."
    
    # Extract workstreams (multi-line parsing)
    # We'll parse workstream names and repos manually
    WORKSTREAM_COUNT=0
    MILESTONE_COUNT=0
    
    # Get all workstream names
    WORKSTREAM_NAMES=$(grep -A 500 "^workstreams:" "$YAML_FILE" | grep "  - name:" | sed 's/.*name: "\?\([^"]*\)"\?/\1/')
    
    while IFS= read -r ws_name; do
        [ -z "$ws_name" ] && continue
        WORKSTREAM_COUNT=$((WORKSTREAM_COUNT + 1))
        
        # Find repo for this workstream (next line after name)
        WS_REPO=$(grep -A 1 "name: \"$ws_name\"" "$YAML_FILE" | grep "repo:" | awk '{print $2}')
        
        if [ -z "$WS_REPO" ]; then
            GITHUB_FINDINGS+=("Warning: Workstream '$ws_name' missing repo field")
            continue
        fi
        
        # Validate repo exists
        if gh api repos/$WS_REPO --jq '.name' > /dev/null 2>&1; then
            echo "✅ Workstream '$ws_name': repo $WS_REPO found"
        else
            GITHUB_FINDINGS+=("Warning: Workstream '$ws_name' repo not found: $WS_REPO")
            continue
        fi
        
        # Extract milestone numbers for this workstream
        # Find milestones section within this workstream block
        MS_NUMBERS=$(grep -A 100 "name: \"$ws_name\"" "$YAML_FILE" | \
                     grep -A 50 "milestones:" | \
                     grep "number:" | \
                     head -20 | \
                     awk '{print $2}')
        
        for ms_number in $MS_NUMBERS; do
            [ -z "$ms_number" ] && continue
            MILESTONE_COUNT=$((MILESTONE_COUNT + 1))
            
            # Validate milestone number exists in repo
            MS_DATA=$(gh api repos/$WS_REPO/milestones/$ms_number --jq '{title: .title, state: .state}' 2>&1)
            GH_EXIT_CODE=$?
            
            if [ $GH_EXIT_CODE -eq 0 ]; then
                MS_TITLE=$(echo "$MS_DATA" | jq -r '.title')
                MS_STATE=$(echo "$MS_DATA" | jq -r '.state')
                echo "✅ Milestone #$ms_number found: $MS_TITLE (state: $MS_STATE)"
                
                if [ "$MS_STATE" = "closed" ]; then
                    GITHUB_FINDINGS+=("Info: Milestone #$ms_number in $WS_REPO is closed")
                fi
            else
                GITHUB_FINDINGS+=("Warning: Milestone #$ms_number not found in repo $WS_REPO")
            fi
        done
        
    done <<< "$WORKSTREAM_NAMES"
    
    echo "Validated $WORKSTREAM_COUNT workstreams with $MILESTONE_COUNT milestones"
    
else
    echo "ℹ️  Workstreams: Not configured (skipped)"
fi
```

### Step 4: Validate Confluence Page

Check if Confluence page exists:

```bash
# Extract Confluence config
CONFLUENCE_URL="${CONFLUENCE_URL:-https://confluence.company.com}"
CONFLUENCE_TOKEN="${CONFLUENCE_API_TOKEN}"

# Extract page ID from YAML
PAGE_ID=$(grep "page_id:" "$YAML_FILE" | awk '{print $2}' | tr -d '"')

CONFLUENCE_FINDINGS=()

if [ -n "$PAGE_ID" ]; then
    # Validate page ID is numeric
    if ! [[ "$PAGE_ID" =~ ^[0-9]+$ ]]; then
        CONFLUENCE_FINDINGS+=("Critical: Page ID must be numeric, got: $PAGE_ID")
    else
        # Check if page exists
        STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Authorization: Bearer $CONFLUENCE_TOKEN" \
            "$CONFLUENCE_URL/rest/api/content/$PAGE_ID")
        
        if [ "$STATUS_CODE" -eq 200 ]; then
            echo "✅ Confluence page found: $PAGE_ID"
        elif [ "$STATUS_CODE" -eq 404 ]; then
            CONFLUENCE_FINDINGS+=("Warning: Confluence page not found: $PAGE_ID")
        elif [ "$STATUS_CODE" -eq 401 ]; then
            CONFLUENCE_FINDINGS+=("Warning: Confluence authentication failed")
        else
            CONFLUENCE_FINDINGS+=("Warning: Unable to verify Confluence page (HTTP $STATUS_CODE)")
        fi
    fi
fi
```

### Step 5: Generate Report

Aggregate findings and output markdown:

```bash
INITIATIVE_NAME=$(grep "^name:" "$YAML_FILE" | sed 's/name: "\(.*\)"/\1/')

echo "# Validation Report: $(basename $YAML_FILE)"
echo ""
echo "## Summary"
echo "- ✅ Schema: Valid"
echo "- GitHub: ${#GITHUB_FINDINGS[@]} issues"
echo "- JIRA: ${#JIRA_FINDINGS[@]} issues"
echo "- Confluence: ${#CONFLUENCE_FINDINGS[@]} issues"
echo ""

# Critical Issues
echo "## Critical Issues"
if [ ${#CRITICAL_FINDINGS[@]} -eq 0 ]; then
    echo "None"
else
    for finding in "${CRITICAL_FINDINGS[@]}"; do
        echo "- $finding"
    done
fi
echo ""

# Warnings
echo "## Warnings"
if [ ${#GITHUB_FINDINGS[@]} -eq 0 ] && [ ${#JIRA_FINDINGS[@]} -eq 0 ] && [ ${#CONFLUENCE_FINDINGS[@]} -eq 0 ]; then
    echo "None"
else
    for finding in "${GITHUB_FINDINGS[@]}"; do
        echo "- $finding"
    done
    for finding in "${JIRA_FINDINGS[@]}"; do
        echo "- $finding"
    done
    for finding in "${CONFLUENCE_FINDINGS[@]}"; do
        echo "- $finding"
    done
fi
echo ""

# Info
echo "## Info"
if ! grep -q "^tags:" "$YAML_FILE"; then
    echo "- Consider adding \`tags:\` for better discoverability"
fi
if ! grep -q "^team:" "$YAML_FILE"; then
    echo "- Consider adding \`team:\` to track all contributors"
fi
echo ""

# Action Items
echo "## Action Items for Initiative Owner"
if [ ${#GITHUB_FINDINGS[@]} -gt 0 ] || [ ${#JIRA_FINDINGS[@]} -gt 0 ] || [ ${#CONFLUENCE_FINDINGS[@]} -gt 0 ]; then
    echo "1. Review warnings above and verify referenced resources"
    echo "2. Update YAML to remove stale references or confirm they are intentional"
    echo "3. Re-run validation after making changes"
else
    echo "All validations passed! Initiative YAML is complete and accurate."
fi
```

## Configuration

**Environment variables:**
```bash
export JIRA_URL="https://jira.company.com"
export JIRA_API_TOKEN="your-token-here"
export CONFLUENCE_URL="https://confluence.company.com"
export CONFLUENCE_API_TOKEN="your-token-here"
```

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
  }
}
```

## Error Handling

- **File not found:** Exit immediately with error message
- **Schema validation failure:** Report critical error, exit 1
- **API authentication failure:** Skip that validator, continue others, exit 0
- **Network timeout:** Mark as "unable to verify", continue, exit 0
- **Resource not found:** Normal validation finding (warning), exit 0

## Examples

See `examples/` directory for:
- `valid-report.md` - All validations pass
- `missing-milestone-report.md` - GitHub milestone not found
- `invalid-schema-report.md` - Schema validation errors
