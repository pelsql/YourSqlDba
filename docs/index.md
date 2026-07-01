---
layout: default
title: YourSqlDba
nav_order: 1
---

# YourSqlDba

YourSqlDba is an open-source T-SQL script that automates common SQL Server database maintenance tasks.

Summary
-------

This project provides a single installable script that creates a database named YourSqlDba on the target SQL Server instance. That database contains stored procedures, functions and helpers used to schedule and run maintenance (backups, integrity checks, index maintenance, metrics and diagnostics).

QuickLinks
----------

- Version history and release notes: [Releases](releases.html)
- Project README: [README.md](https://github.com/pelsql/YourSqlDba#readme)
- Online documentation (GitHub Pages): [https://pelsql.github.io/YourSqlDba/](https://pelsql.github.io/YourSqlDba/)
- Latest install script (raw): [YourSQLDba_InstallOrUpdateScript.sql](https://github.com/pelsql/YourSqlDba/blob/master/YourSQLDba_InstallOrUpdateScript.sql?raw=true)
- Installation / First install: [Installation guide](https://pelsql.github.io/YourSqlDba/installation.html)
- Main maintenance entry point: [Maintenance - main entry](https://pelsql.github.io/YourSqlDba/maintenance/your-sql-dba-domaint.html)
- Job reporting & diagnostics: [Diagnostics and reporting](https://pelsql.github.io/YourSqlDba/maintenance/index.html)

How to get started
------------------

1. Read the [Installation guide](https://pelsql.github.io/YourSqlDba/installation.html).
2. Run the `YourSQLDba_InstallOrUpdateScript.sql` script on the server where you want to install the tools.
3. Follow the post-install setup (SQL Agent jobs and Database Mail) described in the Installation guide.

If you prefer a short overview, start with the project README which links to the most-read pages and QuickLinks above.

If you want this page translated to French (or another language) let me know and I can add a short localized introduction.
