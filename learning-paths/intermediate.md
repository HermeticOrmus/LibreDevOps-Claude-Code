# Intermediate Learning Path - Kubernetes, IaC & Monitoring

## Overview

This path moves from single-machine containers to production-grade infrastructure. You will orchestrate containers with Kubernetes, define infrastructure declaratively with Terraform, and build observability stacks that tell you what is happening before users complain. These are the tools and patterns that separate hobby deployments from systems that run at scale.

## Prerequisites

- Completed the Beginner Learning Path or equivalent experience
- Comfortable with Docker and Docker Compose
- Working CI/CD pipeline (GitHub Actions or equivalent)
- Basic networking knowledge (ports, DNS, HTTP, TLS)
- A cloud account (AWS, GCP, or Azure free tier)

## Modules

### Module 1: Kubernetes Fundamentals

#### Concepts

- Why Kubernetes: container orchestration solves scheduling, scaling, networking, and self-healing
- Architecture: control plane (API server, etcd, scheduler, controller manager) and worker nodes (kubelet, kube-proxy)
- Core objects: Pods, Deployments, Services, ConfigMaps, Secrets, Namespaces
- Declarative management: you describe desired state, Kubernetes reconciles actual state
- Networking: ClusterIP, NodePort, LoadBalancer, Ingress controllers
- Storage: PersistentVolumes, PersistentVolumeClaims, StorageClasses
- Resource management: requests and limits for CPU and memory
- Health checks: liveness probes (restart if dead), readiness probes (remove from traffic if not ready)
- Rolling updates and rollbacks: zero-downtime deployments by default
- Local development: kind (Kubernetes in Docker), minikube, k3d

#### Hands-On Exercise

Deploy your containerized application to Kubernetes:

1. Install `kind` and create a local cluster: `kind create cluster --name dev`
2. Write Kubernetes manifests:
   - `namespace.yaml`: isolate your application
   - `deployment.yaml`: 3 replicas, resource limits, health checks
   - `service.yaml`: ClusterIP service for internal access
   - `ingress.yaml`: expose the application externally
   - `configmap.yaml`: externalize configuration
3. Deploy and verify: `kubectl apply -f k8s/ && kubectl get pods -n myapp`
4. Test self-healing: `kubectl delete pod <pod-name>` and watch Kubernetes recreate it
5. Perform a rolling update: change the image tag and apply, watch pods cycle
6. Roll back: `kubectl rollout undo deployment/myapp -n myapp`

Verify: your application is accessible through the Ingress, survives pod deletion, and can be updated without downtime.

#### Key Takeaways

- Kubernetes is declarative: you describe what you want, not how to get there
- Health checks are not optional: without them, Kubernetes cannot self-heal
- Start with `kind` or `k3d` locally before touching cloud-managed Kubernetes
- Resource limits prevent one misbehaving pod from starving the cluster

### Module 2: Infrastructure as Code with Terraform

#### Concepts

- IaC philosophy: infrastructure defined in code, versioned, reviewed, and reproducible
- Terraform workflow: `init`, `plan`, `apply`, `destroy`
- HCL (HashiCorp Configuration Language): resources, data sources, variables, outputs
- State management: the state file tracks what Terraform manages; remote state for teams
- Modules: reusable infrastructure components with inputs and outputs
- Providers: plugins for AWS, GCP, Azure, Kubernetes, and hundreds of others
- Plan before apply: `terraform plan` shows what will change before anything changes
- Workspaces: managing multiple environments (dev, staging, prod) from one codebase
- Import: bringing existing infrastructure under Terraform management
- Drift detection: when someone changes infrastructure manually, Terraform notices

#### Hands-On Exercise

Provision cloud infrastructure with Terraform:

1. Install Terraform and configure a cloud provider (AWS free tier recommended)
2. Write Terraform configuration for:
   - A VPC with public and private subnets
   - A managed Kubernetes cluster (EKS, GKE, or AKS)
   - An RDS database instance (or equivalent)
   - IAM roles and policies following least privilege
3. Use variables for environment-specific values (region, instance size, cluster name)
4. Create a module for the VPC that can be reused across projects
5. Set up remote state in S3 (or equivalent) with state locking via DynamoDB
6. Run `terraform plan`, review the output, then `terraform apply`
7. Destroy everything: `terraform destroy` (verify nothing is left behind)

Document each resource with comments explaining why it exists, not just what it is.

#### Key Takeaways

- `terraform plan` is your safety net: never apply without reviewing the plan
- Remote state with locking is required for teams; local state is a single point of failure
- Modules enforce consistency: write once, deploy many times
- IaC means infrastructure changes go through code review, just like application changes

### Module 3: Monitoring with Prometheus and Grafana

#### Concepts

- The three pillars of observability: metrics, logs, traces
- Prometheus: pull-based metrics collection, time-series database, PromQL query language
- Grafana: visualization, dashboards, alerting across multiple data sources
- The RED method: Rate, Errors, Duration for request-driven services
- The USE method: Utilization, Saturation, Errors for resource-oriented monitoring
- Alerting: actionable alerts that wake someone up vs informational alerts that can wait
- Service Level Indicators (SLIs), Service Level Objectives (SLOs), and error budgets
- Log aggregation: structured logging, centralized collection (Loki, ELK, or Fluentd)
- Distributed tracing: following requests across service boundaries (Jaeger, Tempo)
- Instrumenting applications: exposing metrics endpoints, structured log output

#### Hands-On Exercise

Build a monitoring stack for your Kubernetes application:

1. Deploy Prometheus to your cluster using the kube-prometheus-stack Helm chart
2. Instrument your application to expose a `/metrics` endpoint with:
   - Request count by endpoint and status code
   - Request duration histogram
   - Active connections gauge
   - Application-specific business metrics (e.g., items processed)
3. Create Grafana dashboards for:
   - Application RED metrics (rate, errors, duration)
   - Kubernetes cluster health (CPU, memory, pod status)
   - Database connection pool and query latency
4. Set up alerts for:
   - Error rate exceeding 1% over 5 minutes
   - P99 latency exceeding 500ms
   - Pod restarts exceeding 3 in 10 minutes
   - Disk usage exceeding 80%
5. Deploy Loki for log aggregation and link logs to metrics in Grafana
6. Trigger an alert intentionally and verify the notification reaches you

#### Key Takeaways

- Monitoring is not optional: you cannot fix what you cannot see
- Good alerts are actionable: if the alert does not tell you what to do, it is noise
- SLOs turn "is the system healthy?" from an opinion into a measurement
- Structured logging is an investment that pays off the first time you debug a production issue

## Assessment

You have completed the intermediate path when you can:

1. Deploy and manage applications on Kubernetes with proper health checks and resource limits
2. Provision cloud infrastructure reproducibly with Terraform
3. Build a monitoring stack that surfaces problems before users report them
4. Define SLOs for a service and set up alerts based on error budgets
5. Explain the tradeoffs between managed and self-hosted Kubernetes

## Next Steps

- Move to the **Advanced Path**: multi-cloud, service mesh, GitOps, and chaos engineering
- Get certified: CKA (Certified Kubernetes Administrator) or Terraform Associate
- Read "Site Reliability Engineering" by Google for the philosophical foundation of production operations
- Practice incident response: run a game day where you break things and practice recovery
