# Service Mesh Plugin

Istio mTLS, traffic management (VirtualService/DestinationRule), circuit breaking, Linkerd, Envoy proxy debugging, and L7 authorization policies.

## Components

- **Agent**: `mesh-engineer` -- Istio vs Linkerd selection, mTLS configuration, circuit breaker tuning, traffic splitting, JWT at the mesh level
- **Command**: `/service-mesh` -- Installs mesh, manages traffic policies, debugs Envoy config, checks mTLS status
- **Skill**: `mesh-patterns` -- Istio install, Ingress Gateway, Linkerd observability, traffic mirroring, JWT RequestAuthentication

## Quick Reference

```bash
# Check mTLS status across a namespace
istioctl authn tls-check -n production

# View VirtualService routing
kubectl describe virtualservice payment-api -n production

# Check Envoy clusters for a pod
istioctl proxy-config cluster $POD -n production

# Linkerd: real-time success rate per deployment
linkerd viz stat deploy -n production

# Analyze Istio config for issues
istioctl analyze -n production
```

## mTLS Status Modes

| Mode | Behavior |
|------|----------|
| STRICT | All traffic must use mTLS. Plaintext rejected. **Use in production.** |
| PERMISSIVE | Accept both mTLS and plaintext. **Migration only.** |
| DISABLE | No mTLS. **Never in production.** |

**Migration path**: Deploy new services -> set PERMISSIVE -> verify all pods injected -> set STRICT -> verify no plaintext traffic -> done.

## Circuit Breaker Tuning

Start conservative, tighten based on real data:

```yaml
outlierDetection:
  consecutive5xxErrors: 10   # Start high to avoid false ejections
  interval: 60s
  baseEjectionTime: 30s
  maxEjectionPercent: 50     # Never eject more than half the pool
```

If you set `maxEjectionPercent: 100` and have only 2 replicas, one bad deploy ejects all traffic. Keep it at 50% or less.

## Related Plugins

- [kubernetes-operations](../kubernetes-operations/) -- Pod networking, ServiceAccount for mesh auth
- [load-balancing](../load-balancing/) -- East-west (pod-to-pod) vs north-south (ingress) LB
- [monitoring-observability](../monitoring-observability/) -- Istio metrics in Prometheus, Kiali
- [infrastructure-security](../infrastructure-security/) -- mTLS as zero-trust network control
