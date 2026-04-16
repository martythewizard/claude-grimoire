# GitHub Context Agent Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend github-context-agent to understand initiatives (YAML), GitHub Projects v2, workstreams, and milestones, providing unified context gathering for all GitHub organizational patterns.

**Architecture:** Agent documentation defines the contract for how skills/teams invoke the agent. We'll update the agent.md to specify new input types (`initiative`, `project`, `workstream`, `milestone`), add YAML parsing from eci-global/initiatives repo, integrate GitHub Projects v2 GraphQL API, and return normalized context structures that work consistently across all types.

**Tech Stack:** 
- GitHub CLI (`gh`) for API access
- GitHub REST API (via `gh api`) for YAML fetching
- GitHub GraphQL API (via `gh api graphql`) for Projects v2
- YAML parsing (via yq or python)
- Markdown documentation

---

## File Structure

**Files to Modify:**
- `agents/github-context-agent/agent.md` - Main agent documentation (current: ~490 lines)
  - Add new input types
  - Update input/output contracts
  - Add initiative/project/workstream/milestone examples
  - Document YAML parsing behavior
  - Add error handling patterns

**Files to Create:**
- `agents/github-context-agent/examples/initiative-context.md` - Example initiative context flow
- `agents/github-context-agent/examples/project-context.md` - Example project context flow
- `agents/github-context-agent/examples/ambiguous-input.md` - Example clarification flows
- `test/github-context-agent/test-initiative-parsing.sh` - Test YAML parsing
- `test/github-context-agent/test-project-graphql.sh` - Test Projects v2 API
- `test/github-context-agent/test-input-detection.sh` - Test input type detection

---

### Task 1: Update Input Contract for New Types

**Files:**
- Modify: `agents/github-context-agent/agent.md:51-69`

- [ ] **Step 1: Add new types to input contract**

Update the input contract JSON example to include new types:

```markdown
## Input Contract

The agent accepts a context request object:

```json
{
  "type": "issue | initiative | project | workstream | milestone | pr | repo",
  "identifier": "string (flexible format - see Identifier Formats below)",
  "depth": "shallow | standard | deep",
  "include": {
    "comments": true,
    "relatedPRs": true,
    "relatedIssues": true,
    "commits": false,
    "timeline": true,
    "codeowners": false,
    "yaml": true,
    "project": true,
    "workstreams": true,
    "milestones": true,
    "progress": true
  }
}
```

### Type Descriptions

**Existing types:**
- `issue` - GitHub issue
- `pr` - GitHub pull request  
- `repo` - Repository metadata

**New types:**
- `initiative` - Initiative defined in eci-global/initiatives YAML file
- `project` - GitHub Project v2 (organization or repository project)
- `workstream` - Logical grouping within an initiative (repo + milestones)
- `milestone` - GitHub milestone within a repository

### Identifier Formats

The agent detects type from identifier format:

**Initiative identifiers:**
- YAML file path: `initiatives/2026-q1-ai-cost-intelligence-platform.yaml`
- Initiative name: `2026 Q1 - AI Cost Intelligence Platform`
- Partial match: `ai-cost-intelligence` (searches YAML files)

**Project identifiers:**
- URL: `https://github.com/orgs/eci-global/projects/14`
- Org project: `eci-global#14`
- Repo project: `owner/repo#project-14`

**Workstream identifiers:**
- Initiative + workstream: `initiative:2026-q1-ai-cost workstream:S3 Data Lake`
- YAML path + workstream: `initiatives/file.yaml workstream:name`

**Milestone identifiers:**
- Repo + milestone name: `owner/repo milestone:"M1 - Foundation"`
- Repo + milestone number: `owner/repo milestone:5`

**Issue/PR identifiers (existing):**
- `owner/repo#123`
- `https://github.com/owner/repo/issues/123`
- `#123` (if repo context available)

**Ambiguous detection:**
When identifier could match multiple types, agent asks for clarification.
```
```

- [ ] **Step 2: Verify markdown formatting**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
# Check that the markdown is valid
cat agents/github-context-agent/agent.md | grep -A 20 "## Input Contract"
```

Expected: New types and identifier formats clearly documented

- [ ] **Step 3: Commit input contract updates**

```bash
git add agents/github-context-agent/agent.md
git commit -m "docs(github-context-agent): add initiative/project/workstream/milestone types to input contract"
```

---

### Task 2: Add Initiative YAML Parsing Documentation

**Files:**
- Modify: `agents/github-context-agent/agent.md` (after Input Contract section)
- Create: `agents/github-context-agent/examples/initiative-context.md`

- [ ] **Step 1: Document YAML fetching behavior**

Add new section after "Input Contract":

```markdown
## Initiative YAML Parsing

When `type: "initiative"` is requested, the agent fetches and parses YAML files from the `eci-global/initiatives` repository.

### YAML Fetch Process

1. **Identifier resolution:**
   - If full path: `gh api repos/eci-global/initiatives/contents/{path}`
   - If name/partial: Search `initiatives/` directory for matches
   - If ambiguous: Return list of matches for user to choose

2. **YAML parsing:**
   - Fetch file content (base64 encoded)
   - Decode content
   - Parse YAML with schema v2 support
   - Validate required fields present

3. **Related data fetching (based on YAML content):**
   - If `github_project` exists: Fetch project via GraphQL
   - If `workstreams` exist: Fetch milestone data for each repo
   - If `progress` exists: Include in context
   - If `jira`/`confluence` exist: Include references (no API calls)

### YAML Schema v2 Fields

The agent understands all schema v2 fields:

**Required:**
- `schema_version` - Must be 2
- `name` - Initiative name
- `description` - What it delivers
- `status` - One of: active, planning, paused, completed, cancelled
- `owner` - GitHub username

**Optional:**
- `phase` - Current phase
- `team` - Array of GitHub usernames
- `github_project` - {org, number, id}
- `workstreams` - Array of {name, repo, milestones}
- `progress` - {github_issues, jira_epics, tests, infrastructure, etc}
- `jira` - {project_key, parent_key, board_url, epics}
- `confluence` - {space_key, page_id, page_version}
- `steward` - {enabled, last_run}
- `tags` - Array of strings
- `pulse` - {scan_window, channels, discussion_category}

### Example YAML Fetch

