# Intermediate — multi-env + observability + IR

## Multi-environment

- Dev / staging / prod as separate clusters or namespaces
- GitOps (Argo CD, Flux) for declarative promotion
- Promotion = merging a PR, not running a script
- Secrets per env via External Secrets Operator or Vault

## Observability

SLI/SLO/SLA:
- SLI: what you measure (p99 latency, error rate)
- SLO: what you target (99.9% requests < 500ms)
- SLA: what you promise to customers (uptime guarantees)

Stack: Prometheus + Grafana + Loki + Tempo + OpenTelemetry instrumentation.

## Incident response

Playbooks per scenario. Tabletop exercises quarterly. PagerDuty rotation. Blameless postmortems with action items tracked to completion.

## Next: [Advanced](advanced.md)
