# **Project Description**
T-SQL Database script that automate database maintenance using SQL Agent an SQL Server DatabaseMail. Perform all maintenance good practices (backups, optimizations and history log management).  Default setup does the job for most configurations, but it still remains very configurable.

**Documentation** of **YourSqlDba** is now in online format.  **Click on the following link** to access **[YourSqlDba Online documentation](https://onedrive.live.com/redir?resid=12C385255443C4ED!7080&authkey=!AHNqPfcuRy83NzA&ithint=onenote%2c)**.

This documentation is in OneNote's notebook web access format on OneDrive.  _For small form factor displays **use the top left icon** to display/hide document navigation_. Documentation can be browsed natively in many browsers and no software licence is required to browse documentation 

## YourSqlDba Tool Overview

This project is essentially a T-SQL script which creates or updates a database that contains a set of SQL objects to automate maintenance. Stored procedure **Install.InitialSetupOfYourSqlDba** creates 2 SQL Agent jobs and their schedules to set automatic maintenance. It also sets a profile and account into SQL Server's Database Mail to be able  to send you  job reports and alerts.  **Install.InitialSetupOfYourSqlDba** need to be run once after initial run of YourSqlDba script, and doesn't need to be re-run on next upgrades.
The first daily job perform general maintenance and the second perform recurrent log backups during the day.

Daily maintenance perform database physical integrity checks, optimizations, and backups.  Some intelligence is put into the maintenance procedure to maintain a reasonable maintenance window, like reorganizing only indexes that needs to be and spreading update statistics on database's tables across a week.  Database log shrinking is automatic when database log size grows beyond a size computed from the sum of combination of ratios of database file sizes.  This avoid frequent log file shrinks, which is not suitable in regard to disk fragmentation, and makes reasonable log management.

Most YourSqlDba behaviors are specified by parameters to allows flexibility for dynamic database selection, backup retention, backup targets, optimizations and other tasks.  This add a great deal of flexibility for more complex database administration scenarios.

The default parameters values provided in setup are good start-up values for those who are not sure how to perform database maintenance.  Put simply, YourSqlDba fits nicely to the type of database management needed given your environment.  In most cases no one is going to have to diverge from default setup to have a complete automatic maintenance solution.  If your actual hardware doesn't cope with reasonable maintenance windows, you probably already have the necessary expertise to customize easily YourSqlDba's jobs and steps parameters.

**YourSqlDba** provides a very easy way to set up a "mirror server" from your backup strategy+.  This feature is analogous to SQL standy server setup, but it automatically includes your dynamically selected backups in that recovery strategy. Using this YourSqlDba's feature, ensures you that you have valid full and log backups, since they are restored immediately to the standby server.  This means that all databases on the stanby server are at most as recent as the last log backup, which is set by default to every 15 minutes.  **This feature is a must because** it checks automatically your backups by restoring them. You must know that many recovery cases failures happen because backups thought valid were not.  This feature let you know if they become corrupt for any reason.

Another great use of YourSqlDba's mirroring is to reduce migration window to few minutes when migrating your databases to an higher version of SQL Server.  Read online documentation to see more details.

A lot of other useful stored procedure utilities come with YourSqlDba to handle complementary database administration.  See **_SP Reference_** section of Online Documentation