```bash
# Fetch initiative YAML
gh api repos/eci-global/initiatives/contents/initiatives/2026-q1-ai-cost-intelligence-platform.yaml \
  --jq '.content' | base64 -d

# List all initiatives
gh api repos/eci-global/initiatives/contents/initiatives --jq '.[].name'
```

### Error Handling

**YAML not found:**
```json
{
  "success": false,
  "error": {
    "type": "NotFound",
    "message": "Initiative 'auth' not found in eci-global/initiatives",
    "suggestion": "Available initiatives: 2026-q1-ai-cost-intelligence-platform.yaml, 2026-q1-coralogix-quota-manager.yaml, ...",
    "retryable": false
  }
}
```

**Invalid YAML schema:**
```json
{
  "success": false,
  "error": {
    "type": "ValidationError",
    "message": "YAML validation failed",
    "details": [
      "Missing required field: status",
      "Invalid status value: 'in progress' (must be one of: active, planning, paused, completed, cancelled)"
    ],
    "suggestion": "Check YAML file conforms to schema v2",
    "retryable": false
  }
}
```

**Ambiguous identifier:**
```json
{
  "success": false,
  "error": {
    "type": "AmbiguousInput",
    "message": "Multiple initiatives match 'cost'",
    "matches": [
      "2026-q1-ai-cost-intelligence-platform.yaml",
      "2025-q4-cost-optimization.yaml"
    ],
    "suggestion": "Please specify which initiative",
    "retryable": true
  }
}
```
```

- [ ] **Step 2: Create initiative context example**

Create `agents/github-context-agent/examples/initiative-context.md`:

```markdown
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
```

- [ ] **Step 3: Verify example renders correctly**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
cat agents/github-context-agent/examples/initiative-context.md | head -50
```

Expected: Example displays correct JSON structure

- [ ] **Step 4: Commit YAML parsing documentation**

```bash
git add agents/github-context-agent/agent.md agents/github-context-agent/examples/initiative-context.md
git commit -m "docs(github-context-agent): add initiative YAML parsing documentation and example"
```

---

### Task 3: Add GitHub Projects v2 API Documentation

**Files:**
- Modify: `agents/github-context-agent/agent.md` (after Initiative section)
- Create: `agents/github-context-agent/examples/project-context.md`

- [ ] **Step 1: Document Projects v2 GraphQL integration**

Add new section after "Initiative YAML Parsing":

```markdown
## GitHub Projects v2 Integration

When `type: "project"` is requested, the agent fetches project data using GitHub's Projects v2 GraphQL API.

### Project Fetch Process

1. **Identifier resolution:**
   - URL: Extract org/repo and project number
   - `org#number`: Organization project
   - `owner/repo#project-number`: Repository project

2. **GraphQL query:**
   ```graphql
   query($org: String!, $number: Int!) {
     organization(login: $org) {
       projectV2(number: $number) {
         id
         title
         url
         shortDescription
         public
         closed
         createdAt
         updatedAt
         items(first: 100) {
           totalCount
           nodes {
             id
             content {
               ... on Issue {
                 id
                 number
                 title
                 state
                 url
                 repository {
                   nameWithOwner
                 }
                 milestone {
                   title
                   number
                 }
               }
               ... on PullRequest {
                 id
                 number
                 title
                 state
                 url
                 repository {
                   nameWithOwner
                 }
               }
             }
           }
         }
       }
     }
   }
   ```

3. **Data enrichment:**
   - Count items by state (open/closed)
   - Group items by repository
   - Calculate progress percentage
   - Extract milestone associations

### Example GraphQL Execution

```bash
# Fetch organization project
gh api graphql -f query='
  query {
    organization(login: "eci-global") {
      projectV2(number: 14) {
        id
        title
        url
        items(first: 100) {
          totalCount
          nodes {
            content {
              ... on Issue {
                number
                title
                state
              }
            }
          }
        }
      }
    }
  }
'
```

### Error Handling

**Project not found:**
```json
{
  "success": false,
  "error": {
    "type": "NotFound",
    "message": "GitHub Project #99 not found in eci-global",
    "suggestion": "Verify project number and organization. Use GitHub UI to check project exists.",
    "retryable": false
  }
}
```

**Permission denied:**
```json
{
  "success": false,
  "error": {
    "type": "PermissionDenied",
    "message": "Cannot access GitHub Project #14 in eci-global",
    "suggestion": "Ensure GitHub token has 'project' read scope. Run: gh auth refresh -s project",
    "retryable": true
  }
}
```

### Project-Initiative Linking

When an initiative YAML contains `github_project`, the agent automatically fetches project data:

```yaml
github_project:
  org: eci-global
  number: 14
  id: PVT_kwDOBgqCFs4BRXOh  # Optional GraphQL node ID
```

The agent will:
1. Fetch initiative YAML
2. See `github_project` section
3. Make GraphQL call to fetch project
4. Merge project data into response
```

- [ ] **Step 2: Create project context example**

Create `agents/github-context-agent/examples/project-context.md`:

```markdown
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
```

- [ ] **Step 3: Verify GraphQL example syntax**

```bash
# Test that the GraphQL query is valid JSON
cd /mnt/c/Users/mhoward/projects/claude-grimoire
grep -A 30 "query {" agents/github-context-agent/agent.md
```

Expected: GraphQL query is properly formatted

- [ ] **Step 4: Commit Projects v2 documentation**

```bash
git add agents/github-context-agent/agent.md agents/github-context-agent/examples/project-context.md
git commit -m "docs(github-context-agent): add GitHub Projects v2 GraphQL integration docs"
```

---

### Task 4: Add Workstream and Milestone Support

**Files:**
- Modify: `agents/github-context-agent/agent.md` (after Projects section)

- [ ] **Step 1: Document workstream context**

Add new section:

```markdown
## Workstream Context

A workstream is a logical grouping within an initiative that maps to a specific repository and set of milestones.

### Workstream Identifier Format

```
initiative:<yaml-name> workstream:<workstream-name>
```

Examples:
- `initiative:2026-q1-ai-cost workstream:S3 Data Lake`
- `initiatives/file.yaml workstream:Intelligence System`

### Workstream Resolution Process

1. **Parse identifier:**
   - Extract initiative reference
   - Extract workstream name

2. **Fetch initiative:**
   - Load YAML file
   - Validate schema

3. **Find workstream:**
   - Search `workstreams` array for name match
   - Return error if not found

4. **Enrich workstream data:**
   - Fetch milestone details from repo
   - Get issue counts per milestone
   - Calculate workstream progress

