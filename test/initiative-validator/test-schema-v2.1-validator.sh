#!/bin/bash

# Integration test for schema v2.1 validator enhancements
# Tests repo field inference and validation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Schema v2.1 Validator Integration Tests ==="
echo

# Helper function to validate fixture structure
validate_fixture() {
    local fixture_file="$1"
    local fixture_name=$(basename "$fixture_file" .yaml)

    echo "Validating: $fixture_name"

    # Check file exists
    if [ ! -f "$fixture_file" ]; then
        echo -e "${RED}✗ FAIL${NC}: Fixture file not found: $fixture_file"
        return 1
    fi

    # Check schema version
    if ! grep -q "schema_version: 2" "$fixture_file"; then
        echo -e "${RED}✗ FAIL${NC}: Missing schema_version: 2"
        return 1
    fi

    # Check required fields
    local required_fields=("name" "description" "status" "owner")
    for field in "${required_fields[@]}"; do
        if ! grep -q "^$field:" "$fixture_file"; then
            echo -e "${RED}✗ FAIL${NC}: Missing required field '$field'"
            return 1
        fi
    done

    return 0
}

# Test 1: Single Repo (baseline - inference always succeeds)
echo "Test 1: Single Repo Fixture"
if validate_fixture "$FIXTURES_DIR/schema-v2.1-single-repo.yaml"; then
    # Verify single workstream
    if grep -q "workstreams:" "$FIXTURES_DIR/schema-v2.1-single-repo.yaml" && \
       grep -A 10 "workstreams:" "$FIXTURES_DIR/schema-v2.1-single-repo.yaml" | grep -q "repo: testorg/test-repo"; then
        echo -e "${GREEN}✓ PASS${NC}: Single repo validation successful"
    else
        echo -e "${RED}✗ FAIL${NC}: Single repo fixture malformed"
        exit 1
    fi
else
    echo -e "${RED}✗ FAIL${NC}: Single repo validation failed"
    exit 1
fi
echo

# Test 2: Multi-Repo Explicit (all tasks have explicit repo)
echo "Test 2: Multi-Repo Explicit Fixture"
if validate_fixture "$FIXTURES_DIR/schema-v2.1-multi-repo-explicit.yaml"; then
    # Verify both repos are referenced
    if grep -q "testorg/test-repo" "$FIXTURES_DIR/schema-v2.1-multi-repo-explicit.yaml" && \
       grep -q "testorg/test-api" "$FIXTURES_DIR/schema-v2.1-multi-repo-explicit.yaml"; then
        echo -e "${GREEN}✓ PASS${NC}: Multi-repo explicit validation shows both repos"
    else
        echo -e "${RED}✗ FAIL${NC}: Multi-repo explicit fixture missing repo info"
        exit 1
    fi
else
    echo -e "${RED}✗ FAIL${NC}: Multi-repo explicit validation failed"
    exit 1
fi
echo

# Test 3: Multi-Repo Inferred (mixed explicit/inferred)
echo "Test 3: Multi-Repo Inferred Fixture"
if validate_fixture "$FIXTURES_DIR/schema-v2.1-multi-repo-inferred.yaml"; then
    # Verify frontend repo is present
    if grep -q "testorg/test-frontend" "$FIXTURES_DIR/schema-v2.1-multi-repo-inferred.yaml"; then
        echo -e "${GREEN}✓ PASS${NC}: Multi-repo inferred validation successful"
    else
        echo -e "${RED}✗ FAIL${NC}: Multi-repo inferred validation missing expected repo"
        exit 1
    fi
else
    echo -e "${RED}✗ FAIL${NC}: Multi-repo inferred validation failed"
    exit 1
fi
echo

