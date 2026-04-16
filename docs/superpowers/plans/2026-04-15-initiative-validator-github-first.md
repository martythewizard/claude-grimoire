# Initiative Validator GitHub-First Updates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update initiative-validator skill to focus on GitHub Projects and issues as primary validation targets, with JIRA and Confluence as optional secondary systems.

**Architecture:** Add GitHub Projects v2 (GraphQL) and GitHub issues (REST API) validation steps before milestone validation. Make JIRA and Confluence validation conditional on their sections existing in YAML. Update report format to show GitHub-first with clear "Not configured (skipped)" messages for optional sections.

**Tech Stack:** GitHub CLI (gh), GitHub REST API, GitHub GraphQL API, bash scripting, YAML parsing

---

## File Structure

**Modified files:**
- `skills/initiative-validator/skill.md` - Add GitHub Projects/issues validation workflow steps
- `skills/initiative-validator/examples/valid-report.md` - Update to show GitHub validation
- `skills/initiative-validator/examples/missing-milestone-report.md` - Update to GitHub-first format
- `skills/initiative-validator/examples/invalid-schema-report.md` - Show optional JIRA/Confluence
- `test/initiative-validator/fixtures/valid-complete.yaml` - Add github.projects and github.issues
- `test/initiative-validator/test-integration.sh` - Add GitHub Projects/issues tests

**Created files:**
- `test/initiative-validator/fixtures/github-only.yaml` - GitHub-only YAML (no JIRA/Confluence)

---

### Task 1: Add GitHub Projects Validation Step

**Files:**
- Modify: `skills/initiative-validator/skill.md`

- [ ] **Step 1: Add GitHub Projects validation section after Step 1 (schema validation)**

Insert new Step 2 (GitHub Projects validation) at line 78 in skill.md:

```markdown
### Step 2: Validate GitHub Projects

For each project in `github.projects:`, check if project exists and is accessible:

```bash
# Check if github.projects section exists
if grep -q "^github:" "$YAML_FILE" && grep -q "  projects:" "$YAML_FILE"; then
    echo "Validating GitHub Projects..."
    
    GITHUB_FINDINGS=()
    
    # Extract org from first repo (assumes all repos in same org)
    FIRST_REPO=$(grep -A 100 "^repos:" "$YAML_FILE" | grep "  - name:" | head -1 | awk '{print $3}')
    ORG=$(echo "$FIRST_REPO" | cut -d'/' -f1)
    
    # Extract project numbers
    PROJECT_NUMBERS=$(grep -A 50 "  projects:" "$YAML_FILE" | grep "    - number:" | awk '{print $3}')
    
    for proj_num in $PROJECT_NUMBERS; do
        # Check project exists via GraphQL
        QUERY='query($org: String!, $number: Int!) {
          organization(login: $org) {
            projectV2(number: $number) {
              id
              title
            }
          }
        }'
        
        RESPONSE=$(gh api graphql -f query="$QUERY" -f org="$ORG" -F number="$proj_num" 2>&1)
        
        if echo "$RESPONSE" | jq -e '.data.organization.projectV2.id' > /dev/null 2>&1; then
            PROJ_TITLE=$(echo "$RESPONSE" | jq -r '.data.organization.projectV2.title')
            echo "✅ GitHub Project found: #$proj_num ($PROJ_TITLE)"
        else
            GITHUB_FINDINGS+=("Warning: GitHub Project #$proj_num not found or not accessible in org $ORG")
        fi
    done
    
    # Check for auth errors
    if [ $? -ne 0 ]; then
        GITHUB_FINDINGS+=("Warning: GitHub API authentication failed - skipping GitHub Projects validation")
    fi
else
    echo "ℹ️  GitHub Projects: Not configured (skipped)"
fi
```
```

- [ ] **Step 2: Commit**

```bash
git add skills/initiative-validator/skill.md
git commit -m "feat(initiative-validator): add GitHub Projects v2 validation step

- Validate projects via GraphQL organizati on.projectV2 query
- Check project exists and is accessible
- Skip gracefully if github.projects not configured"
```

---

