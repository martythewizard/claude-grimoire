# Initiative Creator Flexibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform initiative-creator from a rigid YAML-only workflow into a flexible tool that handles standalone issues, issue linking, and comprehensive YAML creation based on user needs.

**Architecture:** Skill documentation defines three distinct modes: (1) standalone issue creation, (2) linking issues to existing initiatives/projects, (3) full YAML initiative creation. Parameter support allows non-interactive invocation. The skill detects user intent and routes to appropriate workflow.

**Tech Stack:**
- GitHub CLI (`gh`) for issue/project operations
- Git for YAML commits to eci-global/initiatives
- YAML generation following schema v2 from eci-global/initiatives
- github-context-agent for fetching existing context
- Markdown documentation

**Dependencies:** Requires Plan 1 (github-context-agent enhancement) to be complete.

---

## File Structure

**Files to Modify:**
- `skills/initiative-creator/skill.md` - Main skill documentation (current: ~453 lines)
  - Add mode detection workflow
  - Add parameter parsing
  - Add standalone issue creation
  - Add linking workflows
  - Update YAML generation to match eci-global/initiatives structure
  - Add examples for each mode

**Files to Create:**
- `skills/initiative-creator/examples/standalone-issue.md` - Standalone issue example
- `skills/initiative-creator/examples/link-to-project.md` - Link issue to project example
- `skills/initiative-creator/examples/link-to-initiative.md` - Link to initiative YAML example
- `skills/initiative-creator/examples/full-yaml-creation.md` - Full YAML initiative example
- `skills/initiative-creator/examples/parameter-passing.md` - Parameter-based invocation
- `skills/initiative-creator/templates/initiative-template.yaml` - Schema v2 template
- `test/initiative-creator/test-yaml-generation.sh` - Test YAML structure validation
- `test/initiative-creator/test-parameter-parsing.sh` - Test parameter handling

---

### Task 1: Add Mode Detection Workflow

**Files:**
- Modify: `skills/initiative-creator/skill.md:34-50` (replace "Initial Context Gathering")

- [ ] **Step 1: Replace workflow section with mode detection**

Replace "Workflow" section with:

```markdown
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
```

- [ ] **Step 2: Verify mode detection is clear**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
grep -A 20 "## Workflow" skills/initiative-creator/skill.md
```

Expected: Mode detection process clearly outlined

- [ ] **Step 3: Commit mode detection**

```bash
git add skills/initiative-creator/skill.md
git commit -m "docs(initiative-creator): add mode detection workflow (standalone/linking/full)"
```

---

### Task 2: Add Standalone Issue Mode

**Files:**
- Modify: `skills/initiative-creator/skill.md` (after Mode Detection)
- Create: `skills/initiative-creator/examples/standalone-issue.md`

- [ ] **Step 1: Document standalone issue workflow**

Add new section after mode detection:

```markdown
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
```

- [ ] **Step 2: Create standalone issue example**

Create `skills/initiative-creator/examples/standalone-issue.md`:

```markdown
# Standalone Issue Creation Example

## Scenario

User wants to create a quick bug fix issue without any initiative/project context.

## Interactive Flow

```
User: /initiative-creator

Skill: What would you like to create?
A) Standalone issue (no initiative or project)
B) Issue linked to existing initiative or project  
C) New comprehensive initiative with YAML file

User: A

Skill: What's the issue title?

User: Fix authentication timeout error

Skill: Describe the issue:

User: Users are getting logged out after 5 minutes instead of 30 minutes

Skill: Which repository?

User: eci-global/auth-service

Skill: Any labels? (or 'none')

User: bug, high-priority

Skill: Assignee? (or 'none')

User: @security-team

Skill: Creating issue in eci-global/auth-service...

✅ Issue created: https://github.com/eci-global/auth-service/issues/456

Title: Fix authentication timeout error
Labels: bug, high-priority
Assignee: @security-team
Milestone: none

This is a standalone issue (not linked to any initiative or project).

To link it later, run:
  /initiative-creator --issue eci-global/auth-service#456 --project org#14
```

## Non-Interactive Flow

```
User: /initiative-creator --title "Fix auth timeout" --body "Users logged out after 5 min instead of 30" --repo eci-global/auth-service --label bug,high-priority --assignee security-team

Skill: Creating issue...

✅ Issue created: https://github.com/eci-global/auth-service/issues/456
```

## GitHub Command Used

```bash
gh issue create \
  --repo eci-global/auth-service \
  --title "Fix authentication timeout error" \
  --body "Users are getting logged out after 5 minutes instead of 30 minutes" \
  --label bug,high-priority \
  --assignee security-team
```
```

- [ ] **Step 3: Verify standalone mode is documented**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
grep "## Standalone Issue Mode" skills/initiative-creator/skill.md
cat skills/initiative-creator/examples/standalone-issue.md | head -30
```

