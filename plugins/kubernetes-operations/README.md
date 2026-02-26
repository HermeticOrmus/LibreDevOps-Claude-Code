# Kubernetes Operations Plugin

Deployments, HPA/KEDA, Helm charts, PodDisruptionBudgets, NetworkPolicy, kubectl debugging, and cluster upgrades.

## Components

- **Agent**: `k8s-engineer` -- Rolling updates, HPA/KEDA, Helm chart authoring, NetworkPolicy, PDB, debug techniques
- **Command**: `/k8s` -- Deploys with Helm, scales workloads, debugs pods with ephemeral containers, manages rollouts
- **Skill**: `k8s-patterns` -- Production Deployment YAML, Helm values pattern, KEDA ScaledObject, LimitRange, upgrade checklist

## Quick Reference

```bash
# Deploy with Helm (atomic rollback on failure)
helm upgrade --install myapp ./charts/myapp \
  -n production --values values-prod.yaml \
  --set image.tag=$TAG --wait --atomic

# Check rollout status
kubectl rollout status deployment/myapp -n production

# Debug a failing pod
kubectl describe pod $POD -n production | tail -30
kubectl logs $POD -n production --previous

# Ephemeral container for distroless images
kubectl debug -it pod/$POD --image=busybox --target=myapp -n production

# Rollback
kubectl rollout undo deployment/myapp -n production
helm rollback myapp 1 -n production

# Resource usage
kubectl top pods -n production --sort-by=cpu
```

## Critical Configs for Production

**Readiness probe**: Required. Without it, Kubernetes routes traffic to pods that aren't ready. Use `/ready` endpoint (checks DB connectivity, etc.) separate from `/health`.

**Resource requests and limits**: Required. Without requests, scheduler can't make placement decisions. Without limits, a memory leak takes down the node.

**PodDisruptionBudget**: Required for HA. Without PDB, node drains or upgrades can take all pods offline simultaneously.

**topologySpreadConstraints**: Spread pods across zones to survive AZ failures. Use `topology.kubernetes.io/zone` key.

**terminationGracePeriodSeconds + preStop sleep**: Allows in-flight requests to complete before pod shutdown. Set to > your request timeout.

## Related Plugins

- [helm](../release-management/) -- Helm via Argo Rollouts and GitOps
- [monitoring-observability](../monitoring-observability/) -- Prometheus metrics from K8s workloads
- [secret-management](../secret-management/) -- External Secrets Operator for K8s secrets
- [service-mesh](../service-mesh/) -- Istio/Linkerd for inter-pod mTLS and traffic management
