---
name: incident-handler
description: End-to-end incident response from alert to post-mortem with automated context gathering
version: 1.0.0
author: claude-grimoire
requires:
  - incident-context-agent
  - documentation-agent
optional:
  - staff-developer
  - staff-engineer
  - two-claude-review
---

# Incident Handler

Complete incident response workflow from initial alert through diagnosis, fix implementation, verification, and post-mortem documentation. Automates context gathering from Firehydrant, logs, metrics, and services.

## Purpose

Streamline incident response to minimize MTTR (Mean Time To Resolution):
- Automated context gathering from multiple sources
- Guided root cause analysis
- Implementation with quality gates
- Automated post-mortem generation
- Integration with incident management (Firehydrant)

## When to Use

- Responding to production incidents
- Investigating Firehydrant alerts
- Troubleshooting service degradation
- Post-incident documentation
- Learning from outages

## Workflow

### Phase 1: Incident Triage

**Goal:** Understand the incident and gather initial context

**Input:** Firehydrant incident URL or alert description

**Process:**

1. **Get incident identifier:**
   ```
   Ask user: "What incident are we responding to?"
   
   Options:
   A) Firehydrant incident URL
   B) Alert description (I'll create Firehydrant incident)
   C) Known issue (provide details)
   ```

2. **Validate Firehydrant access:**
   ```bash
   # Check Firehydrant API key is configured
   if [ -z "$FIREHYDRANT_API_KEY" ]; then
     Error: "Firehydrant API key not found"
     Suggest: "Set FIREHYDRANT_API_KEY environment variable"
   fi
   ```

3. **Gather basic incident info:**
   ```
   If Firehydrant URL provided:
     Extract incident ID from URL
     e.g., https://app.firehydrant.io/incidents/abc123 → abc123
   
   If alert description:
     Ask: "What service is affected?"
     Ask: "What's the observed behavior?"
     Ask: "When did it start?"
   ```

4. **Invoke incident-context-agent:**
   ```json
   {
     "incident_id": "abc123",
     "timeframe": "last_1h",
     "services": ["api-gateway", "user-service"],
     "gather": ["logs", "metrics", "traces", "deployments"]
   }
   ```

5. **Present initial assessment:**
   ```markdown
   ## Incident Overview
   
   **Incident:** #abc123
   **Severity:** P1 (Critical)
   **Started:** 2026-04-13 14:30 UTC
   **Duration:** 15 minutes (ongoing)
   **Affected:** api-gateway, user-service
   
   **Symptoms:**
   - 500 error rate: 0.5% → 15%
   - Response time: 200ms → 5s (p95)
   - User reports: 47 complaints
   
   **Recent Changes:**
   - Deploy: user-service v2.3.1 at 14:25 UTC
   - Config: Rate limit increased at 14:20 UTC
   
   **Correlated Events:**
   - Database connection pool exhaustion
   - Memory usage spike: 60% → 95%
   ```

**Output:** Incident context package with timeline, symptoms, recent changes

---

### Phase 2: Root Cause Analysis

**Goal:** Identify root cause through guided investigation

**Input:** Incident context from Phase 1

**Process:**

1. **Present evidence:**
   ```
   Show agent-gathered evidence:
   - Log patterns (errors, warnings)
   - Metric anomalies (spikes, drops)
   - Trace analysis (slow operations)
   - Recent deployments
   - Configuration changes
   
   Organize by likelihood of being root cause
   ```

2. **Guide hypothesis formation:**
   ```
   Ask: "Based on the evidence, what do you think is the root cause?"
   
   If unsure, present top hypotheses:
   
   1. **Database connection pool exhaustion** (High confidence)
      Evidence:
      - Logs: "connection pool timeout" errors spiking at 14:30
      - Metrics: Pool size maxed at 100 (limit)
      - Recent change: Traffic increased 3x after rate limit change
      
   2. **Memory leak in user-service v2.3.1** (Medium confidence)
      Evidence:
      - Memory usage climbing steadily since 14:25
      - Heap dumps show retained objects growing
      - Version v2.3.1 deployed at incident start
      
   3. **External API degradation** (Low confidence)
      Evidence:
      - Payment service latency increased
      - But only affecting 10% of requests
   ```