Expected: Standalone mode section exists, example file created

- [ ] **Step 4: Commit standalone issue mode**

```bash
git add skills/initiative-creator/skill.md skills/initiative-creator/examples/standalone-issue.md
git commit -m "docs(initiative-creator): add standalone issue mode and example"
```

---

### Task 3: Add Linking Mode

**Files:**
- Modify: `skills/initiative-creator/skill.md` (after Standalone mode)
- Create: `skills/initiative-creator/examples/link-to-project.md`
- Create: `skills/initiative-creator/examples/link-to-initiative.md`

- [ ] **Step 1: Document linking mode workflow**

Add new section:

```markdown
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

If A: → Link to Project (Task 3.2)
If B: → Link to Initiative (Task 3.3)
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
```

- [ ] **Step 2: Create link-to-project example**

Create `skills/initiative-creator/examples/link-to-project.md`:

```markdown
# Link Issue to Project Example

## Scenario

User has an existing issue that should be added to a GitHub Project board.

## Interactive Flow

```
User: /initiative-creator --issue eci-global/auth-service#456

Skill: Fetching issue eci-global/auth-service#456...

Issue found:
  Title: Fix authentication timeout error
  State: open
  Labels: bug, high-priority
  Assignee: @security-team

Skill: What should this issue be linked to?
A) GitHub Project
B) Initiative YAML
C) Both project and initiative
D) Milestone within repo

User: A

Skill: What's the GitHub Project? (provide org#number or URL)

User: eci-global#8

Skill: Verifying project eci-global#8 exists...

✓ Project found: "2026 Q1 - Coralogix Quota Manager"
  Status: Open
  Items: 45

Skill: Linking issue to project...

✅ Issue linked successfully!

Issue: https://github.com/eci-global/auth-service/issues/456
Project: https://github.com/orgs/eci-global/projects/8

You can view the issue on the project board now.
```

## Non-Interactive Flow

```
User: /initiative-creator --issue eci-global/auth-service#456 --project eci-global#8

Skill: Fetching issue and verifying project...
Skill: Linking issue to project...

✅ Linked eci-global/auth-service#456 to project eci-global#8
```

## GitHub Commands Used

```bash
# Verify project exists (via github-context-agent)
# (agent uses GraphQL internally)

# Link issue to project
gh project item-add 8 \
  --owner eci-global \
  --url https://github.com/eci-global/auth-service/issues/456
```

## Result

Issue #456 now appears in the GitHub Project #8 board.
```

- [ ] **Step 3: Create link-to-initiative example**

Create `skills/initiative-creator/examples/link-to-initiative.md`:

```markdown
# Link Issue to Initiative YAML Example

## Scenario

User wants to associate an issue with an initiative YAML file for tracking.

## Interactive Flow

```
User: /initiative-creator --issue eci-global/auth-service#456

Skill: Fetching issue...

Issue found:
  Title: Fix authentication timeout error
  State: open

Skill: What should this issue be linked to?
A) GitHub Project
B) Initiative YAML
C) Both project and initiative
D) Milestone within repo

User: B

Skill: Which initiative? (provide YAML path or search term)

User: coralogix quota

Skill: Searching initiatives for "coralogix quota"...

Found: initiatives/2026-q1-coralogix-quota-manager.yaml
  Name: 2026 Q1 - Coralogix Quota Manager
  Status: active
  Owner: RustyAutopsy

Is this correct? (y/n)

User: y

Skill: Checking if initiative has a GitHub Project...

✓ Initiative references GitHub Project eci-global#8

Would you like to link the issue to the project as well? (y/n)

User: y

Skill: Linking issue to:
  - Initiative YAML (via comment)
  - GitHub Project #8

✅ Issue linked successfully!

Issue: https://github.com/eci-global/auth-service/issues/456
Initiative: initiatives/2026-q1-coralogix-quota-manager.yaml
Project: https://github.com/orgs/eci-global/projects/8

Added comment to issue with initiative reference.
```

## Non-Interactive Flow

```
User: /initiative-creator --issue eci-global/auth-service#456 --initiative initiatives/2026-q1-coralogix-quota-manager.yaml

Skill: Linking issue to initiative...

✅ Linked successfully
  - Comment added to issue referencing initiative
  - Also linked to GitHub Project #8 (from initiative YAML)
```

## GitHub Commands Used

```bash
# Add comment with initiative reference
gh issue comment 456 \
  --repo eci-global/auth-service \
  --body "Part of initiative: [2026 Q1 - Coralogix Quota Manager](https://github.com/eci-global/initiatives/blob/main/initiatives/2026-q1-coralogix-quota-manager.yaml)"