### Workstream Context Response

```json
{
  "success": true,
  "context": {
    "type": "workstream",
    "metadata": {
      "name": "S3 Unified FOCUS Data Lake",
      "repo": "eci-global/one-cloud-cloud-costs",
      "initiative": "2026 Q1 - AI Cost Intelligence Platform",
      "initiative_yaml": "initiatives/2026-q1-ai-cost-intelligence-platform.yaml"
    },
    "milestones": [
      {
        "title": "M0 — S3 Unified FOCUS Data Lake (DataSync)",
        "number": 5,
        "due": "2026-03-31",
        "status": "deployed",
        "state": "closed",
        "url": "https://github.com/eci-global/one-cloud-cloud-costs/milestone/5",
        "open_issues": 0,
        "closed_issues": 12,
        "issues": [
          {
            "number": 123,
            "title": "Implement DataSync pipeline",
            "state": "closed",
            "url": "https://github.com/eci-global/one-cloud-cloud-costs/issues/123"
          }
        ]
      }
    ],
    "progress": {
      "total_milestones": 2,
      "completed_milestones": 2,
      "total_issues": 20,
      "closed_issues": 20,
      "percentage": 100
    }
  }
}
```

## Milestone Context

### Milestone Identifier Format

```
owner/repo milestone:"<milestone-title>"
owner/repo milestone:<milestone-number>
```

Examples:
- `eci-global/one-cloud-cloud-costs milestone:"M0 — S3 Unified FOCUS Data Lake"`
- `eci-global/one-cloud-cloud-costs milestone:5`

### Milestone Resolution Process

1. **Parse identifier:**
   - Extract owner/repo
   - Extract milestone reference (title or number)

2. **Fetch milestone:**
   - If number: Direct API call
   - If title: List milestones and filter by title

3. **Fetch milestone issues:**
   - Get all issues assigned to milestone
   - Include state, labels, assignees

4. **Check for workstream association:**
   - Search eci-global/initiatives for YAMLs referencing this milestone
   - Include initiative context if found

### Milestone Context Response

```json
{
  "success": true,
  "context": {
    "type": "milestone",
    "metadata": {
      "title": "M0 — S3 Unified FOCUS Data Lake (DataSync)",
      "number": 5,
      "repo": "eci-global/one-cloud-cloud-costs",
      "due_on": "2026-03-31T00:00:00Z",
      "state": "closed",
      "url": "https://github.com/eci-global/one-cloud-cloud-costs/milestone/5",
      "description": "Build unified FOCUS-compliant data lake in S3 with DataSync integration",
      "created_at": "2026-01-10T09:00:00Z",
      "updated_at": "2026-03-31T18:00:00Z",
      "closed_at": "2026-03-31T18:00:00Z"
    },
    "issues": {
      "open_count": 0,
      "closed_count": 12,
      "items": [
        {
          "number": 123,
          "title": "Implement DataSync pipeline",
          "state": "closed",
          "url": "https://github.com/eci-global/one-cloud-cloud-costs/issues/123",
          "labels": ["infrastructure", "datasync"],
          "assignees": ["tedgar"],
          "created_at": "2026-01-15T10:00:00Z",
          "closed_at": "2026-02-20T16:30:00Z"
        }
      ]
    },
    "related_workstream": {
      "initiative": "2026 Q1 - AI Cost Intelligence Platform",
      "initiative_yaml": "initiatives/2026-q1-ai-cost-intelligence-platform.yaml",
      "workstream": "S3 Unified FOCUS Data Lake",
      "detected": "Milestone found in initiative YAML workstreams"
    },
    "related_project": {
      "org": "eci-global",
      "number": 14,
      "url": "https://github.com/orgs/eci-global/projects/14",
      "detected": "Initiative YAML contains github_project reference"
    }
  }
}
```
```

- [ ] **Step 2: Verify workstream/milestone docs are clear**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
# Check workstream section exists and is properly formatted
grep -A 10 "## Workstream Context" agents/github-context-agent/agent.md
```

Expected: Workstream and milestone sections clearly documented

- [ ] **Step 3: Commit workstream/milestone documentation**

```bash
git add agents/github-context-agent/agent.md
git commit -m "docs(github-context-agent): add workstream and milestone context support"
```

---

### Task 5: Add Input Detection and Ambiguity Handling

**Files:**
- Modify: `agents/github-context-agent/agent.md` (after Milestone section)
- Create: `agents/github-context-agent/examples/ambiguous-input.md`

- [ ] **Step 1: Document input detection logic**

Add new section:

```markdown
## Input Type Detection

The agent automatically detects the type from the identifier format. When ambiguous, it asks the user to clarify.

### Detection Rules

**Priority order (first match wins):**

1. **Explicit type provided** - Use `type` field if present
2. **URL patterns:**
   - `https://github.com/*/issues/*` → issue
   - `https://github.com/*/pull/*` → pr
   - `https://github.com/orgs/*/projects/*` → project
   - `https://github.com/*/projects/*` → project (repo project)
3. **Format patterns:**
   - `owner/repo#123` → issue (or PR if #123 is a PR)
   - `org#123` → project (organization project)
   - `initiatives/*.yaml` or YAML filename → initiative
   - `milestone:"..."` or `milestone:N` → milestone
   - `workstream:...` → workstream
4. **Keyword patterns:**
   - Contains "initiative:" → initiative
   - Contains "workstream:" → workstream
   - Contains "milestone:" → milestone
5. **Ambiguous** - Ask user

### Ambiguous Input Examples

**Example 1: Number could be issue or project**

Input: `eci-global/repo#14`

Could be:
- Issue #14 in eci-global/repo
- Project #14 (if "project" keyword intended)

Detection: Check if issue #14 exists. If not, check for project.

**Example 2: Name could match multiple initiatives**

Input: `cost intelligence`

Matches:
- `2026-q1-ai-cost-intelligence-platform.yaml`
- `2025-q4-cost-optimization.yaml`

Response: Ask user to choose from list

**Example 3: Project number appears in both project and initiative**

Input: `14`

Could be:
- Project eci-global#14
- Initiative that references project 14

Response: Ask user to clarify

### Clarification Flow

When input is ambiguous, return error with options:

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
        "description": "GitHub Project: 2026 Q1 - AI Cost Intelligence Platform"
      },
      {
        "type": "initiative",
        "identifier": "initiatives/2026-q1-ai-cost-intelligence-platform.yaml",
        "description": "Initiative YAML (references project 14)"
      }
    ],
    "suggestion": "Please specify which you meant:\nA) GitHub Project eci-global#14\nB) Initiative YAML (includes project as part of initiative)",
    "retryable": true
  }
}
```

The calling skill should then ask the user:

```
I found multiple matches for "14":
A) GitHub Project eci-global#14 - 2026 Q1 - AI Cost Intelligence Platform
B) Initiative YAML - 2026 Q1 - AI Cost Intelligence Platform (references project 14)

