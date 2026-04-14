---
name: incident-response-team
description: End-to-end incident response from alert to documentation with automated context gathering and quality gates
version: 1.0.0
author: claude-grimoire
team_type: orchestration
requires:
  - incident-context-agent
  - documentation-agent
optional:
  - staff-developer
  - staff-engineer
  - two-claude-review
  - firehydrant
  - coralogix
---

# Incident Response Team

Multi-agent orchestration team that manages complete incident response from initial alert through diagnosis, fix implementation, verification, and post-mortem documentation. Minimizes MTTR with automated context gathering and quality gates.

## Purpose

Streamline incident response to resolve incidents faster and learn from them:
- Automated context gathering (logs, metrics, deployments)
- Guided root cause analysis
- Fix implementation with quality gates
- Automated post-mortem generation
- Knowledge base building

## When to Use

- Responding to production incidents (P0-P2)
- Investigating Firehydrant alerts
- Troubleshooting service degradation
- Post-incident documentation
- Learning from outages

## Team Members

### Agents
- `incident-context-agent` - Gather context from multiple sources
- `documentation-agent` - Generate post-mortems

### Skills (Optional)
- `staff-developer` - Implement code fixes
- `staff-engineer` - Review fixes
- `two-claude-review` - Review complex fix plans

## Workflow

### Phase 1: Incident Triage & Context Gathering

**Goal:** Understand the incident and gather comprehensive context

**Input:** Firehydrant incident URL or alert description

**Process:**

1. **Identify incident:**
   ```
   Ask user: "What incident are we responding to?"
   
   Options:
   A) Firehydrant incident URL (e.g., https://app.firehydrant.io/incidents/abc123)
   B) Alert description (I'll create Firehydrant incident)
   C) Known issue (provide details)
   ```

2. **Extract incident details:**
   ```
   If Firehydrant URL:
     incident_id = extract_from_url(url)  # abc123
   
   If alert description:
     Ask: "What service is affected?"
     Ask: "What are the symptoms?"
     Ask: "When did it start?"
     
     Optionally create Firehydrant incident
   ```

3. **Determine timeframe:**
   ```
   Calculate investigation window:
   - Start: incident_start - 1 hour (capture leading indicators)
   - End: now (ongoing) or incident_end (resolved)
   
   Default to 1 hour window for context gathering
   ```

4. **Invoke incident-context-agent:**
   ```json
   {
     "incident_id": "abc123",
     "timeframe": "1h",
     "services": ["api-gateway", "user-service"],
     "gather": {
       "logs": true,
       "metrics": true,
       "traces": true,
       "deployments": true,
       "config_changes": true
     }
   }
   ```

5. **Present initial assessment:**
   ```markdown
   ## 🔥 Incident Overview
   
   **Incident:** FH-abc123
   **Severity:** P1 (Critical)
   **Started:** 2026-04-13 14:30 UTC (15 minutes ago)
   **Affected:** api-gateway, user-service
   
   ## 📊 Symptoms
   
   - **Error rate:** 0.5% → 15% (30x spike)
   - **Response time:** 200ms → 5s p95 (25x slower)
   - **User reports:** 47 complaints in last 10 min
   
   ## 📈 Recent Changes
   
   - ⚠️  **10 min before incident:** Config change (rate limit 5k → 10k req/min)
   - ⚠️  **5 min before incident:** Deploy user-service v2.3.1
   
   ## 🔍 Evidence
   
   **Logs (top errors):**
   - "Database connection pool exhausted" (1,523 occurrences)
   - "Timeout waiting for connection" (892 occurrences)
   
   **Metrics (anomalies):**
   - db_connection_pool_utilization: 60% → 100%
   - memory_usage: 70% → 95%
   
   **Traces (slow operations):**
   - GET /api/users: 150ms → 4,500ms (database query bottleneck)
   ```

**Output:** Comprehensive incident context package

---

### Phase 2: Root Cause Analysis

**Goal:** Identify root cause through evidence-based analysis

**Input:** Incident context from Phase 1

**Process:**

