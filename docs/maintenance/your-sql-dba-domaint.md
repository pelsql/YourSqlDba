---
title: Maint.YourSqlDba_DoMaint
parent: Maintenance
grand_parent: YourSqlDba documentation
nav_order: 10
---

# Maint.YourSqlDba_DoMaint

`Maint.YourSqlDba_DoMaint` is the main stored procedure used for regular
YourSqlDba maintenance. It is normally called from SQL Agent job steps; manual
execution is reserved for testing, troubleshooting, or one-off maintenance.

Use this procedure to define:

- which maintenance actions are performed;
- which databases are included or excluded;
- where backup files are written;
- how long backup files are retained;
- whether backups are restored to a standby or mirror server;
- how maintenance results are reported.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Execution model

`Maint.YourSqlDba_DoMaint` is intended to be the top-level entry point for
automatic maintenance.

At the start of a run, YourSqlDba creates a maintenance context and records the
procedure parameters in its history tables. This context is used by the
procedures called later in the run, and by the reporting tools after the run is
complete.

The procedure then performs the selected actions, such as:

- deleting old backup files;
- running integrity checks;
- updating statistics;
- reorganizing or rebuilding indexes;
- creating full, differential, or transaction log backups;
- optionally restoring backups to a mirror or standby server.

The procedure also coordinates maintenance execution with an application lock so
that other processes that integrate with YourSqlDba can synchronize with regular
maintenance.

## Typical calls

Daily full maintenance usually enables integrity checks, statistics updates,
index maintenance, and full backups. These examples reflect the default initial
setup jobs for full maintenance and log backups:

```sql
EXEC Maint.YourSqlDba_DoMaint
    @oper = N'YourSQLDba_Operator',
    @MaintJobName = N'YourSQLDba: DoInteg,DoUpdateStats,DoReorg,Full backups',
    @DoInteg = 1,
    @DoUpdStats = 1,
    @DoReorg = 1,
    @DoBackup = N'F',
    @FullBackupPath = N'D:\SQLBackups',
    @LogBackupPath = N'D:\SQLBackups',
    @FullBkpRetDays = 1,
    @LogBkpRetDays = 8;
```

Frequent transaction log backups usually call the same procedure with
`@DoBackup = N'L'`:

```sql
EXEC Maint.YourSqlDba_DoMaint
    @oper = N'YourSQLDba_Operator',
    @MaintJobName = N'YourSQLDba: Log backups',
    @DoBackup = N'L';
```

## Main parameters

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `@oper` | `nvarchar(200)` | Required | SQL Agent operator used for maintenance notifications. |
| `@MaintJobName` | `nvarchar(200)` | `Ad-Hoc Job` | Job name stored in maintenance history and reports. |
| `@DoInteg` | `int` | `0` | Runs database integrity checks when set to `1`. |
| `@DoUpdStats` | `int` | `0` | Updates optimizer statistics when set to `1`. |
| `@DoReorg` | `int` | `0` | Performs selective index reorganization or rebuild when set to `1`. |
| `@DoBackup` | `nvarchar(5)` | Empty string | Backup mode: `F`, `D`, `L`, or empty for no backup. |
| `@FullBackupPath` | `nvarchar(512)` | `NULL` | Directory used for full and differential backup files. |
| `@LogBackupPath` | `nvarchar(512)` | `NULL` | Directory used for transaction log backup files. |
| `@TimeStampNamingForBackups` | `int` | `1` | Adds timestamps to backup file names when set to `1`. |
| `@FullBkExt` | `nvarchar(7)` | `BAK` | File extension used for full and differential backups. |
| `@LogBkExt` | `nvarchar(7)` | `TRN` | File extension used for transaction log backups. |
| `@FullBkpRetDays` | `int` | `NULL` | Number of days to retain old full backup files. `NULL` disables cleanup. |
| `@LogBkpRetDays` | `int` | `NULL` | Number of days to retain old log backup files. `NULL` disables cleanup. |
| `@NotifyMandatoryFullDbBkpBeforeLogBkp` | `int` | `1` | Reports an error when a log backup cannot run because no full backup is available. |
| `@BkpLogsOnSameFile` | `int` | `1` | Uses the same log backup file after a full backup when set to `1`; creates a new file each run when set to `0`. |
| `@SpreadUpdStatRun` | `int` | `7` | Spreads statistics updates across a number of maintenance executions. |
| `@SpreadCheckDb` | `int` | `7` | Spreads full DBCC checks across a number of maintenance executions. |
| `@ConsecutiveDaysOfFailedBackupsToPutDbOffline` | `int` | `9999` | Last-resort threshold for putting a database offline after repeated full backup failures. |
| `@MirrorServer` | `sysname` | Empty string | Optional destination SQL instance for automatic restore of backups. |
| `@MigrationTestMode` | `int` | `0` | Changes mirror restore behavior to support migration testing. |
| `@ReplaceSrcBkpPathToMatchingMirrorPath` | `nvarchar(max)` | Empty string | Rewrites backup paths as seen from the mirror server. |
| `@ReplacePathsInDbFilenames` | `nvarchar(max)` | Empty string | Rewrites database file paths during restore on the mirror server. |
| `@IncDb` | `nvarchar(max)` | Empty string | Includes databases matching the supplied patterns. |
| `@ExcDb` | `nvarchar(max)` | Empty string | Excludes databases matching the supplied patterns. |
| `@ExcDbFromPolicy_CheckFullRecoveryModel` | `nvarchar(max)` | Empty string | Excludes databases from the full recovery model policy check. |
| `@EncryptionAlgorithm` | `nvarchar(10)` | Empty string | Backup encryption algorithm. |
| `@EncryptionCertificate` | `nvarchar(100)` | Empty string | Certificate used for encrypted backups. |

