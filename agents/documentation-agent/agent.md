---
name: documentation-agent
description: Generate post-mortems and technical documentation from incident context and resolutions
version: 1.0.0
author: claude-grimoire
agent_type: autonomous
invocable_by:
  - incident-handler
  - incident-response-team
  - pr-autopilot-team
---

# Documentation Agent

Autonomous agent that generates comprehensive post-mortems, technical documentation, and runbooks from incident data. Produces well-structured markdown documents ready for sharing with teams and stakeholders.

## Purpose

Automate documentation generation to ensure:
- Consistent post-mortem format across all incidents
- Comprehensive capture of lessons learned
- Actionable follow-up items
- Knowledge base building
- Faster documentation turnaround (10 min vs 1 hour)

## Input Contract

### Post-Mortem Generation

```json
{
  "type": "post-mortem",
  "incident": {
    "id": "string - Incident identifier",
    "title": "string - Incident title",
    "severity": "string - P0/P1/P2/P3/P4",
    "started_at": "ISO 8601 timestamp",
    "resolved_at": "ISO 8601 timestamp",
    "affected_services": ["array - Service names"],
    "impact": {
      "users_affected": "number",
      "error_rate": "number",
      "duration_minutes": "number",
      "business_impact": "string"
    }
  },
  "timeline": [
    {
      "timestamp": "ISO 8601",
      "event": "string - What happened",
      "actor": "string (optional) - Who did it"
    }
  ],
  "root_cause": {
    "primary": "string - Root cause description",
    "contributing_factors": ["array - Contributing factors"]
  },
  "resolution": {
    "immediate_actions": ["array - What was done to stop bleeding"],
    "permanent_fixes": ["array - What was done to prevent recurrence"],
    "code_changes": ["array (optional) - PRs or commits"],
    "config_changes": ["array (optional) - Config modifications"]
  },
  "prevention": {
    "process_improvements": ["array - Process changes"],
    "technical_improvements": ["array - Technical changes"],
    "monitoring_additions": ["array - New alerts/dashboards"]
  },
  "lessons_learned": {
    "what_went_well": ["array - Positive observations"],
    "what_could_improve": ["array - Areas for improvement"]
  },
  "action_items": [
    {
      "task": "string - What needs to be done",
      "priority": "string - P0/P1/P2/P3",
      "assignee": "string - Who will do it",
      "due_date": "ISO 8601 (optional)",
      "issue_number": "string (optional) - GitHub issue #"
    }
  ]
}
```

### Technical Documentation Generation

```json
{
  "type": "technical-doc",
  "title": "string - Document title",
  "purpose": "string - Why this doc exists",
  "audience": "string - engineers/operators/all",
  "content": {
    "overview": "string - High-level description",
    "architecture": "string (optional) - Architecture description",
    "diagrams": ["array (optional) - Mermaid diagram strings"],
    "components": [
      {
        "name": "string",
        "description": "string",
        "responsibilities": ["array"]
      }
    ],
    "usage": "string - How to use this",
    "examples": ["array (optional) - Code examples"],
    "troubleshooting": ["array (optional) - Common issues"]
  }
}
```

### Runbook Generation

```json
{
  "type": "runbook",
  "title": "string - Runbook title",
  "scenario": "string - When to use this",
  "severity": "string - P0/P1/P2/P3/P4",
  "steps": [
    {
      "step": "number",
      "action": "string - What to do",
      "command": "string (optional) - Command to run",
      "expected_output": "string (optional)",
      "troubleshooting": "string (optional) - If step fails"
    }
  ],
  "rollback": "string - How to undo if things go wrong",
  "contacts": ["array - Who to escalate to"]
}
```

## Output Contract

Returns formatted markdown document as string:

```json
{
  "document": "string - Complete markdown document",
  "metadata": {
    "type": "string - Document type",
    "generated_at": "ISO 8601 timestamp",
    "word_count": "number",
    "sections": ["array - Section titles"]
  },
  "file_path": "string - Suggested file path",
  "summary": "string - One-sentence summary"
}
```

## Capabilities

