---
name: initiative-creator
description: Create well-structured GitHub initiatives through guided workflow
version: 2.0.0
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
- Standalone Issue Mode (see below)
- Linking Mode (see below)
- Full Initiative Mode (see below)

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

## Linking Mode

Create or link an issue to an existing initiative (YAML) or project.

### When to Use

- Issue is part of tracked initiative
- Issue belongs in existing GitHub Project
- Want to associate standalone issue with initiative
- Organizing work across repos/milestones

### Workflow

**Step 1: Get or Create Issue**

```
If --issue provided:
  Fetch existing issue via github-context-agent
  
If --title/--body provided:
  Create new issue (same as standalone mode)
  
If nothing provided:
  Ask user: "Should I use an existing issue or create a new one?"
  A) Use existing (ask for issue number)
  B) Create new (gather title/body/repo)
```

**Step 2: Ask What to Link To**

```
Ask user: "What should this issue be linked to?"

A) GitHub Project (provide org#number or URL)
B) Initiative YAML (provide path or name)
C) Both project and initiative
D) Milestone within repo

If A: → Link to Project
If B: → Link to Initiative
If C: → Link to both
If D: → Assign to milestone
```

**Step 3: Verify Target Exists**

Use github-context-agent to verify:
- Project exists and is open
- Initiative YAML exists
- Milestone exists in repo

**Step 4: Perform Linking**

Based on target type:

**Link to Project:**
```bash
# Get project ID if needed
gh project item-add <project-number> \
  --owner <org> \
  --url https://github.com/<owner>/<repo>/issues/<number>
```

**Link to Initiative:**
```bash
# Add comment to issue referencing YAML
gh issue comment <number> \
  --repo <owner>/<repo> \
  --body "Part of initiative: [2026 Q1 - AI Cost Intelligence](https://github.com/eci-global/initiatives/blob/main/initiatives/2026-q1-ai-cost-intelligence-platform.yaml)"
```

**Assign to Milestone:**
```bash
gh issue edit <number> \
  --repo <owner>/<repo> \
  --milestone "<milestone-title>"
```

**Step 5: Report Completion**

```
✅ Issue linked successfully!

Issue: https://github.com/<owner>/<repo>/issues/<number>
Linked to: GitHub Project #14 (2026 Q1 - AI Cost Intelligence Platform)
Initiative: initiatives/2026-q1-ai-cost-intelligence-platform.yaml
Milestone: M1 — Eyes Open: Automated Detection

The issue is now tracked in the project and associated with the initiative.
```

### Parameter Examples

```bash
# Link existing issue to project
/initiative-creator --issue eci-global/repo#123 --project eci-global#14

# Create issue and link to project
/initiative-creator --title "New task" --body "Description" --repo owner/repo --project org#14

# Link to initiative YAML
/initiative-creator --issue owner/repo#123 --initiative initiatives/2026-q1-ai-cost.yaml

# Link to both project and milestone
/initiative-creator --issue owner/repo#123 --project org#14 --milestone "M1 - Foundation"

# Create and link everything
/initiative-creator \
  --title "Implement feature" \
  --body "Description" \
  --repo owner/repo \
  --project org#14 \
  --initiative initiatives/file.yaml \
  --milestone "M2 - Implementation"
```

## Full Initiative Mode

Create comprehensive initiative with YAML file in eci-global/initiatives repo.

### When to Use

- Large multi-week/multi-month initiatives
- Cross-repository coordination needed
- Need JIRA/Confluence integration
- Want to track progress metrics
- Multiple workstreams and milestones

**This is the RARE case** - most work uses Standalone or Linking modes.

### Workflow

**Step 1: Gather Initiative Metadata**

Ask user:
- What problem are you solving?
- Who are the stakeholders?
- What are the goals and success metrics?
- What's in scope / out of scope?
- Dependencies and blockers?
- Timeline and target completion?

**Step 2: Ask About GitHub Project**

```
Does a GitHub Project already exist for this initiative?

A) Yes (provide project number or URL)
B) No, create one (rare - only if truly needed)
C) No project needed

If A:
  Get project org and number
  Verify project exists via github-context-agent
  Include in YAML: github_project.org and github_project.number
  
If B:
  Ask: "What should the project be named?"
  Create project: gh project create --owner <org> --title "<name>"
  Get new project number
  Include in YAML
  
If C:
  Skip github_project section in YAML
```

