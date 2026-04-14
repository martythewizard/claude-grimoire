# PR with Initiative Reference Example

## Scenario

Creating a pull request for a task that's part of a larger initiative, linked to a project board and assigned to a milestone.

## Input

- Working on issue #234 in eci-global/api
- Task is part of a Q1 initiative
- Linked to project board #14
- Assigned to milestone M2
- Branch: `feat/rate-limiting`
- 3 commits with changes to rate limiting implementation

## Process

```
User: /pr-author

Skill: Analyzing git state...
  Branch: feat/rate-limiting
  Commits: 3
  Referenced issues in commits: #234

Skill: Fetching context for issue #234 via github-context-agent...

Agent response for issue #234:
  {
    "type": "issue",
    "number": 234,
    "title": "Implement rate limiting for API endpoints",
    "metadata": {
      "created_at": "2026-03-15T10:30:00Z",
      "state": "open"
    },
    "related_initiative": {
      "yaml_path": "initiatives/2026-q1-ai-cost-intelligence-platform.yaml",
      "name": "2026 Q1 - AI Cost Intelligence Platform"
    },
    "related_project": {
      "org": "eci-global",
      "number": 14,
      "url": "https://github.com/orgs/eci-global/projects/14"
    },
    "related_workstream": {
      "name": "Intelligence System",
      "initiative": "2026 Q1 - AI Cost Intelligence Platform"
    },
    "related_milestone": {
      "title": "M2 — Learning Normal",
      "repo": "eci-global/api"
    }
  }

Skill: Detected initiative and project linkage.
  - Initiative: 2026 Q1 - AI Cost Intelligence Platform
  - Project: eci-global/projects/14
  - Workstream: Intelligence System
  - Milestone: M2 — Learning Normal

Skill: Analyzing changes...
  Files modified: 3
  - Added: 2 files
  - Modified: 2 files
  - Tests: Added integration tests

Skill: Generating PR description with full context...
```

## Generated PR Title

```
Add API rate limiting for cost control
```

## Generated PR Description

```markdown
# Add API rate limiting for cost control

## Summary

Implements rate limiting on API endpoints to prevent cost overruns from runaway processes. Uses token bucket algorithm with per-client limits stored in Redis. This addresses the critical need to control API costs during the intelligence system development phase.

- Implements token bucket rate limiting algorithm
- Stores rate limits in Redis with TTL support
- Provides per-client rate limits based on API key
- Includes graceful degradation if Redis is unavailable
- Adds rate limit headers to all API responses

## Related Work

**Issues:**
- Closes #234 - Implement rate limiting for API endpoints

**Initiative:**
[2026 Q1 - AI Cost Intelligence Platform](https://github.com/eci-global/initiatives/blob/main/initiatives/2026-q1-ai-cost-intelligence-platform.yaml)

**Project:**
https://github.com/orgs/eci-global/projects/14

**Workstream:**
Intelligence System

**Milestone:**
M2 — Learning Normal (eci-global/api)

## Changes

### Added
- `src/middleware/rate-limiter.ts` - Token bucket rate limiter implementation
- `src/redis/rate-limit-store.ts` - Redis storage abstraction for rate limits
- `config/rate-limits.yaml` - Per-endpoint rate limit configuration file
- `tests/integration/rate-limits.test.ts` - End-to-end rate limiting tests

### Modified
- `src/api/server.ts` - Applied rate limiter middleware to request pipeline
- `src/api/routes/data.ts` - Added rate limit headers to responses

### Files Changed
- 3 files modified
- 2 files added
- ~250 lines added, ~15 lines removed

## Test Plan

- [x] Unit tests pass (100% coverage on rate limiter module)
- [x] Integration tests verify rate limiting enforces limits correctly
- [x] Manual testing with burst traffic (100+ req/sec)
- [x] Verified rate limit headers in responses (X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset)
- [x] Tested graceful degradation when Redis connection fails
- [x] Tested per-client isolation (separate limits per API key)
- [x] Edge case: Rate limit boundary conditions
- [x] Edge case: Clock skew handling in token bucket

## Implementation Notes

- **Algorithm:** Token bucket - allows controlled bursts while maintaining average rate limit
- **Storage:** Redis with configurable TTL (default 1 hour)
- **Failure Mode:** Logs warning and allows requests if Redis unavailable (fail-open)
- **Per-Client:** Limits based on API key extraction from request headers
- **Response Headers:** X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset
- **Configuration:** YAML-based per-endpoint limits, hot-reloadable

## Reviewer Notes

Please pay particular attention to:
1. The graceful degradation logic - ensure the fail-open behavior matches your team's security requirements
2. Redis connection handling - we're using the existing connection pool from `src/redis/pool.ts`
3. Rate limit values in `config/rate-limits.yaml` - these may need adjustment based on production usage patterns

The implementation follows the architectural pattern established in the intelligent cost monitoring system (M1) and should integrate seamlessly with the existing pipeline.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Result

PR created with full initiative, project, workstream, and milestone context visible to reviewers. The "Related Work" section clearly shows how this task connects to the larger organizational initiative and planning structure, helping reviewers understand the broader context and making it easier to track related work across multiple PRs.