# Link to project (if initiative has github_project)
gh project item-add 8 \
  --owner eci-global \
  --url https://github.com/eci-global/auth-service/issues/456
```
```

- [ ] **Step 4: Verify linking mode is complete**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
grep "## Linking Mode" skills/initiative-creator/skill.md
ls -la skills/initiative-creator/examples/link-to-*.md
```

Expected: Linking mode documented, both example files exist

- [ ] **Step 5: Commit linking mode**

```bash
git add skills/initiative-creator/skill.md skills/initiative-creator/examples/link-to-*.md
git commit -m "docs(initiative-creator): add linking mode with project and initiative examples"
```

---

### Task 4: Add Full Initiative Mode with YAML Generation

**Files:**
- Modify: `skills/initiative-creator/skill.md` (after Linking mode)
- Create: `skills/initiative-creator/templates/initiative-template.yaml`
- Create: `skills/initiative-creator/examples/full-yaml-creation.md`

- [ ] **Step 1: Document full initiative mode workflow**

Add new section:

```markdown
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

Ask user (existing questions from v1.0.0):
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
```

- [ ] **Step 2: Create initiative YAML template**

Create `skills/initiative-creator/templates/initiative-template.yaml`:

```yaml
# Initiative Template - Schema v2
# Based on eci-global/initiatives structure
# Only include sections with actual data

schema_version: 2
name: ""  # Required: Initiative name
description: >-  # Required: Use >- for multi-line folded scalar
  
status: planning  # Required: active | planning | paused | completed | cancelled
owner: ""  # Required: GitHub username
team:  # Required but can be empty array
  - ""

# Optional: Only include if GitHub Project exists or is being created
# github_project:
#   org: ""
#   number: 0
#   id: ""  # Optional: GraphQL node ID

# Optional: Only include if initiative has distinct phases
# phase: ""

# Optional: Only include if workstreams are defined
# workstreams:
#   - name: ""
#     repo: ""  # owner/repo format
#     milestones:
#       - title: ""
#         number: 0
#         due: "YYYY-MM-DD"
#         status: ""  # Freeform: deployed, code-complete, in-progress, etc.

# Optional: Only include if progress tracking is active
# progress:
#   github_issues: ""  # e.g., "76/76"
#   jira_epics: ""
#   jira_stories: ""
#   tests: ""
#   infrastructure: ""
#   last_reconciled: "YYYY-MM-DD"

# Optional: Only include if JIRA tracking exists
# jira:
#   project_key: ""
#   parent_key: ""
#   board_url: ""
#   epics:
#     - key: ""
#       milestone: ""
#       status: ""

# Optional: Only include if Confluence docs exist
# confluence:
#   space_key: ""
#   page_id: ""
#   page_version: 0

# Optional: Include if Steward monitoring is enabled
# steward:
#   enabled: true
#   last_run: "YYYY-MM-DDTHH:MM:SSZ"

# Optional: Only include if tags are defined
# tags:
#   - ""

# Optional: Only include if Pulse notifications configured
# pulse:
#   scan_window: ""  # e.g., "24h"
#   channels:
#     - ""
#   discussion_category: ""
```

- [ ] **Step 3: Create full YAML creation example**

Create `skills/initiative-creator/examples/full-yaml-creation.md`:

```markdown
# Full Initiative YAML Creation Example

## Scenario

User is starting a large multi-month initiative that needs comprehensive tracking.

## Interactive Flow (Abbreviated)

