use yoursqldba; 
go
-- Le déploiment ne se fait pas sous le bon nom de procédure, je corrige ça ici
-- je recrée l'assembly, et la procédure au bon endroit
Print '******************** Execution de PostDeplyScript écrit par Maurice, voir explorateur de solution *************************************'
Print ' Par défaut Le déploiement de VS met les objets sous dbo.  On les déplace vers le schema de notre choix '
declare @sql nvarchar(max);
With InfoModuleAssemblies
as
(
select 
  OBJECT_SCHEMA_NAME(m.object_id) as NomSchema
, OBJECT_NAME(m.object_id) as nomObj
, A.name as NomModule
from 
  sys.assembly_modules M
  join 
  sys.assemblies A
  On A.assembly_id = M.assembly_id 
)
Select @sql =
(
Select convert(nvarchar(max), '') +'ALTER SCHEMA yUtl TRANSFER '+I.NomSchema+'.'+I.nomObj+';'+NCHAR(10) as [text()]
from InfoModuleAssemblies I
Where NomModule = 'YourSqlDba_ClrFileOp'
For XML PATH('')
)
print 'Requête exécutée ' + isnull(@sql, ' erreur chaîne vide ')
exec (@sql)
Print 'Contournement à l''avertissement que le deploy de Visual Studio dit quand il dit que cette procédure est supprimée et pas recréée'
Print '******************** Fin Execution de PostDeplyScript écrit par Maurice, voir explorateur de solution *************************************'
