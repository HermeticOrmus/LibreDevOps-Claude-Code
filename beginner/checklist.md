# Pre-Deployment Infrastructure Checklist

Before asking Claude Code to create or modify infrastructure, verify these considerations. Copy this checklist into your prompt or review it mentally before each request.

---

## State Management

- [ ] **State backend configured**: Is Terraform using a remote backend (S3, GCS, Azure Blob) with encryption and locking?
- [ ] **State locking enabled**: Is DynamoDB or equivalent configured to prevent concurrent modifications?
- [ ] **State per environment**: Does each environment (dev, staging, prod) have its own isolated state file?
- [ ] **State backup**: Is versioning enabled on the state bucket for recovery?

## Secrets and Credentials

- [ ] **No hardcoded secrets**: Are all passwords, API keys, tokens, and connection strings sourced from a secret manager or environment variables?
- [ ] **No secrets in state**: Are sensitive values marked with `sensitive = true` in Terraform? Is state encrypted at rest?
- [ ] **No secrets in images**: Are Docker images clean of credentials? Secrets injected at runtime only?
- [ ] **No secrets in CI logs**: Are secret values masked in pipeline output?
- [ ] **Rotation plan**: Is there a documented procedure for rotating each credential type?

## Networking

- [ ] **Private subnets for compute**: Are application servers, databases, and caches in private subnets?
- [ ] **Load balancer in public subnet**: Is only the load balancer internet-facing?
- [ ] **Security groups scoped**: Are security group rules as restrictive as possible (no 0.0.0.0/0 for management ports)?
- [ ] **VPC endpoints**: Are VPC endpoints configured for frequently accessed AWS services (S3, ECR, Secrets Manager)?
- [ ] **DNS configured**: Are DNS records managed via IaC (not manually)?

## Containers

- [ ] **Version pinned**: Are Docker base images using specific versions (not `:latest`)?
- [ ] **Non-root user**: Does the container run as a non-root user?
- [ ] **Health check defined**: Does the Dockerfile include a HEALTHCHECK instruction?
- [ ] **Resource limits set**: Are CPU and memory limits defined in the orchestrator (Docker Compose, K8s, ECS)?
- [ ] **Multi-stage build**: Is the Dockerfile using multi-stage builds to minimize the production image?
- [ ] **No unnecessary tools**: Is the production image stripped of build tools, package managers, and debug utilities?

## CI/CD Pipeline

- [ ] **Tests pass before deploy**: Does the pipeline gate deployment on test results?
- [ ] **Security scanning**: Are container images scanned for vulnerabilities (Trivy, Snyk)?
- [ ] **Secret scanning**: Are commits scanned for leaked credentials (trufflehog, gitleaks)?
- [ ] **IaC scanning**: Is Terraform scanned for misconfigurations (tfsec, checkov)?
- [ ] **Environment separation**: Does staging deploy before production? Is there an approval gate?
- [ ] **OIDC authentication**: Is the pipeline using OIDC to cloud providers instead of long-lived credentials?
- [ ] **Rollback procedure**: If the deployment fails, how is the previous version restored?

## Monitoring and Observability

- [ ] **Health checks on all services**: Do load balancers and orchestrators check service health?
- [ ] **Metrics collected**: Are the four golden signals monitored (latency, traffic, errors, saturation)?
- [ ] **Alerts configured**: Are alerts set for error rate, latency, and resource saturation?
- [ ] **Alert routing**: Do critical alerts page on-call? Do warnings go to Slack/email?
- [ ] **Dashboards created**: Is there an overview dashboard showing service health at a glance?
- [ ] **Log retention set**: Are log groups configured with appropriate retention (not infinite)?

## Backup and Recovery

- [ ] **Database backups automated**: Are daily backups configured with appropriate retention?
- [ ] **Backup restore tested**: Has a backup been restored in a test environment recently?
- [ ] **Disaster recovery documented**: Is the failover procedure written and accessible?
- [ ] **RPO and RTO defined**: Are recovery objectives documented and achievable with current setup?

## Cost

- [ ] **Resources tagged**: Do all cloud resources have Project, Environment, ManagedBy, and CostCenter tags?
- [ ] **Instance sizes appropriate**: Are dev/staging using smaller instances than production?
- [ ] **Cost estimate reviewed**: Has the estimated monthly cost been calculated (Terraform, Infracost, or provider calculator)?
- [ ] **Cleanup documented**: Can all resources be destroyed cleanly (terraform destroy, helm uninstall)?

## Infrastructure Code Quality

- [ ] **Version constraints**: Are Terraform providers, Helm charts, and GitHub Actions pinned to exact versions?
- [ ] **Variables documented**: Do all Terraform variables have descriptions and appropriate defaults?
- [ ] **Outputs defined**: Are important values (endpoints, IDs, ARNs) exported as outputs?
- [ ] **Naming conventions followed**: Do resource names follow a consistent pattern?

---

## Quick Copy-Paste Suffix

Append this to any Claude Code prompt for infrastructure work:

```
Infrastructure requirements:
- Remote state backend with locking and encryption
- All secrets from secret manager or environment variables (never hardcoded)
- Resources in private subnets (only LB in public)
- Health checks on all services
- Resource limits (CPU, memory) on all containers
- Version pinning on all images, providers, and actions
- Tags on all resources: Project, Environment, ManagedBy
- CloudWatch alarms for error rate, latency, and CPU
- Output important values (endpoints, IDs)
```

---

*Part of [LibreDevOps-Claude-Code](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code) -- MIT License*