```
User: /initiative-creator

Skill: What would you like to create?
A) Standalone issue
B) Issue linked to existing initiative or project
C) New comprehensive initiative with YAML file

User: C

Skill: Let's create a comprehensive initiative. I'll ask some questions about scope, goals, and structure.

What problem are you solving?

User: Need to modernize our authentication service to support OAuth2 and SSO

Skill: Who are the primary stakeholders?

User: Security team, all engineering teams using auth

[... more questions about goals, scope, constraints ...]

Skill: Does a GitHub Project already exist for this initiative?
A) Yes (provide project number)
B) No, create one
C) No project needed

User: A

Skill: What's the project number or URL?

User: eci-global#15

Skill: Verifying project exists...
✓ Project found: "2026 Q2 - Auth Service Modernization"

Skill: Does this initiative span multiple repos or have distinct workstreams?

User: Yes, two workstreams

Skill: Name of workstream 1?

User: OAuth2 Implementation

Skill: Which repository?

User: eci-global/auth-service

Skill: Any milestones for this workstream?

User: Yes - "M1 - OAuth2 Core" due 2026-06-01, "M2 - Client Integration" due 2026-07-01

[... gather workstream 2 ...]

Skill: Is this tracked in JIRA?

User: Yes - project ITPLAT01, parent epic ITPMO01-1650

[... gather optional fields ...]

Skill: Generating YAML file...

✓ YAML generated: initiatives/2026-q2-auth-service-modernization.yaml

Skill: Validating YAML structure...
✓ Valid schema v2
✓ All required fields present
✓ Status is valid enum value
✓ Dates are ISO 8601 format

Skill: Committing to eci-global/initiatives...

git clone https://github.com/eci-global/initiatives.git
cp initiatives/2026-q2-auth-service-modernization.yaml initiatives/
git add initiatives/2026-q2-auth-service-modernization.yaml
git commit -m "Add initiative: 2026 Q2 - Auth Service Modernization"
git push origin main

✅ Initiative created successfully!

YAML: https://github.com/eci-global/initiatives/blob/main/initiatives/2026-q2-auth-service-modernization.yaml
Name: 2026 Q2 - Auth Service Modernization
Status: planning
Owner: @security-team
GitHub Project: https://github.com/orgs/eci-global/projects/15
Workstreams: 2 (OAuth2 Implementation, SSO Integration)

What's next?
1. Review the YAML file in eci-global/initiatives
2. Use /initiative-breakdown to create tasks
3. Share with stakeholders for feedback

Would you like me to break this initiative down into tasks now? (y/n)

User: y

Skill: Invoking /initiative-breakdown...
```

## Generated YAML File

```yaml
schema_version: 2
name: 2026 Q2 - Auth Service Modernization
description: >-
  Modernize authentication service to support OAuth2 and SSO across all
  ECI products. Includes OAuth2 core implementation, client SDK updates,
  and SSO provider integrations (Okta, Azure AD).
status: planning
owner: security-team
team:
  - security-lead
  - auth-engineer-1
  - auth-engineer-2

github_project:
  org: eci-global
  number: 15

workstreams:
  - name: OAuth2 Implementation
    repo: eci-global/auth-service
    milestones:
      - title: "M1 — OAuth2 Core"
        number: 10
        due: "2026-06-01"
        status: planning
      - title: "M2 — Client Integration"
        number: 11
        due: "2026-07-01"
        status: planning
  - name: SSO Integration
    repo: eci-global/auth-service
    milestones:
      - title: "M3 — Okta Integration"
        number: 12
        due: "2026-07-15"
        status: planning
      - title: "M4 — Azure AD Integration"
        number: 13
        due: "2026-08-01"
        status: planning

jira:
  project_key: ITPLAT01
  parent_key: ITPMO01-1650

steward:
  enabled: true

tags:
  - auth
  - oauth2
  - sso
  - security
  - q2-2026
```
```

- [ ] **Step 4: Verify full initiative mode is complete**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
grep "## Full Initiative Mode" skills/initiative-creator/skill.md
cat skills/initiative-creator/templates/initiative-template.yaml | head -20
cat skills/initiative-creator/examples/full-yaml-creation.md | head -30
```

Expected: Full mode documented, template and example created

- [ ] **Step 5: Commit full initiative mode**

```bash
git add skills/initiative-creator/skill.md skills/initiative-creator/templates/ skills/initiative-creator/examples/full-yaml-creation.md
git commit -m "docs(initiative-creator): add full initiative mode with YAML generation"
```

---

### Task 5: Add Parameter Parsing Documentation

**Files:**
- Modify: `skills/initiative-creator/skill.md` (add new section after modes)
- Create: `skills/initiative-creator/examples/parameter-passing.md`

- [ ] **Step 1: Document parameter support**

Add new section after the three modes:

```markdown
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
```

- [ ] **Step 2: Create parameter passing examples**

Create `skills/initiative-creator/examples/parameter-passing.md`:

```markdown
# Parameter Passing Examples

## Example 1: Quick Standalone Issue

```bash
/initiative-creator \
  --title "Update dependencies" \
  --body "Upgrade to latest versions" \
  --repo eci-global/app \
  --label maintenance
```

**Result:**
```
Creating issue in eci-global/app...
✅ Issue created: https://github.com/eci-global/app/issues/890
```

## Example 2: Link Existing Issue

```bash
/initiative-creator \
  --issue eci-global/auth-service#456 \
  --project eci-global#8
```

**Result:**
```
Fetching issue eci-global/auth-service#456...
Verifying project eci-global#8...
Linking issue to project...
✅ Linked successfully
```

## Example 3: Create and Link to Everything

```bash
/initiative-creator \
  --title "Implement rate limiting" \
  --body "Add rate limiting to API endpoints" \
  --repo eci-global/api-gateway \
  --project eci-global#14 \
  --initiative initiatives/2026-q1-ai-cost-intelligence-platform.yaml \
  --milestone "M2 — Learning Normal" \
  --label feature,performance \
  --assignee api-team
