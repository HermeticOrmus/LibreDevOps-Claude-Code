# Intermediate: Multi-Environment Infrastructure with Claude Code

> You can deploy a single service. Now build systems that manage multiple environments, handle state across teams, and recover from failures automatically.

**Prerequisites**: Complete `../beginner/` or have equivalent experience with Docker, basic Terraform, and CI/CD pipelines.

---

## Table of Contents

1. [Multi-Environment Terraform](#multi-environment-terraform)
2. [Kubernetes Patterns for Production](#kubernetes-patterns-for-production)
3. [Monitoring Stacks](#monitoring-stacks)
4. [Infrastructure Testing](#infrastructure-testing)
5. [State Management Strategies](#state-management-strategies)
6. [Case Study: Deploying a SaaS Platform](#case-study-deploying-a-saas-platform)
7. [CLAUDE.md Infrastructure Configuration](#claudemd-infrastructure-configuration)
8. [Eight-Phase Learning Path](#eight-phase-learning-path)

---

## Multi-Environment Terraform

The hard part of Terraform is not writing a single environment. It is managing dev, staging, and production with shared modules, separate state, and environment-specific configuration.

### Module-Based Architecture

```
infrastructure/
+-- modules/
|   +-- vpc/
|   |   +-- main.tf
|   |   +-- variables.tf
|   |   +-- outputs.tf
|   +-- ecs-service/
|   +-- rds/
|   +-- monitoring/
+-- environments/
    +-- dev/
    |   +-- main.tf          # Instantiates modules with dev values
    |   +-- terraform.tfvars  # Dev-specific variable values
    |   +-- backend.tf        # Dev state backend
    +-- staging/
    +-- prod/
```

**Prompt for Claude Code:**

```
"Design a Terraform module structure for a web application with:
- VPC module: configurable CIDR, public/private subnets across 2 AZs,
  NAT gateway (single for dev, HA for prod), VPC flow logs
- ECS Fargate service module: configurable instance count, CPU/memory,
  ALB with health checks, auto-scaling policies, CloudWatch log group
- RDS module: configurable instance class, multi-AZ (prod only),
  encrypted storage, automated backups, parameter group
- Monitoring module: CloudWatch dashboard, alarms for CPU/memory/
  error rate, SNS topic for notifications

Each module should accept an 'environment' variable and adjust
defaults accordingly (dev = small/cheap, prod = HA/monitored).
Include outputs that other modules can reference via remote state."
```

### Remote State Composition

Modules reference each other through remote state data sources. The networking module outputs VPC and subnet IDs. The compute module reads those outputs.

```hcl
# environments/prod/data.tf
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "myapp-terraform-state"
    key    = "prod/networking/terraform.tfstate"
    region = "us-east-1"
  }
}

# Use networking outputs in compute module
module "api_service" {
  source = "../../modules/ecs-service"

  vpc_id             = data.terraform_remote_state.networking.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids
  alb_subnet_ids     = data.terraform_remote_state.networking.outputs.public_subnet_ids

  environment    = "prod"
  service_name   = "api"
  container_image = var.api_image
  desired_count   = 3
  cpu             = 512
  memory          = 1024
}
```

### Workspaces vs. Directories

**Directories** (recommended): Each environment has its own directory with its own state file and backend configuration. Clear separation, no risk of applying dev changes to prod.

**Workspaces**: Terraform workspaces share the same code but have separate state. Useful for identical environments, dangerous when environments differ (which they always do in practice).

---

## Kubernetes Patterns for Production

### Namespace Strategy

```yaml
# Namespace per environment, resource quotas prevent runaway consumption
apiVersion: v1
kind: Namespace
metadata:
  name: myapp-production
  labels:
    app: myapp
    environment: production
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: production-quota
  namespace: myapp-production
spec:
  hard:
    requests.cpu: "8"
    requests.memory: 16Gi
    limits.cpu: "16"
    limits.memory: 32Gi
    pods: "50"
    services: "10"
    persistentvolumeclaims: "10"
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: myapp-production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-ingress
  namespace: myapp-production
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
      ports:
        - protocol: TCP
          port: 3000
```

### Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
  namespace: myapp-production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Pods
          value: 2
          periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Pods
          value: 1
          periodSeconds: 120
```

### Pod Disruption Budget

```yaml
# Ensure minimum availability during rolling updates and node maintenance
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-pdb
  namespace: myapp-production
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: api
```

---

## Monitoring Stacks

### Prometheus + Grafana Stack

**Prompt for Claude Code:**

```
"Set up a Prometheus + Grafana monitoring stack on Kubernetes using
Helm charts. Requirements:
- Prometheus: 15-day retention, persistent storage, service discovery
  for all namespaces, recording rules for common aggregations
- Grafana: pre-configured dashboards for Kubernetes cluster health,
  node metrics, and application RED metrics (rate, errors, duration)
- Alertmanager: route critical alerts to PagerDuty, warnings to Slack
- Node exporter: DaemonSet on all nodes
- kube-state-metrics: deployment-level metrics

Include: Prometheus recording rules for p50/p95/p99 latency by
service, alert rules for SLO burn rates, and a Grafana dashboard
JSON for the application overview."
```

### CloudWatch Stack (AWS)

```hcl
# Monitoring module for an ECS service
resource "aws_cloudwatch_dashboard" "service" {
  dashboard_name = "${var.project}-${var.environment}-${var.service_name}"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", var.service_name,
             "ClusterName", var.cluster_name, { stat = "Average" }],
          ]
          period = 300
          title  = "CPU Utilization"
          region = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ServiceName", var.service_name,
             "ClusterName", var.cluster_name, { stat = "Average" }],
          ]
          period = 300
          title  = "Memory Utilization"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count",
             "TargetGroup", var.target_group_arn_suffix,
             "LoadBalancer", var.alb_arn_suffix, { stat = "Sum" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count",
             "TargetGroup", var.target_group_arn_suffix,
             "LoadBalancer", var.alb_arn_suffix, { stat = "Sum" }],
          ]
          period = 60
          title  = "Response Codes"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${var.project}-${var.environment}-${var.service_name}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "High 5xx error rate on ${var.service_name}"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  dimensions = {
    TargetGroup  = var.target_group_arn_suffix
    LoadBalancer = var.alb_arn_suffix
  }
}
```

---

## Infrastructure Testing

### Terraform Validation Pipeline

```yaml
# .github/workflows/terraform-validate.yml
name: Terraform Validation
on:
  pull_request:
    paths:
      - 'infrastructure/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [dev, staging, prod]
    defaults:
      run:
        working-directory: infrastructure/environments/${{ matrix.environment }}
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.7.0

      - name: Terraform fmt
        run: terraform fmt -check -recursive

      - name: Terraform init
        run: terraform init -backend=false

      - name: Terraform validate
        run: terraform validate

      - name: tfsec security scan
        uses: aquasecurity/tfsec-action@v1.0.3
        with:
          working_directory: infrastructure/environments/${{ matrix.environment }}
          soft_fail: false

      - name: Checkov IaC scan
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: infrastructure/environments/${{ matrix.environment }}
          framework: terraform
```

### Testing with Terratest

```go
// infrastructure/test/vpc_test.go
package test

import (
    "testing"

    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestVPCModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/vpc",
        Vars: map[string]interface{}{
            "project_name": "test",
            "environment":  "test",
            "vpc_cidr":     "10.0.0.0/16",
            "azs":          []string{"us-east-1a", "us-east-1b"},
        },
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)

    privateSubnets := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
    assert.Equal(t, 2, len(privateSubnets))
}
```

---

## State Management Strategies

### State File Organization

```
s3://myapp-terraform-state/
+-- dev/
|   +-- networking/terraform.tfstate
|   +-- compute/terraform.tfstate
|   +-- database/terraform.tfstate
|   +-- monitoring/terraform.tfstate
+-- staging/
|   +-- networking/terraform.tfstate
|   +-- compute/terraform.tfstate
|   +-- database/terraform.tfstate
|   +-- monitoring/terraform.tfstate
+-- prod/
|   +-- networking/terraform.tfstate
|   +-- compute/terraform.tfstate
|   +-- database/terraform.tfstate
|   +-- monitoring/terraform.tfstate
+-- global/
    +-- iam/terraform.tfstate
    +-- dns/terraform.tfstate
    +-- state-backend/terraform.tfstate
```

### State Recovery Procedures

```
# State corruption recovery:
# 1. S3 versioning allows reverting to previous state version
# 2. List previous versions: aws s3api list-object-versions --bucket myapp-terraform-state --prefix prod/compute/terraform.tfstate
# 3. Restore previous version: aws s3api get-object --bucket myapp-terraform-state --key prod/compute/terraform.tfstate --version-id <version> restored.tfstate
# 4. Import restored state: terraform state push restored.tfstate
#
# State lock stuck:
# 1. Check who holds the lock: aws dynamodb get-item --table-name myapp-terraform-locks --key '{"LockID":{"S":"myapp-terraform-state/prod/compute/terraform.tfstate-md5"}}'
# 2. Force unlock (only if certain no other apply is running): terraform force-unlock <lock-id>
```

---

## Case Study: Deploying a SaaS Platform

A step-by-step approach to deploying a multi-service SaaS application from scratch, using all intermediate-level patterns.

**Architecture**: React SPA + Node.js API + PostgreSQL + Redis + S3

**Prompt sequence for Claude Code:**

1. **Networking**: "Create Terraform VPC module with public/private subnets, NAT gateway, and VPC endpoints for S3 and ECR."
2. **Database**: "Create Terraform RDS PostgreSQL module with Multi-AZ, encryption, automated backups, and parameter group tuned for a web application."
3. **Compute**: "Create Terraform ECS Fargate module with ALB, auto-scaling, CloudWatch logging, and secrets injection from Secrets Manager."
4. **CI/CD**: "Create GitHub Actions pipeline that builds Docker images, pushes to ECR, and deploys to ECS with blue-green deployment."
5. **Monitoring**: "Create Terraform monitoring module with CloudWatch dashboard, alarms for all four golden signals, and SNS alerting to Slack."

---

## Eight-Phase Learning Path

### Phase 1: Multi-Environment Terraform
- Study: Terraform module documentation, remote state backends
- Practice: Refactor a single-environment Terraform project into modules
- Exercise: Deploy the same application to dev and staging from shared modules

### Phase 2: Kubernetes Operations
- Study: Kubernetes in Action (book), official K8s docs on workloads
- Practice: Deploy a multi-service application on Minikube with resource limits, probes, and network policies
- Exercise: Implement rolling updates with PDB, HPA, and health checks

### Phase 3: CI/CD Pipelines
- Study: GitHub Actions documentation, OIDC authentication with cloud providers
- Practice: Build a pipeline with validate, test, build, scan, deploy stages
- Exercise: Add Terraform plan/apply to the pipeline with environment-specific approval gates

### Phase 4: Monitoring and Alerting
- Study: Google SRE Book (free online), Prometheus documentation
- Practice: Set up Prometheus + Grafana on a local cluster
- Exercise: Define SLOs, configure burn-rate alerts, build a service overview dashboard

### Phase 5: Secret Management
- Study: HashiCorp Vault tutorials, AWS Secrets Manager documentation
- Practice: Migrate hardcoded secrets to a secret manager
- Exercise: Implement automatic secret rotation for database credentials

### Phase 6: Infrastructure Testing
- Study: Terratest documentation, conftest for policy testing
- Practice: Write validation tests for your Terraform modules
- Exercise: Add infrastructure tests to your CI/CD pipeline

### Phase 7: Disaster Recovery
- Study: AWS Well-Architected Framework (Reliability Pillar)
- Practice: Document and test a restore procedure from backup
- Exercise: Simulate a database failure and recover using automated failover

### Phase 8: Cost Optimization
- Study: Cloud provider cost documentation, reserved instance strategies
- Practice: Tag all resources and set up cost allocation reports
- Exercise: Identify and eliminate the top 3 cost inefficiencies in your infrastructure

---

## Next Steps

After completing this intermediate material:

1. Implement multi-environment Terraform for one of your projects
2. Deploy a service to Kubernetes with all production patterns (probes, limits, HPA, PDB)
3. Set up a monitoring stack with SLO-based alerting
4. Complete the 8-phase learning path
5. Move to `../advanced/` for multi-cloud, GitOps, chaos engineering, and platform engineering

---

*Part of [LibreDevOps-Claude-Code](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code) -- MIT License*
