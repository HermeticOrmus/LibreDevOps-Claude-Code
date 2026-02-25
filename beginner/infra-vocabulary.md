# Infrastructure Vocabulary Guide

Essential terminology for working with infrastructure, DevOps, and cloud operations. Terms are grouped by category for reference.

---

## Infrastructure as Code

**IaC (Infrastructure as Code)**: Managing infrastructure through version-controlled configuration files instead of manual processes. Instead of clicking in a web console, you write code that describes what you want. Tools: Terraform, Pulumi, CloudFormation, CDK.

**Terraform**: An open-source IaC tool by HashiCorp that works across multiple cloud providers. Uses HCL (HashiCorp Configuration Language) to declare desired infrastructure state. Terraform plans changes, shows what will be created/modified/destroyed, then applies them.

**State**: The record of what infrastructure resources currently exist and their properties. Terraform stores state in a JSON file. Without state, Terraform would not know what already exists and would try to create duplicates. State must be stored remotely, encrypted, and protected with locking.

**State Locking**: A mechanism that prevents two people from modifying infrastructure simultaneously. Without locking, concurrent `terraform apply` operations can corrupt state. DynamoDB (AWS) or Cloud Storage (GCP) provide atomic locking.

**Drift**: When actual infrastructure differs from what is defined in code. Happens when someone makes manual changes in the cloud console (ClickOps) or when external processes modify resources. Detected by `terraform plan` showing unexpected changes.

**Plan**: Terraform's preview of what changes it will make. Shows resources to be created, modified, or destroyed. Always review the plan before applying. In CI/CD, the plan output is saved and the exact plan is applied (no surprises).

**Module**: A reusable package of Terraform configuration. Like a function in programming. Accepts inputs (variables), creates resources, and returns outputs. Example: a VPC module that creates subnets, route tables, and NAT gateways from a few input parameters.

**Provider**: A Terraform plugin that knows how to talk to a specific cloud or service API. The AWS provider creates AWS resources. The Kubernetes provider creates K8s objects. Providers should be version-pinned to prevent unexpected changes.

**Backend**: Where Terraform stores its state file. Local backend stores on disk (dangerous). Remote backends store in cloud storage (S3, GCS, Azure Blob) with encryption and locking. Always use a remote backend for shared infrastructure.

**Idempotent**: An operation that produces the same result whether executed once or multiple times. `terraform apply` is idempotent -- running it twice with no code changes makes no infrastructure changes. Essential property for safe automation.

---

## Containers

**Container**: A lightweight, standalone package that includes everything needed to run a piece of software: code, runtime, libraries, and system tools. Unlike a virtual machine, containers share the host OS kernel, making them fast to start and efficient to run.

**Docker**: The most common container platform. Docker builds container images from Dockerfiles and runs them as containers. Docker Compose orchestrates multiple containers locally.

**Image**: A read-only template used to create containers. Built in layers from a Dockerfile. Images are stored in registries (Docker Hub, ECR, GCR) and pulled to run as containers.

**Dockerfile**: A text file with instructions for building a Docker image. Each instruction (FROM, COPY, RUN) creates a layer. Multi-stage Dockerfiles use multiple FROM statements to separate build-time dependencies from the final production image.

**Container Registry**: A storage service for container images. Like a package registry but for Docker images. Examples: Docker Hub (public), Amazon ECR, Google GCR, GitHub Container Registry. Images are tagged with versions for traceability.

**Volume**: Persistent storage that survives container restarts. Containers are ephemeral by default -- when they stop, their filesystem is lost. Volumes mount external storage into the container for data that must persist (databases, uploads).

**Health Check**: A command or HTTP request that reports whether a container is functioning correctly. Orchestrators use health checks to detect unhealthy containers and replace them. Without health checks, a container that starts but does not work correctly goes undetected.

---

## Orchestration

**Kubernetes (K8s)**: An open-source container orchestration platform. Manages container deployment, scaling, networking, and health across a cluster of machines. The industry standard for running containers in production.

**Pod**: The smallest deployable unit in Kubernetes. Contains one or more containers that share networking and storage. Most pods contain a single application container. Pods are ephemeral and managed by controllers (Deployments, StatefulSets).

**Deployment**: A Kubernetes controller that manages a set of identical pods. Handles rolling updates, rollbacks, and scaling. You declare the desired state (3 replicas of version 1.2.3) and Kubernetes makes it so.

**Service**: A Kubernetes abstraction that provides a stable network endpoint for a set of pods. Pods come and go (scaling, updates, failures), but the service IP and DNS name remain constant. Types: ClusterIP (internal), NodePort, LoadBalancer (external).

**Namespace**: A logical partition within a Kubernetes cluster. Used to separate environments (dev, staging, production) or teams. Resource quotas and network policies can be applied per namespace.

**Helm**: A package manager for Kubernetes. Helm charts are templates for Kubernetes manifests with configurable values. Like a reusable deployment recipe. Charts can be shared via Helm repositories.

**Ingress**: A Kubernetes resource that manages external HTTP/HTTPS access to services. Provides URL routing, TLS termination, and load balancing. Requires an ingress controller (nginx, Traefik, ALB Ingress Controller).

---

## CI/CD

**CI (Continuous Integration)**: Automatically building and testing code every time changes are pushed. Catches bugs early by running tests on every commit. Tools: GitHub Actions, GitLab CI, Jenkins, CircleCI.

**CD (Continuous Delivery/Deployment)**: Continuous Delivery means code is always in a deployable state (manual approval to deploy). Continuous Deployment means every change that passes tests is automatically deployed to production. CD extends CI through the deployment pipeline.

**Pipeline**: A series of automated steps that code goes through from commit to production. Typical stages: build, test, security scan, deploy to staging, integration test, approve, deploy to production. Each stage is a quality gate.