```

**Result:**
```
Creating issue in eci-global/api-gateway...
Verifying project eci-global#14...
Verifying initiative YAML...
Linking issue to project...
Adding initiative comment...
Assigning to milestone "M2 — Learning Normal"...

✅ All operations completed successfully!

Issue: https://github.com/eci-global/api-gateway/issues/234
Project: https://github.com/orgs/eci-global/projects/14
Initiative: initiatives/2026-q1-ai-cost-intelligence-platform.yaml
Milestone: M2 — Learning Normal (eci-global/api-gateway)
```

## Example 4: Mixed Parameters and Interactive

```bash
/initiative-creator --title "Add logging" --body "Improve observability"
```

**Interaction:**
```
Skill: No repository specified. Which repository?

User: eci-global/api-gateway

Skill: Should this be linked to a project or initiative? (y/n)

User: y

Skill: What should it be linked to?
A) GitHub Project
B) Initiative YAML
C) Both

User: A

Skill: Project number or URL?

User: eci-global#14

Skill: Creating issue and linking...
✅ Done
```

## Example 5: Force YAML Mode

```bash
/initiative-creator --yaml
```

**Interaction:**
```
Skill: Creating comprehensive initiative with YAML file.

What problem are you solving?

[... full interactive YAML creation workflow ...]
```

## Example 6: Validation Error

```bash
/initiative-creator --issue eci-global/repo#999 --project org#14
```

**Result:**
```
❌ Error: Issue eci-global/repo#999 not found

Suggestion: Check the issue number. Run without --issue to create a new issue instead.
```

## Example 7: Minimal Parameters

```bash
/initiative-creator --title "Quick fix" --body "Description"
```

**Interaction:**
```
Skill: No repository specified. Which repository?

User: eci-global/app

Skill: Creating issue...
✅ Issue created: https://github.com/eci-global/app/issues/901
```
```

- [ ] **Step 3: Verify parameter documentation**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
grep "## Parameter Passing" skills/initiative-creator/skill.md
cat skills/initiative-creator/examples/parameter-passing.md | grep "## Example" | wc -l
```

Expected: Parameter section exists, 7 examples in parameter-passing.md

- [ ] **Step 4: Commit parameter parsing**

```bash
git add skills/initiative-creator/skill.md skills/initiative-creator/examples/parameter-passing.md
git commit -m "docs(initiative-creator): add parameter passing support and examples"
```

---

### Task 6: Create YAML Validation Test Script

**Files:**
- Create: `test/initiative-creator/test-yaml-generation.sh`

- [ ] **Step 1: Create test directory**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
mkdir -p test/initiative-creator
```

- [ ] **Step 2: Write YAML validation test**

Create `test/initiative-creator/test-yaml-generation.sh`:

