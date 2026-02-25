# Learning Path: Infrastructure Engineering

> For engineers who have built basic CI/CD pipelines and containerized applications. Ready to operate real infrastructure.

---

## What You Will Learn

By the end of this path, you will understand:

- Kubernetes architecture and how to deploy, scale, and troubleshoot workloads
- Terraform modules, state management, and multi-environment patterns
- Monitoring stacks with Prometheus, Grafana, and alerting
- Multi-environment promotion workflows (dev -> staging -> production)
- Secrets management beyond plain environment variables
- Networking fundamentals for cloud infrastructure

---

## Prerequisites

- Completed the [Beginner Path](beginner.md) or equivalent experience
- Comfortable with Docker (building images, docker-compose, debugging containers)
- Basic Terraform experience (init, plan, apply, destroy)
- Functional CI/CD pipeline (GitHub Actions or equivalent)
- Access to a cloud provider account (AWS free tier, GCP free tier, or Azure free tier)

---

## Phase 1: Kubernetes Fundamentals

### 1.1 Why Kubernetes?

Docker Compose works for a single machine. Kubernetes works for fleets.

When your application needs:
- **High availability** -- If a server dies, containers restart elsewhere
- **Auto-scaling** -- Add capacity when traffic increases, remove it when traffic drops
- **Rolling updates** -- Deploy new versions with zero downtime
- **Service discovery** -- Containers find each other without hardcoded addresses

Kubernetes provides all of this through a declarative API. You describe what you want. Kubernetes makes it happen and keeps it that way.

### 1.2 Core Concepts

| Concept | What It Is | Analogy |
|---------|-----------|---------|
| **Pod** | Smallest deployable unit. One or more containers that share networking. | A single shipping container |
| **Deployment** | Manages a set of identical pods. Handles scaling and updates. | A fleet manager |
| **Service** | Stable network endpoint for a set of pods. Pods come and go; the Service address stays. | A phone number that routes to whoever is on call |
| **Namespace** | Logical partition within a cluster. Isolates workloads. | A floor in an office building |
| **ConfigMap** | Configuration data stored in the cluster. Injected into pods. | A shared configuration file |
| **Secret** | Sensitive data stored in the cluster. Base64 encoded (not encrypted by default). | A locked drawer (with a flimsy lock) |
| **Ingress** | Routes external HTTP traffic to Services based on hostname/path. | A receptionist directing visitors |
| **PersistentVolume** | Storage that survives pod restarts. | A filing cabinet that stays when employees leave |

### 1.3 Your First Deployment

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  replicas: 3                    # Run 3 copies for availability
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-app
          image: my-registry/my-app:v1.2.0
          ports:
            - containerPort: 3000
          resources:
            requests:              # Minimum resources guaranteed
              cpu: 100m
              memory: 128Mi
            limits:                # Maximum resources allowed
              cpu: 500m
              memory: 256Mi
          readinessProbe:          # Is the pod ready to receive traffic?
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:           # Is the pod alive?
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 15
            periodSeconds: 20
          env:
            - name: NODE_ENV
              value: "production"
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: database-url
```

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  selector:
    app: my-app
  ports:
    - port: 80
      targetPort: 3000
  type: ClusterIP
```

### 1.4 Essential kubectl Commands

```bash
# Apply manifests
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Check status
kubectl get pods                        # List pods
kubectl get pods -w                     # Watch pods (live updates)
kubectl get deployments                 # List deployments
kubectl get services                    # List services
kubectl get events --sort-by=.lastTimestamp  # Recent cluster events

# Debug
kubectl describe pod <pod-name>         # Detailed pod info (events, conditions)
kubectl logs <pod-name>                 # View container logs
kubectl logs <pod-name> --previous      # Logs from crashed container
kubectl exec -it <pod-name> -- sh       # Shell into a running container
kubectl port-forward svc/my-app 3000:80 # Access service locally

# Scaling
kubectl scale deployment my-app --replicas=5

# Rolling update
kubectl set image deployment/my-app my-app=my-registry/my-app:v1.3.0
kubectl rollout status deployment/my-app
kubectl rollout undo deployment/my-app  # Rollback if something breaks
```

