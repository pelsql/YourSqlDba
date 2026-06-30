---
title: Installation and upgrade
parent: YourSqlDba documentation
nav_order: 20
---

# Installation and upgrade

Install YourSqlDba by running the main T-SQL installation script. This creates
or updates the `YourSqlDba` database and deploys the objects used by maintenance.

## Prerequisites

- SQL Server instance with SQL Agent enabled
- permissions to create or alter the `YourSqlDba` database
- access to backup directories used by SQL Server
- Database Mail available for email reporting
- Windows account or service account that can write to backup paths

## First installation

For a first installation:

1. Open `YourSQLDba_InstallOrUpdateScript.sql` in SQL Server Management Studio.
2. Run the script against the target SQL Server instance.
3. Execute `Install.InitialSetupOfYourSqlDba` with values that match your environment.
4. Review the created SQL Agent jobs and schedules.
5. Confirm that Database Mail and SQL Agent notifications work.

Example:

```sql
EXEC Install.InitialSetupOfYourSqlDba
    @FullBackupPath = N'D:\SQLBackups',
    @LogBackupPath = N'D:\SQLBackups',
    @email = N'dba-team@example.com',
    @SmtpMailServer = N'smtp.example.com';
```

## Initial setup

Initial setup creates the default SQL Agent maintenance jobs and configures:

- full backup path
- transaction log backup path
- Database Mail profile
- SMTP server
- notification recipients
- SQL Agent schedules

This step is required after a first installation.

## Created SQL Agent jobs

The initial setup creates two default jobs.

| Job | Procedure called | Purpose |
| --- | --- | --- |
| Full maintenance | `Maint.YourSqlDba_DoMaint` | Daily maintenance and full backups |
| Log backups | `Maint.YourSqlDba_DoMaint` | Frequent transaction log backups |

Each job contains a SQL Agent job step that calls `Maint.YourSqlDba_DoMaint`
with different parameters.

## Upgrade

To upgrade YourSqlDba, run the latest `YourSQLDba_InstallOrUpdateScript.sql`
again.

The upgrade process preserves YourSqlDba configuration and history while
updating the database objects.

After an upgrade:

1. Review the version history.
2. Check SQL Agent job steps for changes.
3. Run a maintenance job manually if you want immediate validation.
4. Confirm that the maintenance email report is received.

## When to rerun initial setup

Rerun `Install.InitialSetupOfYourSqlDba` only when you need to recreate the
default job definitions, backup paths, mail profile, or notification settings.

> **Warning:** `Install.InitialSetupOfYourSqlDba` recreates the default
> definition of the daily maintenance and log backup jobs. Review any custom
> SQL Agent job steps before rerunning it.