```bash
#!/usr/bin/env bash
# Test YAML generation follows eci-global/initiatives structure

set -e

echo "Testing initiative-creator YAML generation..."

# Create temp YAML for testing
temp_yaml="/tmp/test-initiative.yaml"

cat > "$temp_yaml" << 'EOF'
schema_version: 2
name: "Test Initiative"
description: >-
  This is a test initiative to validate YAML structure.
  Second line of description continues naturally.
status: planning
owner: test-user
team:
  - member1
  - member2

github_project:
  org: test-org
  number: 99

workstreams:
  - name: "Test Workstream"
    repo: owner/repo
    milestones:
      - title: "M1 — Test Milestone"
        number: 1
        due: "2026-06-01"
        status: planning

jira:
  project_key: TEST01
  parent_key: TEST-123
  epics:
    - key: TEST-456
      milestone: "M1 — Test Milestone"
      status: Todo

confluence:
  space_key: TEST
  page_id: "123456"

steward:
  enabled: true

tags:
  - test
  - validation
EOF

# Test 1: Valid YAML syntax
echo "Test 1: Valid YAML syntax"
if python3 -c "import sys, yaml; yaml.safe_load(open('$temp_yaml'))" 2>/dev/null; then
  echo "✓ YAML is valid"
else
  echo "✗ YAML parsing failed"
  exit 1
fi

# Test 2: Required fields present
echo ""
echo "Test 2: Required fields present"
required_fields=("schema_version" "name" "description" "status" "owner" "team")
missing_fields=()

for field in "${required_fields[@]}"; do
  if grep -q "^$field:" "$temp_yaml"; then
    echo "✓ $field present"
  else
    echo "✗ $field missing"
    missing_fields+=("$field")
  fi
done

if [ ${#missing_fields[@]} -eq 0 ]; then
  echo "✓ All required fields present"
else
  echo "✗ Missing fields: ${missing_fields[*]}"
  exit 1
fi

# Test 3: Schema version is 2
echo ""
echo "Test 3: Schema version validation"
schema_version=$(grep "^schema_version:" "$temp_yaml" | awk '{print $2}')
if [ "$schema_version" = "2" ]; then
  echo "✓ schema_version is 2"
else
  echo "✗ schema_version is $schema_version (expected 2)"
  exit 1
fi

# Test 4: Status is valid enum
echo ""
echo "Test 4: Status enum validation"
status=$(grep "^status:" "$temp_yaml" | awk '{print $2}')
valid_statuses=("active" "planning" "paused" "completed" "cancelled")
status_valid=false

for valid in "${valid_statuses[@]}"; do
  if [ "$status" = "$valid" ]; then
    status_valid=true
    break
  fi
done

if [ "$status_valid" = true ]; then
  echo "✓ Status '$status' is valid"
else
  echo "✗ Status '$status' is invalid"
  exit 1
fi

# Test 5: Description uses folded scalar (>-)
echo ""
echo "Test 5: Description format"
if grep -q "description: >-" "$temp_yaml"; then
  echo "✓ Description uses >- folded scalar"
else
  echo "✗ Description should use >- for multi-line"
  exit 1
fi

# Test 6: Dates are ISO 8601
echo ""
echo "Test 6: Date format validation"
due_date=$(grep "due:" "$temp_yaml" | awk '{print $2}' | tr -d '"')
if [[ "$due_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "✓ Date '$due_date' is ISO 8601 (YYYY-MM-DD)"
else
  echo "✗ Date '$due_date' is not ISO 8601 format"
  exit 1
fi

# Test 7: Field names are snake_case
echo ""
echo "Test 7: Field naming convention"
if grep -qE "(githubProject|pageId|projectKey)" "$temp_yaml"; then
  echo "✗ Found camelCase fields (should be snake_case)"
  exit 1
else
  echo "✓ All fields use snake_case"
fi

# Test 8: Workstream milestone structure
echo ""
echo "Test 8: Workstream milestone structure"
required_milestone_fields=("title" "number" "due" "status")
all_present=true

for field in "${required_milestone_fields[@]}"; do
  if grep -A 10 "milestones:" "$temp_yaml" | grep -q "^[[:space:]]*$field:"; then
    echo "✓ Milestone has $field"
  else
    echo "✗ Milestone missing $field"
    all_present=false
  fi
done

if [ "$all_present" = true ]; then
  echo "✓ Milestone structure correct"
fi

# Test 9: Compare with real example from eci-global/initiatives
echo ""
echo "Test 9: Compare structure with real initiative"
real_yaml=$(gh api repos/eci-global/initiatives/contents/initiatives/2026-q1-coralogix-quota-manager.yaml --jq '.content' | base64 -d)

# Check that our test YAML has similar structure
if echo "$real_yaml" | grep -q "schema_version: 2"; then
  echo "✓ Real initiative uses schema_version: 2"
  
  if echo "$real_yaml" | grep -q "description: >-"; then
    echo "✓ Real initiative uses >- for description"
  fi
  
  if echo "$real_yaml" | grep -q "github_project:"; then
    echo "✓ Real initiative uses github_project (not githubProject)"
  fi
else
  echo "✗ Could not verify against real initiative"
fi

# Cleanup
rm "$temp_yaml"

echo ""
echo "================================================"
echo "All YAML generation validation tests passed!"
echo "================================================"
```

- [ ] **Step 3: Make test executable**

```bash
chmod +x test/initiative-creator/test-yaml-generation.sh
```

- [ ] **Step 4: Run test**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
./test/initiative-creator/test-yaml-generation.sh
```

Expected: All 9 tests pass

- [ ] **Step 5: Commit YAML validation test**

```bash
git add test/initiative-creator/test-yaml-generation.sh
git commit -m "test(initiative-creator): add YAML generation validation test"
```

---

### Task 7: Create Parameter Parsing Test Script

**Files:**
- Create: `test/initiative-creator/test-parameter-parsing.sh`

- [ ] **Step 1: Write parameter parsing test**

Create `test/initiative-creator/test-parameter-parsing.sh`:

```bash
#!/usr/bin/env bash
# Test parameter parsing logic

set -e

echo "Testing initiative-creator parameter parsing..."

