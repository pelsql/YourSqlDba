# YourSqlDba

**Contact info: [Maurice Pelchat](https://www.linkedin.com/in/maurice-pelchat-9891495/)**

**[Get the script for the latest release](https://raw.githubusercontent.com/pelsql/YourSqlDba/refs/heads/master/YourSQLDba_InstallOrUpdateScript.sql)**

For previous versions and details about changes between releases, see the
[version history and release notes](docs/releases.md).

To display the currently installed version of YourSqlDba, execute:

```sql
SELECT * FROM Install.VersionInfo();
```

> [!WARNING]
> **Breaking change — Starting with version 7.1.0.12 — delegated database management:** Existing non-sysadmin
> backup, restore, duplication, backup cleanup, or maintenance-mode workflows
> may stop working after this upgrade. Each delegated login and its authorized
> databases must now be configured in `Maint.DelegatedDbManagement`, and restore
> targets must follow the new naming restrictions. Review the
> [delegated database management documentation](docs/maintenance/delegated-database-management.md)
> before upgrading any instance that uses delegated operations.

Everything about YourSqlDba is documented in the
**[GitHub Pages documentation](https://pelsql.github.io/YourSqlDba/)**,
which can be read directly in a web browser. Start with the landing page for an
overview of what YourSqlDba does and how it works. Its `QuickLinks` table points
to frequently used documentation.

> YourSqlDba operates through SQL Server Agent jobs and Database Mail, both of
> which must be configured. After downloading and running the YourSqlDba script,
> execute `Install.InitialSetupOfYourSqlDba` once per instance. This procedure
> configures Database Mail, backup directories, and default behaviors. It also
> creates and schedules two SQL Server Agent jobs. Future upgrades do not require
> rerunning this procedure.

> Each job has a single maintenance step. Both call the main stored procedure,
> `Maint.YourSqlDba_DoMaint`, with parameters appropriate for the job type. These
> parameters are documented in detail in the online documentation.

YourSqlDba is a large T-SQL script that automates database maintenance tasks for
SQL Server. It creates a database named `YourSqlDba` containing T-SQL modules,
including functions, stored procedures, and views. Most operate behind the
scheduled maintenance jobs, while some are also useful for occasional DBA work.

## Latest release: 7.1.0.12

1. **Controlled delegation of database management operations**

   YourSqlDba now provides a least-privilege delegation model for application
   owners and senior support users who need to refresh non-production databases,
   test or roll back application upgrades, or clean up backups without receiving
   `sysadmin` privileges.

   A sysadmin authorizes each delegated login through
   `Maint.DelegatedDbManagement`. Restore targets are restricted by naming rules
   that prevent delegated users from overwriting source or unrelated databases.

2. **Simplified transaction log backup file management**

   The initial transaction log backup produced after a full or differential
   maintenance backup now keeps its own file name and is no longer reused by the
   regular log backup job.

   The next regular log backup creates the reusable log backup file and records
   it in `Maint.JobLastBkpLocations.lastLogBkpFile`. When
   `@BkpLogsOnSameFile = 0`, each regular log backup continues to use a new file.

3. **More resilient YourSqlDba upgrades**

   Upgrade information is preserved temporarily in the
   `YourSqlDbaUpgradeSavedInfos` database. This protects the existing
   configuration if an upgrade fails. The temporary database is removed after a
   successful upgrade. Exclusive access handling during upgrades has also been
   improved.

4. **Exclusive access for delegated restores**

   Before a delegated non-sysadmin restore, YourSqlDba terminates active sessions
   connected to the target database. Delegated users cannot normally terminate
   those sessions themselves, and their restore targets are already restricted.

   For sysadmins, sessions are not terminated automatically because a parameter
   mistake could affect an unrelated or production database. Sysadmins must
   handle active sessions explicitly when using `Maint.DuplicateDb`,
   `Maint.DuplicateDbFromBackupHistory`, or `Maint.RestoreDb`. They may call
   `S#.KillDbUsers` explicitly when appropriate.

For the complete history, see the [release notes](docs/releases.md).
