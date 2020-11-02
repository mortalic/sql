SET FMTONLY OFF
SET NOCOUNT ON
declare @count int
declare @cmd nvarchar(max)
declare @db nvarchar(max)
declare @work_to_do table (
i int identity(1,1),
DBtoUpdate nvarchar(max)
)

insert into @work_to_do
SELECT [name]  
FROM sys.databases 
WHERE database_id > 4
and state_desc = 'ONLINE'

SET @count = 1

create table ##Results 
(
Servername varchar(128)
,runtime datetime
,Databasename nvarchar(128)
,DatabaseID int
,Avg_Estimated_Impact float
,Last_User_Seek datetime
,TableName nvarchar(256)
,Create_Statement nvarchar(max)
)

while @count <= (Select MAX(i) From @work_to_do)  
begin

set @db = (select DBtoUpdate from @work_to_do where i = @count)

set @cmd = ('
use ['+ @db +']
insert into ##Results
SELECT
(select @@servername) as Servername,
(select getdate()) as Runtime,
(select db_name()) as Databasename,
dm_mid.database_id AS DatabaseID,
dm_migs.avg_user_impact*(dm_migs.user_seeks+dm_migs.user_scans) Avg_Estimated_Impact,
dm_migs.last_user_seek AS Last_User_Seek,
OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id) AS [TableName],
''CREATE INDEX [IX_'' + OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id) + ''_''
+ REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.equality_columns,''''),'', '',''_''),''['',''''),'']'','''') +
CASE
WHEN dm_mid.equality_columns IS NOT NULL AND dm_mid.inequality_columns IS NOT NULL THEN ''_''
ELSE ''''
END
+ REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.inequality_columns,''''),'', '',''_''),''['',''''),'']'','''')
+ '']''
+ '' ON '' + dm_mid.statement
+ '' ('' + ISNULL (dm_mid.equality_columns,'''')
+ CASE WHEN dm_mid.equality_columns IS NOT NULL AND dm_mid.inequality_columns IS NOT NULL THEN '','' ELSE
'''' END
+ ISNULL (dm_mid.inequality_columns, '''')
+ '')''
+ ISNULL ('' INCLUDE ('' + dm_mid.included_columns + '')'', '''') AS Create_Statement
FROM sys.dm_db_missing_index_groups dm_mig
INNER JOIN sys.dm_db_missing_index_group_stats dm_migs
ON dm_migs.group_handle = dm_mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details dm_mid
ON dm_mig.index_handle = dm_mid.index_handle
WHERE dm_mid.database_ID = DB_ID()
')
print @cmd
exec (@cmd)

SET @count = @count +1
end
select * from ##Results
drop table ##results