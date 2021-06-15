# YourSqlDba

Recent releases of YourSqlDba - [Lastest release here](YourSQLDba_InstallOrUpdateScript.sql?raw=true)
See version history below.

YourSqlDba (up-to-date) OneNote Online documentation https://tinyurl.com/YourSqlDba
A prettier documentation crafted by some collaborators is available here online, but its up-to-date status lag behind the one based on the shared OneNote Notebook above that is far easier to maintain. [YourSqlDba Online Documentation](https://pelsql.github.io/YourSqlDba/) gives excellent overview of what YourSqlDba is all about.

YourSqlDba is just a very big T-SQL script that helps a lot in automating database maintenance. 
It creates a database named YourSqlDba packed with T-SQL modules (function, stored procedures, and views) on the server where it is run. You don't need to be concerned by all of them, albeit some of them are interesting tools for exceptional day-to-day DBA tasks, out of regular maintenance tasks.
YourSqlDba main maintenance stored procedure must be launch from SQL Server Agent.

YourSqlDba [Quick start](https://pelsql.github.io/YourSqlDba/#quickstart-section) introduction explains how it works.  

YourSqlDba builds on SQL Agent and database mail, to schedule maintenance and reports how it goes everyday. 
The stored procedure [Install.InitialSetupOfYourSQLDba](https://pelsql.github.io/YourSqlDba/#InitialSetupOfYourSQLDba) provides the necessary parameters to set up database mail, backup directories, and some default behaviors. 

Mail parameters go to Database mail *YourSQLDba_EmailProfile* and other maintenance parameters appears as parameters of in two SQL Agent Jobs which call two T-SQL mainteance steps. 
In each of this maintenance step there is a call to [Maint.YourSQLDba_DoMaint](https://pelsql.github.io/YourSqlDba/#YourSQLDba_DoMaint) stored procedure. Its parameters reflect some of the [Install.InitialSetupOfYourSQLDba](https://pelsql.github.io/YourSqlDba/#InitialSetupOfYourSQLDba) parameters value, and many are by default.  [Maint.YourSQLDba_DoMaint](https://pelsql.github.io/YourSqlDba/#YourSQLDba_DoMaint) parameters are explained in detail in YourSqlDba online documentation.

## Version history:

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

