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