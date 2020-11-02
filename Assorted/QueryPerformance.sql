SELECT TOP 10
@@SERVERNAME as Servername
,convert(smalldatetime,getdate()) as Runtime
,(total_logical_reads/execution_count) AS avg_logical_reads
,(total_logical_writes/execution_count) AS avg_logical_writes
,(total_physical_reads/execution_count) AS avg_phys_reads
,(total_worker_time/execution_count) AS avg_cpu_over_head
,total_logical_reads
,total_logical_writes
,total_physical_reads
,total_worker_time
,execution_count
,total_elapsed_time AS Duration
,plan_generation_num AS num_recompiles
,statement_start_offset AS stmt_start_offset
,(select name from sys.databases where database_id = (SELECT dbid FROM sys.dm_exec_query_plan(plan_handle))) AS DatabaseID
,(SELECT SUBSTRING(text, statement_start_offset/2 + 1,
        (CASE WHEN statement_end_offset = -1
            THEN LEN(CONVERT(nvarchar(MAX),text)) * 2
                ELSE statement_end_offset
            END - statement_start_offset)/2)
     FROM sys.dm_exec_sql_text(sql_handle)) AS query_text
,(SELECT query_plan FROM sys.dm_exec_query_plan(plan_handle)) AS query_plan
FROM sys.dm_exec_query_stats a
--JUST CHANGE THE ORDER BY TO GET THE OTHER RESOURCES
ORDER BY (total_logical_reads + total_logical_writes)/execution_count DESC