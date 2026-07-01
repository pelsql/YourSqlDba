---
layout: default
title: Version history and release notes
---

# Version history and release notes

**Version 7.1.0.12**

{: .warning }
> **Breaking change — delegated database management:** Existing non-sysadmin
> backup, restore, duplication, backup cleanup, or maintenance-mode workflows
> may stop working after this upgrade. Each delegated login and its authorized
> databases must now be configured in `Maint.DelegatedDbManagement`, and restore
> targets must follow the new naming restrictions. Review the
> [delegated database management documentation](maintenance/delegated-database-management.html)
> before upgrading any instance that uses delegated operations.

1. **Controlled delegation of database management operations**

   YourSqlDba now provides a least-privilege delegation model for application
   owners and senior support users who need to refresh non-production databases,
   test or roll back application upgrades, or clean up backups without receiving
   `sysadmin` privileges.

   A sysadmin authorizes each delegated login through
   `Maint.DelegatedDbManagement`. Restore targets are restricted by naming rules
   that prevent delegated users from overwriting source or unrelated databases.

2. **Simplified transaction log backup file management**

   The initial transaction log backup produced after a full or differential
   maintenance backup now keeps its own file name and is no longer reused by the
   regular log backup job.

   The next regular log backup creates the reusable log backup file and records
   it in `Maint.JobLastBkpLocations.lastLogBkpFile`. When
   `@BkpLogsOnSameFile = 0`, each regular log backup continues to use a new file.

3. **More resilient YourSqlDba upgrades**

   Upgrade information is preserved temporarily in the
   `YourSqlDbaUpgradeSavedInfos` database. This protects the existing
   configuration if an upgrade fails. The temporary database is removed after a
   successful upgrade. Exclusive access handling during upgrades has also been
   improved.

4. **Exclusive access for delegated restores**

   Before a delegated non-sysadmin restore, YourSqlDba terminates active sessions
   connected to the target database. Delegated users cannot normally terminate
   those sessions themselves, and their restore targets are already restricted.

   For sysadmins, sessions are not terminated automatically because a parameter
   mistake could affect an unrelated or production database. Sysadmins must
   handle active sessions explicitly when using `Maint.DuplicateDb`,
   `Maint.DuplicateDbFromBackupHistory`, or `Maint.RestoreDb`. They may call
   `S#.KillDbUsers` explicitly when appropriate.

[View script 7.1.0.12 on GitHub](../YourSQLDba_InstallOrUpdateScript.sql)

