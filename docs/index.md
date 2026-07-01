---
layout: default
title: YourSqlDba documentation
nav_order: 1
has_children: true
---

# YourSqlDba

YourSqlDba is an open-source T-SQL script that automates common SQL Server
database maintenance tasks.

Summary
-------

The project provides a single installable script that creates a database named
`YourSqlDba` on the target SQL Server instance. That database contains stored
procedures, functions, and supporting objects used to schedule and run backups,
integrity checks, index maintenance, metrics collection, and diagnostics.

QuickLinks
----------

- Version history and release notes: [Releases](releases.md)
- Project README: [README.md](https://github.com/pelsql/YourSqlDba#readme)
- Installation and first-time setup: [Installation guide](installation.md)
- Main maintenance entry point: [`Maint.YourSqlDba_DoMaint`](maintenance/your-sql-dba-domaint.md)
- Delegated database management: [Controlled backup, restore, database refresh, cleanup, and application-upgrade operations for selected non-sysadmin users](maintenance/delegated-database-management.md)
- Job reporting and diagnostics: [`Maint.HistoryView`, Database Mail, and performance diagnostics](diagnostics.md)
- Latest install script: [YourSQLDba_InstallOrUpdateScript.sql](https://raw.githubusercontent.com/pelsql/YourSqlDba/refs/heads/master/YourSQLDba_InstallOrUpdateScript.sql)

How to get started
------------------

1. Read the [installation guide](installation.md).
2. Run `YourSQLDba_InstallOrUpdateScript.sql` on the SQL Server instance where
   you want to install YourSqlDba.
3. Complete the SQL Server Agent and Database Mail setup described in the
   installation guide.

For a shorter project overview, see the
[repository README](https://github.com/pelsql/YourSqlDba#readme).
