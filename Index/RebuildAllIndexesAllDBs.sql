declare @dbname nvarchar(256)
declare @i int
declare @inneri int
declare @cmd nvarchar(1000)
declare @TableName nvarchar(256)

create table ##DBsToModify (
i int identity(1,1),
dbname nvarchar(256)
)

create table ##TablesToRebuild (
i int identity(1,1),
TableName nvarchar(256)
)

insert into ##DBsToModify
select 
name 
from sys.databases 
where name NOT IN ('tempdb')

set @i = 1
set @inneri = 1

while @i <= (select max(i) from ##DBsToModify)
begin

set @dbname = (select dbname from ##DBsToModify where i = @i)

set @cmd =('
use [' + @dbname + ']
insert into ##TablesToRebuild
SELECT
''['' + IST.TABLE_SCHEMA + ''].['' + IST.TABLE_NAME + '']'' AS [TableName]
FROM INFORMATION_SCHEMA.TABLES IST
WHERE IST.TABLE_TYPE = ''BASE TABLE''
')
--print @cmd
exec (@cmd)

	while @inneri <= (select max(i) from ##TablesToRebuild)
	begin

	set @TableName = (select TableName from ##TablesToRebuild where i = @inneri)

	set @cmd = ('
	use [' + @dbname + ']
	SET QUOTED_IDENTIFIER ON
	Begin Try
		PRINT(''Rebuilding indexes on table ' + @TableName +' .'')
		EXEC(''ALTER INDEX ALL ON ' + @TableName + ' REBUILD with (ONLINE=ON)'')
	End Try
 
	Begin Catch
		PRINT(''Cannot do rebuild with Online=On option, taking table ' + @TableName+' down for rebuild. May cause blocking during this process.'')
		EXEC(''ALTER INDEX ALL ON ' + @TableName + ' REBUILD'')
	End Catch

	')
	--print @cmd
	exec (@cmd)
	set @inneri = @inneri + 1
	end

set @i = @i + 1
end

drop table ##TablesToRebuild
drop table ##DBsToModify