3. **Validate hypothesis:**
   ```
   For selected hypothesis, ask:
   - "Does this explain all symptoms?"
   - "Is timing consistent?"
   - "Are there counter-examples?"
   
   If hypothesis doesn't fit, iterate
   ```

4. **Confirm root cause:**
   ```
   Once validated:
   
   ✅ Root Cause Identified
   
   **Root Cause:** Database connection pool exhaustion
   
   **Contributing Factors:**
   - Rate limit increase caused 3x traffic spike
   - Connection pool size not scaled accordingly
   - No connection timeout configured (hung connections)
   
   **Why It Happened:**
   - Config change bypassed normal review
   - No load testing of rate limit changes
   - Missing monitoring on pool utilization
   ```

**Output:** Confirmed root cause with contributing factors

---

### Phase 3: Fix Planning

**Goal:** Design solution and mitigation strategy

**Input:** Root cause from Phase 2

**Process:**

1. **Identify fix options:**
   ```
   Present options:
   
   **Immediate Mitigation (Stop the bleeding):**
   A) Rollback rate limit config (2 minutes)
   B) Increase connection pool size (5 minutes)
   C) Restart services to clear hung connections (10 minutes)
   D) Multiple of above
   
   **Permanent Fix (Prevent recurrence):**
   - Add connection timeout configuration
   - Scale pool size with rate limit
   - Add pool utilization monitoring
   - Add load testing to config changes
   ```

2. **User selects approach:**
   ```
   Ask: "Which immediate mitigation?"
   
   Common choice: "A + B - Rollback rate limit and increase pool size"
   ```

3. **Create implementation plan:**
   ```markdown
   ## Fix Implementation Plan
   
   ### Immediate Actions (Next 5 minutes)
   
   1. **Rollback rate limit config** (2 minutes)
      - File: `config/rate-limits.yaml`
      - Change: `requests_per_minute: 10000` → `5000`
      - Deploy: Hot reload via config service
      - Verify: Traffic drops, error rate decreases
   
   2. **Increase connection pool** (3 minutes)
      - File: `config/database.yaml`
      - Change: `pool_size: 100` → `300`
      - Deploy: Rolling restart of user-service pods
      - Verify: Pool utilization <80%, errors stop
   
   ### Permanent Fixes (This week)
   
   3. **Add connection timeout** (Task #500)
      - Add `connection_timeout: 30s` to database config
      - Prevents hung connections
      - Test: Simulate database slowness
   
   4. **Add monitoring** (Task #501)
      - Alert: Pool utilization >80%
      - Dashboard: Connection metrics
      - Proactive detection
   
   5. **Process improvement** (Task #502)
      - Load test config changes
      - Require review for rate limits
      - Capacity planning checklist
   
   ### Rollback Plan
   
   If fix makes things worse:
   - Rollback config: 1 minute
   - Rollback pool size: 5 minutes (restart required)
   - Emergency: Route traffic to backup region
   ```

4. **Review plan (if complex):**
   ```
   If fix is complex or risky:
     Invoke /two-claude-review with plan
     
     Reviewer checks:
     - Will this actually fix the root cause?
     - Are there side effects or risks?
     - Is rollback plan solid?
     - Is this the simplest fix?
     
     Iterate on feedback
   ```

**Output:** Approved implementation plan with rollback strategy

---

### Phase 4: Fix Implementation

**Goal:** Execute fix with verification

**Input:** Approved fix plan from Phase 3

**Process:**

1. **Execute immediate mitigations:**
   ```
   For each mitigation:
     Show exactly what to do
     Or offer to execute automatically (if safe)
     
   Example:
   
   **Action 1: Rollback rate limit**
   
   ```bash
   # Edit config
   vim config/rate-limits.yaml
   # Change line 12: requests_per_minute: 5000
   
   # Deploy
   kubectl apply -f config/rate-limits.yaml
   
   # Verify
   curl https://api.example.com/health
   ```
   
   Ask after each: "Did this action succeed? Any errors?"
   ```

