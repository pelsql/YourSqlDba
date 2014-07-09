declare @jobno int; select top 1 @jobno = jobno from maint.JobHistory order by jobno desc
delete  from maint.JobHistory where jobno < @jobno
exec yoursqldba.maint.Showhistory
exec yoursqldba.maint.ShowHistoryErrors 
