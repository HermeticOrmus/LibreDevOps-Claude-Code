# /terraform

Plan, apply, and manage Terraform infrastructure with proper state management, drift detection, and CI/CD integration.

## Usage

```
/terraform plan|apply|state|module [options]
```

## Actions

### `plan`
Plan and preview infrastructure changes.

```bash
# Initialize (first time or after backend change)
terraform init -reconfigure  # reconfigure backend
terraform init -upgrade      # Upgrade provider versions

# Plan with specific var file
terraform plan \
  -var-file="environments/production.tfvars" \
  -out=tfplan.binary

# Plan targeted resource only
terraform plan -target=aws_db_instance.main

# Check what will be destroyed (useful before apply)
terraform plan | grep "will be destroyed\|must be replaced"

# Plan with refresh disabled (faster, uses cached state)
terraform plan -refresh=false

# Generate JSON plan for programmatic analysis
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary | jq '.resource_changes[] | select(.change.actions[] == "delete")'

# infracost: cost estimation from plan
terraform plan -out=tfplan.binary
infracost breakdown --path tfplan.binary

# tflint: lint HCL
tflint --init
tflint --recursive

# checkov: security scanning
checkov -d . --framework terraform
checkov -d . --framework terraform --skip-check CKV_AWS_21,CKV_AWS_23
```

### `apply`
Apply infrastructure changes safely.

```bash
# Apply previously saved plan (exact plan, no drift)
terraform apply tfplan.binary

# Apply with var file
terraform apply -var-file="production.tfvars" -auto-approve

# Apply only targeted resources
terraform apply -target=module.vpc -target=aws_security_group.app

# Apply with detailed log output
TF_LOG=INFO terraform apply -var-file="production.tfvars"

# Destroy specific resource (careful!)
terraform destroy -target=aws_instance.old_worker -auto-approve

# Full destroy (staging only, never production without confirmation)
terraform destroy -var-file="staging.tfvars" -auto-approve

# Apply with parallelism (default 10, lower for API rate limits)
terraform apply -parallelism=5 -var-file="production.tfvars"

# Unlock state after failed apply
terraform force-unlock LOCK_ID
# Get lock ID from error message or: aws dynamodb scan --table-name terraform-state-locks
```

### `state`
Manage Terraform state.

```bash
# List all resources in state
terraform state list

# Show specific resource details
terraform state show aws_db_instance.main
terraform state show module.vpc.aws_subnet.private[\"us-east-1a\"]

# Import existing resource (bring under Terraform management)
terraform import aws_s3_bucket.logs my-existing-bucket-name

# Move resource (renaming or moving to module)
terraform state mv aws_instance.app module.ec2.aws_instance.app

# Remove resource from state (stop managing without destroying)
terraform state rm aws_s3_bucket.old_bucket

# Pull remote state locally
terraform state pull > state-backup.json

# Push state (use with extreme caution -- can corrupt state)
terraform state push state-backup.json

# Check state for drift
terraform plan -refresh-only -out=refresh.plan
terraform show -json refresh.plan | jq '.resource_changes[] | select(.change.actions != ["no-op"])'

# Accept drift (update state to match reality without making changes)
terraform apply -refresh-only -auto-approve

# List state versions (S3 backend)
aws s3api list-object-versions \
  --bucket myorg-terraform-state \
  --prefix environments/production/terraform.tfstate \
  --query 'Versions[*].{VersionId:VersionId,LastModified:LastModified}' \
  --output table
```

### `module`
Create, update, and test Terraform modules.

```bash
# Generate module documentation (terraform-docs)
terraform-docs markdown table --output-file README.md --output-mode inject .

# Validate module inputs
terraform validate

# Run module tests (Terraform 1.6+ built-in test framework)
terraform test

# Test with a specific test file
terraform test -filter=tests/basic.tftest.hcl

# Basic test file structure
cat << 'EOF' > tests/basic.tftest.hcl
variables {
  name        = "test"
  environment = "development"
}

run "creates_vpc" {
  command = plan

  assert {
    condition     = aws_vpc.main.enable_dns_hostnames == true
    error_message = "VPC must have DNS hostnames enabled"
  }
}

run "validates_environment" {
  command = plan

  variables {
    environment = "invalid"
  }

  expect_failures = [var.environment]
}
EOF

# Check module for known issues
tflint --module
checkov -d . --framework terraform

# Format all HCL files
terraform fmt -recursive

# Check formatting without modifying
terraform fmt -recursive -check -diff
```
