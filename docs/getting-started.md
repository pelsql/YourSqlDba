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
- clean up SQL Server, SQL Agent, mail, backup, and maintenance history
- send maintenance reports by email
- record detailed execution history for troubleshooting

## Design approach

The initial setup is intended to provide useful maintenance without requiring a
separate maintenance plan for every database. For many small and medium-sized
instances, the default jobs are a practical starting point that can be adjusted
after the first runs have been reviewed.

YourSqlDba also limits work that does not need to run in full during every
maintenance window. Statistics updates and full integrity checks can be spread
across several runs, while index maintenance targets indexes according to their
condition. These behaviors make the maintenance cycle easier to fit within the
available window.

Detailed reporting is part of the operating model, not an afterthought. Each
run records enough context to identify the commands that were executed and the
errors that occurred. Email reports direct the DBA to `Maint.HistoryView`, which
can focus on the relevant errors or show the wider activity around a job.

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

## From the default setup to advanced configurations

The active maintenance configuration remains visible in SQL Agent schedules and
job steps. A DBA can progressively adapt it by:

- changing the schedule of either default job;
- using `@IncDb` and `@ExcDb` patterns to target database groups;
- separating backups, integrity checks, statistics, or index maintenance into
  different job steps;
- creating additional jobs when a database group requires its own schedule;
- using restore-based mirroring to maintain a recoverable copy or prepare a
  migration to another SQL Server instance.

If all selected databases can be maintained sequentially within the available
window, the default structure may be sufficient. When that window becomes too
long, the same procedure can be divided across jobs or steps without replacing
the maintenance framework.

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
