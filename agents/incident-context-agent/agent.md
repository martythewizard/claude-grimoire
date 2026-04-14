---
name: incident-context-agent
description: Query Firehydrant, Coralogix, and affected services to gather comprehensive incident context
version: 1.0.0
author: claude-grimoire
agent_type: autonomous
invocable_by:
  - incident-handler
  - incident-response-team
---

# Incident Context Agent

Autonomous agent that gathers comprehensive incident context from multiple sources including Firehydrant, Coralogix logs/metrics, recent deployments, and service-specific data. Returns structured incident intelligence for rapid diagnosis.

## Purpose

Automate the time-consuming process of gathering incident context:
- Fetch incident details from Firehydrant
- Query relevant logs from Coralogix
- Retrieve metrics and traces
- Identify recent deployments and config changes
- Gather service-specific data via company CLI
- Correlate events across sources

## Input Contract

```json
{
  "incident_id": "string (optional) - Firehydrant incident ID",
  "alert_description": "string (optional) - If no Firehydrant incident",
  "timeframe": "string (required) - Time window (1h, 4h, 24h, custom)",
  "services": ["array (required) - Affected service names"],
  "gather": {
    "logs": "boolean (default: true)",
    "metrics": "boolean (default: true)",
    "traces": "boolean (default: true)",
    "deployments": "boolean (default: true)",
    "config_changes": "boolean (default: true)"
  },
  "custom_timeframe": {
    "start": "ISO 8601 timestamp (optional)",
    "end": "ISO 8601 timestamp (optional)"
  }
}
```

## Output Contract

```json
{
  "incident": {
    "id": "string - Firehydrant incident ID",
    "url": "string - Firehydrant incident URL",
    "severity": "string - P0/P1/P2/P3/P4",
    "status": "string - open/investigating/resolved",
    "started_at": "ISO 8601 timestamp",
    "duration_minutes": "number",
    "title": "string",
    "description": "string",
    "affected_services": ["array - Service names"]
  },
  "symptoms": {
    "error_rate": {
      "baseline": "number - Normal error rate",
      "current": "number - Current error rate",
      "spike_factor": "number - How many times higher"
    },
    "latency": {
      "baseline_p95": "number ms",
      "current_p95": "number ms",
      "degradation_factor": "number"
    },
    "traffic": {
      "baseline_rps": "number",
      "current_rps": "number",
      "change_percent": "number"
    },
    "user_reports": "number - Support tickets/complaints"
  },
  "logs": {
    "errors": [
      {
        "timestamp": "ISO 8601",
        "level": "ERROR",
        "message": "string",
        "service": "string",
        "count": "number - Occurrences in timeframe",
        "sample": "string - Full log entry"
      }
    ],
    "warnings": ["array - Similar structure"],
    "patterns": [
      {
        "pattern": "string - Log pattern",
        "frequency": "number - Times seen",
        "first_seen": "ISO 8601",
        "services": ["array - Where this appears"]
      }
    ]
  },
  "metrics": {
    "anomalies": [
      {
        "metric": "string - Metric name",
        "service": "string",
        "baseline": "number",
        "current": "number",
        "change": "string - e.g., +150%",
        "anomaly_score": "number 0-1"
      }
    ],
    "correlated_changes": [
      {
        "metric": "string",
        "correlation": "number - Correlation coefficient",
        "timing": "string - e.g., 2 minutes before errors"
      }
    ]
  },
  "traces": {
    "slow_operations": [
      {
        "operation": "string",
        "baseline_ms": "number",
        "current_ms": "number",
        "sample_trace_id": "string"
      }
    ],
    "failed_operations": [
      {
        "operation": "string",
        "error_rate": "number",
        "error_types": ["array - Error messages"]
      }
    ]
  },
  "recent_changes": {
    "deployments": [
      {
        "service": "string",
        "version": "string",
        "deployed_at": "ISO 8601",
        "minutes_before_incident": "number",
        "deployment_method": "string - rolling/canary/blue-green",
        "author": "string",
        "pr_url": "string"
      }
    ],
    "config_changes": [
      {
        "file": "string",
        "change": "string - What changed",
        "changed_at": "ISO 8601",
        "minutes_before_incident": "number",
        "author": "string"
      }
    ]
  },
  "hypotheses": [
    {
      "hypothesis": "string - Possible root cause",
      "confidence": "string - high/medium/low",
      "evidence": ["array - Supporting evidence"],
      "counter_evidence": ["array - Evidence against"],
      "next_steps": ["array - How to validate"]
    }
  ],
  "summary": "string - Human-readable summary of context"
}
```

