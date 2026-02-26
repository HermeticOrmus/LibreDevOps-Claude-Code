# Incident Management Plugin

P1-P4 severity matrix, on-call rotation (PagerDuty/OpsGenie), SLO burn rate alerting, postmortem templates, and runbook structure.

## Components

- **Agent**: `incident-commander` -- Severity classification, response coordination, burn rate alerting, blameless postmortems
- **Command**: `/incident` -- Declares incidents, provides diagnosis commands, generates postmortem structure, configures Alertmanager
- **Skill**: `incident-patterns` -- PagerDuty Terraform, multi-window SLO alerts, postmortem template, Slack channel format

## When to Use

- Declaring and managing active P1/P2 incidents
- Designing on-call rotation schedules and escalation policies
- Writing SLO burn rate alerting rules (fast burn + slow burn windows)
- Conducting blameless postmortems with timeline reconstruction
- Building runbooks for common failure scenarios
- Configuring Alertmanager routing and notification channels

## Quick Reference

```bash
# Check recent deployments (first step in any incident)
kubectl rollout history deployment/myapp -n production

# Roll back bad deployment
kubectl rollout undo deployment/myapp -n production

# Check pod health
kubectl get pods -n production -o wide
kubectl describe pod <pod> -n production | tail -20
kubectl logs <pod> -n production --previous

# PagerDuty: create incident via API
curl -X POST https://api.pagerduty.com/incidents \
  -H "Authorization: Token token=$PD_API_KEY" \
  -H "From: oncall@example.com" \
  -d '{"incident": {"type": "incident", "title": "...", "urgency": "high"}}'
```

## SLO Burn Rate Math

99.9% SLO = 43.8 minutes/month error budget:
- **14.4x burn rate** = budget depleted in 72 minutes (fast burn, P1)
- **6x burn rate** = budget depleted in ~5 hours (slow burn, P2)
- **1x burn rate** = exactly on target (do nothing)

Multi-window alerting: check both 1hr/5min (fast burn) AND 6hr/30min (slow burn) windows. Short-duration spikes won't page; sustained slow burns will.

## Related Plugins

- [monitoring-observability](../monitoring-observability/) -- Prometheus alerting rules, Grafana dashboards
- [log-management](../log-management/) -- Log aggregation for timeline reconstruction
- [kubernetes-operations](../kubernetes-operations/) -- kubectl diagnosis commands
- [database-operations](../database-operations/) -- DB lock investigation during incidents
