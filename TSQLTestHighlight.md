
|Commentaire|Exemple de code|
|-----------|---------------|
|Ex.1       | pas trop fort |

|  Parameter name   | Parameter description                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
|:-----------------:|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|       @oper       | SQL Server Agent Operator.  Any valid operator name is allowed.   By default 'YourSQLDba_Operator'.  (nvarchar(200))                                                                                                                                                                                                                                                                                                                                                               |
|   @MaintJobName   | nvarchar(200)   SQL Server Agent job name logged into the maintenance history.  Any valid job name is allowed.    By default 'YourSQLDba: DoInteg,DoUpdateStats,DoReorg,Full backups'.  (nvarchar(200))                                                                                                                                                                                                                                                                            |
|     @DoInteg      | When equal to 1 perform Integrity tests on selected databases.   By default 0  (Int)                                                                                                                                                                                                                                                                                                                                                                                               |
|    @DoUpdStats    | When equal to 1 perform Update Statistics on selected databases.   By default 0  (Int)                                                                                                                                                                                                                                                                                                                                                                                             |
|     @DoReorg      | When equal to 1 perform Selective Index Reorganization or Rebuild depending of an internal fragmentation level found on them. When Rebuilding now leave the original FillFactor.  By default 0 (Int)                                                                                                                                                                                                                                                                               |
|     @DoBackup     | When equal to 'F'; full database backups are performed, plus an initial log backup.   When equal to 'L'; log backups are performed.   When equal to 'D' differential backups are done.    In case of log backups, @FullBackupPath and @LogBackupPath are ignored, the value used at last full backup performed by Maint.YourSQLDba_DoMaint or Maint.SaveDbOnNewFileSet, is the one used for log backups.   When an empty string is supplied no backup is performed. (nvarchar(5))  |
| @FullBackupPath   | Location where full database backup files (.Bak) are going to be stored.   (Required parameter).   The UNC format is allowed.     Example A : 'G:\SQL\Backups'  Example B : '\\SQL\Backups'   (nvarchar(512))                                                                                                                                                                                                                                                                      |



| Command | Description |
| :---: | --- |
| `git status avec plus d'une ligne` | List all *new or modified* files |
| `git diff`   `git add` | Show file differences that **haven't been** staged    changement de ligne|
```TSQL
insert into S#.ScriptToRun (Sql, seq)
select
  code 
, row_number() Over (order by nomTABLE) 
from
  (select * from Sys.tables where name like '%ELE%') as T
  CROSS APPLY (Select nomtable=QSN From S#.InferObjectNamings(object_id, null)) as N
  CROSS APPLY
  (
  Select dbDest='GpiBak', DbSrc='Gpi', i.IdentityOn, i.IdentityOff, i.DropIndexes, i.CreateIndexes, i.ValidInsertCols,I.FullTbName
  From S#.tableInfo(nomtable) as I
  ) as Prm

  -- la partie intéressante...
  Cross Apply (Select J=(Select Prm.* For JSON PATH, Include_null_Values)) as J
  CROSS APPLY S#.GetTemplateFromCmtAndReplaceTags ('===Importer===', null, J) as R

/*===Importer===
Use [#dbDest#]
#DropIndexes#
#IdentityOn#
Truncate Table #FullTbName#
Insert into #FullTbName# (#ValidInsertCols#)
Select #ValidInsertCols#
From [#dbSrc#].#FullTbName#
#IdentityOff#
#CreateIndexes#
===Importer===*/
Exec S#.Runscript @printOnly=1
```