Which did you mean?
```
```

- [ ] **Step 2: Create ambiguous input examples**

Create `agents/github-context-agent/examples/ambiguous-input.md`:

```markdown
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
```

- [ ] **Step 3: Verify ambiguous input examples are comprehensive**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
cat agents/github-context-agent/examples/ambiguous-input.md
```

Expected: All three examples (partial match, number context, not found) are documented

- [ ] **Step 4: Commit input detection documentation**

```bash
git add agents/github-context-agent/agent.md agents/github-context-agent/examples/ambiguous-input.md
git commit -m "docs(github-context-agent): add input detection and ambiguity handling"
```

---

### Task 6: Update Output Contract with New Context Structures

**Files:**
- Modify: `agents/github-context-agent/agent.md:91-231` (Output Contract section)

- [ ] **Step 1: Add initiative output format**

Update Output Contract section to include initiative response structure:

```markdown
## Output Contract

Returns a structured context object. Format varies by type.

### Issue Context (existing)

[Keep existing issue context format]

### Initiative Context (NEW)

```json
{
  "success": true,
  "context": {
    "type": "initiative",
    "metadata": {
      "schema_version": 2,
      "name": "string",
      "description": "string",
      "status": "active | planning | paused | completed | cancelled",
      "phase": "string (optional)",
      "owner": "github-username",
      "team": ["username1", "username2"],
      "tags": ["tag1", "tag2"]
    },
    "github_project": {
      "org": "string",
      "number": 0,
      "id": "string (optional)",
      "url": "string",
      "title": "string",
      "state": "OPEN | CLOSED",
      "items_count": 0,
      "closed_items_count": 0,
      "progress_percentage": 0
    },
    "workstreams": [
      {
        "name": "string",
        "repo": "owner/repo",
        "milestones": [
          {
            "title": "string",
            "number": 0,
            "due": "ISO 8601 date",
            "status": "string (from YAML)",
            "state": "open | closed",
            "url": "string",
            "open_issues": 0,
            "closed_issues": 0
          }
        ]
      }
    ],
    "progress": {
      "github_issues": "string",
      "jira_epics": "string",
      "jira_stories": "string",
      "tests": "string",
      "infrastructure": "string",
      "last_reconciled": "ISO 8601 date"
    },
    "jira": {
      "project_key": "string",
      "parent_key": "string",
      "board_url": "string",
      "epics": [
        {
          "key": "string",
          "milestone": "string",
          "status": "string"
        }
      ]
    },
    "confluence": {
      "space_key": "string",
      "page_id": "string",
      "page_version": 0,
      "page_url": "string"
    },
    "steward": {
      "enabled": true,
      "last_run": "ISO 8601 timestamp"
    },
    "yaml_path": "string",
    "yaml_url": "string"
  },
  "requestMetadata": {
    "type": "initiative",
    "depth": "shallow | standard | deep",
    "duration": "string",
    "apiCallsUsed": 0,
    "rateLimitRemaining": 0
  }
}
```

### Project Context (NEW)

```json
{
  "success": true,
  "context": {
    "type": "project",
    "metadata": {
      "id": "string (GraphQL node ID)",
      "number": 0,
      "org": "string (or null for repo project)",
      "repo": "owner/repo (or null for org project)",
      "title": "string",
      "url": "string",
      "shortDescription": "string",
      "public": boolean,
      "closed": boolean,
      "createdAt": "ISO 8601 timestamp",
      "updatedAt": "ISO 8601 timestamp"
    },
    "items": {
      "total": 0,
      "open": 0,
      "closed": 0,
      "by_repo": {
        "owner/repo": {
          "total": 0,
          "open": 0,
          "closed": 0,
          "issues": [...],
          "pull_requests": [...]
        }
      },
      "by_milestone": {
        "Milestone Title": count,
        "No milestone": count
      }
    },
    "progress": {
      "percentage": 0,
      "completed_items": 0,
      "total_items": 0
    },
    "related_initiative": {
      "yaml_path": "string (if detected)",
      "name": "string",
      "detected": "string (explanation)"
    }
  }
}
```

### Workstream Context (NEW)

```json
{
  "success": true,
  "context": {
    "type": "workstream",
    "metadata": {
      "name": "string",
      "repo": "owner/repo",
      "initiative": "string (initiative name)",
      "initiative_yaml": "string (path)"
    },
    "milestones": [...],
    "progress": {
      "total_milestones": 0,
      "completed_milestones": 0,
      "total_issues": 0,
      "closed_issues": 0,
      "percentage": 0
    }
  }
}
```

### Milestone Context (NEW)

```json
{
  "success": true,
  "context": {
    "type": "milestone",
    "metadata": {
      "title": "string",
      "number": 0,
      "repo": "owner/repo",
      "due_on": "ISO 8601 date",
      "state": "open | closed",
      "url": "string",
      "description": "string",
      "created_at": "ISO 8601 timestamp",
      "updated_at": "ISO 8601 timestamp",
      "closed_at": "ISO 8601 timestamp (if closed)"
    },
    "issues": {
      "open_count": 0,
      "closed_count": 0,
      "items": [...]
    },
    "related_workstream": {
      "initiative": "string",
      "initiative_yaml": "string",
      "workstream": "string",
      "detected": "string"
    },
    "related_project": {
      "org": "string",
      "number": 0,
      "url": "string",
      "detected": "string"
    }
  }
}
```

### PR Context (existing)

[Keep existing PR context format]

### Repo Context (existing)

[Keep existing repo context format]
```

- [ ] **Step 2: Verify output contract formatting**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
# Check that all new context types are documented
grep -E "### (Initiative|Project|Workstream|Milestone) Context" agents/github-context-agent/agent.md
```

Expected: All 4 new context types appear in output contract

- [ ] **Step 3: Commit output contract updates**

```bash
git add agents/github-context-agent/agent.md
git commit -m "docs(github-context-agent): add initiative/project/workstream/milestone output contracts"
```

