# /cost-optimize

Analyze cloud spend, identify waste, recommend reserved capacity, and generate cost reports.

## Usage

```
/cost-optimize analyze|rightsize|reserve|report [options]
```

## Actions

### `analyze`
Find waste and quick wins.

```bash
# Unattached EBS volumes (paying for storage with nothing using it)
aws ec2 describe-volumes \
  --filters Name=status,Values=available \
  --query 'Volumes[].{VolumeId:VolumeId,Size:Size,Type:VolumeType,Created:CreateTime}' \
  --output table

# Stopped instances (still paying for EBS)
aws ec2 describe-instances \
  --filters Name=instance-state-name,Values=stopped \
  --query 'Reservations[].Instances[].{ID:InstanceId,Type:InstanceType,Stopped:StateTransitionReason,Name:Tags[?Key==`Name`]|[0].Value}' \
  --output table

# Idle load balancers (no active targets)
aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerArn' --output text | \
  xargs -I{} aws elbv2 describe-target-health --target-group-arn {} 2>/dev/null

# Old snapshots (>30 days, no associated running instances)
aws ec2 describe-snapshots --owner-ids self \
  --query "Snapshots[?StartTime < '$(date -d '-30 days' --iso-8601)'].{SnapshotId:SnapshotId,StartTime:StartTime,Size:VolumeSize}" \
  --output table

# NAT Gateway data cost breakdown
aws cloudwatch get-metric-statistics \
  --namespace AWS/NATGateway \
  --metric-name BytesOutToDestination \
  --dimensions Name=NatGatewayId,Value=nat-xxxxxxxxxxxxxxxxx \
  --start-time $(date -d '-30 days' --iso-8601=seconds) \
  --end-time $(date --iso-8601=seconds) \
  --period 2592000 \
  --statistics Sum \
  --query 'Datapoints[0].Sum'

# gp2 volumes that should be gp3 (20% savings)
aws ec2 describe-volumes \
  --filters Name=volume-type,Values=gp2 \
  --query 'Volumes | length(@)'
```

### `rightsize`
Get rightsizing recommendations from AWS Compute Optimizer.

```bash
# EC2 rightsizing recommendations
aws compute-optimizer get-ec2-instance-recommendations \
  --query 'instanceRecommendations[?finding==`OVER_PROVISIONED`].{
    Instance:instanceArn,
    CurrentType:currentInstanceType,
    RecommendedType:recommendationOptions[0].instanceType,
    MonthlySavings:recommendationOptions[0].estimatedMonthlySavings.value,
    Currency:recommendationOptions[0].estimatedMonthlySavings.currency
  }' \
  --output table

# Lambda rightsizing (memory settings)
aws compute-optimizer get-lambda-function-recommendations \
  --query 'lambdaFunctionRecommendations[?finding==`OVER_PROVISIONED`].{
    Function:functionArn,
    CurrentMemory:currentMemorySize,
    RecommendedMemory:memorySizeRecommendationOptions[0].memorySize,
    Savings:memorySizeRecommendationOptions[0].estimatedMonthlySavings.value
  }' \
  --output table

# RDS rightsizing
aws compute-optimizer get-rds-database-recommendations \
  --query 'rdsDBRecommendations[?finding==`OVER_PROVISIONED`].{
    DB:resourceArn,
    Current:currentDBInstanceClass,
    Recommended:instanceRecommendationOptions[0].dbInstanceClass,
    Savings:instanceRecommendationOptions[0].estimatedMonthlySavings.value
  }' \
  --output table

# EBS volume recommendations
aws compute-optimizer get-ebs-volume-recommendations \
  --query 'volumeRecommendations[].{
    Volume:volumeArn,
    CurrentType:currentConfiguration.volumeType,
    CurrentSize:currentConfiguration.volumeSize,
    RecommendedType:volumeRecommendationOptions[0].configuration.volumeType,
    Savings:volumeRecommendationOptions[0].estimatedMonthlySavings.value
  }' \
  --output table
```

### `reserve`
Analyze and purchase reserved capacity.

```bash
# Get Compute Savings Plans recommendation (1yr, no upfront)
aws savingsplans get-savings-plans-purchase-recommendation \
  --savings-plans-type COMPUTE_SP \
  --term-in-years ONE_YEAR \
  --payment-option NO_UPFRONT \
  --lookback-period-in-days SIXTY_DAYS \
  --query '{
    RecommendedHourlyCommitment: SavingsPlansRecommendation.SavingsPlansDetails.HourlyCommitment,
    EstimatedMonthlySavings: SavingsPlansRecommendation.EstimatedMonthlySavings,
    EstimatedROI: SavingsPlansRecommendation.EstimatedROI,
    CurrentOnDemandSpend: SavingsPlansRecommendation.CurrentOnDemandSpend
  }'

# List existing Savings Plans
aws savingsplans describe-savings-plans \
  --query 'savingsPlans[].{
    Type:savingsPlansType,
    Hourly:commitment,
    Term:termDurationInSeconds,
    State:state,
    Start:start,
    End:end
  }' --output table

# RDS Reserved Instance recommendation
aws rds describe-reserved-db-instances-offerings \
  --db-instance-class db.r6g.xlarge \
  --multi-az \
  --offering-type "No Upfront" \
  --duration 31536000 \  # 1 year in seconds
  --query 'ReservedDBInstancesOfferings[].{
    OfferingId:ReservedDBInstancesOfferingId,
    Engine:ProductDescription,
    MonthlyPrice:FixedPrice
  }'
```

### `report`
Generate cost summary and trend report.

```bash
# Monthly cost trend by service (last 6 months)
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '-180 days' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --output json | jq '
    .ResultsByTime[] |
    {
      period: .TimePeriod.Start,
      services: [.Groups[] |
        select(.Metrics.BlendedCost.Amount | tonumber > 1) |
        {service: .Keys[0], cost: (.Metrics.BlendedCost.Amount | tonumber | . * 100 | round / 100)}
      ] | sort_by(.cost) | reverse
    }
  '

# Get cost anomalies with root cause
aws ce get-anomalies \
  --date-interval Start=$(date -d '-30 days' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --query 'Anomalies[].{
    Service:DimensionValue,
    ActualSpend:TotalImpact.TotalActualSpend,
    ExpectedSpend:TotalImpact.TotalExpectedSpend,
    ImpactDiff:TotalImpact.TotalImpact
  }' \
  --output table

# Savings Plan utilization report
aws ce get-savings-plans-utilization \
  --time-period Start=$(date -d '-30 days' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --query 'Total.Utilization.UtilizationPercentage'
```
