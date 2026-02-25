# Learning Path: Platform Engineering

> For experienced infrastructure engineers ready to design multi-cloud architectures, implement GitOps, and build internal developer platforms.

---

## What You Will Learn

By the end of this path, you will understand:

- Multi-cloud architecture patterns and when they actually make sense
- Service mesh for zero-trust networking and advanced traffic management
- GitOps as the operational model for Kubernetes
- Chaos engineering for validating resilience assumptions
- Platform engineering and building internal developer platforms
- Advanced observability with distributed tracing and SLO-based alerting

---

## Prerequisites

- Completed the [Intermediate Path](intermediate.md) or equivalent production experience
- Comfortable operating Kubernetes clusters (deployments, services, Helm, debugging)
- Terraform module authoring and state management experience
- Running monitoring stack (Prometheus + Grafana or equivalent)
- Experience with at least one cloud provider's core services

---

## Phase 1: Multi-Cloud Architecture

### 1.1 When Multi-Cloud Makes Sense

Multi-cloud is often sold as a hedge against vendor lock-in. The reality is more nuanced.

**Legitimate reasons for multi-cloud:**
- Regulatory requirements (data sovereignty, specific certifications)
- Best-of-breed services (GCP for ML, AWS for breadth, Azure for enterprise)
- Acquisition integration (inherited workloads on different clouds)
- Extreme availability requirements (survive a full cloud provider outage)

**Illegitimate reasons:**
- "Avoiding vendor lock-in" without a concrete scenario where you would actually migrate
- Political reasons (each team picks their favorite cloud)
- Premature optimization for a problem you do not have

Multi-cloud doubles your operational complexity. Everything -- IAM, networking, monitoring, CI/CD, secrets management -- now exists in two or more variants. Be certain the benefit justifies the cost.

### 1.2 Abstraction Strategies

When multi-cloud is justified, you need abstraction:

| Layer | Abstraction | Tools |
|-------|------------|-------|
| **Infrastructure** | Terraform with provider-agnostic modules | Terraform, Pulumi |
| **Compute** | Kubernetes (same API everywhere) | EKS, GKE, AKS |
| **Networking** | Service mesh (provider-agnostic mTLS and routing) | Istio, Linkerd |
| **Observability** | OpenTelemetry (vendor-neutral telemetry) | OTel Collector |
| **Secrets** | HashiCorp Vault (works with any cloud) | Vault |
| **CI/CD** | Cloud-agnostic pipelines | GitHub Actions, GitLab CI |

### 1.3 The Kubernetes Abstraction Layer

Kubernetes is the most practical multi-cloud abstraction for compute. The API is the same across EKS, GKE, and AKS. Your workload manifests port without modification.

What does NOT port:
- **Ingress controllers** -- ALB Ingress Controller (AWS) vs. GKE Ingress (GCP)
- **Storage classes** -- EBS (AWS) vs. Persistent Disk (GCP)
- **IAM integration** -- IRSA (AWS) vs. Workload Identity (GCP) vs. AAD Pod Identity (Azure)
- **Load balancers** -- Cloud-specific implementation behind `type: LoadBalancer`

The pattern: abstract these differences into Helm values or Kustomize overlays per cloud.

### 1.4 Cross-Cloud Networking

Connecting workloads across clouds requires explicit networking:

- **VPN tunnels** -- IPsec tunnels between cloud VPCs. Simple, but bandwidth-limited.
- **Cloud interconnects** -- Dedicated physical connections (AWS Direct Connect, GCP Cloud Interconnect). Higher bandwidth, lower latency.
- **Service mesh federation** -- Istio multi-cluster can span clouds with mTLS.
- **API gateways** -- Expose services via public APIs with authentication. Simplest, highest latency.

### 1.5 Exercises

