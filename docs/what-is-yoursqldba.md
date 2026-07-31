---
layout: default
title: What is YourSqlDba?
parent: YourSqlDba documentation
nav_order: 1
has_children: false
---

# What is YourSqlDba?

> **Version française : [Qu’est-ce que YourSqlDba ?](fr/qu-est-ce-que-yoursqldba.md)**

YourSqlDba is an open-source maintenance and automation tool for Microsoft SQL
Server, developed by Maurice Pelchat. Written entirely in T-SQL, it is
distributed as a single script that creates a database named `YourSqlDba` on
the SQL Server instance. It automates backups, integrity checks, index and
statistics maintenance, cleanup, diagnostics, and reporting. It can also
delegate selected database-management operations to non-`sysadmin` users under
explicit controls.

Its purpose is to automate recurring maintenance and provide a consistent
framework for professional, part-time, and accidental DBAs. The default setup
is directly usable, while its schedules, database filters, retention rules,
and maintenance operations remain visible and configurable.

## What does YourSqlDba automate?

YourSqlDba automates tasks including:

- full, differential, and transaction log backups;
- integrity checks with `DBCC CHECKDB`;
- statistics updates;
- index reorganization or rebuilding according to index condition and the
  configured thresholds;
- removal of expired backup files;
- diagnostic data collection and email reporting.

## How is it built?

YourSqlDba relies on native SQL Server components:

- T-SQL;
- SQL Server Agent;
- Database Mail.

The installation script creates the `YourSqlDba` database and deploys its
stored procedures, functions, views, tables, and other supporting objects.
Running `Install.InitialSetupOfYourSqlDba` performs the initial configuration
and creates two default SQL Server Agent jobs. Both jobs call the primary
maintenance procedure:

```sql
Maint.YourSqlDba_DoMaint
```

That procedure coordinates the routine maintenance operations. See
[Getting started](getting-started.md) and the
[`Maint.YourSqlDba_DoMaint` reference](maintenance/your-sql-dba-domaint.md).

## How can it be customized?

Administrators can:

- select databases through inclusion and exclusion filters;
- create SQL Server Agent jobs with different schedules and actions;
- distribute expensive integrity checks, statistics updates, and index work
  across different runs;
- configure backup and retention strategies for different environments.

See [Configuration](configuration.md) for the available controls.

## How does controlled delegation work?

YourSqlDba lets administrators authorize selected non-`sysadmin` users, such
as application owners or senior support staff, to perform specific operations
on an explicit set of databases. These operations include backup, restore,
duplication, refresh, backup cleanup, maintenance mode, and application-upgrade
workflows.

Authorization is configured centrally in `Maint.DelegatedDbManagement`.
Additional safeguards, including restore-target naming rules, prevent a
delegated user from overwriting the source database or an unrelated database.
This supports least-privilege operational workflows without granting the full
`sysadmin` role. See [Delegated database management](maintenance/delegated-database-management.md).

## How are problems diagnosed?

The inline table-valued function `Maint.HistoryView` centralizes the commands,
messages, errors, execution context, status, and timing recorded during
maintenance. Email reports include a ready-to-run query that helps investigate
the relevant execution quickly. See [Diagnostics and reporting](diagnostics.md).

## Who is it for?

YourSqlDba is particularly suitable for:

- organizations without a full-time DBA;
- software vendors that deliver solutions backed by SQL Server;
- SQL Server instances that host many databases;
- professional DBAs who want a transparent and configurable maintenance
  framework implemented entirely in T-SQL;
- teams that need to delegate controlled database operations without granting
  `sysadmin` privileges.

For more detail, see [Who YourSqlDba is for](Who-YourSqlDba-is-for.md).

## Project philosophy and history

YourSqlDba is designed to install from one script, upgrade by rerunning the
current script, and keep its maintenance logic visible in SQL Server. It avoids
unnecessary work by selecting operations according to database and index state
rather than blindly performing every possible task on every run.

The project has existed since 2007. Its database self-maintenance approach
earned Maurice Pelchat the
[SQL Server Magazine 2007 Innovator Award](https://www.linkedin.com/in/maurice-pelchat-9891495/).
It remains actively maintained and documented online.

For SQL Server environments, YourSqlDba provides an open and highly
configurable alternative to built-in maintenance plans, with detailed
diagnostics and no additional software runtime.