1. **Present hypotheses:**
   ```
   Based on evidence, the most likely root causes are:
   
   1. **Database connection pool exhaustion** (High confidence: 85%)
      ✅ Evidence:
      - Logs: "connection pool exhausted" spiking at incident start
      - Metrics: Pool utilization at 100% (maxed out)
      - Timing: Rate limit increase 10 min before (3x traffic)
      - Symptoms: Timeouts and slow database queries
      
      ❌ Counter-evidence:
      - None identified
      
      🔍 Validation steps:
      - Check actual pool size vs traffic
      - Confirm no connection leaks
      - Verify rate limit change timing
   
   2. **Memory leak in user-service v2.3.1** (Medium confidence: 40%)
      ✅ Evidence:
      - Memory climbing since v2.3.1 deploy
      - Timing: Deployed 5 min before incident
      
      ❌ Counter-evidence:
      - Error logs point to database, not memory
      - Memory increased but not yet OOM
      
      🔍 Validation steps:
      - Check heap dumps
      - Compare v2.3.1 with v2.3.0
   
   Which hypothesis should we investigate first?
   ```

2. **Guide validation:**
   ```
   User selects hypothesis (typically highest confidence)
   
   For selected hypothesis, guide validation:
   
   "Let's validate hypothesis #1: Connection pool exhaustion"
   
   Validation questions:
   - What's the configured pool size? (Check config)
   - What's the current traffic rate? (Check metrics)
   - Are connections timing out or leaking? (Check logs)
   - Does the timing match? (Compare timeline)
   ```

3. **Confirm root cause:**
   ```
   Once validated:
   
   ✅ **Root Cause Confirmed**
   
   **Primary:** Database connection pool size (100) insufficient for 10k req/min traffic
   
   **Contributing Factors:**
   1. Rate limit increase from 5k to 10k req/min (3x traffic spike)
   2. Connection pool size not scaled with rate limit
   3. No connection timeout configured (hung connections accumulate)
   4. Missing monitoring on pool utilization
   
   **Why It Happened:**
   - Config change bypassed normal review process
   - No load testing of rate limit changes
   - Capacity planning was manual, not automated
   ```

**Output:** Confirmed root cause with contributing factors

---

### Phase 3: Fix Planning

**Goal:** Design safe, effective solution

**Input:** Root cause from Phase 2

**Process:**

1. **Present fix options:**
   ```markdown
   ## 🚑 Immediate Mitigation (Stop the bleeding)
   
   Choose one or more:
   
   A) **Rollback rate limit** (2 minutes, low risk)
      - Restore traffic to 5k req/min
      - Pool can handle this load
      - Quickest mitigation
   
   B) **Increase pool size** (5 minutes, medium risk)
      - Scale pool from 100 → 300
      - Requires service restart (rolling)
      - Fixes root cause directly
   
   C) **Restart services** (10 minutes, medium risk)
      - Clears hung connections
      - Temporary relief
      - Doesn't fix root cause
   
   D) **Combination** (recommended: A + B)
      - Rollback rate limit immediately
      - Then increase pool size
      - Safest, most effective
   
   ## 🔧 Permanent Fixes (Prevent recurrence)
   
   1. Add connection timeout configuration (30s)
   2. Scale pool size dynamically with traffic
   3. Add pool utilization monitoring and alerting
   4. Require load testing for rate limit changes
   5. Automate capacity planning
   ```

2. **User selects approach:**
   ```
   User chooses (e.g., "D - Rollback + Increase pool")
   ```

