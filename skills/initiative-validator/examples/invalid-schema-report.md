# Validation Report: new-initiative.yaml

## Summary
- ❌ Schema: FAILED - missing required fields
- ⚠️ GitHub: Validation skipped (schema must pass first)
- ⚠️ JIRA: Validation skipped (schema must pass first)
- ⚠️ Confluence: Validation skipped (schema must pass first)

## Critical Issues

### Schema Validation Errors
- Critical: Missing required field 'owner'
  - **Action:** Add `owner: GitHubUsername` to YAML
  
- Critical: Missing required field 'description'
  - **Action:** Add `description: "One-sentence summary of initiative"` to YAML

- Critical: Invalid status value 'in-progress'. Must be one of: active, planning, paused, completed, cancelled
  - **Action:** Change `status: in-progress` to `status: active`

## Warnings
External validations cannot run until schema validation passes.

## Info
Fix critical schema errors above, then re-run validation to check GitHub/JIRA/Confluence references.

## Action Items for Initiative Owner
1. Add missing required fields: owner, description
2. Fix status enum value
3. Re-run validation after schema is corrected
4. Once schema passes, external validations will run automatically