## Capabilities

### 1. Firehydrant Integration

**Fetch incident details:**

```bash
# Get incident
curl "https://api.firehydrant.io/v1/incidents/${incident_id}" \
  -H "Authorization: Bearer $FIREHYDRANT_API_KEY"

# Extract:
- Severity (P0-P4)
- Start time
- Status
- Affected services
- Description
- Timeline events
```

**Get incident timeline:**

```bash
# Fetch timeline
curl "https://api.firehydrant.io/v1/incidents/${incident_id}/timeline" \
  -H "Authorization: Bearer $FIREHYDRANT_API_KEY"

# Extract:
- When alert fired
- When investigation started
- Status changes
- Notes and updates
```

### 2. Coralogix Logs Integration

**Query error logs:**

```bash
# Using Coralogix API
curl "https://api.coralogix.${region}.com/api/v1/logs/query" \
  -H "Authorization: Bearer $CORALOGIX_API_KEY" \
  -d '{
    "query": "level:ERROR AND service:${service}",
    "from": "'${start_time}'",
    "to": "'${end_time}'",
    "limit": 1000
  }'
```

**Identify log patterns:**

```python
# Pseudocode for pattern detection
patterns = {}
for log in logs:
    # Extract pattern (remove variable parts)
    pattern = extract_pattern(log.message)
    patterns[pattern] += 1

# Sort by frequency
top_patterns = sorted(patterns, key=lambda x: x.count, reverse=True)
```

**Find correlated errors:**

```sql
-- Coralogix DataPrime query
source logs
| filter severity == 'error'
| filter timestamp >= now() - 1h
| summarize count() by service, error_type
| sort count desc
| head 20
```

### 3. Coralogix Metrics Integration

**Query key metrics:**

```bash
# Error rate
curl "https://api.coralogix.${region}.com/api/v1/metrics/query" \
  -d '{
    "query": "rate(http_requests_total{status=~\"5..\"}[5m])",
    "from": "'${start_time}'",
    "to": "'${end_time}'"
  }'

# Response time
curl "https://api.coralogix.${region}.com/api/v1/metrics/query" \
  -d '{
    "query": "histogram_quantile(0.95, http_request_duration_seconds)",
    "from": "'${start_time}'",
    "to": "'${end_time}'"
  }'
```

**Detect anomalies:**

```python
# Calculate baseline (1 week ago, same hour)
baseline_start = incident_time - timedelta(days=7, hours=1)
baseline_end = incident_time - timedelta(days=7)

baseline = query_metric(metric, baseline_start, baseline_end)
current = query_metric(metric, incident_start, incident_end)

if current > baseline * 2:  # 2x spike
    anomaly_detected(metric, baseline, current)
```

### 4. Coralogix Traces Integration

**Find slow operations:**

```bash
# Query for slow traces
curl "https://api.coralogix.${region}.com/api/v1/traces/query" \
  -d '{
    "query": "duration > 1000ms",
    "service": "'${service}'",
    "from": "'${start_time}'",
    "to": "'${end_time}'",
    "limit": 100
  }'
```

**Analyze trace spans:**

```python
# Find bottleneck in trace
def analyze_trace(trace_id):
    spans = get_trace_spans(trace_id)
    
    # Find slowest span
    slowest = max(spans, key=lambda s: s.duration)
    
    # Find external calls
    external_calls = [s for s in spans if s.type == 'external']
    
    # Find database queries
    db_queries = [s for s in spans if s.type == 'database']
    
    return {
        'bottleneck': slowest,
        'external_calls': external_calls,
        'db_queries': db_queries
    }
```

### 5. Deployment Tracking

**Query recent deployments:**

