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

### Step 2: Validate GitHub Milestones

For each repo in `repos:`, check if milestones exist:

```bash
# Extract repos from YAML (assumes yq is available, or parse manually)
REPOS=$(grep -A 100 "^repos:" "$YAML_FILE" | grep "  - name:" | awk '{print $3}')

GITHUB_FINDINGS=()

for repo in $REPOS; do
    # Extract milestones for this repo
    MILESTONES=$(grep -A 50 "name: $repo" "$YAML_FILE" | grep "    - \"" | sed 's/.*"\(.*\)".*/\1/')
    
    for milestone in $MILESTONES; do
        # Check if milestone exists via gh CLI
        if gh api repos/$repo/milestones --jq ".[] | select(.title == \"$milestone\") | .title" | grep -q "$milestone"; then
            echo "✅ GitHub milestone found: $repo -> $milestone"
        else
            GITHUB_FINDINGS+=("Warning: Milestone '$milestone' not found in repo $repo")
        fi
    done
done

# Check for auth errors
if [ $? -ne 0 ]; then
    GITHUB_FINDINGS+=("Warning: GitHub API authentication failed - skipping GitHub validation")
fi
```

### Step 3: Validate JIRA Epics

For each epic in `jira.epics:`, verify accessibility:

```bash
# Extract JIRA URL from config
JIRA_URL="${JIRA_URL:-https://jira.company.com}"
JIRA_TOKEN="${JIRA_API_TOKEN}"

# Extract epic keys from YAML
EPIC_KEYS=$(grep -A 50 "^jira:" "$YAML_FILE" | grep "  - key:" | awk '{print $3}')

JIRA_FINDINGS=()

for epic_key in $EPIC_KEYS; do
    # Validate epic key format (PROJECT-123)
    if ! [[ "$epic_key" =~ ^[A-Z]+-[0-9]+$ ]]; then
        JIRA_FINDINGS+=("Critical: Malformed epic key '$epic_key' (expected format: PROJECT-123)")
        continue
    fi
    
    # Check if epic exists
    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $JIRA_TOKEN" \
        "$JIRA_URL/rest/api/3/issue/$epic_key")
    
    if [ "$STATUS_CODE" -eq 200 ]; then
        echo "✅ JIRA epic found: $epic_key"
    elif [ "$STATUS_CODE" -eq 404 ]; then
        JIRA_FINDINGS+=("Warning: JIRA epic not found: $epic_key")
    elif [ "$STATUS_CODE" -eq 401 ]; then
        JIRA_FINDINGS+=("Warning: JIRA authentication failed - skipping remaining JIRA validation")
        break
    else
        JIRA_FINDINGS+=("Warning: Unable to verify JIRA epic $epic_key (HTTP $STATUS_CODE)")
    fi
done
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
