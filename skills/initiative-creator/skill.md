---
name: initiative-creator
description: Create well-structured GitHub initiatives through guided workflow
version: 1.0.0
author: claude-grimoire
requires:
  - github
optional_agents:
  - visual-prd
---

# Initiative Creator

Creates well-structured GitHub initiatives through a conversational interview process. Gathers context about goals, success metrics, scope, constraints, dependencies, and timeline to generate comprehensive initiative descriptions.

## Purpose

Turn high-level project ideas into actionable GitHub initiatives with:
- Clear objectives and success criteria
- Proper scope definition and constraints
- Timeline estimates and milestones
- Stakeholder assignments and dependencies
- Linked issues and related work
- Optional visual PRD for complex initiatives

## When to Use

- Starting a new project or large initiative
- Planning a multi-week or multi-sprint effort
- Need to communicate scope to stakeholders
- Breaking down a high-level goal into trackable work
- Coordinating work across multiple repositories or teams

## Workflow

The skill operates in three modes based on user input and needs:

1. **Standalone Issue Mode** - Create issue without initiative/project
2. **Linking Mode** - Create or link issue to existing initiative/project
3. **Full Initiative Mode** - Create comprehensive YAML initiative (rare)

### Mode Detection Process

**Phase 1: Parse Input**

Check what user provided:

```
Parameters provided:
  --issue owner/repo#123        → Use existing issue (Linking Mode)
  --title "..." --body "..."    → Create new issue (Standalone or Linking)
  --project org#14              → Link to project (Linking Mode)
  --initiative path/to/yaml     → Link to initiative (Linking Mode)
  --yaml                        → Force Full Initiative Mode
  
No parameters:
  → Interactive detection
```

**Phase 2: Interactive Detection (if no parameters)**

```
Ask user: "What would you like to create?"

A) Standalone issue (no initiative or project)
B) Issue linked to existing initiative or project
C) New comprehensive initiative with YAML file

If A: → Standalone Issue Mode
If B: → Linking Mode (ask for initiative/project reference)
If C: → Full Initiative Mode
```

### Mode Workflows

The skill branches to one of three workflows based on detected mode:
- Standalone Issue Mode → Task 2
- Linking Mode → Task 3
- Full Initiative Mode → Task 4

## Standalone Issue Mode

Create a single GitHub issue without linking to initiatives or projects.

### When to Use

- Quick bug fixes
- Small standalone tasks
- Issues that don't fit into any initiative
- Exploratory work

### Workflow

**Step 1: Gather Issue Details**

Ask user (or use parameters):
- Title (required)
- Description/body (required)
- Repository (required if not in repo context)
- Labels (optional)
- Assignees (optional)
- Milestone (optional, but no initiative context)

**Step 2: Create Issue**

```bash
gh issue create \
  --repo <owner>/<repo> \
  --title "<title>" \
  --body "<body>" \
  --label "<labels>" \
  --assignee "<assignee>"
```

**Step 3: Report Completion**

```
✅ Issue created: https://github.com/<owner>/<repo>/issues/<number>

This is a standalone issue (not linked to any initiative or project).
```

### Parameter Examples

```bash
# Interactive
/initiative-creator
> "What would you like to create?"
> A) Standalone issue

# Non-interactive
/initiative-creator --title "Fix login bug" --body "Users can't login" --repo eci-global/app

# With labels and assignee
/initiative-creator --title "Update docs" --body "Add API docs" --repo owner/repo --label documentation --assignee username
```

### Example Output

```
Issue created at: https://github.com/eci-global/app/issues/789

Title: Fix login bug
Labels: bug
Assignee: none
Milestone: none

This is a standalone issue. To link it to an initiative or project later, run:
  /initiative-creator --issue eci-global/app#789 --project org#14
```

### 2. Goals and Success Metrics

Define what success looks like:

**Questions to ask:**
- What are the primary goals of this initiative?
- How will you measure success? (quantitative metrics)
- What does "done" look like?
- What would make this a complete success vs. partial success?

**Example metrics:**
- Performance: "Reduce page load time to under 2 seconds"
- Adoption: "10% of users adopt new feature within first month"
- Quality: "Zero critical security vulnerabilities"
- Completion: "All authentication flows support SSO"

### 3. Scope and Constraints

Define boundaries and limitations:

**Questions to ask:**
- What's explicitly in scope for this initiative?
- What's explicitly out of scope?
- Are there any technical constraints? (performance, compatibility, security)
- Are there any resource constraints? (timeline, team size, budget)
- Are there any regulatory or compliance requirements?

**Present multiple choice when helpful:**
Example: "Does this need to be backwards compatible?"
- A) Full backwards compatibility required
- B) Breaking changes acceptable with migration path
- C) Complete rewrite, no compatibility needed

### 4. Dependencies and Blockers

Identify what must happen first:

