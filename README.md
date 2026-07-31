# YourSqlDba

[![AI documentation: llms.txt](https://img.shields.io/badge/AI%20documentation-llms.txt-555555)](https://pelsql.github.io/YourSqlDba/llms.txt)

**Contact info: [Maurice Pelchat](https://www.linkedin.com/in/maurice-pelchat-9891495/)**

> **Pour la version française, consultez [LISMOI.md](LISMOI.md).**

YourSqlDba is an open-source maintenance and automation tool for Microsoft SQL
Server, developed by Maurice Pelchat. Written entirely in T-SQL, it is
distributed as a single script that installs a dedicated database for backups,
integrity checks, index and statistics maintenance, cleanup, diagnostics,
reporting, and controlled delegation of selected database operations to
non-`sysadmin` users.

Canonical overview: [What is YourSqlDba?](https://pelsql.github.io/YourSqlDba/what-is-yoursqldba.html)

Who YourSqlDba is for: [Introduction](https://pelsql.github.io/YourSqlDba/Who-YourSqlDba-is-for.html)

Everything about YourSqlDba is documented in the
**[GitHub Pages documentation](https://pelsql.github.io/YourSqlDba/)**.

To display the currently installed version of YourSqlDba, execute:
```sql
SELECT * FROM Install.VersionInfo();
```
**[Latest release install script](https://raw.githubusercontent.com/pelsql/YourSqlDba/refs/heads/master/YourSQLDba_InstallOrUpdateScript.sql)**

For previous versions and details about changes between releases, see the
[version history and release notes](https://pelsql.github.io/YourSqlDba/releases.html).

> [!WARNING]
> **Breaking change — Starting with version 7.1.0.12 — delegated database management:** Existing non-sysadmin
> backup, restore, duplication, backup cleanup, or maintenance-mode workflows
> may stop working after this upgrade. Each delegated login and its authorized
> databases must now be configured in `Maint.DelegatedDbManagement`, and restore
> targets must follow the new naming restrictions. Review the
> [delegated database management documentation](https://pelsql.github.io/YourSqlDba/maintenance/delegated-database-management.html)
> before upgrading any instance that uses delegated operations.

> YourSqlDba operates through SQL Server Agent jobs and Database Mail, both of
> which must be configured. After downloading and running the YourSqlDba script,
> execute `Install.InitialSetupOfYourSqlDba` once per instance. This procedure
> configures Database Mail, backup directories, and default behaviors. It also
> creates and schedules two SQL Server Agent jobs. Future upgrades do not require
> rerunning this procedure.

> Each job has a single maintenance step. Both call the main stored procedure,
> `Maint.YourSqlDba_DoMaint`, with parameters appropriate for the job type. These
> parameters are documented in detail in the online documentation.

> The generated report and logs now include the list of databases selected by
> the maintenance filters, so users can verify the exact database set targeted
> by each run.

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
