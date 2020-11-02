--Check to see if all databases are marked as completed givup after 2 hours.

while (select distinct completed from ##ParallelStatsTasks where completed <> 0) <> 1 OR @giveup = 60
begin

waitfor delay '00:01:00'
set @giveup = @giveup + 1

end

drop table ##ParallelStatsTasks

DBCC TRACEOFF(7471,-1)