### 1.5 Local Kubernetes

For learning, use a local cluster instead of cloud Kubernetes:

- **Minikube** -- Single-node cluster. Good for learning.
- **kind** (Kubernetes in Docker) -- Multi-node clusters in Docker containers. Good for CI testing.
- **k3s** -- Lightweight Kubernetes. Good for resource-constrained machines.

```bash
# Minikube
minikube start
minikube dashboard    # Opens the Kubernetes dashboard in your browser

# kind
kind create cluster --name dev
kind delete cluster --name dev
```

### 1.6 Helm -- The Kubernetes Package Manager

Helm packages Kubernetes manifests into reusable, parameterized charts:

```bash
# Add a chart repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install PostgreSQL with custom values
helm install my-db bitnami/postgresql \
  --set auth.postgresPassword=secretpass \
  --set primary.persistence.size=10Gi

# List installed releases
helm list

# Upgrade a release
helm upgrade my-db bitnami/postgresql --set primary.persistence.size=20Gi

# Uninstall
helm uninstall my-db
```

### 1.7 Exercises

1. **Deploy to Minikube** -- Deploy a containerized app with 3 replicas, a Service, and an Ingress
2. **Rolling update** -- Deploy a new version and watch pods roll over with `kubectl get pods -w`
3. **Break and recover** -- Delete a pod manually and watch Kubernetes recreate it
4. **Resource limits** -- Set CPU limits too low, generate load, and observe throttling
5. **Helm** -- Deploy PostgreSQL with Helm and connect your application to it

---

## Phase 2: Terraform at Scale

### 2.1 From Scripts to Modules

Single-file Terraform works for learning. Real projects need structure.

A **module** is a reusable Terraform component with defined inputs and outputs:

```
modules/
|-- vpc/
|   |-- main.tf          # Resource definitions
|   |-- variables.tf     # Input variables
|   |-- outputs.tf       # Output values
|   +-- README.md        # Usage documentation
|
+-- ecs-service/
    |-- main.tf
    |-- variables.tf
    |-- outputs.tf
    +-- README.md
```

### 2.2 Writing a Module

```hcl
# modules/vpc/variables.tf
variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}
```

```hcl
# modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "${var.project_name}-${var.environment}-private-${var.availability_zones[count.index]}"
    Environment = var.environment
    Tier        = "private"
  }
}
```

```hcl
# modules/vpc/outputs.tf
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}
```

### 2.3 Using Modules Across Environments

```hcl
# environments/dev/main.tf
module "vpc" {
  source = "../../modules/vpc"

  project_name       = "myapp"
  environment        = "dev"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
}

# environments/prod/main.tf
module "vpc" {
  source = "../../modules/vpc"

  project_name       = "myapp"
  environment        = "prod"
  vpc_cidr           = "10.1.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
```