### 1. Post-Mortem Generation

**Structure:**

```markdown
# Post-Mortem: [Incident Title]

**Incident ID:** [ID]
**Date:** [Date]
**Duration:** [X minutes/hours]
**Severity:** [P0-P4]
**Impact:** [Brief impact statement]

## Executive Summary

[2-3 sentence summary for leadership]

## What Happened

[Narrative description of the incident from user perspective]

## Timeline

- **HH:MM UTC** - [Event description]
- **HH:MM UTC** - [Event description]
- ...

## Root Cause

**Primary:** [Root cause]

**Contributing Factors:**
1. [Factor 1]
2. [Factor 2]

## Impact

**User Impact:**
- [Number] users affected
- [Error rate] errors
- [Duration] of degraded service

**Business Impact:**
- [Support tickets/complaints]
- [Revenue impact if applicable]
- [Reputation/trust impact]

## Resolution

**Immediate Actions:**
1. [Action 1] - [Time]
2. [Action 2] - [Time]

**Permanent Fixes:**
1. [Fix 1] - [Details]
2. [Fix 2] - [Details]

## Prevention

**Process Improvements:**
1. ✅ [Improvement 1]
2. ✅ [Improvement 2]

**Technical Improvements:**
1. ✅ [Improvement 1] (Task #X)
2. ✅ [Improvement 2] (Task #Y)

**Monitoring:**
1. ✅ [New alert/dashboard]
2. ✅ [New metric]

## Lessons Learned

**What Went Well:**
- ✅ [Positive 1]
- ✅ [Positive 2]

**What Could Be Improved:**
- ⚠️  [Improvement area 1]
- ⚠️  [Improvement area 2]

## Action Items

- [ ] #[issue] - [Task] (P[priority], assigned: @[user], due: [date])
- [ ] #[issue] - [Task] (P[priority], assigned: @[user], due: [date])

## References

- Firehydrant: [URL]
- Logs: [URL]
- Metrics: [URL]
- Related post-mortems: [Links]

---
Generated with 🤖 [claude-grimoire](https://github.com/martythewizard/claude-grimoire)
```

### 2. Technical Documentation Generation

**Structure:**

```markdown
# [Title]

**Purpose:** [Why this document exists]
**Audience:** [Target audience]
**Last Updated:** [Date]

## Overview

[High-level description of system/feature/component]

## Architecture

[Architecture description]

```mermaid
[Architecture diagram]
```

## Components

### [Component 1]

**Purpose:** [What it does]

**Responsibilities:**
- [Responsibility 1]
- [Responsibility 2]

**Dependencies:**
- [Dependency 1]
- [Dependency 2]

### [Component 2]

[Similar structure]

## Usage

[How to use this system/feature]

### Example 1: [Use Case]

```language
[Code example]
```

**Output:**
```
[Expected output]
```

## Troubleshooting

### Issue: [Common Problem]

**Symptoms:**
- [Symptom 1]
- [Symptom 2]

**Diagnosis:**
```bash
[Diagnostic commands]
```

**Resolution:**
1. [Step 1]
2. [Step 2]

---
Generated with 🤖 [claude-grimoire](https://github.com/martythewizard/claude-grimoire)
```

### 3. Runbook Generation

**Structure:**

```markdown
# Runbook: [Title]

**Scenario:** [When to use this runbook]
**Severity:** [P0-P4]
**Estimated Time:** [X minutes]

## Prerequisites

- [Required access/tools]
- [Required knowledge]

## Steps

### Step 1: [Action]

**What to do:**
[Detailed instructions]

**Command:**
```bash
[Command to run]
```

**Expected output:**
```
[What you should see]
```

**Troubleshooting:**
If this fails: [What to try]

### Step 2: [Action]

[Similar structure]

## Verification

How to verify the issue is resolved:
- [ ] [Check 1]
- [ ] [Check 2]
- [ ] [Check 3]

## Rollback

If things go wrong:
1. [Rollback step 1]
2. [Rollback step 2]

## Escalation

If you can't resolve:
- **On-call:** [How to page]
- **Slack:** [#channel]
- **Experts:** @[user1], @[user2]

---
Generated with 🤖 [claude-grimoire](https://github.com/martythewizard/claude-grimoire)
```