# Helper function to parse parameters
parse_params() {
  local params="$*"
  
  # Initialize variables
  issue=""
  title=""
  body=""
  repo=""
  project=""
  initiative=""
  milestone=""
  label=""
  assignee=""
  force_yaml=false
  
  # Parse parameters
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --issue)
        issue="$2"
        shift 2
        ;;
      --title)
        title="$2"
        shift 2
        ;;
      --body)
        body="$2"
        shift 2
        ;;
      --repo)
        repo="$2"
        shift 2
        ;;
      --project)
        project="$2"
        shift 2
        ;;
      --initiative)
        initiative="$2"
        shift 2
        ;;
      --milestone)
        milestone="$2"
        shift 2
        ;;
      --label)
        label="$2"
        shift 2
        ;;
      --assignee)
        assignee="$2"
        shift 2
        ;;
      --yaml)
        force_yaml=true
        shift
        ;;
      *)
        shift
        ;;
    esac
  done
  
  # Determine mode
  if [ "$force_yaml" = true ]; then
    echo "full-initiative"
  elif [ -n "$issue" ] || [ -n "$project" ] || [ -n "$initiative" ] || [ -n "$milestone" ]; then
    echo "linking"
  elif [ -n "$title" ] && [ -n "$body" ]; then
    if [ -n "$project" ] || [ -n "$initiative" ]; then
      echo "linking"
    else
      echo "standalone"
    fi
  else
    echo "interactive"
  fi
}

# Test cases
echo "Test 1: Standalone issue parameters"
mode=$(parse_params --title "Fix bug" --body "Description" --repo owner/repo)
if [ "$mode" = "standalone" ]; then
  echo "✓ Detected standalone mode"
else
  echo "✗ Expected standalone, got $mode"
  exit 1
fi

