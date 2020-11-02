set NOCOUNT on

declare @dbname nvarchar(256)
declare @iDBsToLoop int
declare @iTblsToLoop int
declare @cmdIDX varchar(max)
declare @cmdTBL varchar(max)
declare @TableName nvarchar(256)

create table ##TablesToProcessT2 (
	[i] [int] identity(1,1)
	,[TableName] [nvarchar](256)
	,[Processing] [int]
	,[Completed] [bit]
)

SET @iDBsToLoop = (select  min(i) as i from ##DBsToProcess where processing = 0 and completed = 0)

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
			truncate table ##TablesToProcessT2
			insert into ##TablesToProcessT2
			SELECT
			''['' + IST.TABLE_SCHEMA + ''].['' + IST.TABLE_NAME + '']'' AS [TableName],
			0 as Processing,
			0 as Completed	
			FROM INFORMATION_SCHEMA.TABLES IST
			WHERE IST.TABLE_TYPE = ''BASE TABLE''
			')
			exec (@cmdTBL)

			set @iTblsToLoop = (select min(i) as i from ##TablesToProcessT2 where processing = 0 and completed = 0)

			while @iTblsToLoop <= (select max(i) from ##TablesToProcessT2)
				begin

					set @TableName = (select TableName from ##TablesToProcessT2 where i = @iTblsToLoop and processing = 0 and completed = 0)
					
					update ##TablesToProcessT2
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
					--print @cmdIDX
					exec (@cmdIDX)
	
					update ##TablesToProcessT2
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

drop table ##TablesToProcessT2