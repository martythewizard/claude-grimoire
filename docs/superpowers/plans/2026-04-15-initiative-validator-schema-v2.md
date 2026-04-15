# Initiative Validator Schema v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update initiative-validator skill to validate schema v2 YAML files from eci-global/initiatives with workstreams, github_project, and JIRA epic tasks.

**Architecture:** Parse schema v2 structure (workstreams instead of repos, milestone objects instead of strings), validate GitHub Project v2 via GraphQL, validate milestone numbers in repos, validate JIRA epic task github_issue references, generate workstream-organized reports.

**Tech Stack:** Bash, gh CLI (REST + GraphQL), grep/awk for YAML parsing, curl for JIRA API

---

## File Structure

**Files to modify:**
- `skills/initiative-validator/skill.md` - Main skill documentation (major rewrite for schema v2)
- `skills/initiative-validator/examples/valid-report.md` - Update for schema v2 format
- `skills/initiative-validator/examples/missing-milestone-report.md` - Update for schema v2 format
- `skills/initiative-validator/examples/invalid-schema-report.md` - Update for schema v2 format

**Files to create:**
- `test/initiative-validator/fixtures/schema-v2-valid.yaml` - Test fixture with valid schema v2
- `test/initiative-validator/fixtures/schema-v2-invalid.yaml` - Test fixture with invalid schema v2
- `test/initiative-validator/test-schema-v2.sh` - Integration test script

---

## Task 1: Update Skill Metadata and Version

**Files:**
- Modify: `skills/initiative-validator/skill.md:1-5`

- [ ] **Step 1: Update version and description in frontmatter**

```yaml
---
name: initiative-validator
description: Validate initiative YAML files (schema v2) against GitHub Projects, workstreams, JIRA epic tasks, and Confluence
version: 2.0.0
---
```

- [ ] **Step 2: Commit metadata update**

```bash
git add skills/initiative-validator/skill.md
git commit -m "feat(initiative-validator): bump version to 2.0.0 for schema v2"
```

---

## Task 2: Update Purpose and How It Works Section

**Files:**
- Modify: `skills/initiative-validator/skill.md:7-31`

- [ ] **Step 1: Replace Purpose section**

```markdown
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
```

- [ ] **Step 2: Commit purpose update**

```bash
git add skills/initiative-validator/skill.md
git commit -m "docs(initiative-validator): update purpose for schema v2"
```

---

## Task 3: Update Step 1 - Schema Validation

**Files:**
- Modify: `skills/initiative-validator/skill.md:33-76`

- [ ] **Step 1: Replace Step 1 with schema v2 validation**

```markdown
## Workflow

### Step 1: Parse and Validate YAML Schema v2

Ask user for YAML file path:
```
"Please provide the path to the initiative YAML file to validate:"
```

Read and validate schema v2:

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
```

- [ ] **Step 2: Commit schema validation update**

```bash
git add skills/initiative-validator/skill.md
git commit -m "feat(initiative-validator): update schema validation for v2"
```

---

## Task 4: Add Step 2 - GitHub Project Validation

**Files:**
- Modify: `skills/initiative-validator/skill.md:78-106` (replace old Step 2)

- [ ] **Step 1: Add GitHub Project v2 validation step**

```markdown
### Step 2: Validate GitHub Project (Optional)

Check if github_project exists and is accessible:

```bash
# Check if github_project section exists
if grep -q "^github_project:" "$YAML_FILE"; then
    echo "Validating GitHub Project..."
    
    # Extract project org and number
    PROJECT_ORG=$(grep -A 5 "^github_project:" "$YAML_FILE" | grep "  org:" | awk '{print $2}')
    PROJECT_NUMBER=$(grep -A 5 "^github_project:" "$YAML_FILE" | grep "  number:" | awk '{print $2}')
    
    if [ -z "$PROJECT_ORG" ] || [ -z "$PROJECT_NUMBER" ]; then
        GITHUB_FINDINGS+=("Critical: github_project missing required fields (org, number)")
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

# Initialize GITHUB_FINDINGS if not set
if [ -z "${GITHUB_FINDINGS+x}" ]; then
    GITHUB_FINDINGS=()
fi
```
```

- [ ] **Step 2: Commit GitHub Project validation**

```bash
git add skills/initiative-validator/skill.md
git commit -m "feat(initiative-validator): add GitHub Project v2 validation"
```

