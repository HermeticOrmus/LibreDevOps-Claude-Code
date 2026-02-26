# Monitoring & Observability Plugin

Prometheus, Grafana, Thanos, OpenTelemetry, SLO alerting, and distributed tracing with Tempo/Jaeger.

## Components

- **Agent**: `observability-engineer` -- PromQL, SLO burn rate alerting, OTel instrumentation, cardinality management, Thanos multi-cluster
- **Command**: `/monitor` -- Queries metrics, manages silences, exports dashboards, checks SLO budgets, debugs pipelines
- **Skill**: `observability-patterns` -- kube-prometheus-stack Helm, OTel Collector config, Thanos sidecar, Grafana provisioning, error budget PromQL

## Quick Reference

```bash
# Check firing alerts
curl -s http://prometheus:9090/api/v1/alerts | jq '.data.alerts[] | select(.state=="firing")'

# Current error rate
curl -s "http://prometheus:9090/api/v1/query" \
  --data-urlencode 'query=sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))'

# Silence an alert for 2h
curl -X POST http://alertmanager:9093/api/v2/silences -d \
  '{"matchers":[{"name":"alertname","value":"HighCPU"}],"startsAt":"now","endsAt":"now+2h","comment":"maintenance"}'

# P99 latency
curl -s "http://prometheus:9090/api/v1/query" \
  --data-urlencode 'query=histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))'
```

## SLO Alerting Thresholds (99.9% SLO)

| Severity | Burn Rate | Window | Consumes Budget In |
|----------|-----------|--------|-------------------|
| Critical (page) | 14.4x | 5m + 1h | ~50h (5% in 1h) |
| Warning (ticket) | 6x | 30m + 6h | ~5d (10% in 3d) |
| Info | 1x | 6h + 3d | 30d (slow leak) |

## The Four Golden Signals

1. **Latency**: P50/P99 request duration (use histogram, not summary)
2. **Traffic**: Request rate (requests/sec per service)
3. **Errors**: Error ratio (5xx / total)
4. **Saturation**: CPU throttling, memory pressure, queue depth

## Related Plugins

- [log-management](../log-management/) -- Loki log aggregation, Promtail
- [incident-management](../incident-management/) -- SLO alerting -> PagerDuty
- [kubernetes-operations](../kubernetes-operations/) -- kube-state-metrics, node-exporter
- [service-mesh](../service-mesh/) -- Istio metrics, distributed tracing
