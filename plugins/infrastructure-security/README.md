# Infrastructure Security Plugin

CIS Benchmarks, Checkov IaC scanning, HashiCorp Vault, AWS Security Hub/GuardDuty, Security Groups, and CloudTrail analysis.

## Components

- **Agent**: `infrasec-engineer` -- CIS controls, custom Checkov checks, Vault dynamic secrets, GuardDuty remediation
- **Command**: `/infrasec` -- Runs Checkov/tfsec/Terrascan, remediates findings, audits IAM, applies CIS hardening
- **Skill**: `infrasec-patterns` -- Checkov CI YAML, Vault Agent injection, PKI engine, Security Hub Terraform, VPC flow logs

## Quick Reference

```bash
# Checkov: scan Terraform
checkov -d terraform/ --framework terraform --output cli --compact

# tfsec: fast alternative
tfsec terraform/

# Security Hub: critical findings
aws securityhub get-findings \
  --filters '{"SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"}],"RecordState":[{"Value":"ACTIVE","Comparison":"EQUALS"}]}' \
  --query 'Findings[:5].{Title:Title,Resource:Resources[0].Id}'

# GuardDuty: high-severity findings
aws guardduty list-findings --detector-id $DETECTOR_ID \
  --finding-criteria '{"Criterion":{"severity":{"Gte":7}}}'

# Remove SSH from internet (security group)
aws ec2 revoke-security-group-ingress \
  --group-id sg-xxx --protocol tcp --port 22 --cidr 0.0.0.0/0
```

## Security Layers

**Defense in depth**: No single control is sufficient. Layer multiple controls:
1. Organization-level: SCPs (deny public buckets, deny unapproved regions)
2. Account-level: GuardDuty, Security Hub, Config rules, CloudTrail
3. Network: Security Groups, NACLs, VPC Flow Logs, WAF
4. Compute: IMDSv2 required, SSM Session Manager (no SSH), no public IPs
5. Data: S3 Block Public Access, encryption at rest (KMS), Macie for PII
6. IAM: Least privilege, Permission Boundaries, Access Analyzer, no root keys
7. Application: Vault dynamic secrets, secrets rotation, code scanning

## Checkov Check Categories

| Prefix | Domain |
|--------|--------|
| CKV_AWS_* | AWS resources |
| CKV_K8S_* | Kubernetes manifests |
| CKV_DOCKER_* | Dockerfiles |
| CKV_TF_* | Terraform code patterns |
| CKV2_AWS_* | AWS advanced checks |

## Related Plugins

- [secret-management](../secret-management/) -- Vault KV, dynamic secrets, External Secrets Operator
- [aws-infrastructure](../aws-infrastructure/) -- IAM policies, SCPs, VPC security design
- [kubernetes-operations](../kubernetes-operations/) -- Pod security standards, NetworkPolicy
- [monitoring-observability](../monitoring-observability/) -- Security alerts and anomaly detection
