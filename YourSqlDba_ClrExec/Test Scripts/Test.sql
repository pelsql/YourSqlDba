--set nocount on
--declare @cmd nvarchar(max) = 
--'
----raiserror (''test'',9,1);
----Backup database model to disk = ''c:\isql2008r2\DBBACKUPS\test.bak'' with init;
--Backup database model to disk = ''z:\isql2008r2\DBBACKUPS\test.bak'' with init
--'
--declare @s int, @m nvarchar(max)
--exec yExecNLog.ExecAndLogAllMsgs @cmd, @s output, @m output;
--select cast(@m as XML) as message into #tabView
--Select * from #tabView
--print 'Severitymax:'+convert(nvarchar,@s);
--drop table #tabView


--go
DECLARE @SqlCmd nvarchar(max)
DECLARE @MaxSeverity int
DECLARE @Msgs nvarchar(max)

---- TODO: Set parameter values here
--create table #MustLogBackupToShrink (i int);
--EXECUTE [YourSQLDba].[yExecNLog].[Clr_ExecAndLogAllMsgs] 
--'
--set nocount on 
--declare @MustLogBackupToShrink int
--Exec yMaint.ShrinkLog  @Db = ''AdminQuotasSQLGRICS'', @JobNo=46471, @MustLogBackupToShrink = @MustLogBackupToShrink  output
--truncate table #MustLogBackupToShrink 
--insert into #MustLogBackupToShrink Values(@MustLogBackupToShrink)
--'
--  ,@MaxSeverity OUTPUT
--  ,@Msgs OUTPUT

--select @MaxSeverity 
--select @Msgs


EXECUTE [YourSQLDba].[yExecNLog].[Clr_ExecAndLogAllMsgs] 
   'dbcc checkdb(''Corrupt2008DemoFatalCorruption2'')'
  ,@MaxSeverity OUTPUT
  ,@Msgs OUTPUT

select @MaxSeverity 
select @Msgs