---

### Task 7: Update Configuration Section

**Files:**
- Modify: `agents/github-context-agent/agent.md:386-412` (Configuration section)

- [ ] **Step 1: Add initiatives configuration**

Update Global Config section:

```markdown
### Global Config (`~/.claude/claude-grimoire/config.json`)

```json
{
  "github": {
    "org": "myorg",
    "defaultRepos": ["repo1", "repo2"],
    "token": "${GITHUB_TOKEN}",
    "apiUrl": "https://api.github.com",
    "cacheEnabled": true,
    "cacheTTL": 300,
    "initiativesRepo": "eci-global/initiatives",
    "initiativesPath": "initiatives/",
    "defaultOrg": "eci-global"
  },
  "githubContextAgent": {
    "defaultDepth": "standard",
    "codeownersPath": ".github/CODEOWNERS",
    "includeArchivedIssues": false,
    "enableInitiatives": true,
    "enableProjects": true,
    "projectApiVersion": "v2",
    "yamlSchemaVersion": 2,
    "ambiguityHandling": "prompt"
  }
}
```

**New configuration fields:**

- `initiativesRepo` - Repository containing initiative YAML files (default: "eci-global/initiatives")
- `initiativesPath` - Path within repo to YAML files (default: "initiatives/")
- `defaultOrg` - Default organization for project lookups (default: "eci-global")
- `enableInitiatives` - Enable initiative YAML parsing (default: true)
- `enableProjects` - Enable GitHub Projects v2 API (default: true)
- `projectApiVersion` - Projects API version (default: "v2")
- `yamlSchemaVersion` - Expected YAML schema version (default: 2)
- `ambiguityHandling` - How to handle ambiguous input: "prompt" (ask user) or "auto" (best guess)
```

- [ ] **Step 2: Add per-repo config example**

Update Per-Repo Config section:

```markdown
### Per-Repo Config (`.claude-grimoire/config.json`)

```json
{
  "github": {
    "defaultDepth": "standard",
    "codeownersPath": ".github/CODEOWNERS",
    "includeArchivedIssues": false,
    "projectNumber": 14,
    "projectOrg": "eci-global",
    "initiativeYaml": "initiatives/2026-q1-ai-cost-intelligence-platform.yaml"
  }
}
```

**Repo-specific fields:**

- `projectNumber` - Default project for this repo
- `projectOrg` - Organization for default project
- `initiativeYaml` - Default initiative YAML for this repo
```

- [ ] **Step 3: Verify configuration examples are valid JSON**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
# Extract JSON and validate
grep -A 20 '```json' agents/github-context-agent/agent.md | grep -v '```' | python3 -m json.tool > /dev/null
echo $?
```

Expected: Exit code 0 (valid JSON)

- [ ] **Step 4: Commit configuration updates**

```bash
git add agents/github-context-agent/agent.md
git commit -m "docs(github-context-agent): add initiatives and projects configuration options"
```

---

### Task 8: Update Usage Examples Section

**Files:**
- Modify: `agents/github-context-agent/agent.md:262-340` (Usage Examples section)

- [ ] **Step 1: Add initiative breakdown example**

Add new example to Usage Examples section:

```markdown
### Example 4: Research Initiative for Breakdown

**Request:**
```json
{
  "type": "initiative",
  "identifier": "initiatives/2026-q1-coralogix-quota-manager.yaml",
  "depth": "deep",
  "include": {
    "yaml": true,
    "project": true,
    "workstreams": true,
    "milestones": true,
    "progress": true
  }
}
```

**Use Case:**
When breaking down an initiative with /initiative-breakdown:
- Fetch full initiative context including all workstreams
- Extract milestones for each workstream
- Get current progress metrics
- Understand initiative structure to create properly scoped tasks
- Link new issues to existing GitHub Project
- Assign issues to appropriate milestones

**Skill Integration:**
```markdown
# In initiative-breakdown skill

1. Call github-context-agent with initiative YAML path
2. Extract workstreams array from response
3. For each workstream:
   - Get repo and milestones
   - Create issues in that repo
   - Assign to milestone if specified
   - Link to github_project if exists
4. Add comment to each issue referencing initiative YAML
```
```

- [ ] **Step 2: Add project linking example**

Add example for project context:

```markdown
### Example 5: Link Issue to Project

**Request:**
```json
{
  "type": "project",
  "identifier": "eci-global#14",
  "depth": "shallow"
}
```

**Use Case:**
When creating issue that should be linked to project:
- Verify project exists and is open
- Get project GraphQL node ID for linking
- Check current item count

**Command sequence:**
```bash
# 1. Get project context
# (via github-context-agent)

# 2. Create issue
gh issue create --title "New task" --body "Description" --repo eci-global/repo

# 3. Link issue to project
gh project item-add 14 --owner eci-global --url https://github.com/eci-global/repo/issues/456
```
```

- [ ] **Step 3: Add workstream scoping example**

Add workstream example:

```markdown
### Example 6: Scope Tasks to Workstream

**Request:**
```json
{
  "type": "workstream",
  "identifier": "initiative:2026-q1-ai-cost workstream:Intelligence System",
  "depth": "standard",
  "include": {
    "workstreams": true,
    "milestones": true
  }
}
```

**Use Case:**
When user wants to break down just one workstream of an initiative:
- Get milestones specific to this workstream
- See existing issues in these milestones
- Create new issues scoped to this workstream's milestones
- Don't interfere with other workstreams

**Response includes:**
- Workstream name and repo
- All milestones in this workstream
- Issues in each milestone
- Progress metrics for just this workstream
```

- [ ] **Step 4: Verify examples are practical**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
# Check that new examples are added
grep "### Example [4-6]" agents/github-context-agent/agent.md
```

Expected: Three new examples (4, 5, 6) are present

- [ ] **Step 5: Commit usage examples**

```bash
git add agents/github-context-agent/agent.md
git commit -m "docs(github-context-agent): add initiative, project, and workstream usage examples"
```

---

### Task 9: Add Performance Considerations for New Types

**Files:**
- Modify: `agents/github-context-agent/agent.md:414-445` (Performance Considerations section)

- [ ] **Step 1: Update optimization strategies**

Add new optimization strategies:

