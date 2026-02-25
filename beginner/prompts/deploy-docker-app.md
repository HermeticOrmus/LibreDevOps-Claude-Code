# Prompt Template: Deploy a Dockerized Application to Production

This document provides a copy-paste-ready prompt for deploying a containerized application with Claude Code. It demonstrates the difference between a vague prompt that produces tutorial-grade configs and a precise prompt that produces production-grade infrastructure.

---

## The Vague Version (Do Not Use)

```
Deploy my Node.js app with Docker to AWS.
```

**What Claude generates**: A basic Dockerfile, maybe `docker-compose.yml`, an EC2 instance with Docker installed. No load balancer, no auto-scaling, no health checks, no monitoring, state stored locally, secrets hardcoded, everything in the default VPC with a public IP.

---

## The Precise Version (Use This)

```
Deploy a Node.js API application to AWS using Docker containers.
This is a production SaaS application serving 10,000 daily active users.

## Container Image

Create a multi-stage Dockerfile:
- Build stage: node:22-alpine, npm ci, npm run build
- Production stage: node:22-alpine, non-root user (uid 1001),
  only production dependencies and built artifacts
- HEALTHCHECK: wget to /health endpoint, 30s interval, 5s timeout,
  3 retries, 10s start period
- No secrets in the image -- all config via environment variables

## Infrastructure (Terraform)

State management:
- S3 backend with DynamoDB locking
- Encrypted state (AES-256)
- Separate state file: environments/prod/compute/terraform.tfstate

Networking:
- Custom VPC (10.0.0.0/16)
- 2 public subnets (for ALB) across 2 AZs
- 2 private subnets (for ECS tasks) across 2 AZs
- NAT gateway for outbound traffic from private subnets
- VPC endpoints for ECR, S3, CloudWatch Logs, Secrets Manager

Compute (ECS Fargate):
- Task definition: 512 CPU, 1024 MB memory
- Service: desired count 3, deployment minimum 66%, maximum 200%
- ALB with HTTPS listener (ACM certificate), health check on /health
- Auto-scaling: target tracking on CPU (70%) and memory (80%),
  min 3, max 10 instances
- Log driver: awslogs with 90-day retention

Secrets:
- DATABASE_URL from AWS Secrets Manager
- API_KEYS from AWS Secrets Manager
- Injected as ECS secrets (not environment variables in task def)
- IAM execution role with minimal Secrets Manager access

Tags on all resources:
- Project: myapp
- Environment: production
- ManagedBy: terraform
- CostCenter: engineering

## CI/CD Pipeline (GitHub Actions)

Trigger: push to main branch (after PR merge)

Stages:
1. Test: npm ci, npm test, npm run lint
2. Security: trufflehog for secrets, trivy for container scan
3. Build: docker build, push to ECR with git SHA tag
4. Deploy staging: update ECS task definition, wait for stable
5. Health check staging: verify /health returns 200
6. Manual approval: required for production
7. Deploy production: update ECS task definition, wait for stable
8. Health check production: verify /health returns 200
9. Rollback: if health check fails, revert to previous task definition

Authentication: OIDC to AWS (no long-lived credentials)

## Monitoring

CloudWatch:
- Dashboard: CPU, memory, request count, error rate, latency p50/p95/p99
- Alarms:
  - 5xx error rate > 1% for 5 minutes -> Critical (SNS -> PagerDuty)
  - p99 latency > 2s for 10 minutes -> Warning (SNS -> Slack)
  - CPU > 80% for 15 minutes -> Warning (SNS -> Slack)
  - Unhealthy host count > 0 for 5 minutes -> Critical (SNS -> PagerDuty)
  - ECS service desired != running for 5 minutes -> Critical

## Outputs

Provide:
- Terraform files (backend, variables, main, outputs)
- Dockerfile
- GitHub Actions workflow
- Deploy script (deploy.sh)
- Health check script (health-check.sh)
```

---

## Why This Works

The precise version specifies:

1. **Scale context**: "10,000 daily active users" tells Claude the reliability requirements.
2. **State management**: S3 backend with locking -- not local state.
3. **Network architecture**: Private subnets for compute, public for load balancer. VPC endpoints to reduce NAT costs and improve security.
4. **Secret handling**: Secrets Manager with IAM, not hardcoded or in environment variables visible in task definition.
5. **Deployment strategy**: Blue-green via ECS with rollback on failure.
6. **Monitoring**: Specific alerts with thresholds, not "add monitoring."
7. **CI/CD with gates**: Sequential deployment with health checks and manual approval.

The vague version leaves all of these decisions to Claude's defaults, which optimize for "it starts" not "it stays running."

---

## Adapting This Template

To use this template for your own deployment:

1. Replace the application type and scale requirements
2. Adjust the compute resources (CPU, memory) based on your application's needs
3. Modify the auto-scaling parameters based on your traffic patterns
4. Update the monitoring thresholds based on your SLOs
5. Add any compliance-specific requirements (encryption, logging, access controls)

The structure -- container, infrastructure, CI/CD, monitoring -- applies to every deployment. Keep it as a checklist.

---

*Part of [LibreDevOps-Claude-Code](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code) -- MIT License*
