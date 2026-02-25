# Advanced: Platform Engineering with Claude Code

> At this level, infrastructure is no longer a series of individual configurations. It is a self-service platform that development teams consume, with automated governance, multi-cloud resilience, and continuous verification.

**Prerequisites**: Complete `../intermediate/` or have equivalent experience with multi-environment Terraform, Kubernetes operations, monitoring stacks, and CI/CD pipelines.

---

## Table of Contents

1. [Multi-Cloud Architecture](#multi-cloud-architecture)
2. [GitOps Workflows](#gitops-workflows)
3. [Chaos Engineering](#chaos-engineering)
4. [Platform Engineering](#platform-engineering)
5. [Advanced Kubernetes Patterns](#advanced-kubernetes-patterns)
6. [Infrastructure Automation with MCP](#infrastructure-automation-with-mcp)
7. [Production Incident Management](#production-incident-management)
8. [Three-Month Infrastructure Mastery Path](#three-month-infrastructure-mastery-path)

---

## Multi-Cloud Architecture

Multi-cloud is not about avoiding vendor lock-in (a rarely achieved goal). It is about resilience, compliance (data sovereignty), and leveraging best-of-breed services.

### Terraform Multi-Cloud Pattern

```hcl
# modules/compute/main.tf -- cloud-agnostic compute abstraction
variable "cloud_provider" {
  type = string
  validation {
    condition     = contains(["aws", "gcp", "azure"], var.cloud_provider)
    error_message = "Supported providers: aws, gcp, azure."
  }
}

module "aws_compute" {
  source = "./aws"
  count  = var.cloud_provider == "aws" ? 1 : 0

  instance_type = var.instance_specs.aws_type
  subnet_id     = var.subnet_id
  image_id      = var.image_ids.aws
}

module "gcp_compute" {
  source = "./gcp"
  count  = var.cloud_provider == "gcp" ? 1 : 0

  machine_type = var.instance_specs.gcp_type
  subnet       = var.subnet_id
  image        = var.image_ids.gcp
}

# Unified outputs regardless of provider
output "instance_id" {
  value = var.cloud_provider == "aws" ? module.aws_compute[0].instance_id : module.gcp_compute[0].instance_id
}
```

### Cross-Cloud Networking

**Prompt for Claude Code:**

```
"Design a multi-cloud networking architecture with:
- AWS VPC (10.0.0.0/16) in us-east-1
- GCP VPC (10.1.0.0/16) in us-central1
- Site-to-site VPN between AWS and GCP
- Terraform modules for both sides of the VPN
- DNS resolution across clouds (Route 53 + Cloud DNS)
- Network monitoring: latency between clouds, VPN tunnel status,
  bandwidth utilization
- Failover: if VPN drops, alert and document manual intervention steps

Include Terraform for both providers, monitoring for the VPN tunnels,
and a runbook for VPN failure."
```

---

## GitOps Workflows

GitOps uses Git as the single source of truth for infrastructure state. Instead of running `terraform apply` manually, changes are merged to Git and a controller reconciles the desired state.

### ArgoCD Pattern

```yaml
# argocd/applications/production.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp-production
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: production
  source:
    repoURL: https://github.com/myorg/infrastructure.git
    targetRevision: main
    path: kubernetes/overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: myapp-production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas  # Managed by HPA
```

### Kustomize Overlays

```
kubernetes/
+-- base/
|   +-- deployment.yaml
|   +-- service.yaml
|   +-- kustomization.yaml
+-- overlays/
    +-- dev/
    |   +-- kustomization.yaml    # patches for dev
    |   +-- replicas-patch.yaml
    +-- staging/
    |   +-- kustomization.yaml
    +-- production/
        +-- kustomization.yaml    # patches for production
        +-- replicas-patch.yaml
        +-- resources-patch.yaml
        +-- hpa.yaml
        +-- pdb.yaml
```

```yaml
# kubernetes/overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: myapp-production

resources:
  - ../../base
  - hpa.yaml
  - pdb.yaml

patches:
  - path: replicas-patch.yaml
  - path: resources-patch.yaml

images:
  - name: myapp
    newName: 123456789.dkr.ecr.us-east-1.amazonaws.com/myapp
    newTag: "1.2.3"

configMapGenerator:
  - name: app-config
    envs:
      - config.env
```

---

## Chaos Engineering

Chaos engineering is the discipline of experimenting on a system to build confidence in its ability to withstand turbulent conditions in production.

### Litmus Chaos on Kubernetes

```yaml
# chaos/pod-delete-experiment.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: api-pod-delete
  namespace: myapp-staging
spec:
  engineState: active
  appinfo:
    appns: myapp-staging
    applabel: app=api
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: "30"
            - name: CHAOS_INTERVAL
              value: "10"
            - name: FORCE
              value: "false"
            - name: PODS_AFFECTED_PERC
              value: "50"
        probe:
          - name: api-health-check
            type: httpProbe
            httpProbe/inputs:
              url: http://api.myapp-staging.svc.cluster.local:3000/health
              method:
                get:
                  criteria: ==
                  responseCode: "200"
            mode: Continuous
            runProperties:
              probeTimeout: 5
              interval: 5
              retry: 3
```

### Chaos Experiment Design

**Prompt for Claude Code:**

```
"Design a chaos engineering program for our production Kubernetes cluster.
Create experiments that test:

1. Pod resilience: Kill 50% of API pods. Verify: response time stays
   under 1s, error rate stays under 1%, HPA scales up within 2 minutes.

2. Node failure: Drain a worker node. Verify: all pods reschedule
   within 5 minutes, no dropped requests during migration.

3. Database failover: Trigger RDS failover. Verify: application reconnects
   within 30 seconds, no data loss, connection pool recovers.

4. Network partition: Block traffic between API and cache (Redis).
   Verify: application degrades gracefully (slower but not broken),
   cache reconnects when network restores.

5. DNS failure: Block DNS resolution for 60 seconds. Verify: cached
   DNS entries sustain traffic, application recovers when DNS restores.

For each experiment:
- Hypothesis (what we expect)
- Steady state definition (metrics that define 'normal')
- Blast radius (what is affected)
- Abort conditions (when to stop the experiment)
- Rollback procedure
- Success/failure criteria
- Monitoring queries to observe during experiment"
```

---

## Platform Engineering

Platform engineering builds internal developer platforms (IDPs) that provide self-service infrastructure to development teams while maintaining governance.

### Service Catalog with Backstage

```yaml
# backstage/templates/new-service/template.yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: new-microservice
  title: New Microservice
  description: Create a new microservice with full infrastructure
  tags:
    - recommended
    - microservice
spec:
  owner: platform-team
  type: service
  parameters:
    - title: Service Configuration
      required:
        - name
        - owner
        - language
      properties:
        name:
          title: Service Name
          type: string
          pattern: "^[a-z][a-z0-9-]{2,30}$"
        owner:
          title: Owner Team
          type: string
          ui:field: OwnerPicker
        language:
          title: Language
          type: string
          enum: [nodejs, python, go]
        needs_database:
          title: Needs Database
          type: boolean
          default: false
        needs_cache:
          title: Needs Cache (Redis)
          type: boolean
          default: false

  steps:
    - id: scaffold
      name: Scaffold Repository
      action: fetch:template
      input:
        url: ./skeleton/${{ parameters.language }}
        values:
          name: ${{ parameters.name }}
          owner: ${{ parameters.owner }}

    - id: create-repo
      name: Create GitHub Repository
      action: publish:github
      input:
        repoUrl: github.com?owner=myorg&repo=${{ parameters.name }}
        defaultBranch: main

    - id: create-infra
      name: Provision Infrastructure
      action: custom:terraform-apply
      input:
        module: microservice
        vars:
          service_name: ${{ parameters.name }}
          needs_database: ${{ parameters.needs_database }}
          needs_cache: ${{ parameters.needs_cache }}

    - id: register
      name: Register in Backstage
      action: catalog:register
      input:
        repoContentsUrl: ${{ steps['create-repo'].output.repoContentsUrl }}
        catalogInfoPath: /catalog-info.yaml
```

### Policy as Code with OPA

```rego
# policy/terraform/required_tags.rego
package terraform.required_tags

import rego.v1

required_tags := {"Project", "Environment", "ManagedBy", "CostCenter"}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.change.actions[_] == "create"
    tags := object.get(resource.change.after, "tags", {})
    missing := required_tags - {key | tags[key]}
    count(missing) > 0
    msg := sprintf(
        "%s '%s' is missing required tags: %v",
        [resource.type, resource.address, missing]
    )
}

# policy/kubernetes/no_latest_tag.rego
package kubernetes.no_latest_tag

import rego.v1

deny contains msg if {
    container := input.spec.template.spec.containers[_]
    endswith(container.image, ":latest")
    msg := sprintf("Container '%s' uses :latest tag. Pin to a specific version.", [container.name])
}

deny contains msg if {
    container := input.spec.template.spec.containers[_]
    not contains(container.image, ":")
    msg := sprintf("Container '%s' has no tag. Pin to a specific version.", [container.name])
}
```

---

## Advanced Kubernetes Patterns

### Service Mesh with Istio

```yaml
# Virtual service for canary deployment
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api
  namespace: myapp-production
spec:
  hosts:
    - api.myapp.svc.cluster.local
  http:
    - match:
        - headers:
            x-canary:
              exact: "true"
      route:
        - destination:
            host: api.myapp.svc.cluster.local
            subset: canary
    - route:
        - destination:
            host: api.myapp.svc.cluster.local
            subset: stable
          weight: 95
        - destination:
            host: api.myapp.svc.cluster.local
            subset: canary
          weight: 5
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: api
  namespace: myapp-production
spec:
  host: api.myapp.svc.cluster.local
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        h2UpgradePolicy: DEFAULT
        http1MaxPendingRequests: 100
        http2MaxRequests: 1000
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
  subsets:
    - name: stable
      labels:
        version: stable
    - name: canary
      labels:
        version: canary
```

---

## Infrastructure Automation with MCP

The Model Context Protocol allows Claude Code to interact with infrastructure tools directly.

### Terraform MCP Server

```json
{
  "mcpServers": {
    "terraform": {
      "command": "node",
      "args": ["mcp-servers/terraform/index.js"],
      "env": {
        "TF_BINARY": "/usr/local/bin/terraform",
        "WORKING_DIR": "${WORKSPACE}/infrastructure"
      }
    }
  }
}
```

**Usage pattern:**

```
"Using the Terraform MCP server:
1. Run terraform plan for the production environment
2. Analyze the plan output for any destructive changes
3. If no destructive changes, summarize what will be created/modified
4. If destructive changes found, list them with impact assessment
5. Generate a deployment approval summary"
```

### Kubernetes MCP Server

```json
{
  "mcpServers": {
    "kubernetes": {
      "command": "node",
      "args": ["mcp-servers/kubernetes/index.js"],
      "env": {
        "KUBECONFIG": "${HOME}/.kube/config",
        "CONTEXT": "production"
      }
    }
  }
}
```

---

## Production Incident Management

### Incident Response Runbook Template

```markdown
# Runbook: [Incident Type]

## Detection
- Alert name: [CloudWatch alarm / Prometheus alert name]
- Condition: [metric threshold that triggers]
- Dashboard: [link to relevant Grafana/CloudWatch dashboard]

## Triage (first 5 minutes)
1. Confirm the alert is not a false positive (check dashboard)
2. Determine scope: which services, which environments, how many users
3. Classify severity:
   - SEV1: Complete service outage, data loss risk
   - SEV2: Degraded service, significant user impact
   - SEV3: Minor degradation, limited user impact

## Mitigation (SEV1: within 15 minutes)
- [ ] Step 1: [specific command or action]
- [ ] Step 2: [specific command or action]
- [ ] Verify: [how to confirm mitigation worked]

## Root Cause Investigation
- [ ] Collect logs: [specific log queries]
- [ ] Check recent deployments: [git log, deployment history]
- [ ] Check infrastructure changes: [terraform state, cloud console]
- [ ] Check external dependencies: [status pages, API health]

## Recovery
- [ ] Rollback procedure: [specific commands]
- [ ] Data recovery: [if applicable]
- [ ] Verification: [health checks, integration tests]

## Post-Incident
- [ ] Timeline documented
- [ ] Root cause identified
- [ ] Action items created
- [ ] Detection improvement identified
```

---

## Three-Month Infrastructure Mastery Path

### Month 1: Multi-Cloud and Advanced IaC

**Phase 1-2: Terraform at Scale**
- Study: Terraform Up and Running (book), module registry patterns
- Practice: Build a multi-environment, multi-region Terraform setup
- Exercise: Implement Terratest for all modules, add policy-as-code with OPA/Conftest
- Milestone: All infrastructure tested, policy-checked, and auto-deployed via CI/CD

**Phase 3-4: Kubernetes Operations**
- Study: Kubernetes patterns (book), CKA curriculum
- Practice: Deploy a multi-service application with service mesh, HPA, PDB, network policies
- Exercise: Implement GitOps with ArgoCD, progressive delivery with Argo Rollouts
- Milestone: Zero-downtime deployments, automatic canary analysis, self-healing infrastructure

### Month 2: Platform Engineering

**Phase 5-6: Internal Developer Platform**
- Study: Team Topologies (book), Backstage documentation
- Practice: Build a service catalog with self-service provisioning
- Exercise: Implement golden paths for new services (repo, CI/CD, infra, monitoring)
- Milestone: Development teams can deploy new services without platform team involvement

**Phase 7-8: Observability Engineering**
- Study: Observability Engineering (book), OpenTelemetry documentation
- Practice: Implement distributed tracing across services
- Exercise: Build SLO dashboards with burn-rate alerting, implement error budgets
- Milestone: SLOs defined for all services, automated incident detection and escalation

### Month 3: Reliability Engineering

**Phase 9-10: Chaos Engineering**
- Study: Chaos Engineering (book), Litmus/Gremlin documentation
- Practice: Run chaos experiments in staging, then production
- Exercise: Build a game day program with scheduled chaos experiments
- Milestone: Monthly game days running, resilience improvements tracked

**Phase 11-12: Cost and Compliance**
- Study: FinOps Foundation materials, cloud provider cost optimization
- Practice: Implement cost allocation, reserved instances, spot instances
- Exercise: Build compliance automation (SOC 2 evidence collection, audit reports)
- Milestone: Infrastructure costs optimized by 20%+, compliance evidence automated

### Assessment Checkpoints

**End of Month 1:**
- [ ] Multi-environment Terraform with testing and policy enforcement
- [ ] Kubernetes with GitOps, service mesh, and progressive delivery
- [ ] All infrastructure changes flow through CI/CD with approval gates

**End of Month 2:**
- [ ] Self-service platform for development teams
- [ ] Distributed tracing across all services
- [ ] SLO-based alerting with error budgets

**End of Month 3:**
- [ ] Regular chaos experiments with tracked improvements
- [ ] Infrastructure cost optimized and reported
- [ ] Compliance evidence collection automated

---

## Next Steps

This advanced guide provides the frameworks. Execution requires:

1. Choose one advanced pattern and implement it this phase
2. Set up at least one MCP integration for infrastructure tooling
3. Begin Month 1 of the learning path
4. Contribute improvements back to this guide

Infrastructure is a continuous practice. The tools evolve rapidly. The principles -- automation, observability, resilience, self-service -- remain constant.

---

*Part of [LibreDevOps-Claude-Code](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code) -- MIT License*