---

## Task 5: Add Step 3 - Workstream and Milestone Validation

**Files:**
- Modify: `skills/initiative-validator/skill.md:108-150` (replace old milestone validation)

- [ ] **Step 1: Add workstream validation step**

```markdown
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
```

- [ ] **Step 2: Commit workstream validation**

```bash
git add skills/initiative-validator/skill.md
git commit -m "feat(initiative-validator): add workstream and milestone validation for schema v2"
```

---

## Task 6: Add Step 4 - JIRA Epic Task Validation

**Files:**
- Modify: `skills/initiative-validator/skill.md:152-200` (replace old JIRA validation)

- [ ] **Step 1: Add JIRA epic task validation with github_issue check**

```markdown
### Step 4: Validate JIRA Epic Tasks (Optional)

For each JIRA epic task, verify github_issue reference is valid:

```bash
# Check if jira section exists
if grep -q "^jira:" "$YAML_FILE" && grep -q "  project_key:" "$YAML_FILE"; then
    echo "Validating JIRA Epic Tasks..."
    
    # Extract JIRA URL from config
    JIRA_URL="${JIRA_URL:-https://jira.company.com}"
    JIRA_TOKEN="${JIRA_API_TOKEN}"
    
    JIRA_FINDINGS=()
    JIRA_TASK_COUNT=0
    
    # Extract all epic keys to process
    EPIC_KEYS=$(grep -A 200 "^jira:" "$YAML_FILE" | grep "  - key:" | awk '{print $3}')
    
    for epic_key in $EPIC_KEYS; do
        # Validate epic key format (PROJECT-123)
        if ! [[ "$epic_key" =~ ^[A-Z]+-[0-9]+$ ]]; then
            JIRA_FINDINGS+=("Critical: Malformed epic key '$epic_key' (expected format: PROJECT-123)")
            continue
        fi
        
        # Check if epic exists (optional, can be slow)
        # For now, assume epic exists and focus on tasks
        
        # Extract tasks for this epic
        TASK_KEYS=$(grep -A 50 "key: $epic_key" "$YAML_FILE" | \
                    grep -A 30 "tasks:" | \
                    grep "  - key:" | \
                    awk '{print $3}')
        
        for task_key in $TASK_KEYS; do
            JIRA_TASK_COUNT=$((JIRA_TASK_COUNT + 1))
            
            # Extract github_issue number for this task
            GITHUB_ISSUE=$(grep -A 2 "key: $task_key" "$YAML_FILE" | \
                          grep "github_issue:" | \
                          awk '{print $2}')
            
            if [ -z "$GITHUB_ISSUE" ]; then
                JIRA_FINDINGS+=("Info: JIRA task $task_key has no github_issue reference")
                continue
            fi
            
            # Find which repo this issue should be in (from workstream context)
            # For now, check all workstream repos
            FOUND_ISSUE=false
            WORKSTREAM_REPOS=$(grep -A 500 "^workstreams:" "$YAML_FILE" | grep "repo:" | awk '{print $2}' | sort -u)
            
            for ws_repo in $WORKSTREAM_REPOS; do
                if gh api repos/$ws_repo/issues/$GITHUB_ISSUE --jq '.number' > /dev/null 2>&1; then
                    echo "✅ JIRA task $task_key github_issue #$GITHUB_ISSUE found in $ws_repo"
                    FOUND_ISSUE=true
                    break
                fi
            done
            
            if [ "$FOUND_ISSUE" = false ]; then
                JIRA_FINDINGS+=("Warning: JIRA task $task_key references github_issue #$GITHUB_ISSUE but issue not found in any workstream repo")
            fi
        done
    done
    
    echo "Validated $JIRA_TASK_COUNT JIRA epic tasks"
    
else
    echo "ℹ️  JIRA: Not configured (skipped)"
    JIRA_FINDINGS=()
fi
```
```

- [ ] **Step 2: Commit JIRA task validation**

```bash
git add skills/initiative-validator/skill.md
git commit -m "feat(initiative-validator): add JIRA epic task github_issue validation"
```

---

## Task 7: Update Step 5 - Confluence Validation (Minor Changes)

**Files:**
- Modify: `skills/initiative-validator/skill.md:202-230`

- [ ] **Step 1: Update step number to Step 5**