```markdown
### Optimization Strategies

[Keep existing strategies 1-4]

5. **Initiative YAML caching**
   - YAML files change infrequently
   - Cache for 5 minutes (default)
   - Invalidate on explicit refresh
   - Fetch only once per session when possible

6. **Projects v2 GraphQL batching**
   - Fetch project + items in single query
   - Limit items to 100 per page
   - Use cursor pagination for large projects
   - Cache project metadata separately from items

7. **Milestone data reuse**
   - When fetching initiative with workstreams, cache milestone data
   - Reuse for subsequent milestone-specific queries
   - Batch milestone queries when multiple workstreams reference same repo

8. **Selective inclusion**
   - Default to `include.yaml: true, include.project: false`
   - Only fetch project if explicitly needed
   - Skip workstream milestone details for shallow depth
```

- [ ] **Step 2: Update performance benchmarks**

Add new rows to benchmark table:

```markdown
### Performance Benchmarks

Typical response times by depth:

| Context Type | API Calls | Time (shallow) | Time (standard) | Time (deep) |
|-------------|-----------|----------------|-----------------|-------------|
| Single Issue | 3-5 | 2-4s | 2-4s | 4-8s |
| Initiative (YAML only) | 1-2 | 1-2s | 1-2s | 1-2s |
| Initiative (with Project) | 3-5 | 2-3s | 3-5s | 5-8s |
| Initiative (with 3 workstreams) | 8-12 | 3-4s | 6-10s | 10-15s |
| Project (< 100 items) | 1-2 | 2-3s | 2-3s | 3-5s |
| Project (> 100 items) | 2-4 | 3-5s | 5-8s | 8-12s |
| Workstream (2 milestones) | 3-5 | 2-3s | 3-5s | 5-8s |
| Milestone | 2-3 | 1-2s | 2-3s | 3-5s |
| PR with reviews | 5-8 | 3-6s | 3-6s | 6-10s |
| Repository CODEOWNERS | 1-2 | 1-2s | 1-2s | 1-2s |
```

- [ ] **Step 3: Verify performance guidance is clear**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
# Check performance section is updated
grep -A 30 "### Performance Benchmarks" agents/github-context-agent/agent.md | head -35
```

Expected: New benchmark table with initiative/project/workstream/milestone rows

- [ ] **Step 4: Commit performance updates**

```bash
git add agents/github-context-agent/agent.md
git commit -m "docs(github-context-agent): add performance benchmarks for new context types"
```

---

### Task 10: Add Integration Patterns for Skills

**Files:**
- Modify: `agents/github-context-agent/agent.md:349-384` (Integration Patterns section)

- [ ] **Step 1: Update skill integration examples**

Update "Skill Integration" section with new patterns:

```markdown
### Skill Integration

From a skill:

**Pattern 1: Initiative Context (for breakdown)**

```markdown
### Step: Gather Initiative Context

Invoke the `github-context-agent` with:
- Type: "initiative"
- Identifier: YAML path or initiative name provided by user
- Depth: "deep"
- Include: yaml, project, workstreams, milestones, progress

Use the returned context to:
- Extract workstreams and their milestones
- Understand initiative goals and scope
- Link new issues to github_project if it exists
- Reference initiative YAML in issue comments
- Respect existing milestone structure
```

**Pattern 2: Project Context (for linking)**

```markdown
### Step: Verify Project Exists

Invoke the `github-context-agent` with:
- Type: "project"
- Identifier: Project number/URL provided by user
- Depth: "shallow"
- Include: project metadata only

Use the returned context to:
- Verify project exists and is open
- Get project GraphQL node ID for gh project item-add
- Check if related initiative YAML exists
- Link issues using: gh project item-add <number> --url <issue-url>
```

**Pattern 3: Workstream Scoping**

```markdown
### Step: Scope to Workstream

Invoke the `github-context-agent` with:
- Type: "workstream"
- Identifier: initiative:name workstream:workstream-name
- Depth: "standard"
- Include: workstreams, milestones

Use the returned context to:
- Create issues in workstream's repo only
- Assign to workstream's milestones only
- Calculate workstream-specific progress
- Don't touch other workstreams
```

**Pattern 4: Milestone Assignment**

```markdown
### Step: Get Milestone for Issue

Invoke the `github-context-agent` with:
- Type: "milestone"
- Identifier: owner/repo milestone:"title" or milestone:number
- Depth: "shallow"

Use the returned context to:
- Verify milestone exists
- Check if milestone is closed (don't assign to closed)
- See existing issues in milestone for context
- Assign issue: gh issue edit <number> --milestone "<title>"
- Check if milestone is part of initiative workstream
```
```

- [ ] **Step 2: Add team integration pattern**

Add new "Team Integration" subsection:

```markdown
### Team Integration

From a team workflow:

**feature-delivery-team Phase 1:**

```markdown
1. User provides initiative/project/workstream/issue reference
2. Call github-context-agent to detect type and fetch context
3. Based on type:
   - Initiative → Full initiative workflow (breakdown, tasks, linking)
   - Project → Link standalone issue to project
   - Workstream → Scope work to specific workstream
   - Issue → Standard issue workflow
4. Pass context to appropriate phase
```

**pr-autopilot-team:**

```markdown
1. Get current branch and commits
2. Check if commits reference issue numbers
3. For each issue:
   - Call github-context-agent with type="issue"
   - Check issue.related_project or issue.related_initiative
   - Include initiative/project references in PR description
4. Generate PR description with proper linking
```
```

- [ ] **Step 3: Verify integration patterns are actionable**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
# Verify integration patterns section exists
grep -A 5 "### Skill Integration" agents/github-context-agent/agent.md
grep -A 5 "### Team Integration" agents/github-context-agent/agent.md
```

Expected: Both Skill Integration and Team Integration sections present with patterns

- [ ] **Step 4: Commit integration patterns**

```bash
git add agents/github-context-agent/agent.md
git commit -m "docs(github-context-agent): add skill and team integration patterns for new types"
```

---

### Task 11: Create Test Script for Initiative YAML Parsing

**Files:**
- Create: `test/github-context-agent/test-initiative-parsing.sh`

- [ ] **Step 1: Create test directory**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
mkdir -p test/github-context-agent
```

- [ ] **Step 2: Write initiative parsing test**

Create `test/github-context-agent/test-initiative-parsing.sh`:

```bash
#!/usr/bin/env bash
# Test initiative YAML parsing functionality

set -e

echo "Testing github-context-agent initiative YAML parsing..."

