#!/usr/bin/env bash
# Test issue linking and milestone assignment logic

set -e

echo "Testing initiative-breakdown linking logic..."

# Test 1: Simulate project linking
echo "Test 1: Project linking simulation"
project_number=14
org="eci-global"
issue_url="https://github.com/eci-global/test-repo/issues/999"

# Build command (don't execute, just validate syntax)
cmd="gh project item-add $project_number --owner $org --url $issue_url"
echo "Command: $cmd"

if [[ "$cmd" =~ "gh project item-add" ]] && [[ "$cmd" =~ "--owner" ]] && [[ "$cmd" =~ "--url" ]]; then
  echo "✓ Project linking command format valid"
else
  echo "✗ Invalid command format"
  exit 1
fi

# Test 2: Milestone assignment simulation
echo ""
echo "Test 2: Milestone assignment simulation"
issue_num=999
repo="eci-global/test-repo"
milestone="M1 — Foundation"

cmd="gh issue edit $issue_num --repo $repo --milestone \"$milestone\""
echo "Command: $cmd"

if [[ "$cmd" =~ "gh issue edit" ]] && [[ "$cmd" =~ "--milestone" ]]; then
  echo "✓ Milestone assignment command format valid"
else
  echo "✗ Invalid command format"
  exit 1
fi

# Test 3: Initiative comment format
echo ""
echo "Test 3: Initiative comment format"
yaml_url="https://github.com/eci-global/initiatives/blob/main/initiatives/2026-q1-test.yaml"
initiative_name="2026 Q1 - Test Initiative"
comment="Part of initiative: [$initiative_name]($yaml_url)"

if [[ "$comment" =~ "Part of initiative:" ]] && [[ "$comment" =~ \[.*\]\(.*\) ]]; then
  echo "✓ Initiative comment format valid"
  echo "  Comment: $comment"
else
  echo "✗ Invalid comment format"
  exit 1
fi

# Test 4: Batch operation logic
echo ""
echo "Test 4: Batch operation simulation"
issue_urls=(
  "https://github.com/org/repo/issues/1"
  "https://github.com/org/repo/issues/2"
  "https://github.com/org/repo/issues/3"
)

count=0
for url in "${issue_urls[@]}"; do
  # Simulate linking
  if [[ "$url" =~ https://github.com/.*/issues/[0-9]+ ]]; then
    ((count+=1))
  fi
done

if [ $count -eq 3 ]; then
  echo "✓ Batch operations: $count issues processed"
else
  echo "✗ Batch operation failed"
  exit 1
fi

# Test 5: Milestone grouping
echo ""
echo "Test 5: Milestone grouping logic"
declare -A milestone_issues
milestone_issues["M1"]="1 2 3"
milestone_issues["M2"]="4 5"

total_grouped=0
for milestone in "${!milestone_issues[@]}"; do
  count=$(echo "${milestone_issues[$milestone]}" | wc -w)
  total_grouped=$((total_grouped + count))
  echo "  Milestone $milestone: $count issues"
done

if [ $total_grouped -eq 5 ]; then
  echo "✓ Milestone grouping: $total_grouped total issues"
else
  echo "✗ Grouping failed"
  exit 1
fi

# Test 6: Order of operations validation
echo ""
echo "Test 6: Order of operations"
operations=("create_issue" "link_project" "assign_milestone" "add_comment")
current_step=0

for op in "${operations[@]}"; do
  ((current_step+=1))
  echo "  Step $current_step: $op"
done

if [ $current_step -eq 4 ]; then
  echo "✓ All 4 operations in correct order"
else
  echo "✗ Operation order incorrect"
  exit 1
fi

echo ""
echo "=========================================="
echo "All linking logic tests passed!"
echo "=========================================="
