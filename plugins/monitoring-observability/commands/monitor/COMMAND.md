# /monitor

Query metrics, manage alerts, inspect dashboards, and debug observability pipelines.

## Usage

```
/monitor query|alerts|dashboard|slo|debug [options]
```

## Actions

### `query`
Run PromQL queries and inspect metrics.

```bash
# Query Prometheus API directly
curl -s "http://prometheus:9090/api/v1/query" \
  --data-urlencode 'query=sum(rate(http_requests_total[5m])) by (service)' | \
  jq '.data.result[] | {service: .metric.service, rate: .value[1]}'

# Range query (time series data)
curl -s "http://prometheus:9090/api/v1/query_range" \
  --data-urlencode 'query=rate(http_requests_total[5m])' \
  --data-urlencode 'start=2024-01-15T00:00:00Z' \
  --data-urlencode 'end=2024-01-15T01:00:00Z' \
  --data-urlencode 'step=60'

# Check what metrics a service exposes
kubectl port-forward svc/myapp 8080:80 -n production &
curl -s http://localhost:8080/metrics | grep "^# HELP"

# Find high cardinality metrics (check label count)
curl -s "http://prometheus:9090/api/v1/label/__name__/values" | \
  jq '.data | length'

# Check active targets (scrape health)
curl -s "http://prometheus:9090/api/v1/targets" | \
  jq '.data.activeTargets[] | select(.health != "up") | {job: .labels.job, error: .lastError}'

# Check TSDB status (cardinality)
curl -s http://prometheus:9090/api/v1/status/tsdb | \
  jq '.data.seriesCountByMetricName | to_entries | sort_by(.value) | reverse | .[0:10]'
```

### `alerts`
Manage Prometheus alerting rules and Alertmanager.

```bash
# Check currently firing alerts
curl -s "http://prometheus:9090/api/v1/alerts" | \
  jq '.data.alerts[] | select(.state=="firing") | {name: .labels.alertname, severity: .labels.severity}'

# Check alert rule evaluation status
curl -s "http://prometheus:9090/api/v1/rules" | \
  jq '.data.groups[].rules[] | select(.type=="alerting") | {name: .name, state: .state}'

# Silence a noisy alert (during maintenance)
curl -X POST http://alertmanager:9093/api/v2/silences \
  -H "Content-Type: application/json" -d '{
    "matchers": [{"name": "alertname", "value": "HighCPU", "isRegex": false}],
    "startsAt": "2024-01-15T10:00:00.000Z",
    "endsAt": "2024-01-15T12:00:00.000Z",
    "comment": "Planned maintenance window",
    "createdBy": "ops-team"
  }'

# List active silences
curl -s http://alertmanager:9093/api/v2/silences | \
  jq '.[] | select(.status.state=="active") | {id: .id, comment: .comment, endsAt: .endsAt}'

# Delete a silence
curl -X DELETE http://alertmanager:9093/api/v2/silences/${SILENCE_ID}

# Reload Prometheus rules (after editing PrometheusRule CRDs)
curl -X POST http://prometheus:9090/-/reload

# Test PromQL alert expression
curl -s "http://prometheus:9090/api/v1/query" \
  --data-urlencode 'query=sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) > 0.01' | \
  jq '.data.result'
```

### `dashboard`
Manage Grafana dashboards.

```bash
# Export dashboard as JSON (for version control)
curl -s -u admin:$GRAFANA_PASSWORD \
  "http://grafana:3000/api/dashboards/uid/golden-signals" | \
  jq '.dashboard' > golden-signals.json

# Import dashboard from JSON
curl -X POST http://grafana:3000/api/dashboards/import \
  -H "Content-Type: application/json" \
  -u admin:$GRAFANA_PASSWORD \
  -d "{\"dashboard\": $(cat golden-signals.json), \"overwrite\": true, \"folderId\": 0}"

# List all dashboards
curl -s -u admin:$GRAFANA_PASSWORD \
  "http://grafana:3000/api/search?type=dash-db" | \
  jq '.[] | {uid: .uid, title: .title}'

# Check datasource health
curl -s -u admin:$GRAFANA_PASSWORD \
  "http://grafana:3000/api/datasources" | \
  jq '.[] | {name: .name, type: .type, url: .url}'

# Render a panel as PNG (for reports)
curl -s -u admin:$GRAFANA_PASSWORD \
  "http://grafana:3000/render/d-solo/golden-signals?panelId=1&from=now-1h&to=now&width=1000&height=500" \
  -o panel-screenshot.png
```

### `slo`
Track and report on SLO error budgets.

```bash
# Check current error budget remaining (via Prometheus)
# Assumes you have recording rule: job:http_error_ratio:rate30d
curl -s "http://prometheus:9090/api/v1/query" \
  --data-urlencode 'query=1 - (sum(increase(http_requests_total{status=~"5.."}[30d])) / (sum(increase(http_requests_total[30d])) * 0.001))' | \
  jq '.data.result[] | {service: .metric.service, budget_remaining: (.value[1] | tonumber | (. * 100 | round / 100))}'

# Current burn rate
curl -s "http://prometheus:9090/api/v1/query" \
  --data-urlencode 'query=(sum(rate(http_requests_total{status=~"5.."}[1h])) / sum(rate(http_requests_total[1h]))) / 0.001' | \
  jq '.data.result[] | "Burn rate: \(.value[1])x (14.4x = page-worthy)"'

# SLO report: downtime minutes in last 30d
# (for 99.9% SLO: budget is 43.8 min)
curl -s "http://prometheus:9090/api/v1/query" \
  --data-urlencode 'query=sum(increase(http_requests_total{status=~"5.."}[30d])) / sum(increase(http_requests_total[30d])) * 100' | \
  jq '.data.result[] | "Error rate last 30d: \(.value[1])%"'
```

### `debug`
Diagnose observability pipeline issues.

```bash
# Check if Prometheus is scraping a specific pod
curl -s "http://prometheus:9090/api/v1/targets" | \
  jq --arg pod "myapp-7d9f8b-xyz" \
  '.data.activeTargets[] | select(.labels.pod == $pod)'

# Check ServiceMonitor is picked up
kubectl get servicemonitor -n monitoring
kubectl describe servicemonitor myapp -n monitoring

# Verify OTEL collector is receiving spans
kubectl logs -n monitoring deploy/otel-collector | grep "traces\|spans" | tail -20

# Check trace sampling
kubectl exec -n monitoring deploy/otel-collector -- \
  wget -qO- http://localhost:8888/metrics | grep "otelcol_processor_tail_sampling"

# Verify Tempo receiving traces
kubectl logs -n monitoring deploy/tempo | tail -20
kubectl port-forward -n monitoring svc/tempo 3200:3200
curl http://localhost:3200/ready

# Check Grafana datasource connectivity
kubectl exec -n monitoring deploy/grafana -- \
  wget -qO- http://prometheus:9090/-/ready
kubectl exec -n monitoring deploy/grafana -- \
  wget -qO- http://loki:3100/ready
```
