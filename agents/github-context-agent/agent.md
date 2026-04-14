---
name: github-context-agent
description: Gather comprehensive GitHub context for issues, initiatives, and PRs
version: 1.0.0
type: agent
---

# GitHub Context Agent

An autonomous agent that gathers comprehensive context from GitHub repositories including issues, initiatives, PRs, commits, and related metadata.

## Purpose

This agent provides structured GitHub context to skills and teams, eliminating the need for manual information gathering. It acts as a specialized research assistant that knows how to navigate GitHub's structure and extract relevant information.

## Capabilities

### Issue Context Gathering
- Fetches issue details (title, description, labels, assignees)
- Retrieves full comment history with timestamps
- Identifies linked PRs and their status
- Extracts acceptance criteria from issue body
- Discovers related issues via mentions and labels

### Initiative/Project Context
- Gathers initiative metadata and goals
- Maps child issues and their status
- Builds timeline of activity
- Identifies key stakeholders
- Tracks progress metrics

### Pull Request Context
- Retrieves PR details and status
- Analyzes review comments and decisions
- Identifies file changes and scope
- Discovers related issues/PRs
- Extracts test results from checks

### Repository Context
- Parses CODEOWNERS for file ownership
- Identifies code reviewers
- Finds recent commits on relevant branches
- Discovers related branches and tags

### Historical Context
- Analyzes commit history for patterns
- Finds similar past issues/PRs
- Identifies recurring contributors
- Tracks resolution times

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

**Note:** New include fields (`yaml`, `project`, `workstreams`, `milestones`, `progress`) default to `false` for backward compatibility. Only explicitly opt-in when needed to avoid unnecessary API calls.

### Type Descriptions

**Existing types:**
- `issue` - GitHub issue
- `pr` - GitHub pull request  
- `repo` - Repository metadata

**New types:**
- `initiative` - Initiative defined in eci-global/initiatives YAML file (previously supported issue-based initiatives, now adds YAML-based support)
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
- Repo project: `owner/repo#project-14` (the `project-` prefix distinguishes from issues)

**Workstream identifiers:**
- Initiative + workstream: `initiative:2026-q1-ai-cost workstream:S3 Data Lake`
- YAML path + workstream: `initiatives/file.yaml workstream:name`

**Milestone identifiers:**
- Repo + milestone name: `owner/repo milestone:"M1 - Foundation"`
- Repo + milestone number: `owner/repo milestone:5`

**Issue/PR identifiers (existing):**
- `owner/repo#123`
- `https://github.com/owner/repo/issues/123`
- `https://github.com/owner/repo/pull/456`
- `#123` (if repo context available)

**Ambiguous detection:**
When identifier could match multiple types, agent asks for clarification. See Input Type Detection section below for detection priority rules and clarification flow.

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

### Depth Levels

**Shallow** (fastest, < 5s)
- Basic metadata only
- No comments or relationships
- Use for quick lookups

**Standard** (balanced, 5-15s)
- Full metadata with comments
- Immediate relationships (linked issues/PRs)
- Timeline of major events
- Default depth level

**Deep** (comprehensive, 15-30s)
- Everything in Standard
- Transitive relationships (issues linked to linked PRs)
- Full commit history
- Similar historical issues
- Use for complex research

## Output Contract

Returns a structured context object. Format varies by type.

### Issue Context

For `type: "issue"` requests:

