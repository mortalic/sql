create table ##ParallelStatsTasks (
[i] [int] IDENTITY(1,1) NOT NULL,
[Databasename] [varchar](128) NOT NULL,
[LastUpdate] [smalldatetime] NOT NULL,
[Processing] [int] NOT NULL,
[Completed] [bit] NOT NULL
)

insert into ##ParallelStatsTasks
select 
[name], 
cast(getdate() as smalldatetime),	--Set their process time
0 as Processing,					--Set their processing bit to 0
0 as Completed						--Set their completed bit to 0
from sys.databases d
LEFT JOIN sys.dm_hadr_database_replica_states rs
ON d.database_id = rs.database_id
where 
d.name <> 'tempdb'
and d.state_desc NOT IN ('RESTORING', 'OFFLINE')
AND (rs.is_local = 0 OR rs.is_local IS NULL)

--drop table ##ParallelStatsTasks