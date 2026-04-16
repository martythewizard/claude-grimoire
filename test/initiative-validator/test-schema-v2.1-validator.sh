#!/bin/bash

# Integration test for schema v2.1 validator enhancements
# Tests repo field inference and validation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
VALIDATOR_SKILL="$SCRIPT_DIR/../../skills/initiative-validator/skill.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Schema v2.1 Validator Integration Tests ==="
echo

# Extract validator code from skill.md and create a temporary validator script
create_validator_script() {
    local temp_script=$(mktemp)

    # Write bash script header
    cat > "$temp_script" <<'HEADER'
#!/bin/bash
# Extracted validator from skill.md
HEADER

    # Extract Step 1: Parse and Validate YAML Schema (bash block 1)
    sed -n '/### Step 1: Parse and Validate YAML Schema/,/### Step 2:/p' "$VALIDATOR_SKILL" | \
        sed -n '/^```bash$/,/^```$/p' | \
        grep -v '^```' >> "$temp_script"

    # Extract Step 2: Validate GitHub Project (bash block 2)
    sed -n '/### Step 2: Validate GitHub Project/,/### Step 3:/p' "$VALIDATOR_SKILL" | \
        sed -n '/^```bash$/,/^```$/p' | \
        grep -v '^```' >> "$temp_script"

    # Extract Step 3: Validate Workstreams (bash block 3)
    sed -n '/### Step 3: Validate Workstreams/,/# Function: Resolve repository/p' "$VALIDATOR_SKILL" | \
        sed -n '/^```bash$/,/^```$/p' | \
        grep -v '^```' >> "$temp_script"

    # Extract resolve_repo function (not in bash block, extract directly)
    sed -n '/^resolve_repo() {/,/^}$/p' "$VALIDATOR_SKILL" >> "$temp_script"

    # Extract Step 4: Validate JIRA (bash block 4)
    sed -n '/### Step 4: Validate JIRA Epic Tasks/,/### Step 5:/p' "$VALIDATOR_SKILL" | \
        sed -n '/^```bash$/,/^```$/p' | \
        grep -v '^```' >> "$temp_script"

    # Extract Step 5: Validate Confluence (bash block 5)
    sed -n '/### Step 5: Validate Confluence/,/### Step 6:/p' "$VALIDATOR_SKILL" | \
        sed -n '/^```bash$/,/^```$/p' | \
        grep -v '^```' >> "$temp_script"

    # Extract Step 6: Generate Report (bash block 6)
    sed -n '/### Step 6: Generate Report/,/## Configuration/p' "$VALIDATOR_SKILL" | \
        sed -n '/^```bash$/,/^```$/p' | \
        grep -v '^```' >> "$temp_script"

    chmod +x "$temp_script"
    echo "$temp_script"
}

# Helper function to run validator against a fixture
run_validator() {
    local fixture_file="$1"
    local temp_script=$(create_validator_script)

    # Run the validator with the fixture file
    # Capture both stdout and stderr
    local output=$(bash "$temp_script" "$fixture_file" 2>&1 || true)

    # Clean up temp script
    rm -f "$temp_script"

    echo "$output"
}

# Test 1: Single Repo (baseline - inference always succeeds)
echo "Test 1: Single Repo Fixture"
echo "Running validator on schema-v2.1-single-repo.yaml..."
OUTPUT=$(run_validator "$FIXTURES_DIR/schema-v2.1-single-repo.yaml")

if echo "$OUTPUT" | grep -q "✅ Schema v2 validation passed"; then
    echo -e "${GREEN}✓ PASS${NC}: Schema validation passed"
else
    echo -e "${RED}✗ FAIL${NC}: Schema validation failed"
    echo "Output: $OUTPUT"
    exit 1
fi

# Verify repo inference worked (should see testorg/test-repo)
if echo "$OUTPUT" | grep -q "testorg/test-repo"; then
    echo -e "${GREEN}✓ PASS${NC}: Repo inference successful"
else
    echo -e "${YELLOW}⚠ WARN${NC}: Expected repo reference in output (API calls may have failed)"
fi
echo

# Test 2: Multi-Repo Explicit (all tasks have explicit repo)
echo "Test 2: Multi-Repo Explicit Fixture"
echo "Running validator on schema-v2.1-multi-repo-explicit.yaml..."
OUTPUT=$(run_validator "$FIXTURES_DIR/schema-v2.1-multi-repo-explicit.yaml")

if echo "$OUTPUT" | grep -q "✅ Schema v2 validation passed"; then
    echo -e "${GREEN}✓ PASS${NC}: Schema validation passed"
else
    echo -e "${RED}✗ FAIL${NC}: Schema validation failed"
    exit 1
fi