1. **Deploy to two clouds** -- Deploy the same application to EKS and GKE using the same Helm chart with per-cloud values
2. **Cross-cloud connectivity** -- Set up a VPN tunnel between an AWS VPC and a GCP VPC
3. **Unified monitoring** -- Deploy OpenTelemetry Collector in both clusters, shipping to a single Grafana Cloud instance

---

## Phase 2: Service Mesh

### 2.1 What a Service Mesh Provides

A service mesh adds infrastructure-level capabilities to service-to-service communication:

| Capability | Without Mesh | With Mesh |
|-----------|-------------|-----------|
| **Encryption** | Application-level TLS | Automatic mTLS between all services |
| **Authentication** | Custom auth middleware | Automatic identity via certificates |
| **Traffic control** | Application-level routing | Infrastructure-level canary, mirroring, retry |
| **Observability** | Manual instrumentation | Automatic request metrics, traces |
| **Resilience** | Application-level retry/timeout | Infrastructure-level retry, circuit breaking, timeout |

### 2.2 Istio Architecture

Istio injects a **sidecar proxy** (Envoy) into every pod. All traffic flows through the proxy. The control plane configures the proxies.

```
[Service A] <-> [Envoy Proxy] <-- mTLS --> [Envoy Proxy] <-> [Service B]
                                    |
                              [Istio Control Plane]
                              (Istiod: config, certs, policy)
```

### 2.3 Traffic Management

```yaml
# VirtualService -- Route traffic between versions
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: my-app
spec:
  hosts:
    - my-app
  http:
    - route:
        - destination:
            host: my-app
            subset: stable
          weight: 90
        - destination:
            host: my-app
            subset: canary
          weight: 10
      retries:
        attempts: 3
        perTryTimeout: 2s
        retryOn: gateway-error,connect-failure,refused-stream
```

```yaml
# DestinationRule -- Define subsets and connection policies
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: my-app
spec:
  host: my-app
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        h2UpgradePolicy: DEFAULT
        maxRequestsPerConnection: 10
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 30s
  subsets:
    - name: stable
      labels:
        version: v1
    - name: canary
      labels:
        version: v2
```

### 2.4 Authorization Policies

```yaml
# Only allow frontend to call the API service
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: api-access
  namespace: production
spec:
  selector:
    matchLabels:
      app: api
  rules:
    - from:
        - source:
            principals: ["cluster.local/ns/production/sa/frontend"]
      to:
        - operation:
            methods: ["GET", "POST"]
            paths: ["/api/*"]
```

### 2.5 When to Use a Service Mesh

A service mesh adds operational complexity. Use it when:

- You have 10+ microservices and need consistent mTLS across all of them
- You need fine-grained traffic control (canary, mirroring, fault injection)
- Compliance requires mutual authentication and encrypted inter-service traffic
- You need service-level observability without modifying application code

Do NOT use it when:
- You have fewer than 5 services
- A simple API gateway handles your routing needs
- Your team does not have Kubernetes operational maturity

### 2.6 Exercises

1. **Install Istio** -- Deploy Istio to a Minikube or kind cluster
2. **mTLS** -- Enable strict mTLS and verify services communicate encrypted
3. **Canary deployment** -- Route 10% of traffic to a new version, observe metrics, promote or rollback
4. **Authorization** -- Create policies that restrict which services can communicate

---

## Phase 3: GitOps

### 3.1 What GitOps Is

GitOps uses Git as the single source of truth for declarative infrastructure. An operator in the cluster watches a Git repository and automatically applies changes.

**Traditional CI/CD:**
```
Push code -> CI builds image -> CI deploys to cluster (push-based)
```

**GitOps:**
```
Push code -> CI builds image -> CI updates manifest in Git -> Operator detects change -> Operator deploys (pull-based)
```

The key difference: the cluster pulls configuration from Git, rather than CI pushing to the cluster. This means:
- The cluster is always converging toward the declared state
- If someone makes a manual change, the operator reverts it (drift correction)
- Git history is the complete audit trail of every deployment

### 3.2 ArgoCD

