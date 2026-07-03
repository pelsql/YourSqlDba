---
title: Mirror, standby, and migration testing
parent: Maintenance
grand_parent: YourSqlDba documentation
nav_order: 11
---

# Mirror, standby, and migration testing

YourSqlDba mirroring maintains a restorable copy of selected databases on a
second SQL Server instance. A primary use case is preparing an upgrade to a
newer SQL Server version while keeping the final service interruption as short
as possible.

> This is not SQL Server database mirroring. YourSqlDba uses a separate linked-server restore workflow driven by `Maint.YourSqlDba_DoMaint`.

For signatures, parameters, prerequisites, and execution examples, see the
[Mirroring procedure reference](mirroring-reference.md).

## Preparing a SQL Server version upgrade

Before the migration, regular maintenance backups are restored continuously on
the target instance. Full, differential, and transaction log backups keep each
target database close to the state of its source database. In normal mirroring
mode, the target remains in `RESTORING` state so that subsequent backups can be
applied.

This approach provides two important benefits before cutover:

- most of the data has already been transferred and restored on the target;
- the regular restore activity verifies that the backup chain can be read and
  applied on the destination instance.

The target SQL Server version must be the same as or newer than the source
version. This makes it possible to prepare a side-by-side version upgrade
without attempting an unsupported restore to an older SQL Server version.

## How it works

When `Maint.YourSqlDba_DoMaint` runs with `@MirrorServer` set, YourSqlDba can queue backup restores to the remote server after each eligible backup.

The restore workflow includes:

- The maintenance task that produces backups also creates a mirror restore task if it does not already exist.
- In all cases, the mirror restore task is then started to process any queued restore operations.

The restore job is created automatically when needed. Its visible SQL Agent job name follows the pattern:

`Restores to <MirrorServer> For <SqlAgentJobName or MaintJobName>`

For example, if the maintenance job is named `YourSQLDba_FullBackups_And_Maintenance` and the mirror server is `MauriceSql\Sql2k25`, the restore job will be named:

`Restores to MauriceSql\Sql2k25 For YourSQLDba_FullBackups_And_Maintenance`

The default job step command is:

```sql
EXECUTE [Mirroring].[ProcessRestores]
```

## Cutover with Mirroring.Failover

`Mirroring.Failover` performs the final synchronization and switches the
selected databases from the source instance to the target instance. For each
eligible database, it:

1. terminates active connections on the source;
2. creates and restores the final transaction log backup when the database uses
   the `FULL` or `BULK_LOGGED` recovery model, or a final differential backup
   when it uses `SIMPLE`;
3. takes the source database offline to prevent further access or changes;
4. recovers the target database and brings it online;
5. restores the database owner when available;
6. sets the database compatibility level for the target SQL Server version.

The `@IncDb` and `@ExcDb` parameters allow the DBA to cut over a selected group
of databases independently of the database filters used by the regular
maintenance job. `@LastDataSync = 0` skips the final YourSqlDba backup and
restore when another data-synchronization product has already performed that
step.

{: .warning }
> `Mirroring.Failover` is a disruptive cutover operation. It disconnects users
> and leaves the source databases offline before making the target databases
> available. Validate connectivity, restore status, application configuration,
> database selection, and the rollback plan before executing it. Most users find
> it easier to keep the same instance names on different servers and adjust name
> resolution so it points to the new servers.

## Key parameters

These are parameters of `Maint.YourSqlDba_DoMaint`.

| Parameter | Purpose |
| --- | --- |
| `@MirrorServer` | Target linked server name for remote restore operations. |
| `@MigrationTestMode` | Enables migration testing mode, where only full backups are restored and remote copies are not repeatedly refreshed. |
| `@ReplaceSrcBkpPathToMatchingMirrorPath` | Maps source backup paths into corresponding mirror-server backup paths. |
| `@ReplacePathsInDbFilenames` | Rewrites database file paths when restoring on the mirror server. |

## Requirements

- Use `Mirroring.AddServer` to create and register the linked server for YourSqlDba mirroring.
- When the mirror server is no longer required, it can be removed with `Mirroring.DropServer`.
- The linked server name must match the value supplied in `@MirrorServer`.
- YourSqlDba must be installed on the target server, and both instances must use
  the same YourSqlDba version.
