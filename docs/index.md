# YourSqlDba

**YourSqlDba ia a free script that creates tools that automates SQL Server database maintenance.**

For more info about YourSqlDba release goto 

>YourSqlDba comes alive only through SQL Agent job and Database Mail that need to be configured. An helper stored procedure need to be lauched (see documentation of  **[Install.InitialSetupOfYourSQLDba](https://tinyurl.com/YSDInitSetup)**). This procedure  provides the necessary parameters to set up database mail, backup directories, and some default behaviors. It creates also two SQL Agent Jobs and schedules them to be launched them as needed.

**Everything about YourSqlDba** can be found in this **[One-Note Online documentation](https://tinyurl.com/YourSqlDba)**
which doesn't requires no other thing than a browser to navigate. Here is a **[Quick start](https://tinyurl.com/YSDBAQuickStart)** documentation about what YourSqlDba does and how it works.  

>Each jobs has one single maintenance step that. They both runs **[Maint.YourSQLDba_DoMaint](https://tinyurl.com/YSDDoMaint)** stored procedure with different parameters according to the type of job run. Its parameters reflect some of the **[Install.InitialSetupOfYourSQLDba](https://tinyurl.com/YSDInitSetup)** parameters values, and many are by default. **[Maint.YourSQLDba_DoMaint](https://tinyurl.com/YSDDoMaint)** parameters are explained in detail in YourSqlDba online documentation.

>YourSqlDba is finally just a **very big T-SQL script** that helps a lot about installing automating database maintenance for SQL Server. 
It creates, on the SQL instance where it runs, a database named YourSqlDba packed with T-SQL modules (function, stored procedures, and views). You don't need to be concerned by all of them, albeit if some of them are interesting tools for exceptional day-to-day DBA tasks, out of regular maintenance tasks.