3. **Create implementation plan:**
   ```markdown
   ## 📋 Fix Implementation Plan
   
   ### Immediate Actions (Next 7 minutes)
   
   **Action 1: Rollback rate limit** (2 minutes)
   - File: `config/rate-limits.yaml`
   - Change: `requests_per_minute: 10000 → 5000`
   - Method: Hot reload via config service
   - Verification: Traffic drops, error rate decreases
   - Risk: Low (known good config)
   - Rollback: Re-apply if needed (1 min)
   
   **Action 2: Increase connection pool** (5 minutes)
   - File: `config/database.yaml`
   - Change: `pool_size: 100 → 300`
   - Method: Rolling restart (3 pods at a time)
   - Verification: Pool utilization <80%, errors stop
   - Risk: Medium (restart required)
   - Rollback: Revert config and restart (5 min)
   
   ### Permanent Fixes (This week)
   
   **Task #500: Add connection timeout** (P1, 1 day)
   - Add `connection_timeout: 30s` to database config
   - Prevents hung connections from accumulating
   - Test: Simulate database slowness
   
   **Task #501: Add pool monitoring** (P1, 2 days)
   - Alert: Pool utilization >80%
   - Dashboard: Connection pool metrics
   - Proactive detection before exhaustion
   
   **Task #502: Automated capacity planning** (P2, 1 week)
   - Auto-scale pool based on traffic
   - Load test config changes automatically
   - Capacity planning checklist
   ```

4. **Assess plan complexity:**
   ```
   If plan is complex or risky:
     Ask: "This plan involves [risks]. Should we review with two-claude-review?"
     
     Criteria for review:
     - Affects production database
     - Requires service restarts
     - Multiple concurrent changes
     - High severity incident (P0/P1)
     
   If user says yes:
     Invoke two-claude-review with plan
     Iterate on feedback
   ```

**Output:** Approved, detailed implementation plan

---

### Phase 4: Fix Implementation

**Goal:** Execute fix safely with verification

**Input:** Approved plan from Phase 3

**Process:**

1. **Execute immediate mitigations:**
   ```
   For each mitigation in order:
   
   **Executing Action 1: Rollback rate limit**
   
   Step 1: Edit config
   ```bash
   kubectl edit configmap rate-limits -n production
   # Change line 12: requests_per_minute: 5000
   ```
   
   Step 2: Apply config
   ```bash
   kubectl rollout restart deployment/config-service
   ```
   
   Step 3: Verify
   ```bash
   # Check traffic dropped
   curl https://metrics.example.com/api/request_rate
   
   # Check error rate decreasing
   curl https://metrics.example.com/api/error_rate
   ```
   
   ✅ Did this action succeed? (wait for user confirmation)
   ```

2. **Monitor impact after each action:**
   ```
   After each mitigation:
   
   📊 **Impact Check**
   
   Metrics to verify:
   - Error rate: Target <1% (currently: checking...)
   - Response time: Target <500ms p95 (currently: checking...)
   - Pool utilization: Target <80% (currently: checking...)
   
   Ask user: "What do the metrics show? Are things improving?"
   
   If not improving:
     Stop and re-evaluate
     May need to try alternative approach
   
   If improving:
     Continue to next action
   ```

3. **For code fixes (if needed):**
   ```
   If fix requires code changes:
   
   Invoke staff-developer:
   "Implement permanent fix for connection pool exhaustion
   
   Context:
   - Root cause: Pool size (100) insufficient for 10k req/min
   - Immediate fix: Already rolled back to 5k req/min
   
   Permanent fix needed:
   - Add connection_timeout: 30s to database config
   - Add pool utilization metrics
   - Update documentation
   
   Files to modify:
   - config/database.yaml
   - pkg/metrics/database_metrics.go
   - docs/database.md
   
   Test plan:
   - Load test with 10k req/min
   - Verify pool stays <80% utilized
   - Verify timeouts prevent hung connections
   - Verify metrics are exported"
   
   Developer implements and reports back
   ```

4. **Code review (for code fixes):**
   ```
   If code was changed:
   
   Invoke staff-engineer:
   "Review connection pool fix implementation
   
   Context:
   - Incident: Connection pool exhaustion (P1)
   - Changes: Added timeout, metrics, increased pool
   
   Review for:
   - Does timeout prevent hung connections?
   - Are metrics sufficient for monitoring?
   - Is pool size calculation correct?
   - Edge cases handled?
   - Documentation updated?
   
   This is a hotfix for production incident."
   
   If issues found:
     Loop back to staff-developer with feedback
   
   Once approved:
     Proceed to deployment
   ```