ArgoCD is the most widely adopted GitOps operator for Kubernetes.

```yaml
# ArgoCD Application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/k8s-manifests.git
    targetRevision: HEAD
    path: apps/my-app/overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true            # Delete resources removed from Git
      selfHeal: true         # Revert manual changes
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

### 3.3 Repository Structure for GitOps

```
k8s-manifests/
|-- apps/
|   |-- my-app/
|   |   |-- base/
|   |   |   |-- deployment.yaml
|   |   |   |-- service.yaml
|   |   |   +-- kustomization.yaml
|   |   +-- overlays/
|   |       |-- dev/
|   |       |   |-- kustomization.yaml
|   |       |   +-- patch-replicas.yaml
|   |       |-- staging/
|   |       +-- production/
|   +-- another-app/
|
+-- infrastructure/
    |-- cert-manager/
    |-- external-secrets/
    |-- istio/
    +-- monitoring/
```

### 3.4 The Image Update Pattern

When CI builds a new image:

1. CI builds `my-app:v1.2.3` and pushes to the container registry
2. CI updates `k8s-manifests/apps/my-app/base/deployment.yaml` to reference `my-app:v1.2.3`
3. CI commits and pushes the manifest change
4. ArgoCD detects the new commit and applies the updated deployment

Automated image updaters (ArgoCD Image Updater, Flux Image Automation) can handle step 2-3 automatically.

### 3.5 Exercises

1. **Deploy ArgoCD** -- Install ArgoCD in a cluster and access the UI
2. **First GitOps app** -- Create an Application that syncs from a Git repository
3. **Drift correction** -- Manually modify a deployment and watch ArgoCD revert it
4. **Promotion pipeline** -- Set up a workflow where merging to `main` updates production manifests

---

## Phase 4: Chaos Engineering

### 4.1 Why Break Things on Purpose?

Your system has resilience assumptions:
- "If a pod crashes, Kubernetes restarts it within 30 seconds"
- "If the database fails over, the application reconnects within 5 seconds"
- "If a network partition occurs, the circuit breaker opens and serves cached data"

Chaos engineering **tests these assumptions** by deliberately injecting failures in controlled conditions. Better to find weaknesses in a planned experiment than in a production incident.

### 4.2 The Chaos Engineering Process

1. **Hypothesize** -- "If we kill 1 of 3 API pods, response time stays under 500ms and error rate stays below 0.1%"
2. **Define steady state** -- Measure baseline metrics (latency, error rate, throughput)
3. **Inject failure** -- Kill the pod
4. **Observe** -- Did metrics stay within the hypothesis?
5. **Learn** -- If yes, confidence increases. If no, fix the weakness.

### 4.3 Chaos Toolkit

```yaml
# experiment.yaml
title: "Pod failure resilience"
description: "Verify the system handles a pod failure gracefully"

steady-state-hypothesis:
  title: "Application serves traffic normally"
  probes:
    - type: probe
      name: "api-responds"
      provider:
        type: http
        url: "http://my-app.example.com/health"
        timeout: 5
      tolerance:
        status: 200

    - type: probe
      name: "error-rate-below-threshold"
      provider:
        type: python
        module: chaosprometheus.probes
        func: query_instant
        arguments:
          query: "sum(rate(http_requests_total{status=~'5..'}[1m])) / sum(rate(http_requests_total[1m]))"
      tolerance:
        type: range
        range: [0.0, 0.001]

method:
  - type: action
    name: "kill-one-api-pod"
    provider:
      type: python
      module: chaosk8s.pod.actions
      func: terminate_pods
      arguments:
        label_selector: "app=my-app"
        qty: 1
    pauses:
      after: 30    # Wait 30 seconds for recovery