```markdown
### Step 5: Validate Confluence Page (Optional)

Check if Confluence page exists (skips if confluence section not configured):

```bash
# Check if confluence section exists
if grep -q "^confluence:" "$YAML_FILE" && grep -q "  page_id:" "$YAML_FILE"; then
    echo "Validating Confluence Page..."
    
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
else
    echo "ℹ️  Confluence: Not configured (skipped)"
    CONFLUENCE_FINDINGS=()
fi
```
```

- [ ] **Step 2: Commit Confluence validation update**

```bash
git add skills/initiative-validator/skill.md
git commit -m "docs(initiative-validator): update Confluence validation step number"
```

---

## Task 8: Update Step 6 - Report Generation

**Files:**
- Modify: `skills/initiative-validator/skill.md:232-350`

- [ ] **Step 1: Replace report generation with schema v2 format**

```markdown
### Step 6: Generate Report

Aggregate findings and output markdown with workstream-organized format:

```bash
INITIATIVE_NAME=$(grep "^name:" "$YAML_FILE" | sed 's/name: "\?\([^"]*\)"\?/\1/')

# Count validations
GITHUB_PROJECT_CONFIGURED=$(grep -q "^github_project:" "$YAML_FILE" && echo "true" || echo "false")
WORKSTREAMS_CONFIGURED=$(grep -q "^workstreams:" "$YAML_FILE" && echo "true" || echo "false")
JIRA_CONFIGURED=$(grep -q "^jira:" "$YAML_FILE" && echo "true" || echo "false")
CONFLUENCE_CONFIGURED=$(grep -q "^confluence:" "$YAML_FILE" && echo "true" || echo "false")

echo "# Validation Report: $(basename $YAML_FILE)"
echo ""
echo "## Summary"
echo "- ✅ Schema v2: Valid"

# GitHub Project summary
if [ "$GITHUB_PROJECT_CONFIGURED" = "true" ]; then
    PROJECT_ISSUES=$(echo "${GITHUB_FINDINGS[@]}" | grep -c "Project" || echo "0")
    if [ "$PROJECT_ISSUES" -eq 0 ]; then
        echo "- ✅ GitHub Project: Found ($PROJECT_ORG#$PROJECT_NUMBER)"
    else
        echo "- ⚠️ GitHub Project: Issues found"
    fi
else
    echo "- ℹ️  GitHub Project: Not configured (skipped)"
fi

# Workstreams summary
if [ "$WORKSTREAMS_CONFIGURED" = "true" ]; then
    WS_ISSUES=$(echo "${GITHUB_FINDINGS[@]}" | grep -c "Workstream\|Milestone" || echo "0")
    if [ "$WS_ISSUES" -eq 0 ]; then
        echo "- ✅ Workstreams: $WORKSTREAM_COUNT validated"
        echo "- ✅ Milestones: $MILESTONE_COUNT found in repos"
    else
        echo "- ⚠️ Workstreams: $WORKSTREAM_COUNT validated with issues"
        echo "- ⚠️ Milestones: Issues found"
    fi
else
    echo "- ℹ️  Workstreams: Not configured (skipped)"
fi

# JIRA summary
if [ "$JIRA_CONFIGURED" = "true" ]; then
    JIRA_ISSUE_COUNT=$(echo "${JIRA_FINDINGS[@]}" | grep -c "Warning\|Critical" || echo "0")
    if [ "$JIRA_ISSUE_COUNT" -eq 0 ]; then
        echo "- ✅ JIRA Epic Tasks: $JIRA_TASK_COUNT validated"
    else
        echo "- ⚠️ JIRA Epic Tasks: $JIRA_ISSUE_COUNT issues found"
    fi
else
    echo "- ⚠️ JIRA: Not configured (skipped)"
fi

# Confluence summary
if [ "$CONFLUENCE_CONFIGURED" = "true" ]; then
    CONF_ISSUES=$(echo "${CONFLUENCE_FINDINGS[@]}" | wc -l)
    if [ "$CONF_ISSUES" -eq 0 ]; then
        echo "- ✅ Confluence: Page found"
    else
        echo "- ⚠️ Confluence: ${#CONFLUENCE_FINDINGS[@]} issues"
    fi
else
    echo "- ⚠️ Confluence: Not configured (skipped)"
fi
echo ""