### Task 2: Add GitHub Issues Validation Step

**Files:**
- Modify: `skills/initiative-validator/skill.md`

- [ ] **Step 1: Add GitHub issues validation section after GitHub Projects step**

Insert new Step 3 (GitHub issues validation) after Step 2:

```markdown
### Step 3: Validate GitHub Issues

For each issue in `github.issues:`, check if issue exists and is accessible:

```bash
# Check if github.issues section exists
if grep -q "^github:" "$YAML_FILE" && grep -q "  issues:" "$YAML_FILE"; then
    echo "Validating GitHub Issues..."
    
    # Extract repo from repos section (use first repo, or could iterate all)
    FIRST_REPO=$(grep -A 100 "^repos:" "$YAML_FILE" | grep "  - name:" | head -1 | awk '{print $3}')
    
    # Extract issue numbers
    ISSUE_NUMBERS=$(grep -A 50 "  issues:" "$YAML_FILE" | grep "    - " | awk '{print $2}')
    
    for issue_num in $ISSUE_NUMBERS; do
        # Check issue exists via REST API
        STATUS_CODE=$(gh api repos/$FIRST_REPO/issues/$issue_num --jq '.number' 2>&1)
        
        if [ $? -eq 0 ]; then
            ISSUE_TITLE=$(gh api repos/$FIRST_REPO/issues/$issue_num --jq '.title')
            echo "✅ GitHub Issue found: #$issue_num ($ISSUE_TITLE)"
        else
            GITHUB_FINDINGS+=("Warning: GitHub Issue #$issue_num not found in repo $FIRST_REPO")
        fi
    done
    
    # Check for auth errors
    if [ $? -ne 0 ]; then
        GITHUB_FINDINGS+=("Warning: GitHub API authentication failed - skipping GitHub issues validation")
    fi
else
    echo "ℹ️  GitHub Issues: Not configured (skipped)"
fi
```
```

- [ ] **Step 2: Commit**

```bash
git add skills/initiative-validator/skill.md
git commit -m "feat(initiative-validator): add GitHub issues validation step

- Validate issues via gh CLI REST API
- Check each issue exists and is accessible
- Skip gracefully if github.issues not configured"
```

---

### Task 3: Update Milestone Validation to GitHub-First

**Files:**
- Modify: `skills/initiative-validator/skill.md`

- [ ] **Step 1: Update existing Step 2 (GitHub Milestones) to be Step 4 and keep GitHub findings array**

The existing milestone validation is at lines 78-106. Update the step number and ensure it uses the same `GITHUB_FINDINGS` array:

```markdown
### Step 4: Validate GitHub Milestones

For each repo in `repos:`, check if milestones exist:

```bash
# Extract repos from YAML
REPOS=$(grep -A 100 "^repos:" "$YAML_FILE" | grep "  - name:" | awk '{print $3}')

# Initialize GITHUB_FINDINGS if not already set
if [ -z "$GITHUB_FINDINGS" ]; then
    GITHUB_FINDINGS=()
fi

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
```

- [ ] **Step 2: Commit**

```bash
git add skills/initiative-validator/skill.md
git commit -m "refactor(initiative-validator): update milestone validation to Step 4

- Renumber as Step 4 to accommodate GitHub Projects/issues steps
- Ensure GITHUB_FINDINGS array is shared across all GitHub checks"
```

---

### Task 4: Make JIRA Validation Optional

**Files:**
- Modify: `skills/initiative-validator/skill.md`

- [ ] **Step 1: Update Step 3 (JIRA Epics) to be Step 5 and make conditional**

The existing JIRA validation is at lines 108-145. Update to check if jira section exists first:

```markdown
### Step 5: Validate JIRA Epics (Optional)

For each epic in `jira.epics:`, verify accessibility (skips if jira section not configured):

```bash
# Check if jira section exists
if grep -q "^jira:" "$YAML_FILE" && grep -q "  project_key:" "$YAML_FILE"; then
    echo "Validating JIRA Epics..."
    
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
else
    echo "ℹ️  JIRA: Not configured (skipped)"
    JIRA_FINDINGS=()
fi
```
```

- [ ] **Step 2: Commit**

```bash
git add skills/initiative-validator/skill.md
git commit -m "feat(initiative-validator): make JIRA validation optional

