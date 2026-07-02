---
title: Getting started
parent: YourSqlDba documentation
nav_order: 10
---

# Getting started

YourSqlDba automates SQL Server maintenance using a dedicated database,
`YourSqlDba`, SQL Agent jobs, and stored procedures.

The central maintenance procedure is:

```sql
Maint.YourSqlDba_DoMaint
```

Its primary diagnostic companion is
[`Maint.HistoryView`](diagnostics.md#maintenance-diagnostics-with-mainthistoryview).
It presents the commands, messages, status, and errors recorded by maintenance
jobs and can correlate jobs that ran during the same period.

This page explains the DBA workflow, the default jobs, and the first checks
after setup.

## What YourSqlDba does

YourSqlDba is designed to run standard maintenance tasks across multiple
databases without requiring a custom maintenance plan for each database.

It can:

- create full, differential, and transaction log backups
- clean up old backup files
- run database integrity checks
- update optimizer statistics
- reorganize or rebuild indexes when appropriate
- send maintenance reports by email
- record detailed execution history for troubleshooting

## DBA quick start

1. Run `YourSQLDba_InstallOrUpdateScript.sql` against the target SQL Server instance.
2. Execute `Install.InitialSetupOfYourSqlDba` with values that match your environment.
3. Review the SQL Agent jobs and the job steps that call `Maint.YourSqlDba_DoMaint`.
4. Verify backup paths, mail settings, and the first maintenance run.
5. Use `Maint.HistoryView` to investigate any errors reported by that run.
6. Adjust `Maint.YourSqlDba_DoMaint` parameters for your environment.

## Default jobs

The default initial setup creates two SQL Agent jobs:

| Job | Schedule | Purpose |
| --- | --- | --- |
| Full maintenance | Daily, around midnight | Full backups, integrity checks, statistics updates, and index maintenance |
| Log backups | Every 15 minutes | Transaction log backups for databases in full recovery model |

These jobs usually call the same procedure with different parameters.

## What to verify after setup

After installation and initial setup, confirm that:

- SQL Agent jobs exist and are enabled
- job steps call `Maint.YourSqlDba_DoMaint`
- `@FullBackupPath` and `@LogBackupPath` are correct
- Database Mail profile and SMTP server are configured
- notification recipients are set
- the first maintenance run completes successfully

## Where to customize maintenance

The main configuration point is the SQL Agent job step that calls
`Maint.YourSqlDba_DoMaint`.

Common customizations include:

- excluding databases from the default job
- maintaining a specific database group only
- separating backups from integrity checks
- adjusting backup retention
- changing log backup file behavior
- configuring mirror or standby restore behavior

See [Configuration](configuration.md) and [Maint.YourSqlDba_DoMaint](maintenance/your-sql-dba-domaint.md) for detailed parameters.