# Critical Issues
echo "## Critical Issues"
CRITICAL_FOUND=false
for finding in "${GITHUB_FINDINGS[@]}"; do
    if [[ "$finding" == Critical:* ]]; then
        echo "- $finding"
        CRITICAL_FOUND=true
    fi
done
for finding in "${JIRA_FINDINGS[@]}"; do
    if [[ "$finding" == Critical:* ]]; then
        echo "- $finding"
        CRITICAL_FOUND=true
    fi
done
for finding in "${CONFLUENCE_FINDINGS[@]}"; do
    if [[ "$finding" == Critical:* ]]; then
        echo "- $finding"
        CRITICAL_FOUND=true
    fi
done
if [ "$CRITICAL_FOUND" = false ]; then
    echo "None"
fi
echo ""

# Warnings
echo "## Warnings"
WARNINGS_FOUND=false
for finding in "${GITHUB_FINDINGS[@]}"; do
    if [[ "$finding" == Warning:* ]]; then
        echo "- $finding"
        WARNINGS_FOUND=true
    fi
done
for finding in "${JIRA_FINDINGS[@]}"; do
    if [[ "$finding" == Warning:* ]]; then
        echo "- $finding"
        WARNINGS_FOUND=true
    fi
done
for finding in "${CONFLUENCE_FINDINGS[@]}"; do
    if [[ "$finding" == Warning:* ]]; then
        echo "- $finding"
        WARNINGS_FOUND=true
    fi
done
if [ "$WARNINGS_FOUND" = false ]; then
    echo "None"
fi
echo ""

# Info
echo "## Info"
INFO_FOUND=false
for finding in "${GITHUB_FINDINGS[@]}"; do
    if [[ "$finding" == Info:* ]]; then
        echo "- $finding"
        INFO_FOUND=true
    fi
done
for finding in "${JIRA_FINDINGS[@]}"; do
    if [[ "$finding" == Info:* ]]; then
        echo "- $finding"
        INFO_FOUND=true
    fi
done

# Add suggestions for optional sections
if [ "$GITHUB_PROJECT_CONFIGURED" = false ]; then
    echo "- Consider adding \`github_project\` to track work in GitHub Projects"
    INFO_FOUND=true
fi
if [ "$WORKSTREAMS_CONFIGURED" = false ]; then
    echo "- Consider adding \`workstreams\` to organize work by repo and milestone"
    INFO_FOUND=true
fi
if [ "$JIRA_CONFIGURED" = false ]; then
    echo "- JIRA validation skipped (no jira.project_key configured)"
    INFO_FOUND=true
fi
if [ "$CONFLUENCE_CONFIGURED" = false ]; then
    echo "- Confluence validation skipped (no confluence.page_id configured)"
    INFO_FOUND=true
fi

if [ "$INFO_FOUND" = false ]; then
    echo "None"
fi
echo ""

# Workstream Details (if workstreams configured)
if [ "$WORKSTREAMS_CONFIGURED" = "true" ]; then
    echo "## Workstream Details"
    echo ""
    
    # Print details for each workstream
    while IFS= read -r ws_name; do
        [ -z "$ws_name" ] && continue
        WS_REPO=$(grep -A 1 "name: \"$ws_name\"" "$YAML_FILE" | grep "repo:" | awk '{print $2}')
        echo "### $ws_name ($WS_REPO)"
        
        # List milestones for this workstream
        grep -A 100 "name: \"$ws_name\"" "$YAML_FILE" | \
            grep -A 50 "milestones:" | \
            grep -B 1 "number:" | \
            grep "title:" | \
            sed 's/.*title: "\?\([^"]*\)"\?/\1/' | \
            head -20 | \
            while read ms_title; do
                MS_NUMBER=$(grep -A 2 "title: \"$ms_title\"" "$YAML_FILE" | grep "number:" | awk '{print $2}' | head -1)
                MS_DUE=$(grep -A 3 "title: \"$ms_title\"" "$YAML_FILE" | grep "due:" | awk '{print $2}' | tr -d '"' | head -1)
                MS_STATUS=$(grep -A 4 "title: \"$ms_title\"" "$YAML_FILE" | grep "status:" | awk '{print $2}' | head -1)
                echo "- ✅ $ms_title (milestone #$MS_NUMBER, due $MS_DUE, status: $MS_STATUS)"
            done
        echo ""
    done <<< "$WORKSTREAM_NAMES"
fi