5. **Deploy fix:**
   ```
   Guide deployment:
   
   **Deployment Strategy: Rolling Update**
   
   1. Deploy to canary (10% of pods)
   2. Monitor for 5 minutes
   3. If metrics good, continue rollout
   4. If metrics bad, rollback immediately
   
   Commands:
   ```bash
   # Deploy canary
   kubectl set image deployment/user-service \
     user-service=user-service:v2.3.2-fix
   
   # Watch rollout
   kubectl rollout status deployment/user-service
   
   # Monitor metrics
   watch -n 5 'curl https://metrics.example.com/api/health'
   
   # If good, continue
   kubectl rollout resume deployment/user-service
   
   # If bad, rollback
   kubectl rollout undo deployment/user-service
   ```
   
   Ask: "How do metrics look? Green to continue?"
   ```

6. **Verify complete resolution:**
   ```markdown
   ## ✅ Resolution Verification
   
   Check all symptoms resolved:
   - ✅ Error rate back to baseline (0.1%)
   - ✅ Response time normal (200ms p95)
   - ✅ Pool utilization healthy (65%)
   - ✅ No new user reports
   - ✅ All services healthy
   
   **Incident resolved!** ✅
   
   Time to resolution: [X] minutes
   ```

**Output:** Incident mitigated and fix deployed

---

### Phase 5: Post-Incident Documentation

**Goal:** Generate comprehensive post-mortem

**Input:** Complete incident data

**Process:**

1. **Gather post-mortem data:**
   ```python
   post_mortem_data = {
     'incident': {
       'id': incident_id,
       'title': incident_title,
       'severity': severity,
       'started_at': incident_start,
       'resolved_at': incident_end,
       'duration_minutes': (incident_end - incident_start).minutes
     },
     'timeline': timeline_events,  # All timestamped events
     'root_cause': confirmed_root_cause,
     'resolution': {
       'immediate_actions': actions_taken,
       'permanent_fixes': planned_fixes,
       'code_changes': deployed_prs
     },
     'prevention': prevention_measures,
     'lessons_learned': lessons,
     'action_items': follow_up_tasks
   }
   ```

2. **Invoke documentation-agent:**
   ```json
   {
     "type": "post-mortem",
     ... (data from step 1)
   }
   ```

3. **Review generated post-mortem:**
   ```
   Present generated post-mortem to user
   
   "I've generated a post-mortem. Please review:"
   
   [Show document]
   
   "Does this accurately capture:
   - Timeline of events?
   - Root cause explanation?
   - Resolution steps?
   - Lessons learned?
   - Action items?"
   
   Iterate on feedback until approved
   ```

4. **Save and share post-mortem:**
   ```bash
   # Save to repository
   file_path="docs/post-mortems/2026/2026-04-13-connection-pool-exhaustion.md"
   mkdir -p "$(dirname "$file_path")"
   echo "$post_mortem" > "$file_path"
   
   # Commit
   git add "$file_path"
   git commit -m "Add post-mortem for incident FH-abc123

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
   
   # Push
   git push origin main
   ```

5. **Create follow-up tasks:**
   ```bash
   # Create GitHub issues for action items
   for action_item in action_items:
     gh issue create \
       --title "${action_item.task}" \
       --label "incident-followup,${action_item.priority}" \
       --assignee "${action_item.assignee}" \
       --body "Follow-up from incident FH-abc123

${action_item.details}

**Context:** ${post_mortem_url}
**Priority:** ${action_item.priority}
**Due:** ${action_item.due_date}"
   ```

6. **Update Firehydrant:**
   ```bash
   # Mark incident as resolved
   curl -X PATCH \
     "https://api.firehydrant.io/v1/incidents/${incident_id}" \
     -H "Authorization: Bearer $FIREHYDRANT_API_KEY" \
     -d '{
       "status": "resolved",
       "resolved_at": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
     }'
   
   # Add post-mortem link
   curl -X POST \
     "https://api.firehydrant.io/v1/incidents/${incident_id}/notes" \
     -H "Authorization: Bearer $FIREHYDRANT_API_KEY" \
     -d '{
       "body": "Post-mortem: '"${post_mortem_url}"'"
     }'
   ```

