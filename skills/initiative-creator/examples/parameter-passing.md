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