**Questions to ask:**
- Does this depend on any other work being completed first?
- Are there any known blockers or risks?
- Do we need input or approval from other teams?
- Are there any external dependencies? (third-party APIs, infrastructure)

**Check GitHub for dependencies:**
- Search for related open issues
- Check for recent architectural decisions
- Look for ongoing work that might conflict

### 5. Timeline and Milestones

Estimate effort and plan phases:

**Questions to ask:**
- What's the target completion date?
- Are there any intermediate milestones or checkpoints?
- Can this be broken into phases?
- What's the minimum viable scope for a first release?

**Suggest milestone structure:**
Example for a 3-month initiative:
- Phase 1 (Week 1-2): Design and planning
- Phase 2 (Week 3-8): Core implementation
- Phase 3 (Week 9-10): Testing and refinement
- Phase 4 (Week 11-12): Documentation and rollout

### 6. Complexity Assessment

Determine if visual planning is needed:

**Assess complexity based on:**
- Multiple repositories involved?
- New architecture or abstractions required?
- UI/UX design needed?
- Complex data flows or integrations?
- Multiple teams coordinating?

**If complex (any of above):**
> "This initiative involves [complexity factors]. Would you like me to create a visual PRD with architecture diagrams and UI mockups? This will help communicate the plan to stakeholders and ensure alignment before implementation."
>
> Options:
> - A) Yes, create comprehensive visual PRD
> - B) Just architecture diagrams, no UI mockups
> - C) Skip visual PRD, proceed with text description

**If they choose A or B:** Invoke the `visual-prd` skill with gathered context

### 7. Generate Initiative Description

Create comprehensive GitHub initiative description:

**Structure:**

```markdown
# [Initiative Title]

## Overview
[2-3 sentence summary of what this initiative aims to achieve]

## Problem Statement
[What problem are we solving? Why does this matter?]

## Goals
- [Primary goal 1]
- [Primary goal 2]
- [Primary goal 3]

## Success Metrics
- [Metric 1]: [Target]
- [Metric 2]: [Target]
- [Metric 3]: [Target]

## Scope

### In Scope
- [What we will do]
- [What we will deliver]

### Out of Scope
- [What we won't do]
- [What we're explicitly deferring]

## Technical Approach
[High-level overview of how we'll implement this]
[Link to visual PRD if created]

## Dependencies
- [Dependency 1] - [Status]
- [Dependency 2] - [Status]

## Constraints
- [Technical constraint 1]
- [Resource constraint 2]
- [Timeline constraint 3]

## Timeline
- **Target Start:** [Date]
- **Target Completion:** [Date]

### Milestones
- [ ] Phase 1: [Name] - [Target Date]
- [ ] Phase 2: [Name] - [Target Date]
- [ ] Phase 3: [Name] - [Target Date]

## Repositories Affected
- `owner/repo1` - [What will change]
- `owner/repo2` - [What will change]

## Stakeholders
- **Owner:** @username
- **Contributors:** @user1, @user2
- **Reviewers:** @reviewer1

## Related Work
- Related to #issue-number
- Depends on #issue-number
- Blocks #issue-number

## Risk Assessment
- **[Risk 1]**: [Mitigation strategy]
- **[Risk 2]**: [Mitigation strategy]

## Questions and Unknowns
- [Open question 1]
- [Open question 2]

---
Created with 🤖 [claude-grimoire](https://github.com/martythewizard/claude-grimoire)
```

### 8. Review and Refine

Present the generated description to the user:

> "Here's the initiative description I've generated. Please review each section:
>
> [Show description section by section]
>
> Does this accurately capture your intent? Any sections need adjustment?"

**Be ready to iterate:**
- Adjust scope based on feedback
- Refine success metrics
- Add missing dependencies
- Clarify technical approach

### 9. Create GitHub Initiative

Once the user approves the description:

```bash
# Create the initiative
gh issue create \
  --title "[Initiative Title]" \
  --body "$(cat initiative-description.md)" \
  --label "initiative,planning" \
  --assignee @me
```

**Apply appropriate labels:**
- `initiative` (required)
- `planning` (for initiatives in planning phase)
- `enhancement` (for new features)
- `refactor` (for architectural improvements)
- `infrastructure` (for platform/tooling work)
- Custom labels based on repository conventions

**Set milestone if applicable:**
```bash
gh issue edit [number] --milestone "Q2 2026"
```

### 10. Link Related Work

Connect to existing issues and PRs:

```bash
# Link dependencies
gh issue comment [initiative-number] --body "Depends on #123"

# Link related work
gh issue comment [initiative-number] --body "Related to #456"
```

### 11. Report Completion

Provide the user with:
- Initiative URL
- Summary of what was created
- Next steps suggestion

**Example:**
> ✅ **Initiative created successfully!**
>
> **URL:** https://github.com/owner/repo/issues/123
> **Title:** Add JWT-based authentication system
> **Labels:** initiative, planning, enhancement, security
> **Milestone:** Q2 2026
>
> **What's next?**
> 1. Review and refine the initiative description
> 2. Use `/initiative-breakdown` to create actionable tasks
> 3. Optionally create visual PRD if not done yet
> 4. Share with stakeholders for feedback