## Maintenance actions

The maintenance actions are controlled by independent parameters. This makes it
possible to use a single procedure for several SQL Agent jobs or job steps.

| Parameter | Action when enabled |
| --- | --- |
| `@DoInteg = 1` | Runs database integrity checks. |
| `@DoUpdStats = 1` | Updates optimizer statistics. |
| `@DoReorg = 1` | Optimizes indexes that need maintenance. |
| `@DoBackup = N'F'` | Runs full backups. |
| `@DoBackup = N'D'` | Runs differential backups. |
| `@DoBackup = N'L'` | Runs transaction log backups. |

These actions can be combined. The default full maintenance job usually combines
integrity checks, statistics updates, index maintenance, and full backups.

If a maintenance window is too short for every action, split the work into
separate job steps or separate SQL Agent jobs.

## Backup mode

`@DoBackup` controls which backup operation is performed.

| Value | Operation |
| --- | --- |
| `F` | Full backups. YourSqlDba also performs an initial transaction log backup when applicable. |
| `D` | Differential backups. |
| `L` | Transaction log backups. |
| Empty string | No backup operation. |

For log backups, `@FullBackupPath` and `@LogBackupPath` are not normally needed.
YourSqlDba typically derives the log backup location from the latest full or
differential backup file set.

### Full and differential backups

Full and differential backups use `@FullBackupPath` and the extension defined by
`@FullBkExt`.

When `@TimeStampNamingForBackups = 1`, backup files include a timestamp in their
name. This allows backup retention cleanup to remove older files while preserving
newer backup sets.

When `@TimeStampNamingForBackups = 0`, backup file names are reused. This can be
useful with deduplication tools, but it changes the practical meaning of backup
file retention because older backup files are overwritten instead of accumulating.

### Transaction log backups

Transaction log backups use the log backup location recorded by the latest full
or differential maintenance backup.

`@BkpLogsOnSameFile` controls how log backup files are written:

| Value | Behavior |
| --- | --- |
| `1` | Log backups are appended to the same log backup file associated with the current backup set. |
| `0` | Each log backup creates a separate file. |

`@NotifyMandatoryFullDbBkpBeforeLogBkp` controls whether YourSqlDba reports an
error when a log backup cannot run because no full backup is available.

## Database selection

`@IncDb` and `@ExcDb` define the database scope.

- `@IncDb` limits maintenance to databases matching the include list.
- `@ExcDb` removes databases from the selected set.
- Leaving `@IncDb` empty is the usual “all eligible databases, except excluded
  ones” strategy.

These parameters are especially useful on instances that host many databases.
When database names follow usable naming conventions, DBAs typically prefer to
maintain most databases by leaving `@IncDb` empty and using `@ExcDb` for a few
exceptions. This avoids long explicit database lists and keeps default maintenance
broad.

Use separate SQL Agent job steps or separate jobs when different database groups
need different maintenance actions or schedules.

### Include and exclude patterns

The include and exclude parameters are lists of SQL `LIKE` patterns.

Examples:

```sql
@IncDb = N'Payroll%,Accounting%'
```

```sql
@ExcDb = N'%Archive%,%Test%'
```

Typical strategies:

| Strategy | Parameters |
| --- | --- |
| Maintain most databases, except a few | Leave `@IncDb` empty and set `@ExcDb`. |
| Maintain only one application group | Set `@IncDb` to the application database pattern. |
| Give a group a different schedule | Exclude it from the default job, then create another job or job step with `@IncDb`. |

### Job step or separate job

Use another SQL Agent job step when the maintenance can run in the same schedule
as the default job.

Use another SQL Agent job when the database group needs a different schedule.

When creating separate jobs, avoid unnecessary overlap between heavy operations
such as full backups, DBCC checks, and index maintenance.

## Backup retention

Backup cleanup is controlled by:

- `@FullBkpRetDays`
- `@LogBkpRetDays`

`NULL` means that cleanup is disabled for that backup type.