```bash
# If using Kubernetes
kubectl get events --all-namespaces \
  --field-selector type=Normal,reason=Deployed \
  --since="${start_time}"

# Extract:
- Service name
- Version/tag
- Deployment time
- Deployment method
```

**Correlate with incident:**

```python
def correlate_deployments(incident_time, deployments):
    recent = []
    for deploy in deployments:
        minutes_before = (incident_time - deploy.time).total_seconds() / 60
        
        # Deployments within 1 hour before incident
        if 0 < minutes_before < 60:
            recent.append({
                'deployment': deploy,
                'minutes_before_incident': minutes_before
            })
    
    return sorted(recent, key=lambda x: x['minutes_before_incident'])
```

### 6. Configuration Changes

**Track config changes:**

```bash
# If configs in git
git log --since="${start_time}" --until="${end_time}" \
  --pretty=format:"%H|%an|%ad|%s" \
  -- config/

# If configs in ConfigMaps
kubectl get configmaps --all-namespaces \
  -o json | jq '.items[] | select(.metadata.annotations.changed > "'${start_time}'")'
```

### 7. Service-Specific Queries

**Use company CLI:**

```bash
# Health check
company-cli service status ${service}

# Connection pools
company-cli db pool-status ${service}

# Cache stats
company-cli cache stats ${service}

# Queue depths
company-cli queue depth ${service}
```

**Parse CLI output:**

```python
def query_service_health(service):
    # Run CLI command
    output = subprocess.check_output(['company-cli', 'service', 'status', service])
    
    # Parse output
    health = parse_cli_output(output)
    
    return {
        'healthy': health.status == 'ok',
        'checks': health.checks,
        'dependencies': health.dependencies
    }
```

### 8. Hypothesis Generation

**Correlate evidence:**

```python
def generate_hypotheses(context):
    hypotheses = []
    
    # Hypothesis: Recent deployment
    if context.recent_changes.deployments:
        deploy = context.recent_changes.deployments[0]
        if deploy.minutes_before_incident < 10:
            hypotheses.append({
                'hypothesis': f'Deployment of {deploy.service} v{deploy.version} caused issue',
                'confidence': 'high',
                'evidence': [
                    f'Deployed {deploy.minutes_before_incident} min before incident',
                    f'Errors started at same time as deployment',
                    f'Service: {deploy.service} matches affected service'
                ],
                'next_steps': [
                    'Check deployment logs',
                    'Compare v{deploy.version} with previous version',
                    'Consider rollback'
                ]
            })
    
    # Hypothesis: Resource exhaustion
    if context.metrics.anomalies:
        for anomaly in context.metrics.anomalies:
            if 'memory' in anomaly.metric or 'cpu' in anomaly.metric:
                hypotheses.append({
                    'hypothesis': f'{anomaly.service} resource exhaustion',
                    'confidence': 'medium',
                    'evidence': [
                        f'{anomaly.metric}: {anomaly.baseline} → {anomaly.current} ({anomaly.change})',
                        f'Error logs show OOM or timeout errors'
                    ],
                    'next_steps': [
                        'Check pod resource limits',
                        'Look for memory leaks',
                        'Scale up if needed'
                    ]
                })
    
    # Hypothesis: External dependency
    if context.traces.slow_operations:
        for op in context.traces.slow_operations:
            if 'external' in op.operation or 'api' in op.operation:
                hypotheses.append({
                    'hypothesis': f'External dependency {op.operation} degraded',
                    'confidence': 'low',
                    'evidence': [
                        f'{op.operation}: {op.baseline_ms}ms → {op.current_ms}ms',
                        'Only affecting some requests'
                    ],
                    'next_steps': [
                        'Check external service status page',
                        'Verify API key/auth is valid',
                        'Consider circuit breaker'
                    ]
                })
    
    # Sort by confidence
    return sorted(hypotheses, key=lambda h: confidence_score(h.confidence), reverse=True)
```

## Agent Workflow

When invoked, the agent follows this process:

### 1. Validate Inputs

