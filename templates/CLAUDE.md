# Infrastructure Configuration -- CLAUDE.md Template

> Paste this into your project's `CLAUDE.md` file and customize each section for your infrastructure.
> Remove sections that do not apply. Fill in every section you keep -- incomplete configuration
> gives incomplete infrastructure.

---

## Project Infrastructure Profile

- **Project Name:** [your-project-name]
- **Environment:** [Production / Staging / Development / All]
- **Cloud Provider(s):** [AWS / GCP / Azure / Multi-cloud / On-premises / Hybrid]
- **IaC Tool:** [Terraform / Pulumi / CloudFormation / CDK / Ansible / None]
- **Container Runtime:** [Docker / Podman / containerd / None]
- **Orchestration:** [Kubernetes / ECS / Nomad / Docker Compose / None]
- **CI/CD Platform:** [GitHub Actions / GitLab CI / Jenkins / CircleCI / None]

---

## Infrastructure Standards

### IaC Tool Configuration

```
# Terraform configuration:
# - Version: >= 1.6.0
# - Backend: S3 + DynamoDB (state locking)
# - State file: one per environment (dev/staging/prod)
# - Module structure: modules/ for reusable, environments/ for instantiation
# - Naming convention: {project}-{env}-{resource} (e.g., myapp-prod-vpc)
# - Provider pinning: exact version constraints (= not ~>)
#
# State backend:
# - Bucket: {project}-terraform-state-{account-id}
# - DynamoDB table: {project}-terraform-locks
# - Encryption: AES-256 (SSE-S3) or KMS
# - Versioning: enabled (state file recovery)
# - Access: IAM role per environment, no cross-env access
```

### Module Structure

```
infrastructure/
+-- modules/                    # Reusable Terraform modules
|   +-- networking/             # VPC, subnets, security groups
|   +-- compute/                # EC2, ECS, Lambda
|   +-- database/               # RDS, DynamoDB, ElastiCache
|   +-- monitoring/             # CloudWatch, alerts, dashboards
|   +-- security/               # IAM, KMS, WAF
+-- environments/
|   +-- dev/                    # Development environment
|   |   +-- main.tf
|   |   +-- variables.tf
|   |   +-- terraform.tfvars
|   +-- staging/                # Staging environment
|   +-- prod/                   # Production environment
+-- scripts/                    # Deployment and utility scripts
```

### Naming Conventions

| Resource | Pattern | Example |
|----------|---------|---------|
| VPC | `{project}-{env}-vpc` | `myapp-prod-vpc` |
| Subnet | `{project}-{env}-{type}-{az}` | `myapp-prod-private-us-east-1a` |
| Security Group | `{project}-{env}-{service}-sg` | `myapp-prod-api-sg` |
| IAM Role | `{project}-{env}-{service}-role` | `myapp-prod-api-role` |
| S3 Bucket | `{project}-{env}-{purpose}-{account-id}` | `myapp-prod-assets-123456789` |
| RDS Instance | `{project}-{env}-{engine}` | `myapp-prod-postgres` |
| ECS Service | `{project}-{env}-{service}` | `myapp-prod-api` |
| K8s Namespace | `{project}-{env}` | `myapp-staging` |

---

## CI/CD Pipeline Requirements

### Pipeline Stages

```
Code Push -> Lint/Validate -> Test -> Build -> Security Scan -> Deploy Dev -> Deploy Staging -> Approval -> Deploy Prod
```

### Quality Gates

| Stage | Gate | Blocking |
|-------|------|----------|
| Validate | `terraform validate`, `terraform fmt -check` | Yes |
| Test | Unit tests pass, integration tests pass | Yes |
| Security | No CRITICAL/HIGH vulnerabilities in dependencies | Yes |
| Security | No secrets detected in code (gitleaks/trufflehog) | Yes |
| Security | Container image scan (Trivy) -- no CRITICAL | Yes |
| IaC Scan | `tfsec` or `checkov` -- no HIGH findings | Yes |
| Plan | `terraform plan` output reviewed | Yes (production) |
| Deploy Staging | Health checks pass within 5 minutes | Yes |
| Approval | Manual approval for production | Yes |
| Deploy Prod | Canary passes health checks, rollback on failure | Yes |

### Deployment Strategy