**Artifact**: A build output that is stored and deployed. Container images, compiled binaries, compressed archives. Artifacts are tagged with version or commit SHA for traceability. Stored in registries or artifact stores (S3, Artifactory).

**OIDC (OpenID Connect)**: A protocol for authenticating CI/CD pipelines to cloud providers without storing long-lived credentials. GitHub Actions can assume an AWS IAM role via OIDC federation -- no access keys stored as secrets.

**Blue-Green Deployment**: Running two identical production environments (blue and green). Deploy to the inactive one, verify it works, then switch traffic. Instant rollback by switching back. Costs more (double infrastructure during deployment).

**Canary Deployment**: Deploying a new version to a small percentage of traffic (e.g., 5%), monitoring for errors, then gradually increasing. If errors spike, route all traffic back to the stable version. Lower risk than big-bang deployments.

**Rolling Update**: Gradually replacing old instances with new ones, a few at a time. Kubernetes default strategy. During the update, both old and new versions run simultaneously. Requires backward-compatible changes.

---

## Cloud Infrastructure

**VPC (Virtual Private Cloud)**: An isolated network within a cloud provider. You control the IP address range, subnets, route tables, and network gateways. All cloud resources should be in a VPC with proper network segmentation.

**Subnet**: A range of IP addresses within a VPC. Public subnets have a route to the internet (via Internet Gateway). Private subnets route through a NAT Gateway for outbound-only access. Databases and application servers belong in private subnets.

**Security Group**: A virtual firewall for cloud resources. Controls inbound and outbound traffic by protocol, port, and source/destination. Stateful: if you allow inbound traffic, the response is automatically allowed. Principle of least privilege applies.

**IAM (Identity and Access Management)**: The system that controls who (users, services, applications) can do what (read, write, delete) to which resources. IAM policies should follow least privilege: grant only the permissions needed, nothing more.

**Load Balancer**: A service that distributes incoming traffic across multiple instances. Application Load Balancer (ALB) operates at HTTP layer (routing by path, host). Network Load Balancer (NLB) operates at TCP layer (high performance). Essential for high availability.

**Auto-Scaling**: Automatically adjusting the number of running instances based on demand. Scale up when CPU/memory/request rate exceeds threshold. Scale down when load decreases. Prevents both under-provisioning (outages) and over-provisioning (waste).

**CDN (Content Delivery Network)**: A network of edge servers that cache content close to users. Reduces latency for static assets (images, CSS, JavaScript). Also provides DDoS protection and TLS termination. Examples: CloudFront, Cloudflare, Fastly.

---

## Monitoring and Observability

**Observability**: The ability to understand a system's internal state from its external outputs. Three pillars: metrics (numerical measurements over time), logs (timestamped event records), and traces (request flow through distributed systems).

**Metrics**: Numerical measurements collected over time. Examples: CPU utilization, request rate, error rate, response time. Stored in time-series databases (Prometheus, CloudWatch, Datadog). Used for dashboards and alerting.

**SLO (Service Level Objective)**: A target for service reliability. Example: "99.9% of requests complete successfully within 500ms." Measured over a rolling window (30 days). SLOs define the error budget -- how much unreliability is acceptable.

**SLI (Service Level Indicator)**: The actual measurement used to evaluate an SLO. If the SLO is "99.9% availability," the SLI is the ratio of successful requests to total requests. SLIs are derived from metrics.

**Error Budget**: The amount of unreliability allowed by an SLO. A 99.9% SLO gives a 0.1% error budget = ~43 minutes of downtime per month. When the error budget is exhausted, freeze feature deployments and focus on reliability.

**Alert**: A notification triggered when a metric exceeds a threshold. Good alerts are actionable (someone needs to do something), timely (detected quickly), and accurate (low false positive rate). Alert fatigue from noisy alerts is worse than no alerts.

**Dashboard**: A visual display of metrics and system health. Should answer "is everything working?" at a glance. The four golden signals: latency, traffic, errors, saturation.

**On-Call**: The practice of having an engineer available to respond to alerts outside business hours. On-call rotation ensures no single person is always responsible. Effective on-call requires good alerts, runbooks, and escalation procedures.

---

## Operations

**GitOps**: Using Git as the single source of truth for infrastructure and application state. Changes are made via pull requests. A controller (ArgoCD, Flux) continuously reconciles the actual state with the desired state in Git.

**Runbook**: A documented procedure for handling a specific operational scenario. Contains exact steps, commands, and decision points. Good runbooks enable anyone on the team (not just the expert) to resolve incidents.

**Post-Mortem**: A blameless analysis of an incident after it is resolved. Documents what happened, why, how it was detected, how it was resolved, and what changes will prevent recurrence. Blameless means focusing on systems, not people.

**Toil**: Repetitive, manual, automatable operational work that scales linearly with service growth. Examples: manually scaling instances, hand-rotating certificates, manually deploying. The goal is to automate toil away.

**FinOps**: The practice of bringing financial accountability to cloud spending. Involves cost allocation (tagging), optimization (right-sizing, reserved instances), and forecasting. Cloud bills can grow surprisingly fast without active management.

---

## Further Reading

- [The Phoenix Project](https://itrevolution.com/the-phoenix-project/) -- DevOps principles through narrative
- [Site Reliability Engineering](https://sre.google/sre-book/table-of-contents/) -- Google's SRE book (free online)
- [Terraform Up and Running](https://www.terraformupandrunning.com/) -- Practical Terraform guide
- [Kubernetes Documentation](https://kubernetes.io/docs/) -- Official K8s docs
- [Docker Documentation](https://docs.docker.com/) -- Official Docker docs

---

*Part of [LibreDevOps-Claude-Code](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code) -- MIT License*
