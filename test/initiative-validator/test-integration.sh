#!/bin/bash
set -e

echo "Running initiative-validator integration tests..."

# Test 1: Skill documentation has all required sections
echo "Test 1: Skill documentation structure"
SKILL_FILE="skills/initiative-validator/skill.md"

if ! grep -q "## Purpose" "$SKILL_FILE"; then
    echo "FAIL: Missing Purpose section"
    exit 1
fi

if ! grep -q "## Workflow" "$SKILL_FILE"; then
    echo "FAIL: Missing Workflow section"
    exit 1
fi

if ! grep -q "### Step 1: Parse and Validate YAML Schema" "$SKILL_FILE"; then
    echo "FAIL: Missing YAML validation workflow step"
    exit 1
fi

if ! grep -q "### Step 2: Validate GitHub Milestones" "$SKILL_FILE"; then
    echo "FAIL: Missing GitHub validation workflow step"
    exit 1
fi

if ! grep -q "### Step 3: Validate JIRA Epics" "$SKILL_FILE"; then
    echo "FAIL: Missing JIRA validation workflow step"
    exit 1
fi

if ! grep -q "### Step 4: Validate Confluence Page" "$SKILL_FILE"; then
    echo "FAIL: Missing Confluence validation workflow step"
    exit 1
fi

if ! grep -q "### Step 5: Generate Report" "$SKILL_FILE"; then
    echo "FAIL: Missing report generation workflow step"
    exit 1
fi

echo "PASS: Skill documentation has all required workflow sections"

# Test 2: Example fixtures exist
echo "Test 2: Test fixtures"
if [ ! -f "test/initiative-validator/fixtures/valid-complete.yaml" ]; then
    echo "FAIL: Missing valid-complete.yaml fixture"
    exit 1
fi

if [ ! -f "test/initiative-validator/fixtures/invalid-schema.yaml" ]; then
    echo "FAIL: Missing invalid-schema.yaml fixture"
    exit 1
fi

echo "PASS: All test fixtures exist"

# Test 3: Example reports exist
echo "Test 3: Example reports"
if [ ! -f "skills/initiative-validator/examples/valid-report.md" ]; then
    echo "FAIL: Missing valid-report.md example"
    exit 1
fi

if [ ! -f "skills/initiative-validator/examples/missing-milestone-report.md" ]; then
    echo "FAIL: Missing missing-milestone-report.md example"
    exit 1
fi

if [ ! -f "skills/initiative-validator/examples/invalid-schema-report.md" ]; then
    echo "FAIL: Missing invalid-schema-report.md example"
    exit 1
fi

echo "PASS: All example reports exist"

echo "All integration tests passed!"
