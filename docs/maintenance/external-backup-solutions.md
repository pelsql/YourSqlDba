---
title: External backup solutions
parent: Maintenance
grand_parent: YourSqlDba documentation
nav_order: 30
---

# External backup solutions

An external backup product can replace the backup portion of YourSqlDba while
YourSqlDba continues to perform integrity checks, statistics updates, and index
maintenance. This is useful when the external product provides storage features
that depend on issuing its own SQL Server backup commands, such as block-level
deduplication.

CommVault is used here as a concrete example. Product capabilities, command-line
paths, schedules, and observed storage savings depend on the installed version
and environment.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Separate maintenance from backups

Configure the main `Maint.YourSqlDba_DoMaint` job step without a backup mode so
that it continues to perform the required non-backup maintenance. Schedule the
external full backup after that maintenance.

Transaction log backups should generally continue on their normal recurring
schedule. Allowing them to run during index maintenance helps control log reuse
while rebuild and reorganization operations generate log records.

YourSqlDba no longer automatically shrinks transaction logs after log backups,
and the former `Maint.ShrinkAllLogs` procedure has been removed. Do not reproduce
the obsolete post-backup shrink step from older documentation. Log files should
normally be sized for their expected workload; investigate abnormal growth
instead of scheduling routine shrink operations.

## Synchronize an external full backup with maintenance

`Maint.SetSyncWith_YourSqlDba_DoMaint` waits for the main maintenance operation
to release its application lock. An external backup pre-job can call this
procedure before starting a full backup.

The following command illustrates a local default SQL Server instance using
Windows authentication:

```bat
"C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\Sqlcmd.exe" -E -S . -d YourSqlDba -Q "EXEC Maint.SetSyncWith_YourSqlDba_DoMaint;"
```

Adjust the `sqlcmd` path and `-S` instance name for the environment. The account
running the external command must be able to connect to SQL Server and execute
the procedure.

If the backup product shares one pre-job between full and log backup schedules,
apply the wait only to the time window reserved exclusively for the full backup.
Keep that window separate from recurring log backup start times. Schedule the
external full backup with enough delay for `Maint.YourSqlDba_DoMaint` to start
and acquire its application lock.

Example with a full backup scheduled at 00:15 and no log backup scheduled from
00:14 through 00:29:

```bat
"C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\Sqlcmd.exe" -E -S . -d YourSqlDba -Q "IF CONVERT(char(8), GETDATE(), 108) BETWEEN '00:14:00' AND '00:29:00' EXEC Maint.SetSyncWith_YourSqlDba_DoMaint;"
```

The time test is only an integration workaround for products that do not tell a
shared pre-job which backup type is starting. Adapt it to the actual schedules;
do not copy these times unchanged.

## Restore CommVault backup files

CommVault can materialize SQL Server backups as `.bak` files instead of
restoring a database directly. A striped backup normally produces multiple
media-family files for each full, differential, or log backup. Restoring several
days can therefore require many ordered `RESTORE` statements.

The following optional example scans a folder containing files that follow the
CommVault naming convention and generates the corresponding restore sequence:

[View or download `BuildRestoreFromCommVaultBackupFiles.sql`](../assets/examples/BuildRestoreFromCommVaultBackupFiles.sql)

{: .warning }
> This script is a documentation example. It is not installed by YourSqlDba and
> is not part of the YourSqlDba product code. It is provided as-is and is not
> validated against each client's CommVault configuration or file-naming
> conventions. The user is responsible for testing it in a non-production
> environment and reviewing every generated `RESTORE` statement before
> execution.

### Requirements and assumptions

The example:

- requires SQL Server 2017 or later because it uses
  `sys.dm_os_enumerate_filesystem`;
- requires a current YourSqlDba installation for its version-aware
  `RESTORE HEADERONLY` and `RESTORE FILELISTONLY` collectors;
- expects the SQL Server Database Engine service account to have read access to
  the source folder;
- expects two media-family files identified by `_1_` and `_2_` in each CommVault
  backup name;
- depends on the CommVault file-name pattern used by the documented example;
- generates, but does not execute, the restore sequence;
- supports an optional point-in-time target through `@StopAt`;
- supports up to three source-to-destination path substitutions.

### Generate a restore sequence

```sql
Exec dbo.BuildRestoreFromBackupFiles
  @SourceFolder=N'P:\CommVaultRestore\Payroll'
, @DestinationDatabase=N'Payroll_RecoveryTest'
, @SystemName=N'Payroll'
, @pathRepFrom1=N'F:\Data\'
, @pathRepTo1=N'F:\Data\RecoveryTest\'
, @pathRepFrom2=N'L:\Data\'
, @pathRepTo2=N'L:\Data\RecoveryTest\'
, @pathRepFrom3=NULL
, @pathRepTo3=NULL
, @StopAt=N'2026-06-30 12:00:30';
```

Run the installation portion of the example in a DBA utility database rather
than adding it to the `YourSqlDba` database. The result set contains the
generated restore statement parts. Inspect the selected full backup, media
files, target paths, restore order, and `STOPAT` placement before execution.

For a simple restore from a single, self-contained backup file, prefer
[`Maint.RestoreDb`](delegated-database-management.md#delegated-duplication-and-restore-procedures).