## Configuration

The skill respects configuration from `.claude-grimoire/config.json`:

```json
{
  "github": {
    "org": "your-org",
    "defaultRepos": ["repo1", "repo2"]
  },
  "initiativeCreator": {
    "defaultLabels": ["initiative", "planning"],
    "requireSuccessMetrics": true,
    "requireTimeline": true,
    "autoCreateVisualPRD": false
  }
}
```

## Tips for Great Initiatives

**Be specific about success:**
- ❌ "Improve performance"
- ✅ "Reduce page load time from 5s to under 2s"

**Define clear boundaries:**
- ❌ "Build authentication"
- ✅ "Add JWT-based session management for web app. OAuth integration deferred to Phase 2."

**Include actual dates:**
- ❌ "Next quarter"
- ✅ "Target completion: June 30, 2026"

**Quantify when possible:**
- ❌ "Support more users"
- ✅ "Scale to 100k daily active users (up from 10k)"

**Be honest about unknowns:**
- List questions you don't have answers to yet
- Identify areas needing research or spikes
- Call out assumptions that need validation

## Integration with Other Skills

**Before initiative-creator:**
- None required (this is typically the starting point)

**After initiative-creator:**
- `/initiative-breakdown` - Break initiative into actionable tasks
- `/visual-prd` - Create visual requirements (if not done during creation)
- `feature-delivery-team` - Execute the complete delivery workflow

**Can invoke during creation:**
- `visual-prd` skill - For complex initiatives needing visual planning
- `github-context-agent` - To fetch related issue/PR context

## Examples

### Example 1: Simple Feature Initiative

**User:** "I need to add dark mode to our app"

**Skill response:**
> What problem are you trying to solve with dark mode?

**User:** "Users complain about eye strain when using the app at night"

**Skill response:**
> Who are the primary users affected by this?

**User:** "All mobile app users, particularly those using the app in the evening"

**Skill continues interview...**

**Result:** Initiative created with clear scope (theme toggle + system preference detection), success metrics (adoption rate, user satisfaction), 2-week timeline

---

### Example 2: Complex Multi-Repo Initiative

**User:** "We need to add SSO authentication across all our services"

**Skill response:**
> What repositories will be involved?

**User:** "Web app, mobile app, admin dashboard, and API gateway"

**Skill response:**
> This initiative spans multiple repositories and involves authentication architecture. Would you like me to create a visual PRD with architecture diagrams? This will help align stakeholders on the approach.

**User:** "Yes, architecture diagrams would be helpful"

**Skill response:** 
> *[Invokes visual-prd skill to create diagrams]*
> 
> I've created a visual PRD with the SSO architecture. Let me now create the initiative...

**Result:** Initiative with linked visual PRD, phased rollout plan (API gateway first, then services), clear dependencies between repos

---

### Example 3: Infrastructure Initiative

**User:** "We need to migrate from Postgres to Aurora"

**Skill response:**
> What's driving this migration?

**User:** "Need better scaling and automatic failover for production"

**Skill response:**
> What constraints do we have? Does this need zero-downtime migration?

**User:** "Yes, we can't have any downtime. We process payments 24/7"

**Skill continues assessing risks and dependencies...**

**Result:** Initiative with phased migration plan, rollback procedures, success metrics (migration time, downtime = 0), comprehensive risk assessment

## Error Handling

**If GitHub API fails:**
- Save generated description to local file
- Provide manual creation instructions
- Offer to retry when API is available

**If user provides insufficient information:**
- Continue asking clarifying questions
- Don't generate initiative until you have enough context
- It's better to ask too many questions than create a vague initiative

**If initiative already exists:**
- Ask if they want to update existing or create new
- Show existing initiative for reference
- Suggest using `/initiative-breakdown` instead if scope is defined

## Common Pitfalls to Avoid

❌ **Creating initiatives too large:** If the scope spans more than 3 months or 10+ issues, suggest breaking into multiple initiatives

❌ **Vague success metrics:** Push for quantifiable targets, not subjective goals

❌ **Missing dependencies:** Always check for related work that must happen first

❌ **Skipping the visual PRD:** For complex initiatives, always offer to create diagrams

❌ **No timeline:** Every initiative needs target dates, even if they're estimates

❌ **Forgetting stakeholders:** Always identify who owns, contributes, and reviews

## Success Criteria

This skill is successful when:
- ✅ Initiative clearly communicates scope and goals
- ✅ Stakeholders understand what will be delivered
- ✅ Success can be measured objectively
- ✅ Dependencies and risks are identified upfront
- ✅ Timeline is realistic and has buy-in
- ✅ Follow-up work (`initiative-breakdown`) can proceed smoothly