# initiative-creator Flexibility - Plan Complete

**Status:** COMPLETE  
**Date:** 2026-04-13  
**Tasks:** 9/9 Complete  
**Tests:** 18/18 Pass  
**Version:** 2.0.0

## Summary

Plan 2 successfully upgraded the initiative-creator skill from v1.0.0 to v2.0.0, transforming it from a single-purpose YAML generation tool into a flexible, multi-mode workflow system. All 9 tasks completed successfully with comprehensive testing and documentation.

The skill now supports three distinct modes:
1. **Standalone Issue Mode** - Quick issue creation without initiative overhead
2. **Linking Mode** - Connect issues to existing projects/initiatives/milestones
3. **Full Initiative Mode** - Comprehensive YAML generation (rare, ~10% of use cases)

This change aligns the tool with actual usage patterns while maintaining 100% backward compatibility with v1.0.0 workflows.

## What Was Implemented

### Task 1: Mode Detection (Lines 34-72)
**Files Modified:** `skills/initiative-creator/skill.md`

Implemented intelligent mode detection with two phases:
- **Phase 1:** Parameter parsing - Detect mode from command-line flags
- **Phase 2:** Interactive detection - Ask user "What would you like to create?"

**Parameters that control mode:**
- `--issue` or `--title/--body` with `--project/--initiative/--milestone` → Linking Mode
- `--title/--body` only → Standalone Issue Mode
- `--yaml` → Force Full Initiative Mode
- No parameters → Interactive mode selection

**Result:** Skill routes to appropriate workflow based on user input and needs.

---

### Task 2: Standalone Issue Mode (Lines 81-151)
**Files Modified:** `skills/initiative-creator/skill.md`  
**Files Created:** `skills/initiative-creator/examples/standalone-issue.md`

Implemented quick issue creation workflow:
1. Gather issue details (title, body, repo, labels, assignees)
2. Create issue via `gh issue create`
3. Report completion with suggestion to link later if needed

**Use cases:**
- Quick bug fixes
- Small standalone tasks
- Exploratory work

**Result:** Users can create standalone issues in under 1 minute without initiative overhead.

---

### Task 3: Linking Mode (Lines 153-266)
**Files Modified:** `skills/initiative-creator/skill.md`  
**Files Created:** 
- `skills/initiative-creator/examples/link-to-project.md`
- `skills/initiative-creator/examples/link-to-initiative.md`

Implemented linking workflow for connecting issues to existing resources:

**Workflow:**
1. Get or create issue (use existing or create new)
2. Ask what to link to (Project, Initiative YAML, Milestone, or combination)
3. Verify target exists via github-context-agent
4. Perform linking via appropriate gh commands

**Linking targets:**
- GitHub Projects: `gh project item-add`
- Initiative YAMLs: Comment with link to YAML
- Milestones: `gh issue edit --milestone`

**Result:** Users can organize issues without creating new YAML files.

---

### Task 4: Full Initiative Mode with YAML Generation (Lines 268-479)
**Files Modified:** `skills/initiative-creator/skill.md`  
**Files Created:** 
- `skills/initiative-creator/examples/full-yaml-creation.md`
- `skills/initiative-creator/templates/initiative-template.yaml`

Updated YAML generation to follow eci-global/initiatives schema v2 exactly:

**Key improvements:**
- Uses `schema_version: 2` (not v1 or version)
- Proper field naming: `github_project`, `space_key`, `project_key` (snake_case)
- Folded scalar descriptions: `description: >-`
- ISO 8601 dates: `YYYY-MM-DD` for dates, `YYYY-MM-DDTHH:MM:SSZ` for timestamps
- Conditional sections: Only include sections with actual data (no empty arrays/objects)
- Workstream support with milestone tracking

**Workflow additions:**
- Ask about existing GitHub Project (default: link to existing, not create new)
- Ask about workstreams (multiple repos with milestones)
- Ask about optional integrations (JIRA, Confluence, tags, Steward, Pulse)
- Validate YAML before committing
- Commit to eci-global/initiatives repo