Small values are common when the backup folder is dedicated to the latest backup
set. Larger values are useful when the folder must keep several days of recovery
points.

Retention applies to backup files that YourSqlDba can identify as part of its
maintenance naming rules.

## Spreading maintenance work

Two parameters reduce the amount of work performed in a single maintenance run:

| Parameter | Purpose |
| --- | --- |
| `@SpreadUpdStatRun` | Spreads statistics updates across several runs. |
| `@SpreadCheckDb` | Spreads full DBCC checks across several runs. |

For example, with the default value `7`, the work is spread over a seven-run
cycle. This reduces the maintenance window while still ensuring that all
databases or objects are eventually processed.

## Recovery model policy

YourSqlDba expects databases that need transaction log backups to be in full
recovery model. It can report databases that do not follow the expected policy.

Use `@ExcDbFromPolicy_CheckFullRecoveryModel` when a database is intentionally
excluded from that policy.

This is common for test or transient databases where log backup coverage is not
required.

## Mirror, standby, and migration testing

`@MirrorServer` enables automatic restore of backups to another SQL Server
instance. This is useful for backup validation, standby reporting, or migration
testing when a copy of the database must be recovered on a second server.

For detailed guidance on mirroring and restore job management, see
[Mirror, standby, and migration testing](mirror-standby-migration.md).

## Encrypted backups

YourSqlDba can request encrypted backups through:

- `@EncryptionAlgorithm`
- `@EncryptionCertificate`

Both values must match SQL Server backup encryption requirements. The certificate
must already exist and be usable by SQL Server for backup encryption.

Use encrypted backups only after validating certificate backup and restore
procedures. Losing the certificate can make encrypted backups unusable.

## Reporting

Each run records its execution context and detailed history in YourSqlDba tables.
Maintenance email reports include a query that uses `Maint.HistoryView` to
review the run.

Use the report first, then inspect `Maint.HistoryView` when deeper
troubleshooting is required.

`Maint.HistoryView` is the main tool for understanding what happened during a
maintenance run. It can show commands, informational messages, context, and
errors tied to a specific job execution.

## Common customization examples

### Run integrity checks without backups

```sql
EXEC Maint.YourSqlDba_DoMaint
    @oper = N'YourSQLDba_Operator',
    @MaintJobName = N'Integrity checks only',
    @DoInteg = 1,
    @DoBackup = N'';
```

### Maintain only one database group

```sql
EXEC Maint.YourSqlDba_DoMaint
    @oper = N'YourSQLDba_Operator',
    @MaintJobName = N'Payroll maintenance',
    @DoInteg = 1,
    @DoUpdStats = 1,
    @DoReorg = 1,
    @DoBackup = N'F',
    @IncDb = N'Payroll%';
```

### Exclude databases from the default job

```sql
EXEC Maint.YourSqlDba_DoMaint
    @oper = N'YourSQLDba_Operator',
    @MaintJobName = N'Default maintenance excluding archives',
    @DoInteg = 1,
    @DoUpdStats = 1,
    @DoReorg = 1,
    @DoBackup = N'F',
    @ExcDb = N'%Archive%';
```

### Create a new log backup file at each run

```sql
EXEC Maint.YourSqlDba_DoMaint
    @oper = N'YourSQLDba_Operator',
    @MaintJobName = N'Log backups',
    @DoBackup = N'L',
    @BkpLogsOnSameFile = 0;
```

## Related tools and objects

| Object | Role |
| --- | --- |
| `Install.InitialSetupOfYourSqlDba` | Creates default SQL Agent jobs and initial configuration. |
| `Maint.HistoryView` | Displays detailed maintenance history. |
| `Maint.ShowHistory` | Legacy history viewer for maintenance records. |
| `Maint.ShowHistoryErrors` | Shows maintenance errors for a specific job execution. |
| `Maint.SaveDbOnNewFileSet` | Starts a new full backup file set for a database. |
| `Maint.DeleteOldBackups` | Deletes old backup files according to YourSqlDba rules. |
| `Maint.DelegatedDbManagement` | Stores delegation configuration for non-sysadmin database management. |
| `Maint.SaveDbCopyOnly` | Creates a copy-only backup of a database. |
| `Maint.DuplicateDb` | Duplicates a database from an existing backup or backup history. |
| `Maint.DuplicateDbFromBackupHistory` | Creates a duplicate database from a recorded backup history entry. |
| `Maint.RestoreDb` | Restores a database from backup under YourSqlDba rules. |
| `Maint.PrepDbForMaintenanceMode` | Prepares a database for maintenance mode. |
| `Maint.RestoreDbAtStartOfMaintenanceMode` | Restores the database when entering maintenance mode. |
| `Maint.ReturnDbToNormalUseFromMaintenanceMode` | Returns the database to normal operation after maintenance. |
| `Maint.JobHistory` | Stores maintenance run context. |