- Check if jira section exists before validating
- Skip gracefully with info message if not configured
- Renumber as Step 5"
```

---

### Task 5: Make Confluence Validation Optional

**Files:**
- Modify: `skills/initiative-validator/skill.md`

- [ ] **Step 1: Update Step 4 (Confluence) to be Step 6 and make conditional**

The existing Confluence validation is at lines 147-182. Update to check if confluence section exists:

```markdown
### Step 6: Validate Confluence Page (Optional)

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

- [ ] **Step 2: Commit**

```bash
git add skills/initiative-validator/skill.md
git commit -m "feat(initiative-validator): make Confluence validation optional

- Check if confluence section exists before validating
- Skip gracefully with info message if not configured
- Renumber as Step 6"
```

---

### Task 6: Update Report Generation to GitHub-First

**Files:**
- Modify: `skills/initiative-validator/skill.md`

- [ ] **Step 1: Update Step 5 (Report Generation) to be Step 7 and show GitHub-first**

The existing report generation is at lines 184-247. Update to show GitHub Projects/issues and handle optional sections:

```markdown
### Step 7: Generate Report

Aggregate findings and output markdown with GitHub-first format:

```bash
INITIATIVE_NAME=$(grep "^name:" "$YAML_FILE" | sed 's/name: "\(.*\)"/\1/')

# Count GitHub checks
GITHUB_PROJECTS_CHECKED=false
GITHUB_ISSUES_CHECKED=false
if grep -q "^github:" "$YAML_FILE"; then
    if grep -q "  projects:" "$YAML_FILE"; then
        GITHUB_PROJECTS_CHECKED=true
    fi
    if grep -q "  issues:" "$YAML_FILE"; then
        GITHUB_ISSUES_CHECKED=true
    fi
fi

# Check if optional sections are configured
JIRA_CONFIGURED=$(grep -q "^jira:" "$YAML_FILE" && echo "true" || echo "false")
CONFLUENCE_CONFIGURED=$(grep -q "^confluence:" "$YAML_FILE" && echo "true" || echo "false")

echo "# Validation Report: $(basename $YAML_FILE)"
echo ""
echo "## Summary"
echo "- ✅ Schema: Valid"

# GitHub summary
if [ "$GITHUB_PROJECTS_CHECKED" = true ]; then
    PROJECTS_COUNT=$(grep -A 50 "  projects:" "$YAML_FILE" | grep "    - number:" | wc -l)
    PROJECTS_ISSUES=$(echo "${GITHUB_FINDINGS[@]}" | grep -c "Project")
    echo "- GitHub Projects: $((PROJECTS_COUNT - PROJECTS_ISSUES))/$PROJECTS_COUNT found"
fi
if [ "$GITHUB_ISSUES_CHECKED" = true ]; then
    ISSUES_COUNT=$(grep -A 50 "  issues:" "$YAML_FILE" | grep "    - " | wc -l)
    ISSUES_ISSUES=$(echo "${GITHUB_FINDINGS[@]}" | grep -c "Issue")
    echo "- GitHub Issues: $((ISSUES_COUNT - ISSUES_ISSUES))/$ISSUES_COUNT accessible"
fi

# Milestone count
MILESTONES_COUNT=$(grep -A 100 "^repos:" "$YAML_FILE" | grep "    - \"" | wc -l)
MILESTONE_ISSUES=$(echo "${GITHUB_FINDINGS[@]}" | grep -c "Milestone")
echo "- GitHub Milestones: $((MILESTONES_COUNT - MILESTONE_ISSUES))/$MILESTONES_COUNT found"

# JIRA summary
if [ "$JIRA_CONFIGURED" = true ]; then
    EPICS_COUNT=$(grep -A 50 "^jira:" "$YAML_FILE" | grep "  - key:" | wc -l)
    echo "- JIRA: ${#JIRA_FINDINGS[@]} issues ($EPICS_COUNT epics checked)"
