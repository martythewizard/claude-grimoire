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
  "type": "issue | initiative | pr | repo",
  "identifier": "owner/repo#123 | https://github.com/owner/repo/issues/123",
  "depth": "shallow | standard | deep",
  "include": {
    "comments": true,
    "relatedPRs": true,
    "relatedIssues": true,
    "commits": false,
    "timeline": true,
    "codeowners": false
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