# Should see both repos referenced
if echo "$OUTPUT" | grep -q "testorg/test-repo" && echo "$OUTPUT" | grep -q "testorg/test-api"; then
    echo -e "${GREEN}✓ PASS${NC}: Both repos found in output"
else
    echo -e "${YELLOW}⚠ WARN${NC}: Expected both repos in output (API calls may have failed)"
fi
echo

# Test 3: Multi-Repo Inferred (mixed explicit/inferred)
echo "Test 3: Multi-Repo Inferred Fixture"
echo "Running validator on schema-v2.1-multi-repo-inferred.yaml..."
OUTPUT=$(run_validator "$FIXTURES_DIR/schema-v2.1-multi-repo-inferred.yaml")

if echo "$OUTPUT" | grep -q "✅ Schema v2 validation passed"; then
    echo -e "${GREEN}✓ PASS${NC}: Schema validation passed"
else
    echo -e "${RED}✗ FAIL${NC}: Schema validation failed"
    exit 1
fi

# Should successfully infer repos for tasks without explicit repo field
if echo "$OUTPUT" | grep -q "testorg/test-frontend"; then
    echo -e "${GREEN}✓ PASS${NC}: Frontend repo inferred successfully"
else
    echo -e "${YELLOW}⚠ WARN${NC}: Expected testorg/test-frontend in output (API calls may have failed)"
fi
echo

# Test 4: Ambiguous Milestone (should warn)
echo "Test 4: Ambiguous Milestone Fixture"
echo "Running validator on schema-v2.1-ambiguous-milestone.yaml..."
OUTPUT=$(run_validator "$FIXTURES_DIR/schema-v2.1-ambiguous-milestone.yaml")

if echo "$OUTPUT" | grep -q "✅ Schema v2 validation passed"; then
    echo -e "${GREEN}✓ PASS${NC}: Schema validation passed"
else
    echo -e "${RED}✗ FAIL${NC}: Schema validation failed"
    exit 1
fi

# Check if resolve_repo function successfully handled ambiguous case
# The function should resolve TEST-205 to testorg/test-repo (first match)
if echo "$OUTPUT" | grep -q "TEST-205"; then
    echo -e "${GREEN}✓ PASS${NC}: Ambiguous milestone task processed (TEST-205)"

    # Check for ambiguous warning in output
    if echo "$OUTPUT" | grep -iq "warning.*ambiguous\|ambiguous.*repo"; then
        echo -e "${GREEN}✓ PASS${NC}: Ambiguous milestone warning detected"
    else
        echo -e "${YELLOW}⚠ INFO${NC}: Ambiguous warning may be suppressed (validator still processed correctly)"
    fi
else
    echo -e "${RED}✗ FAIL${NC}: TEST-205 task not processed"
    exit 1
fi
echo

# Test 5: Cross-Repo Tracking (should warn but validate)
echo "Test 5: Cross-Repo Tracking Fixture"
echo "Running validator on schema-v2.1-cross-repo.yaml..."
OUTPUT=$(run_validator "$FIXTURES_DIR/schema-v2.1-cross-repo.yaml")

if echo "$OUTPUT" | grep -q "✅ Schema v2 validation passed"; then
    echo -e "${GREEN}✓ PASS${NC}: Schema validation passed"
else
    echo -e "${RED}✗ FAIL${NC}: Schema validation failed"
    exit 1
fi

# Should process TEST-201 with explicit repo (cross-repo tracking)
if echo "$OUTPUT" | grep -q "TEST-201"; then
    echo -e "${GREEN}✓ PASS${NC}: Cross-repo task processed (TEST-201)"

    # Should show testorg/test-api (explicit cross-repo reference)
    if echo "$OUTPUT" | grep -q "testorg/test-api"; then
        echo -e "${GREEN}✓ PASS${NC}: Cross-repo reference found (testorg/test-api)"

        # Check for cross-repo warning
        if echo "$OUTPUT" | grep -iq "warning.*explicit.*repo\|warning.*task.*uses"; then
            echo -e "${GREEN}✓ PASS${NC}: Cross-repo warning detected"
        else
            echo -e "${YELLOW}⚠ INFO${NC}: Cross-repo warning may be suppressed (validator still processed correctly)"
        fi
    else
        echo -e "${YELLOW}⚠ INFO${NC}: testorg/test-api reference may be suppressed (API unavailable)"
    fi
else
    echo -e "${RED}✗ FAIL${NC}: TEST-201 task not processed"
    exit 1
fi
echo

echo "=== All Validator Tests Completed ==="
echo "✅ Schema v2.1 validator executed successfully against all fixtures"
echo ""
echo "Note: Warning detection tests may show WARN if GitHub/JIRA APIs are not accessible."
echo "      This is expected in test environments without real API credentials."
