#!/bin/bash
set -e

echo "Running initiative-discoverer integration tests..."

# Test 1: Skill documentation structure
echo "Test 1: Skill documentation structure"
SKILL_FILE="skills/initiative-discoverer/skill.md"

if ! grep -q "## Workflow" "$SKILL_FILE"; then
    echo "FAIL: Missing Workflow section"
    exit 1
fi

if ! grep -q "### Step 1: Extract Context from YAML" "$SKILL_FILE"; then
    echo "FAIL: Missing context extraction step"
    exit 1
fi

if ! grep -q "### Step 2: Search JIRA for Candidate Epics" "$SKILL_FILE"; then
    echo "FAIL: Missing JIRA search step"
    exit 1
fi

if ! grep -q "### Step 3: Deduplicate Against Existing Epics" "$SKILL_FILE"; then
    echo "FAIL: Missing deduplication step"
    exit 1
fi

if ! grep -q "### Step 4: Rank Candidates with AI" "$SKILL_FILE"; then
    echo "FAIL: Missing AI ranking step"
    exit 1
fi

if ! grep -q "### Step 5: Generate Suggestions" "$SKILL_FILE"; then
    echo "FAIL: Missing suggestion generation step"
    exit 1
fi

echo "PASS: Skill has all required workflow sections"

# Test 2: Heuristic fallback documented
echo "Test 2: Heuristic fallback"
if ! grep -q "heuristic_score" "$SKILL_FILE"; then
    echo "FAIL: Missing heuristic scoring fallback"
    exit 1
fi

if ! grep -q "USE_AI_RANKING=false" "$SKILL_FILE"; then
    echo "FAIL: Missing AI ranking fallback logic"
    exit 1
fi

echo "PASS: Heuristic fallback is documented"

# Test 3: Test fixture exists
echo "Test 3: Test fixtures"
if [ ! -f "test/initiative-discoverer/fixtures/discoverable.yaml" ]; then
    echo "FAIL: Missing discoverable.yaml fixture"
    exit 1
fi

echo "PASS: Test fixture exists"

echo "All integration tests passed!"
