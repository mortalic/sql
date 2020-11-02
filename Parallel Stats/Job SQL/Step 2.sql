USE [master]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

declare @count int
declare @cmd varchar(500)
declare @db varchar(256)
declare @dbname varchar(256)
declare @giveup int

--Instantiante the variables
SET @count = 1

if @dbname = ''
set @db = (select db_name())
else set @db = @dbname

--Set the traceflag to minimize lock contention
DBCC TRACEON(7471,-1)

--Begin the while loop
--Set the count limit
while @count <= (Select MAX(i) From ##ParallelStatsTasks)  
begin
set @db = (select Databasename from ##ParallelStatsTasks where i = @count)

if (select completed from ##ParallelStatsTasks where i = @count) = 0

begin
update ##ParallelStatsTasks
set Processing = Processing + 1
where i = @count

set @cmd = 'use [' + @DB +']'+ CHAR(13) + 'EXEC sp_updatestats' + CHAR(13)  
print @cmd
exec (@cmd)

update ##ParallelStatsTasks
set 
Completed = 1,
Processing = Processing - 1
where i = @count
end

SET @count = @count +1
end

--Check to see if all databases are marked as completed and giveup after 2 hours.

while (select distinct completed from ##ParallelStatsTasks where completed <> 0) <> 1 OR @giveup = 60
begin

waitfor delay '00:01:00'
set @giveup = @giveup + 1

end

drop table ##ParallelStatsTasks

DBCC TRACEOFF(7471,-1)

GO