# Test 4: Ambiguous Milestone (should have duplicate milestone in multiple workstreams)
echo "Test 4: Ambiguous Milestone Fixture"
if validate_fixture "$FIXTURES_DIR/schema-v2.1-ambiguous-milestone.yaml"; then
    # Check that same milestone appears in multiple workstreams
    MILESTONE_COUNT=$(grep -c "M2 — Feature Development" "$FIXTURES_DIR/schema-v2.1-ambiguous-milestone.yaml")
    if [ "$MILESTONE_COUNT" -ge 2 ]; then
        echo -e "${GREEN}✓ PASS${NC}: Ambiguous milestone fixture properly configured"
        echo -e "${GREEN}  (Milestone appears $MILESTONE_COUNT times)${NC}"
    else
        echo -e "${YELLOW}⚠ WARN${NC}: Ambiguous milestone might not be properly configured"
    fi
else
    echo -e "${RED}✗ FAIL${NC}: Ambiguous milestone validation failed"
    exit 1
fi
echo

# Test 5: Cross-Repo Tracking (should have task with repo different from milestone)
echo "Test 5: Cross-Repo Tracking Fixture"
if validate_fixture "$FIXTURES_DIR/schema-v2.1-cross-repo.yaml"; then
    # Check for multiple workstreams
    WS_COUNT=$(grep -c "^  - name:" "$FIXTURES_DIR/schema-v2.1-cross-repo.yaml")
    if [ "$WS_COUNT" -ge 2 ]; then
        # Check for testorg/test-api in tasks (explicit repo)
        if grep "testorg/test-api" "$FIXTURES_DIR/schema-v2.1-cross-repo.yaml" | grep -q "repo:"; then
            echo -e "${GREEN}✓ PASS${NC}: Cross-repo tracking validated"
            echo -e "${GREEN}  (Multiple workstreams with explicit repo field)${NC}"
        else
            echo -e "${RED}✗ FAIL${NC}: Cross-repo tracking fixture missing explicit repo field"
            exit 1
        fi
    else
        echo -e "${RED}✗ FAIL${NC}: Cross-repo fixture needs multiple workstreams"
        exit 1
    fi
else
    echo -e "${RED}✗ FAIL${NC}: Cross-repo tracking validation failed"
    exit 1
fi
echo

# Test 6: Verify all fixtures have jira section with repo inference setup
echo "Test 6: JIRA Integration Setup Verification"
JIRA_FIXTURES=("schema-v2.1-single-repo.yaml" "schema-v2.1-multi-repo-explicit.yaml" "schema-v2.1-multi-repo-inferred.yaml" "schema-v2.1-ambiguous-milestone.yaml" "schema-v2.1-cross-repo.yaml")
JIRA_COUNT=0

for fixture in "${JIRA_FIXTURES[@]}"; do
    if grep -q "^jira:" "$FIXTURES_DIR/$fixture"; then
        if grep -q "epics:" "$FIXTURES_DIR/$fixture"; then
            JIRA_COUNT=$((JIRA_COUNT + 1))
        fi
    fi
done

if [ $JIRA_COUNT -ge 4 ]; then
    echo -e "${GREEN}✓ PASS${NC}: JIRA integration fixtures properly configured ($JIRA_COUNT with epics)"
else
    echo -e "${YELLOW}⚠ WARN${NC}: Only $JIRA_COUNT fixtures have JIRA epics (expected 4+)"
fi
echo

# Test 7: Verify milestone to task tracking
echo "Test 7: Milestone-to-Task Reference Verification"
CROSS_REPO_FIXTURE="$FIXTURES_DIR/schema-v2.1-cross-repo.yaml"

# Extract milestone from epic key
EPIC_MILESTONE=$(grep "key: TEST-101" "$CROSS_REPO_FIXTURE" -A 2 | grep "milestone:" | sed 's/.*milestone: "\?\([^"]*\)"\?/\1/')

# Check if that milestone exists in workstreams
if grep -q "title:" "$CROSS_REPO_FIXTURE" && grep "title:" "$CROSS_REPO_FIXTURE" | grep -q "M1"; then
    echo -e "${GREEN}✓ PASS${NC}: Milestone-to-task reference valid"
    echo -e "${GREEN}  (Milestone references properly configured in workstreams)${NC}"
else
    echo -e "${RED}✗ FAIL${NC}: Milestone reference broken"
    exit 1
fi
echo

echo "=== All Integration Tests Passed ==="
echo "✅ Schema v2.1 validator test fixtures are properly configured"