```
# Strategy: [Blue-Green / Canary / Rolling / Recreate]
#
# Blue-Green:
# - Provision new environment alongside existing
# - Switch traffic via load balancer / DNS
# - Keep old environment for instant rollback
# - Destroy old environment after validation period (24h)
#
# Canary:
# - Deploy to 5% of traffic
# - Monitor error rate, latency, saturation for 15 minutes
# - Promote to 25%, 50%, 100% if metrics healthy
# - Auto-rollback if error rate exceeds baseline by 2x
#
# Rollback:
# - Automated: revert to previous task definition / deployment
# - Manual: `terraform apply` with previous state
# - Database: migration rollback scripts tested and available
# - DNS: TTL set to 60s for fast failover
```

---

## Monitoring Requirements

### Metrics to Collect

```
# Application metrics (RED method):
# - Request Rate: requests per second by endpoint
# - Error Rate: 4xx and 5xx responses per second
# - Duration: p50, p95, p99 latency by endpoint
#
# Infrastructure metrics (USE method):
# - Utilization: CPU, memory, disk, network per host/container
# - Saturation: queue depth, connection pool usage, thread count
# - Errors: OOM kills, disk failures, network errors
#
# Business metrics:
# - [Define per application: signups, transactions, etc.]
```

### Alert Definitions

| Alert | Condition | Severity | Runbook |
|-------|-----------|----------|---------|
| High Error Rate | 5xx > 1% of traffic for 5 min | Critical | `/runbooks/high-error-rate.md` |
| High Latency | p99 > 2s for 10 min | Warning | `/runbooks/high-latency.md` |
| CPU Saturation | CPU > 80% for 15 min | Warning | `/runbooks/cpu-saturation.md` |
| Disk Space | Disk > 85% usage | Warning | `/runbooks/disk-space.md` |
| Health Check Fail | 3 consecutive failures | Critical | `/runbooks/health-check-fail.md` |
| Certificate Expiry | TLS cert expires in < 14 days | Warning | `/runbooks/cert-expiry.md` |
| State Lock Stuck | Terraform lock held > 30 min | Warning | `/runbooks/state-lock.md` |
| Deployment Failed | Deploy did not complete in 15 min | Critical | `/runbooks/deploy-failure.md` |

### SLO Definitions

```
# Service Level Objectives:
#
# Availability:
# - Target: 99.9% (43.8 minutes downtime per month)
# - Measurement: successful responses / total responses
# - Window: 30-day rolling
# - Error budget: 0.1% = ~43 minutes
#
# Latency:
# - Target: 95% of requests < 500ms
# - Measurement: p95 response time
# - Window: 30-day rolling
#
# Burn rate alerts:
# - 14.4x burn rate for 5 min -> page (1-hour budget exhaustion)
# - 6x burn rate for 30 min -> page (6-hour budget exhaustion)
# - 3x burn rate for 6 hours -> ticket (3-day budget exhaustion)
# - 1x burn rate for 3 days -> ticket (budget trending to exhaust)
```

---

## Secret Management Policy

### Rules

1. **No hardcoded secrets.** Not in Terraform, not in Docker, not in CI configs, not in Helm values, not in Ansible vars.
2. **No secrets in state files without encryption.** Terraform state must be encrypted at rest.
3. **No secrets in container images.** Inject at runtime via environment variables or mounted secrets.
4. **No secrets in git history.** If committed accidentally, rotate immediately -- do not just delete.
5. **No long-lived credentials.** Use IAM roles, OIDC federation, or short-lived tokens where possible.

### Secret Storage

```
# Provider: [HashiCorp Vault / AWS Secrets Manager / GCP Secret Manager / Azure Key Vault]
# Access method: [IAM role / service account / OIDC / Kubernetes auth]
# Injection method: [environment variable / mounted file / sidecar]
#
# CI/CD secrets:
# - GitHub Actions: repository secrets or OIDC to cloud provider
# - GitLab CI: CI/CD variables (masked, protected)
# - Jenkins: credentials plugin with appropriate scope
#
# Kubernetes secrets:
# - Method: External Secrets Operator + cloud secret manager
# - NOT: plain Kubernetes secrets (base64 is not encryption)
```

### Rotation Policy

| Secret Type | Rotation | Automated |
|-------------|----------|-----------|
| IAM access keys | 90 days | Yes (rotate-keys script) |
| Database credentials | 90 days | Yes (Secrets Manager rotation) |
| TLS certificates | Before expiry | Yes (cert-manager / ACME) |
| API keys (third-party) | 90 days | No (manual, documented procedure) |
| SSH keys | 180 days | No (manual, documented procedure) |
| Encryption keys (KMS) | Annual | Yes (automatic key rotation) |

---

## Environment Strategy

