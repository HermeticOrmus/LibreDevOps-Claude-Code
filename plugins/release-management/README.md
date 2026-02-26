# Release Management Plugin

GitOps with ArgoCD, canary deployments with Argo Rollouts, Helm release management, semantic versioning, and blue/green deployments.

## Components

- **Agent**: `release-manager` -- Deployment strategy selection, Argo Rollouts canary with analysis, ArgoCD GitOps, semantic-release automation
- **Command**: `/release` -- Deploys with Helm/ArgoCD, promotes canaries, rolls back releases, checks deployment status
- **Skill**: `release-patterns` -- ArgoCD ApplicationSet, GitHub Actions semantic release pipeline, ECS blue/green Terraform, .releaserc config, rollback runbook

## Quick Reference

```bash
# Deploy with Helm (safe: atomic rollback)
helm upgrade --install myapp ./charts/myapp \
  -n production --values values-prod.yaml \
  --set image.tag=$TAG --wait --atomic

# Check what will change before deploying
helm diff upgrade myapp ./charts/myapp --values values-prod.yaml --set image.tag=$TAG

# Rollback Helm release
helm rollback myapp -n production --wait

# Argo Rollouts: watch canary progress
kubectl argo rollouts get rollout myapp -n production --watch

# Promote canary to next step
kubectl argo rollouts promote myapp -n production

# Abort canary and rollback
kubectl argo rollouts undo myapp -n production
```

## Deployment Strategy Decision

| Strategy | When | Rollback Time |
|----------|------|---------------|
| Rolling update | Default for most K8s apps | ~30s (kubectl rollout undo) |
| Canary + analysis | High-traffic, risky changes | Minutes (abort rollout) |
| Blue/Green | Stateless, need instant switch | Seconds (update LB) |
| Feature flags | Untested features, A/B tests | Instant (toggle flag) |

## ArgoCD Health Check

Apps are Healthy when all resources are healthy. If stuck:
1. `argocd app diff myapp` -- see what's out of sync
2. `argocd app sync myapp --prune` -- sync with pruning
3. Check pod events: `kubectl describe pod -n production -l app=myapp`

## Related Plugins

- [kubernetes-operations](../kubernetes-operations/) -- Helm, kubectl rollout commands
- [github-actions](../github-actions/) -- CI/CD pipelines for building images
- [container-registry](../container-registry/) -- ECR image push, image signing
- [monitoring-observability](../monitoring-observability/) -- Prometheus analysis for Argo Rollouts
