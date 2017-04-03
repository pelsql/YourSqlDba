# YourSqlDba

YourSqlDb is just a very big T-SQL script that helps a lot in automating database maintenance. 

[YourSqlDba Online Documentation](https://1drv.ms/o/s!Au3EQ1QlhcMStyhzaj33LkcvNzcw) gives excellent overview of what YourSqlDba is all about.

YourSqlDba script creates a database named YourSqlDba packed with T-SQL modules (function, stored procedures, and views) on the server where it is run. You don't need to be concerned by all of them, albeit some of them are interesting tools for exceptional day-to-day DBA tasks, out of regular maintenance tasks.

YourSqlDba [Quick start](https://onedrive.live.com/edit.aspx?cid=12c385255443c4ed&id=documents&resid=12C385255443C4ED!7080&app=OneNote&&wd=target%28%2F%2FIntroduction.one%7Cc7014943-14b8-4c1d-9ae7-429002e0759c%2FYourSqlDba%20Quick%20Start%7C7baefd6f-3103-45b4-899f-8c9f4be9e119%2F%29) introduction explains how it works.  

YourSqlDba builds on SQL Agent and database mail, to schedule maintenance and reports how it goes everyday. 
The stored procedure [Install.InitialSetupOfYourSQLDba](https://onedrive.live.com/edit.aspx?cid=12c385255443c4ed&id=documents&resid=12C385255443C4ED!7080&app=OneNote&&wd=target%28%2F%2FREFERENCE.one%7C%2FInstall.InitialSetupOfYourSQLDba%7Cab0a67f6-ba01-419d-b111-336b424de5de%2F%29) provides the necessary parameters to set up database mail, backup directories, and some default behaviors. 

Mail parameters go to Database mail *YourSQLDba_EmailProfile* and other maintenance parameters appears as parameters of in two SQL Agent Jobs which call two T-SQL mainteance steps. 
In each of this maintenance step there is a call to [Maint.YourSQLDba_DoMaint](https://onedrive.live.com/edit.aspx?cid=12c385255443c4ed&id=documents&resid=12C385255443C4ED!7080&app=OneNote&&wd=target%28%2F%2FREFERENCE.one%7C%2FMaint.YourSQLDba_DoMaint%7Cde56c9b2-3548-4c94-a646-ae4139610a99%2F%29) stored procedure. Its parameters reflect some of the [Install.InitialSetupOfYourSQLDba](https://onedrive.live.com/edit.aspx?cid=12c385255443c4ed&id=documents&resid=12C385255443C4ED!7080&app=OneNote&&wd=target%28%2F%2FREFERENCE.one%7C%2FInstall.InitialSetupOfYourSQLDba%7Cab0a67f6-ba01-419d-b111-336b424de5de%2F%29) parameters value, and many are by default.  [Maint.YourSQLDba_DoMaint](https://onedrive.live.com/edit.aspx?cid=12c385255443c4ed&id=documents&resid=12C385255443C4ED!7080&app=OneNote&&wd=target%28%2F%2FREFERENCE.one%7C%2FMaint.YourSQLDba_DoMaint%7Cde56c9b2-3548-4c94-a646-ae4139610a99%2F%29) parameters are explained in detail in YourSqlDba online documentation.
