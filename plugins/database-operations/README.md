# Database Operations Plugin

PostgreSQL query optimization, EXPLAIN ANALYZE, indexing, VACUUM, pgBouncer, streaming replication, Flyway migrations.

## Components

- **Agent**: `dba-specialist` -- Reads EXPLAIN ANALYZE, designs indexes, tunes autovacuum, configures pgBouncer
- **Command**: `/db-ops` -- Runs migrations, analyzes slow queries, monitors connections/locks/replication
- **Skill**: `db-ops-patterns` -- EXPLAIN guide, index types, pgBouncer config, Flyway patterns, pg_stat_statements queries

## When to Use

- Diagnosing slow queries (EXPLAIN ANALYZE interpretation)
- Designing indexes (B-tree vs GIN vs BRIN, partial vs covering)
- Setting up pgBouncer for connection pooling
- Configuring PostgreSQL streaming replication
- Running zero-downtime database migrations
- Monitoring blocking locks, connection states, table bloat

## Quick Reference

```sql
-- Find slow queries
SELECT LEFT(query,80), calls, round(mean_exec_time::numeric,1) AS avg_ms
FROM pg_stat_statements
WHERE mean_exec_time > 50
ORDER BY mean_exec_time DESC LIMIT 10;

-- Find missing indexes (large sequential scans)
SELECT tablename, seq_scan, n_live_tup
FROM pg_stat_user_tables
WHERE seq_scan > 100 AND n_live_tup > 10000
ORDER BY seq_tup_read DESC;

-- Blocking locks
SELECT blocked_locks.pid, blocked_activity.query AS blocked,
       blocking_activity.query AS blocking
FROM pg_locks blocked_locks
JOIN pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_locks blocking_locks ON blocking_locks.relation = blocked_locks.relation
  AND blocking_locks.pid != blocked_locks.pid
JOIN pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.GRANTED;

-- Table and index sizes
SELECT tablename,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables WHERE schemaname='public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## Index Type Decision

| Data Type / Query | Index Type |
|------------------|-----------|
| Equality, range, sort | B-tree (default) |
| JSONB `@>`, `?` operators | GIN |
| Full-text search `@@` | GIN |
| Array contains | GIN |
| Geometric, range types | GiST |
| Time-series append-only (created_at) | BRIN |
| Only equality `=` | Hash (rarely better than B-tree) |

Always use `CREATE INDEX CONCURRENTLY` on production tables.

## Related Plugins

- [backup-disaster-recovery](../backup-disaster-recovery/) -- pgBackRest WAL archiving, PITR
- [monitoring-observability](../monitoring-observability/) -- pg_stat_statements dashboards, slow query alerts
- [secret-management](../secret-management/) -- Database credentials rotation with Vault
- [kubernetes-operations](../kubernetes-operations/) -- StatefulSets for PostgreSQL, PVC management