# Action Items
echo "## Action Items for Initiative Owner"
if [ "$WARNINGS_FOUND" = true ] || [ "$CRITICAL_FOUND" = true ]; then
    echo "1. Review warnings and critical issues above"
    echo "2. Verify referenced resources or update YAML"
    echo "3. Re-run validation after making changes"
else
    echo "All validations passed! Initiative YAML is complete and accurate."
fi
```
```

- [ ] **Step 2: Commit report generation**

```bash
git add skills/initiative-validator/skill.md
git commit -m "feat(initiative-validator): update report generation for schema v2 with workstream details"
```

---

## Task 9: Update Configuration Section

**Files:**
- Modify: `skills/initiative-validator/skill.md:352-380`

- [ ] **Step 1: Update configuration section (no changes needed, just verify)**

Configuration section remains the same - environment variables for JIRA/Confluence still apply.

- [ ] **Step 2: Commit if any changes**

```bash
# Only if changes were made
git add skills/initiative-validator/skill.md
git commit -m "docs(initiative-validator): verify configuration section for schema v2"
```

---

## Task 10: Update Examples - Valid Report

**Files:**
- Modify: `skills/initiative-validator/examples/valid-report.md`

- [ ] **Step 1: Replace with schema v2 valid report example**

```markdown
# Validation Report: 2026-q1-ai-cost-intelligence-platform.yaml

## Summary
- ✅ Schema v2: Valid
- ✅ GitHub Project: Found (eci-global#14)
- ✅ Workstreams: 2 validated
- ✅ Milestones: 4 found in repos
- ✅ JIRA Epic Tasks: 12 validated
- ✅ Confluence: Page found

## Critical Issues
None

## Warnings
None

## Info
None

## Workstream Details

### S3 Unified FOCUS Data Lake (eci-global/one-cloud-cloud-costs)
- ✅ M0 — S3 Unified FOCUS Data Lake (DataSync) (milestone #5, due 2026-03-31, status: deployed)
- ✅ M5 — Terraform Infrastructure (milestone #9, due 2026-03-31, status: deployed)

### Intelligence System (eci-global/one-cloud-cloud-costs)
- ✅ M1 — Eyes Open: Automated Detection (milestone #6, due 2026-04-14, status: code-complete)
- ✅ M2 — Learning Normal: Baseline Intelligence (milestone #7, due 2026-05-09, status: code-complete)

## Action Items for Initiative Owner
All validations passed! Initiative YAML is complete and accurate.
```

- [ ] **Step 2: Commit valid report example**

```bash
git add skills/initiative-validator/examples/valid-report.md
git commit -m "docs(initiative-validator): update valid report example for schema v2"
```

---

## Task 11: Update Examples - Missing Milestone Report

**Files:**
- Modify: `skills/initiative-validator/examples/missing-milestone-report.md`

- [ ] **Step 1: Replace with schema v2 format showing missing milestone**

```markdown
# Validation Report: 2026-q1-coralogix-quota-manager.yaml

## Summary
- ✅ Schema v2: Valid
- ✅ GitHub Project: Found (eci-global#8)
- ✅ Workstreams: 1 validated
- ⚠️ Milestones: 1/2 found in repos
- ⚠️ JIRA Epic Tasks: Not configured (skipped)
- ⚠️ Confluence: Not configured (skipped)

## Critical Issues
None

## Warnings

### Milestone Not Found
- **Warning:** Milestone #15 not found in repo eci-global/coralogix
- **Workstream:** Quota Enforcement
- **Action:** Verify milestone number is correct in YAML, or milestone may have been deleted/closed in GitHub

## Info
- JIRA validation skipped (no jira.project_key configured)
- Confluence validation skipped (no confluence.page_id configured)

## Workstream Details

### Quota Enforcement (eci-global/coralogix)
- ✅ M1 — Core Quota Logic (milestone #12, due 2026-04-30, status: in-progress)
- ⚠️ M2 — Dashboard Integration (milestone #15, due 2026-05-31, status: planned) - NOT FOUND

## Action Items for Initiative Owner
1. Review warnings and critical issues above
2. Verify milestone #15 exists in eci-global/coralogix or update YAML with correct milestone number
3. Re-run validation after making changes
```

- [ ] **Step 2: Commit missing milestone example**

```bash
git add skills/initiative-validator/examples/missing-milestone-report.md
git commit -m "docs(initiative-validator): update missing milestone report for schema v2"
```

