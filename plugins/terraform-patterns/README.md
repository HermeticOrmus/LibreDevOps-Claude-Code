# Terraform Patterns Plugin

HCL module authoring, S3 remote state with DynamoDB locking, for_each patterns, Terragrunt DRY configs, drift detection, and Terraform CI/CD.

## Components

- **Agent**: `terraform-engineer` -- Module structure, variable validation, state management, for_each vs count, Terragrunt, lifecycle rules
- **Command**: `/terraform` -- Plans, applies, manages state, imports resources, tests modules
- **Skill**: `terraform-patterns` -- Full RDS module example, GitHub Actions CI/CD pipeline, drift detection workflow, Terragrunt run-all

## Quick Reference

```bash
# Init + plan + apply
terraform init
terraform plan -out=tfplan -var-file=production.tfvars
terraform apply tfplan

# Detect drift
terraform plan -refresh-only

# Import existing resource
terraform import aws_s3_bucket.logs my-bucket-name

# Move resource in state (refactoring)
terraform state mv aws_instance.old module.ec2.aws_instance.app

# Format and validate
terraform fmt -recursive && terraform validate

# Security scan
checkov -d . --framework terraform
```

## State Management Rules

1. **Never edit state manually** -- use `terraform state mv/rm/import`
2. **Always use remote state** -- S3 + DynamoDB locking for teams
3. **State is not a backup** -- enable S3 versioning on the state bucket
4. **`prevent_destroy`** on production databases, state buckets, KMS keys
5. **Separate state per environment** -- production and staging never share state

## CI/CD Roles

Use two IAM roles with OIDC:
- **Plan role** (PR): Read-only + `sts:GetCallerIdentity`. Can't modify anything.
- **Apply role** (merge to main): Full permissions for managed resources, restricted to specific Terraform state paths.

Never use long-lived access keys in CI. Always OIDC.

## Related Plugins

- [aws-infrastructure](../aws-infrastructure/) -- AWS CDK as an alternative to Terraform
- [gcp-infrastructure](../gcp-infrastructure/) -- GCP Terraform modules
- [azure-infrastructure](../azure-infrastructure/) -- Azure Bicep vs Terraform
- [infrastructure-security](../infrastructure-security/) -- Checkov, tfsec scanning
- [cost-optimization](../cost-optimization/) -- Infracost with Terraform plans
