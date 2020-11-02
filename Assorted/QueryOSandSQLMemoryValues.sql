--This query obtains the OS memory and the sql IN USE values.  Change the value_in_use column if you want the configured value.

declare @OsMemoryMB varchar(500)
declare @sqlMinMemoryMB varchar(500)
declare @sqlMaxMemoryMB varchar(500)
declare @OsPercentRemaining int

set @OsMemoryMB = (select convert(varchar(500),(total_physical_memory_kb /1024)) as TotalOSMemoryInMB from sys.dm_os_sys_memory)
set @sqlMinMemoryMB = (SELECT convert(varchar(500),value_in_use) FROM sys.configurations WHERE name like '%min server memory%')
set @sqlMaxMemoryMB = (SELECT convert(varchar(500), value_in_use) FROM sys.configurations WHERE name like '%max server memory%')
set @osPercentRemaining = abs((convert(float,@sqlMaxMemoryMB)) / (convert(float,@OsMemoryMB)) * 100 -100)

select 
@OsMemoryMB as OSMemoryMB
,@sqlMinMemoryMB as SQLMinMemoryMB 
,@sqlMaxMemoryMB as SQLMaxMemoryMB
,@OsPercentRemaining as OSPercentRemaining