else
    echo "- ⚠️ JIRA: Not configured (skipped)"
fi

# Confluence summary
if [ "$CONFLUENCE_CONFIGURED" = true ]; then
    echo "- Confluence: ${#CONFLUENCE_FINDINGS[@]} issues"
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
if ! grep -q "^tags:" "$YAML_FILE"; then
    echo "- Consider adding \`tags:\` for better discoverability"
fi
if ! grep -q "^team:" "$YAML_FILE"; then
    echo "- Consider adding \`team:\` to track all contributors"
fi
if [ "$GITHUB_PROJECTS_CHECKED" = false ]; then
    echo "- Consider adding \`github.projects\` to track work in GitHub Projects"
fi
if [ "$GITHUB_ISSUES_CHECKED" = false ]; then
    echo "- Consider adding \`github.issues\` to track specific issues"
fi
if [ "$JIRA_CONFIGURED" = false ]; then
    echo "- JIRA validation skipped (no jira.project_key configured)"
fi
if [ "$CONFLUENCE_CONFIGURED" = false ]; then
    echo "- Confluence validation skipped (no confluence.page_id configured)"
fi
echo ""

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

- [ ] **Step 2: Commit**

```bash
git add skills/initiative-validator/skill.md
git commit -m "feat(initiative-validator): update report to GitHub-first format

- Show GitHub Projects/issues validation results
- Clearly indicate optional sections as 'Not configured (skipped)'
- Suggest adding GitHub Projects/issues if missing
- Renumber as Step 7"
```

---

### Task 7: Update Example Reports

**Files:**
- Modify: `skills/initiative-validator/examples/valid-report.md`
- Modify: `skills/initiative-validator/examples/missing-milestone-report.md`
- Modify: `skills/initiative-validator/examples/invalid-schema-report.md`

- [ ] **Step 1: Update valid-report.md to show GitHub-first**

```markdown
# Validation Report: firehydrant.yaml

## Summary
- ✅ Schema: Valid
- GitHub Projects: 1/1 found
- GitHub Issues: 3/3 accessible
- GitHub Milestones: 2/2 found
- ⚠️ JIRA: Not configured (skipped)
- ⚠️ Confluence: Not configured (skipped)

## Critical Issues
None

## Warnings
None

## Info
- JIRA validation skipped (no jira.project_key configured)
- Confluence validation skipped (no confluence.page_id configured)

## Action Items for Initiative Owner
All validations passed! Initiative YAML is complete and accurate.
```

- [ ] **Step 2: Update missing-milestone-report.md**

```markdown
# Validation Report: onecloud.yaml

## Summary
- ✅ Schema: Valid
- GitHub Projects: 1/1 found
- GitHub Issues: 2/2 accessible
- GitHub Milestones: 7/8 found (1 missing)
- JIRA: 0 issues (5 epics checked)
- Confluence: 0 issues

## Critical Issues
None

## Warnings

### GitHub Milestone Not Found
- **Milestone:** "Q3 Infrastructure"
- **Repo:** eci-global/ember
- **Action:** Verify milestone name is correct, or create milestone in GitHub if it should exist

## Info
- Consider creating the missing milestone in eci-global/ember if Q3 Infrastructure work is planned

## Action Items for Initiative Owner
1. Verify GitHub milestone "Q3 Infrastructure" in repo eci-global/ember
2. Create milestone if needed, or update YAML if milestone name changed
3. Re-run validation after making changes
```

- [ ] **Step 3: Update invalid-schema-report.md**

```markdown
# Validation Report: broken.yaml

## Summary
- ❌ Schema: Invalid
- GitHub validation: Skipped (schema errors must be fixed first)
- JIRA validation: Skipped (schema errors must be fixed first)
- Confluence validation: Skipped (schema errors must be fixed first)

## Critical Issues

### Missing Required Field
- **Field:** owner
- **Action:** Add `owner: username` to YAML

### Invalid Status Value
- **Value:** "in-progress"
- **Action:** Change to one of: active, planning, paused, completed, cancelled

## Warnings
None (schema must be fixed first)

## Info
Fix critical schema errors before running validation again.

## Action Items for Initiative Owner
1. Add required field `owner:` with your username
2. Fix status value to use valid enum
3. Re-run validation after fixing schema
```

