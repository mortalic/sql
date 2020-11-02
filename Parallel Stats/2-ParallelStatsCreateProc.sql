USE [DBA]
GO

/****** Object:  StoredProcedure [dbo].[ParallelStatistics]    Script Date: 5/11/2016 10:18:02 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[ParallelStatistics](
@dbname nvarchar(256) = ''
)

as
/*
For this version to work, you must be running sql server 2014 cu6 or greater and have traceflag 7471 enabled.
To be more specific, this will work on older versions however it will block itself in very slow non performant ways if you aren't running the above.
*/

declare @count int
declare @cmd varchar(500)
declare @db varchar(500)

--These variables are for the ProcessLog
declare @Servername varchar(256)
declare @Runtime datetime
declare @Object varchar(256)
declare @Error bigint
declare @Message nvarchar(max)

--Instantiante the variables
SET @count = 1
--set @databasename = (select db_name())
if @dbname = ''
set @db = (select db_name())
else set @db = @dbname

--Begin the while loop
--Set the count limit
while @count <= (Select MAX(i) From DBA..ParallelStatsTasks)  
begin
set @db = (select Databasename from DBA..ParallelStatsTasks where i = @count)

--if ((select processing from DBA..ParallelStatsTasks where i = @count) = 0) and ((select completed from DBA..ParallelStatsTasks where i = @count) = 0)
if (select completed from DBA..ParallelStatsTasks where i = @count) = 0

begin
update DBA..ParallelStatsTasks
set Processing = Processing + 1
where i = @count

set @cmd = 'use [' + @DB +']'+ CHAR(13) + 'EXEC sp_updatestats' + CHAR(13)  
print @cmd
exec (@cmd)

update DBA..ParallelStatsTasks
set 
Completed = 1,
Processing = Processing - 1
where i = @count
end

SET @count = @count +1
end



GO


