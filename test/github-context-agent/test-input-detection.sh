#!/usr/bin/env bash
# Test input type detection logic

echo "Testing github-context-agent input type detection..."

# Helper function to detect type from identifier
detect_type() {
  local identifier="$1"

  # URL patterns
  if [[ "$identifier" =~ https://github\.com/.*/issues/ ]]; then
    echo "issue"
  elif [[ "$identifier" =~ https://github\.com/.*/pull/ ]]; then
    echo "pr"
  elif [[ "$identifier" =~ https://github\.com/orgs/.*/projects/ ]]; then
    echo "project"
  elif [[ "$identifier" =~ https://github\.com/.*/projects/ ]]; then
    echo "project"
  # Format patterns
  elif [[ "$identifier" =~ ^[^/]+/[^/]+#[0-9]+$ ]]; then
    echo "issue"  # owner/repo#123
  elif [[ "$identifier" =~ ^[^/]+#[0-9]+$ ]]; then
    echo "project"  # org#123
  elif [[ "$identifier" =~ \.yaml$ ]] || [[ "$identifier" =~ ^initiatives/ ]]; then
    echo "initiative"
  elif [[ "$identifier" =~ milestone: ]]; then
    echo "milestone"
  elif [[ "$identifier" =~ workstream: ]]; then
    echo "workstream"
  else
    echo "ambiguous"
  fi
}

# Test cases
declare -A tests=(
  ["https://github.com/eci-global/repo/issues/123"]="issue"
  ["https://github.com/eci-global/repo/pull/456"]="pr"
  ["https://github.com/orgs/eci-global/projects/14"]="project"
  ["eci-global/repo#123"]="issue"
  ["eci-global#14"]="project"
  ["initiatives/2026-q1-ai-cost.yaml"]="initiative"
  ["2026-q1-coralogix-quota-manager.yaml"]="initiative"
  ["owner/repo milestone:\"M1 - Foundation\""]="milestone"
  ["milestone:5"]="milestone"
  ["initiative:ai-cost workstream:Data Lake"]="workstream"
  ["workstream:Intelligence"]="workstream"
  ["14"]="ambiguous"
  ["cost"]="ambiguous"
)

pass_count=0
fail_count=0

for identifier in "${!tests[@]}"; do
  expected="${tests[$identifier]}"
  actual=$(detect_type "$identifier")

  if [ "$actual" = "$expected" ]; then
    echo "✓ '$identifier' → $actual"
    ((pass_count++))
  else
    echo "✗ '$identifier' → $actual (expected: $expected)"
    ((fail_count++))
  fi
done

echo ""
echo "=========================================="
echo "Input detection tests:"
echo "  Passed: $pass_count"
echo "  Failed: $fail_count"
echo "=========================================="

if [ $fail_count -eq 0 ]; then
  echo "All tests passed!"
  exit 0
else
  echo "Some tests failed!"
  exit 1
fi