**Result:** YAML files match production schema exactly and validate successfully.

---

### Task 5: Parameter Passing Documentation (Lines 481-563)
**Files Modified:** `skills/initiative-creator/skill.md`  
**Files Created:** `skills/initiative-creator/examples/parameter-passing.md`

Documented comprehensive parameter support for non-interactive invocation:

**Supported parameters:**
- Issue parameters: `--issue`, `--title`, `--body`, `--repo`
- Linking parameters: `--project`, `--initiative`, `--milestone`
- Issue metadata: `--label`, `--assignee`
- Mode control: `--yaml`

**Parameter priority rules:**
1. Parameters override interactive questions
2. Missing parameters trigger interactive prompts for those fields only
3. `--yaml` flag forces Full Initiative Mode regardless of other parameters

**Validation:**
- Issue number must exist if `--issue` provided
- Project must exist if `--project` provided
- Initiative YAML must exist if `--initiative` provided
- Repository must be accessible if `--repo` provided
- Milestone must exist in repo if `--milestone` provided

**Result:** Skills and users can invoke non-interactively for automation.

---

### Task 6: YAML Validation Test
**Files Created:** `test/initiative-creator/test-yaml-generation.sh`

Created comprehensive test suite with 9 tests:

1. **Valid YAML syntax** - Ensures YAML parses without errors
2. **Required fields present** - Validates schema_version, name, description, status, owner, team
3. **Schema version validation** - Checks `schema_version: 2` exactly
4. **Status enum validation** - Verifies status is one of: active, planning, paused, completed, cancelled
5. **Description format** - Ensures `description: >-` folded scalar syntax
6. **Date format validation** - Checks ISO 8601 format: YYYY-MM-DD
7. **Field naming convention** - Validates snake_case (github_project not githubProject)
8. **Workstream milestone structure** - Verifies title, number, due, status fields
9. **Compare with real initiative** - Cross-checks against production eci-global/initiatives example

**Result:** All 9 tests pass. YAML generation verified correct.

---

### Task 7: Parameter Parsing Test
**Files Created:** `test/initiative-creator/test-parameter-parsing.sh`

Created comprehensive test suite with 9 tests:

1. **Standalone issue parameters** - `--title --body --repo` → Standalone Mode
2. **Linking to project** - `--issue --project` → Linking Mode
3. **Create and link** - `--title --body --project` → Linking Mode
4. **Force YAML mode** - `--yaml` → Full Initiative Mode
5. **No parameters (interactive)** - No flags → Interactive mode selection
6. **Link to initiative YAML** - `--issue --initiative` → Linking Mode
7. **Assign to milestone** - `--issue --milestone` → Linking Mode
8. **Full parameter set** - All parameters → Linking Mode
9. **--yaml overrides other parameters** - `--yaml` + other flags → Full Initiative Mode

**Result:** All 9 tests pass. Parameter parsing and mode detection verified correct.

---

### Task 8: Configuration and Examples Update
**Files Modified:** `skills/initiative-creator/skill.md`

Updated documentation for v2.0.0:
- Updated configuration section (lines 564-606) with new settings
- Removed orphaned v1.0.0 sections and references
- Added 5 comprehensive examples showing all modes
- Added Tips for Great Initiatives section
- Added Integration with Other Skills section
- Added Error Handling section
- Added Common Pitfalls to Avoid section

**Configuration additions:**
- `defaultMode`: "issue" | "linking" | "full"
- `assumeProjectExists`: true (ask to link before creating)
- `allowParameters`: true (enable parameter passing)
- `autoCreateVisualPRD`: false (ask user)
- `requireConfirmation`: false (commit after validation)

**Result:** Documentation clean, comprehensive, and accurate for v2.0.0.

---

### Task 9: Final Review and Testing
**Files Modified:** `skills/initiative-creator/skill.md`

Final cleanup and documentation:

