# Project Configuration

Copy this file to `CONFIG.md` and fill in your project-specific values.
**Do NOT commit CONFIG.md** — it may contain sensitive information.

---

## GitHub

| Setting | Value | Notes |
|---------|-------|-------|
| Repository | `owner/repo` | GitHub repo in owner/repo format (e.g., `acme/my-app`) |

### Labels

| Label | Default Value | Notes |
|-------|--------------|-------|
| In Progress | `in-progress` | Applied when work starts |
| In Review | `in-review` | Applied when review has open findings |
| QA Ready | `qa-ready` | Applied when fix is ready for QA |
| Done | `done` | Applied when issue is fully closed |

### Team

| Name | GitHub Username | Alias |
|------|----------------|-------|
| Jane Doe | `jane-doe` | `jane` |

To find a GitHub username: github.com/{username} or `gh api users/{name} --jq '.login'`.

### Milestones

| Setting | Value | Notes |
|---------|-------|-------|
| Default milestone | *(leave blank)* | Optional — milestone number to auto-assign when fixing an issue (e.g., `3`). Leave blank if not using milestones. |

Milestones are auto-populated from `.gh-issue/context.json` when gh-issue is run before fix-issue.
To find a milestone number: `gh api repos/{owner}/{repo}/milestones --jq '.[] | [.number, .title] | @tsv'`

### Project Board (Optional)

Leave blank if not using GitHub Projects.

| Setting | Value | Notes |
|---------|-------|-------|
| Project number | `5` | GitHub Projects board number (`gh project list`) |
| Status field ID | `PVTF_...` | Get via `gh project field-list {number} --owner {owner}` |
| QA column option ID | `...` | Get via `gh project field-list {number} --owner {owner} --format json` |

## Deployment

| Setting | Value | Notes |
|---------|-------|-------|
| Platform | `vercel` | Currently supported: `vercel`. Set to `none` to skip deployment monitoring. |
| Production URL | `https://yourapp.com` | Used for "test in prod" QA mode |

### Vercel (if applicable)

Read from `.vercel/project.json` automatically. No config needed here unless the file doesn't exist.

## QA Testing (Optional)

These settings are only needed if you want headless browser QA verification.

| Setting | Value | Notes |
|---------|-------|-------|
| QA tool | `playwright-cli` | CLI tool for headless browser testing |
| Dev server command | `npm run dev` | Command to start local dev server |
| Dev server port | `3000` | Port the dev server runs on |
| Test user email | `qa-test@yourapp.test` | Dedicated QA test user |
| Test user password | `YourSecurePassword` | Test user password |

### Auth Provider

| Setting | Value | Notes |
|---------|-------|-------|
| Provider | `supabase` | Auth provider: `supabase`, `firebase`, `auth0`, `custom` |
| Supabase project ID | `your-project-id` | Only if using Supabase |

### Test Data Schema

If your QA tests need to seed test data, document your table schemas here:

```sql
-- Example: seed a test record
INSERT INTO public.your_table (id, user_id, created_at, name)
VALUES (gen_random_uuid(), '{USER_ID}', now(), 'Test Record');
```

### Route Detection

Map file paths to routes for QA navigation:

| File Pattern | Route |
|-------------|-------|
| `dashboard/**` | `/dashboard` |
| `settings/**` | `/settings` |
| Default | `/` |

## Complex Fix Delegation (Optional)

| Setting | Value | Notes |
|---------|-------|-------|
| Delegation skill | `/develop-team` | Skill to invoke for complex (3+ file) fixes. Set to `none` to handle all fixes inline. |