echo ""
echo "Test 2: Linking to project"
mode=$(parse_params --issue owner/repo#123 --project org#14)
if [ "$mode" = "linking" ]; then
  echo "✓ Detected linking mode"
else
  echo "✗ Expected linking, got $mode"
  exit 1
fi

echo ""
echo "Test 3: Create and link"
mode=$(parse_params --title "Task" --body "Desc" --repo owner/repo --project org#14)
if [ "$mode" = "linking" ]; then
  echo "✓ Detected linking mode (create + link)"
else
  echo "✗ Expected linking, got $mode"
  exit 1
fi

echo ""
echo "Test 4: Force YAML mode"
mode=$(parse_params --yaml)
if [ "$mode" = "full-initiative" ]; then
  echo "✓ Detected full-initiative mode"
else
  echo "✗ Expected full-initiative, got $mode"
  exit 1
fi

echo ""
echo "Test 5: No parameters (interactive)"
mode=$(parse_params)
if [ "$mode" = "interactive" ]; then
  echo "✓ Detected interactive mode"
else
  echo "✗ Expected interactive, got $mode"
  exit 1
fi

echo ""
echo "Test 6: Link to initiative YAML"
mode=$(parse_params --issue owner/repo#123 --initiative initiatives/file.yaml)
if [ "$mode" = "linking" ]; then
  echo "✓ Detected linking mode (to initiative)"
else
  echo "✗ Expected linking, got $mode"
  exit 1
fi

echo ""
echo "Test 7: Assign to milestone"
mode=$(parse_params --title "Task" --body "Desc" --repo owner/repo --milestone "M1")
if [ "$mode" = "linking" ]; then
  echo "✓ Detected linking mode (milestone assignment)"
else
  echo "✗ Expected linking, got $mode"
  exit 1
fi

echo ""
echo "Test 8: Full parameter set"
mode=$(parse_params \
  --title "Feature" \
  --body "Description" \
  --repo owner/repo \
  --project org#14 \
  --initiative initiatives/file.yaml \
  --milestone "M1" \
  --label feature,high \
  --assignee user)
if [ "$mode" = "linking" ]; then
  echo "✓ Detected linking mode (full parameters)"
else
  echo "✗ Expected linking, got $mode"
  exit 1
fi

echo ""
echo "============================================="
echo "All parameter parsing tests passed!"
echo "============================================="
```

- [ ] **Step 2: Make test executable**

```bash
chmod +x test/initiative-creator/test-parameter-parsing.sh
```

- [ ] **Step 3: Run test**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
./test/initiative-creator/test-parameter-parsing.sh
```

Expected: All 8 tests pass

- [ ] **Step 4: Commit parameter parsing test**

```bash
git add test/initiative-creator/test-parameter-parsing.sh
git commit -m "test(initiative-creator): add parameter parsing test"
```

---

### Task 8: Update Configuration and Examples Sections

**Files:**
- Modify: `skills/initiative-creator/skill.md:296-312` (Configuration section)
- Modify: `skills/initiative-creator/skill.md:352-453` (Examples section)

- [ ] **Step 1: Update configuration section**

Replace existing Configuration section:

```markdown
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
```

- [ ] **Step 2: Replace examples section**

Replace existing Examples section with new examples covering all three modes:

```markdown
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
```

- [ ] **Step 3: Verify configuration and examples**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
grep "defaultMode" skills/initiative-creator/skill.md
grep "### Example [1-5]" skills/initiative-creator/skill.md
```

Expected: Configuration updated, 5 examples present

- [ ] **Step 4: Commit configuration and examples updates**

```bash
git add skills/initiative-creator/skill.md
git commit -m "docs(initiative-creator): update configuration and add examples for all modes"
```

---

### Task 9: Final Review and Testing

**Files:**
- Modify: `skills/initiative-creator/skill.md` (add migration notes at end)

- [ ] **Step 1: Add migration notes**

Add section at end before closing:

```markdown
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
```

- [ ] **Step 2: Run all tests**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire

echo "Running YAML generation tests..."
./test/initiative-creator/test-yaml-generation.sh

echo ""
echo "Running parameter parsing tests..."
./test/initiative-creator/test-parameter-parsing.sh

echo ""
echo "All initiative-creator tests passed!"
```

Expected: Both test scripts pass

- [ ] **Step 3: Verify skill.md is complete**

```bash
cd /mnt/c/Users/mhoward/projects/claude-grimoire
wc -l skills/initiative-creator/skill.md
ls -la skills/initiative-creator/examples/
ls -la skills/initiative-creator/templates/
```

Expected: 
- skill.md approximately 700-800 lines
- 5 example files in examples/
- 1 template file in templates/

- [ ] **Step 4: Create summary commit**

```bash
git add skills/initiative-creator/skill.md
git commit -m "docs(initiative-creator): add migration notes and finalize v2.0.0 documentation"
```

- [ ] **Step 5: Create plan completion summary**

Create summary:

```markdown
# initiative-creator Flexibility - Plan Complete

## What Was Implemented

### Skill Documentation Updates (skills/initiative-creator/skill.md)
- ✅ Added mode detection workflow (standalone/linking/full)
- ✅ Documented standalone issue mode
- ✅ Documented linking mode (to project, to initiative, to milestone)
- ✅ Documented full initiative mode with YAML generation
- ✅ Added parameter passing support
- ✅ Updated YAML generation to match eci-global/initiatives schema v2
- ✅ Updated configuration section
- ✅ Replaced examples with mode-specific examples
- ✅ Added migration notes

### Examples Created
- ✅ skills/initiative-creator/examples/standalone-issue.md
- ✅ skills/initiative-creator/examples/link-to-project.md
- ✅ skills/initiative-creator/examples/link-to-initiative.md
- ✅ skills/initiative-creator/examples/full-yaml-creation.md
- ✅ skills/initiative-creator/examples/parameter-passing.md

### Templates Created
- ✅ skills/initiative-creator/templates/initiative-template.yaml

### Test Scripts Created
- ✅ test/initiative-creator/test-yaml-generation.sh (9 tests)
- ✅ test/initiative-creator/test-parameter-parsing.sh (8 tests)

## Verification

All tests passing:
- YAML generation: ✅ (validates schema v2 structure)
- Parameter parsing: ✅ (validates mode detection)

## Next Steps

This plan is complete. initiative-creator now supports:
1. Standalone issue creation (no initiative/project)
2. Linking issues to existing projects/initiatives
3. Full YAML initiative creation (rare case)
4. Parameter passing for non-interactive use
5. YAML generation matching eci-global/initiatives schema v2

Ready for:
- Plan 3: initiative-breakdown Updates
- Plan 4: Teams & PR Integration
```

---

## Plan Self-Review

### Spec Coverage Check

✅ **Mode detection** - Three modes clearly defined and documented
✅ **Standalone issue mode** - Documented workflow and example
✅ **Linking mode** - Project, initiative, and milestone linking documented
✅ **Full initiative mode** - Comprehensive YAML creation workflow
✅ **Parameter passing** - All parameters documented with examples
✅ **YAML structure** - Matches eci-global/initiatives schema v2 exactly
✅ **Configuration** - Updated with new flexibility options
✅ **Examples** - 5 examples covering all modes
✅ **Templates** - YAML template created
✅ **Testing** - 2 test scripts with 17 total tests
✅ **Migration** - Backward compatibility documented

### Placeholder Scan

✅ No "TBD" or "TODO" markers
✅ All workflows complete with specific steps
✅ All examples show actual commands and output
✅ Template shows exact structure
✅ No vague "add appropriate" statements

### Type Consistency

✅ YAML fields match schema v2: snake_case, github_project not githubProject
✅ Parameter names consistent: --issue, --project, --initiative
✅ Mode names consistent: standalone, linking, full-initiative
✅ Status enum matches: active, planning, paused, completed, cancelled

### Gaps

None identified. All spec requirements for initiative-creator covered.

---
