# Backup & Disaster Recovery Plugin

3-2-1 backup strategies, RTO/RPO planning, Velero, pgBackRest, AWS Backup, and DR runbooks.

## Components

- **Agent**: `dr-planner` -- Calculates RTO/RPO per service tier, designs backup architecture, writes DR runbooks
- **Command**: `/backup-plan` -- Generates Velero schedules, AWS Backup plans, restore procedures, compliance reports
- **Skill**: `dr-patterns` -- pgBackRest config, Velero hooks, AWS Backup Terraform, chaos test schedules, runbook template

## When to Use

- Designing backup architecture for new services (what to back up, how often, where)
- Writing DR runbooks for database or cluster failures
- Calculating acceptable RTO/RPO for service tiers
- Setting up pgBackRest WAL archiving for PostgreSQL PITR
- Configuring Velero for Kubernetes cluster backup
- Planning and executing DR drills

## Quick Reference

```bash
# Velero backup status
velero backup get
velero backup describe <name> --details

# pgBackRest operations
pgbackrest --stanza=main backup --type=full
pgbackrest --stanza=main info
pgbackrest --stanza=main check   # Verify backup integrity

# AWS Backup: list failed jobs
aws backup list-backup-jobs \
  --by-state FAILED \
  --query 'BackupJobs[].{Resource:ResourceArn,Reason:StatusMessage}'

# Point-in-time restore
pgbackrest --stanza=main restore \
  --target="2024-01-15 14:30:00+00" \
  --target-action=promote \
  --delta
```

## Backup Tiers

| Tier | RPO | RTO | Method |
|------|-----|-----|--------|
| Critical (DB) | 5 min | 30 min | WAL archiving + streaming replica |
| High (K8s) | 1 hr | 45 min | Velero hourly + EBS snapshots |
| Medium (files) | 24 hr | 2 hr | S3 cross-region replication |
| Compliance | 30 days | 24 hr | Glacier with Object Lock (WORM) |

## Key Principles

**Backups are only valid if tested.** The "0" in 3-2-1-1-0 means zero errors on restore verification. Run a monthly restore drill to a test environment.

**Replication is not a backup.** Streaming replication propagates corruption immediately. You need both replication (fast failover) and backups (corruption recovery).

**Immutable copies block ransomware.** S3 Object Lock in Compliance mode or AWS Backup Vault Lock prevents deletion even by administrators.

**WAL archiving for PostgreSQL.** Gives you PITR to any second in the archive window. pg_dump alone gives you only the state at dump time.

## Related Plugins

- [database-operations](../database-operations/) -- PostgreSQL internals, pgBouncer, replication
- [kubernetes-operations](../kubernetes-operations/) -- Velero install, PVC management
- [aws-infrastructure](../aws-infrastructure/) -- AWS Backup, S3 versioning, cross-region
- [monitoring-observability](../monitoring-observability/) -- Backup job alerting, restore time tracking
