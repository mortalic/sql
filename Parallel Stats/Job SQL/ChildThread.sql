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


GO


