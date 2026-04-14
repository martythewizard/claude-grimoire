#!/usr/bin/env bash
# Test parameter parsing logic

set -e

echo "Testing initiative-creator parameter parsing..."

# Helper function to parse parameters
parse_params() {
  # Initialize variables
  issue=""
  title=""
  body=""
  repo=""
  project=""
  initiative=""
  milestone=""
  label=""
  assignee=""
  force_yaml=false

  # Parse parameters
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --issue)
        issue="$2"
        shift 2
        ;;
      --title)
        title="$2"
        shift 2
        ;;
      --body)
        body="$2"
        shift 2
        ;;
      --repo)
        repo="$2"
        shift 2
        ;;
      --project)
        project="$2"
        shift 2
        ;;
      --initiative)
        initiative="$2"
        shift 2
        ;;
      --milestone)
        milestone="$2"
        shift 2
        ;;
      --label)
        label="$2"
        shift 2
        ;;
      --assignee)
        assignee="$2"
        shift 2
        ;;
      --yaml)
        force_yaml=true
        shift
        ;;
      *)
        shift
        ;;
    esac
  done

  # Determine mode
  if [ "$force_yaml" = true ]; then
    echo "full-initiative"
  elif [ -n "$issue" ] || [ -n "$project" ] || [ -n "$initiative" ] || [ -n "$milestone" ]; then
    echo "linking"
  elif [ -n "$title" ] && [ -n "$body" ]; then
    echo "standalone"
  else
    echo "interactive"
  fi
}

# Test cases
echo "Test 1: Standalone issue parameters"
mode=$(parse_params --title "Fix bug" --body "Description" --repo owner/repo)
if [ "$mode" = "standalone" ]; then
  echo "✓ Detected standalone mode"
else
  echo "✗ Expected standalone, got $mode"
  exit 1
fi

echo ""
echo "Test 2: Linking to project"
mode=$(parse_params --issue owner/repo#123 --project org#14)
if [ "$mode" = "linking" ]; then
  echo "✓ Detected linking mode"
else
  echo "✗ Expected linking, got $mode"
  exit 1
fi

echo ""
echo "Test 3: Create and link"
mode=$(parse_params --title "Task" --body "Desc" --repo owner/repo --project org#14)
if [ "$mode" = "linking" ]; then
  echo "✓ Detected linking mode (create + link)"
else
  echo "✗ Expected linking, got $mode"
  exit 1
fi

echo ""
echo "Test 4: Force YAML mode"
mode=$(parse_params --yaml)
if [ "$mode" = "full-initiative" ]; then
  echo "✓ Detected full-initiative mode"
else
  echo "✗ Expected full-initiative, got $mode"
  exit 1
fi

echo ""
echo "Test 5: No parameters (interactive)"
mode=$(parse_params)
if [ "$mode" = "interactive" ]; then
  echo "✓ Detected interactive mode"
else
  echo "✗ Expected interactive, got $mode"
  exit 1
fi

echo ""
echo "Test 6: Link to initiative YAML"
mode=$(parse_params --issue owner/repo#123 --initiative initiatives/file.yaml)
if [ "$mode" = "linking" ]; then
  echo "✓ Detected linking mode (to initiative)"
else
  echo "✗ Expected linking, got $mode"
  exit 1
fi

echo ""
echo "Test 7: Assign to milestone"
mode=$(parse_params --title "Task" --body "Desc" --repo owner/repo --milestone "M1")
if [ "$mode" = "linking" ]; then
  echo "✓ Detected linking mode (milestone assignment)"
else
  echo "✗ Expected linking, got $mode"
  exit 1
fi

echo ""
echo "Test 8: Full parameter set"
mode=$(parse_params \
  --title "Feature" \
  --body "Description" \
  --repo owner/repo \
  --project org#14 \
  --initiative initiatives/file.yaml \
  --milestone "M1" \
  --label feature,high \
  --assignee user)
if [ "$mode" = "linking" ]; then
  echo "✓ Detected linking mode (full parameters)"
else
  echo "✗ Expected linking, got $mode"
  exit 1
fi

echo ""
echo "Test 9: --yaml overrides other parameters"
mode=$(parse_params --yaml --title "Task" --body "Desc" --project org#14)
if [ "$mode" = "full-initiative" ]; then
  echo "✓ Detected full-initiative mode (--yaml overrides)"
else
  echo "✗ Expected full-initiative, got $mode"
  exit 1
fi

echo ""
echo "============================================="
echo "All parameter parsing tests passed!"
echo "============================================="
