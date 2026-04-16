# Ambiguous Input Handling Examples

## Example 1: Partial Initiative Name

### Request

```json
{
  "type": "initiative",
  "identifier": "cost",
  "depth": "shallow"
}
```

### Response (Ambiguous)

```json
{
  "success": false,
  "error": {
    "type": "AmbiguousInput",
    "message": "Multiple initiatives match 'cost'",
    "options": [
      {
        "type": "initiative",
        "identifier": "initiatives/2026-q1-ai-cost-intelligence-platform.yaml",
        "description": "2026 Q1 - AI Cost Intelligence Platform"
      },
      {
        "type": "initiative",
        "identifier": "initiatives/2025-q4-cost-optimization.yaml",
        "description": "2025 Q4 - Cost Optimization Initiative"
      }
    ],
    "suggestion": "Please specify the full YAML filename or use a more specific search term",
    "retryable": true
  }
}
```

### Skill Response to User

```
Multiple initiatives match 'cost':
A) 2026 Q1 - AI Cost Intelligence Platform (2026-q1-ai-cost-intelligence-platform.yaml)
B) 2025 Q4 - Cost Optimization Initiative (2025-q4-cost-optimization.yaml)

Which initiative did you mean?
```

## Example 2: Number Context

### Request

```json
{
  "identifier": "14",
  "depth": "standard"
}
```

Note: No `type` specified

### Response (Ambiguous)

```json
{
  "success": false,
  "error": {
    "type": "AmbiguousInput",
    "message": "Input '14' could refer to multiple items",
    "options": [
      {
        "type": "project",
        "identifier": "eci-global#14",
        "description": "GitHub Project: 2026 Q1 - AI Cost Intelligence Platform (76 items)"
      },
      {
        "type": "initiative",
        "identifier": "initiatives/2026-q1-ai-cost-intelligence-platform.yaml",
        "description": "Initiative YAML that includes project 14"
      }
    ],
    "suggestion": "Specify 'eci-global#14' for the project or the YAML path for the initiative",
    "retryable": true
  }
}
```

### Skill Response to User

```
I found multiple items matching '14':
A) GitHub Project eci-global#14 (just the project board)
B) Initiative YAML (full initiative including project, workstreams, JIRA, etc.)

Which context do you need?
```

## Example 3: No Matches

### Request

```json
{
  "type": "initiative",
  "identifier": "auth-system",
  "depth": "standard"
}
```

### Response (Not Found)

```json
{
  "success": false,
  "error": {
    "type": "NotFound",
    "message": "Initiative 'auth-system' not found in eci-global/initiatives",
    "available": [
      "2026-q1-ai-cost-intelligence-platform.yaml",
      "2026-q1-coralogix-quota-manager.yaml",
      "2026-q1-aws-org-account-factory.yaml"
    ],
    "suggestion": "Check spelling or browse available initiatives. Use /initiative-creator to create a new initiative.",
    "retryable": false
  }
}
```

### Skill Response to User

```
Initiative 'auth-system' not found. Available initiatives:
- 2026-q1-ai-cost-intelligence-platform.yaml
- 2026-q1-coralogix-quota-manager.yaml
- 2026-q1-aws-org-account-factory.yaml

Would you like to:
A) Create a new initiative for auth-system
B) Search again with different keywords
C) Work with standalone issues instead
```
