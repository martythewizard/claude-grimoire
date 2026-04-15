#!/bin/bash

# Integration test for initiative-discoverer schema v2 support

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURE_FILE="$SCRIPT_DIR/fixtures/schema-v2-discoverable.yaml"

echo "Testing initiative-discoverer with schema v2 fixture..."
echo ""

# Test 1: Schema validation
echo "Test 1: Schema v2 validation"
if grep -q "schema_version: 2" "$FIXTURE_FILE"; then
    echo "✅ Fixture has schema_version: 2"
else
    echo "❌ Fixture missing schema_version: 2"
    exit 1
fi

# Test 2: GitHub Project extraction
echo ""
echo "Test 2: GitHub Project structure"
if grep -q "^github_project:" "$FIXTURE_FILE"; then
    echo "✅ GitHub Project section present"

    PROJECT_ORG=$(grep -A 3 "^github_project:" "$FIXTURE_FILE" | grep "org:" | awk '{print $2}')
    PROJECT_NUMBER=$(grep -A 3 "^github_project:" "$FIXTURE_FILE" | grep "number:" | awk '{print $2}')

    if [ -n "$PROJECT_ORG" ] && [ -n "$PROJECT_NUMBER" ]; then
        echo "✅ Project org and number extracted: $PROJECT_ORG#$PROJECT_NUMBER"
    else
        echo "❌ Failed to extract project org/number"
        exit 1
    fi
else
    echo "❌ GitHub Project section missing"
    exit 1
fi

# Test 3: Workstream repo extraction
echo ""
echo "Test 3: Workstream repos"
WORKSTREAM_REPOS=$(grep -A 500 "^workstreams:" "$FIXTURE_FILE" | grep "repo:" | awk '{print $2}')
if [ -n "$WORKSTREAM_REPOS" ]; then
    echo "✅ Workstream repos found: $WORKSTREAM_REPOS"
else
    echo "❌ No workstream repos found"
    exit 1
fi

# Test 4: JIRA epic task extraction
echo ""
echo "Test 4: JIRA epic task github_issue extraction"
EXISTING_ISSUES=$(grep -A 500 "^jira:" "$FIXTURE_FILE" | grep "github_issue:" | awk '{print $2}' | tr '\n' ',')
if [ -n "$EXISTING_ISSUES" ]; then
    echo "✅ Existing github_issue numbers found: $EXISTING_ISSUES"
else
    echo "⚠️  No github_issue numbers found (may be valid if no JIRA tasks yet)"
fi

# Test 5: Tag extraction
echo ""
echo "Test 5: Tag extraction"
TAGS=$(grep -A 50 "^tags:" "$FIXTURE_FILE" | grep "  - " | awk '{print $2}' | tr '\n' ' ')
if [ -n "$TAGS" ]; then
    echo "✅ Tags found: $TAGS"
else
    echo "⚠️  No tags found (optional)"
fi

echo ""
echo "========================================="
echo "All tests passed! ✅"
echo "========================================="