2. **Monitor impact:**
   ```
   After each mitigation:
   
   Check metrics:
   - Error rate: Has it decreased?
   - Response time: Has it improved?
   - Pool utilization: Is it lower?
   
   Ask user to confirm from their dashboard
   
   If not improving:
     - Stop
     - Re-evaluate hypothesis
     - Try alternative fix
   ```

3. **Invoke staff-developer (for code fixes):**
   ```
   If fix requires code changes:
   
   Provide context to staff-developer:
   "Fix the connection pool exhaustion issue
   
   Root cause: Pool size (100) insufficient for 10k req/min
   
   Changes needed:
   - config/database.yaml: pool_size: 100 → 300
   - config/database.yaml: add connection_timeout: 30s
   - Add pool utilization metric
   
   Test plan:
   - Load test with 10k req/min
   - Verify pool stays <80% utilized
   - Verify timeouts prevent hung connections"
   
   Developer implements and reports back
   ```

4. **Code review (if applicable):**
   ```
   If code was changed:
     Invoke staff-engineer for review
     
     Focus on:
     - Does this actually fix the root cause?
     - Are there edge cases?
     - Is error handling correct?
     - Are metrics/logs added?
   ```

5. **Deploy fix:**
   ```
   Guide deployment:
   
   **Deployment Strategy:**
   - Canary: Deploy to 10% of pods first
   - Monitor: Watch metrics for 5 minutes
   - If good: Roll out to remaining 90%
   - If bad: Rollback immediately
   
   Commands:
   ```bash
   # Canary deploy
   kubectl set image deployment/user-service \
     user-service=user-service:v2.3.2-fix \
     --record
   
   # Watch pods
   kubectl rollout status deployment/user-service
   
   # If good, continue
   kubectl rollout resume deployment/user-service
   ```
   
   Ask: "How does the canary look? Green to proceed?"
   ```

6. **Verify resolution:**
   ```
   Check all symptoms resolved:
   - ✅ Error rate back to baseline (0.1%)
   - ✅ Response time normal (200ms p95)
   - ✅ Pool utilization healthy (65%)
   - ✅ No more user reports
   
   Incident resolved!
   ```

**Output:** Incident mitigated and fix deployed

---

### Phase 5: Post-Incident Documentation

**Goal:** Create comprehensive post-mortem

**Input:** Complete incident timeline and fix

**Process:**

1. **Invoke documentation-agent:**
   ```json
   {
     "type": "post-mortem",
     "incident_id": "abc123",
     "timeline": [...],
     "root_cause": "Database connection pool exhaustion",
     "fix": "Increased pool size and added timeout",
     "prevention": ["Load test config changes", "Add monitoring"]
   }
   ```