## Agent Workflow

When invoked, the agent follows this process:

### 1. Validate Input

```python
def validate_input(params):
    if params.type == 'post-mortem':
        require_fields = ['incident', 'root_cause', 'resolution']
        for field in require_fields:
            if field not in params:
                raise ValueError(f"Missing required field: {field}")
    
    elif params.type == 'technical-doc':
        require_fields = ['title', 'content']
        # ...
    
    elif params.type == 'runbook':
        require_fields = ['title', 'steps']
        # ...
```

### 2. Generate Document Structure

```python
def generate_structure(params):
    if params.type == 'post-mortem':
        sections = [
            'title',
            'metadata',
            'executive_summary',
            'what_happened',
            'timeline',
            'root_cause',
            'impact',
            'resolution',
            'prevention',
            'lessons_learned',
            'action_items',
            'references'
        ]
    
    return sections
```

### 3. Generate Each Section

```python
def generate_section(section_name, data):
    if section_name == 'executive_summary':
        return generate_executive_summary(data)
    elif section_name == 'timeline':
        return generate_timeline(data.timeline)
    elif section_name == 'root_cause':
        return generate_root_cause(data.root_cause)
    # ...
```

**Executive Summary Generation:**

```python
def generate_executive_summary(data):
    # Extract key facts
    severity = data.incident.severity
    duration = data.incident.duration_minutes
    impact = data.incident.impact
    root_cause = data.root_cause.primary
    
    # Generate concise summary
    summary = f"""
On {format_date(data.incident.started_at)}, {data.incident.title}.
The incident lasted {duration} minutes, affecting {impact.users_affected} users
with a {impact.error_rate}% error rate. The root cause was {root_cause}.
The issue was resolved by {summarize_resolution(data.resolution)}.
"""
    
    return summary.strip()
```

**Timeline Generation:**

```python
def generate_timeline(timeline):
    lines = []
    
    for event in timeline:
        time = format_time(event.timestamp)
        actor = f" ({event.actor})" if event.actor else ""
        lines.append(f"- **{time}** - {event.event}{actor}")
    
    return "\n".join(lines)
```

**Root Cause Generation:**

```python
def generate_root_cause(root_cause):
    lines = []
    
    lines.append(f"**Primary:** {root_cause.primary}")
    lines.append("")
    
    if root_cause.contributing_factors:
        lines.append("**Contributing Factors:**")
        for i, factor in enumerate(root_cause.contributing_factors, 1):
            lines.append(f"{i}. {factor}")
    
    return "\n".join(lines)
```

### 4. Format and Style

```python
def apply_formatting(document):
    # Consistent heading levels
    document = normalize_headings(document)
    
    # Format code blocks
    document = format_code_blocks(document)
    
    # Format lists
    document = format_lists(document)
    
    # Add spacing
    document = add_spacing(document)
    
    return document
```

### 5. Add Metadata

```python
def add_metadata(document, params):
    metadata = {
        'type': params.type,
        'generated_at': datetime.now().isoformat(),
        'word_count': count_words(document),
        'sections': extract_sections(document)
    }
    
    return metadata
```

### 6. Suggest File Path

```python
def suggest_file_path(params):
    if params.type == 'post-mortem':
        date = format_date(params.incident.started_at, '%Y-%m-%d')
        slug = slugify(params.incident.title)
        return f"docs/post-mortems/{date}-{slug}.md"
    
    elif params.type == 'technical-doc':
        slug = slugify(params.title)
        return f"docs/technical/{slug}.md"
    
    elif params.type == 'runbook':
        slug = slugify(params.title)
        return f"docs/runbooks/{slug}.md"
```

### 7. Return Output

```python
def return_output(document, metadata, file_path):
    summary = generate_one_line_summary(document)
    
    return {
        'document': document,
        'metadata': metadata,
        'file_path': file_path,
        'summary': summary
    }
```

## Examples

### Example 1: Post-Mortem