```python
def validate_inputs(params):
    # Required fields
    if not params.timeframe and not params.custom_timeframe:
        raise ValueError("timeframe or custom_timeframe required")
    
    if not params.services:
        raise ValueError("services array required")
    
    # API keys
    if params.gather.logs and not os.getenv('CORALOGIX_API_KEY'):
        raise ValueError("CORALOGIX_API_KEY not set")
    
    if params.incident_id and not os.getenv('FIREHYDRANT_API_KEY'):
        raise ValueError("FIREHYDRANT_API_KEY not set")
```

### 2. Fetch Firehydrant Context (if incident_id provided)

```python
def fetch_firehydrant_context(incident_id):
    incident = get_firehydrant_incident(incident_id)
    timeline = get_firehydrant_timeline(incident_id)
    
    return {
        'incident': incident,
        'timeline': timeline,
        'started_at': incident.created_at,
        'services': incident.services
    }
```

### 3. Query Logs

```python
def query_logs(services, start_time, end_time):
    all_errors = []
    all_warnings = []
    
    for service in services:
        # Error logs
        errors = coralogix_query(
            f'level:ERROR AND service:{service}',
            start_time, end_time
        )
        all_errors.extend(errors)
        
        # Warning logs
        warnings = coralogix_query(
            f'level:WARN AND service:{service}',
            start_time, end_time
        )
        all_warnings.extend(warnings)
    
    # Identify patterns
    patterns = identify_log_patterns(all_errors)
    
    return {
        'errors': aggregate_errors(all_errors),
        'warnings': aggregate_errors(all_warnings),
        'patterns': patterns
    }
```

### 4. Query Metrics

```python
def query_metrics(services, start_time, end_time):
    anomalies = []
    
    for service in services:
        # Key metrics
        metrics = [
            'error_rate',
            'response_time_p95',
            'request_rate',
            'cpu_usage',
            'memory_usage',
            'db_connection_pool'
        ]
        
        for metric in metrics:
            current = get_metric(service, metric, start_time, end_time)
            baseline = get_metric_baseline(service, metric)
            
            if is_anomalous(current, baseline):
                anomalies.append({
                    'metric': metric,
                    'service': service,
                    'baseline': baseline,
                    'current': current,
                    'change': calculate_change(baseline, current),
                    'anomaly_score': calculate_anomaly_score(current, baseline)
                })
    
    return {'anomalies': anomalies}
```

### 5. Query Traces

```python
def query_traces(services, start_time, end_time):
    slow_ops = []
    failed_ops = []
    
    for service in services:
        # Find slow operations
        slow_traces = coralogix_traces_query(
            service, 'duration > 1000ms', start_time, end_time
        )
        
        for trace in slow_traces:
            analysis = analyze_trace(trace.id)
            slow_ops.append({
                'operation': trace.operation,
                'baseline_ms': get_baseline_latency(trace.operation),
                'current_ms': trace.duration,
                'bottleneck': analysis.bottleneck
            })
        
        # Find failed operations
        failed_traces = coralogix_traces_query(
            service, 'status:error', start_time, end_time
        )
        
        failed_ops.extend(aggregate_failed_operations(failed_traces))
    
    return {
        'slow_operations': slow_ops,
        'failed_operations': failed_ops
    }
```

### 6. Track Recent Changes

```python
def track_recent_changes(services, start_time, incident_time):
    deployments = []
    config_changes = []
    
    # Query deployments
    for service in services:
        deploys = get_recent_deployments(service, start_time, incident_time)
        
        for deploy in deploys:
            minutes_before = (incident_time - deploy.time).total_seconds() / 60
            deployments.append({
                'service': service,
                'version': deploy.version,
                'deployed_at': deploy.time,
                'minutes_before_incident': minutes_before,
                'author': deploy.author,
                'pr_url': deploy.pr_url
            })
    
    # Query config changes
    configs = get_config_changes(start_time, incident_time)
    for config in configs:
        minutes_before = (incident_time - config.time).total_seconds() / 60
        config_changes.append({
            'file': config.file,
            'change': config.diff,
            'changed_at': config.time,
            'minutes_before_incident': minutes_before,
            'author': config.author
        })
    
    return {
        'deployments': sorted(deployments, key=lambda d: d['minutes_before_incident']),
        'config_changes': sorted(config_changes, key=lambda c: c['minutes_before_incident'])
    }
```