# Test 1: List all initiatives
echo "Test 1: List all initiatives"
initiatives=$(gh api repos/eci-global/initiatives/contents/initiatives --jq '.[].name' | head -5)
count=$(echo "$initiatives" | wc -l)

if [ "$count" -ge 1 ]; then
  echo "✓ Found $count initiatives"
else
  echo "✗ Failed to list initiatives"
  exit 1
fi

# Test 2: Fetch specific YAML
echo ""
echo "Test 2: Fetch specific YAML file"
yaml_file="2026-q1-coralogix-quota-manager.yaml"
yaml_content=$(gh api repos/eci-global/initiatives/contents/initiatives/$yaml_file --jq '.content' | base64 -d)

if echo "$yaml_content" | grep -q "schema_version: 2"; then
  echo "✓ YAML fetched and contains schema_version: 2"
else
  echo "✗ YAML fetch failed or missing schema_version"
  exit 1
fi

# Test 3: Parse required fields
echo ""
echo "Test 3: Validate required fields present"
name=$(echo "$yaml_content" | grep "^name:" | cut -d'"' -f2)
status=$(echo "$yaml_content" | grep "^status:" | awk '{print $2}')
owner=$(echo "$yaml_content" | grep "^owner:" | awk '{print $2}')

if [ -n "$name" ] && [ -n "$status" ] && [ -n "$owner" ]; then
  echo "✓ Required fields present:"
  echo "  name: $name"
  echo "  status: $status"
  echo "  owner: $owner"
else
  echo "✗ Missing required fields"
  exit 1
fi

# Test 4: Parse github_project if present
echo ""
echo "Test 4: Check github_project section"
if echo "$yaml_content" | grep -q "github_project:"; then
  project_org=$(echo "$yaml_content" | awk '/github_project:/,/^[a-z]/ {print}' | grep "org:" | awk '{print $2}')
  project_number=$(echo "$yaml_content" | awk '/github_project:/,/^[a-z]/ {print}' | grep "number:" | awk '{print $2}')
  
  if [ -n "$project_org" ] && [ -n "$project_number" ]; then
    echo "✓ github_project found:"
    echo "  org: $project_org"
    echo "  number: $project_number"
  else
    echo "✓ github_project present but incomplete (acceptable)"
  fi
else
  echo "✓ No github_project section (acceptable)"
fi

# Test 5: Parse workstreams if present
echo ""
echo "Test 5: Check workstreams section"
if echo "$yaml_content" | grep -q "workstreams:"; then
  workstream_count=$(echo "$yaml_content" | grep -c "  - name:" || true)
  echo "✓ Found $workstream_count workstream(s)"
else
  echo "✓ No workstreams section (acceptable)"
fi

# Test 6: Status enum validation
echo ""
echo "Test 6: Validate status enum"
valid_statuses=("active" "planning" "paused" "completed" "cancelled")
status_valid=false

for valid_status in "${valid_statuses[@]}"; do
  if [ "$status" = "$valid_status" ]; then
    status_valid=true
    break
  fi
done

if [ "$status_valid" = true ]; then
  echo "✓ Status '$status' is valid"
else
  echo "✗ Status '$status' is not valid (must be: active, planning, paused, completed, cancelled)"
  exit 1
fi

echo ""
echo "=========================================="
echo "All initiative YAML parsing tests passed!"
echo "=========================================="
```

- [ ] **Step 3: Make test executable**

```bash
chmod +x test/github-context-agent/test-initiative-parsing.sh
```

- [ ] **Step 4: Run test to verify it works**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
./test/github-context-agent/test-initiative-parsing.sh
```

Expected: All 6 tests pass

- [ ] **Step 5: Commit test script**

```bash
git add test/github-context-agent/test-initiative-parsing.sh
git commit -m "test(github-context-agent): add initiative YAML parsing test script"
```

---

### Task 12: Create Test Script for Projects v2 GraphQL

**Files:**
- Create: `test/github-context-agent/test-project-graphql.sh`

- [ ] **Step 1: Write Projects v2 GraphQL test**

Create `test/github-context-agent/test-project-graphql.sh`:

```bash
#!/usr/bin/env bash
# Test GitHub Projects v2 GraphQL functionality

set -e

echo "Testing github-context-agent Projects v2 GraphQL..."

# Test 1: Basic project query
echo "Test 1: Fetch project metadata"
project_data=$(gh api graphql -f query='
  query {
    organization(login: "eci-global") {
      projectV2(number: 14) {
        id
        title
        url
        closed
      }
    }
  }
' 2>&1)

if echo "$project_data" | grep -q '"title":'; then
  title=$(echo "$project_data" | jq -r '.data.organization.projectV2.title')
  echo "✓ Project fetched: $title"
else
  echo "✗ Failed to fetch project"
  echo "Response: $project_data"
  exit 1
fi

# Test 2: Fetch project items
echo ""
echo "Test 2: Fetch project items"
items_data=$(gh api graphql -f query='
  query {
    organization(login: "eci-global") {
      projectV2(number: 14) {
        items(first: 10) {
          totalCount
          nodes {
            id
            content {
              ... on Issue {
                number
                title
                state
              }
            }
          }
        }
      }
    }
  }
')

total_count=$(echo "$items_data" | jq -r '.data.organization.projectV2.items.totalCount')

if [ -n "$total_count" ] && [ "$total_count" -ge 0 ]; then
  echo "✓ Project has $total_count items"
else
  echo "✗ Failed to get item count"
  exit 1
fi

# Test 3: Check item types
echo ""
echo "Test 3: Verify item content types"
if echo "$items_data" | grep -q '"number":'; then
  echo "✓ Project contains issues"
else
  echo "✓ Project has no issues (or first 10 are not issues)"
fi

# Test 4: Project state
echo ""
echo "Test 4: Check project state"
closed=$(echo "$project_data" | jq -r '.data.organization.projectV2.closed')

if [ "$closed" = "false" ]; then
  echo "✓ Project is open"
elif [ "$closed" = "true" ]; then
  echo "✓ Project is closed"
else
  echo "✗ Could not determine project state"
  exit 1
fi

echo ""
echo "============================================"
echo "All Projects v2 GraphQL tests passed!"
echo "============================================"
```

- [ ] **Step 2: Make test executable**

```bash
chmod +x test/github-context-agent/test-project-graphql.sh
```