- [ ] **Step 4: Commit**

```bash
git add skills/initiative-validator/examples/valid-report.md \
     skills/initiative-validator/examples/missing-milestone-report.md \
     skills/initiative-validator/examples/invalid-schema-report.md
git commit -m "docs(initiative-validator): update example reports to GitHub-first

- Show GitHub Projects/issues validation results
- Indicate JIRA/Confluence as optional/skipped
- Keep examples realistic and actionable"
```

---

### Task 8: Add GitHub-Only Test Fixture

**Files:**
- Create: `test/initiative-validator/fixtures/github-only.yaml`

- [ ] **Step 1: Create github-only.yaml test fixture**

```yaml
schema_version: 1
name: "FireHydrant Improvements"
description: "Enhance firehydrant management and automation"
status: active
owner: mhoward
repos:
  - name: eci-global/firehydrant
    milestones:
      - "Q1 2026"
      - "Q2 2026"
github:
  projects:
    - number: 25
      title: "AI-First FireHydrant Management"
  issues:
    - 205
    - 202
    - 200
tags:
  - firehydrant
  - automation
  - incident-management
team:
  - mhoward
  - jsmith
```

- [ ] **Step 2: Commit**

```bash
git add test/initiative-validator/fixtures/github-only.yaml
git commit -m "test(initiative-validator): add GitHub-only test fixture

- No JIRA or Confluence sections
- Includes GitHub Projects and issues
- Represents typical GitHub-first initiative"
```

---

### Task 9: Update Test Integration Script

**Files:**
- Modify: `test/initiative-validator/test-integration.sh`

- [ ] **Step 1: Read current test-integration.sh**

Read to see current structure and determine where to add GitHub Projects/issues tests.

- [ ] **Step 2: Add GitHub Projects validation test case**

Add test case that validates GitHub Projects exist:

```bash
# Test: GitHub Projects validation
test_github_projects_validation() {
    echo "Testing GitHub Projects validation..."
    
    # This test requires network access and gh CLI configured
    if ! command -v gh &> /dev/null; then
        echo "⚠️  gh CLI not found, skipping GitHub Projects test"
        return 0
    fi
    
    # Run validator on github-only fixture
    OUTPUT=$(bash skills/initiative-validator/skill.md test/initiative-validator/fixtures/github-only.yaml 2>&1)
    
    # Check for GitHub Projects in summary
    if echo "$OUTPUT" | grep -q "GitHub Projects:"; then
        echo "✅ GitHub Projects validation executed"
    else
        echo "❌ GitHub Projects validation not found in output"
        return 1
    fi
    
    return 0
}

test_github_projects_validation
```

- [ ] **Step 3: Add GitHub issues validation test case**

```bash
# Test: GitHub Issues validation
test_github_issues_validation() {
    echo "Testing GitHub Issues validation..."
    
    # This test requires network access and gh CLI configured
    if ! command -v gh &> /dev/null; then
        echo "⚠️  gh CLI not found, skipping GitHub Issues test"
        return 0
    fi
    
    # Run validator on github-only fixture
    OUTPUT=$(bash skills/initiative-validator/skill.md test/initiative-validator/fixtures/github-only.yaml 2>&1)
    
    # Check for GitHub Issues in summary
    if echo "$OUTPUT" | grep -q "GitHub Issues:"; then
        echo "✅ GitHub Issues validation executed"
    else
        echo "❌ GitHub Issues validation not found in output"
        return 1
    fi
    
    return 0
}

test_github_issues_validation
```

- [ ] **Step 4: Add test for optional JIRA/Confluence**

