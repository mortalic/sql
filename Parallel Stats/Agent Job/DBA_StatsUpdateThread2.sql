USE [msdb]
GO

/****** 
Object:  Job [DBA_StatsUpdateThread2]    Script Date: 5/30/2017 10:12:23 AM 
Written by Nathan A. Ferguson
******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 5/30/2017 10:12:23 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA_StatsUpdateThread2', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Step 1]    Script Date: 5/30/2017 10:12:23 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Step 1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [master]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

declare @count int
declare @cmd varchar(500)
declare @db varchar(256)
declare @dbname varchar(256)
declare @giveup int

--Instantiante the variables
SET @count = 1

if @dbname = ''''
set @db = (select db_name())
else set @db = @dbname

--Begin the while loop
--Set the count limit
while @count <= (Select MAX(i) From ##ParallelStatsTasks)  
begin
set @db = (select Databasename from ##ParallelStatsTasks where i = @count)

if (select completed from ##ParallelStatsTasks where i = @count) = 0

begin
update ##ParallelStatsTasks
set Processing = Processing + 1
where i = @count

set @cmd = ''use ['' + @DB +'']''+ CHAR(13) + ''EXEC sp_updatestats'' + CHAR(13)  
print @cmd
exec (@cmd)

update ##ParallelStatsTasks
set 
Completed = 1,
Processing = Processing - 1
where i = @count
end

SET @count = @count +1
end


GO


', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20170512, 
		@active_end_date=99991231, 
		@active_start_time=10015, 
		@active_end_time=235959, 
		@schedule_uid=N'a1b616c2-d3bd-4b4e-ae14-aef3d69f54d9'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

