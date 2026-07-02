---
title: Configuration
parent: YourSqlDba documentation
nav_order: 30
---

# Configuration

YourSqlDba configuration is mainly controlled by SQL Agent job steps that call
`Maint.YourSqlDba_DoMaint`.

This page explains how setup is performed, which parameters matter most, and
how DBAs typically customize maintenance.

## Where setup is performed

YourSqlDba setup is established through a few components:

| Location | Purpose |
| --- | --- |
| `Install.InitialSetupOfYourSqlDba` | Helper that creates default SQL Agent jobs, schedules, backup paths, and Database Mail support settings |
| SQL Agent job schedules | When maintenance jobs run |
| SQL Agent job steps | Active maintenance parameters passed to `Maint.YourSqlDba_DoMaint` |
| Database Mail / mail profile | Email reporting configuration and report delivery |
| `Maint.YourSqlDba_DoMaint` | Defines maintenance actions, database selection, retention, and mirror/standby behavior |

`Install.InitialSetupOfYourSqlDba` does not itself hold configuration values. It is a helper that builds the default setup by creating SQL Agent jobs and job steps, and by configuring Database Mail for reporting.

The active configuration lives in the SQL Agent jobs and job steps, plus the Database Mail settings used for YourSqlDba reports.
DBAs can then customize maintenance behavior by adjusting those job steps and the related mail settings.

## Key parameters

| Parameter | Purpose |
| --- | --- |
| `@oper` | SQL Agent operator for notifications |
| `@MaintJobName` | Job name stored in history and reports |
| `@DoInteg` | Run database integrity checks when `1` |
| `@DoUpdStats` | Update optimizer statistics when `1` |
| `@DoReorg` | Reorganize or rebuild indexes when `1` |
| `@DoBackup` | Backup mode: `F`, `D`, `L`, or empty for no backup |
| `@FullBackupPath` | Directory for full and differential backups |
| `@LogBackupPath` | Directory for transaction log backups |
| `@FullBkpRetDays` | Days to retain old full backup files |
| `@LogBkpRetDays` | Days to retain old log backup files |
| `@BkpLogsOnSameFile` | Reuse the same log file or create a new file each run |
| `@SpreadUpdStatRun` | Spread statistics updates across multiple runs |
| `@SpreadCheckDb` | Spread full DBCC checks across multiple runs |
| `@MirrorServer` | Optional instance for restore validation or standby/migration testing |

## Backup mode

`@DoBackup` controls backup behavior:

| Value | Operation |
| --- | --- |
| `F` | Full database backups (plus an initial log backup when applicable) |
| `D` | Differential backups |
| `L` | Transaction log backups |
| Empty string | No backup operation |

For log backup jobs, YourSqlDba typically uses the log backup location recorded
by the latest full backup file set. That means frequent log backup jobs usually
do not need explicit full backup path values.

## Database selection

Database selection is controlled most often by `@IncDb` and `@ExcDb`.

- `@IncDb` limits maintenance to matching databases.
- `@ExcDb` excludes matching databases from the selected set.

When database names follow a usable naming convention, the preferred strategy
is often to maintain most databases and exclude only the exceptions. This keeps
the default job broad while allowing targeted exclusions.

If `@IncDb` is empty, YourSqlDba starts from all eligible databases and then
removes those listed in `@ExcDb`.

### Include / exclude patterns

These parameters accept SQL `LIKE` patterns.

Examples:

```sql
@IncDb = N'Payroll%,Accounting%'
@ExcDb = N'%Archive%,%Test%'
```

Common strategies:

| Strategy | Parameters |
| --- | --- |
| Maintain most databases, except a few | `@ExcDb` only |
| Maintain a specific application group | `@IncDb` only |
| Separate a database group with a different schedule | exclude from the default job, then add another job or step with `@IncDb` |

## Common customization patterns

### Exclude a database from the default job

Use `@ExcDb` in the SQL Agent job step for the default maintenance job.

This is useful when a database needs a different schedule, backup policy, or
maintenance behavior.

### Add a second maintenance step

If a database group should run with different parameters but can use the same
schedule, add another SQL Agent job step with a specific `@IncDb` value.

### Use a separate SQL Agent job

If the database group needs a different schedule, create a separate SQL Agent
job.

When separate jobs run on the same instance, avoid unnecessary overlap between
heavy operations such as full backups, DBCC checks, and index maintenance.

## Backup retention

Backup cleanup is controlled by:

- `@FullBkpRetDays`
- `@LogBkpRetDays`

A value of `NULL` disables cleanup for that backup type.

Retention applies only to files YourSqlDba can recognize as part of its backup
naming rules.

## Spread maintenance work

Use these parameters to reduce work per run:

| Parameter | Purpose |
| --- | --- |
| `@SpreadUpdStatRun` | Spread statistics updates across multiple runs |
| `@SpreadCheckDb` | Spread full DBCC checks across multiple runs |

This is useful when your maintenance window cannot handle all work in a single
execution.

## Reporting and troubleshooting

`Maint.HistoryView` is the primary maintenance diagnostic tool. Maintenance
reports sent by email include a ready-to-run query for it. When the report
identifies an error, the query is already restricted to the relevant job and
error-related events.

See [Diagnostics and reporting](diagnostics.md#maintenance-diagnostics-with-mainthistoryview)
for complete-history and error-investigation examples.

For the main maintenance procedure reference, see
[Maint.YourSqlDba_DoMaint](maintenance/your-sql-dba-domaint.md).