**Default assumption: Projects already exist (option A)**

**Step 3: Ask About Workstreams**

```
Does this initiative span multiple repos or have distinct workstreams?

If yes:
  For each workstream:
    - Name
    - Repository (owner/repo)
    - Milestones (titles, due dates, status)
    
If no:
  Skip workstreams section
```

**Step 4: Ask About Optional Integrations**

```
One question at a time:

1. "Is this tracked in JIRA?"
   If yes: Collect project_key, parent_key, epic keys
   
2. "Is there Confluence documentation?"
   If yes: Collect space_key, page_id
   
3. "What tags apply to this initiative?"
   Collect array of tags (lowercase, kebab-case)
   
4. "Should Steward monitoring be enabled?"
   Default: yes (enabled: true)
   
5. "Should Pulse notifications be configured?"
   If yes: Collect scan_window, channels, discussion_category
```

**Step 5: Generate YAML File**

**CRITICAL: Follow eci-global/initiatives structure exactly**

```yaml
schema_version: 2
name: "<Initiative Name>"
description: >-
  <Multi-line description using folded scalar.
  Second line continues naturally.>
status: planning  # One of: active, planning, paused, completed, cancelled
owner: <github-username>
team:
  - <member1>
  - <member2>

# Only include github_project if project exists or was created
github_project:
  org: <org-name>
  number: <number>

# Only include workstreams if provided
workstreams:
  - name: "<Workstream Name>"
    repo: <owner>/<repo>
    milestones:
      - title: "<Milestone Title>"
        number: <number>
        due: "YYYY-MM-DD"
        status: <freeform-status>

# Only include jira if provided
jira:
  project_key: <KEY>
  parent_key: <PARENT-KEY>
  epics:
    - key: <EPIC-KEY>
      milestone: "<Milestone Title>"
      status: <Status>

# Only include confluence if provided
confluence:
  space_key: <SPACE>
  page_id: "<page-id>"

# Only include steward if enabled
steward:
  enabled: true

# Only include tags if provided
tags:
  - <tag1>
  - <tag2>

# Only include pulse if configured
pulse:
  scan_window: <window>
  channels:
    - <channel1>
  discussion_category: "<category>"
```

**YAML Generation Rules:**
1. Use `>-` for multi-line descriptions (folded scalar)
2. ISO 8601 dates: `YYYY-MM-DD` for dates, `YYYY-MM-DDTHH:MM:SSZ` for timestamps
3. Status must be one of enum: active, planning, paused, completed, cancelled
4. Only include sections with actual data (no empty arrays/objects)
5. Quote strings with special characters (milestone titles with "—", etc.)
6. Match field names exactly from schema v2 (snake_case)

**File naming:** `initiatives/YYYY-QQ-<kebab-case-name>.yaml`
Example: `initiatives/2026-q1-auth-service-modernization.yaml`

**Step 6: Validate YAML**

Before committing:
```bash
# Check YAML is valid
cat initiatives/<file>.yaml | python3 -c "import sys, yaml; yaml.safe_load(sys.stdin)"

# Verify required fields
grep "schema_version: 2" initiatives/<file>.yaml
grep "^name:" initiatives/<file>.yaml
grep "^status:" initiatives/<file>.yaml
grep "^owner:" initiatives/<file>.yaml
```

**Step 7: Commit to eci-global/initiatives**

```bash
cd /tmp
git clone https://github.com/eci-global/initiatives.git
cd initiatives
cp /path/to/initiatives/<file>.yaml initiatives/
git add initiatives/<file>.yaml
git commit -m "Add initiative: <name>"
git push origin main
```

**Step 8: Create Initial Issues (Optional)**

```
Ask user: "Would you like me to break this initiative down into tasks now?"

If yes: Invoke /initiative-breakdown with YAML path
If no: Provide next steps
```

**Step 9: Report Completion**

```
✅ Initiative created successfully!

YAML: https://github.com/eci-global/initiatives/blob/main/initiatives/<file>.yaml
Name: <Initiative Name>
Status: planning
Owner: @<username>
GitHub Project: https://github.com/orgs/<org>/projects/<number> (if exists)

What's next?
1. Review the YAML file in eci-global/initiatives
2. Use /initiative-breakdown to create tasks
3. Share with stakeholders for feedback
```