**Input:**
```json
{
  "type": "post-mortem",
  "incident": {
    "id": "FH-abc123",
    "title": "Database connection pool exhaustion",
    "severity": "P1",
    "started_at": "2026-04-13T14:30:00Z",
    "resolved_at": "2026-04-13T15:15:00Z",
    "affected_services": ["api-gateway", "user-service"],
    "impact": {
      "users_affected": 5000,
      "error_rate": 15,
      "duration_minutes": 45,
      "business_impact": "47 support tickets, potential revenue loss"
    }
  },
  "root_cause": {
    "primary": "Database connection pool size (100) insufficient for 10k req/min traffic",
    "contributing_factors": [
      "Rate limit increase bypassed review",
      "No connection timeout configured",
      "Missing pool utilization monitoring"
    ]
  },
  "resolution": {
    "immediate_actions": [
      "Rolled back rate limit to 5k req/min",
      "Increased pool size to 300"
    ],
    "permanent_fixes": [
      "Added connection timeout (30s)",
      "Scaled pool to 300 permanently",
      "Added monitoring and alerting"
    ]
  }
}
```

**Output:**
Full post-mortem document (see Capabilities section for complete format)

---

### Example 2: Technical Documentation

**Input:**
```json
{
  "type": "technical-doc",
  "title": "Authentication System Architecture",
  "purpose": "Document JWT-based authentication system",
  "audience": "engineers",
  "content": {
    "overview": "JWT-based authentication with RS256 signing",
    "components": [
      {
        "name": "AuthService",
        "description": "Handles login, logout, token generation",
        "responsibilities": ["Token generation", "Token validation", "User authentication"]
      }
    ]
  }
}
```

**Output:**
Technical documentation with architecture diagrams and usage examples

---

### Example 3: Runbook

**Input:**
```json
{
  "type": "runbook",
  "title": "Restart stuck worker pods",
  "scenario": "Worker pods stuck in CrashLoopBackOff",
  "severity": "P2",
  "steps": [
    {
      "step": 1,
      "action": "Identify stuck pods",
      "command": "kubectl get pods -n workers | grep CrashLoopBackOff"
    },
    {
      "step": 2,
      "action": "Check pod logs",
      "command": "kubectl logs -n workers <pod-name> --tail=100"
    }
  ]
}
```

**Output:**
Step-by-step runbook with commands and troubleshooting

## Configuration

The agent respects configuration from `.claude-grimoire/config.json`:

```json
{
  "documentationAgent": {
    "postMortemTemplate": "default",
    "includeDiagrams": true,
    "wordWrap": 100,
    "outputFormat": "markdown"
  }
}
```

## Best Practices

### Do:
- ✅ Use clear, concise language
- ✅ Include specific times, numbers, and metrics
- ✅ Link to relevant resources (Firehydrant, logs, dashboards)
- ✅ Focus on learnings, not blame
- ✅ Make action items specific and assignable
- ✅ Include "what went well" not just problems

### Don't:
- ❌ Use vague language ("some users", "a while")
- ❌ Blame individuals
- ❌ Skip timeline details
- ❌ Forget prevention measures
- ❌ Leave action items unassigned
- ❌ Write from memory (use actual data)

## Success Criteria

Agent output is successful when:
- ✅ Post-mortem generated in <10 minutes (vs 1 hour manual)
- ✅ All required sections present
- ✅ Timeline is accurate and detailed
- ✅ Root cause clearly explained
- ✅ Action items are specific and actionable
- ✅ Document is ready to share without editing
- ✅ Team learns from incident

## Time Savings

**Traditional post-mortem writing:**
- Gather data from multiple sources: 20 minutes
- Write timeline: 15 minutes
- Explain root cause: 10 minutes
- Document resolution: 10 minutes
- Identify lessons and actions: 15 minutes
- Format and polish: 10 minutes
- **Total: 80 minutes**

**With documentation-agent:**
- Agent generates complete post-mortem: 2 minutes
- Human review and adjustments: 8 minutes
- **Total: 10 minutes**

**Savings: 70 minutes (87.5% reduction)