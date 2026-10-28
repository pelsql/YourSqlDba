---
title: Delete old backups
parent: Maintenance
grand_parent: YourSqlDba documentation
nav_order: 25
---

# Delete old backups

`Maint.DeleteOldBackups` deletes old backup files recognized by YourSqlDba's
naming rules. It normally runs from `Maint.YourSqlDba_DoMaint`, but can also run
in a separate SQL Server Agent job or an SQL Server Management Studio query.

[Version française](../fr/maintenance/delete-old-backups.md)

## File selection and retention

The procedure examines only the files directly in `@path`; it does not scan
subdirectories. A local path or UNC share is accepted. The SQL Server service
account must be able to enumerate the directory and delete the selected files.

Files must match the requested extension and contain a recognized, valid date
in their name. Typical names are:

```text
AdventureWorks_[2026-04-28_23h02m28_Tue]_Database.Bak
AdventureWorks_[2026-04-28_23h02m28_Tue]_Differential.Bak
AdventureWorks_[2026-04-28_23h02m28_Tue]_Logs.Trn
MSDB_[2026-04-28_Tue]_Database.Bak
```

Age is calculated from the date in the filename, not the filesystem creation
or modification date. For ordinary timestamped names, the calculation uses
minute precision; for the short MSDB format, it uses midnight on that date.
The reference date is the maintenance context's job start time. A standalone
call creates its own context with the current date and time.

A file qualifies when its age in minutes is **strictly greater than the
retention value multiplied by 1440**. `NULL` disables the corresponding cleanup
rule. `0` makes files older than the reference minute eligible; it does not mean
"keep today's backups". Files with unrecognized names or invalid dates are ignored.

Selected databases come from YourSqlDba's online, maintenance-eligible database
list, using `@IncDb` and `@ExcDb`. The shared filter always includes eligible
`master`, `model`, `msdb`, and `YourSqlDba` databases, even when user database
filters are specified. An unselected backup can belong to a database that was
dropped, renamed, excluded, or is otherwise absent from that selected list.

## Parameters

| Parameter | Type | Default | Purpose |
| --- | --- | --- | --- |
| `@oper` | `nvarchar(200)` | `'YourSQLDba_Operator'` | Enabled SQL Server Agent operator used for reporting. |
| `@path` | `nvarchar(max)` | Required | Backup directory. The final backslash is optional. |
| `@BkpRetDays` | `int` | `NULL` | Retention in days for backups of selected databases; also used by the MSDB rule. |
| `@BkpRetDaysForUnSelectedDb` | `int` | `NULL` | Retention for backups not matched to the selected database list. Restricted to sysadmins. |
| `@extension` | `sysname` | `''` | Extension filter, such as `.bak`, `bak`, or `.trn`. Empty means any extension, subject to the filename rules. |
| `@IncDb` | `nvarchar(max)` | `''` | Inclusion list of SQL `LIKE` patterns. Empty selects all eligible databases. |
| `@ExcDb` | `nvarchar(max)` | `''` | Exclusion list of SQL `LIKE` patterns for user databases. |
| `@SendOnErrorOnly` | `int` | `1` | Send the standalone execution report only on error; `0` also reports successful executions. |
| `@DeleteOnlyLogDiffBackups` | `int` | `0` | With `1`, restrict the selected-database rule to filenames containing `_Logs` or `_Differential`. |

Put each database pattern on its own line. `%` matches any sequence of
characters, `_` one character, and `[5-9]` a character in a range. Use `[_]`
to match a literal underscore, as in `%[_]test`.

When a maintenance context already exists, its operator and database filters
replace the values of `@oper`, `@IncDb`, and `@ExcDb` supplied to this call.
The old OneNote parameters `@MaintJobName`, `@RefDate`, and `@JobNo` are no
longer part of the procedure signature; history and reference time are managed
through the execution context.

## Permissions and separate cleanup rules

Sysadmins can clean selected database backups, MSDB backups, and unselected
database backups under the applicable retention rules. Delegated users can
clean only authorized user-named variants of source databases configured in
`Maint.DelegatedDbManagement`. See [Delegated database management](delegated-database-management.md).

The MSDB and unselected-database rules are evaluated separately from the
selected-database rule. In particular, `@DeleteOnlyLogDiffBackups = 1` does
**not** restrict those two rules. Leave `@BkpRetDaysForUnSelectedDb = NULL`
when unselected files must be kept. A file matching more than one deletion
reason is processed only once.

Directory enumeration and file-attribute errors from the CLR helpers are
logged; files with such errors are not deleted. Deletion failures are also
logged. The history records the reason and outcome of each attempted deletion.

## Examples

These calls delete files immediately; the procedure has no preview parameter.
Use retention values appropriate to the recovery points and external copies
you need to keep.

### Clean a directory after copying backups elsewhere

After verifying the external copy, a sysadmin can remove recognized backups
older than the reference minute, including backups of databases that no longer
exist. Files in subdirectories remain untouched.

```sql
Exec YourSqlDba.Maint.DeleteOldBackups
  @path = N'G:\Sql\Backups\ForXCOPY\'
, @BkpRetDays = 0
, @BkpRetDaysForUnSelectedDb = 0
, @extension = ''
```

### Clean test database backups while keeping archive variants

This example retains seven days of `.bak` files for user databases ending in
`_test`, excluding those whose names contain `Archive`. Unselected files are
kept. The system database inclusion and MSDB rules described above still apply.
The same call can run in an SQL Agent job or an SSMS query window.

```sql
Exec YourSqlDba.Maint.DeleteOldBackups
  @path = N'G:\Sql\Backups\ForXCOPY\'
, @BkpRetDays = 7
, @BkpRetDaysForUnSelectedDb = NULL
, @extension = '.bak'
, @IncDb = N'
%[_]test
'
, @ExcDb = N'
%Archive%
'
```

## Integration and reporting

`Maint.YourSqlDba_DoMaint` passes `@FullBkpRetDays` for the full/differential
backup directory and `@LogBkpRetDays` for the log directory, with the configured
extensions. During differential maintenance it sets
`@DeleteOnlyLogDiffBackups = 1` for the full/differential directory.
These calls occur before the backup operations; cleanup does not verify that
a new backup has succeeded or that the remaining files form a restorable chain.

A standalone call creates a history entry and sends a report to `@oper`
according to `@SendOnErrorOnly`. When called from the main maintenance procedure,
cleanup messages are included in that procedure's report. The operator must
exist and be enabled in `msdb.dbo.sysoperators`.

See [Main maintenance and retention](your-sql-dba-domaint.md#backup-retention),
[Configuration](../configuration.md#backup-retention), and
[Diagnostics and history](../diagnostics.md).
