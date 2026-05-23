# Beginner — DevOps mindset

## Mindset shifts

1. **Infrastructure as code, not as clicks.** Every change goes through Git. No production changes via console.
2. **Declarative over imperative.** Describe the desired state; let the system reconcile. `kubectl apply` not `kubectl create`.
3. **Idempotency everywhere.** Running the same playbook twice produces the same result.
4. **Observability is a Day 0 concern.** Logs, metrics, traces from launch. Adding them after an incident is too late.
5. **Blameless postmortems.** Mistakes are system signal, not personal failure.

## Your first k8s deployment

Walk QUICK_START. Design a real workload. Iterate with `/k8s`.

## Read

- Kubernetes docs (kubernetes.io)
- The Twelve-Factor App (12factor.net)
- Google's SRE Book (free online)
