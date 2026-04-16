# Discovery Results: 2026-q1-ai-cost-intelligence-platform.yaml

Initiative has GitHub Project eci-global#14. Found 3 untracked issues.

## High Confidence (8-10)

### #234: Implement cost anomaly alerting
**Repo:** eci-global/one-cloud-cloud-costs  
**Milestone:** M1 — Eyes Open: Automated Detection  
**Score:** 9/10  
**Reasoning:** In GitHub Project #14, assigned to milestone M1, matches initiative tags (cost-optimization, ai). Not tracked in any JIRA epic task.

**Add to YAML:**
```yaml
jira:
  epics:
    - key: ITPLAT01-2258  # M1 epic
      milestone: "M1 — Eyes Open: Automated Detection"
      tasks:
        - key: ITPLAT01-2262  # Create this JIRA task
          github_issue: 234
          status: Backlog
```

### #235: Add Coralogix integration for alerts
**Repo:** eci-global/one-cloud-cloud-costs  
**Milestone:** M2 — Learning Normal  
**Score:** 8/10  
**Reasoning:** In GitHub Project #14, milestone M2, mentions Coralogix (related system).

**Add to YAML:**
```yaml
jira:
  epics:
    - key: ITPLAT01-2259  # M2 epic
      milestone: "M2 — Learning Normal: Baseline Intelligence"
      tasks:
        - key: ITPLAT01-2263  # Create this JIRA task
          github_issue: 235
          status: Backlog
```

## Medium Confidence (5-7)

### #240: Improve data pipeline performance
**Repo:** eci-global/one-cloud-cloud-costs  
**Milestone:** none  
**Score:** 6/10  
**Reasoning:** Open issue in workstream repo, mentions data pipeline (matches workstream "S3 Data Lake"), but no milestone assigned.

**Suggested action:**
1. Review issue to confirm relevance
2. Assign to appropriate milestone (M0 or M5?)
3. Add to GitHub Project eci-global#14 if relevant
4. Create JIRA task and add github_issue reference

---

## Already Tracked

- 12 issues tracked in JIRA epic tasks
- GitHub Project eci-global#14 configured

## JIRA Discovery (Optional)

JIRA project ITPLAT01 is configured. To search for untracked JIRA epics:
1. Run JIRA epic discovery separately (out of scope for schema v2)
2. Or continue using GitHub-first workflow

## Action Items
1. Review high-confidence GitHub issue suggestions
2. Create corresponding JIRA tasks if tracking there
3. Add github_issue references to JIRA epic tasks in YAML
4. Re-run /initiative-validator after updating YAML