**Fixes applied:**
1. Updated version from 1.0.0 to 2.0.0 in frontmatter (line 4)
2. Replaced "Task 2/3/4" references with section names in Mode Workflows (lines 77-79)
3. Removed "(existing questions from v1.0.0)" parenthetical (line 286)

**Migration notes added (lines 865-905):**
- What changed in v2.0.0
- Breaking changes (none)
- Migration path for skills and users
- Recommended usage patterns (90% standalone/linking, 10% full initiative)

**Verification completed:**
- Both test scripts pass (18/18 tests)
- File completeness verified (905 lines, 5 examples, 1 template)
- Final commit created

**Result:** v2.0.0 finalized and ready for production.

## Examples Created

### 1. standalone-issue.md
**Location:** `skills/initiative-creator/examples/standalone-issue.md`  
**Purpose:** Shows quick issue creation without initiative overhead

Example demonstrates:
- Interactive mode selection (choosing Standalone)
- Gathering title, description, repository, labels
- Creating issue via gh CLI
- Output showing standalone status

Use case: Bug fixes, small tasks, exploratory work

---

### 2. link-to-project.md
**Location:** `skills/initiative-creator/examples/link-to-project.md`  
**Purpose:** Shows linking existing issue to GitHub Project

Example demonstrates:
- Using `--issue` and `--project` parameters
- Verifying project exists
- Adding issue to project via `gh project item-add`
- Output confirming linkage

Use case: Organizing issues into project boards

---

### 3. link-to-initiative.md
**Location:** `skills/initiative-creator/examples/link-to-initiative.md`  
**Purpose:** Shows linking issue to initiative YAML and project

Example demonstrates:
- Creating new issue with `--title` and `--body`
- Interactive selection of linking mode
- Searching for initiative YAML by name
- Linking to both project and initiative
- Adding comment with initiative reference

Use case: Tracking work as part of larger initiative

---

### 4. full-yaml-creation.md
**Location:** `skills/initiative-creator/examples/full-yaml-creation.md`  
**Purpose:** Shows comprehensive initiative creation with YAML

Example demonstrates:
- Using `--yaml` flag to force Full Initiative Mode
- Complete interview process for gathering initiative details
- Linking to existing GitHub Project (not creating new)
- Adding workstreams with milestones
- Optional integrations (JIRA, Confluence, tags)
- YAML validation and commit to eci-global/initiatives

Use case: Large multi-week/multi-month initiatives requiring formal tracking

---

### 5. parameter-passing.md
**Location:** `skills/initiative-creator/examples/parameter-passing.md`  
**Purpose:** Shows non-interactive parameter-based invocation

Example demonstrates:
- All 10 supported parameters
- Different parameter combinations for each mode
- Validation behavior
- Error handling for invalid parameters

Use case: Automation scripts, skill-to-skill invocation, batch operations

## Templates Created

### initiative-template.yaml
**Location:** `skills/initiative-creator/templates/initiative-template.yaml`  
**Purpose:** Reference template for YAML generation

Template includes:
- Correct schema_version: 2
- All possible sections with proper structure
- Field naming conventions (snake_case)
- Date format examples (ISO 8601)
- Description folded scalar syntax (`>-`)
- Comments indicating required vs optional sections
- Examples of workstreams, milestones, JIRA, Confluence, Steward, Pulse

Used by Full Initiative Mode to generate valid YAML files matching eci-global/initiatives schema v2.

## Test Scripts Created

### 1. test-yaml-generation.sh
**Location:** `test/initiative-creator/test-yaml-generation.sh`  
**Tests:** 9 tests  
**Status:** All pass

Tests validate YAML generation correctness:
1. Valid YAML syntax
2. Required fields present
3. Schema version validation
4. Status enum validation
5. Description format
6. Date format validation
7. Field naming convention
8. Workstream milestone structure
9. Compare with real initiative

**Coverage:**
- Schema compliance
- Field naming (snake_case)
- Date formats (ISO 8601)
- Description syntax (folded scalars)
- Structure validation
- Cross-reference with production examples

