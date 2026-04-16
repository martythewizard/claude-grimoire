# Validation Report: invalid-initiative.yaml

## Summary
- ❌ Schema v2: INVALID
- ⚠️ Cannot proceed with further validation until schema is fixed

## Critical Issues

### Schema Validation Errors
- **Critical:** Expected schema_version: 2, got: 1
- **Message:** This skill only supports schema v2. Please use initiative-validator v1.0.0 for older schemas.

## Warnings
None (validation stopped at schema check)

## Info
Schema v2 required fields:
- `schema_version: 2`
- `name: string`
- `description: string`
- `status: active | planning | paused | completed | cancelled`
- `owner: string`

## Action Items for Initiative Owner
1. Update schema_version to 2
2. Ensure all required fields are present and correctly formatted
3. Re-run validation after fixing schema
