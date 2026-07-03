---
title: Mirroring procedure reference
parent: Maintenance
grand_parent: YourSqlDba documentation
nav_order: 12
---

# Mirroring procedure reference

This page documents the public procedures used to configure, operate, recover,
and remove YourSqlDba restore-based mirroring. For the architecture and migration
workflow, begin with [Mirror, standby, and migration testing](mirror-standby-migration.md).

{: .warning }
> These procedures configure linked-server security, recover databases, or take
> source databases offline. Run them as a YourSqlDba administrator and validate
> the affected servers and databases before execution.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

## Mirroring.AddServer

Run `Mirroring.AddServer` on the source instance to register a target instance
and create the linked-server configuration used by YourSqlDba.

The procedure:

- requires SQL Server Agent to be running so its service login can be detected;
- creates the linked server with the `MSOLEDBSQL` provider;
- configures login mappings, RPC, RPC OUT, and the remote query timeout;
- records the target in `Mirroring.TargetServer`;
- configures the `YourSqlDba` login used for remote operations;
- verifies that both instances run the same YourSqlDba version;
- synchronizes eligible SQL logins to the target.

If a linked server with the same logical name already exists, the procedure
removes its YourSqlDba configuration before recreating it.

### Parameters

| Parameter | Type | Default | Purpose |
| --- | --- | --- | --- |
| `@MirrorServer` | `nvarchar(512)` | Required | Logical linked-server name recorded by YourSqlDba. |
| `@remoteLogin` | `nvarchar(512)` | Required | SQL-authenticated sysadmin login on the target, used to establish remote mappings. |
| `@remotePassword` | `nvarchar(512)` | Required | Password for `@remoteLogin`. |
| `@ExcSysAdminLoginsInSync` | `int` | `0` | Reserved in the current signature; `Mirroring.AddServer` does not currently consume this value. |
| `@ExcLoginsFilter` | `nvarchar(max)` | Empty string | Reserved in the current signature; `Mirroring.AddServer` does not currently consume this value. |
| `@MirrorServerDataSrc` | `nvarchar(512)` | Empty string | Actual provider data source when it differs from the logical linked-server name. |
| `@YourSqlDbaAccountForMirroringPwd` | `nvarchar(512)` | `NULL` | Optional common password for the `YourSqlDba` login, particularly when several sources share one target. |

### Prerequisites

- Install the same YourSqlDba version on the source and target instances.
- Start SQL Server Agent on the source.
- Install and configure the `MSOLEDBSQL` provider.
- Ensure the target credentials supplied to the procedure have sysadmin rights.
- Make backup files accessible to the target, directly or through the path
  translations configured in `Maint.YourSqlDba_DoMaint`.

### Example

```sql
EXEC YourSqlDba.Mirroring.AddServer
    @MirrorServer = N'SQLTARGET\SQL2025'
  , @remoteLogin = N'MirroringSetup'
  , @remotePassword = N'<secure-password>';
```

Do not retain a real password in a saved script or source-control repository.
After registration, run a full maintenance backup or
`Maint.SaveDbOnNewFileSet` to seed each selected target database before log
backups are restored.

## Mirroring.DropServer

Run `Mirroring.DropServer` on the source instance to remove a target from
YourSqlDba. It removes the row from `Mirroring.TargetServer`, deletes the linked
server's login mappings, and drops the linked server.

It does not delete databases or backup files on the target instance.

### Parameters

| Parameter | Type | Default | Purpose |
| --- | --- | --- | --- |
| `@MirrorServer` | `sysname` | Empty string | Logical linked-server name to remove. |
| `@silent` | `int` | `0` | Suppresses some target-version reporting when set to `1`; it does not change the removal scope. |

### Example

```sql
EXEC YourSqlDba.Mirroring.DropServer
    @MirrorServer = N'SQLTARGET\SQL2025';
```

## Mirroring.DoRecovery

Run `Mirroring.DoRecovery` on the instance that currently hosts the databases
in `RESTORING` state. It executes `RESTORE DATABASE ... WITH RECOVERY` for each
eligible database selected by `@IncDb` and `@ExcDb`, then reports whether each
database became `ONLINE`.

Recovering a database ends its current restore sequence. Further differential
or log backups cannot be applied to that recovered copy. Use this procedure when
the copy is intentionally being made available, not as a diagnostic test during
continuous mirroring.

### Parameters

