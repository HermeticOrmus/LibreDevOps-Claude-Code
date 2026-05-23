# Quick start

Ten minutes from clone to your first proper k8s deployment.

## Install

```bash
git clone https://github.com/HermeticOrmus/LibreDevOps-Claude-Code.git ~/projects/LibreDevOps-Claude-Code
cd ~/projects/LibreDevOps-Claude-Code
./setup.sh
```

Restart Claude Code.

## Design a workload

```
/k8s design a Deployment for a stateless API. EKS 1.28. 4 replicas baseline, autoscale to 20 on CPU 70% + custom metric (req/sec). Anti-affinity across 3 zones. PDB minimum 2. NetworkPolicy: ingress from nginx-ingress namespace only; egress to postgres on 5432 + DNS only.
```

Expected output: full YAML with Deployment, Service, ServiceAccount, Role, RoleBinding, PDB, HPA, NetworkPolicy (3 — default-deny, ingress, egress). With reasoning for each setting.

If the response uses default ServiceAccount or skips NetworkPolicy, the plugin didn't install correctly.

## Debug a failure

```
/k8s my pod is in CrashLoopBackOff. Container exits with code 1 after ~5 seconds. liveness probe is HTTP GET / on port 8080 with initialDelaySeconds: 5. Diagnose.
```

The agent should walk: probe firing before app booted, check `kubectl logs --previous`, add startup probe with generous failureThreshold, then keep liveness for actual hangs.

## Next

- [Beginner](learning-paths/beginner.md)
- [Intermediate](learning-paths/intermediate.md)
- [Advanced](learning-paths/advanced.md)
