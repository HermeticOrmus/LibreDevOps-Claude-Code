# /aws

Design and provision AWS infrastructure using CDK, audit security posture, and optimize costs.

## Usage

```
/aws provision|secure|cost|audit [options]
```

## Actions

### `provision`
Generate CDK TypeScript infrastructure for a service or component.

```typescript
// CDK VPC + ECS pattern: /aws provision --service webapp --type ecs-fargate
import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecs_patterns from 'aws-cdk-lib/aws-ecs-patterns';

export class AppStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: AppStackProps) {
    super(scope, id, props);

    // ECS auto-scaling Fargate service behind ALB
    const service = new ecs_patterns.ApplicationLoadBalancedFargateService(this, 'Service', {
      cluster: props.cluster,
      cpu: 256,
      memoryLimitMiB: 512,
      desiredCount: 2,
      taskImageOptions: {
        image: ecs.ContainerImage.fromEcrRepository(props.repo, props.imageTag),
        containerPort: 8080,
        environment: { NODE_ENV: 'production' },
        secrets: {
          DATABASE_URL: ecs.Secret.fromSecretsManager(props.dbSecret),
        },
      },
      publicLoadBalancer: true,
      certificate: props.certificate,
      redirectHTTP: true,
    });

    // Target tracking auto-scaling
    service.service.autoScaleTaskCount({ minCapacity: 2, maxCapacity: 20 })
      .scaleOnCpuUtilization('Cpu', { targetUtilizationPercent: 70 });
  }
}
```

### `secure`
Audit and harden IAM, Security Groups, and account-level security services.

```bash
# Enable GuardDuty in all regions
aws guardduty create-detector --enable --finding-publishing-frequency FIFTEEN_MINUTES

# Security Hub with AWS Foundational Security Best Practices
aws securityhub enable-security-hub \
  --enable-default-standards \
  --no-enable-default-standards  # Then enable specific standards

# Check for public S3 buckets
aws s3api list-buckets --query 'Buckets[].Name' --output text | \
  xargs -I{} aws s3api get-bucket-policy-status --bucket {} 2>/dev/null

# Find IAM users with console access (should use SSO instead)
aws iam list-users --query 'Users[].UserName' --output text | \
  xargs -I{} aws iam get-login-profile --user-name {} 2>/dev/null

# Check for access keys older than 90 days
aws iam generate-credential-report
aws iam get-credential-report --query 'Content' --output text | \
  base64 -d | grep -E "^[^,]+,.*,true,.*,[0-9]{4}"
```

```json
// Service Control Policy: Deny creation of public S3 buckets org-wide
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyPublicS3",
      "Effect": "Deny",
      "Action": ["s3:PutBucketAcl", "s3:PutBucketPolicy"],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": ["public-read", "public-read-write", "authenticated-read"]
        }
      }
    },
    {
      "Sid": "DenyNonApprovedRegions",
      "Effect": "Deny",
      "NotAction": ["iam:*", "sts:*", "support:*", "budgets:*", "cloudfront:*"],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": ["us-east-1", "us-west-2", "eu-west-1"]
        }
      }
    }
  ]
}
```

### `cost`
Analyze and optimize AWS spending.

```bash
# Get last 30 days cost by service
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# Find unattached EBS volumes
aws ec2 describe-volumes \
  --filters Name=status,Values=available \
  --query 'Volumes[].{ID:VolumeId,Size:Size,Type:VolumeType,Created:CreateTime}'

# Find stopped EC2 instances still costing money (EBS)
aws ec2 describe-instances \
  --filters Name=instance-state-name,Values=stopped \
  --query 'Reservations[].Instances[].{ID:InstanceId,Type:InstanceType,Stopped:StateTransitionReason}'

# Get Savings Plans recommendation
aws savingsplans get-savings-plans-purchase-recommendation \
  --savings-plans-type COMPUTE_SP \
  --term-in-years ONE_YEAR \
  --payment-option NO_UPFRONT \
  --lookback-period-in-days SIXTY_DAYS
```

### `audit`
Run AWS Config rules and Well-Architected review checks.

```bash
# List non-compliant Config rules
aws configservice describe-compliance-by-config-rule \
  --compliance-types NON_COMPLIANT \
  --query 'ComplianceByConfigRules[].{Rule:ConfigRuleName,Compliance:Compliance.ComplianceType}'

# Run Well-Architected Tool workload review
aws wellarchitected create-workload \
  --workload-name "MyApp Production" \
  --description "Production workload review" \
  --environment PRODUCTION \
  --review-owner "platform-team@company.com" \
  --lenses "wellarchitected" "serverless" \
  --aws-regions us-east-1

# Check for CloudTrail in all regions
aws cloudtrail describe-trails --include-shadow-trails \
  --query 'trailList[?IsMultiRegionTrail==`true`].{Name:Name,Bucket:S3BucketName,Logging:LogFileValidationEnabled}'

# Get Security Hub findings summary
aws securityhub get-findings \
  --filters '{"SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"},{"Value":"HIGH","Comparison":"EQUALS"}],"RecordState":[{"Value":"ACTIVE","Comparison":"EQUALS"}]}' \
  --query 'length(Findings)'
```

## CDK Workflow Reference

```bash
# Bootstrap CDK in account/region (one-time setup)
cdk bootstrap aws://ACCOUNT_ID/us-east-1

# Synthesize CloudFormation template
cdk synth --context env=prod

# Review changes before deploying
cdk diff --context env=prod

# Deploy with approval for security changes
cdk deploy --require-approval broadening --context env=prod

# Deploy specific stack
cdk deploy NetworkStack --context env=prod

# Destroy (requires explicit confirmation)
cdk destroy --force DataStack

# List all stacks
cdk list

# Check CDK version and installed libraries
cdk --version && cat package.json | grep '@aws-cdk'
```
