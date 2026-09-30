# /infrasec

Scan IaC for misconfigurations, remediate security findings, audit IAM, and harden infrastructure.

## Usage

```
/infrasec scan|remediate|audit|harden [options]
```

## Actions

### `scan`
Run Checkov, tfsec, and AWS Inspector against infrastructure code and deployed resources.

```bash
# Checkov: scan Terraform directory
checkov -d terraform/ --framework terraform --output cli --compact

# Checkov: scan with specific check list
checkov -d terraform/ \
  --check CKV_AWS_18,CKV_AWS_19,CKV_AWS_21,CKV_AWS_57,CKV_AWS_86

# tfsec: fast Terraform security scanner
tfsec terraform/ --format lovely

# Terrascan: YAML-based policies
terrascan scan -i terraform -t aws

# Scan Kubernetes manifests
checkov -d kubernetes/ --framework kubernetes
kube-score score kubernetes/*.yaml

# Scan Dockerfiles
hadolint Dockerfile
checkov -d . --framework dockerfile

# AWS: run Security Hub findings
aws securityhub get-findings \
  --filters '{
    "SeverityLabel": [{"Value":"CRITICAL","Comparison":"EQUALS"},{"Value":"HIGH","Comparison":"EQUALS"}],
    "RecordState": [{"Value":"ACTIVE","Comparison":"EQUALS"}],
    "WorkflowStatus": [{"Value":"NEW","Comparison":"EQUALS"}]
  }' \
  --query 'Findings | sort_by(@, &Severity.Normalized) | reverse(@) | [:10].{Title:Title,Resource:Resources[0].Id,Severity:Severity.Label}' \
  --output table
```

### `remediate`
Fix specific security findings with code.

```bash
# Fix: S3 bucket public access not blocked
aws s3api put-public-access-block \
  --bucket my-bucket \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Fix: EBS not encrypted by default
aws ec2 enable-ebs-encryption-by-default --region us-east-1

# Fix: S3 bucket logging not enabled
aws s3api put-bucket-logging \
  --bucket my-bucket \
  --bucket-logging-status '{
    "LoggingEnabled": {
      "TargetBucket": "my-access-logs-bucket",
      "TargetPrefix": "my-bucket/"
    }
  }'

# Fix: Security group with 0.0.0.0/0 SSH
# First: find the offending rule
aws ec2 describe-security-groups \
  --filters Name=ip-permission.cidr,Values='0.0.0.0/0' \
            Name=ip-permission.from-port,Values=22 \
  --query 'SecurityGroups[].{GroupId:GroupId,GroupName:GroupName}'

# Then: remove the rule
aws ec2 revoke-security-group-ingress \
  --group-id sg-xxxxxxxxxxxxxxxxx \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# Fix: GuardDuty not enabled
aws guardduty create-detector --enable \
  --finding-publishing-frequency FIFTEEN_MINUTES \
  --data-sources '{
    "S3Logs": {"Enable": true},
    "Kubernetes": {"AuditLogs": {"Enable": true}}
  }'
```

### `audit`
Audit IAM permissions, key rotation, and compliance posture.

```bash
# Generate IAM credential report
aws iam generate-credential-report
sleep 5
aws iam get-credential-report \
  --query 'Content' \
  --output text | base64 -d | \
  csvkit -H | \
  awk -F',' '
    $10 != "false" && $5 != "N/A" {
      # Users with console access and password older than 90 days
      "date -d \""$5"\" +%s" | getline last_used
      if (systime() - last_used > 7776000) print $1, "password age:", $5
    }
  '

# Find IAM users with active access keys older than 90 days
aws iam list-users --query 'Users[].UserName' --output text | \
  xargs -I{} sh -c '
    aws iam list-access-keys --user-name {} \
      --query "AccessKeyMetadata[?Status==\`Active\`].{User:UserName,Key:AccessKeyId,Created:CreateDate}" \
      --output json
  ' | jq -r '.[] | select(.Created < (now - 7776000 | todate)) | "\(.User): \(.Key) created \(.Created)"'

# Check for overly permissive policies (allow *)
aws iam list-policies --scope Local \
  --query 'Policies[].Arn' --output text | \
  xargs -I{} aws iam get-policy-version \
    --policy-arn {} \
    --version-id $(aws iam get-policy --policy-arn {} --query 'Policy.DefaultVersionId' --output text) \
    --query 'PolicyVersion.Document.Statement[?Effect==`Allow` && Action==`*` && Resource==`*`]'

# AWS Config: compliance summary
aws configservice describe-compliance-by-config-rule \
  --compliance-types NON_COMPLIANT \
  --query 'ComplianceByConfigRules[].{Rule:ConfigRuleName,NonCompliant:Compliance.ComplianceContributorCount}' \
  --output table
```

### `harden`
Apply CIS benchmark hardening to AWS account.

```bash
#!/bin/bash
# CIS AWS Foundations Benchmark - Level 1 Quick Wins

# 1.4: Ensure no root access keys exist
ROOT_KEYS=$(aws iam list-access-keys --user-name root 2>/dev/null | jq '.AccessKeyMetadata | length')
if [ "$ROOT_KEYS" -gt 0 ]; then
  echo "WARNING: Root account has $ROOT_KEYS access key(s) -- delete immediately"
fi

# 1.5: Ensure MFA is enabled on root account
MFA_ENABLED=$(aws iam get-account-summary --query 'SummaryMap.AccountMFAEnabled' --output text)
echo "Root MFA enabled: $MFA_ENABLED (0=no, 1=yes)"

# 2.1.1: Ensure S3 account-level public access block
aws s3control put-public-access-block \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# 3.1: Enable CloudTrail multi-region
aws cloudtrail create-trail \
  --name org-security-trail \
  --s3-bucket-name $TRAIL_BUCKET \
  --is-multi-region-trail \
  --enable-log-file-validation \
  --include-global-service-events

aws cloudtrail start-logging --name org-security-trail

# 4.1: Enable GuardDuty
aws guardduty create-detector --enable \
  --finding-publishing-frequency FIFTEEN_MINUTES

# 4.3: Enable Security Hub
aws securityhub enable-security-hub --enable-default-standards

echo "CIS Level 1 hardening applied. Review remaining controls manually."
```
