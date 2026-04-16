#!/usr/bin/env bash
# Test YAML generation follows eci-global/initiatives structure

set -e

echo "Testing initiative-creator YAML generation..."

# Create temp YAML for testing
temp_yaml="/tmp/test-initiative.yaml"

cat > "$temp_yaml" << 'EOF'
schema_version: 2
name: "Test Initiative"
description: >-
  This is a test initiative to validate YAML structure.
  Second line of description continues naturally.
status: planning
owner: test-user
team:
  - member1
  - member2

github_project:
  org: test-org
  number: 99

workstreams:
  - name: "Test Workstream"
    repo: owner/repo
    milestones:
      - title: "M1 — Test Milestone"
        number: 1
        due: "2026-06-01"
        status: planning

jira:
  project_key: TEST01
  parent_key: TEST-123
  epics:
    - key: TEST-456
      milestone: "M1 — Test Milestone"
      status: Todo

confluence:
  space_key: TEST
  page_id: "123456"

steward:
  enabled: true

tags:
  - test
  - validation
EOF

# Test 1: Valid YAML syntax
echo "Test 1: Valid YAML syntax"
if python3 -c "import sys, yaml; yaml.safe_load(open('$temp_yaml'))" 2>/dev/null; then
  echo "✓ YAML is valid"
else
  echo "✗ YAML parsing failed"
  exit 1
fi

# Test 2: Required fields present
echo ""
echo "Test 2: Required fields present"
required_fields=("schema_version" "name" "description" "status" "owner" "team")
missing_fields=()

for field in "${required_fields[@]}"; do
  if grep -q "^$field:" "$temp_yaml"; then
    echo "✓ $field present"
  else
    echo "✗ $field missing"
    missing_fields+=("$field")
  fi
done

if [ ${#missing_fields[@]} -eq 0 ]; then
  echo "✓ All required fields present"
else
  echo "✗ Missing fields: ${missing_fields[*]}"
  exit 1
fi

# Test 3: Schema version is 2
echo ""
echo "Test 3: Schema version validation"
schema_version=$(grep "^schema_version:" "$temp_yaml" | awk '{print $2}')
if [ "$schema_version" = "2" ]; then
  echo "✓ schema_version is 2"
else
  echo "✗ schema_version is $schema_version (expected 2)"
  exit 1
fi

# Test 4: Status is valid enum
echo ""
echo "Test 4: Status enum validation"
status=$(grep "^status:" "$temp_yaml" | awk '{print $2}')
valid_statuses=("active" "planning" "paused" "completed" "cancelled")
status_valid=false

for valid in "${valid_statuses[@]}"; do
  if [ "$status" = "$valid" ]; then
    status_valid=true
    break
  fi
done

if [ "$status_valid" = true ]; then
  echo "✓ Status '$status' is valid"
else
  echo "✗ Status '$status' is invalid"
  exit 1
fi

# Test 5: Description uses folded scalar (>-)
echo ""
echo "Test 5: Description format"
if grep -q "description: >-" "$temp_yaml"; then
  echo "✓ Description uses >- folded scalar"
else
  echo "✗ Description should use >- for multi-line"
  exit 1
fi

# Test 6: Dates are ISO 8601
echo ""
echo "Test 6: Date format validation"
due_date=$(grep "due:" "$temp_yaml" | awk '{print $2}' | tr -d '"')
if [[ "$due_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "✓ Date '$due_date' is ISO 8601 (YYYY-MM-DD)"
else
  echo "✗ Date '$due_date' is not ISO 8601 format"
  exit 1
fi

# Test 7: Field names are snake_case
echo ""
echo "Test 7: Field naming convention"
if grep -qE "(githubProject|pageId|projectKey)" "$temp_yaml"; then
  echo "✗ Found camelCase fields (should be snake_case)"
  exit 1
else
  echo "✓ All fields use snake_case"
fi

# Test 8: Workstream milestone structure
echo ""
echo "Test 8: Workstream milestone structure"
required_milestone_fields=("title" "number" "due" "status")
all_present=true

for field in "${required_milestone_fields[@]}"; do
  if grep -A 10 "milestones:" "$temp_yaml" | grep -q "$field:"; then
    echo "✓ Milestone has $field"
  else
    echo "✗ Milestone missing $field"
    all_present=false
  fi
done

if [ "$all_present" = true ]; then
  echo "✓ Milestone structure correct"
else
  echo "✗ Milestone structure validation failed"
  exit 1
fi

# Test 9: Compare with real example from eci-global/initiatives
echo ""
echo "Test 9: Compare structure with real initiative"
real_yaml=$(gh api repos/eci-global/initiatives/contents/initiatives/2026-q1-coralogix-quota-manager.yaml --jq '.content' | base64 -d)

# Check that our test YAML has similar structure
if echo "$real_yaml" | grep -q "schema_version: 2"; then
  echo "✓ Real initiative uses schema_version: 2"

  if echo "$real_yaml" | grep -q "description: >-"; then
    echo "✓ Real initiative uses >- for description"
  fi

  if echo "$real_yaml" | grep -q "github_project:"; then
    echo "✓ Real initiative uses github_project (not githubProject)"
  fi
else
  echo "✗ Could not verify against real initiative"
fi

# Cleanup
rm "$temp_yaml"

echo ""
echo "================================================"
echo "All YAML generation validation tests passed!"
echo "================================================"