```

### 4.4 Types of Failure Injection

| Failure Type | What It Tests | Tools |
|-------------|--------------|-------|
| **Pod kill** | Self-healing, auto-scaling | Chaos Toolkit, Litmus |
| **Network latency** | Timeout handling, circuit breakers | tc, Toxiproxy, Istio fault injection |
| **Network partition** | Split-brain handling, failover | iptables, Chaos Mesh |
| **CPU/Memory stress** | Resource limits, OOM handling | stress-ng, Chaos Mesh |
| **DNS failure** | Fallback behavior, caching | Chaos Mesh |
| **Disk fill** | Alerting, graceful degradation | dd, Chaos Mesh |
| **Clock skew** | Time-dependent logic, certificate validation | Chaos Mesh |

### 4.5 Exercises

1. **Kill a pod** -- In a 3-replica deployment, kill one pod during load testing. Measure impact on latency and error rate.
2. **Network delay** -- Add 500ms latency between two services. Verify timeouts and retries work correctly.
3. **DNS failure** -- Block DNS resolution for an external dependency. Verify graceful degradation.
4. **Game day** -- Plan and execute a chaos experiment involving multiple failure types simultaneously.

---

## Phase 5: Platform Engineering

### 5.1 What Platform Engineering Solves

As organizations grow, every team rebuilding the same infrastructure patterns wastes engineering time. Platform engineering builds an **Internal Developer Platform (IDP)** that provides self-service infrastructure.

**Before platform engineering:**
- Each team writes their own Terraform, Kubernetes manifests, CI/CD pipelines
- Inconsistent security, monitoring, and operational practices
- Platform team is a bottleneck for every infrastructure request

**After platform engineering:**
- Teams request resources through a self-service interface
- The platform enforces security, compliance, and best practices automatically
- The platform team builds reusable components, not individual team infrastructure

### 5.2 The Platform Stack

```
+------------------------------------------+
|        Developer Self-Service            |
|  (Backstage, Port, custom portal)        |
+------------------------------------------+
|        Orchestration Layer               |
|  (Crossplane, Terraform, custom)         |
+------------------------------------------+
|        Policy & Governance               |
|  (OPA/Gatekeeper, Kyverno, Sentinel)     |
+------------------------------------------+
|        Infrastructure Layer              |
|  (Kubernetes, Cloud APIs, Terraform)     |
+------------------------------------------+
```

### 5.3 Crossplane -- Kubernetes-Native Infrastructure

Crossplane extends Kubernetes to manage cloud resources. Developers request infrastructure using the same kubectl/YAML interface they use for workloads.

```yaml
# Claim -- what a developer writes
apiVersion: database.example.com/v1alpha1
kind: PostgreSQLInstance
metadata:
  name: my-database
  namespace: team-a
spec:
  parameters:
    storageGB: 20
    version: "16"
  compositionSelector:
    matchLabels:
      provider: aws
      environment: production
```

The platform team defines what this actually creates (RDS instance, security group, subnet group, parameter group, monitoring) in a Composition. Developers never see the cloud-specific details.

### 5.4 Policy as Code

Enforce organizational policies automatically:

```yaml
# Kyverno -- require resource limits on all containers
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-limits
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "All containers must have CPU and memory limits"
        pattern:
          spec:
            containers:
              - resources:
                  limits:
                    memory: "?*"
                    cpu: "?*"
