# /db-ops

Run database migrations, analyze slow queries, configure pgBouncer, and monitor replication.

## Usage

```
/db-ops migrate|optimize|backup|monitor [options]
```

## Actions

### `migrate`
Run and manage database migrations safely.

```bash
# Flyway: run pending migrations
flyway -url=jdbc:postgresql://db:5432/myapp \
       -user=myapp \
       -password=${DB_PASSWORD} \
       migrate

# Dry-run (show pending without applying)
flyway info

# Validate checksums on applied migrations
flyway validate

# Repair (fix failed or corrupted migrations)
flyway repair

# Liquibase alternative
liquibase --url="jdbc:postgresql://db:5432/myapp" \
          --username=myapp \
          --password=${DB_PASSWORD} \
          --changelog-file=changelog.xml \
          update

# Liquibase: generate rollback SQL for review
liquibase rollbackSQL --tag=v1.2.0

# Django/Alembic/Rails: check migration status
python manage.py showmigrations
alembic current; alembic history --verbose
rails db:migrate:status

# Pre-migration checklist
psql -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';"
psql -c "SELECT pg_size_pretty(pg_database_size('myapp'));"
psql -c "SELECT * FROM pg_locks WHERE NOT GRANTED;"  # Check for blocking locks
```

### `optimize`
Analyze and fix slow queries.

```sql
-- Find slow queries (requires pg_stat_statements extension)
SELECT LEFT(query, 100) AS query,
       calls,
       round(mean_exec_time::numeric, 1) AS avg_ms,
       round(total_exec_time::numeric, 1) AS total_ms
FROM pg_stat_statements
WHERE mean_exec_time > 50
ORDER BY mean_exec_time DESC
LIMIT 20;

-- Check missing indexes (sequential scans on large tables)
SELECT schemaname, tablename, seq_scan, seq_tup_read,
       idx_scan, n_live_tup,
       round(seq_tup_read::numeric / NULLIF(seq_scan, 0), 0) AS avg_rows_per_seqscan
FROM pg_stat_user_tables
WHERE seq_scan > 100
  AND n_live_tup > 10000
ORDER BY seq_tup_read DESC;

-- Check existing indexes -- are they being used?
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
WHERE idx_scan = 0        -- Never scanned
  AND indexrelname NOT LIKE 'pg_%'
ORDER BY schemaname, tablename;

-- Find duplicate indexes
SELECT pg_size_pretty(pg_relation_size(idx)) AS size,
       idx, indkey
FROM (
  SELECT indexrelid::regclass AS idx, indkey
  FROM pg_index
) sub
GROUP BY indkey, idx
HAVING COUNT(*) > 1;
```

```bash
# Run EXPLAIN ANALYZE from command line
psql -c "EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) SELECT ..." | less

# Autogenerate EXPLAIN with auto_explain (add to postgresql.conf)
# shared_preload_libraries = 'auto_explain'
# auto_explain.log_min_duration = '1s'
# auto_explain.log_analyze = on
# auto_explain.log_buffers = on

# Use pev2 or explain.depesz.com for visual plan analysis
```

### `backup`
Database backup and point-in-time recovery.

```bash
# pg_dump: logical backup (portable, supports PITR to any transaction)
pg_dump -h db.prod.example.com \
        -U myapp \
        -d myapp \
        -F custom \            # Custom format: compressed, allows parallel restore
        -j 4 \                 # 4 parallel workers
        -f /backup/myapp_$(date +%Y%m%d_%H%M%S).dump

# Restore from custom format dump
pg_restore -h db-new.example.com \
           -U postgres \
           -d myapp \
           -j 4 \              # Parallel restore
           --clean \            # Drop existing objects before creating
           /backup/myapp_20240115.dump

# pgBackRest: continuous WAL archiving
pgbackrest --stanza=main backup --type=full
pgbackrest --stanza=main backup --type=diff
pgbackrest --stanza=main info

# Point-in-time recovery
pgbackrest --stanza=main restore \
  --target="2024-01-15 14:30:00+00" \
  --target-action=promote \
  --delta

# Check WAL archiving is working
SELECT last_archived_wal, last_archived_time,
       last_failed_wal, last_failed_time,
       archived_count, failed_count
FROM pg_stat_archiver;
```

### `monitor`
Monitor database health, connections, and replication.

```sql
-- Active connections by state
SELECT state, COUNT(*) as count,
       MAX(now() - query_start) AS max_duration
FROM pg_stat_activity
WHERE state IS NOT NULL
GROUP BY state
ORDER BY count DESC;

-- Long-running queries (>30 seconds)
SELECT pid, now() - query_start AS duration, state,
       LEFT(query, 100) AS query
FROM pg_stat_activity
WHERE query_start IS NOT NULL
  AND now() - query_start > INTERVAL '30 seconds'
  AND state != 'idle'
ORDER BY duration DESC;

-- Blocking locks
SELECT blocked_locks.pid AS blocked_pid,
       blocked_activity.query AS blocked_query,
       blocking_locks.pid AS blocking_pid,
       blocking_activity.query AS blocking_query,
       now() - blocked_activity.query_start AS blocked_duration
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
  AND blocking_locks.relation = blocked_locks.relation
  AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.GRANTED;

-- Database size and table sizes
SELECT
  pg_database.datname AS database,
  pg_size_pretty(pg_database_size(pg_database.datname)) AS size
FROM pg_database
ORDER BY pg_database_size(pg_database.datname) DESC;

SELECT tablename,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
       pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS index_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 20;
```

```bash
# pgBouncer stats
psql -h pgbouncer -p 5432 -U pgbouncer pgbouncer -c "SHOW STATS;"
psql -h pgbouncer -p 5432 -U pgbouncer pgbouncer -c "SHOW POOLS;"
psql -h pgbouncer -p 5432 -U pgbouncer pgbouncer -c "SHOW CLIENTS;"

# Kill long-running query
# SELECT pg_cancel_backend(pid);   -- soft cancel
# SELECT pg_terminate_backend(pid); -- hard kill
```