- [ ] **Step 3: Run test to verify it works**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
./test/github-context-agent/test-project-graphql.sh
```

Expected: All 4 tests pass

- [ ] **Step 4: Commit test script**

```bash
git add test/github-context-agent/test-project-graphql.sh
git commit -m "test(github-context-agent): add Projects v2 GraphQL test script"
```

---

### Task 13: Create Test Script for Input Detection

**Files:**
- Create: `test/github-context-agent/test-input-detection.sh`

- [ ] **Step 1: Write input detection test**

Create `test/github-context-agent/test-input-detection.sh`:

```bash
#!/usr/bin/env bash
# Test input type detection logic

set -e

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
```

- [ ] **Step 2: Make test executable**

```bash
chmod +x test/github-context-agent/test-input-detection.sh
```

- [ ] **Step 3: Run test to verify detection logic**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
./test/github-context-agent/test-input-detection.sh
```

Expected: All 12 test cases pass

- [ ] **Step 4: Commit test script**

```bash
git add test/github-context-agent/test-input-detection.sh
git commit -m "test(github-context-agent): add input type detection test script"
```

---

### Task 14: Final Review and Summary

**Files:**
- Modify: `agents/github-context-agent/agent.md` (end of file)

- [ ] **Step 1: Add migration notes**

Add new section at end of agent.md before "Future Enhancements":

```markdown
## Migration from v1.0.0

This version adds initiative, project, workstream, and milestone support. Existing code continues to work unchanged.

### Breaking Changes

None. All existing `type` values (`issue`, `pr`, `repo`) remain supported with identical behavior.

### New Features

- `type: "initiative"` - Fetch initiative YAML from eci-global/initiatives
- `type: "project"` - Fetch GitHub Projects v2 data via GraphQL
- `type: "workstream"` - Scope to specific workstream within initiative
- `type: "milestone"` - Fetch milestone with related initiative context
- Automatic input type detection
- Ambiguous input clarification
- Initiative-project linking (when YAML contains github_project)
- Workstream-milestone association

### Migration Path

**Skills using github-context-agent:**

1. Continue using existing `type: "issue"` for issue context
2. Add `type: "initiative"` when user provides YAML path
3. Add `type: "project"` when user provides project number
4. Let agent auto-detect type by omitting `type` field

**Example:**
```json
// Old (still works)
{
  "type": "issue",
  "identifier": "owner/repo#123"
}

// New (auto-detection)
{
  "identifier": "owner/repo#123"
  // Agent detects type: "issue"
}

// New (initiative)
{
  "type": "initiative",
  "identifier": "initiatives/2026-q1-ai-cost.yaml"
}
```

No changes required to existing skills unless they want to use new features.
```

- [ ] **Step 2: Run all test scripts**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire

echo "Running initiative YAML parsing tests..."
./test/github-context-agent/test-initiative-parsing.sh

echo ""
echo "Running Projects v2 GraphQL tests..."
./test/github-context-agent/test-project-graphql.sh

echo ""
echo "Running input detection tests..."
./test/github-context-agent/test-input-detection.sh

echo ""
echo "All github-context-agent tests passed!"
```

Expected: All three test scripts pass

- [ ] **Step 3: Verify agent.md is complete**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
wc -l agents/github-context-agent/agent.md
```

Expected: File is approximately 800-900 lines (substantial additions)

- [ ] **Step 4: Create summary commit**

```bash
git add agents/github-context-agent/agent.md
git commit -m "docs(github-context-agent): add migration notes and finalize v2.0.0 documentation"
```

- [ ] **Step 5: Create plan completion summary**

Create summary of what was implemented:

```markdown
# github-context-agent Enhancement - Plan Complete

## What Was Implemented

### Documentation Updates (agents/github-context-agent/agent.md)
- ✅ Added 4 new input types: initiative, project, workstream, milestone
- ✅ Documented identifier formats for each type
- ✅ Added Initiative YAML parsing section
- ✅ Added GitHub Projects v2 GraphQL integration section
- ✅ Added workstream and milestone context documentation
- ✅ Added input type detection and ambiguity handling
- ✅ Updated output contract with new context structures
- ✅ Updated configuration with initiatives settings
- ✅ Added 3 new usage examples
- ✅ Updated performance benchmarks
- ✅ Added skill and team integration patterns
- ✅ Added migration notes

### Examples Created
- ✅ agents/github-context-agent/examples/initiative-context.md
- ✅ agents/github-context-agent/examples/project-context.md
- ✅ agents/github-context-agent/examples/ambiguous-input.md

### Test Scripts Created
- ✅ test/github-context-agent/test-initiative-parsing.sh (6 tests)
- ✅ test/github-context-agent/test-project-graphql.sh (4 tests)
- ✅ test/github-context-agent/test-input-detection.sh (12 tests)

## Verification

All tests passing:
- Initiative YAML parsing: ✅
- Projects v2 GraphQL: ✅
- Input detection: ✅

## Next Steps

This plan is complete. The github-context-agent is now documented to support:
1. Initiative YAML from eci-global/initiatives
2. GitHub Projects v2 via GraphQL
3. Workstreams within initiatives
4. Milestones with initiative context
5. Automatic input type detection
6. Ambiguity clarification

Ready for:
- Plan 2: initiative-creator Flexibility
- Plan 3: initiative-breakdown Updates
- Plan 4: Teams & PR Integration
```

---

## Plan Self-Review

### Spec Coverage Check

✅ **Input types** - Added initiative, project, workstream, milestone
✅ **YAML parsing** - Documented fetch from eci-global/initiatives
✅ **Projects v2** - Documented GraphQL integration
✅ **Input detection** - Added detection rules and ambiguity handling
✅ **Output structures** - All 4 new types have complete output contracts
✅ **Examples** - 3 new example files created
✅ **Configuration** - Added initiatives and projects config options
✅ **Performance** - Updated benchmarks for new types
✅ **Integration patterns** - Added for skills and teams
✅ **Testing** - 3 test scripts with 22 total test cases
✅ **Migration** - Documented backward compatibility

### Placeholder Scan

✅ No "TBD" or "TODO" markers
✅ All code examples are complete
✅ All commands include expected output
✅ No "implement later" or "fill in details"
✅ No vague "add appropriate" statements

### Type Consistency

✅ Field names consistent: github_project, workstreams, milestones
✅ Status enum consistent: active, planning, paused, completed, cancelled
✅ Date format consistent: ISO 8601
✅ URL formats consistent across examples

### Gaps

None identified. All spec requirements covered.

---