---

### 2. test-parameter-parsing.sh
**Location:** `test/initiative-creator/test-parameter-parsing.sh`  
**Tests:** 9 tests  
**Status:** All pass

Tests validate parameter parsing and mode detection:
1. Standalone issue parameters
2. Linking to project
3. Create and link
4. Force YAML mode
5. No parameters (interactive)
6. Link to initiative YAML
7. Assign to milestone
8. Full parameter set
9. --yaml overrides other parameters

**Coverage:**
- Mode detection logic
- Parameter combinations
- Priority rules
- Override behavior
- Interactive fallback

## Verification

### Test Results
**Total Tests:** 18  
**Passed:** 18  
**Failed:** 0  
**Pass Rate:** 100%

**YAML Generation Tests:** 9/9 pass
- Schema validation: ✓
- Field naming: ✓
- Date formats: ✓
- Description syntax: ✓
- Structure compliance: ✓

**Parameter Parsing Tests:** 9/9 pass
- Mode detection: ✓
- Parameter combinations: ✓
- Priority rules: ✓
- Override behavior: ✓
- Interactive fallback: ✓

### File Completeness
- **skill.md:** 905 lines (within expected 900-950 range)
- **Examples:** 5 files created
- **Templates:** 1 file created
- **Tests:** 2 scripts created

### Documentation Quality
- All modes documented with workflows
- Parameter passing fully documented
- Configuration options explained
- Integration patterns described
- Error handling covered
- Common pitfalls identified
- Migration notes comprehensive

### Breaking Changes
**None.** All v1.0.0 workflows continue to work.

The only behavioral change is asking "What would you like to create?" first instead of assuming full initiative creation. This is more flexible and better matches actual usage patterns.

To force v1.0.0 behavior (skip mode selection): `--yaml` flag

## Next Steps

### What This Enables

**For Users:**
1. Quick issue creation without initiative overhead (Standalone Mode)
2. Organize existing issues into projects/initiatives (Linking Mode)
3. Create formal initiatives when needed (Full Initiative Mode)
4. Non-interactive invocation for automation

**For Skills:**
1. `/initiative-breakdown` can invoke with parameters to create issues
2. `feature-delivery-team` can create standalone issues for quick tasks
3. Other skills can link issues to initiatives programmatically
4. Automation scripts can batch-create and organize issues

**For Development:**
1. YAML generation matches production schema exactly
2. Test coverage ensures future changes don't break functionality
3. Examples provide clear reference implementations
4. Migration path documented for future versions

### Recommended Usage

**90% of work:** Standalone or Linking mode
- Bug fixes: Standalone
- Small tasks: Standalone
- Organizing work: Linking
- Adding to existing initiatives: Linking

**10% of work:** Full Initiative mode
- Multi-week/multi-month efforts
- Cross-repository coordination
- Formal tracking requirements
- Multiple workstreams

### Integration Opportunities

1. **initiative-breakdown** - Invoke initiative-creator with parameters to create issues
2. **visual-prd** - Continue integration for complex initiatives
3. **feature-delivery-team** - Use standalone mode for quick tasks
4. **github-context-agent** - Verify projects/initiatives exist before linking
5. **Automation scripts** - Batch create and organize issues via parameters

### Future Enhancements

Potential v2.1.0 features:
- Bulk issue creation from CSV/JSON
- JIRA sync integration (create JIRA tickets when creating issues)
- Template-based issue creation (reusable issue templates)
- Project board automation (auto-add to project columns)
- Initiative progress tracking (scan linked issues for status)

## Conclusion

initiative-creator v2.0.0 successfully transforms a single-purpose YAML generator into a flexible, multi-mode workflow system that matches actual usage patterns. The skill now handles 90% of work (standalone/linking) more efficiently while maintaining comprehensive initiative creation for the 10% that needs it.

All tests pass, documentation is comprehensive, backward compatibility is maintained, and the foundation is laid for future enhancements.

**Status: PRODUCTION READY**