```

### 5.5 The Golden Path

A golden path is the platform team's recommended way to build and deploy a service. It includes:

- **Project template** -- Preconfigured repository with CI/CD, Docker, Kubernetes manifests
- **CI/CD pipeline** -- Standardized build, test, scan, deploy workflow
- **Monitoring** -- Automatic dashboards and alerts for every service
- **Security** -- Preconfigured network policies, RBAC, secret injection
- **Documentation** -- Generated API docs, architecture diagrams, runbooks

Developers can deviate from the golden path, but the path is so well-built that most choose to follow it.

### 5.6 Exercises

1. **Backstage** -- Deploy Backstage and create a software template that scaffolds a new service
2. **Crossplane** -- Install Crossplane and create a Composition that provisions an S3 bucket with encryption and versioning
3. **Policy enforcement** -- Deploy Kyverno and create policies that require labels, resource limits, and image pull policies
4. **Golden path** -- Build a project template that includes Dockerfile, Helm chart, CI/CD pipeline, and monitoring config

---

## Phase 6: Advanced Observability

### 6.1 Distributed Tracing

In a microservices architecture, a single user request touches multiple services. When something is slow, which service is the bottleneck?

Distributed tracing propagates a unique **trace ID** through every service in the request path. Each service records its **span** (start time, duration, metadata). The trace shows the complete request journey.

### 6.2 OpenTelemetry

OpenTelemetry (OTel) is the vendor-neutral standard for metrics, logs, and traces:

```
[Service A]  -->  [OTel SDK]  -->  [OTel Collector]  -->  [Backend]
   metrics           (auto-          (routing,              (Jaeger, Tempo,
   traces            instrument)      sampling,              Grafana Cloud,
   logs                               enrichment)            Datadog)
```

The key insight: instrument once with OTel, ship to any backend.

### 6.3 SLO-Based Alerting

Traditional alerting: "Alert when error rate > 1%"
Problem: Too many alerts. Alert fatigue. Engineers ignore pages.

SLO-based alerting: "Alert when we are consuming error budget too fast"

```yaml
# Multi-window, multi-burn-rate alerts
# Alert when error budget burn rate threatens the SLO

# Fast burn (1-hour budget exhaustion pace) -- page immediately
- alert: SLOBurnRateCritical
  expr: |
    (
      sum(rate(http_requests_total{status=~"5.."}[5m]))
      /
      sum(rate(http_requests_total[5m]))
    ) > (14.4 * 0.001)
    and
    (
      sum(rate(http_requests_total{status=~"5.."}[1h]))
      /
      sum(rate(http_requests_total[1h]))
    ) > (14.4 * 0.001)
  labels:
    severity: critical

# Slow burn (3-day budget exhaustion pace) -- create ticket
- alert: SLOBurnRateWarning
  expr: |
    (
      sum(rate(http_requests_total{status=~"5.."}[6h]))
      /
      sum(rate(http_requests_total[6h]))
    ) > (1 * 0.001)
    and
    (
      sum(rate(http_requests_total{status=~"5.."}[3d]))
      /
      sum(rate(http_requests_total[3d]))
    ) > (1 * 0.001)
  labels:
    severity: warning
```

### 6.4 Exercises

1. **Distributed tracing** -- Add OpenTelemetry instrumentation to 3 services and view traces in Jaeger or Grafana Tempo
2. **Trace-based debugging** -- Introduce artificial latency in one service and identify it through traces
3. **SLO definition** -- Define SLOs for a service, calculate error budgets, and create burn-rate alerts
4. **Unified observability** -- Build a Grafana dashboard that correlates metrics, logs, and traces for a single request

---

## What Comes Next

At this level, growth comes from depth and breadth:

- **Depth**: Become an expert in your organization's specific stack
- **Breadth**: Study adjacent domains (security engineering, data engineering, ML infrastructure)
- **Leadership**: Define standards, mentor others, drive architectural decisions
- **Community**: Contribute to open-source tools, write about your experiences, share operational knowledge

---

## Plugin Recommendations for Advanced

| Plugin | Why Use It Now |
|--------|---------------|
| [service-mesh](../plugins/service-mesh/) | Istio/Linkerd architecture and traffic management |
| [release-management](../plugins/release-management/) | GitOps, progressive delivery, feature flags |
| [incident-management](../plugins/incident-management/) | Production incident response and postmortems |
| [infrastructure-security](../plugins/infrastructure-security/) | CIS benchmarks, compliance, policy as code |
| [cost-optimization](../plugins/cost-optimization/) | FinOps at scale, enterprise cost management |
| [backup-disaster-recovery](../plugins/backup-disaster-recovery/) | Multi-region DR, RPO/RTO architecture |