```json
{
  "success": true,
  "context": {
    "metadata": {
      "id": "123",
      "type": "issue",
      "url": "https://github.com/owner/repo/issues/123",
      "title": "Add user authentication",
      "state": "open",
      "created": "2026-03-15T10:30:00Z",
      "updated": "2026-04-10T14:20:00Z"
    },
    "content": {
      "description": "We need to add JWT-based authentication...",
      "acceptanceCriteria": [
        "User can login with email/password",
        "JWT token issued on successful login",
        "Protected routes require valid token"
      ]
    },
    "participants": {
      "author": "user1",
      "assignees": ["user2", "user3"],
      "reviewers": [],
      "commenters": ["user4", "user5"]
    },
    "labels": ["feature", "security", "high-priority"],
    "relationships": {
      "linkedPRs": [
        {
          "number": 456,
          "title": "Implement JWT authentication",
          "state": "open",
          "url": "https://github.com/owner/repo/pull/456"
        }
      ],
      "linkedIssues": [
        {
          "number": 100,
          "title": "Security improvements initiative",
          "type": "initiative",
          "url": "https://github.com/owner/repo/issues/100"
        }
      ],
      "blockedBy": [],
      "blocks": []
    },
    "timeline": [
      {
        "timestamp": "2026-03-15T10:30:00Z",
        "event": "created",
        "actor": "user1"
      },
      {
        "timestamp": "2026-03-16T09:15:00Z",
        "event": "labeled",
        "actor": "user2",
        "label": "high-priority"
      },
      {
        "timestamp": "2026-04-10T14:20:00Z",
        "event": "referenced",
        "actor": "user3",
        "reference": "PR #456"
      }
    ],
    "comments": [
      {
        "author": "user4",
        "timestamp": "2026-03-20T11:00:00Z",
        "body": "Should we use OAuth instead of JWT?",
        "reactions": {
          "thumbsUp": 3,
          "eyes": 1
        }
      }
    ]
  },
  "codeowners": [
    {
      "pattern": "src/auth/*",
      "owners": ["@security-team", "@user5"]
    }
  ],
  "requestMetadata": {
    "type": "issue",
    "depth": "standard",
    "duration": "8.5s",
    "apiCallsUsed": 12,
    "rateLimitRemaining": 4988
  }
}
```

### Initiative Context (NEW)

For `type: "initiative"` requests:

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
    "pulse": {
      "scan_window": "string",
      "channels": ["string"],
      "discussion_category": "string"
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

For `type: "project"` requests:

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
      "public": false,
      "closed": false,
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
          "issues": [],
          "pull_requests": []
        }
      },
      "by_milestone": {
        "Milestone Title": 0,
        "No milestone": 0
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
  },
  "requestMetadata": {
    "type": "project",
    "depth": "shallow | standard | deep",
    "duration": "string",
    "apiCallsUsed": 0,
    "rateLimitRemaining": 0
  }
}
```

### Workstream Context (NEW)

For `type: "workstream"` requests:

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
    "milestones": [
      {
        "title": "string",
        "number": 0,
        "due": "ISO 8601 date",
        "status": "string",
        "state": "open | closed",
        "url": "string",
        "open_issues": 0,
        "closed_issues": 0
      }
    ],
    "progress": {
      "total_milestones": 0,
      "completed_milestones": 0,
      "total_issues": 0,
      "closed_issues": 0,
      "percentage": 0
    }
  },
  "requestMetadata": {
    "type": "workstream",
    "depth": "shallow | standard | deep",
    "duration": "string",
    "apiCallsUsed": 0,
    "rateLimitRemaining": 0
  }
}
```

### Milestone Context (NEW)