**[Get script 7.1.0.12](https://raw.githubusercontent.com/pelsql/YourSqlDba/refs/heads/master/YourSQLDba_InstallOrUpdateScript.sql)**

**Version 7.1.0.11**
- `YourSqlDba` is now created in the `FULL` recovery model.
- `YourSqlDba` is always backed up whenever any maintenance backup runs.
- Its backup follows the current maintenance backup type: full, differential, or log.
- If a differential or log backup is requested before a valid full backup of `YourSqlDba` exists, a full backup is taken automatically to initialize the backup chain.

**[Get script 7.1.0.11](https://raw.githubusercontent.com/pelsql/YourSqlDba/3dd6a23ba772320c3392693dc3ba587da43cd8e1/YourSQLDba_InstallOrUpdateScript.sql)**

**Version 7.1.0.10**
Fixes a rare issue for YourSqlDba testers on Windows Pro using SMB shares for backups.
When a skipped SQL Agent job restarts with the server, it may start before SMB shares are available. This version adds a delay while checking backup destination availability. If the destination remains unavailable for any other reason, the job still stops.

**[Get script 7.1.0.10](https://raw.githubusercontent.com/pelsql/YourSqlDba/6cc3e280cd4a8ed81e84048d8fc24b0c6b4a9175/YourSQLDba_InstallOrUpdateScript.sql)** 


**Version 7.1.0.9**
1. YourSqlDba is now set in Full recovery model on creation.

2. Some obsolete security constraints have been removed. They were originally added because mirroring performed restores from a SQL Broker queue through an auto-activated stored procedure.

   Those constraints could cause problems when running `Maint.SaveDbCopyOnly`, `Maint.DuplicateDb`, or `Maint.SaveDbOnNewFileSet` on a standalone Windows Pro machine using a Microsoft account.

**[Get script 7.1.0.9](https://raw.githubusercontent.com/pelsql/YourSqlDba/2bb789c4bbb5076f15e7c4b98d355ea5574ce5c8/YourSQLDba_InstallOrUpdateScript.sql)** 


**Version 7.1.0.8**
Maint.ShrinkAllLogs is removed from this version

**[Get script 7.1.0.8](https://raw.githubusercontent.com/pelsql/YourSqlDba/e3cd2dfae63f8ffdf8da395cd055c1e069be3013/YourSQLDba_InstallOrUpdateScript.sql)** 

Some bugs fixed for non-users of mirroring


Maint.ShrinkAllLogs
**Version 7.1.0.7**

**[Get script 7.1.0.7](https://raw.githubusercontent.com/pelsql/YourSqlDba/534387a4b91e9866137cff7daa5fed7ff0c1f61c/YourSQLDba_InstallOrUpdateScript.sql)** 

Some procedures are removed.  Maint.ShrinkAllLogs. 
Internally YourSqlDba do not attempt to shrink the log anymore at log backup.

Some fixes for a better sync better backups/restores in mirroring.  Job for restores are changed. There is now a specific restore job for a specific backup job which proves to be more reliable for queuing and sync. 

**Version 7.1.0.6**

**[Get script 7.1.0.6](https://raw.githubusercontent.com/pelsql/YourSqlDba/340301644d2dceba1014531fb57396a9f3c61f4f/YourSQLDba_InstallOrUpdateScript.sql)** 

Fix for backup names too large for the name parameter of the backup command

**Version 7.1.0.5**

**[Get script 7.1.0.5](https://raw.githubusercontent.com/pelsql/YourSqlDba/45ae7f77d79e84581009f5a64b459a7ea77b3ab5/YourSQLDba_InstallOrUpdateScript.sql)** 

The yyyy-mm-dd date format used in the CREATE CREDENTIAL instruction was not universally supported.
When connections language setting is configured for French, it caused an installation error. The date format YYYYMMDD that is now used is no more dependent on the connection language settings.

In the function that generates backup command, the parameter NoInit was mistyped for NoInt, causing error in log backup commands.

**Version 7.1.0.4**

[Get script 7.1.0.4 on GitHub](https://raw.githubusercontent.com/pelsql/YourSqlDba/5a0674c0221b007c7bc238a78aa7f42a63164528/YourSQLDba_InstallOrUpdateScript.sql)
 
If you got script 7.1.0.3 re-apply this script, as the provider upgrade of YourSqlDba "Mirror server" may be incorrect.

**Fix** for the small number of users who use 
*group Managed Service Account* to run the Database Engine service.

This type of account slightly reduces the rights granted to the relational engine 
for disk access. As a result, creating an assembly directly from its DLL file can fail.

A valid alternative is to import the binary content into SQL Server and create the assembly 
from that binary content.

---

**Force Upgrade to MSOLEDBSQL provider** When YourSqlDba "Mirroring" servers use the old "SQLNCLI" 
provider, they are forcefully deleted to be asked to be recreated 
with Mirroring.AddServer, which will then use the MSOLEDBSQL provider.

[Doc reference on how to do a Mirroring.AddServer](https://onedrive.live.com/personal/12c385255443c4ed/_layouts/15/Doc.aspx?sourcedoc=%7B5443c4ed-8525-20c3-8012-a81b00000000%7D&action=view&redeem=aHR0cHM6Ly8xZHJ2Lm1zL28vYy8xMmMzODUyNTU0NDNjNGVkL0V1M0VRMVFsaGNNZ2dCS29Hd0FBQUFBQlJ2b290QVJmaE5LQjJaenNPU09yZkE_ZT11c0h6Vms&wd=target%28REFERENCE.one%7Cc7b30aeb-6ae2-4bd6-a550-14feb11d776d%2FMirroring.AddServer%7Ca71c4787-8076-4ed3-a6be-d6c5c3c8b6b3%2F%29&wdorigin=703&wdpartid=%7B2da72b12-728f-4f44-ba3b-477df906c323%7D%7B80%7D&wdsectionfileid=%7B12c385255443c4ed%21sfb02454d2d084363a169b209686c280b%7D)
(ignore the error "cannot add YourSqlDbaRemoteServerCred because it already exists"

---

**Code maintenance was also done to improve clarity**. No features were added or changed.

**Some tooling was added** to help with code maintenance. Useful only for YourSqlDba maintainers.
A permanent bookmark system is now used, based on special comments in the code of the form. The comment is the name of the bookmark.
```sql
-- @@MARK: Some comment explaining the purpose of this section of code
```
To add this tooling, in SSMS 22.3 or above (not tested in previous versions) goto Tools/External Tools, click add:

Via Tools/External Tools

|To Complete | Sample Value |
|---|---|
|Title |Goto-Mark |
|Command |C:\Program Files\PowerShell\7\pwsh.exe |
|Arguments |-NoProfile -ExecutionPolicy Bypass -File "C:\Github\YourSqlDba\Goto-Mark.ps1" "$(ItemPath)" "$(ItemFileName)" |
|Initial directory |$(ItemDir) |

The PowerShell script (this tool) scans the current source, builds a table of these marks, and displays it in a grid window.

You can scroll through the list or search for a specific string. Once an item is selected, click OK. No text must be selected when doing so.

These comments highlight the architectural elements of YourSqlDba. Reading them helps provide an overview of the project. They also make it easier to locate those elements in YourSqlDba, which is a very large script.

**Version 7.1.0.2**

In mirroring mode, restore could block log backups. Added internal locking to prevent this.

**[Get script for version 7.1.0.2](https://raw.githubusercontent.com/pelsql/YourSqlDba/5b53e48ee0da146731bca28e92a3088108d89d38/YourSQLDba_InstallOrUpdateScript.sql)**

**Version 7.1.0.1**

The restore queue is now cleared between full-backup executions.
This change ensures that the full-maintenance job no longer repeatedly reports leftover error entries from previous maintenance cycles. At the end of a cycle, the job performs a final check but intentionally does not remove any queued items that are in an error state. Instead, YourSqlDba sends a message instructing the user to query the queue (via a SELECT statement) to identify failed restores; those entries are then removed at the start of the next maintenance run.

**[Get script for version 7.1.0.1](https://raw.githubusercontent.com/pelsql/YourSqlDba/dc41bac618203c31b0d36371671b01ac72dfadc3/YourSQLDba_InstallOrUpdateScript.sql)**

**Version 7.1**

**[Get script for version 7.1](https://raw.githubusercontent.com/pelsql/YourSqlDba/c4460c5808e4696b75c1259a754bbcb1693cf1d8/YourSQLDba_InstallOrUpdateScript.sql)**

This version achieves a long-sought goal: removing all external assembly dependencies from YourSqlDba.
The script now builds its own assemblies from C# source code defined inside an inline table-valued function (iTvf).
Since the script itself compiles and creates the assembly, it also signs it automatically — no binaries are imported from untrusted sources.

By enabling the script to compile, deploy, and secure the assembly autonomously, YourSqlDba takes a major step toward self-containment.
This capability is derived from portions of my own library, **S#** (not yet published on GitHub).
That library allows C# source code to be embedded directly within an inline function definition, enabling a complete set of T-SQL commands to create the assembly and expose its SQLCLR entry points in SQL Server.

Special thanks to **Solomon Rutzky** ([srutzky@gmail.com](mailto:srutzky@gmail.com)) for his insights on assembly and module security, which helped finalize the design by adding a signature at creation time.
Now, every DBA can review the relatively straightforward C# code without the risk of executing unsigned assemblies, significantly improving the overall security of YourSqlDba.

Another important benefit is that the database no longer needs to be set as **TRUSTWORTHY**, further increasing security.
This improvement was made possible by removing all reliance on **Service Broker** for mirror server operations.
Previously, Service Broker was used to provide a background thread for running restores in parallel with backups.
It has now been replaced with an automatically created, standalone **SQL Agent YourSqlDba task** dedicated to this purpose.
That task starts automatically when backups complete and stops itself five minutes after finishing the `restoreQueue` processing.

Version 7.1 lays the foundation for the new architecture of YourSqlDba, introducing these components gradually so the original and new architectures can coexist without compromising code quality.
Upgrading is strongly recommended, especially for its security improvements.

---

With version 7.0, `YourSQLDba.Maint.HistoryView` (**see `Goals/QuickLinks table/Maint.HistoryView (V 7.0+)`**) received several improvements that enhance the visualization of multi-job interactions.
Events within a selected period are now displayed in chronological order and show simultaneous job activity.
Each time the log history switches jobs, columns indicating job lineage are highlighted to make these transitions easily identifiable.

`YourSQLDba.Maint.HistoryView` is an essential diagnostic tool for maintenance operations.
When investigating beyond the scope of a single job, pre-computed datetime values from `Maint.MaintenanceEnums` allow you to query YourSqlDba activity within relative time frames.
More details are available in the updated documentation.

**Version 7.0.0.5:**
**[Get script for version 7.0.0.5](https://github.com/pelsql/YourSqlDba/blob/68fbb28cfd3e380eca9b158372e0f077b5c4fa69/YourSQLDba_InstallOrUpdateScript.sql)**
Version 7.0.0.5 is mandatory, encompassing all earlier changes and fixing issues with documentation links in both the README and `index.md`.
Interim versions 7.0.0.0 to 7.0.0.4 are deprecated.

**Version 7.0.0.4:**
A divide-by-zero error may occur in integrity testing when database filtering excludes all databases. This is because table selection is based on `@SpreadCheckDd` job parameter. When computing this selection, the number of databases is taken into account to calculate a modulo value, set either to `@SpreadCheckDd` or the total number of databases.

**Version 7.0.0.3:**
Upon upgrading from a previous version, YourSqlDba maintenance logs may expand significantly, potentially causing log size issues. To mitigate this, cleanup operations are performed prior to the upgrade, with the DELETE statement broken into smaller statements (using `TOP()`) to prevent log oversizing. On upgrade from version below 7.0.0.2 upgrading may take a sensible time,so just be more patient.

**Version 7.0.0.2:**
The message for access issues with the mirror server has been updated to indicate that the mirror instance may simply be down.

**Version 7.0.0.1:**
Code for log cleanup, omitted since version 6.8.0.0, has been reintroduced in version 7.0.0.1. 


Version 7.0.0.4:
Replace TinyUrl links in readme and source that do not work for github links.

Version 7.0.0.5:
When Shrinking database files, if an error was encountered, improper call to yExecNLog.FormatBasicBeginCatchErrMsg () outside yourSqlDba database context prevent correct error reporting. Call was corrected to YourSqlDba.yExecNLog.FormatBasicBeginCatchErrMsg ()

**[Get script of 6.8.2.1](https://raw.githubusercontent.com/pelsql/YourSqlDba/6e7d1fbf53fb5344efae2b9640f551b78794d758/YourSQLDba_InstallOrUpdateScript.sql)**
SQL2022 needed a small adjustment to the procedure YUtl.CollectBackupHeaderInfoFromBackupFile because 'Restore Header Only' output now 3 more columns. I just saw the issue (2024-04-23). This is new to me, that I'm informed through the Issue feature from Github, and it is welcome. I'll now check more often, and be more proactive with new versions.

**[Get script of 6.8.2.0](https://raw.githubusercontent.com/pelsql/YourSqlDba/294f3f55dfebff31c6bb4079ab91ee6a7c9af08f/YourSQLDba_InstallOrUpdateScript.sql)**
>This version corrects a parameter problem for YourSQLDba.Maint.HistoryView, when the default language setting of the connection is french. 
Language setting can be "french" by being the default language for the login, or once connected, being set explicitely outside of the initial connetion process. 

The expect date format for the date is the style 121 of the convert function which is yyyy-mm-dd hh:mm:ss.mmm. But as function date parameters were datetime, an implicit conversion occurs.

When connection language setting is french, implicit date conversion swaps mm-dd to dd-mm. This give another date than the intended one or worst and invalid date leading to a runtime error (ex: a day value of 13 or greater being swapped to month isn't valid for a month value). 

**[YourSQLDba.Maint.HistoryView](#mainthistoryview)** date parameters were modified to received a string that is then internally explicitely converted to datetime with the 121 style option.

Select cmdStartTime, JobNo, seq, Typ, line, Txt 
From
  (Select ShowErrOnly=1, ShowAll=NULL) as Enum
  cross apply YourSQLDba.Maint.HistoryView('2024-04-20 22:25:01.297', '2024-04-20 22:25:09.223', ShowErrOnly) 
Order By cmdStartTime, JobNo, Seq, TypSeq, Typ, Line

Alongside some works are done to incorporate elements of an outside library (of mine), that I already started to use in part in previous versions. The goal is to allow a significant rewrite of YourSqlDba on the basis to make it much more compact and easy to read. I expect to "deflated" a lot YourSqlDba using elements of this new library, and eventually remove a lot of old routines from YourSqlDba.

**[Get script of 6.8.1.0](https://raw.githubusercontent.com/pelsql/YourSqlDba/df2f7622aa5606d08d144f33ca6c3674a7166a81/YourSQLDba_InstallOrUpdateScript.sql)**
##This version
>- If extend reporting capablities of YourSqlDba to help diagnosis in maintenance and harden exception trapping and reporting in it its own code.
>- Internal Coding: generalizes the use of Drop ... if exists statement.
>- Internal Coding : Reduction of the number of parameters to maintenance modules through the use of a context concept available from dbo.MainContextInfo().

**[Get script of 6.8.0.3](https://raw.githubusercontent.com/pelsql/YourSqlDba/afa43da1be7f18d770a97a44b373901039db79db/YourSQLDba_InstallOrUpdateScript.sql)**
>This version adds column SessionId to view Perfmon.SessionInfo 

**[Get script of 6.8.0.2](https://raw.githubusercontent.com/pelsql/YourSqlDba/2e744db1731ac73749e1c32a4cffbf0e1c4c6084/YourSQLDba_InstallOrUpdateScript.sql)**
>This version is a significant rewrite of the YourSqlDba logging system, and reporting of code played and exceptions whenever they occur. Previous code evolved to become too complex to maintain. The new logging system relies on a different architecture for logging YourSqlDba actions and errors. Previous code evolved to become too complex to maintain. The new logging system relies on a different architecture for logging YourSqlDba actions and errors. It reduced code size, made it more modern with fewer code paths, and easier to follow. It considers that more than one job may run at a time. I changed Maint.HistoryView parameters to starting and ending times of the job. Output also includes other job events that happen in that period. Poor SQL Agent's job history output formatting required new methods to leave a more readable result. What led to this significant review was some deadlock reported in the logging table when doing YourSqlDba mirroring. Solutions brought with version 6.7.3.2 needed a better retrofit of the architecture to make it sounder. I decided it was time to review the whole thing, so it is. A small correction 

**[Get script of 6.7.3.2](https://raw.githubusercontent.com/pelsql/YourSqlDba/9d78b52824110221bb2e9d6314286decbc88f4ab/YourSQLDba_InstallOrUpdateScript.sql)**
>This version has two set of unreleated feature changes. One is an improvment of the way to get exclusive access to a database by switching to single_user mode instead to offline. Using offline mode proved to be less reliable since latest SQL Server version, since going offline was blocked sometimes by SQL internal processes.
