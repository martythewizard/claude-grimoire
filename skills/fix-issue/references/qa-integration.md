# QA Integration for Fix-Issue

Full steps for headless browser QA verification using `playwright-cli`. Referenced from SKILL.md Phase 1.5 (bug reproduction) and Phase 5.5 (fix verification).

## Prerequisites

Read from CONFIG.md before starting:
- `{QA_TOOL}` — must be `playwright-cli`
- `{DEV_COMMAND}` — e.g., `npm run dev`
- `{DEV_PORT}` — e.g., `3000`
- `{TEST_USER_EMAIL}` — dedicated QA test user email
- `{TEST_USER_PASSWORD}` — test user password
- Auth provider type (e.g., `supabase`, `firebase`, `auth0`)

Also read the GitHub issue body (`{issue-number}`) for:
- Reproduction steps — what the user did to trigger the bug
- Expected behavior — what should happen (also found in `context.json` as `generatedSpec.acceptanceCriteria`)
- Screenshots or error messages the user attached

## Step 1: Start Dev Server

```bash
lsof -ti:{DEV_PORT} || ({DEV_COMMAND} &)
```

Wait up to 30s for the server to be ready. Set `WE_STARTED_SERVER=true` if you started it.

Confirm it is up:
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:{DEV_PORT}
```

Expected: `200` or `301`. Anything else — wait 5s and retry up to 3 times.

## Step 2: Provision Test User

Follow the steps in `skills/playwright-qa-cli/references/provision.md` for your auth provider.

Key outcomes:
- Test user exists in the auth provider
- All required profile/onboarding records exist
- Usage/credits reset to known state
- Email verification metadata set

## Step 3: Open Browser and Login

```bash
export PATH="$HOME/.npm-global/bin:$PATH" && playwright-cli goto "http://localhost:{DEV_PORT}"
export PATH="$HOME/.npm-global/bin:$PATH" && playwright-cli eval "() => new Promise(r => setTimeout(r, 2000))"
export PATH="$HOME/.npm-global/bin:$PATH" && playwright-cli snapshot
export PATH="$HOME/.npm-global/bin:$PATH" && playwright-cli screenshot --filename=playwright-qa-screenshots/{issue-number}-verify/01-login-page.png
```

Fill login form:
```bash
export PATH="$HOME/.npm-global/bin:$PATH" && playwright-cli fill {email-ref} "{TEST_USER_EMAIL}"
export PATH="$HOME/.npm-global/bin:$PATH" && playwright-cli fill {password-ref} "{TEST_USER_PASSWORD}"
export PATH="$HOME/.npm-global/bin:$PATH" && playwright-cli click {submit-ref}
```

Wait for auth redirect (auth redirects involve server round-trips):
```bash
export PATH="$HOME/.npm-global/bin:$PATH" && playwright-cli eval "() => new Promise(r => setTimeout(r, 3000))"
export PATH="$HOME/.npm-global/bin:$PATH" && playwright-cli snapshot
export PATH="$HOME/.npm-global/bin:$PATH" && playwright-cli screenshot --filename=playwright-qa-screenshots/{issue-number}-verify/02-after-login.png
```

Confirm you are logged in (no login form visible, dashboard or app content shown).

## Step 4: Navigate to Affected Page

Navigate to the page described in the GitHub issue body. If the issue body names a specific route or feature, go there directly:

```bash
export PATH="$HOME/.npm-global/bin:$PATH" && playwright-cli goto "http://localhost:{DEV_PORT}/{affected-path}"
export PATH="$HOME/.npm-global/bin:$PATH" && playwright-cli eval "() => new Promise(r => setTimeout(r, 2000))"
export PATH="$HOME/.npm-global/bin:$PATH" && playwright-cli snapshot
export PATH="$HOME/.npm-global/bin:$PATH" && playwright-cli screenshot --filename=playwright-qa-screenshots/{issue-number}-verify/03-affected-page.png
```

## Step 5: Reproduce the Bug (Phase 1.5) / Verify the Fix (Phase 5.5)

Follow the reproduction steps from the GitHub issue body. For each step:

```bash
# Example: click a button
export PATH="$HOME/.npm-global/bin:$PATH" && playwright-cli click {action-ref}
export PATH="$HOME/.npm-global/bin:$PATH" && playwright-cli eval "() => new Promise(r => setTimeout(r, 1000))"
export PATH="$HOME/.npm-global/bin:$PATH" && playwright-cli snapshot
export PATH="$HOME/.npm-global/bin:$PATH" && playwright-cli screenshot --filename=playwright-qa-screenshots/{issue-number}-verify/NN-step.png
```

After all steps, check for errors:
```bash
export PATH="$HOME/.npm-global/bin:$PATH" && playwright-cli console error
```

### Verdicts

**Phase 1.5 (Bug Reproduction)**

| Verdict | Criteria | Action |
|---------|----------|--------|
| Bug confirmed | Observed behavior matches issue description | Show screenshots, continue to Phase 2 |
| Not reproducible | Issue steps complete without error | Show screenshots, ask user whether to continue |
| Different behavior | Something fails, but not what the issue describes | Report actual behavior, ask user how to proceed |

**Phase 5.5 (Fix Verification)**

| Verdict | Criteria | Action |
|---------|----------|--------|
| Fix verified | Bug no longer occurs; issue's expected behavior now works | Show before/after screenshots, proceed to Phase 6 |
| Fix incomplete | Bug still occurs or only partially resolved | Report what still fails → loop back to Phase 4 (max 1 retry) |
| Regression found | New unexpected behavior introduced by the fix | Report the regression → loop back to Phase 4 |

## Step 6: Cleanup

After Phase 5.5 (or after Phase 1.5 if skipping QA check):

```bash
# Kill dev server if you started it
if [ "$WE_STARTED_SERVER" = "true" ]; then
  kill $(lsof -ti:{DEV_PORT}) 2>/dev/null || true
fi
```

Clean up test user data if needed (reset to known state for next run):
- Re-run the reset SQL from `skills/playwright-qa-cli/references/provision.md` → "If User EXISTS → Reset Data"

## Screenshot Naming Convention

| Screenshot | Filename |
|------------|----------|
| Login page | `{issue-number}-verify/01-login-page.png` |
| After login | `{issue-number}-verify/02-after-login.png` |
| Affected page | `{issue-number}-verify/03-affected-page.png` |
| Reproduction step N | `{issue-number}-verify/NN-step.png` |
| Fix verification step N | `{issue-number}-fix-check/NN-step.png` |

## Error Handling

| Scenario | Action |
|----------|--------|
| QA tool not found | Warn user, skip QA phases (1.5 and 5.5), continue pipeline |
| Dev server won't start | Warn user, skip QA phases, continue pipeline |
| Auth fails | Retry with alternative method (max 2 attempts); if still failing, check test user provisioning |
| Login redirect fails | Check `playwright-cli console error` — likely a middleware or auth config issue |
| Browser crash | Kill all browser instances (`pkill -f playwright-cli`), retry once from Step 3 |
| Page not found (404) | Verify the route from the GitHub issue body — ask user for correct URL if unclear |
| Console errors found | Note them in Phase 9 summary — may indicate related issues beyond the current fix |