2. **Agent generates post-mortem:**
   ```markdown
   # Post-Mortem: Database Connection Pool Exhaustion
   
   **Incident ID:** FH-abc123
   **Date:** 2026-04-13
   **Duration:** 45 minutes
   **Severity:** P1 (Critical)
   **Impact:** 15% error rate, 47 user complaints
   
   ## What Happened
   
   On April 13 at 14:30 UTC, the API gateway began returning 500 errors at a rate of 15% (up from baseline 0.1%). Response times degraded from 200ms to 5s (p95). Users reported inability to access their accounts.
   
   ## Timeline
   
   - **14:20 UTC** - Rate limit configuration increased from 5k to 10k requests/minute
   - **14:25 UTC** - user-service v2.3.1 deployed (unrelated)
   - **14:30 UTC** - Error rate begins climbing
   - **14:32 UTC** - PagerDuty alert fires
   - **14:35 UTC** - Engineer begins investigation
   - **14:40 UTC** - Root cause identified (connection pool exhaustion)
   - **14:42 UTC** - Rate limit rolled back to 5k req/min
   - **14:45 UTC** - Connection pool increased to 300
   - **14:50 UTC** - Services restarted
   - **14:55 UTC** - Metrics return to normal
   - **15:15 UTC** - Incident declared resolved
   
   ## Root Cause
   
   **Primary:** Database connection pool size (100) was insufficient for 10k requests/minute traffic load.
   
   **Contributing Factors:**
   1. Rate limit increase bypassed normal review process
   2. No load testing of configuration changes
   3. Missing monitoring on connection pool utilization
   4. No connection timeout configured (allowed hung connections to accumulate)
   
   ## Impact
   
   - **User Impact:** 15% of API requests failed, affecting ~5,000 users
   - **Business Impact:** 47 support tickets, potential revenue loss
   - **Duration:** 45 minutes from first symptom to full resolution
   
   ## Resolution
   
   **Immediate Actions:**
   1. Rolled back rate limit configuration (restored traffic to manageable level)
   2. Increased connection pool size from 100 to 300
   3. Restarted services to clear hung connections
   
   **Permanent Fixes:**
   1. Added connection timeout configuration (30s)
   2. Scaled connection pool to 300 (3x traffic capacity)
   3. Added monitoring and alerting on pool utilization
   
   ## Prevention
   
   **Process Improvements:**
   1. ✅ Require load testing for all rate limit changes
   2. ✅ Add capacity planning checklist for config changes
   3. ✅ Implement automated canary testing for config
   
   **Technical Improvements:**
   1. ✅ Add connection pool monitoring (Task #501)
   2. ✅ Alert on pool utilization >80%
   3. ✅ Configure connection timeouts (Task #500)
   4. ✅ Auto-scale pool based on traffic
   
   **Documentation:**
   1. ✅ Update runbook: "Connection pool exhaustion"
   2. ✅ Document rate limit capacity planning
   3. ✅ Add troubleshooting guide
   
   ## Lessons Learned
   
   **What Went Well:**
   - ✅ Root cause identified quickly (10 minutes)
   - ✅ Mitigation was straightforward (config rollback)
   - ✅ Team communicated effectively
   - ✅ Monitoring provided clear signals
   
   **What Could Be Improved:**
   - ⚠️  Rate limit change should have been load tested
   - ⚠️  Connection pool monitoring was missing
   - ⚠️  Config changes need better review process
   - ⚠️  Capacity planning was not rigorous enough
   
   ## Action Items
   
   - [ ] #500 - Add connection timeout config (P1, assigned: @backend-team)
   - [ ] #501 - Add connection pool monitoring (P1, assigned: @platform-team)
   - [ ] #502 - Load testing for config changes (P2, assigned: @sre-team)
   - [ ] #503 - Config change review process (P2, assigned: @tech-lead)
   - [ ] #504 - Capacity planning automation (P3, assigned: @platform-team)
   
   ## References
   
   - Firehydrant Incident: https://app.firehydrant.io/incidents/abc123
   - Coralogix Logs: [link]
   - Grafana Dashboard: [link]
   - Related Post-Mortems: [PM-2024-03-15: Database slowdown]
   
   ---
   Generated with 🤖 [claude-grimoire](https://github.com/martythewizard/claude-grimoire)
   ```

3. **Review post-mortem with user:**
   ```
   Present generated post-mortem
   
   Ask: "Does this accurately capture what happened?"
   
   Iterate on:
   - Timeline accuracy
   - Root cause explanation
   - Action items
   - Lessons learned
   ```

4. **Save and share:**
   ```bash
   # Save to repository
   mkdir -p docs/post-mortems/2026
   cat > docs/post-mortems/2026/2026-04-13-connection-pool-exhaustion.md
   
   # Commit
   git add docs/post-mortems/
   git commit -m "Add post-mortem for incident FH-abc123"
   
   # Share with team (optional)
   # Post to Slack, email, or Firehydrant
   ```

5. **Update Firehydrant:**
   ```bash
   # Mark incident as resolved
   curl -X PATCH \
     https://api.firehydrant.io/v1/incidents/abc123 \
     -H "Authorization: Bearer $FIREHYDRANT_API_KEY" \
     -d '{"status": "resolved", "resolved_at": "2026-04-13T15:15:00Z"}'
   
   # Add post-mortem link
   curl -X POST \
     https://api.firehydrant.io/v1/incidents/abc123/notes \
     -H "Authorization: Bearer $FIREHYDRANT_API_KEY" \
     -d '{"body": "Post-mortem: [link]"}'
   ```

