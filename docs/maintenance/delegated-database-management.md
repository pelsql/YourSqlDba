---
title: Delegated database management
parent: Maintenance
grand_parent: YourSqlDba documentation
nav_order: 20
---

# Delegated database management

YourSqlDba can authorize a non-sysadmin login to perform a restricted set of
backup, restore, duplication, cleanup, and application-upgrade operations. This
allows application owners or senior support users to manage their
non-production databases without receiving unrestricted SQL Server privileges.

After validating the delegated workflows, remove broader permissions that are
no longer required, such as membership in the `dbcreator` fixed server role or
the `db_backupoperator` fixed database role.

See the procedures for [delegated backups](#delegated-backup-procedures),
[duplication and restore](#delegated-duplication-and-restore-procedures),
[backup cleanup](#delegated-backup-cleanup), and the
[application-upgrade workflow](#application-upgrade-workflow).

{: .warning }
> **Breaking change:** Existing non-sysadmin scripts that call delegated
> procedures may stop working after upgrading. A sysadmin must add each login
> and its authorized source databases to `Maint.DelegatedDbManagement` before
> those scripts are run again. Restore targets must also follow the naming rules
> described below.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Authorization model

Delegation is configured in `YourSqlDba.Maint.DelegatedDbManagement`. The table
contains one row per delegated login.

| Column | Purpose |
| --- | --- |
| `LoginName` | Login returned by `ORIGINAL_LOGIN()` for the delegated user. |
| `SourceDatabaseList` | Comma-separated source databases authorized for general delegated operations. |
| `MaintenanceModeDatabaseList` | Optional comma-separated databases additionally authorized for the application-upgrade workflow. |
| `CreatedAt` | Date and time at which the row was created. |
| `CreatedBy` | Login that created the row. |

`SourceDatabaseList` authorizes the backup, duplication, restore, and cleanup
operations described on this page. `MaintenanceModeDatabaseList` authorizes the
more specific maintenance-mode workflow. A database listed in
`SourceDatabaseList` is already authorized for both categories; the second list
is useful when a login should receive only the maintenance-mode authorization
for a database.

Sysadmin logins are not restricted by this table.

## Configure a delegated login

Run these statements as a sysadmin in the `YourSqlDba` database. Database names
in both lists are separated by commas. You can edit the table directly in SSMS
by selecting **Edit Top 200 Rows** from its context menu, or adapt the `INSERT`,
`UPDATE`, and `DELETE` examples below.

### Add a login

```sql
USE YourSqlDba;
GO

INSERT Maint.DelegatedDbManagement
       (LoginName, SourceDatabaseList, MaintenanceModeDatabaseList)
VALUES (N'DOMAIN\AppSupport',
        N'Payroll,Accounting',
        N'Payroll');
```

### Change its authorization

The update replaces the complete contents of each list.

```sql
UPDATE Maint.DelegatedDbManagement
SET SourceDatabaseList = N'Payroll,Accounting,Reporting',
    MaintenanceModeDatabaseList = N'Payroll,Accounting'
WHERE LoginName = N'DOMAIN\AppSupport';
```

### Review the configuration

```sql
SELECT LoginName,
       SourceDatabaseList,
       MaintenanceModeDatabaseList,
       CreatedAt,
       CreatedBy
FROM Maint.DelegatedDbManagement
ORDER BY LoginName;
```

### Revoke delegation

```sql
DELETE Maint.DelegatedDbManagement
WHERE LoginName = N'DOMAIN\AppSupport';
```

## Restore target naming rules

A delegated non-sysadmin login cannot restore over the source database or use
an unrelated target name. The target must begin with the complete source name,
followed by an underscore and a suffix.

For a source database named `Payroll`, valid targets include:

- `Payroll_AppSupport`
- `Payroll_UpgradeTest`
- `Payroll_2026Q3`

Invalid targets include:

- `Payroll`, because a delegated user cannot overwrite the source;
- `PayrollTest`, because the required underscore is missing;
- `ProductionPayroll`, because it is not derived from the authorized source.

Do not create a production database whose name follows the delegated naming
pattern of another database. For example, if `Payroll` is delegated, a database
such as `Payroll_Production` would look like an authorized derivative.

## Delegated backup procedures

The following procedures require the source database to be present in
`SourceDatabaseList`:

- `Maint.SaveDbOnNewFileSet` creates a backup using YourSqlDba naming and backup
  rules.
- `Maint.SaveDbCopyOnly` creates a copy-only backup at the specified path and
  file name.

Example:

```sql
EXEC Maint.SaveDbCopyOnly
    @DbName = N'Payroll',
    @PathAndFilename = N'D:\SQLBackups\Payroll_AppSupport.bak';
```

## Delegated duplication and restore procedures

The following procedures enforce both the source authorization and target
naming rules:

- `Maint.DuplicateDb` creates an intermediate backup and restores it under the
  target name.
- `Maint.DuplicateDbFromBackupHistory` restores from the backup locations
  recorded by YourSqlDba.
- `Maint.RestoreDb` restores a specified backup file; the source database is
  validated from the backup information.

Examples:

```sql
EXEC Maint.DuplicateDb
    @SourceDb = N'Payroll',
    @TargetDb = N'Payroll_AppSupport';

EXEC Maint.DuplicateDbFromBackupHistory
    @SourceDb = N'Payroll',
    @TargetDb = N'Payroll_UpgradeTest';
```

Before restoring over an existing delegated target, YourSqlDba terminates its
active sessions because a non-sysadmin user normally cannot do so. This is not
done automatically for sysadmins: they may restore unrelated databases and
must therefore handle active sessions explicitly when appropriate.

## Delegated backup cleanup

`Maint.DeleteOldBackups` allows a delegated login to remove old backup files
only for database variants derived from its authorized source databases. The
same source-name, underscore, and suffix rule applies.

Review `@Path`, retention, extension, `@IncDb`, and `@ExcDb` carefully before
running cleanup. A sysadmin is not restricted to delegated database variants.

## Application-upgrade workflow

The maintenance-mode workflow gives an application owner exclusive access to a
database for an upgrade while retaining a recovery point and a controlled way
to return the database to service.

The workflow provides the following procedures. The restore step is optional
and is used only when the upgrade must be rolled back.

1. `Maint.PrepDbForMaintenanceMode` disconnects users, renames the database with
   the `_MaintenanceMode` suffix, and establishes the recovery point.
2. `Maint.RestoreDbAtStartOfMaintenanceMode` restores that recovery point while
   leaving the database under its maintenance-mode name.
3. `Maint.ReturnDbToNormalUseFromMaintenanceMode` returns the upgraded or
   restored database to its original name and normal use.

Example:

```sql
EXEC Maint.PrepDbForMaintenanceMode
    @DbList = N'Payroll';

-- Run and validate the application upgrade against Payroll_MaintenanceMode.

-- If a rollback is required:
EXEC Maint.RestoreDbAtStartOfMaintenanceMode
    @DbList = N'Payroll';

-- Return either the upgraded or restored database to service:
EXEC Maint.ReturnDbToNormalUseFromMaintenanceMode
    @DbList = N'Payroll';
```

Authorization for this workflow can come from either `SourceDatabaseList` or
`MaintenanceModeDatabaseList`.

## Upgrade checklist

Before upgrading an instance that already uses non-sysadmin management scripts:

1. Identify every login that calls one of the procedures listed on this page.
2. Record the source databases required by each login.
3. Insert or update the corresponding row in
   `Maint.DelegatedDbManagement`.
4. Update restore target names so they use `SourceDatabase_suffix`.
5. Test each delegated workflow with the real non-sysadmin login.
6. Review any production database names that could be mistaken for delegated
   derivatives.
