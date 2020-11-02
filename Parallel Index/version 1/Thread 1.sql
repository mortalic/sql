set NOCOUNT on

declare @cmdTBL varchar(max)
declare @dbname nvarchar(256)
declare @iDBsToLoop int
declare @iTblsToLoop int
declare @cmdIDX varchar(max)
declare @TableName nvarchar(256)
declare @giveup smallint

CREATE TABLE ##DBsToProcess(
	[i] [int] IDENTITY(1,1) NOT NULL,
	[dbname] [nvarchar](256) NOT NULL,
	[LastUpdate] [smalldatetime] NOT NULL,
	[Processing] [bit] NOT NULL,
	[Completed] [bit] NOT NULL
) ON [PRIMARY]

create table ##TablesToProcessT1 (
	[i] [int] identity(1,1)
	,[TableName] [nvarchar](256)
	,[Processing] [int]
	,[Completed] [bit]
)

insert into ##DBsToProcess
select
[name], 
cast(getdate() as smalldatetime),	--Set their process time
0 as Processing,					--Set their processing bit to 0
0 as Completed						--Set their completed bit to 0
from sys.databases d
LEFT JOIN sys.dm_hadr_database_replica_states rs
ON d.database_id = rs.database_id
WHERE 
name <> 'tempdb'
AND d.state_desc NOT IN ('RESTORING', 'OFFLINE')
AND (rs.is_local = 0 OR rs.is_local IS NULL)

--Instantiante the db count
SET @iDBsToLoop = 1

while @iDBsToLoop <= (Select MAX(i) From ##DBsToProcess)  

	begin --db loop (outer)

	if ((select processing from ##DBsToProcess where i = @iDBsToLoop) = 0) and ((select completed from ##DBsToProcess where i = @iDBsToLoop) = 0)

		begin --db if
			update ##DBsToProcess
			set Processing = Processing + 1
			where i = @iDBsToLoop

			set @dbname = (select dbname from ##DBsToProcess where i = @iDBsToLoop)

			set @cmdTBL =('
			use ' + @dbname + '
			truncate table ##TablesToProcessT1
			insert into ##TablesToProcessT1
			SELECT
			''['' + IST.TABLE_SCHEMA + ''].['' + IST.TABLE_NAME + '']'' AS [TableName],
			0 as Processing,
			0 as Completed	
			FROM INFORMATION_SCHEMA.TABLES IST
			WHERE IST.TABLE_TYPE = ''BASE TABLE''
			')
			exec (@cmdTBL)

			set @iTblsToLoop = 1

			while @iTblsToLoop <= (select max(i) from ##TablesToProcessT1)
				begin

					set @TableName = (select TableName from ##TablesToProcessT1 where i = @iTblsToLoop and processing = 0 and completed = 0)
					
					update ##TablesToProcessT1
						set processing = processing +1
						where i = @iTblsToLoop

					set @cmdIDX = ('
					use ' + @dbname + '
					Begin Try
						PRINT(''Rebuilding indexes on table ' + @TableName +' .'')
						EXEC(''ALTER INDEX ALL ON ' + @TableName + ' REBUILD with (ONLINE=ON)'')
					End Try
 
					Begin Catch
						PRINT(''Cannot do rebuild with Online=On option, taking table ' + @TableName+' down for rebuild. May cause blocking during this process.'')
						EXEC(''ALTER INDEX ALL ON ' + @TableName + ' REBUILD'')
					End Catch

					')
					exec (@cmdIDX)
	
					update ##TablesToProcessT1
					set Completed = 1
					,processing = processing -1
					where i = @iTblsToLoop

					set @iTblsToLoop = @iTblsToLoop + 1

				end --TBLs loop

	END --db if

	update ##DBsToProcess
	set completed = 1
	where i = @iDBsToLoop

	SET @iDBsToLoop = (select  min(i) as i from ##DBsToProcess where processing = 0 and completed = 0)

END --db loop (outer)
drop table ##TablesToProcessT1

set @giveup = 1 --arrays start at one for trolls
while (select distinct completed from ##DBsToProcess where completed = 0) is not null  or @giveup = 120
	begin 
		waitfor delay '00:01:00' -- 1 minute
		set @giveup = @giveup + 1
	end

drop table ##DBsToProcess
