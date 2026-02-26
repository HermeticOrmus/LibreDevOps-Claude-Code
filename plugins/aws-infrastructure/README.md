# AWS Infrastructure Plugin

AWS CDK, CloudFormation, VPC design, ECS/EKS, RDS, IAM, and Well-Architected patterns for production AWS infrastructure.

## Components

- **Agent**: `aws-architect` -- Designs three-tier VPCs, ECS services, Aurora clusters, IAM policies, and CDK stacks
- **Command**: `/aws` -- Generates CDK TypeScript, audits IAM/Security Groups, analyzes costs, runs Config checks
- **Skill**: `aws-patterns` -- CDK constructs, CloudFront/S3 SPA hosting, Aurora v2, Config rules, CloudTrail

## When to Use

- Designing new AWS infrastructure from scratch (VPC, compute, database)
- Writing AWS CDK in TypeScript with correct L2/L3 constructs
- Auditing IAM policies for least-privilege violations
- Setting up security baseline (GuardDuty, Security Hub, Config, CloudTrail)
- Optimizing costs (Savings Plans, rightsizing, unused resource cleanup)
- Implementing CloudFront distributions, Route53 routing, ACM certificates

## Quick Reference

```bash
# CDK workflow
cdk synth --context env=prod  # Generate CloudFormation
cdk diff --context env=prod   # Review changes
cdk deploy --require-approval broadening --context env=prod

# Find security issues
aws securityhub get-findings \
  --filters '{"SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"}]}'

# Cost analysis by service (last 30 days)
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '-30 days' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# Unattached EBS volumes (wasted spend)
aws ec2 describe-volumes \
  --filters Name=status,Values=available \
  --query 'Volumes[].{ID:VolumeId,Size:Size}'
```

## Key Architectural Decisions

**VPC Subnets**: Three tiers -- public (ALB, NAT GW), private (ECS, Lambda), isolated (RDS, ElastiCache). Never put databases in public subnets.

**IAM**: Roles only, never IAM users with long-lived access keys on compute. Permission Boundaries for developer roles. SCPs at Organization level for guardrails.

**Secrets**: Secrets Manager for rotatable secrets (DB passwords, API keys). SSM Parameter Store for non-secret config (free tier for standard parameters).

**Compute**: Graviton3 instances for up to 40% better price/performance. Spot instances for batch/CI workloads (70% discount, handle interruptions). Fargate for containers when scale is unpredictable.

**Cost**: VPC Endpoints (S3, ECR, Secrets Manager) eliminate NAT Gateway data transfer charges for internal AWS traffic. Single NAT GW for dev, one per AZ for production HA.

## Related Plugins

- [terraform-patterns](../terraform-patterns/) -- Terraform alternative to CDK for multi-cloud
- [kubernetes-operations](../kubernetes-operations/) -- EKS cluster operations and Helm
- [infrastructure-security](../infrastructure-security/) -- Checkov scanning, CIS benchmarks
- [cost-optimization](../cost-optimization/) -- Infracost, FinOps Framework, tagging strategy
- [secret-management](../secret-management/) -- HashiCorp Vault and External Secrets Operator