### Parameter Example

```bash
# Force full YAML creation
/initiative-creator --yaml

# Will prompt for all initiative details
# Then generate YAML and commit to eci-global/initiatives
```

## Parameter Passing

The skill supports parameters for non-interactive invocation.

### Supported Parameters

**Issue parameters:**
- `--issue <owner>/<repo>#<number>` - Use existing issue
- `--title "<title>"` - Issue title (required if creating)
- `--body "<body>"` - Issue description (required if creating)
- `--repo <owner>/<repo>` - Target repository (required if creating without context)

**Linking parameters:**
- `--project <org>#<number>` or `--project <url>` - Link to GitHub Project
- `--initiative <path>` - Link to initiative YAML
- `--milestone "<title>"` - Assign to milestone

**Issue metadata:**
- `--label <label1>,<label2>` - Comma-separated labels
- `--assignee <username>` - Issue assignee

**Mode control:**
- `--yaml` - Force Full Initiative Mode (interactive YAML creation)

### Parameter Examples

**Standalone issue:**
```bash
/initiative-creator --title "Fix bug" --body "Description" --repo owner/repo
```

**Link existing issue to project:**
```bash
/initiative-creator --issue owner/repo#123 --project org#14
```

**Create and link to everything:**
```bash
/initiative-creator \
  --title "New feature" \
  --body "Description" \
  --repo owner/repo \
  --project org#14 \
  --initiative initiatives/file.yaml \
  --milestone "M1 - Foundation" \
  --label feature,high-priority \
  --assignee username
```

**Force YAML creation:**
```bash
/initiative-creator --yaml
# Will prompt for initiative details interactively
```

### Parameter Priority

If both parameters and interactive mode are mixed:
1. Parameters override interactive questions
2. Missing parameters trigger interactive prompts for those fields only
3. `--yaml` flag forces Full Initiative Mode regardless of other parameters

### Validation

Parameters are validated before execution:
- Issue number must exist if `--issue` provided
- Project must exist if `--project` provided
- Initiative YAML must exist if `--initiative` provided
- Repository must be accessible if `--repo` provided
- Milestone must exist in repo if `--milestone` provided

Validation failures return clear error messages with suggestions.

## Configuration

The skill respects configuration from `.claude-grimoire/config.json`:

```json
{
  "github": {
    "org": "your-org",
    "defaultRepos": ["repo1", "repo2"],
    "initiativesRepo": "eci-global/initiatives",
    "initiativesPath": "initiatives/",
    "defaultOrg": "eci-global"
  },
  "initiativeCreator": {
    "templatePath": ".claude-grimoire/templates/initiative.yaml",
    "defaultMode": "issue",
    "assumeProjectExists": true,
    "promptForOptionalFields": true,
    "allowParameters": true,
    "autoCreateVisualPRD": false,
    "defaultLabels": [],
    "requireConfirmation": false
  }
}
```

**Configuration fields:**

- `defaultMode` - Default mode when no parameters: "issue" | "linking" | "full"
  - Recommended: "issue" (start simple)
- `assumeProjectExists` - Ask to link existing project before creating new
  - Recommended: true (projects rarely need creation)
- `promptForOptionalFields` - Ask about JIRA/Confluence/tags in full mode
  - Recommended: true
- `allowParameters` - Enable parameter passing
  - Recommended: true
- `autoCreateVisualPRD` - Automatically invoke visual-prd for complex initiatives
  - Default: false (ask user)
- `templatePath` - Path to initiative YAML template
  - Default: uses skills/initiative-creator/templates/initiative-template.yaml
- `requireConfirmation` - Ask before committing YAML
  - Default: false (commit automatically after validation)

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

### Example 1: Standalone Issue (Quick Bug Fix)

**User:** "Create an issue for fixing the login timeout"

**Skill:**
```
What would you like to create?
A) Standalone issue
B) Issue linked to existing initiative or project
C) New comprehensive initiative with YAML file

User: A

Title?
> Fix login timeout error

Description?
> Users are being logged out after 5 minutes instead of 30

Repository?
> eci-global/auth-service

Labels?
> bug, high-priority

Creating issue...
✅ Issue created: https://github.com/eci-global/auth-service/issues/456
```

**Result:** Standalone issue created in < 1 minute

---

### Example 2: Link Existing Issue to Project

