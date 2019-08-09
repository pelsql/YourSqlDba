# YourSqlDba

YourSqlDb is just a very big T-SQL script that helps a lot in automating database maintenance. 

[YourSqlDba Online Documentation](https://pelsql.github.io/YourSqlDba/) gives excellent overview of what YourSqlDba is all about.

An alternate, always up-to-date documentation is available through this [YourSqlDba One Note Online documentation](https://1drv.ms/u/s!Au3EQ1QlhcMStyhzaj33LkcvNzcw?e=cBk5t1).

YourSqlDba script creates a database named YourSqlDba packed with T-SQL modules (function, stored procedures, and views) on the server where it is run. You don't need to be concerned by all of them, albeit some of them are interesting tools for exceptional day-to-day DBA tasks, out of regular maintenance tasks.

YourSqlDba [Quick start](https://pelsql.github.io/YourSqlDba/#quickstart-section) introduction explains how it works.  

YourSqlDba builds on SQL Agent and database mail, to schedule maintenance and reports how it goes everyday. 
The stored procedure [Install.InitialSetupOfYourSQLDba](https://pelsql.github.io/YourSqlDba/#InitialSetupOfYourSQLDba) provides the necessary parameters to set up database mail, backup directories, and some default behaviors. 

Mail parameters go to Database mail *YourSQLDba_EmailProfile* and other maintenance parameters appears as parameters of in two SQL Agent Jobs which call two T-SQL mainteance steps. 
In each of this maintenance step there is a call to [Maint.YourSQLDba_DoMaint](https://pelsql.github.io/YourSqlDba/#YourSQLDba_DoMaint) stored procedure. Its parameters reflect some of the [Install.InitialSetupOfYourSQLDba](https://pelsql.github.io/YourSqlDba/#InitialSetupOfYourSQLDba) parameters value, and many are by default.  [Maint.YourSQLDba_DoMaint](https://pelsql.github.io/YourSqlDba/#YourSQLDba_DoMaint) parameters are explained in detail in YourSqlDba online documentation.
