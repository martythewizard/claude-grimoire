#!/bin/bash
# Visual PRD Verification Script
# Tests that the generated PRD contains all required sections

PRD_FILE="docs/prds/2026-04-23-task-comments.html"
PASSED=0
FAILED=0

echo "🔍 Verifying Visual PRD: $PRD_FILE"
echo ""

# Check if file exists
if [ ! -f "$PRD_FILE" ]; then
    echo "❌ FAIL: PRD file not found"
    exit 1
fi

echo "✅ PRD file exists ($(du -h "$PRD_FILE" | cut -f1))"
echo ""

# Function to check for content
check_content() {
    local search_term="$1"
    local description="$2"

    if grep -q "$search_term" "$PRD_FILE"; then
        echo "✅ $description"
        ((PASSED++))
    else
        echo "❌ $description"
        ((FAILED++))
    fi
}

# Verify HTML structure
echo "📄 HTML Structure:"
check_content "<!DOCTYPE html>" "Valid HTML5 doctype"
check_content "<meta charset=\"UTF-8\">" "UTF-8 encoding"
check_content "<meta name=\"viewport\"" "Responsive viewport meta"
check_content "mermaid.min.js" "Mermaid.js library loaded"
echo ""

# Verify sections
echo "📑 Content Sections:"
check_content "id=\"overview\"" "Overview section"
check_content "id=\"mockups\"" "UI Mockups section"
check_content "id=\"flows\"" "User Flows section"
check_content "id=\"architecture\"" "Architecture section"
check_content "id=\"requirements\"" "Requirements section"
check_content "id=\"nonfunctional\"" "Non-functional requirements section"
check_content "id=\"technical\"" "Technical considerations section"
echo ""

# Verify UI mockups
echo "🎨 UI Mockups:"
check_content "Mockup 1: Comment List View" "Comment list mockup"
check_content "Mockup 2: Add Comment Form" "Add comment form mockup"
check_content "Mockup 3: Edit Comment State" "Edit comment mockup"
check_content "Mockup 4: Empty State" "Empty state mockup"
check_content "Mockup 5: Error State" "Error state mockup"
check_content "class=\"comment\"" "CSS for comment styling"
check_content "class=\"comment-form\"" "CSS for comment form styling"
echo ""

# Verify diagrams
echo "📊 Diagrams (Mermaid):"
check_content "graph TD" "User flow diagrams"
check_content "sequenceDiagram" "Sequence diagrams"
check_content "erDiagram" "Entity relationship diagram"
check_content "class=\"mermaid\"" "Mermaid diagram containers"
echo ""

# Verify requirements
echo "📋 Requirements:"
check_content "FR-1: Add Comment" "Functional requirement 1"
check_content "FR-2: View Comments" "Functional requirement 2"
check_content "FR-3: Edit Comment" "Functional requirement 3"
check_content "FR-4: Delete Comment" "Functional requirement 4"
check_content "Acceptance Criteria:" "Acceptance criteria sections"
check_content "NFR-1: Performance" "Non-functional requirements"
echo ""

# Verify technical details
echo "🔧 Technical Details:"
check_content "Architecture Decisions" "Architecture decision records"
check_content "CREATE TABLE comments" "Database schema"
check_content "API Endpoints" "API documentation"
check_content "Implementation Plan" "Implementation phases"
check_content "Testing Strategy" "Testing strategy"
check_content "Monitoring and Observability" "Monitoring section"
check_content "Security Considerations" "Security considerations"
check_content "Rollback Plan" "Rollback plan"
echo ""

# Verify styling
echo "🎨 Styling:"
check_content "font-family:" "Custom fonts"
check_content "border-radius:" "Modern rounded corners"
check_content "box-shadow:" "Depth with shadows"
check_content ".mockup {" "Mockup styling"
check_content ".requirement {" "Requirement styling"
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Results: $PASSED passed, $FAILED failed"

if [ $FAILED -eq 0 ]; then
    echo "✅ All checks passed! Visual PRD is complete."
    exit 0
else
    echo "❌ Some checks failed. Review PRD content."
    exit 1
fi