| Parameter | Type | Default | Purpose |
| --- | --- | --- | --- |
| `@IncDb` | `nvarchar(max)` | Empty string | Includes database names matching the supplied SQL `LIKE` patterns. Empty selects all eligible databases. |
| `@ExcDb` | `nvarchar(max)` | Empty string | Excludes matching databases from the included set. |

### Example

```sql
EXEC YourSqlDba.Mirroring.DoRecovery
    @IncDb = N'Payroll,Accounting'
  , @ExcDb = N'%Archive%';
```

This procedure does not change application connection strings and does not take
matching databases on another instance offline.

## Mirroring.Failover

Run `Mirroring.Failover` on the source instance to perform final synchronization
and make selected target databases available. This is the normal cutover method
for a migration prepared through YourSqlDba mirroring.

For each eligible database, the procedure validates the source and target,
disconnects source users, optionally creates and restores a final backup, takes
the source database offline, recovers the target database, restores its owner,
and adjusts its compatibility level for the target SQL Server version.

The final synchronization uses:

- a transaction log backup for `FULL` and `BULK_LOGGED` databases;
- a differential backup for `SIMPLE` databases.

### Parameters

| Parameter | Type | Default | Purpose |
| --- | --- | --- | --- |
| `@IncDb` | `nvarchar(max)` | Empty string | Includes source databases matching the supplied patterns. Empty selects all eligible databases. |
| `@ExcDb` | `nvarchar(max)` | Empty string | Excludes matching databases from the included set. |
| `@Simulation` | `int` | `0` | When set to `1`, skips the cutover. The current implementation should not be treated as a complete readiness validation. |
| `@LastDataSync` | `int` | `1` | Creates and restores the final YourSqlDba backup. Set to `0` when an external synchronization product has already completed the final data synchronization. |

### Example

```sql
EXEC YourSqlDba.Mirroring.Failover
    @IncDb = N'Payroll,Accounting'
  , @ExcDb = N'%Archive%'
  , @Simulation = 0
  , @LastDataSync = 1;
```

{: .warning }
> A successful failover leaves the source databases `OFFLINE` and the target
> databases `ONLINE`. It does not redirect clients to the target instance.
> Coordinate application shutdown, connection-string or DNS changes, validation,
> and rollback procedures outside YourSqlDba.

After cutover, establish a new full backup baseline on the target for databases
that will use transaction log backups there.

## Mirroring.SetYourSqlDbaAccountForMirroring

Run `Mirroring.SetYourSqlDbaAccountForMirroring` on a source instance to rebuild
the `YourSqlDba` login mappings for every target recorded in
`Mirroring.TargetServer`.

This is especially relevant when several source instances share one target and
must use a common `YourSqlDba` password. When a password is supplied, the
procedure applies it to the local and remote `YourSqlDba` logins and recreates
the mappings. When it is omitted, the procedure generates credentials while
preserving the original local password hash.

### Parameters

| Parameter | Type | Default | Purpose |
| --- | --- | --- | --- |
| `@YourSqlDbaAccountForMirroringPwd` | `nvarchar(max)` | `NULL` | Optional common password used to rebuild mirroring login mappings. |

### Example

```sql
EXEC YourSqlDba.Mirroring.SetYourSqlDbaAccountForMirroring
    @YourSqlDbaAccountForMirroringPwd = N'<secure-password>';
```

Do not retain the supplied password in job text, documentation, or source
control.

## Upgrade.MakeDbCompatibleToTarget

`Mirroring.Failover` calls `Upgrade.MakeDbCompatibleToTarget` on the target
instance after recovering a migrated database. The procedure sets the database
to `MULTI_USER` and changes its compatibility level to the level associated
with the target SQL Server version.

### Parameters

| Parameter | Type | Default | Purpose |
| --- | --- | --- | --- |
| `@DbName` | `sysname` | Required | Database to make compatible with the target instance. |

### Example

This procedure is normally invoked by `Mirroring.Failover`. For a database that
was migrated manually, it can be called directly on the target:

```sql
EXEC YourSqlDba.Upgrade.MakeDbCompatibleToTarget
    @DbName = N'Payroll';
```

Changing the compatibility level can affect query optimization and application
behavior. Test the application and its important workloads at the target level.

## Mirroring.ProcessRestores

`Mirroring.ProcessRestores` is the worker procedure executed by the SQL Agent
restore jobs that YourSqlDba creates and starts automatically. It consumes the
restore queue in order and records its activity under the originating
maintenance job history.

DBAs normally monitor its generated SQL Agent job and diagnose failures with
`Maint.HistoryView`; they should not schedule or invoke this procedure as an
independent restore workflow.
