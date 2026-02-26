# /backup-plan

Design backup strategies, generate DR runbooks, configure Velero schedules, and test restore procedures.

## Usage

```
/backup-plan design|test|restore|report [options]
```

## Actions

### `design`
Generate a backup architecture for a given stack.

```yaml
# Velero daily schedule with 30-day retention
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: daily-full-backup
  namespace: velero
spec:
  schedule: "0 2 * * *"      # 2:00 AM UTC
  template:
    includedNamespaces:
      - production
      - monitoring
      - cert-manager
    excludedResources:
      - events
      - events.events.k8s.io
    ttl: 720h0m0s             # 30 days
    storageLocation: s3-us-east-1
    volumeSnapshotLocations:
      - ebs-us-east-1
    labelSelector:
      matchExpressions:
        - key: backup
          operator: NotIn
          values: [excluded]
```

```bash
# AWS Backup plan for RDS + EFS
aws backup create-backup-plan --backup-plan '{
  "BackupPlanName": "prod-backup",
  "Rules": [
    {
      "RuleName": "daily",
      "TargetBackupVaultName": "prod-vault",
      "ScheduleExpression": "cron(0 3 * * ? *)",
      "StartWindowMinutes": 60,
      "CompletionWindowMinutes": 480,
      "Lifecycle": {
        "MoveToColdStorageAfterDays": 30,
        "DeleteAfterDays": 365
      },
      "CopyActions": [
        {
          "DestinationBackupVaultArn": "arn:aws:backup:us-west-2:ACCOUNT:backup-vault:dr-vault",
          "Lifecycle": {"DeleteAfterDays": 90}
        }
      ]
    }
  ]
}'
```

### `test`
Validate backup integrity and measure actual RTO.

```bash
# Test Velero restore to staging namespace
velero restore create test-restore-$(date +%Y%m%d) \
  --from-backup daily-full-backup-20240115 \
  --include-namespaces production \
  --namespace-mappings production:restore-test \
  --wait

# Verify restored objects
kubectl get all -n restore-test
kubectl get pvc -n restore-test

# Test pgBackRest restore to test server
pgbackrest --stanza=main restore \
  --target="2024-01-15 12:00:00+00" \
  --target-action=promote \
  --pg1-path=/var/lib/postgresql/15/test-restore \
  --delta

# Verify restored data
psql -h test-restore-host -U postgres -c "
  SELECT COUNT(*) FROM orders;
  SELECT MAX(created_at) FROM orders;
"

# Clean up test restore
kubectl delete namespace restore-test
pgbackrest --stanza=test stanza-delete --force
```

### `restore`
Execute recovery from backup with RTO tracking.

```bash
# Start RTO clock
RESTORE_START=$(date +%s)

# Step 1: Identify recovery point
velero backup get | grep Completed | tail -5
pgbackrest --stanza=main info

# Step 2: Restore Kubernetes resources
velero restore create prod-recovery \
  --from-backup daily-full-backup-20240115000204 \
  --wait

# Step 3: Monitor restore progress
velero restore describe prod-recovery --details
kubectl get events -n production --sort-by='.metadata.creationTimestamp' | tail -20

# Step 4: Verify application health
kubectl get pods -n production
kubectl run healthcheck --image=curlimages/curl --rm -it -- \
  curl -f http://app-service.production.svc.cluster.local/health

# Calculate actual RTO
RESTORE_END=$(date +%s)
echo "RTO: $(( (RESTORE_END - RESTORE_START) / 60 )) minutes"

# Compare to RPO target
psql -h db -U postgres -c "
  SELECT now() - MAX(created_at) AS data_loss,
         MAX(created_at) AS most_recent_record
  FROM orders;
"
```

### `report`
Generate backup status and compliance report.

```bash
# List all Velero backups with status
velero backup get -o json | jq '[.items[] | {
  name: .metadata.name,
  status: .status.phase,
  created: .metadata.creationTimestamp,
  expires: .status.expiration,
  warnings: .status.warnings,
  errors: .status.errors
}]'

# AWS Backup: list recovery points for an RDS instance
aws backup list-recovery-points-by-resource \
  --resource-arn "arn:aws:rds:us-east-1:ACCOUNT:db:prod-postgres" \
  --query 'RecoveryPoints[].{Created:CreationDate,Status:Status,Size:BackupSizeInBytes}' \
  --output table

# pgBackRest backup inventory
pgbackrest --stanza=main info --output=json | jq '
  .[0].backup[] |
  {
    label: .label,
    type: .type,
    timestamp_start: (.timestamp.start | todate),
    timestamp_stop: (.timestamp.stop | todate),
    size_gb: (.info.size / 1073741824 | . * 100 | round / 100),
    delta_gb: (.info.delta / 1073741824 | . * 100 | round / 100)
  }
'

# Check backup job status in AWS Backup
aws backup list-backup-jobs \
  --by-state FAILED \
  --by-created-after "$(date -d '-7 days' --iso-8601)" \
  --query 'BackupJobs[].{Resource:ResourceArn,Status:State,Reason:StatusMessage}'
```

## RTO/RPO Reference

| Service | Backup Method | RPO | Estimated RTO | Notes |
|---------|--------------|-----|---------------|-------|
| PostgreSQL | WAL archiving (pgBackRest) | <5min | 30-60min | PITR to any second |
| PostgreSQL | Daily pg_dump | 24hr | 15-30min | Simpler, worse RPO |
| Kubernetes | Velero daily | 24hr | 20-45min | Objects + PVC snapshots |
| S3 | Cross-region replication | Near-zero | Minutes | Built-in, enable per bucket |
| EBS | AWS Backup hourly snapshot | 1hr | 15-30min | Restore to new volume |
| RDS | Automated backups + PITR | 5min | 15-30min | Built-in AWS feature |
