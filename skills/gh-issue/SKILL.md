---
name: gh-issue
description: "Fetch rich context for a GitHub issue or milestone and display it in a structured format. Use before fix-issue or develop-team for deep issue context, or standalone to explore an issue/milestone. Writes context to .gh-issue/context.json for downstream skills to consume."
---

# GitHub Issue & Milestone Context

Fetch, enrich, and display rich context for a GitHub issue or milestone. Surfaces linked PRs, project board status, related issues, and milestone progress — all in one view. Downstream skills (`/fix-issue`, `/develop-team`) check for the output file and use it instead of fetching fresh.

## When to Use

- Before running `/fix-issue` — get full issue context pre-loaded
- Before running `/develop-team` — surface acceptance criteria, linked issues, milestone scope
- Standalone — explore an issue, review a milestone, check project board status
- Understanding a bug's history — linked PRs, past comments, who touched this area

## Dependencies

**External tools:**
- `gh` CLI — [cli.github.com](https://cli.github.com/) (`gh auth login` required)

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| (first arg) | required | Issue number (`123`, `#123`) or milestone name/number (`v2.0`, `milestone:5`) |
| `type` | `auto` | `issue` \| `milestone` \| `auto` (detected from argument shape) |
| `output` | `both` | `display` (print to terminal only) \| `file` (write `.gh-issue/context.json` only) \| `both` |
| `repo` | (current) | Override repo: `owner/repo` — defaults to current directory's GitHub remote |
| `generate` | `true` | Set `false` to skip AI generation and comment posting (pure read mode). Also suppressed by `output=display`. |

## Invocation

```
/gh-issue 123                          # fetch issue #123, display + write file
/gh-issue #123                         # same
/gh-issue 123 output=display           # display only, no file
/gh-issue v2.0                         # fetch milestone named v2.0
/gh-issue milestone:5                  # fetch milestone by number
/gh-issue 123 repo=owner/other-repo    # different repo
```

## Architecture

```
ORCHESTRATOR (main session)
|
+-- Phase 0: DETECT TYPE + RESOLVE REPO
|   Parse argument: issue number vs milestone name/number
|   Detect repo from git remote or parameter
|
+-- Phase 1: FETCH CORE DATA
|   Issue mode:     gh issue view + gh issue comment list
|   Milestone mode: gh api /repos/{owner}/{repo}/milestones + list issues
|
+-- Phase 2: ENRICH (parallel fetches)
|   Linked PRs:     gh pr list --search "#{number}" + scan body for "Fixes/Closes/Resolves"
|   Related issues: scan body for #N references, fetch each
|   Project board:  gh project item-list (if project configured)
|
+-- Phase 2.5: GENERATE TASK SPEC (unless output=display or generate=false)
|   AI generates acceptance criteria, expected vs. actual behavior, edge cases, technical context
|   Uses all data from Phase 1 and Phase 2 as input
|
+-- Phase 2.6: POST COMMENT TO GITHUB (unless output=display or generate=false)
|   Posts structured comment with <!-- gh-issue:generated --> marker via gh issue comment
|   Old generated comments preserved as history — always posts fresh
|
+-- Phase 3: DISPLAY
|   Format structured output for terminal
|
+-- Phase 4: WRITE FILE (unless output=display)
|   Write .gh-issue/context.json (includes generatedSpec fields)
|   Auto-update .gitignore to include .gh-issue/
|   Report: "Context written to .gh-issue/context.json — /fix-issue and /develop-team will use it automatically"
```

---

## Workflow

### Phase 0: Detect Type + Resolve Repo

**Parse the argument:**

| Argument shape | Type | Value |
|----------------|------|-------|
| `123` or `#123` | `issue` | Issue number 123 |
| `v2.0`, `v1.0.1` | `milestone` | Search by title |
| `milestone:5` | `milestone` | Fetch by number 5 |
| `type=issue` (explicit) | `issue` | Override |
| `type=milestone` (explicit) | `milestone` | Override |

**Resolve repo:**

```bash
# Get GitHub remote URL and extract owner/repo
git remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]\([^.]*\).*/\1/'
```

If `repo` parameter provided, use it directly. If git remote fails and no parameter, ask the user: "Which repo? (format: owner/repo)"

Store resolved `OWNER`, `REPO`, and `TYPE` for all subsequent phases.

### Phase 1: Fetch Core Data

#### Issue Mode

```bash
# Full issue details
gh issue view {number} --repo {owner}/{repo} \
  --json number,title,body,state,labels,assignees,milestone,author,createdAt,updatedAt,url,comments

# Comments (if issue has comments — check `comments` count from above)
gh issue view {number} --repo {owner}/{repo} --comments \
  --json comments
```

Extract from the response:
- **Number, title, state** (open/closed)
- **Body** — full description, repro steps, acceptance criteria
- **Labels** — current state labels
- **Assignees** — who is assigned
- **Milestone** — which release this targets
- **Author** — who filed it
- **Created/Updated** — age and last activity
- **Comments** — discussion history, additional context

#### Milestone Mode

```bash
# List all milestones to find by name or get by number
gh api /repos/{owner}/{repo}/milestones --jq '.[] | {number, title, state, description, due_on, open_issues, closed_issues}'

# Get all issues in this milestone
gh issue list --repo {owner}/{repo} --milestone "{milestoneName}" \
  --json number,title,state,labels,assignees,createdAt,updatedAt \
  --limit 100
```

### Phase 2: Enrich (Parallel Fetches)

Run all enrichment in parallel for speed.

#### Linked PRs

Search for PRs that reference this issue number in their title, body, or branch name:

```bash
# PRs with "Closes/Fixes/Resolves #N" in body or that reference this issue
gh pr list --repo {owner}/{repo} --state all \
  --search "#{issueNumber}" \
  --json number,title,state,mergedAt,headRefName,url \
  --limit 10
```

Also check current PR descriptions for "Closes #N" patterns:

```bash
gh pr list --repo {owner}/{repo} --state open \
  --json number,title,body \
  --limit 20 | jq '[.[] | select(.body | test("(Closes|Fixes|Resolves) #?{issueNumber}"))]'
```

#### Related Issues

Scan the issue body for `#N` references. For each unique issue number found:

```bash
gh issue view {referencedNumber} --repo {owner}/{repo} \
  --json number,title,state,labels
```

Limit to 5 related issues to avoid context bloat.

#### Project Board Status

If a `gh-issue` project is configured (check for `.gh-issue/config.json` or CONFIG.md in the project root):

```bash
# Find this issue in the project
gh project item-list {projectNumber} --owner {owner} --format json \
  | jq '.items[] | select(.content.number == {issueNumber}) | {id, status: .fieldValues}'
```

If no project is configured, skip silently.

### Phase 2.5: Generate Task Spec

**Skip if `output=display` or `generate=false`.**

Use all data collected in Phase 1 (issue title, body, labels, state, comments, author) and Phase 2 (linked PRs, related issues, project board status) as context. Generate a structured task spec by reasoning over the issue content.

**Generation prompt:**

```
You are a product manager writing a task spec for a developer.

Issue: #{number} — {title}
Description: {body — truncated to 3000 chars}
Labels: {labels joined by comma}
Recent comments: {last 3 comments, each truncated to 200 chars}
Linked PRs: {PR titles and states, or "None"}
Related issues: {issue titles and states, or "None"}

Write a task spec with these five sections. Be specific and concrete. Do not pad.

1. Acceptance Criteria (3-6 items) — testable checkboxes written from the user's perspective
2. Expected Behavior (1-3 sentences) — what the system should do when working correctly
3. Actual Behavior (1-2 sentences) — what is currently happening, derived from the issue description
4. Edge Cases (2-4 bullets) — scenarios that should also be verified when fixing this issue
5. Technical Context (1-3 sentences) — which components or code areas are likely involved, based on labels and related issues
```

Store the five sections as `GENERATED_SPEC` for use in Phase 2.6.

If the issue body is less than 50 characters (too sparse to generate from), set `GENERATION_SKIPPED=true` and report: "Issue body too sparse to generate a meaningful spec — add more detail to the issue and re-run."

### Phase 2.6: Post Comment to GitHub Issue

**Skip if `output=display`, `generate=false`, or `GENERATION_SKIPPED=true`.**

Format the generated spec as a GitHub comment and post it:

```bash
gh issue comment {number} --repo {owner}/{repo} --body "$(cat <<'COMMENT'
<!-- gh-issue:generated -->
## Task Spec

> Generated by /gh-issue on {YYYY-MM-DD}. Update this issue if requirements change.

### Acceptance Criteria
{GENERATED_SPEC acceptance criteria as - [ ] checkboxes}

### Expected Behavior
{GENERATED_SPEC expected behavior}

### Actual Behavior
{GENERATED_SPEC actual behavior}

### Edge Cases
{GENERATED_SPEC edge cases as bullet list}

### Technical Context
{GENERATED_SPEC technical context}
COMMENT
)"
```

Capture the response to get the comment URL:

```bash
gh issue comment {number} --repo {owner}/{repo} --body "..." 2>&1
# Then get the URL of the most recent comment:
gh issue view {number} --repo {owner}/{repo} --comments --json comments \
  --jq '.comments[-1].url'
```

Store the comment URL as `GENERATED_COMMENT_URL` for use in Phase 4 (context.json).

After posting, print:
```
Task spec posted to issue #{number}.
/fix-issue and /develop-team will use this spec automatically.
```

### Phase 3: Display

Present a structured, scannable view. Use this format:

```
## Issue #{number}: {title}

**State:** {open 🟢 / closed ✅}  |  **Author:** @{author}  |  **Created:** {relative date}
**Labels:** {label1} {label2}  |  **Assigned:** @{assignee} (or "Unassigned")
**Milestone:** {milestone title} ({open_issues} open, {closed_issues} closed)
**Project:** {column status} (or not tracked)

---

### Description
{body — truncated at 2000 chars with "... (truncated, see full at {url})" if longer}

---

### Acceptance Criteria
{extracted from body if present — look for "## Acceptance Criteria", "### AC", "- [ ]" checklists}
{if none found: "None specified in issue body"}

---

### Comments ({count} total)
{last 3 comments, each with: author, date, body truncated at 300 chars}
{if more: "({N} earlier comments — view at {url})"}

---

### Linked PRs
{PR #N: title [state: open/merged/closed] - {url}}
{or "None found"}

---

### Related Issues
{#N: title [state] — {label}}
{or "None referenced"}

---

### Quick Commands
  Fix this issue:    /fix-issue {number}
  Develop a feature: /develop-team {number}
  Review the PR:     /review-team {prNumber}   (if linked PR exists)
```

**For milestone mode**, replace the issue display with:

```
## Milestone: {title}

**State:** {open/closed}  |  **Due:** {date, or "No due date" if dueOn is null or absent}
**Progress:** {closed}/{total} issues closed ({percent}%)

---

### Issues by Status

**Open ({count}):**
  #{N} — {title} [{labels}] — @{assignee or "unassigned"}
  ...

**Closed ({count}):**
  #{N} — {title} — merged via PR #{prN}
  ...

---

### Progress Bar
[██████████░░░░░░░░░░] {percent}% complete
```

### Phase 4: Write Context File

**Skip if `output=display`.**

Create `.gh-issue/` directory if needed, then write:

```json
{
  "type": "issue",
  "number": 123,
  "title": "Bug: checkout form breaks on mobile",
  "body": "...",
  "state": "open",
  "labels": ["bug", "high-priority"],
  "assignees": ["jane-doe"],
  "milestone": {
    "title": "v2.1",
    "number": 4,
    "dueOn": "2026-05-01",
    "openIssues": 8,
    "closedIssues": 14
  },
  "author": "bob-smith",
  "createdAt": "2026-04-10T14:23:00Z",
  "updatedAt": "2026-04-13T09:15:00Z",
  "url": "https://github.com/owner/repo/issues/123",
  "comments": [
    {
      "author": "jane-doe",
      "body": "...",
      "createdAt": "2026-04-11T10:00:00Z"
    }
  ],
  "linkedPRs": [
    {
      "number": 456,
      "title": "fix: checkout form mobile layout",
      "state": "open",
      "url": "https://github.com/owner/repo/pull/456"
    }
  ],
  "relatedIssues": [
    { "number": 110, "title": "...", "state": "closed" }
  ],
  "projectStatus": "In Progress",
  "generatedSpec": {
    "acceptanceCriteria": ["User can complete checkout on mobile without form errors", "Submit button remains enabled during validation"],
    "expectedBehavior": "The checkout form submits successfully on mobile viewports (320px–768px).",
    "actualBehavior": "The submit button becomes unclickable on viewports below 768px due to an overlapping element.",
    "edgeCases": ["iOS Safari 16", "Android Chrome with zoom enabled", "Landscape orientation on small phones"],
    "technicalContext": "Affects CheckoutForm component. Likely a z-index or pointer-events issue in the mobile breakpoint styles."
  },
  "generatedAt": "2026-04-14T08:30:00Z",
  "fetchedAt": "2026-04-14T08:30:00Z",
  "repo": "owner/repo"
}
```

> **Null fields:** Write `milestone.dueOn` as `null` (not omitted) when the milestone has no due date. If `milestone` itself is null (issue not in a milestone), write `"milestone": null`. If generation was skipped (`output=display`, `generate=false`, or body too sparse), write `"generatedSpec": null` and omit `"generatedAt"`.

**For milestone mode**, the JSON is structured as:

```json
{
  "type": "milestone",
  "number": 4,
  "title": "v2.1",
  "state": "open",
  "dueOn": "2026-05-01",
  "description": "Sprint goals for v2.1",
  "openIssues": 8,
  "closedIssues": 14,
  "issues": [
    {
      "number": 123,
      "title": "...",
      "state": "open",
      "labels": ["bug"],
      "assignees": ["jane-doe"]
    }
  ],
  "fetchedAt": "2026-04-14T08:30:00Z",
  "repo": "owner/repo"
}
```

When `due_on` is null in the GitHub API response, write `dueOn` explicitly as `null` (never omit the key):

```json
{
  "type": "milestone",
  "number": 5,
  "title": "v2.2",
  "state": "open",
  "dueOn": null,
  "description": null,
  "openIssues": 3,
  "closedIssues": 0,
  "issues": [],
  "fetchedAt": "2026-04-14T08:30:00Z",
  "repo": "owner/repo"
}
```

After writing the file, auto-update `.gitignore` if needed:

```bash
grep -q "\.gh-issue/" .gitignore 2>/dev/null || echo ".gh-issue/" >> .gitignore
```

After writing, report:

```
Context written to .gh-issue/context.json

/fix-issue and /develop-team will automatically use this context (valid for 30 minutes).
If context.json expires, they will fall back to the generated comment on the issue.
To refresh: run /gh-issue {number} again.
```

---

## How Downstream Skills Use the Context File

Both `/fix-issue` and `/develop-team` check for `.gh-issue/context.json` at the start of their Phase 1. If the file exists AND `fetchedAt` is within 30 minutes, they use it instead of fetching fresh. This surfaces richer context (linked PRs, related issues, generated spec) that those skills don't fetch themselves.

**Fallback when context.json is absent or stale:** downstream skills look for the most recent gh-issue generated comment on the issue:

```bash
gh issue view {number} --comments --json comments \
  --jq '[.comments[] | select(.body | startswith("<!-- gh-issue:generated -->"))] | last'
```

If a generated comment is found, the `acceptanceCriteria`, `expectedBehavior`, and `edgeCases` sections are parsed from the comment body and used as the task spec context.

If neither context.json nor a generated comment exists, downstream skills fall back to extracting acceptance criteria from the issue body directly (looking for `## Acceptance Criteria`, `### AC`, or `- [ ]` checklists).

**To force a fresh fetch** in downstream skills, either:
- Delete `.gh-issue/context.json`
- Re-run `/gh-issue {number}` to refresh it
- Pass `skip-gh-context=true` to the downstream skill to bypass both context.json and the comment fallback

---

## Error Handling

| Scenario | Action |
|----------|--------|
| `gh auth status` fails | Tell user to run `gh auth login` first |
| Issue not found | Report "Issue #{number} not found in {owner}/{repo}" — check repo, verify auth |
| Milestone not found | List available milestones, ask user to confirm |
| No git remote | Ask user: "Which repo? (format: owner/repo)" |
| Project board fetch fails | Log "Project board status unavailable" — continue without it |
| Related issue fetch fails | Skip that issue, continue |
| Write fails (no permissions) | Write to `/tmp/gh-issue-context.json` and report the alternate path |
| Body longer than 10,000 chars | Truncate to 5,000 chars, note full content at issue URL |

---

## Tips

1. **Run before fix-issue** — `gh-issue` surfaces linked PRs and milestone context that `fix-issue` would miss
2. **Use for milestone planning** — `gh-issue v2.0` gives a full progress view with all issues in one command
3. **Context lasts 30 minutes** — Re-run if you start a fix session after a gap
4. **Related issues help debugging** — Often the bug has been attempted before in a now-closed issue
5. **Project board is optional** — Skill works fine without a project configured; board status is additive
