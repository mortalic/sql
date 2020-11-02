/*
This query spits out the default growth values for all databases.

*/
declare @dbname nvarchar(256)
declare @i int
declare @cmd nvarchar(max)

--Global temptable wasn't necessary, but used it for monitoring from other processes.
create table ##DBsToModify (
i int identity(1,1),
dbname nvarchar(256)
)

--Select statement creates the list of databases to be updated. 
--In this case also compares to a specific version of the application
insert into ##DBsToModify
select name from sys.databases d
where database_id > 4

--Instantiate the counter and start the loop
--Be sure to uncomment the actual @cmd var when you want to execute the tsql.
set @i = 1

while @i <= (select max(i) from ##DBsToModify)
begin
set @dbname = (select dbname from ##DBsToModify where i = @i)

set @cmd = ('
use '+ @dbname +'
select name,  fileid, filename,
filegroup = filegroup_name(groupid),
''size'' = convert(nvarchar(15), convert (bigint, size) * 8) + N'' KB'',
''maxsize'' = (case maxsize when -1 then N''Unlimited''
else
convert(nvarchar(15), convert (bigint, maxsize) * 8) + N'' KB'' end),
''growth'' = (case status & 0x100000 when 0x100000 then
convert(nvarchar(15), growth) + N''%''
else
convert(nvarchar(15), convert (bigint, growth) * 8) + N'' KB'' end),
''usage'' = (case status & 0x40 when 0x40 then ''log only'' else ''data only'' end)
from sysfiles
')

print @cmd
exec (@cmd)

set @i = @i + 1
end

drop table ##DBsToModify;