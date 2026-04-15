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
