# /incident

Declare incidents, manage response, write postmortems, and configure SLO burn rate alerts.

## Usage

```
/incident declare|manage|postmortem|alert [options]
```

## Actions

### `declare`
Declare an incident and generate initial communication.

```
# Incident declaration checklist:
1. Open bridge: Zoom/Meet link shared in #incidents
2. Create incident ticket (PagerDuty/Linear/Jira)
3. Post in #incidents: severity, impact, bridge link, IC
4. Update status page: acknowledge impact (don't explain yet)
5. Page stakeholders based on severity
```

```bash
# PagerDuty API: Create incident
curl -X POST https://api.pagerduty.com/incidents \
  -H "Authorization: Token token=$PD_API_KEY" \
  -H "From: oncall@example.com" \
  -H "Content-Type: application/json" \
  -d '{
    "incident": {
      "type": "incident",
      "title": "Payment processing error rate elevated",
      "service": {
        "id": "PAYMENTS_SERVICE_ID",
        "type": "service_reference"
      },
      "urgency": "high",
      "body": {
        "type": "incident_body",
        "details": "Error rate at 4.3%, normal baseline 0.02%. Users unable to complete checkout."
      }
    }
  }'

# StatusPage API: Create incident
curl -X POST "https://api.statuspage.io/v1/pages/$PAGE_ID/incidents" \
  -H "Authorization: OAuth $STATUSPAGE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "incident": {
      "name": "Payment Processing Issues",
      "status": "investigating",
      "body": "We are investigating reports of issues with payment processing. Some users may be unable to complete purchases.",
      "components": {"$COMPONENT_ID": "degraded_performance"},
      "deliver_notifications": true
    }
  }'
```

### `manage`
Active incident management commands.

```bash
# Quick diagnosis commands for common scenarios

# Check recent deployments (first thing to check)
kubectl rollout history deployment/myapp -n production
kubectl rollout history deployment/myapp -n production --revision=N

# Check pod health
kubectl get pods -n production -o wide
kubectl describe pod <pod-name> -n production | tail -20
kubectl logs <pod-name> -n production --previous  # Crashed container logs

# Check error rate (Prometheus)
promtool query instant http://prometheus:9090 \
  "rate(http_requests_total{status=~'5..',service='myapp'}[5m]) / rate(http_requests_total{service='myapp'}[5m])"

# Rollback deployment (fastest mitigation for bad deploy)
kubectl rollout undo deployment/myapp -n production
kubectl rollout status deployment/myapp -n production

# Scale down (reduce load to failing service)
kubectl scale deployment/myapp --replicas=1 -n production

# Check external dependencies
curl -w "@curl-format.txt" -o /dev/null -s https://api.stripe.com/v1/charges
dig +short api.stripe.com   # DNS resolution check
traceroute api.stripe.com   # Network path

# Database: check for blocking locks
psql -h db.prod -c "
  SELECT blocked_locks.pid, blocking_activity.query, now() - blocked_activity.query_start AS age
  FROM pg_locks blocked_locks
  JOIN pg_stat_activity blocked_activity ON blocked_activity.pid = blocking_locks.pid
  WHERE NOT blocked_locks.GRANTED
  LIMIT 10;
"

# Update status page during incident
curl -X PATCH "https://api.statuspage.io/v1/pages/$PAGE_ID/incidents/$INCIDENT_ID" \
  -H "Authorization: OAuth $STATUSPAGE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"incident": {"status": "identified", "body": "Root cause identified: database connection pool exhausted. Mitigation in progress."}}'
```

### `postmortem`
Generate a postmortem from incident data.

```bash
# Pull deployment history for timeline reconstruction
kubectl rollout history deployment/myapp -n production -o json | \
  jq '.items[] | {revision: .metadata.annotations["deployment.kubernetes.io/revision"], time: .metadata.creationTimestamp}'

# Pull error rate timeline from Prometheus
promtool query range http://prometheus:9090 \
  --start=$(date -d '-3 hours' --iso-8601=seconds) \
  --end=$(date --iso-8601=seconds) \
  --step=1m \
  "rate(http_requests_total{status=~'5..'}[5m]) / rate(http_requests_total[5m])"

# Pull logs from incident time window
kubectl logs -n production deployment/myapp \
  --since-time="2024-01-15T14:30:00Z" \
  --until-time="2024-01-15T15:15:00Z" | \
  grep -E "(ERROR|FATAL|Exception)" | head -50

# Loki LogQL for incident logs
logcli query '{namespace="production",app="myapp"} |= "ERROR"' \
  --from="2024-01-15T14:30:00Z" \
  --to="2024-01-15T15:15:00Z" \
  --limit=200
```

### `alert`
Configure SLO burn rate alerts.

```yaml
# Alertmanager routing for incident severity
# alertmanager/config.yml
route:
  receiver: default
  group_by: [alertname, service]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h

  routes:
    - match:
        severity: critical
      receiver: pagerduty-critical
      repeat_interval: 1h
      continue: true

    - match:
        severity: warning
      receiver: slack-warnings
      group_wait: 5m

receivers:
  - name: pagerduty-critical
    pagerduty_configs:
      - service_key: $PAGERDUTY_SERVICE_KEY
        description: '{{ template "pagerduty.default.description" . }}'
        details:
          runbook: '{{ (index .Alerts 0).Annotations.runbook }}'
          dashboard: '{{ (index .Alerts 0).Annotations.dashboard }}'

  - name: slack-warnings
    slack_configs:
      - api_url: $SLACK_WEBHOOK
        channel: '#alerts'
        title: '{{ template "slack.default.title" . }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

inhibit_rules:
  # Suppress warnings when critical is firing for same service
  - source_match:
      severity: critical
    target_match:
      severity: warning
    equal: [service]
```