### Environment Parity

```
# All environments use the same:
# - Terraform modules (parameterized by environment)
# - Docker images (same image, different config)
# - CI/CD pipeline (same stages, different approval gates)
# - Monitoring stack (same dashboards, different alert thresholds)
#
# Environments differ in:
# - Instance sizes / replica counts
# - Domain names and TLS certificates
# - Secret values
# - Feature flags
# - Alert routing (dev -> Slack, prod -> PagerDuty)
```

### Environment Configuration

| Setting | Dev | Staging | Prod |
|---------|-----|---------|------|
| Instance type | t3.small | t3.medium | m6i.large |
| Replicas | 1 | 2 | 3 (min), 10 (max) |
| Database | db.t3.micro, single-AZ | db.t3.small, single-AZ | db.r6g.large, multi-AZ |
| Auto-scaling | Disabled | Enabled (relaxed) | Enabled (strict) |
| Backup retention | 1 day | 7 days | 30 days |
| Monitoring | Basic | Full, alerts to Slack | Full, alerts to PagerDuty |
| Deploy approval | Automatic | Automatic | Manual |
| Log retention | 7 days | 14 days | 90 days |

---

## Disaster Recovery Requirements

### RPO and RTO

```
# Recovery Point Objective (RPO): maximum acceptable data loss
# - Database: 1 hour (point-in-time recovery)
# - Object storage: 0 (cross-region replication)
# - Application state: 0 (stateless, recoverable from database)
#
# Recovery Time Objective (RTO): maximum acceptable downtime
# - Full region failure: 4 hours (failover to secondary region)
# - Single service failure: 5 minutes (auto-restart / auto-scaling)
# - Database failure: 15 minutes (automatic failover to standby)
# - DNS propagation: 5 minutes (TTL = 60s, health-checked routing)
```

### Backup Strategy

```
# Database backups:
# - Automated daily snapshots, retained 30 days
# - Point-in-time recovery enabled (5-minute granularity)
# - Cross-region snapshot copy for DR
# - Monthly restore test (automated, results logged)
#
# Infrastructure state:
# - Terraform state versioned in S3 (recover any previous state)
# - Git history preserves all IaC changes
# - Runbook: recovering from state corruption
#
# Application data:
# - S3 objects: versioning enabled, cross-region replication
# - EBS volumes: daily snapshots, 7-day retention
# - Secrets: backed up to secondary secret manager in DR region
```

### Failover Procedure

```
# Automated failover:
# 1. Health check fails for primary region (3 consecutive failures)
# 2. Route 53 / Cloud DNS routes traffic to secondary region
# 3. Secondary region auto-scales to handle full traffic
# 4. Alert fires: "Regional failover activated"
# 5. On-call engineer verifies failover, begins root cause analysis
#
# Manual failover (if automated fails):
# 1. Confirm primary region is unavailable
# 2. Run: ./scripts/failover.sh --target-region us-west-2
# 3. Verify health checks pass in secondary region
# 4. Update DNS if not automatically routed
# 5. Notify stakeholders via incident channel
#
# Failback procedure:
# 1. Confirm primary region is healthy
# 2. Sync data from secondary to primary (check for conflicts)
# 3. Gradually shift traffic back (25% -> 50% -> 100%)
# 4. Monitor for 24 hours before decommissioning DR scaling
```

---

## Claude Code Infrastructure Directives

When working on this project, Claude Code must:

1. **Always include state backend configuration** in Terraform files. Never generate Terraform without a backend block.
2. **Never hardcode secrets** in any infrastructure file. Use variable references, environment variables, or secret manager lookups.
3. **Always include resource tags** on cloud resources: `Project`, `Environment`, `ManagedBy=terraform`, `CostCenter`.
4. **Set resource limits** on all containers: CPU and memory limits in Docker Compose, Kubernetes manifests, and ECS task definitions.
5. **Use private subnets** for databases, caches, and internal services. Only load balancers and bastion hosts in public subnets.
6. **Enable encryption** at rest and in transit by default. TLS for all connections. Encrypted volumes and buckets.
7. **Include health checks** in every service definition: Docker HEALTHCHECK, Kubernetes readiness/liveness probes, ALB health checks.
8. **Pin versions** for all dependencies: Terraform providers, Docker base images, Helm charts, GitHub Actions.
9. **Generate monitoring** alongside infrastructure: CloudWatch alarms, Prometheus rules, or Datadog monitors for every new resource.
10. **Follow the naming conventions** defined in this document for all resource names.
