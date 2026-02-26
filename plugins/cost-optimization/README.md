# Cost Optimization Plugin

FinOps Framework, AWS Cost Explorer, Savings Plans, Spot instances, Infracost CI, rightsizing, and tagging enforcement.

## Components

- **Agent**: `finops-analyst` -- Savings Plans vs RIs, Spot interruption handling, S3 lifecycle, NAT Gateway reduction
- **Command**: `/cost-optimize` -- Finds waste, gets Compute Optimizer recommendations, purchases Savings Plans, generates reports
- **Skill**: `finops-patterns` -- Spot ASG Terraform, gp2->gp3 migration, S3 lifecycle, VPC Endpoints, Infracost CI, tagging SCP

## Quick Wins (Do These First)

```bash
# 1. Convert gp2 volumes to gp3 (20% savings, zero risk)
aws ec2 describe-volumes --filters Name=volume-type,Values=gp2 \
  --query 'Volumes[].VolumeId' --output text | \
  xargs -I{} aws ec2 modify-volume --volume-id {} --volume-type gp3

# 2. Delete unattached EBS volumes
aws ec2 describe-volumes --filters Name=status,Values=available \
  --query 'Volumes[].VolumeId' --output text | \
  xargs -I{} aws ec2 delete-volume --volume-id {}

# 3. Add S3 Gateway Endpoint (free, eliminates NAT GW charges for S3 traffic)
aws ec2 create-vpc-endpoint --vpc-id vpc-xxx \
  --service-name com.amazonaws.us-east-1.s3 \
  --route-table-ids rtb-xxx

# 4. Enable Compute Optimizer
aws compute-optimizer update-enrollment-status --status Active
```

## Key Savings Strategies

| Strategy | Typical Savings | Effort | Risk |
|----------|----------------|--------|------|
| gp2 -> gp3 | 20% on EBS | Low | Very low |
| Compute Savings Plans (1yr) | 30-40% on EC2 | Low | Low |
| Spot for batch/CI | 60-80% on workers | Medium | Medium |
| S3 Lifecycle rules | 40-70% on old data | Low | Very low |
| S3 Gateway Endpoint | 100% of S3 NAT fees | Low | Very low |
| Rightsizing (Compute Optimizer) | 20-40% on oversized | Medium | Medium |
| Delete idle resources | 100% of waste | Low | Very low |

## Related Plugins

- [aws-infrastructure](../aws-infrastructure/) -- CDK constructs with cost-aware defaults
- [terraform-patterns](../terraform-patterns/) -- Infracost integration in Terraform workflows
- [kubernetes-operations](../kubernetes-operations/) -- KEDA and HPA for compute rightsizing
- [serverless-patterns](../serverless-patterns/) -- Lambda power tuning for cost/performance
