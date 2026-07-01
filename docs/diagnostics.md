---
title: Diagnostics and reporting
parent: YourSqlDba documentation
nav_order: 50
---

# Diagnostics and reporting

YourSqlDba records the commands, messages, execution status, and errors produced
by maintenance jobs. It also provides tools for diagnosing Database Mail and
investigating SQL Server wait statistics.

Use these tools to answer three different questions:

- What did a maintenance job execute, and where did it fail?
- Why were YourSqlDba email reports or alerts not delivered?
- Which SQL Server waits accumulated during a measured workload?

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Common conditions after installation

Two reported conditions are common immediately after installing YourSqlDba.

### A transaction log backup requires a full backup

SQL Server cannot start a valid transaction log backup chain until an
appropriate full database backup exists. This message is expected for a new
database or after a restore that has not yet been followed by a full backup.

Run the full maintenance job or execute a suitably configured
`Maint.YourSqlDba_DoMaint` call to create the required full backup. For related
backup settings, see [`Maint.YourSqlDba_DoMaint`](maintenance/your-sql-dba-domaint.html#backup-mode).

### A database is not in the FULL recovery model

By default, YourSqlDba reports databases that are not in the `FULL` recovery
model. This policy supports regular transaction log backups and point-in-time
recovery for production databases.

Databases intentionally using another recovery model, such as disposable test
databases, can be excluded with
`@ExcDbFromPolicy_CheckFullRecoveryModel`. Review the
[`Maint.YourSqlDba_DoMaint` recovery model policy](maintenance/your-sql-dba-domaint.html#recovery-model-policy)
before changing the exclusion list.

## Maintenance diagnostics with Maint.HistoryView

`Maint.HistoryView` is the primary diagnostic and reporting tool for YourSqlDba
maintenance. It returns job events in chronological order, including generated
SQL, informational messages, SQL Server messages, completion status, and
errors.

The underlying history is stored in these tables:

- `Maint.JobHistory`, which identifies and describes each maintenance run;
- `Maint.JobHistoryDetails`, which records the original execution details;
- `Maint.JobHistoryLineDetails`, which stores the reportable lines consumed by
  `Maint.HistoryView`.

Query `Maint.HistoryView` instead of reading these tables directly. The function
organizes their data into a practical diagnostic result and can show overlapping
jobs in the same time range.

### Parameters

| Parameter | Purpose |
| --- | --- |
| `@StartDateTime` | Start of the reporting interval, supplied as `nvarchar(23)` in SQL style 121 format. |
| `@EndDateTime` | End of the reporting interval, supplied in the same format. |
| `@FilterOption` | Selects all events or only error-related events. Use a constant from `Maint.MaintenanceEnums`. |

The supported date representation is:

```text
YYYY-MM-DD hh:mm:ss.mmm
```

Using this unambiguous format prevents the session language from exchanging the
month and day during conversion.

### Filter and time constants

`Maint.MaintenanceEnums` provides named values for common calls:

| Constant | Meaning |
| --- | --- |
| `HV$ShowAll` | Return all events in the interval. |
| `HV$ShowErrOnly` | Return error-related events in the interval. |
| `HV$Now` | Current date and time. |
| `HV$FromMidnight` | Start of the current day. |
| `HV$FromYesterdayMidnight` | Start of the previous day. |
| `HV$Since12Hours` | Twelve hours before the current time. |
| `HV$Since1Hour` | One hour before the current time. |
| `HV$Since10Min` | Ten minutes before the current time. |

### Review recent activity

The following query displays all YourSqlDba activity from the last ten minutes:

```sql
SELECT
  H.cmdStartTime, H.JobNo, H.seq, H.Typ, H.line, H.Txt,
  H.MaintJobName, H.MainSqlCmd, H.Who, H.Prog, H.Host,
  H.SqlAgentJobName, H.JobId, H.JobStart, H.JobEnd
FROM
  Maint.MaintenanceEnums AS E
  CROSS APPLY
  Maint.HistoryView
  (
    CONVERT(nvarchar(23), E.HV$Since10Min, 121)
  , CONVERT(nvarchar(23), E.HV$Now, 121)
  , E.HV$ShowAll
  ) AS H
ORDER BY
  H.cmdStartTime, H.Seq, H.TypSeq, H.Typ, H.Line;
```

This is also useful while a maintenance job is running. Because the interval can
contain concurrent jobs, use `JobNo` and the job context columns to distinguish
their events.

### Investigate a reported job error

When a maintenance job reports an error, its email report provides a query
against `Maint.HistoryView`. That query already contains the job time range,
uses `HV$ShowErrOnly`, and restricts the output to the relevant `JobNo`. Copy it
into a query window connected to the SQL Server instance that ran the job.

A typical query has this form:

```sql
SELECT
  H.cmdStartTime, H.JobNo, H.seq, H.Typ, H.line, H.Txt,
  H.MaintJobName, H.MainSqlCmd, H.Who, H.Prog, H.Host,
  H.SqlAgentJobName, H.JobId, H.JobStart, H.JobEnd
FROM
  Maint.MaintenanceEnums AS E
  CROSS APPLY
  Maint.HistoryView
  (
    N'2026-06-30 00:40:00.750'
  , N'2026-06-30 00:40:02.520'
  , E.HV$ShowErrOnly
  ) AS H
WHERE
  H.JobNo = 10942
ORDER BY
  H.cmdStartTime, H.JobNo, H.Seq, H.TypSeq, H.Typ, H.Line;
```

Use the query supplied by the report rather than copying these sample dates and
job number.

### Main output columns

| Column | Meaning |
| --- | --- |
| `cmdStartTime` | Time associated with the event. |
| `JobNo` | YourSqlDba job execution that produced the event. |
| `Seq` | Event sequence within the recorded activity. |
| `Secs` | Duration in seconds when a duration applies. |
| `Typ` | Event type, such as job context, SQL, message, status, or error. |
| `Line` | Line number within a multiline event. |
| `Txt` | SQL text, message, status, or error text. |

When the output switches from one job to another, `Maint.HistoryView` also
populates context columns such as `MaintJobName`, `MainSqlCmd`, `Who`, `Prog`,
`Host`, `SqlAgentJobName`, `JobId`, `JobStart`, and `JobEnd`. Their intermittent
display makes concurrent job transitions easier to identify.

Since `Maint.HistoryView` is an inline table-valued function, its result can be
filtered like any other query. Apply additional predicates to `JobNo`, `Typ`,
`Txt`, or other columns when investigating a specific operation.

## Database Mail diagnostics

Run `Maint.DiagDbMail` when maintenance completes but its email report or alert
does not arrive:

```sql
EXEC Maint.DiagDbMail;
```

The procedure returns three result sets:

1. the current Database Mail queue state from
   `msdb.dbo.sysmail_help_queue_sp`;
2. the five most recent entries in `msdb.dbo.sysmail_sentitems`;
3. the 100 most recent rows from `msdb.dbo.sysmail_event_log`.

Use the queue state to confirm that Database Mail is running. Sent items show
what SQL Server handed to Database Mail, while the event log exposes SMTP,
authentication, connectivity, and other delivery errors. A message marked as
sent can still be rejected or filtered after it leaves SQL Server.

## Performance diagnostics with wait statistics

YourSqlDba includes two objects derived from Paul Randal's wait-statistics
analysis approach:

- `PerfMon.ResetAnalyzeWaitStats` clears the accumulated SQL Server wait
  statistics;
- `PerfMon.AnalyzeWaitStats()` summarizes the waits accumulated after that
  reset while excluding common benign waits.

To measure a representative workload:

```sql
EXEC PerfMon.ResetAnalyzeWaitStats;

-- Run or observe the workload long enough to collect a useful interval.

SELECT *
FROM
  PerfMon.AnalyzeWaitStats()
ORDER BY
  Percentage DESC;
```

Pay particular attention to `WaitType`, `Percentage`, `Wait_S`, `Resource_S`,
`Signal_S`, and their average values. Interpret them in the context of an active
workload and the measured interval. A high percentage during an idle period, or
a high value for one wait type by itself, does not establish the cause of a
performance problem.