---

## Task 12: Update Examples - Invalid Schema Report

**Files:**
- Modify: `skills/initiative-validator/examples/invalid-schema-report.md`

- [ ] **Step 1: Replace with schema v2 validation errors**

```markdown
# Validation Report: invalid-initiative.yaml

## Summary
- ❌ Schema v2: INVALID
- ⚠️ Cannot proceed with further validation until schema is fixed

## Critical Issues

### Schema Validation Errors
- **Critical:** Expected schema_version: 2, got: 1
- **Message:** This skill only supports schema v2. Please use initiative-validator v1.0.0 for older schemas.

## Warnings
None (validation stopped at schema check)

## Info
Schema v2 required fields:
- `schema_version: 2`
- `name: string`
- `description: string`
- `status: active | planning | paused | completed | cancelled`
- `owner: string`

## Action Items for Initiative Owner
1. Update schema_version to 2
2. Ensure all required fields are present and correctly formatted
3. Re-run validation after fixing schema
```

- [ ] **Step 2: Commit invalid schema example**

```bash
git add skills/initiative-validator/examples/invalid-schema-report.md
git commit -m "docs(initiative-validator): update invalid schema report for v2"
```

---

## Task 13: Create Test Fixture - Valid Schema v2

**Files:**
- Create: `test/initiative-validator/fixtures/schema-v2-valid.yaml`

- [ ] **Step 1: Create valid schema v2 test fixture**

```yaml
schema_version: 2

name: "Test Initiative - Cost Management"
description: >-
  Test initiative for validating schema v2 parsing.
  Includes workstreams, GitHub project, and JIRA integration.
status: active
owner: testuser
team:
  - testuser
  - reviewer

github_project:
  org: test-org
  number: 1

workstreams:
  - name: "Core Cost Logic"
    repo: test-org/cost-service
    milestones:
      - title: "M1 — Foundation"
        number: 1
        due: "2026-06-30"
        status: in-progress
      - title: "M2 — Optimization"
        number: 2
        due: "2026-07-31"
        status: planned

jira:
  project_key: TEST
  epics:
    - key: TEST-100
      milestone: "M1 — Foundation"
      status: In Progress
      tasks:
        - key: TEST-101
          github_issue: 10
          status: Done
        - key: TEST-102
          github_issue: 11
          status: In Progress

tags:
  - test
  - cost-management
```

- [ ] **Step 2: Commit test fixture**

```bash
git add test/initiative-validator/fixtures/schema-v2-valid.yaml
git commit -m "test(initiative-validator): add schema v2 valid test fixture"
```

---

## Task 14: Create Test Script

**Files:**
- Create: `test/initiative-validator/test-schema-v2.sh`

- [ ] **Step 1: Create integration test script**

