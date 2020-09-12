# YourSqlDba

Recent releases of YourSqlDba - [Lastest release here](YourSQLDba_InstallOrUpdateScript.sql?raw=true)
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

YourSqlDb is just a very big T-SQL script that helps a lot in automating database maintenance. 

[YourSqlDba Online Documentation](https://pelsql.github.io/YourSqlDba/) gives excellent overview of what YourSqlDba is all about.

An alternate, always up-to-date documentation is available through this [YourSqlDba One Note Online documentation](https://1drv.ms/u/s!Au3EQ1QlhcMStyhzaj33LkcvNzcw?e=cBk5t1).

YourSqlDba script creates a database named YourSqlDba packed with T-SQL modules (function, stored procedures, and views) on the server where it is run. You don't need to be concerned by all of them, albeit some of them are interesting tools for exceptional day-to-day DBA tasks, out of regular maintenance tasks.

YourSqlDba [Quick start](https://pelsql.github.io/YourSqlDba/#quickstart-section) introduction explains how it works.  

YourSqlDba builds on SQL Agent and database mail, to schedule maintenance and reports how it goes everyday. 
The stored procedure [Install.InitialSetupOfYourSQLDba](https://pelsql.github.io/YourSqlDba/#InitialSetupOfYourSQLDba) provides the necessary parameters to set up database mail, backup directories, and some default behaviors. 

Mail parameters go to Database mail *YourSQLDba_EmailProfile* and other maintenance parameters appears as parameters of in two SQL Agent Jobs which call two T-SQL mainteance steps. 
In each of this maintenance step there is a call to [Maint.YourSQLDba_DoMaint](https://pelsql.github.io/YourSqlDba/#YourSQLDba_DoMaint) stored procedure. Its parameters reflect some of the [Install.InitialSetupOfYourSQLDba](https://pelsql.github.io/YourSqlDba/#InitialSetupOfYourSQLDba) parameters value, and many are by default.  [Maint.YourSQLDba_DoMaint](https://pelsql.github.io/YourSqlDba/#YourSQLDba_DoMaint) parameters are explained in detail in YourSqlDba online documentation.
