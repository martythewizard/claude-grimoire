#!/usr/bin/env bash
# Test initiative YAML parsing functionality

set -e

echo "Testing github-context-agent initiative YAML parsing..."

# Test 1: List all initiatives
echo "Test 1: List all initiatives"
initiatives=$(gh api repos/eci-global/initiatives/contents/initiatives --jq '.[].name' | head -5)
count=$(echo "$initiatives" | wc -l)

if [ "$count" -ge 1 ]; then
  echo "✓ Found $count initiatives"
else
  echo "✗ Failed to list initiatives"
  exit 1
fi

# Test 2: Fetch specific YAML
echo ""
echo "Test 2: Fetch specific YAML file"
yaml_file="2026-q1-coralogix-quota-manager.yaml"
yaml_content=$(gh api repos/eci-global/initiatives/contents/initiatives/$yaml_file --jq '.content' | base64 -d)

if echo "$yaml_content" | grep -q "schema_version: 2"; then
  echo "✓ YAML fetched and contains schema_version: 2"
else
  echo "✗ YAML fetch failed or missing schema_version"
  exit 1
fi

# Test 3: Parse required fields
echo ""
echo "Test 3: Validate required fields present"
name=$(echo "$yaml_content" | grep "^name:" | cut -d'"' -f2)
status=$(echo "$yaml_content" | grep "^status:" | awk '{print $2}')
owner=$(echo "$yaml_content" | grep "^owner:" | awk '{print $2}')

if [ -n "$name" ] && [ -n "$status" ] && [ -n "$owner" ]; then
  echo "✓ Required fields present:"
  echo "  name: $name"
  echo "  status: $status"
  echo "  owner: $owner"
else
  echo "✗ Missing required fields"
  exit 1
fi

# Test 4: Parse github_project if present
echo ""
echo "Test 4: Check github_project section"
if echo "$yaml_content" | grep -q "github_project:"; then
  project_org=$(echo "$yaml_content" | awk '/github_project:/,/^[a-z]/ {print}' | grep "org:" | awk '{print $2}')
  project_number=$(echo "$yaml_content" | awk '/github_project:/,/^[a-z]/ {print}' | grep "number:" | awk '{print $2}')

  if [ -n "$project_org" ] && [ -n "$project_number" ]; then
    echo "✓ github_project found:"
    echo "  org: $project_org"
    echo "  number: $project_number"
  else
    echo "✓ github_project present but incomplete (acceptable)"
  fi
else
  echo "✓ No github_project section (acceptable)"
fi

# Test 5: Parse workstreams if present
echo ""
echo "Test 5: Check workstreams section"
if echo "$yaml_content" | grep -q "workstreams:"; then
  workstream_count=$(echo "$yaml_content" | grep -c "  - name:" || true)
  echo "✓ Found $workstream_count workstream(s)"
else
  echo "✓ No workstreams section (acceptable)"
fi

# Test 6: Status enum validation
echo ""
echo "Test 6: Validate status enum"
valid_statuses=("active" "planning" "paused" "completed" "cancelled")
status_valid=false

for valid_status in "${valid_statuses[@]}"; do
  if [ "$status" = "$valid_status" ]; then
    status_valid=true
    break
  fi
done

if [ "$status_valid" = true ]; then
  echo "✓ Status '$status' is valid"
else
  echo "✗ Status '$status' is not valid (must be: active, planning, paused, completed, cancelled)"
  exit 1
fi

echo ""
echo "=========================================="
echo "All initiative YAML parsing tests passed!"
echo "=========================================="
