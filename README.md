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


## Latest release: 7.1.0.14

Sysadmin membership detection has been improved. Backup cleanup now checks the
SQL Server Database Engine service account and logs configuration anomalies
without stopping the remaining maintenance operations, including backups.
The final maintenance report signals the logged errors.

For details about earlier releases, including the breaking change introduced in
version 7.1.0.12, see the [online release notes](https://pelsql.github.io/YourSqlDba/releases.html).
