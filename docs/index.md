---
layout: default
title: YourSqlDba documentation
nav_order: 1
has_children: true
---

# YourSqlDba

YourSqlDba is an open-source T-SQL script that automates common SQL Server
database maintenance tasks. It provides a practical default setup for routine
maintenance while remaining adaptable to instances with many databases,
different schedules, or more specialized operational requirements.

Summary
-------

The project provides a single installable script that creates a database named
`YourSqlDba` on the target SQL Server instance. That database contains stored
procedures, functions, and supporting objects used to schedule and run backups,
integrity checks, index maintenance, metrics collection, and diagnostics.

YourSqlDba is designed around SQL Server components that DBAs already use: T-SQL,
SQL Server Agent, and Database Mail for reporting. Its default jobs provide a
direct starting point, while their schedules and calls to
`Maint.YourSqlDba_DoMaint` remain visible and configurable.

Why use YourSqlDba
------------------

- It combines backups, integrity checks, statistics updates, selective index
  maintenance, cleanup, and reporting in one maintenance workflow.
- It limits unnecessary work by spreading suitable operations across runs and
  maintaining indexes according to their condition.
- It scales from the default two-job setup to database groups with different
  actions and schedules through SQL Agent job steps and database-name filters.
- Detailed reporting and `Maint.HistoryView` expose the commands, messages,
  execution context, status, and errors produced by maintenance.
- Its restore-based mirroring can validate backup chains, maintain recoverable
  copies on another instance, and prepare a side-by-side SQL Server migration.

QuickLinks
----------

- Version history and release notes: [Releases](releases.md)
- Project README: [README.md](https://github.com/pelsql/YourSqlDba#readme)
- Who YourSqlDba is for: [Introduction](Who-YourSqlDba-is-for.md)
- Installation and first-time setup: [Installation guide](installation.md)
- Main maintenance entry point: [`Maint.YourSqlDba_DoMaint`](maintenance/your-sql-dba-domaint.md)
- Delegated database management: [Controlled backup, restore, database refresh, cleanup, and application-upgrade operations for selected non-sysadmin users](maintenance/delegated-database-management.md)
- Mirror and migration preparation: [Restore-based mirroring, migration testing, and failover](maintenance/mirror-standby-migration.md)
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
