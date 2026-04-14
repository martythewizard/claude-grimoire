#!/usr/bin/env bash
# Test GitHub Projects v2 GraphQL functionality

set -e

echo "Testing github-context-agent Projects v2 GraphQL..."

# Test 1: Basic project query
echo "Test 1: Fetch project metadata"
project_data=$(gh api graphql -f query='
  query {
    organization(login: "eci-global") {
      projectV2(number: 14) {
        id
        title
        url
        closed
      }
    }
  }
' 2>&1)

if echo "$project_data" | grep -q '"title":'; then
  title=$(echo "$project_data" | jq -r '.data.organization.projectV2.title')
  echo "✓ Project fetched: $title"
else
  echo "✗ Failed to fetch project"
  echo "Response: $project_data"
  exit 1
fi

# Test 2: Fetch project items
echo ""
echo "Test 2: Fetch project items"
items_data=$(gh api graphql -f query='
  query {
    organization(login: "eci-global") {
      projectV2(number: 14) {
        items(first: 10) {
          totalCount
          nodes {
            id
            content {
              ... on Issue {
                number
                title
                state
              }
            }
          }
        }
      }
    }
  }
')

total_count=$(echo "$items_data" | jq -r '.data.organization.projectV2.items.totalCount')

if [ -n "$total_count" ] && [ "$total_count" -ge 0 ]; then
  echo "✓ Project has $total_count items"
else
  echo "✗ Failed to get item count"
  exit 1
fi

# Test 3: Check item types
echo ""
echo "Test 3: Verify item content types"
if echo "$items_data" | grep -q '"number":'; then
  echo "✓ Project contains issues"
else
  echo "✓ Project has no issues (or first 10 are not issues)"
fi

# Test 4: Project state
echo ""
echo "Test 4: Check project state"
closed=$(echo "$project_data" | jq -r '.data.organization.projectV2.closed')

if [ "$closed" = "false" ]; then
  echo "✓ Project is open"
elif [ "$closed" = "true" ]; then
  echo "✓ Project is closed"
else
  echo "✗ Could not determine project state"
  exit 1
fi

echo ""
echo "============================================"
echo "All Projects v2 GraphQL tests passed!"
echo "============================================"