7. **Report completion:**
   ```markdown
   ## ✅ Incident Response Complete
   
   **Timeline:**
   - Incident started: 14:30 UTC
   - Context gathered: 14:35 UTC (5 min)
   - Root cause identified: 14:40 UTC (10 min)
   - Fix deployed: 14:50 UTC (20 min)
   - Incident resolved: 14:55 UTC (25 min)
   - Post-mortem completed: 15:05 UTC (35 min)
   
   **Total MTTR:** 25 minutes (incident to resolution)
   **Total time:** 35 minutes (incident to post-mortem)
   
   **Artifacts:**
   - Post-mortem: [URL]
   - Follow-up tasks: #500, #501, #502
   - Firehydrant: Updated and resolved
   
   **What's next:**
   - Team review post-mortem
   - Work on follow-up tasks
   - Update runbooks if needed
   ```

**Output:** Complete documentation and follow-up plan

---

## Configuration

The team respects configuration from `.claude-grimoire/config.json`:

```json
{
  "incidentResponseTeam": {
    "autoCreateFirehydrantIncident": false,
    "requirePostMortem": true,
    "postMortemPath": "docs/post-mortems",
    "autoCreateFollowupTasks": true,
    "reviewComplexFixes": true
  },
  "firehydrant": {
    "orgSlug": "your-org",
    "apiKey": "${FIREHYDRANT_API_KEY}"
  },
  "coralogix": {
    "region": "us",
    "apiKey": "${CORALOGIX_API_KEY}"
  }
}
```

## Usage Examples

### Example 1: P1 Incident - Database Issue

**User:** "We have a P1 incident: https://app.firehydrant.io/incidents/abc123"

**Team workflow:**

1. **Triage (5 min)**
   - Invokes incident-context-agent
   - Presents: 15% error rate, connection pool at 100%
   - Recent change: Rate limit increase 10 min ago

2. **Root Cause (10 min)**
   - Top hypothesis: Pool exhaustion (85% confidence)
   - Validates: Pool size vs traffic mismatch
   - Confirms: Rate limit change caused 3x traffic

3. **Fix Planning (5 min)**
   - Options: Rollback rate limit + increase pool
   - Creates detailed plan with rollback strategy
   - Skips two-claude-review (straightforward fix)

4. **Implementation (15 min)**
   - Rolls back rate limit (2 min)
   - Increases pool size (5 min)
   - Monitors: Error rate drops to 0.1%
   - Verifies resolution

5. **Documentation (10 min)**
   - Invokes documentation-agent
   - Generates post-mortem
   - Creates 3 follow-up tasks
   - Updates Firehydrant

**Result:** 45 minutes total (vs 2-3 hours manually)

---

### Example 2: P0 Incident - Complete Outage

**User:** "Production is down! All services returning 503"

**Team workflow:**

1. **Triage (3 min)**
   - No Firehydrant incident yet
   - Creates incident (P0, all services)
   - Invokes incident-context-agent with broad scope

2. **Root Cause (5 min)**
   - Multiple hypotheses presented
   - Evidence: Load balancer health checks failing
   - Root cause: Certificate expired

3. **Fix Planning (2 min)**
   - Immediate: Renew certificate
   - Simple fix, no review needed

4. **Implementation (5 min)**
   - Guides certificate renewal
   - Monitors: Services recovering
   - Full recovery in 3 minutes

5. **Documentation (10 min)**
   - Post-mortem emphasizes prevention
   - Action item: Automated cert renewal
   - Lessons: Monitoring gap identified

**Result:** 25 minutes total (vs 1-2 hours manually)

---

### Example 3: P2 Incident - Performance Degradation

**User:** "Response times are 3x normal but no errors"

**Team workflow:**

1. **Triage (10 min)**
   - Creates incident (P2, api-service)
   - Context: Slow database queries

2. **Root Cause (20 min)**
   - Multiple hypotheses
   - Traces show: Missing database index
   - Caused by: New query pattern in recent deploy

3. **Fix Planning (10 min)**
   - Need to add database index
   - Complex fix (production database)
   - Invokes two-claude-review for plan

4. **Implementation (30 min)**
   - staff-developer creates index migration
   - staff-engineer reviews
   - Applies index with monitoring
   - Performance restored

