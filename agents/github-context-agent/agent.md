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

Returns a structured context object:

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
    "depth": "standard",
    "duration": "8.5s",
    "apiCallsUsed": 12,
    "rateLimitRemaining": 4988
  }
}
```

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

### Example 2: Research Initiative for Breakdown

**Request:**
```json
{
  "type": "initiative",
  "identifier": "https://github.com/myorg/myrepo/issues/100",
  "depth": "deep",
  "include": {
    "comments": true,
    "relatedIssues": true,
    "commits": true,
    "timeline": true
  }
}
```

**Use Case:**
When breaking down an initiative, gather:
- All child issues and their status
- Discussion in comments
- Related code changes
- Timeline to understand dependencies

### Example 3: Quick PR Status Check

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

### Example 4: Find Code Owners for PR

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

## Invoked By

This agent is invoked by:
- `pr-author` skill - To fetch issue/initiative context
- `initiative-breakdown` skill - To gather initiative details
- `initiative-creator` skill - To check for existing initiatives
- `feature-delivery-team` - To fetch context at various phases
- `pr-autopilot-team` - To gather context for PR creation

## Integration Patterns

### Skill Integration

From a skill:

```markdown
### Step: Gather GitHub Context

Invoke the `github-context-agent` with:
- Issue numbers provided by user
- Standard depth
- Include comments and related PRs

Use the returned context to:
- Generate PR references
- Include acceptance criteria
- Identify stakeholders
```

### Team Integration

From a team workflow:

```markdown
**Phase 1: Context Gathering**

1. Invoke `github-context-agent` with initiative URL
2. Extract:
   - Initiative goals and scope
   - Child issues and their status
   - Key stakeholders
3. Pass context to next phase
```

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
    "cacheTTL": 300
  }
}
```

### Per-Repo Config (`.claude-grimoire/config.json`)

```json
{
  "github": {
    "defaultDepth": "standard",
    "codeownersPath": ".github/CODEOWNERS",
    "includeArchivedIssues": false
  }
}
```

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

### Performance Benchmarks

Typical response times (standard depth):

| Context Type | API Calls | Time |
|-------------|-----------|------|
| Single Issue | 3-5 | 2-4s |
| Initiative (10 child issues) | 15-20 | 8-12s |
| PR with reviews | 5-8 | 3-6s |
| Repository CODEOWNERS | 1-2 | 1-2s |

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

## Future Enhancements

- **Semantic search** - Find similar issues by description
- **Pattern detection** - Identify recurring issues
- **Velocity metrics** - Track issue resolution times
- **Dependency graphs** - Visualize issue relationships
- **Webhook integration** - Real-time updates instead of polling
- **Multi-repo support** - Gather context across related repositories
