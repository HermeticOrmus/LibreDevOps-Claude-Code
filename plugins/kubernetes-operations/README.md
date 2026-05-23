# Kubernetes Operations

> Pod design, RBAC, NetworkPolicies, autoscaling, operator patterns. The k8s expertise that separates "works in lab" from "survives production traffic."

## Contents

- **Agent**: `k8s-engineer` — senior Kubernetes operator
- **Command**: `/k8s` — manifests, troubleshooting, design
- **Skill**: pattern library covering Pod design, RBAC, autoscaling, NetworkPolicies, ingress, common pitfalls

## Key capabilities

- **Pod design**: resource requests/limits (sizing, not magic numbers), liveness/readiness/startup probes (each does something different), PDBs, affinity/anti-affinity, topology spread
- **RBAC**: ServiceAccount per workload, Role vs ClusterRole, binding patterns, escape patterns to avoid
- **NetworkPolicies**: default-deny baseline, egress rules, namespace isolation, identity-based policies (Cilium, Calico)
- **Autoscaling**: HPA (CPU/memory + custom metrics), VPA (vertical), KEDA (event-driven), Cluster Autoscaler
- **Operator patterns**: CRDs, controller loops, when to write vs use existing operators
- **Ingress**: nginx, Traefik, gateway-api, TLS, rate limiting
- **Pod Security Standards**: Restricted vs Baseline vs Privileged; what gets blocked

## When to use

- Designing new k8s workloads
- Debugging "pod won't schedule," "OOMKilled," "ImagePullBackOff"
- Multi-tenancy design (namespaces, RBAC, network isolation)
- Custom operator design
- Migration from imperative kubectl to declarative GitOps

## Compatibility

- Kubernetes 1.27+ (older versions noted where APIs differ)
- All distributions: EKS, GKE, AKS, OCI OKE, on-prem (kubeadm, k3s, RKE2), kind/minikube for local