5. **Documentation (10 min)**
   - Post-mortem documents missing index
   - Action items: Query review process
   - Lessons: Performance testing gaps

**Result:** 80 minutes total (vs 3-4 hours manually)

---

## Decision Trees

### Should we invoke two-claude-review?

```
Is this a code fix? → No → Skip review
  ↓ Yes
Is it simple config change? → Yes → Skip review
  ↓ No
Is it production database change? → Yes → Review plan
  ↓ No
Is it P0/P1 with high risk? → Yes → Review plan
  ↓ No
Skip review (but still do staff-engineer code review)
```

### Should we create Firehydrant incident?

```
Does Firehydrant incident exist? → Yes → Use it
  ↓ No
Is this P0/P1? → Yes → Create incident
  ↓ No (P2/P3)
User preference? → Ask user
  → If yes: Create incident
  → If no: Proceed without
```

### Should we involve staff-developer?

```
Does fix require code changes? → No → Skip
  ↓ Yes
Is it simple config/restart? → Yes → Skip
  ↓ No
Invoke staff-developer for implementation
```

## Best Practices

### Do:
- ✅ Gather comprehensive context before hypothesis formation
- ✅ Present evidence-based hypotheses
- ✅ Have rollback plan before deploying fix
- ✅ Monitor impact after each mitigation step
- ✅ Generate post-mortem even for quick fixes
- ✅ Create follow-up tasks for prevention
- ✅ Update Firehydrant status

### Don't:
- ❌ Skip to fix without understanding root cause
- ❌ Deploy unreviewed changes for complex fixes
- ❌ Forget to monitor after mitigation
- ❌ Skip post-mortem (even for P3/P4)
- ❌ Blame individuals in documentation
- ❌ Let follow-up tasks go untracked

## Integration with Other Components

### Phase 1 Components
- incident-context-agent - Gathers context (required)
- documentation-agent - Generates post-mortem (required)

### Phase 2 Components
- None directly, but can reference visual-prd for system context

### External Skills
- staff-developer - Implements code fixes (optional)
- staff-engineer - Reviews fixes (optional)
- two-claude-review - Reviews complex plans (optional)

## Success Criteria

The team is successful when:
- ✅ Context gathered in <5 minutes
- ✅ Root cause identified in <15 minutes
- ✅ Fix deployed safely with monitoring
- ✅ Incident resolved faster than manual (60-70% reduction)
- ✅ Post-mortem generated and shared
- ✅ Follow-up tasks created
- ✅ Team learns from incident
- ✅ No rework due to rushed fixes

## Time Savings

### P1 Incident Example

**Traditional response time:**
- Manual context gathering: 30 minutes (logs, metrics, deployments)
- Root cause analysis: 30 minutes (trial and error)
- Fix planning: 15 minutes
- Fix implementation: 20 minutes
- Post-mortem writing: 60 minutes
- **Total: 155 minutes (2.5 hours)**

**With incident-response-team:**
- Context gathering: 5 minutes (automated)
- Root cause analysis: 10 minutes (guided with evidence)
- Fix planning: 5 minutes (structured approach)
- Fix implementation: 20 minutes (same, but monitored)
- Post-mortem: 10 minutes (auto-generated)
- **Total: 50 minutes**

**Savings: 105 minutes (68% reduction)**

### Additional Benefits

- **Consistency:** Every incident documented the same way
- **Learning:** Post-mortems always created, not skipped
- **Quality:** Evidence-based diagnosis, not guesswork
- **Prevention:** Follow-up tasks tracked
- **Knowledge:** Builds searchable incident database

## Metrics to Track

### Response Metrics
- MTTR (Mean Time To Resolution)
- Time to root cause identification
- Fix deployment time
- Post-mortem completion time

### Quality Metrics
- Root cause accuracy (was hypothesis correct?)
- Fix effectiveness (did it actually resolve incident?)
- Post-mortem completeness
- Follow-up task completion rate

### Learning Metrics
- Incident recurrence rate
- Prevention measures implemented
- Runbooks created/updated
- Team knowledge growth

---

**Built to minimize MTTR and maximize learning from every incident** 🔥