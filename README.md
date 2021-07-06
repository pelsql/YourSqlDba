# YourSqlDba

Recent releases of YourSqlDba - [Lastest release here 6.7.0.6](YourSQLDba_InstallOrUpdateScript.sql?raw=true)
To display installed release of YourSqlDba, execute this query: 
*select * from Install.VersionInfo()*

See version history below.

Everything about YourSqlDba can be found at [Online documentation](https://tinyurl.com/YourSqlDba)

This YourSqlDba [Quick start](https://tinyurl.com/YSDQuickStart) documentation explains how it works.  

YourSqlDba comes alive only through SQL Agent job and Database Mail that need to be configured. An helper stored procedure need to be lauched (see documentation of 
 [Install.InitialSetupOfYourSQLDba](https://tinyurl.com/YSDInitSetup)). This procedure  provides the necessary parameters to set up database mail, backup directories, and some default behaviors. It creates also two SQL Agent Jobs and scheduled them to be launched them as needed.

In each of theses jobs, there is one maintenance step that calls [Maint.YourSQLDba_DoMaint](https://tinyurl.com/YSDDoMaint) stored procedure. Its parameters reflect some of the [Install.InitialSetupOfYourSQLDba](https://tinyurl.com/YSDInitSetup) parameters value, and many are by default.  [Maint.YourSQLDba_DoMaint](https://tinyurl.com/YSDDoMaint) parameters are explained in detail in YourSqlDba online documentation.

YourSqlDba is just a very big T-SQL script that helps a lot in automating database maintenance. 
It creates a database named YourSqlDba packed with T-SQL modules (function, stored procedures, and views) on the server where it is ran. You don't need to be concerned by all of them, albeit some of them are interesting tools for exceptional day-to-day DBA tasks, out of regular maintenance tasks.

## Version history:

* 6.7.0.6 - On update or install, enabling Service broker on Msdb seems to hang. Now it is done with rollback immediate option which solves the problem.
* 6.7.0.5 - Fix to 6.6.0.1 for DoRestore which needs a @migrationTestMode default value to 0 to make sense when used with Mirroring.FailOver
* 6.7.0.4 - Improvement of Maint.HistoryView to reduce false positive when searching errors
* 6.7.0.3 - Fix to a change in 6.6.0.3 for printing of code, which translated to string truncation error
* 6.7.0.2 - Fix to a change in 6.6.0.3 for DBCC Shrink_Log.  

* 6.7.0.1 - This version add a new feature [Maint.HistoryView](https://tinyurl.com/2byndy8d) that deprecate some others and solve a minor update bug
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