For `type: "milestone"` requests:

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
      "items": []
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
  },
  "requestMetadata": {
    "type": "milestone",
    "depth": "shallow | standard | deep",
    "duration": "string",
    "apiCallsUsed": 0,
    "rateLimitRemaining": 0
  }
}
```

### PR Context

For `type: "pr"` requests, follows similar structure to Issue Context with PR-specific fields (state, reviews, checks).

### Repo Context

For `type: "repo"` requests, includes repository metadata, branches, tags, CODEOWNERS, and other repository-level information.

## Error Handling

The agent handles errors gracefully and provides actionable feedback:

```json
{
  "success": false,
  "error": {
    "type": "NotFound | PermissionDenied | RateLimitExceeded | NetworkError",
    "message": "Issue #123 not found in owner/repo",
    "suggestion": "Verify the issue number and repository are correct",
    "retryable": false
  }
}
```

### Error Types

**NotFound**
- Issue/PR doesn't exist
- Repository not found
- Suggestion: Verify identifier

**PermissionDenied**
- Private repository without access
- Missing token scopes
- Suggestion: Check GitHub token permissions

**RateLimitExceeded**
- GitHub API rate limit hit
- Suggestion: Wait or use personal access token

**NetworkError**
- GitHub API unavailable
- Connection timeout
- Suggestion: Retry in a moment

## Implementation Details

### GitHub API Usage

The agent uses:
- **GitHub REST API** for structured data
- **GitHub GraphQL API** for complex queries (reduces API calls)
- **GitHub CLI (`gh`)** as fallback

### Authentication

Requires GitHub token with scopes:
- `repo` (for private repos)
- `read:org` (for organization data)
- `read:project` (for project boards)

Token sources (in priority order):
1. `GITHUB_TOKEN` environment variable
2. `gh` CLI authentication
3. Git credential helper

### Caching

To reduce API calls and improve performance:
- Caches results for 5 minutes (configurable)
- Cache key: `{type}:{owner}:{repo}:{identifier}:{depth}`
- Invalidates on explicit refresh request

### Rate Limit Management

- Checks rate limit before making calls
- Reserves 100 calls for other tools
- Falls back to cached data if rate limited
- Warns when < 500 calls remaining

## Usage Examples

### Example 1: Fetch Issue Context for PR Description

**Request:**
```json
{
  "type": "issue",
  "identifier": "myorg/myrepo#125",
  "depth": "standard"
}
```

**Use Case:**
When generating a PR description, fetch the related issue to:
- Include proper "Closes #125" reference
- Extract acceptance criteria for test plan
- Understand the context and motivation

### Example 2: Quick PR Status Check

**Request:**
```json
{
  "type": "pr",
  "identifier": "myorg/myrepo#456",
  "depth": "shallow"
}
```

**Use Case:**
Quick check of PR status:
- Is it merged, open, or closed?
- What's the current CI status?
- Who are the reviewers?

### Example 3: Find Code Owners for PR

**Request:**
```json
{
  "type": "repo",
  "identifier": "myorg/myrepo",
  "depth": "shallow",
  "include": {
    "codeowners": true
  }
}
```

**Use Case:**
When creating a PR, identify:
- Who should review based on files changed
- Team ownership of modified code
- Required approvals

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

## Invoked By

This agent is invoked by:
- `pr-author` skill - To fetch issue/initiative context
- `initiative-breakdown` skill - To gather initiative details
- `initiative-creator` skill - To check for existing initiatives
- `feature-delivery-team` - To fetch context at various phases
- `pr-autopilot-team` - To gather context for PR creation

## Integration Patterns

### Skill Integration

Skills use the github-context-agent to gather and process structured GitHub context for various tasks.

**Pattern 1: Initiative Context (for breakdown tasks)**

Used by skills that need to understand initiative structure and scope.

```json
{
  "type": "initiative",
  "identifier": "initiatives/2026-q1-ai-cost-intelligence-platform.yaml",
  "depth": "standard",
  "include": {
    "yaml": true,
    "project": true,
    "workstreams": true,
    "milestones": true,
    "progress": true
  }
}
```

Processing steps:
1. Extract initiative metadata (name, status, owner, team)
2. Retrieve all workstreams and their associated milestones
3. Map repositories to workstreams
4. Get GitHub Project reference if available
5. Collect progress metrics from all sources
6. Use to create scoped breakdown tasks

Example skill usage: `initiative-breakdown` skill fetches initiative, extracts workstreams, creates issues in correct repos, assigns to correct milestones.

**Pattern 2: Project Context (for linking tasks)**

Used by skills that need to manage issues within a GitHub Project.

```json
{
  "type": "project",
  "identifier": "eci-global#14",
  "depth": "shallow",
  "include": {
    "project": true
  }
}
```

Processing steps:
1. Get project metadata and status
2. Retrieve project GraphQL node ID for linking
3. Count existing items by state
4. Map items to repositories
5. Check for related initiative in YAML
6. Use node ID to add new issues to project

Example skill usage: When creating new issues, skills fetch project context first to get GraphQL ID, then link newly created issues to the project.

**Pattern 3: Workstream Scoping (for scoped task creation)**

Used by skills that need to create tasks within a specific workstream.

```json
{
  "type": "workstream",
  "identifier": "initiative:2026-q1-ai-cost workstream:S3 Data Lake",
  "depth": "standard",
  "include": {
    "workstreams": true,
    "milestones": true
  }
}
```

Processing steps:
1. Parse initiative reference and workstream name
2. Load initiative YAML and find workstream
3. Extract repo and milestone list for workstream
4. Fetch milestone details and current issues
5. Calculate workstream progress
6. Use milestone info to scope new tasks

Example skill usage: When user requests breakdown of one workstream only, skills fetch workstream context, create issues only in relevant repo and milestones, avoid affecting other workstreams.

**Pattern 4: Milestone Assignment (for issue creation)**

Used by skills that need to create issues within a milestone context.

```json
{
  "type": "milestone",
  "identifier": "eci-global/one-cloud-cloud-costs milestone:5",
  "depth": "standard",
  "include": {
    "milestones": true
  }
}
```

Processing steps:
1. Parse repository and milestone reference
2. Fetch milestone by number or title
3. Retrieve all issues in milestone
4. Get milestone due date and current state
5. Check for related workstream
6. Use to understand milestone scope and create aligned issues

Example skill usage: When creating new task, skills fetch milestone context to understand what's already planned, ensure new issue fits milestone goals, avoid duplicates.

### Team Integration

Teams use the github-context-agent across phases of workflow execution.

**Pattern 1: Initiative Planning Phase**

When planning initiative work:

```json
{
  "type": "initiative",
  "identifier": "initiatives/2026-q1-ai-cost-intelligence-platform.yaml",
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

Team workflow:
1. Fetch full initiative context at deep depth
2. Review initiative metadata, goals, owner, team assignments
3. Examine all workstreams and their repos
4. Check GitHub Project for existing linked items
5. Review progress metrics across all sources
6. Identify gaps or misalignments
7. Pass structured context to breakdown or execution phase

**Pattern 2: Milestone Progression Tracking**

When monitoring milestone progress:

```json
{
  "type": "milestone",
  "identifier": "eci-global/one-cloud-cloud-costs milestone:5",
  "depth": "standard"
}
```

Team workflow:
1. Fetch milestone context periodically
2. Track open vs closed issue counts
3. Check milestone due date and current state
4. Identify related workstream from initiative YAML
5. Detect related GitHub Project
6. Use for status reports and progress tracking
7. Notify stakeholders of milestone changes

## Configuration

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
- `ambiguityHandling` - How to handle ambiguous input: "prompt" (ask user) or "auto" (best guess) (default: "prompt")

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

## Performance Considerations

### Optimization Strategies

1. **Use appropriate depth**
   - Shallow for quick checks
   - Standard for most use cases
   - Deep only when necessary

2. **Selective inclusion**
   - Only include what you need
   - Comments are expensive (1 API call per 100 comments)
   - Commits are expensive (1 API call per commit page)

3. **Batch requests**
   - When fetching multiple issues, batch when possible
   - GraphQL for complex multi-entity queries

4. **Cache awareness**
   - Repeated requests within 5 minutes are cached
   - Manual refresh available when needed

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

## Monitoring and Debugging

### Debug Mode

Enable debug output:

```json
{
  "type": "issue",
  "identifier": "myorg/myrepo#123",
  "debug": true
}
```

Returns additional metadata:
```json
{
  "debug": {
    "apiCalls": [
      {
        "endpoint": "/repos/myorg/myrepo/issues/123",
        "duration": "245ms",
        "cached": false
      }
    ],
    "cacheHits": 2,
    "cacheMisses": 3
  }
}
```

### Logging

Logs include:
- API calls made
- Rate limit status
- Cache performance
- Error details

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

## Future Enhancements

- **Semantic search** - Find similar issues by description
- **Pattern detection** - Identify recurring issues
- **Velocity metrics** - Track issue resolution times
- **Dependency graphs** - Visualize issue relationships
- **Webhook integration** - Real-time updates instead of polling
- **Multi-repo support** - Gather context across related repositories