### 2.4 Remote State Backend

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "myapp-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "myapp-terraform-locks"
    encrypt        = true
  }
}
```

**Why remote state matters:**
- **Team collaboration** -- Multiple engineers can work on the same infrastructure
- **State locking** -- DynamoDB prevents two people from applying simultaneously
- **Recovery** -- S3 versioning lets you recover from state corruption
- **Security** -- State files contain sensitive data; keep them encrypted and access-controlled

### 2.5 Terraform Best Practices

| Practice | Why |
|----------|-----|
| Pin provider versions exactly | Prevent unexpected behavior from provider updates |
| Use remote state with locking | Prevent concurrent modifications |
| Never modify state files manually | Use `terraform state mv`, `terraform import` |
| Keep modules small and focused | One module = one logical resource group |
| Review `terraform plan` before every apply | The plan is your safety net |
| Tag all resources | Cost tracking, ownership, lifecycle management |
| Use variables for everything that differs between environments | DRY principle for infrastructure |
| Store tfvars files per environment | `dev.tfvars`, `staging.tfvars`, `prod.tfvars` |

### 2.6 Exercises

1. **Write a module** -- Create a VPC module with inputs for CIDR, AZs, and tags
2. **Use it twice** -- Instantiate the module for dev and prod with different parameters
3. **Remote state** -- Set up an S3 backend with DynamoDB locking
4. **Import** -- Create a resource manually, then import it into Terraform state
5. **Destroy safely** -- Use `terraform plan -destroy` to preview destruction before executing

---

## Phase 3: Monitoring Stacks

### 3.1 The Prometheus + Grafana Stack

The most common open-source monitoring stack:

- **Prometheus** -- Collects and stores metrics (time-series database)
- **Grafana** -- Visualizes metrics in dashboards
- **Alertmanager** -- Routes alerts based on rules (to Slack, PagerDuty, email)

### 3.2 How Prometheus Works

Prometheus uses a **pull model**. It scrapes metrics from your applications at regular intervals.

Your application exposes a `/metrics` endpoint. Prometheus reads it. No push required.

```
# Example Prometheus metrics output (text format)
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",path="/api/users",status="200"} 1234
http_requests_total{method="GET",path="/api/users",status="500"} 5
http_requests_total{method="POST",path="/api/users",status="201"} 89

# HELP http_request_duration_seconds HTTP request latency
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.01"} 500
http_request_duration_seconds_bucket{le="0.05"} 900
http_request_duration_seconds_bucket{le="0.1"} 1100
http_request_duration_seconds_bucket{le="0.5"} 1200
http_request_duration_seconds_bucket{le="1.0"} 1230
http_request_duration_seconds_bucket{le="+Inf"} 1234
```

### 3.3 PromQL -- Querying Metrics

```promql
# Request rate (requests per second over 5 minutes)
rate(http_requests_total[5m])

# Error rate (percentage of 5xx responses)
sum(rate(http_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))

# 95th percentile latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# CPU usage per container
rate(container_cpu_usage_seconds_total[5m])

# Memory usage as percentage
container_memory_usage_bytes / container_spec_memory_limit_bytes * 100
```

### 3.4 Alert Rules

```yaml
# prometheus-rules.yml
groups:
  - name: application
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m]))
          /
          sum(rate(http_requests_total[5m]))
          > 0.01
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }} (threshold: 1%)"
          runbook_url: "https://wiki.example.com/runbooks/high-error-rate"

      - alert: HighLatency
        expr: |
          histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 0.5
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High p95 latency"
          description: "p95 latency is {{ $value }}s (threshold: 500ms)"
```

### 3.5 Grafana Dashboards

Grafana connects to Prometheus and renders dashboards. Key panels for any service:

1. **Request rate** -- `rate(http_requests_total[5m])` -- Are we receiving traffic?
2. **Error rate** -- `sum(rate(http_requests_total{status=~"5.."}[5m]))` -- Are we failing?
3. **Latency percentiles** -- p50, p95, p99 -- How fast are we responding?
4. **CPU usage** -- Are we compute-bound?
5. **Memory usage** -- Are we leaking memory?
6. **Pod restarts** -- Is something crashing?

### 3.6 Local Monitoring Stack

```yaml
# docker-compose.monitoring.yml
version: "3.8"

services:
  prometheus:
    image: prom/prometheus:v2.50.0
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
      - "--storage.tsdb.retention.time=15d"

  grafana:
    image: grafana/grafana:10.3.0
    volumes:
      - grafana_data:/var/lib/grafana
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin

  alertmanager:
    image: prom/alertmanager:v0.27.0
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
    ports:
      - "9093:9093"

volumes:
  prometheus_data:
  grafana_data:
```

### 3.7 Exercises

1. **Deploy the monitoring stack** -- Run the docker-compose above and access Prometheus at :9090 and Grafana at :3001
2. **Instrument an app** -- Add a Prometheus client library to a web app and expose /metrics
3. **Build a dashboard** -- Create a Grafana dashboard with the four golden signals
4. **Write an alert** -- Create a Prometheus alert rule for error rate > 1%
5. **Trigger the alert** -- Generate errors in your app and verify the alert fires

---

## Phase 4: Multi-Environment Workflows

### 4.1 Environment Promotion

Code flows through environments with increasing scrutiny:

```
dev (automatic) -> staging (automatic) -> production (manual approval)
```

Each environment uses the same Docker image, the same Terraform modules, and the same pipeline stages. Only configuration differs (instance sizes, replica counts, domain names, secret values).

### 4.2 GitFlow for Infrastructure

```
main (production)
|
+-- develop (staging)
    |
    +-- feature/add-redis-cache (dev)
```

- Feature branches deploy to **dev** automatically
- Merges to `develop` deploy to **staging** automatically
- Merges to `main` require approval and deploy to **production**

### 4.3 Environment Parity

The number one cause of "works in staging, breaks in production" is environment drift. Minimize it:

| Same Across Environments | Different Per Environment |
|--------------------------|--------------------------|
| Docker images | Instance sizes |
| Terraform modules | Replica counts |
| Application code | Domain names |
| Pipeline stages | Secret values |
| Monitoring dashboards | Alert thresholds |
| Security policies | Alert routing |

### 4.4 Exercises

1. **Three environments** -- Create dev, staging, and prod Terraform configs using the same modules
2. **Pipeline promotion** -- Build a GitHub Actions workflow that deploys to dev on PR, staging on merge, production on approval
3. **Config separation** -- Use Kustomize overlays or Helm values to differentiate Kubernetes configs per environment
4. **Drift detection** -- Run `terraform plan` on a schedule and alert if unexpected changes are detected

---

## Phase 5: Secrets Management

### 5.1 Beyond Environment Variables

Environment variables work for simple cases but break down at scale:

- No audit trail (who accessed what, when)
- No rotation mechanism
- No encryption at rest in many CI/CD systems
- No access control (any process in the container can read them)

### 5.2 Secret Management Tools

| Tool | Best For | Model |
|------|----------|-------|
| **HashiCorp Vault** | Multi-cloud, enterprise | Self-hosted or cloud |
| **AWS Secrets Manager** | AWS-native workloads | Cloud service |
| **GCP Secret Manager** | GCP-native workloads | Cloud service |
| **SOPS** | Git-encrypted secrets | File encryption |
| **External Secrets Operator** | Kubernetes + any secret store | Kubernetes operator |

### 5.3 The External Secrets Pattern

The most practical pattern for Kubernetes: External Secrets Operator syncs secrets from a cloud secret manager into Kubernetes secrets.

```yaml
# external-secret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: app-secrets
  data:
    - secretKey: database-url
      remoteRef:
        key: myapp/prod/database-url
    - secretKey: api-key
      remoteRef:
        key: myapp/prod/api-key
```

### 5.4 Exercises

1. **SOPS** -- Encrypt a secrets file with SOPS and decrypt it in a CI pipeline
2. **AWS Secrets Manager** -- Store a database URL in Secrets Manager and retrieve it in a Terraform config
3. **External Secrets** -- Deploy External Secrets Operator to Minikube and sync a secret

---

## What Comes Next

The [Advanced Path](advanced.md) covers:

- Multi-cloud architecture and abstraction layers
- Service mesh (Istio, Linkerd) for mTLS and traffic management
- GitOps with ArgoCD or Flux
- Chaos engineering and resilience testing
- Platform engineering and internal developer platforms

---

## Plugin Recommendations for Intermediate

| Plugin | Why Use It Now |
|--------|---------------|
| [kubernetes-operations](../plugins/kubernetes-operations/) | Deep K8s deployment and troubleshooting |
| [terraform-patterns](../plugins/terraform-patterns/) | Module design and state management |
| [monitoring-observability](../plugins/monitoring-observability/) | Prometheus, Grafana, alerting patterns |
| [secret-management](../plugins/secret-management/) | Production-grade secrets handling |
| [networking-dns](../plugins/networking-dns/) | VPC design, DNS, and load balancing |
| [aws-infrastructure](../plugins/aws-infrastructure/) | AWS-specific patterns and services |
