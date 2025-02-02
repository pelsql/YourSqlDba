# YourSqlDba

**To get the script of the most recent release of YourSqlDba** - **_Go to [Version History](#version-history) to get a specific script version and see details about changes between versions._**

>To display **currently installed release of YourSqlDba**, execute this query:<br/> **select * from Install.VersionInfo()**

**Everything about YourSqlDba** can be found at **[Links into Online Documentation](#Links-into-Online-Documentation)**


>*[YourSQLDba_InstallOrUpdateScript](YourSQLDba_InstallOrUpdateScript.sql?raw=true)* is essentially a comprehensive T-SQL script designed to simplify and automate database maintenance for SQL Server. When executed, it creates (or update) a database named YourSqlDba on the SQL instance where it is run. This database is packed with T-SQL modules, including functions, stored procedures, and views. While you don’t need to worry about understanding every module, some of them can serve as valuable tools for exceptional day-to-day DBA tasks beyond regular maintenance. 

### Links into Online Documentation

The **[online documentation](https://onedrive.live.com/view.aspx?resid=12C385255443C4ED!7080&migratedtospo=true&redeem=aHR0cHM6Ly8xZHJ2Lm1zL28vYy8xMmMzODUyNTU0NDNjNGVkL0V1M0VRMVFsaGNNZ2dCS29Hd0FBQUFBQlJ2b290QVJmaE5LQjJaenNPU09yZkE_ZT01OjRmYWJlNDFlYzdiZTQxYTM4ZWY1NjQ0ZjhlMDdhYmIxJnNoYXJpbmd2Mj10cnVlJmZyb21TaGFyZT10cnVlJmF0PTk&wd=target%28Introduction.one%7Cc7014943-14b8-4c1d-9ae7-429002e0759c%2FGoals%7Ce133a6f3-2280-42c9-bef3-26c877c23c5d%2F%29&wdorigin=703)** is in the form of a web Microsoft OneNote. No other software than your browser is required to read it (but be patient for initial loading). It includes many sections, but only a few need to be mastered.

>**[Quick start](https://onedrive.live.com/view.aspx?resid=12C385255443C4ED!7080&migratedtospo=true&redeem=aHR0cHM6Ly8xZHJ2Lm1zL28vYy8xMmMzODUyNTU0NDNjNGVkL0V1M0VRMVFsaGNNZ2dCS29Hd0FBQUFBQlJ2b290QVJmaE5LQjJaenNPU09yZkE_ZT01OjRmYWJlNDFlYzdiZTQxYTM4ZWY1NjQ0ZjhlMDdhYmIxJnNoYXJpbmd2Mj10cnVlJmZyb21TaGFyZT10cnVlJmF0PTk&wd=target%28Introduction.one%7Cc7014943-14b8-4c1d-9ae7-429002e0759c%2FQuick%20Start%20%20download%7C7baefd6f-3103-45b4-899f-8c9f4be9e119%2F%29&wdorigin=703)**  This page explains what YourSqlDba is about does and how it works. First step is to run YourSQLDba_InstallOrUpdateScript.sql.  
You can have it at [Version History](#Version-History).   
Next step is to perform  **[Initial Setup of YourSqlDba](https://onedrive.live.com/view.aspx?resid=12C385255443C4ED!7080&migratedtospo=true&redeem=aHR0cHM6Ly8xZHJ2Lm1zL28vYy8xMmMzODUyNTU0NDNjNGVkL0V1M0VRMVFsaGNNZ2dCS29Hd0FBQUFBQlJ2b290QVJmaE5LQjJaenNPU09yZkE_ZT01OjRmYWJlNDFlYzdiZTQxYTM4ZWY1NjQ0ZjhlMDdhYmIxJnNoYXJpbmd2Mj10cnVlJmZyb21TaGFyZT10cnVlJmF0PTk&wd=target%28Initial%20Setup%20or%20Upgrade.one%7Cb3c8c1f9-cd98-47ec-a339-9e14522d31a5%2FInitial%20setup%7C8b51ac78-79a3-41c0-b29b-329f8ba5d372%2F%29&wdorigin=703)** if it is your first YourSqlDba install on a SQL Server.

### **[Install.InitialSetupOfYourSQLDba](https://onedrive.live.com/view.aspx?resid=12C385255443C4ED!7080&migratedtospo=true&redeem=aHR0cHM6Ly8xZHJ2Lm1zL28vYy8xMmMzODUyNTU0NDNjNGVkL0V1M0VRMVFsaGNNZ2dCS29Hd0FBQUFBQlJ2b290QVJmaE5LQjJaenNPU09yZkE_ZT01OjRmYWJlNDFlYzdiZTQxYTM4ZWY1NjQ0ZjhlMDdhYmIxJnNoYXJpbmd2Mj10cnVlJmZyb21TaGFyZT10cnVlJmF0PTk&wd=target%28REFERENCE.one%7Cc7b30aeb-6ae2-4bd6-a550-14feb11d776d%2FInstall.InitialSetupOfYourSQLDba%7Cab0a67f6-ba01-419d-b111-336b424de5de%2F%29&wdorigin=703)**
>YourSQLDba_InstallOrUpdateScript.sql script creates a database along with its set of SQL modules and tables. It operates exclusively through SQL Agent jobs and Database Mail, both of which must be configured. To simplify this setup, the helper stored procedure *Install.InitialSetupOfYourSQLDba* is provided. This procedure allows you to easily configure Database Mail, specify backup directories, and define some default behaviors. The helper procedure also creates two SQL Agent jobs and schedules them to run as needed. These jobs execute the `Maint.YourSqlDba_DoMaint` stored procedure with different parameters. This stored procedure handles all maintenance actions.
### **[Maint.YourSQLDba_DoMaint](https://onedrive.live.com/view.aspx?resid=12C385255443C4ED!7080&migratedtospo=true&redeem=aHR0cHM6Ly8xZHJ2Lm1zL28vYy8xMmMzODUyNTU0NDNjNGVkL0V1M0VRMVFsaGNNZ2dCS29Hd0FBQUFBQlJ2b290QVJmaE5LQjJaenNPU09yZkE_ZT01OjRmYWJlNDFlYzdiZTQxYTM4ZWY1NjQ0ZjhlMDdhYmIxJnNoYXJpbmd2Mj10cnVlJmZyb21TaGFyZT10cnVlJmF0PTk&wd=target%28REFERENCE.one%7Cc7b30aeb-6ae2-4bd6-a550-14feb11d776d%2FMaint.YourSQLDba_DoMaint%7Cde56c9b2-3548-4c94-a646-ae4139610a99%2F%29&wdorigin=703)** 
>This procedure serves as the main entry point for maintenance in both jobs. Different parameters are set based on the type of job to be executed. The first job, which runs daily, performs comprehensive database optimizations, including updating statistics, reorganizing or rebuilding indexes, and ensuring database integrity. It also creates full backups. Filters allow you to include or exclude databases using multiple wildcard sets, and numerous other parameters enable customization of various behaviors. The second job runs every 15 minutes and is dedicated to backing up transaction logs.
### **[Maint.HistoryView](https://onedrive.live.com/view.aspx?resid=12C385255443C4ED!7080&migratedtospo=true&redeem=aHR0cHM6Ly8xZHJ2Lm1zL28vYy8xMmMzODUyNTU0NDNjNGVkL0V1M0VRMVFsaGNNZ2dCS29Hd0FBQUFBQlJ2b290QVJmaE5LQjJaenNPU09yZkE_ZT01OjRmYWJlNDFlYzdiZTQxYTM4ZWY1NjQ0ZjhlMDdhYmIxJnNoYXJpbmd2Mj10cnVlJmZyb21TaGFyZT10cnVlJmF0PTk&wd=target%28REFERENCE.one%7Cc7b30aeb-6ae2-4bd6-a550-14feb11d776d%2FMaint.HistoryView%20%28V%207.0%5C%29%7C50837514-3e97-4c66-9595-e428fb04087c%2F%29&wdorigin=703)** 
>This function is the primary method by which YourSqlDba generates a query (delivered through an email report) to provide a comprehensive error report in case of issues, detailed insights into job activity, or a complete log of events within a specified time frame (e.g., when multiple jobs run concurrently). It also allows you to filter events using any criteria supported by SQL, as it is fundamentally a query. Since version 7.0, significant emphasis has been placed on enhancing diagnostic capabilities, primarily through this function.
### **[More on diagnostics](https://onedrive.live.com/view.aspx?resid=12C385255443C4ED!7080&migratedtospo=true&redeem=aHR0cHM6Ly8xZHJ2Lm1zL28vYy8xMmMzODUyNTU0NDNjNGVkL0V1M0VRMVFsaGNNZ2dCS29Hd0FBQUFBQlJ2b290QVJmaE5LQjJaenNPU09yZkE_ZT01OjRmYWJlNDFlYzdiZTQxYTM4ZWY1NjQ0ZjhlMDdhYmIxJnNoYXJpbmd2Mj10cnVlJmZyb21TaGFyZT10cnVlJmF0PTk&wd=target%28REFERENCE.one%7Cc7b30aeb-6ae2-4bd6-a550-14feb11d776d%2FDiagnostics%20%28maintenance%2C%20performance%5C%29%7C097c91ad-3afb-422f-b8c0-c76f9131e0a5%2F%29&wdorigin=703)** 
>This section also answer to some normal issues after first install.


### Version history

**[Get script of 7.0.0.5](YourSQLDba_InstallOrUpdateScript.sql?raw=true)**
Interim versions 7.0.0.0 to 7.0.0.4 are discarded. Version 7.0.0.5 is mandatory and encompasses all their changes and address a problem to links with documentation, either in the readme and the index.md which is a short doc page.

Here they are:

Version 7.0.0.1 lays the foundation for elements of a new architecture for YourSqlDba. These elements will be introduced gradually, maintaining parallel elements of both the original and the new architecture.

With version 7.0, several improvements have been added to **[YourSQLDba.Maint.HistoryView](#mainthistoryview)**. To acheive better visualization of multi-job interactions, events within a specified period are ordered by time and include simultaneous job events. Each time the log history switches jobs, a list of columns displaying job pedigree is set, making the switch easily visible

**[YourSQLDba.Maint.HistoryView](#mainthistoryview)** is a crucial tool within the YourSqlDba function for diagnosing maintenance problems. When searching outside the realm of a single jon, pre-computed datetime values from Maint.MaintenanceEnums can be used to query current or past YourSqlDba activity within relative time ranges. For more details, see the updated documentation on **[YourSQLDba.Maint.HistoryView](#mainthistoryview)**. These choices are documented in the message that displays the query to use for querying the SQL executed during the maintenance process.

A piece of code invoking log cleanup has been missing since version 6.8.0.0. It is reintroduced in version 7.0.0.1.

Version 7.0.0.2:
Corrects the message related to issues preventing access to the mirror server. It now includes the possibility that the mirror instance may simply be down.

Version 7.0.0.3:
When upgrading from a previous version, YourSqlDba Maintenance logs appear larger. Migrating them may cause issues with YourSqlDba log size. To address this, cleanup operations are performed before the upgrade. The DELETE statement is broken into multiple smaller statements (using TOP()) to avoid log oversizing.

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
>This version is a significant rewrite of the YourSqlDba logging system, and reporting of code played and exceptions whenever they occur. Previous code evolved to become too complex to maintain. The new logging system relies on a different architecture for logging YourSqlDba actions and errors. It reduced code size, made it more modern with fewer code paths, and easier to follow. It considers that more than one job may run at a time. I changed Maint.HistoryView parameters to starting and ending times of the job. Output also includes other job events that happen in that period. Poor SQL Agent's job history output formatting required new methods to leave a more readable result. What led to this significant review was some deadlock reported in the logging table when doing YourSqlDba mirroring. Solutions brought with version 6.7.3.2 needed a better retrofit of the architecture to make it sounder. I decided it was time to review the whole thing, so it is. A small correction 

**[Get script of 6.7.3.2](https://raw.githubusercontent.com/pelsql/YourSqlDba/9d78b52824110221bb2e9d6314286decbc88f4ab/YourSQLDba_InstallOrUpdateScript.sql)**
>This version has two set of unreleated feature changes. One is an improvment of the way to get exclusive access to a database by switching to single_user mode instead to offline. Using offline mode proved to be less reliable since latest SQL Server version, since going offline was blocked sometimes by SQL internal processes.

>The next modification related to Mirroring.FailOver. It is a follow up for external backups solutions performing directly SQL backups to their datastore and able to do some kind of warm standy server. For example CommVault supports some kind of standy-by server very similar to YourSqlDba "Mirroring" solution. Since CommVault handles also backups and restores, a last sync must be done through CommVault console. Mirroring.Failover cannot attempt to do a last sync because it has no more control on backups. However remaining tasks of Mirroring.FailOver remain valuable (sync of logins, adjusting database owner, updating compatibility level, an recovering database on destination server). A new defaut parameter was than added to let know to Mirroring.Failover if some data sync must be done, and it is set to ON by default. For actual YourSqlDba users, default parameter can be ommitted, so use case remains the same. CommVault users must explicitly put this parameter to off when they want to use Mirroring.Failover to automate remaining failOver tasks without attempts of data synching from the procedure.

>Some other stuff very specific to CommVault direct handling of backups is explained there **(https://onedrive.live.com/view.aspx?resid=12C385255443C4ED!7080&migratedtospo=true&redeem=aHR0cHM6Ly8xZHJ2Lm1zL28vYy8xMmMzODUyNTU0NDNjNGVkL0V1M0VRMVFsaGNNZ2dCS29Hd0FBQUFBQlJ2b290QVJmaE5LQjJaenNPU09yZkE_ZT01OjRmYWJlNDFlYzdiZTQxYTM4ZWY1NjQ0ZjhlMDdhYmIxJnNoYXJpbmd2Mj10cnVlJmZyb21TaGFyZT10cnVlJmF0PTk&wd=target%28External%20backup%20solution%20and%20YourSqlDba.one%7C74432c93-3c8e-4c12-85ca-57184e019ae5%2FCommVault%20example%7Cba9123e9-aecf-49fc-84a3-3b6ec94b3b2d%2F%29&wdorigin=NavigationUrl)**. An helper stored procedure was added to documentation to generate restores from a directory of .Bak files with a naming specific to CommVault. Restoring CommVault backups in the form of on-disk equivalent of Sql backups is an option offered by CommVault. So this helper stored proc is welcomed, as it avoids to write a lot of restore commands (one for each file). This procedure is provided as-is in the documentation, and is not part of YourSqlDba common code. It is pretty well documented and could be used for another similar application.

**[Get script of 6.7.3.1](https://raw.githubusercontent.com/pelsql/YourSqlDba/22844466770e0f898eadc1ec28e7fcb7be10f2e0/YourSQLDba_InstallOrUpdateScript.sql)**
>Fix of 6.7.3.0 (Integrity tests could report an error) 
Introduces as a new feature providing some interoperability with other external backups solutions like CommVault backups. In this case you must modify YourSqlDba jobs by disabling or removing log backups job. Main maintenance parameter needs to be adjusted to not ask for full backups, leaving other maintenance actions, for other optimizations and integrity testing, with the same parameters ;  

>Some minimal setup is needed with CommVault backups jobs (full or logs); You must add for full backups a pre-job and for log backups a post job as instructed in **(https://onedrive.live.com/view.aspx?resid=12C385255443C4ED!7080&migratedtospo=true&redeem=aHR0cHM6Ly8xZHJ2Lm1zL28vYy8xMmMzODUyNTU0NDNjNGVkL0V1M0VRMVFsaGNNZ2dCS29Hd0FBQUFBQlJ2b290QVJmaE5LQjJaenNPU09yZkE_ZT01OjRmYWJlNDFlYzdiZTQxYTM4ZWY1NjQ0ZjhlMDdhYmIxJnNoYXJpbmd2Mj10cnVlJmZyb21TaGFyZT10cnVlJmF0PTk&wd=target%28External%20backup%20solution%20and%20YourSqlDba.one%7C74432c93-3c8e-4c12-85ca-57184e019ae5%2FCommVault%20example%7Cba9123e9-aecf-49fc-84a3-3b6ec94b3b2d%2F%29&wdorigin=NavigationUrl)**. 

>Fix: Incorrect database size computing prevented integrity testing for very large databases on a table by table basis as intended. Now it works as intended. Above 1Tb (VLDB), integrity testing will now go through checktables as expected.  

**[Get script of 6.7.2.0](https://raw.githubusercontent.com/pelsql/YourSqlDba/2e6044f1f37ecdfe9086fcec141efa1d1d82747b/YourSQLDba_InstallOrUpdateScript.sql)**
>In some cases Maint.HistoryView may cause excessive memory grants when handling whole historyDetails source table. A simple solution was to add reporting elements to a resulting Maint.JobHistoryLineDetails report table through a trigger on Maint.JobHistoryDetails. This minimize greatly the amount of data processed at once and simplify very much Maint.HistoryView function

**[Get script of 6.7.1.0](https://raw.githubusercontent.com/pelsql/YourSqlDba/e2d5e941169c3cefbeab4543f8ca8c978b3d400b/YourSQLDba_InstallOrUpdateScript.sql).**
>Integrity testing may be delayed when number of databases selected is lower than parameter @SpreadCheckDb, and also with some other "too long to explain here" reasons. Some improvements were implemented to uniformize processing length for DBCC Checkdb from day to day

**[Get script of 6.7.0.6](https://raw.githubusercontent.com/pelsql/YourSqlDba/0abcc636c9405e0ebefaadd93a71d85c8b7e9479/YourSQLDba_InstallOrUpdateScript.sql).**
>On update or install, enabling Service broker on Msdb seems to hang. Now it is done with rollback immediate option which solves the problem

If you run any of these older versions go straigh to the latest one, with some attention to comments on versions 6.7.0.1, 6.5.9.3, and the ones above. You can also explore all commits or YourSQLDba_InstallOrUpdateScript.sql compare differences.

* 6.7.0.5 - Fix to 6.6.0.1 for DoRestore which needs a @migrationTestMode default value to 0 to make sense when used with Mirroring.FailOver
* 6.7.0.4 - Improvement of Maint.HistoryView to reduce false positive when searching errors
* 6.7.0.3 - Fix to a change in 6.6.0.3 for printing of code, which translated to string truncation error
* 6.7.0.2 - Fix to a change in 6.6.0.3 for DBCC Shrink_Log.  

* 6.7.0.1 - This version add a new feature Maint.HistoryView that deprecate some others and solve a minor update bug
  1) A new function called YourSQLDba.Maint.HistoryView allows inspection of YourSqlDba history in a much more readeable form. It accepts 3 parameters: a job Number, a step number, a flag to filter only reported errors. Email messages are adjusted accordingly. The stored procedures ShowHistory and ShowHistoryError are deprecated.

  2) A minor update bug was deleting job history
  3) A minor bug found when writing Maint.HistoryView. Single line queries having no ending linefeed weren't printed.The printing query function was corrected.

* 6.6.0.3 - This version solve some annoying bugs
  1) When a backup occurs on a given database, and the log backups job attempts a log shrink at the same time
     the log of the same database, an error will be thrown for the Shrink log operation. This problem is solved by the mean
     of application lock which signals that a backup operation is ongoing, so YourSqlDba log backups has a mean to knows 
     when to defer the shrink operation.
  2) Two minor fix were done on Install.InitialSetupOfYourSqlDba. The email setup could be done improperly if another email
     profile already exists, and the test message sent to test mail setup was not properly sent.
  3) In yMirroring.MirrorLoginSync, when a login must be recreated, and the default language is not set, the 
     create login command becomes null, returning an error. In a such context the option is simply removed.

* 6.6.0.1 -  This version implement a new parameter for mirroring called @migrationTestMode.
  1) It's goal is just to set mirroring as a simple mean to backup/restore to another server
  e.g. when migrating to a newer SQL version. In that mode, only full backups are restored to remote server, and put online
  While they exist and are online, YourSqlDba do not attempt another restore of any kind.  
  To restore normal YourSqlDba mirroring, just remove the @migrationTestMode=1 parameter and suppress 
  test databases on target server.

  2) In another field, Install.InitialSetupOfYourSqlDba was improved to send a email on successful install.  
  If this email reach its destination, it proves that email configuration is ok.

* 6.5.9.4 - Specify default value for backup encryption parameters for SaveDbOnNewFileSet.
* 6.5.9.3 - Many improvements related to security and very large databases handling (1TB and more). 
  1) Support of backup encryption (and a minor bug correction related to getting backup information to allow it)
  2) Instead of full checkdb, spreading checktables across the  week
  3) Increase of  fragmentation thresold for database reorganizaton and rebuild
  4) Adjusting of backup parameters for increased performance.
* 6.5.9.2 - Minor bug fix synchronizing local windows user login
* 6.5.9.1 - Improvement about Sync logins 
* 6.5.8.1 - Optimization of database index defrag
* 6.5.8.0 - Exclude case sensitive database from YourSqlDba maintenace with reporting an error
* 6.5.7.9 - Take into account possible invalid dbownership on some databases (handled properly in YourSqlDba) 
* 6.5.7.8 - Improved parameter validation of parameters starting by "@Replace..." in mirroring feature  
* 6.5.7.7 - At failover Restore database ownership after database recovery on mirror server  
* 6.5.7.6 - Correction to improper test of database status   
* 6.5.7.5 - Correction to error message for SetYourSqlDbaAccount
