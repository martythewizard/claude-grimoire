# Initiative Context Example

## Request

```json
{
  "type": "initiative",
  "identifier": "initiatives/2026-q1-ai-cost-intelligence-platform.yaml",
  "depth": "standard",
  "include": {
    "yaml": true,
    "project": true,
    "workstreams": true,
    "progress": true
  }
}
```

## Response

```json
{
  "success": true,
  "context": {
    "type": "initiative",
    "metadata": {
      "schema_version": 2,
      "name": "2026 Q1 - AI Cost Intelligence Platform",
      "description": "Always-on agentic AI cost intelligence. DataSync unified FOCUS data lake, ECS Fargate agent loop, Prophet+MAD anomaly detection, developer identity correlation, and tiered autonomous cost response.",
      "status": "active",
      "phase": "operational-go-live",
      "owner": "tedgar",
      "team": ["tedgar"],
      "tags": ["finops", "ai-governance", "cost-intelligence", "q1-2026"]
    },
    "github_project": {
      "org": "eci-global",
      "number": 14,
      "url": "https://github.com/orgs/eci-global/projects/14",
      "title": "2026 Q1 - AI Cost Intelligence Platform",
      "state": "OPEN",
      "items_count": 76,
      "closed_items_count": 76,
      "progress_percentage": 100
    },
    "workstreams": [
      {
        "name": "S3 Unified FOCUS Data Lake",
        "repo": "eci-global/one-cloud-cloud-costs",
        "milestones": [
          {
            "title": "M0 — S3 Unified FOCUS Data Lake (DataSync)",
            "number": 5,
            "due": "2026-03-31",
            "status": "deployed",
            "state": "closed",
            "url": "https://github.com/eci-global/one-cloud-cloud-costs/milestone/5",
            "open_issues": 0,
            "closed_issues": 12
          },
          {
            "title": "M5 — Terraform Infrastructure (Terragrunt + Terraform Cloud)",
            "number": 9,
            "due": "2026-03-31",
            "status": "deployed",
            "state": "closed",
            "url": "https://github.com/eci-global/one-cloud-cloud-costs/milestone/9",
            "open_issues": 0,
            "closed_issues": 8
          }
        ]
      },
      {
        "name": "Intelligence System",
        "repo": "eci-global/one-cloud-cloud-costs",
        "milestones": [
          {
            "title": "M1 — Eyes Open: Automated Detection",
            "number": 6,
            "due": "2026-04-14",
            "status": "code-complete",
            "state": "open",
            "url": "https://github.com/eci-global/one-cloud-cloud-costs/milestone/6",
            "open_issues": 2,
            "closed_issues": 18
          }
        ]
      }
    ],
    "progress": {
      "github_issues": "76/76",
      "jira_epics": "6/6",
      "jira_stories": "65/65",
      "tests": "471/471",
      "infrastructure": "deployed",
      "data_pipelines": "operational",
      "billing_pipeline": "operational",
      "last_reconciled": "2026-03-23"
    },
    "jira": {
      "project_key": "ITPLAT01",
      "parent_key": "ITPMO01-1540",
      "board_url": "https://eci-solutions.atlassian.net/jira/software/c/projects/ITPLAT01/boards/327",
      "epics": [
        {
          "key": "ITPLAT01-1987",
          "milestone": "S3 Unified FOCUS Data Lake",
          "status": "Done"
        },
        {
          "key": "ITPLAT01-1988",
          "milestone": "Eyes Open — Automated Detection",
          "status": "Done"
        }
      ]
    },
    "confluence": {
      "space_key": "CGIP",
      "page_id": "1960706070",
      "page_version": 3,
      "page_url": "https://confluence.eci.com/pages/viewpage.action?pageId=1960706070"
    },
    "steward": {
      "enabled": true,
      "last_run": "2026-03-26T22:30:00Z"
    },
    "yaml_path": "initiatives/2026-q1-ai-cost-intelligence-platform.yaml",
    "yaml_url": "https://github.com/eci-global/initiatives/blob/main/initiatives/2026-q1-ai-cost-intelligence-platform.yaml"
  },
  "requestMetadata": {
    "type": "initiative",
    "depth": "standard",
    "duration": "12.3s",
    "apiCallsUsed": 15,
    "rateLimitRemaining": 4985
  }
}
```

## Usage in Skills

```markdown
### Skill: initiative-breakdown

When user provides initiative reference:

1. Invoke github-context-agent with type="initiative"
2. Extract workstreams and milestones from response
3. For each workstream:
   - Use repo and milestone data to scope tasks
   - Create issues in the repo
   - Assign to milestones
   - Link to github_project if it exists
```
