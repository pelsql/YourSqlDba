---
layout: default
title: Who YourSqlDba Is For
parent: YourSqlDba documentation
nav_order: 2
has_children: false
---

# Who YourSqlDba Is For

YourSqlDba is intended first for DBAs, whether accidental or professional. The
former often have only a basic understanding of the role, unlike the latter,
but the solution can serve both through an immediately usable initial
configuration and advanced customization options.

Another target audience consists of people responsible for specialized
application solutions that rely on a SQL Server instance dedicated to a single
database. Without being DBAs, they know that the data must be backed up and
protected, and they need reliable maintenance that requires little daily
administration.

There are two common application-owner situations. In the first, a DBA,
sometimes only an occasional DBA, remains responsible for the SQL Server
environment but delegates restricted backup, restore, refresh, or upgrade tasks
to the application owner. In the second, the application owner receives a
complete product or appliance-like solution. In that delivery model,
YourSqlDba can be installed and framed by the team that ships the product; in
earlier deployments this maintenance could be launched by Windows Task
Scheduler through a PowerShell module rather than being operated directly by
the application owner.

## The challenge

IT professionals are often assigned part-time responsibilities for which they have not been sufficiently trained. Database administration is one of those responsibilities. They become accidental DBAs.

After years of trying to train these accidental DBAs, I observed that their lack of regular practice led to serious and recurring omissions.

Someone who carries such an important responsibility, part-time and alongside unrelated priorities, cannot reasonably be expected to review everything every day. It is a thankless task, and a large part of it can be automated.

Automation is equally relevant to a professional DBA. YourSqlDba can provide a
complete solution while retaining the flexibility to divide or parallelize the
work when the number or size of databases, or the available maintenance window,
requires a more elaborate arrangement.

At the other end of the experience spectrum, YourSqlDba keeps the person
responsible for the application informed through its reports. That person can
see whether maintenance and backups are running successfully without having to
understand their internal operation. Depending on the deployment model, that
person either alerts the DBA or support team, or follows the operational
instructions supplied with the delivered product.

This visibility does not replace keeping a copy of the backups outside the SQL
Server. Depending on the environment, the application owner must be reminded to
rotate removable media regularly, or backups should be written to a file server
that is itself protected by a higher-level backup service.

## The idea

SQL Server documents what it owns as ordinary data: databases, tables, indexes, backup history, jobs, and so on. It also makes it possible to script the same operations SSMS performs, because SSMS itself generates T-SQL statements.

T-SQL can build statements dynamically as character strings and execute them. In that context, the variable data is mainly the names of the objects to manage. By integrating metadata — database names, table names, index names, and so on — into character strings representing maintenance statements, you can build an automated database administration feature.

This is where the idea emerged: database maintenance could be automated in pure SQL, in a sufficiently dynamic way to adapt to new databases, new tables, and new indexes. YourSqlDba was born from that idea.

YourSqlDba is delivered as a script that creates a database of the same name and deploys SQL modules into it. The maintenance entry point is a single procedure that calls other procedures.

## Dynamic filtering of databases

Part-time DBAs do not want to name every database manually. YourSqlDba uses filters that target databases dynamically by pattern:

- inclusion patterns to select databases generically,
- exclusion patterns to remove unwanted databases,
- multiple lists of patterns to adapt automatically as databases evolve.

The rule is simple:

- if the inclusion filter is not empty, it reduces the set of databases to manage;
- the exclusion filter then removes what must not be managed from the remaining set;
- whether or not the inclusion filter reduced the list, the exclusion filter always applies.

Once the selection of databases is determined, the main maintenance procedure performs the work.

## What the solution manages

YourSqlDba automates the core maintenance actions that matter:

- backups,
- integrity checks,
- statistics updates,
- index optimization (reorganize or rebuild as needed).

The optimization task is divided into two parts:

1. updating statistics so SQL Server can choose the best query plans,
2. reorganizing or rebuilding indexes that become fragmented and bloated over time.

## Why automation matters

A DBA should not have to monitor and drive everything manually if the solution can run on a precise schedule. SQL Server Agent makes recurring execution possible and can report problems.

Reports are essential. YourSqlDba provides them with:

- execution summary,
- detailed SQL commands issued,
- success/failure status and error messages,
- diagnostic queries ready to copy and paste.

## Who should use YourSqlDba

1. Application owners receiving delegated operations: A professional or
   occasional DBA remains responsible for the SQL Server environment but
   authorizes restricted backup, restore, database refresh, cleanup, or
   application-upgrade operations for selected databases.
2. Application owners receiving a product: The team that delivers the product
   also frames the maintenance model. The application owner mainly receives
   reports and escalation instructions, while the maintenance execution can be
   hidden behind the product's operational packaging.
3. Accidental DBAs: Prevent forgotten tasks, provide appropriate alerts, and
   enable escalation to SQL experts when needed if the provided diagnostics do
   not clarify the issue.
4. Professional DBAs: Do what accidental DBAs can do, and when maintenance load
   becomes excessive, divide tasks with different schedules. Detailed
   diagnostics for problems will be more familiar to them.

## How it is delivered

YourSqlDba is delivered as a single installable script. Running it creates the `YourSqlDba` database and all maintenance modules.

Initial activation is performed by a utility procedure that only needs to be executed once. A Database Mail configuration completes the process and allows YourSqlDba to communicate results by email.
