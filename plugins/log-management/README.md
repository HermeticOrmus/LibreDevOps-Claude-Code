# Log Management Plugin

Structured logging, log aggregation pipelines (Fluent Bit, Vector, Promtail), Loki, OpenSearch/Elasticsearch, and log-based alerting.

## Components

- **Agent**: `log-engineer` -- Pipeline architecture, structured log formats, Loki vs OpenSearch selection, sampling strategy, cardinality control
- **Command**: `/logs` -- Searches logs, manages pipelines, configures retention, creates log-based alerts
- **Skill**: `log-patterns` -- Fluent Bit DaemonSet YAML, Loki Helm values, LogQL queries, OpenSearch index templates, Vector sampling config

## Quick Reference

```bash
# Tail production logs via LogCLI
logcli --addr=http://loki:3100 tail '{app="myapp",namespace="production"}'

# Search for errors in last hour
logcli query '{app="myapp"} |= "ERROR"' --since=1h --limit=100

# Check Fluent Bit pipeline metrics
kubectl exec -n logging daemonset/fluent-bit -- \
  curl -s http://localhost:2020/api/v1/metrics/prometheus

# Force Loki retention to apply
curl -X POST http://loki:3100/loki/api/v1/admin/compaction
```

## Cardinality Rules (Critical for Loki)

| Use as Label | Never Use as Label |
|-------------|-------------------|
| `app`, `namespace` | `user_id`, `request_id` |
| `level` (error/warn/info) | `trace_id`, `session_id` |
| `environment` | `email`, `ip_address` |
| `region` | `transaction_id` |

High cardinality labels create millions of streams and kill Loki performance. Put high-cardinality data in the log line, not the label.

## Pipeline Decision

- **Fluent Bit**: Default choice for Kubernetes node-level collection. Low memory (C binary, ~5MB RSS).
- **Fluentd**: Use when you need complex Ruby plugins or aggregation tier with 100+ sources.
- **Vector**: Use when you need complex log transformations (VRL language), fan-out to 5+ sinks, or sampling logic.
- **Promtail**: Use when you're already on the Grafana/Loki stack and don't need multi-sink.

## Related Plugins

- [monitoring-observability](../monitoring-observability/) -- Prometheus metrics, Grafana dashboards
- [kubernetes-operations](../kubernetes-operations/) -- kubectl log commands, pod debugging
- [incident-management](../incident-management/) -- Log-based alerting feeding into PagerDuty
- [infrastructure-security](../infrastructure-security/) -- CloudTrail log analysis, audit logging