**User:** "/initiative-creator --issue eci-global/repo#123 --project eci-global#14"

**Skill:**
```
Fetching issue eci-global/repo#123...
Verifying project eci-global#14...
Linking issue to project...
✅ Linked successfully
```

**Result:** Issue #123 now appears in Project #14

---

### Example 3: Create Issue and Link to Initiative

**User:** "Create a task for implementing rate limiting and add it to the cost intelligence initiative"

**Skill:**
```
What would you like to create?
A) Standalone issue
B) Issue linked to existing initiative or project
C) New comprehensive initiative with YAML file

User: B

Create new issue or use existing?
A) Create new
B) Use existing

User: A

Title?
> Implement rate limiting for API endpoints

Description?
> Add rate limiting to prevent cost overruns from runaway processes

Repository?
> eci-global/api-gateway

What should this be linked to?
A) GitHub Project
B) Initiative YAML
C) Both

User: C

Initiative YAML path or search term?
> ai cost intelligence

Searching initiatives...
Found: initiatives/2026-q1-ai-cost-intelligence-platform.yaml
  Name: 2026 Q1 - AI Cost Intelligence Platform
  Status: active
  Project: eci-global#14

✓ Initiative has GitHub Project #14

Creating issue...
Linking to project...
Adding initiative comment...

✅ Issue created and linked!

Issue: https://github.com/eci-global/api-gateway/issues/234
Project: https://github.com/orgs/eci-global/projects/14
Initiative: initiatives/2026-q1-ai-cost-intelligence-platform.yaml
```

**Result:** Issue created and linked to both project and initiative

---

### Example 4: Full Initiative Creation (Rare)

**User:** "I need to create a comprehensive initiative for modernizing our authentication service"

**Skill:**
```
What would you like to create?
A) Standalone issue
B) Issue linked to existing initiative or project
C) New comprehensive initiative with YAML file

User: C

Let's create a comprehensive initiative. I'll ask about scope, goals, and structure.

What problem are you solving?
> Need to support OAuth2 and SSO across all products

[... detailed interview process ...]

Does a GitHub Project already exist?
A) Yes
B) No, create one
C) No project needed

User: A

Project number?
> eci-global#15

Does this initiative have workstreams?
> Yes, two workstreams

[... gather workstream details ...]

Generating YAML file...
Validating structure...
Committing to eci-global/initiatives...

✅ Initiative created!

YAML: initiatives/2026-q2-auth-service-modernization.yaml
Project: https://github.com/orgs/eci-global/projects/15
Workstreams: 2

Would you like me to break this down into tasks now?
> Yes

Invoking /initiative-breakdown...
```

**Result:** Full initiative YAML created, committed, ready for breakdown

---

### Example 5: Parameter-Based Non-Interactive

**User:** "/initiative-creator --title 'Update docs' --body 'Add API documentation' --repo eci-global/api --project eci-global#14 --label documentation"

**Skill:**
```
Creating issue in eci-global/api...
Linking to project eci-global#14...
✅ Done: https://github.com/eci-global/api/issues/567
```

**Result:** Issue created and linked in single command, no prompts

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

## Migration from v1.0.0

Version 2.0.0 adds flexibility while maintaining backward compatibility.

### What Changed

**New in v2.0.0:**
- Three modes: standalone issue, linking, full initiative
- Parameter passing for non-interactive use
- Linking to existing projects/initiatives (no longer creates by default)
- YAML generation follows eci-global/initiatives schema v2 exactly

**Still works (v1.0.0 behavior):**
- Interactive initiative creation workflow
- Visual PRD integration
- All existing questions and prompts

### Breaking Changes

**None.** All v1.0.0 workflows continue to work.

**Default behavior change:** Skill now asks mode first ("What would you like to create?") instead of assuming full initiative creation. This is more flexible but requires one additional question.

To force v1.0.0 behavior (skip mode selection):
```bash
/initiative-creator --yaml
```

### Migration Path

**For skills invoking initiative-creator:**

No changes required. Existing invocations work as before.

**For users:**

Old way (v1.0.0): Always creates comprehensive initiative with YAML
New way (v2.0.0): Choose mode based on need (most work is standalone/linking)

**Recommended usage:**
- 90% of time: Standalone or Linking mode
- 10% of time: Full Initiative mode (for large initiatives)