- Remote access must work through the `YourSqlDba` login on the target server. It is
  automatically created by `Mirroring.AddServer`; this is typically transparent for
  users who mirror to a single instance.
- If multiple source servers use the same mirror server, they should share a common
  `YourSqlDba` password for automatic login mapping. Conversely, if one source server
  restores to different mirror servers, the same rule applies; use
  `Mirroring.SetYourSqlDbaAccountForMirroring` to resolve the mappings.

## Linked server and security handling

YourSqlDba validates the mirror server before restore operations begin. If the server is missing or access is broken, the process can send a notification email to the configured operator.

An internal stored procedure checks each configured mirror server and can help recover access by calling `Mirroring.SetYourSqlDbaAccountForMirroring`.

## Login and SID synchronization
On each restore, YourSqlDba synchronizes SQL logins and their SIDs on the target instance so that restored databases retain correct login-to-user mappings. This is a database-level security measure (login/user SIDs), not a linked-server security setting, and it prevents orphaned users caused by SID mismatches.

If SQL Agent is not running, starting the restore job fails with an explicit error.

## Path translation and restore file configuration

If you do not want to grant the remote instance startup account access to the source server's backup directory, these parameters can be used as a workaround.

When the mirror server uses a different path structure than the source server — for example, different drive mappings to the same directories — use these parameters:

`@ReplaceSrcBkpPathToMatchingMirrorPath`: a search-and-replace string in the form `sourcePath>mirrorPath` to translate backup paths for the mirror server.
`@ReplacePathsInDbFilenames`: path rewrites for database file names during restore.

These parameter values are normalized by removing linefeeds and repeated spaces before use.

### Example

```sql
@ReplaceSrcBkpPathToMatchingMirrorPath = N'D:\SQLBackups>E:\MirrorBackups'
@ReplacePathsInDbFilenames = N'D:\Data>E:\Data'
```

## Migration testing mode

`@MigrationTestMode = 1` changes the mirror behavior for migration scenarios:

- Only full backups are restored to the mirror server.
- Restored databases are put online on the target server.
- While the target copy exists and is online, YourSqlDba does not attempt additional restores for that database. This can help avoid failures caused by insufficient space while allowing other restores to complete, and it provides a clearer view of actual disk space shortages.

This mode is useful when migrating databases to a newer SQL Server version and you need a one-time restore-based validation path rather than continuous mirror-style refreshes.

To return to normal mirror behavior, remove `@MigrationTestMode = 1` and stop any test databases on the target server.

## Failure handling and notifications

If the mirror workflow detects a missing or unreachable linked server, YourSqlDba can:

- disable mirror restore for the current run,
- log the failure in the job history,
- send an email to the configured operator with remediation instructions.

Common mirror failure causes:

- linked server not created or not reachable,
- `@MirrorServer` value does not match a linked server name,
- `YourSqlDba` remote login mapping failed,
- target server is down or inaccessible.

## Related objects

- [`Mirroring.AddServer`](mirroring-reference.md#mirroringaddserver) — creates and registers the linked server used by YourSqlDba mirroring.
- [`Mirroring.DropServer`](mirroring-reference.md#mirroringdropserver) — removes the linked server when it is no longer required.
- [`Mirroring.DoRecovery`](mirroring-reference.md#mirroringdorecovery) — recovers selected local databases from `RESTORING` state.
- [`Mirroring.Failover`](mirroring-reference.md#mirroringfailover) — performs final synchronization and migration cutover.
- [`Mirroring.SetYourSqlDbaAccountForMirroring`](mirroring-reference.md#mirroringsetyoursqldbaaccountformirroring) — rebuilds the mirroring login mappings.
- [`Upgrade.MakeDbCompatibleToTarget`](mirroring-reference.md#upgrademakedbcompatibletotarget) — applies the target compatibility level after migration.
- [`Mirroring.ProcessRestores`](mirroring-reference.md#mirroringprocessrestores) — internal SQL Agent restore worker.
- `Maint.YourSqlDba_DoMaint`