```bash
# Test: Optional JIRA/Confluence sections
test_optional_sections() {
    echo "Testing optional JIRA/Confluence handling..."
    
    # Run validator on github-only fixture (no JIRA/Confluence)
    OUTPUT=$(bash skills/initiative-validator/skill.md test/initiative-validator/fixtures/github-only.yaml 2>&1)
    
    # Check for "Not configured (skipped)" messages
    if echo "$OUTPUT" | grep -q "JIRA: Not configured (skipped)" && \
       echo "$OUTPUT" | grep -q "Confluence: Not configured (skipped)"; then
        echo "✅ Optional sections handled correctly"
    else
        echo "❌ Optional sections not handled correctly"
        return 1
    fi
    
    return 0
}

test_optional_sections
```

- [ ] **Step 5: Commit**

```bash
git add test/initiative-validator/test-integration.sh
git commit -m "test(initiative-validator): add GitHub Projects/issues tests

- Test GitHub Projects v2 validation
- Test GitHub issues validation
- Test optional JIRA/Confluence handling
- Skip tests gracefully if gh CLI not available"
```

---

### Task 10: Update Skill Description and Purpose

**Files:**
- Modify: `skills/initiative-validator/skill.md`

- [ ] **Step 1: Update skill frontmatter and description**

Update lines 1-18 to reflect GitHub-first focus:

```markdown
---
name: initiative-validator
description: Validate initiative YAML files against GitHub Projects, issues, milestones, with optional JIRA and Confluence validation
version: 2.0.0
---

# Initiative Validator Skill

Validate initiative YAML files end-to-end against GitHub Projects, issues, and milestones. Optionally validates JIRA epics and Confluence pages if configured. Generates actionable reports organized by severity.

## Purpose

This skill helps you:
- Validate YAML schema before committing to the initiatives registry
- Check that GitHub Projects referenced in YAML are accessible
- Verify GitHub issues referenced in YAML exist
- Check that GitHub milestones exist in each repo
- Optionally verify JIRA epic keys (if jira section configured)
- Optionally confirm Confluence pages exist (if confluence section configured)
- Get clear, actionable reports to fix issues

## When to Use

Invoke this skill before committing changes to initiative YAML files, or when you suspect an initiative's external references are stale.

## How It Works

1. **Parse YAML** - Validate schema and extract references
2. **Validate GitHub Projects** - Check projects are accessible (if configured)
3. **Validate GitHub Issues** - Verify issues exist (if configured)
4. **Validate GitHub Milestones** - Check milestones exist in each repo
5. **Validate JIRA** - Verify epic keys (if jira section configured)
6. **Validate Confluence** - Confirm pages exist (if confluence section configured)
7. **Generate Report** - Output markdown organized by severity (Critical/Warning/Info)
```

- [ ] **Step 2: Commit**

```bash
git add skills/initiative-validator/skill.md
git commit -m "docs(initiative-validator): update description to GitHub-first

- Bump version to 2.0.0
- Update description to list GitHub first
- Clarify JIRA/Confluence are optional
- Update workflow steps to match new order"
```

---

## Self-Review Checklist

After implementing all tasks, review:

**Spec Coverage:**
- ✅ GitHub Projects v2 validation (Task 1)
- ✅ GitHub issues validation (Task 2)
- ✅ Optional JIRA validation (Task 4)
- ✅ Optional Confluence validation (Task 5)
- ✅ GitHub-first report format (Task 6)
- ✅ Updated example reports (Task 7)
- ✅ GitHub-only test fixture (Task 8)
- ✅ Test coverage for new features (Task 9)

**Placeholder Scan:**
- No "TBD" or "TODO" in code
- No "add error handling" without implementation
- All bash code blocks are complete and runnable

**Type Consistency:**
- Variable names consistent across steps (GITHUB_FINDINGS, JIRA_FINDINGS, CONFLUENCE_FINDINGS)
- Step numbers sequential (1-7)
- File paths consistent

**Dependencies:**
- All modified files exist
- New test fixture created properly
- No breaking changes to existing functionality

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-04-15-initiative-validator-github-first.md`.**

This plan updates the initiative-validator skill to focus on GitHub Projects and issues as primary validation targets, with JIRA and Confluence as optional secondary systems.

Ready to execute with superpowers:subagent-driven-development or superpowers:executing-plans.
