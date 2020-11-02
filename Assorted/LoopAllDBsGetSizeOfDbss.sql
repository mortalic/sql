declare @count int
declare @cmd nvarchar(max)
declare @db nvarchar(max)
declare @work_to_do table (
i int identity(1,1),
DBtoUpdate nvarchar(max)
)

insert into @work_to_do
SELECT [name]  
FROM master..sysdatabases 

--Instantiante the count
SET @count = 1

--Begin the while loop
--Set the count limit
while @count <= (Select MAX(i) From @work_to_do)  
begin

--do your acutal work here, left a select in for review only.
--select * from @work_to_do where i = @count 

set @db = (select DBtoUpdate from @work_to_do where i = @count)

set @cmd = 'use [' + @DB +']'+ CHAR(13) + '-- Calculates the size of the database. 
SELECT DB_NAME(database_id) AS DatabaseName,
Name AS Logical_Name,
Physical_Name, (size*8)/1024 SizeMB
FROM sys.master_files
WHERE DB_NAME(database_id) = '+ @db +'
'

print @cmd
exec (@cmd)

--increment count, end loop drop temptable.
SET @count = @count +1
end

