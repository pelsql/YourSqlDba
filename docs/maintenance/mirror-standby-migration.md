---
title: Mirror, standby, and migration testing
parent: Maintenance
grand_parent: YourSqlDba documentation
nav_order: 11
---

# Mirror, standby, and migration testing

This page documents the YourSqlDba mirroring feature that restores backups to a secondary SQL Server instance for validation, standby use, or migration testing.

> This is not SQL Server database mirroring. YourSqlDba uses a separate linked-server restore workflow driven by `Maint.YourSqlDba_DoMaint`.

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
- YourSqlDba must be installed on the target server and the versions must match.
- Remote access must work through the `YourSqlDba` login on the target server.
- If multiple source servers use the same mirror server, they should share a common `YourSqlDba` password for automatic login mapping.

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

 - `Mirroring.SetYourSqlDbaAccountForMirroring`
 - `Mirroring.AddServer` — creates and registers the linked server used by YourSqlDba mirroring.
 - `Mirroring.DropServer` — removes the linked server when it is no longer required.
 - `Maint.YourSqlDba_DoMaint`