**Output:** Comprehensive post-mortem saved and shared

---

## Configuration

The skill respects configuration from `.claude-grimoire/config.json`:

```json
{
  "incidentHandler": {
    "defaultTimeframe": "1h",
    "autoCreateFirehydrantIncident": false,
    "requirePostMortem": true,
    "postMortemPath": "docs/post-mortems"
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

### Example 1: Firehydrant Alert

**User:** "I have a Firehydrant incident: https://app.firehydrant.io/incidents/abc123"

**Skill:**
1. Extracts incident ID: abc123
2. Invokes incident-context-agent
3. Presents context (logs, metrics, deployments)
4. Guides root cause analysis
5. Creates fix plan
6. Executes fix with verification
7. Generates post-mortem

**Timeline:** 30-45 minutes from alert to post-mortem (vs 2-3 hours manually)

---

### Example 2: Manual Alert

**User:** "Users are reporting 500 errors on the checkout page"

**Skill:**
1. Asks for service, symptoms, timing
2. Creates Firehydrant incident (optional)
3. Invokes incident-context-agent with service details
4. Presents evidence and hypotheses
5. Guides investigation
6. Implements fix
7. Documents post-mortem

**Timeline:** 45-60 minutes depending on complexity

---

### Example 3: Post-Incident Documentation Only

**User:** "Incident is already fixed, I just need the post-mortem"

**Skill:**
1. Asks for incident details (what happened, root cause, fix)
2. Skips to Phase 5 (documentation)
3. Invokes documentation-agent
4. Generates post-mortem from user's input
5. Saves and shares

**Timeline:** 10-15 minutes for documentation

---

## Integration with Other Components

### Agents Used
- `incident-context-agent` - Gathers context from Firehydrant, Coralogix, services (required)
- `documentation-agent` - Generates post-mortem documentation (required)

### Skills Used
- `staff-developer` - Implements code fixes (optional, for code changes)
- `staff-engineer` - Reviews fixes (optional, for complex fixes)
- `two-claude-review` - Reviews fix plans (optional, for risky fixes)

### External Services
- Firehydrant - Incident management
- Coralogix - Logs and metrics
- Company Go CLI - Service-specific queries
- GitHub - Issue creation for follow-ups

## Best Practices

### Do:
- ✅ Gather context before hypothesis formation
- ✅ Validate root cause thoroughly
- ✅ Have rollback plan before deploying fix
- ✅ Monitor impact after each mitigation
- ✅ Document lessons learned
- ✅ Create action items for prevention

### Don't:
- ❌ Skip to fix without understanding root cause
- ❌ Deploy unreviewed changes to prod during incident
- ❌ Forget to update Firehydrant status
- ❌ Skip post-mortem (even for small incidents)
- ❌ Blame individuals in post-mortem
- ❌ Let action items go untracked

## Success Criteria

This skill is successful when:
- ✅ Root cause identified quickly (<15 minutes)
- ✅ Fix deployed safely with monitoring
- ✅ Incident resolved and verified
- ✅ Post-mortem generated and shared
- ✅ Action items created for prevention
- ✅ Team learns from incident
- ✅ MTTR reduced (30-45 min vs 2-3 hours manual)

## Time Savings

**Traditional incident response:**
- Context gathering: 30-45 minutes (manual log searching, metric hunting)
- Root cause analysis: 30-60 minutes (hypothesis testing, dead ends)
- Fix implementation: 15-30 minutes (same)
- Post-mortem: 45-60 minutes (writing from memory, gathering data)
- **Total: 2-3 hours**

**With incident-handler:**
- Context gathering: 5 minutes (automated via agent)
- Root cause analysis: 10-15 minutes (guided with evidence)
- Fix implementation: 15-30 minutes (same, but with plan review)
- Post-mortem: 10 minutes (auto-generated)
- **Total: 40-60 minutes**

**Savings: 60-70% reduction in overhead (1-2 hours saved per incident)**