### 7. Generate Hypotheses

```python
def generate_hypotheses(context):
    # Correlate all evidence
    hypotheses = []
    
    # Check for recent deployments
    hypotheses.extend(check_deployment_hypothesis(context))
    
    # Check for resource issues
    hypotheses.extend(check_resource_hypothesis(context))
    
    # Check for external dependencies
    hypotheses.extend(check_external_dependency_hypothesis(context))
    
    # Check for configuration
    hypotheses.extend(check_config_hypothesis(context))
    
    # Rank by confidence
    return rank_hypotheses(hypotheses)
```

### 8. Return Structured Output

```python
def return_output(context, hypotheses):
    return {
        'incident': context.incident,
        'symptoms': context.symptoms,
        'logs': context.logs,
        'metrics': context.metrics,
        'traces': context.traces,
        'recent_changes': context.recent_changes,
        'hypotheses': hypotheses,
        'summary': generate_summary(context, hypotheses)
    }
```

## Configuration

The agent respects configuration from `.claude-grimoire/config.json`:

```json
{
  "incidentContext": {
    "defaultTimeframe": "1h",
    "logLimit": 1000,
    "metricResolution": "1m",
    "traceLimit": 100
  },
  "firehydrant": {
    "apiUrl": "https://api.firehydrant.io",
    "orgSlug": "your-org",
    "apiKey": "${FIREHYDRANT_API_KEY}"
  },
  "coralogix": {
    "apiUrl": "https://api.coralogix.com",
    "region": "us",
    "apiKey": "${CORALOGIX_API_KEY}"
  }
}
```

## Examples

### Example 1: High Error Rate

**Input:**
```json
{
  "incident_id": "FH-abc123",
  "timeframe": "1h",
  "services": ["api-gateway", "user-service"]
}
```

**Output:**
```json
{
  "incident": {
    "id": "FH-abc123",
    "severity": "P1",
    "started_at": "2026-04-13T14:30:00Z",
    "title": "High 500 error rate on API gateway"
  },
  "symptoms": {
    "error_rate": {
      "baseline": 0.001,
      "current": 0.15,
      "spike_factor": 150
    }
  },
  "logs": {
    "errors": [
      {
        "message": "Database connection pool exhausted",
        "count": 1523,
        "first_seen": "2026-04-13T14:30:15Z"
      }
    ]
  },
  "metrics": {
    "anomalies": [
      {
        "metric": "db_connection_pool_utilization",
        "baseline": 0.6,
        "current": 1.0,
        "change": "+67%"
      }
    ]
  },
  "recent_changes": {
    "config_changes": [
      {
        "file": "config/rate-limits.yaml",
        "change": "requests_per_minute: 5000 → 10000",
        "minutes_before_incident": 10
      }
    ]
  },
  "hypotheses": [
    {
      "hypothesis": "Rate limit increase exhausted database connection pool",
      "confidence": "high",
      "evidence": [
        "Config change 10 min before incident",
        "Pool utilization at 100%",
        "Error logs: 'connection pool exhausted'"
      ]
    }
  ]
}
```

## Best Practices

### Do:
- ✅ Query multiple sources in parallel (logs, metrics, traces)
- ✅ Calculate baselines for anomaly detection
- ✅ Correlate timing of changes with incident start
- ✅ Rank hypotheses by confidence
- ✅ Include counter-evidence when relevant

### Don't:
- ❌ Return raw logs (aggregate and summarize)
- ❌ Ignore timing correlation
- ❌ Present hypotheses without evidence
- ❌ Query unlimited time ranges (use timeframe limits)
- ❌ Skip baseline comparison for metrics

## Success Criteria

Agent output is successful when:
- ✅ Context gathered in <5 minutes
- ✅ Top hypothesis matches actual root cause 80% of time
- ✅ Evidence clearly supports hypotheses
- ✅ Recent changes identified accurately
- ✅ Output is actionable for responder
- ✅ 60-70% time savings vs manual gathering