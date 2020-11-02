--Create a table for the outdated statistics
CREATE TABLE #Outdated_statistics
([Tablename] sysname,
[Indexname] sysname,
[Lastupdated] datetime NULL,
[Rowsmodified] int NULL)


--Get the list of outdated statistics
INSERT INTO #Outdated_statistics
SELECT OBJECT_NAME(id),name,STATS_DATE(id, indid),rowmodctr
FROM sys.sysindexes
WHERE STATS_DATE(id, indid)<=DATEADD(DAY,-1,GETDATE()) 
AND rowmodctr>0 
AND id IN (SELECT object_id FROM sys.tables)


select * from #Outdated_statistics
order by lastupdated desc
drop table #Outdated_statistics