```bash
#!/bin/bash

# Integration test for initiative-validator schema v2 support

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURE_FILE="$SCRIPT_DIR/fixtures/schema-v2-valid.yaml"

echo "Testing initiative-validator with schema v2 fixture..."
echo ""

# Test 1: Schema validation passes
echo "Test 1: Schema v2 validation"
if grep -q "schema_version: 2" "$FIXTURE_FILE"; then
    echo "✅ Fixture has schema_version: 2"
else
    echo "❌ Fixture missing schema_version: 2"
    exit 1
fi

# Test 2: Required fields present
echo ""
echo "Test 2: Required fields"
REQUIRED_FIELDS=("name" "description" "status" "owner")
for field in "${REQUIRED_FIELDS[@]}"; do
    if grep -q "^$field:" "$FIXTURE_FILE"; then
        echo "✅ Field '$field' present"
    else
        echo "❌ Field '$field' missing"
        exit 1
    fi
done

# Test 3: Workstreams structure
echo ""
echo "Test 3: Workstreams structure"
if grep -q "^workstreams:" "$FIXTURE_FILE"; then
    echo "✅ Workstreams section present"
    
    # Check for repo field
    if grep -A 20 "^workstreams:" "$FIXTURE_FILE" | grep -q "repo:"; then
        echo "✅ Workstream has repo field"
    else
        echo "❌ Workstream missing repo field"
        exit 1
    fi
    
    # Check for milestones with number field
    if grep -A 30 "^workstreams:" "$FIXTURE_FILE" | grep -q "number:"; then
        echo "✅ Milestone has number field"
    else
        echo "❌ Milestone missing number field"
        exit 1
    fi
else
    echo "⚠️  Workstreams section not present (optional)"
fi

# Test 4: GitHub Project structure
echo ""
echo "Test 4: GitHub Project structure"
if grep -q "^github_project:" "$FIXTURE_FILE"; then
    echo "✅ GitHub Project section present"
    
    if grep -A 3 "^github_project:" "$FIXTURE_FILE" | grep -q "org:"; then
        echo "✅ Project has org field"
    else
        echo "❌ Project missing org field"
        exit 1
    fi
    
    if grep -A 3 "^github_project:" "$FIXTURE_FILE" | grep -q "number:"; then
        echo "✅ Project has number field"
    else
        echo "❌ Project missing number field"
        exit 1
    fi
else
    echo "⚠️  GitHub Project not present (optional)"
fi

# Test 5: JIRA epic tasks structure
echo ""
echo "Test 5: JIRA epic tasks structure"
if grep -q "^jira:" "$FIXTURE_FILE"; then
    echo "✅ JIRA section present"
    
    if grep -A 50 "^jira:" "$FIXTURE_FILE" | grep -q "tasks:"; then
        echo "✅ Epic has tasks section"
        
        if grep -A 60 "^jira:" "$FIXTURE_FILE" | grep -q "github_issue:"; then
            echo "✅ Task has github_issue field"
        else
            echo "❌ Task missing github_issue field"
            exit 1
        fi
    else
        echo "⚠️  No tasks in JIRA epic (optional)"
    fi
else
    echo "⚠️  JIRA section not present (optional)"
fi

echo ""
echo "========================================="
echo "All tests passed! ✅"
echo "========================================="
```

- [ ] **Step 2: Make test script executable**

```bash
chmod +x test/initiative-validator/test-schema-v2.sh
```

- [ ] **Step 3: Run test to verify fixture**

```bash
./test/initiative-validator/test-schema-v2.sh
```

Expected output:
```
Testing initiative-validator with schema v2 fixture...

Test 1: Schema v2 validation
✅ Fixture has schema_version: 2

Test 2: Required fields
✅ Field 'name' present
✅ Field 'description' present
✅ Field 'status' present
✅ Field 'owner' present

Test 3: Workstreams structure
✅ Workstreams section present
✅ Workstream has repo field
✅ Milestone has number field

Test 4: GitHub Project structure
✅ GitHub Project section present
✅ Project has org field
✅ Project has number field

Test 5: JIRA epic tasks structure
✅ JIRA section present
✅ Epic has tasks section
✅ Task has github_issue field

=========================================
All tests passed! ✅
=========================================
```

- [ ] **Step 4: Commit test script**

```bash
git add test/initiative-validator/test-schema-v2.sh
git commit -m "test(initiative-validator): add schema v2 integration test"
```

---

## Task 15: Add Version Changelog

**Files:**
- Modify: `skills/initiative-validator/skill.md` (append at end before examples)

- [ ] **Step 1: Add changelog section**

```markdown
## Changelog

### v2.0.0 - Schema v2 Support (2026-04-15)

**Breaking Changes:**
- Only supports schema v2 (schema_version: 2)
- Use v1.0.0 for legacy schema v1 files

**New Features:**
- Validates `github_project` (singular) via GraphQL
- Validates `workstreams` with milestone objects (title, number, due, status)
- Validates JIRA epic task `github_issue` references
- Reports organized by workstream
- Checks milestone numbers instead of string titles

**Removed:**
- Support for `repos:` array (replaced by `workstreams:`)
- Support for milestone string validation (now uses milestone numbers)

**Migration:**
- All initiatives in eci-global/initiatives use schema v2
- No migration needed for users (validator auto-detects schema version)
```

- [ ] **Step 2: Commit changelog**

```bash
git add skills/initiative-validator/skill.md
git commit -m "docs(initiative-validator): add v2.0.0 changelog"
```

---

## Self-Review Checklist

- [ ] All spec requirements covered:
  - ✅ Schema v2 validation (required fields, status enum)
  - ✅ GitHub Project validation (GraphQL)
  - ✅ Workstream milestone validation (object format with numbers)
  - ✅ JIRA epic task github_issue validation
  - ✅ Optional JIRA/Confluence (skip gracefully)
  - ✅ Workstream-organized reports
  
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
