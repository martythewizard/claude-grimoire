# Project Context Example

## Request

```json
{
  "type": "project",
  "identifier": "eci-global#14",
  "depth": "standard",
  "include": {
    "project": true,
    "items": true
  }
}
```

## Response

```json
{
  "success": true,
  "context": {
    "type": "project",
    "metadata": {
      "id": "PVT_kwDOBgqCFs4BRXOh",
      "number": 14,
      "org": "eci-global",
      "title": "2026 Q1 - AI Cost Intelligence Platform",
      "url": "https://github.com/orgs/eci-global/projects/14",
      "shortDescription": "Cost intelligence and anomaly detection platform",
      "public": false,
      "closed": false,
      "createdAt": "2026-01-05T10:00:00Z",
      "updatedAt": "2026-03-26T22:30:00Z"
    },
    "items": {
      "total": 76,
      "open": 0,
      "closed": 76,
      "by_repo": {
        "eci-global/one-cloud-cloud-costs": {
          "total": 76,
          "open": 0,
          "closed": 76,
          "issues": [
            {
              "number": 123,
              "title": "Implement DataSync pipeline",
              "state": "CLOSED",
              "url": "https://github.com/eci-global/one-cloud-cloud-costs/issues/123",
              "milestone": {
                "title": "M0 — S3 Unified FOCUS Data Lake (DataSync)",
                "number": 5
              }
            }
          ],
          "pull_requests": []
        }
      },
      "by_milestone": {
        "M0 — S3 Unified FOCUS Data Lake (DataSync)": 12,
        "M1 — Eyes Open: Automated Detection": 20,
        "M2 — Learning Normal: Baseline Intelligence": 18,
        "No milestone": 26
      }
    },
    "progress": {
      "percentage": 100,
      "completed_items": 76,
      "total_items": 76
    },
    "related_initiative": {
      "yaml_path": "initiatives/2026-q1-ai-cost-intelligence-platform.yaml",
      "name": "2026 Q1 - AI Cost Intelligence Platform",
      "detected": "Project number matches github_project.number in YAML"
    }
  },
  "requestMetadata": {
    "type": "project",
    "depth": "standard",
    "duration": "8.5s",
    "apiCallsUsed": 8,
    "rateLimitRemaining": 4992
  }
}
```

## Usage in Skills

```markdown
### Skill: initiative-breakdown

When user provides project reference:

1. Invoke github-context-agent with type="project"
2. Extract items grouped by repo
3. Check for related initiative YAML
4. Create additional issues as needed
5. Link new issues to project using gh project item-add
```
