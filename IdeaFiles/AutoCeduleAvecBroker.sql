

USE [master]
GO
IF EXISTS (SELECT * FROM sys.databases WHERE NAME = 'TestScheduledJobs')
	DROP DATABASE TestScheduledJobs 
GO
CREATE DATABASE TestScheduledJobs 
GO
-- set the database to trustworthy and enable service broker in it
ALTER DATABASE TestScheduledJobs SET TRUSTWORTHY ON, ENABLE_BROKER

GO

USE TestScheduledJobs


---------------------------------------------------------------------------------------
< FIRST CREATE dbo.F_ISO_WEEK_OF_YEAR (http://www.sqlteam.com/forums/topic.asp?TOPIC_ID=60510) 
	AND dbo.F_TABLE_DATE HERE (http://www.sqlteam.com/forums/topic.asp?TOPIC_ID=61519) >
---------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
---- CREATE SERVICE BROKER OBJECTS, STORED PROCEDURES AND USER DEFINED FUNCTIONS ----
-------------------------------------------------------------------------------------
GO
IF OBJECT_ID('usp_AddJobSchedule') IS NOT NULL
	DROP PROC usp_AddJobSchedule

GO
CREATE PROC usp_AddJobSchedule
(
	@JobScheduleId INT OUT,
	@RunAtInSecondsFromMidnight INT,
	@FrequencyType INT = 0,
	@Frequency INT = 1,
	@AbsoluteSubFrequency VARCHAR(100) = NULL,
	@MontlyRelativeSubFrequencyWhich INT = NULL, 
	@MontlyRelativeSubFrequencyWhat INT = NULL 		
)
AS
	SELECT @JobScheduleId = -1

	INSERT INTO JobSchedules(FrequencyType, Frequency, AbsoluteSubFrequency, MontlyRelativeSubFrequencyWhich, MontlyRelativeSubFrequencyWhat, RunAtInSecondsFromMidnight)
	SELECT @FrequencyType, @Frequency, @AbsoluteSubFrequency, @MontlyRelativeSubFrequencyWhich, @MontlyRelativeSubFrequencyWhat, @RunAtInSecondsFromMidnight 
	
	SELECT @JobScheduleId = SCOPE_IDENTITY()
GO


IF OBJECT_ID('usp_RemoveJobSchedule') IS NOT NULL
	DROP PROC usp_RemoveJobSchedule

GO
CREATE PROC usp_RemoveJobSchedule
(	
	@JobScheduleId INT
)
AS
	IF EXISTS (SELECT * FROM ScheduledJobs WHERE JobScheduleId = @JobScheduleId)
		RAISERROR ('Job schedule ID %d is used by Scheduled Jobs. Please delete referencing Scheduled jobs before deleting Job Schedule.', 16, 1, @JobScheduleId ); 
		
	DELETE JobSchedules
	WHERE id = @JobScheduleId
	
GO

IF OBJECT_ID('usp_AddScheduledJob') IS NOT NULL
	DROP PROC usp_AddScheduledJob

GO
CREATE PROC usp_AddScheduledJob
(
	@ScheduledJobId INT OUT,
	@JobScheduleId INT = -1,
	@JobName NVARCHAR(256),
	@ValidFrom DATETIME,
	@NextRunOn DATETIME = NULL
	
)
AS
	IF @JobScheduleId > 0 AND @NextRunOn IS NOT NULL 
		RAISERROR ('Job Schedule can NOT be set for "Run Once" job types. "Run Once" job type is indicated by setting parameters @NextRunOn to a future date and @JobScheduleId to -1 (default value).', 16, 1); 
	
	IF @NextRunOn IS NULL 
	-- calculate the next run time from job schedule
	BEGIN		
		SELECT	-- get the valid from start time to calculate from 
				@NextRunOn = CASE WHEN @ValidFrom > GETUTCDATE() THEN @ValidFrom ELSE GETUTCDATE() END, 
				-- get next run time based on our valid from starting time
				@NextRunOn = dbo.GetNextRunTime(@NextRunOn, @JobScheduleId)			
	END
	
	IF @NextRunOn < GETUTCDATE()
		RAISERROR ('@NextRunOn parameter has to be in the future in the UTC date format.', 16, 1); 

	
	INSERT INTO ScheduledJobs(JobScheduleId, JobName, ValidFrom, NextRunOn)
	VALUES (@JobScheduleId, @JobName, @ValidFrom, @NextRunOn)
	
	SELECT @ScheduledJobId = SCOPE_IDENTITY()
GO

IF OBJECT_ID('usp_RemoveScheduledJob') IS NOT NULL
	DROP PROC usp_RemoveScheduledJob

GO
CREATE PROC usp_RemoveScheduledJob
(
	@ScheduledJobId INT
)
AS
	SET xact_abort ON
	BEGIN TRAN
	DELETE FROM ScheduledJobSteps WHERE ScheduledJobId = @ScheduledJobId
	DELETE FROM ScheduledJobs WHERE id = @ScheduledJobId
	COMMIT
GO

IF OBJECT_ID('usp_AddScheduledJobStep') IS NOT NULL
	DROP PROC usp_AddScheduledJobStep

GO
CREATE PROC usp_AddScheduledJobStep
(	
	@ScheduledJobStepId INT OUT,	
	@ScheduledJobId INT, 
	@SqlToRun NVARCHAR(MAX),
	@StepName NVARCHAR(256) = '', 
	@RetryOnFail BIT = 0,
	@RetryOnFailTimes INT = 0 	
)
AS

	INSERT INTO ScheduledJobSteps(ScheduledJobId, StepName, SqlToRun, RetryOnFail, RetryOnFailTimes)
	SELECT @ScheduledJobId, @StepName, @SqlToRun, @RetryOnFail, @RetryOnFailTimes 
	
	SELECT @ScheduledJobStepId = SCOPE_IDENTITY()
GO

IF OBJECT_ID('usp_RemoveScheduledJobStep') IS NOT NULL
	DROP PROC usp_RemoveScheduledJobStep

GO
CREATE PROC usp_RemoveScheduledJobStep
(	
	@ScheduledJobStepId INT
)
AS
	DELETE ScheduledJobSteps
	WHERE id = @ScheduledJobStepId
GO

IF OBJECT_ID('usp_StartScheduledJob') IS NOT NULL
	DROP PROC usp_StartScheduledJob

GO
CREATE PROC usp_StartScheduledJob
(
	@ScheduledJobId INT,	
	@ConversationHandle UNIQUEIDENTIFIER = NULL,
	@ValidFrom DATETIME = NULL
)
AS	
	BEGIN TRY
		IF NOT EXISTS (SELECT * FROM ScheduledJobSteps WHERE ScheduledJobId = @ScheduledJobId)
			RAISERROR ('Scheduled job ID %d has no steps. Job has to have steps to start.', 16, 1, @ScheduledJobId); 
		
		BEGIN TRANSACTION

		-- by passing in new @ValidFrom we can reenable a disabled job		
		IF @ValidFrom IS NOT NULL
		BEGIN
			UPDATE	ScheduledJobs
			SET		ValidFrom = @ValidFrom,
					-- calculate the next run datetime
					NextRunOn = dbo.GetNextRunTime(CASE WHEN @ValidFrom > GETUTCDATE() THEN @ValidFrom ELSE GETUTCDATE() END, JobScheduleId),
					IsEnabled = 0
			WHERE	ID = @ScheduledJobId
		END

		DECLARE @TimeoutInSeconds INT, @NextRunOn DATETIME, @JobScheduleId INT 
				
		SELECT	@ValidFrom = ValidFrom, @NextRunOn = NextRunOn, @JobScheduleId = JobScheduleId
		FROM	ScheduledJobs
		WHERE	ID = @ScheduledJobId AND IsEnabled = 0
		
		IF @@ROWCOUNT = 0
		BEGIN
			IF @@TRANCOUNT > 0
				ROLLBACK;
			RETURN;
		END 
	
		-- for the first call when @ConversationHandle is null. 
		-- this sproc is also called by the usp_RunScheduledJob 
		-- activation stored procedure with @ConversationHandle parameter set 
		-- when setting the job to run on the next scheduled run time time 
		IF @ConversationHandle IS NULL
		BEGIN
			BEGIN DIALOG CONVERSATION @ConversationHandle
				FROM SERVICE   [//ScheduledJobService]
				TO SERVICE      '//ScheduledJobService', 
								'CURRENT DATABASE'
				ON CONTRACT     [//ScheduledJobContract]
				WITH ENCRYPTION = OFF;
		
			UPDATE	ScheduledJobs
			SET		ConversationHandle = @ConversationHandle, 
					IsEnabled = 1
			WHERE	ID = @ScheduledJobId		
		END
	
		-- get next run time in seconds. DATEADD(ms, -DATEPART(ms, GETUTCDATE()), GETUTCDATE()) gets utc without miliseconds
		SELECT @TimeoutInSeconds = DATEDIFF(s, DATEADD(ms, -DATEPART(ms, GETUTCDATE()), GETUTCDATE()), @NextRunOn)

		IF @TimeoutInSeconds <= 0
			RAISERROR ('NextRunOn date for scheduled job ID %d is les than current UTC date.', 16, 1, @ScheduledJobId); 

		BEGIN CONVERSATION TIMER (@ConversationHandle) TIMEOUT = @TimeoutInSeconds;

		-- update the NextRunOn for the job
		UPDATE	ScheduledJobs
		SET		NextRunOn = @NextRunOn				
		WHERE	ID = @ScheduledJobId
				
		IF @@TRANCOUNT > 0
			COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0			
			ROLLBACK;
		
		DECLARE @ErrorMessage NVARCHAR(2048), @ErrorSeverity INT, @ErrorState INT
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()
		
		INSERT INTO SchedulingErrors (ErrorProcedure, ErrorLine, ErrorNumber, ErrorMessage, ErrorSeverity, ErrorState, ScheduledJobId)
		SELECT N'usp_StartScheduledJob', ERROR_LINE(), ERROR_NUMBER(), @ErrorMessage, @ErrorSeverity, @ErrorState, @ScheduledJobId		
		
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH;
GO

GO
IF OBJECT_ID('usp_StopScheduledJob') IS NOT NULL
	DROP PROC usp_StopScheduledJob

GO
CREATE PROC usp_StopScheduledJob
(
	@ScheduledJobId INT
)
AS
	BEGIN TRY
		BEGIN TRAN
		DECLARE @ConversationHandle UNIQUEIDENTIFIER
		
		SELECT	@ConversationHandle = ConversationHandle 
		FROM	ScheduledJobs
		WHERE	ID = @ScheduledJobId AND IsEnabled = 1 AND ConversationHandle IS NOT NULL
		
		IF @@ROWCOUNT = 0
			RAISERROR ('Scheduled job ID %d does NOT exists.', 16, 1, @ScheduledJobId);
		
		IF EXISTS (SELECT * FROM sys.conversation_endpoints WHERE conversation_handle = @ConversationHandle)
			END CONVERSATION @ConversationHandle
		
		UPDATE	ScheduledJobs
		SET		IsEnabled = 0, ConversationHandle = NULL, NextRunOn = NULL
		WHERE	ID = @ScheduledJobId 			
		IF @@TRANCOUNT > 0
			COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0			
			ROLLBACK;

		DECLARE @ErrorMessage NVARCHAR(2048), @ErrorSeverity INT, @ErrorState INT
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()
		
		INSERT INTO SchedulingErrors (ErrorProcedure, ErrorLine, ErrorNumber, ErrorMessage, ErrorSeverity, ErrorState, ScheduledJobId)
		SELECT	N'usp_StopScheduledJob', ERROR_LINE(), ERROR_NUMBER(), @ErrorMessage, @ErrorSeverity, @ErrorState, @ScheduledJobId		
		
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH;
GO

IF OBJECT_ID('usp_RunScheduledJobSteps') IS NOT NULL
	DROP PROC usp_RunScheduledJobSteps

GO
CREATE PROC usp_RunScheduledJobSteps
(
	@ScheduledJobId INT
)
AS
	IF NOT EXISTS (SELECT * FROM ScheduledJobSteps WHERE ScheduledJobId = @ScheduledJobId)
		RAISERROR ('Scheduled job ID %d has NO JOB STEPS.', 16, 1, @ScheduledJobId);
	
	DECLARE @ScheduledJobStepId INT, @SqlToRun NVARCHAR(MAX), @RetryOnFail BIT, @RetryOnFailTimes INT

	DECLARE JobStepsCursor CURSOR LOCAL FAST_FORWARD FOR
	SELECT ID, SqlToRun, RetryOnFail, RetryOnFailTimes 
	FROM ScheduledJobSteps 
	WHERE ScheduledJobId = @ScheduledJobId
	ORDER BY ID

	OPEN JobStepsCursor

	FETCH NEXT FROM JobStepsCursor
	INTO @ScheduledJobStepId, @SqlToRun, @RetryOnFail, @RetryOnFailTimes 

	WHILE @@FETCH_STATUS = 0
	BEGIN
		DECLARE @repeats INT, @startTime DATETIME
		SELECT @repeats = 0
		-- we first run the SQL. of the first run fails it is repeated @RetryOnFailTimes.
		-- so if @RetryOnFailTimes = 3 the the loop and statement will be run 4 times (1st + 3 repeats on fail)
		WHILE @repeats <= @RetryOnFailTimes 
		BEGIN
			BEGIN TRY					
				SELECT @startTime = GETUTCDATE()
				EXEC sp_executesql @SqlToRun
			END TRY
			BEGIN CATCH
				-- save the error report
				INSERT INTO SchedulingErrors (ErrorProcedure, ErrorLine, ErrorNumber, ErrorMessage, ErrorSeverity, ErrorState, ScheduledJobId, ScheduledJobStepId)
				SELECT N'usp_RunScheduledJobSteps', ERROR_LINE(), ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_SEVERITY(), ERROR_STATE(), @ScheduledJobId, @ScheduledJobStepId	
				-- if we don't want to retry on fail then exit loop
				IF @RetryOnFail	= 0
					BREAK;					
			END CATCH;			
			SELECT @repeats = @repeats + 1
		END
		UPDATE ScheduledJobSteps 
		SET DurationInSeconds = DATEDIFF(ms, @startTime, GETUTCDATE())/1000.0,
			FinishedOn = GETUTCDATE()
		WHERE ID = @ScheduledJobStepId
	
		FETCH NEXT FROM JobStepsCursor
		INTO @ScheduledJobStepId, @SqlToRun, @RetryOnFail, @RetryOnFailTimes
	END
	
	CLOSE JobStepsCursor 
	DEALLOCATE JobStepsCursor
GO


IF OBJECT_ID('usp_RunScheduledJob') IS NOT NULL
	DROP PROC usp_RunScheduledJob

GO
CREATE PROC usp_RunScheduledJob
AS
	DECLARE @ConversationHandle UNIQUEIDENTIFIER, 
			@ScheduledJobId INT, @ScheduledJobStepId INT, @JobScheduleId INT, 
			@LastRunOn DATETIME, @NextRunOn DATETIME, @ValidFrom DATETIME
	
	-- we don't need transactions since we don't want to put the job back in the queue if it fails
	-- if that's desired transactions could be added but extra error checking would have to added
	BEGIN TRY
		-- receive only one message from the queue
		;RECEIVE TOP(1) @ConversationHandle = conversation_handle FROM ScheduledJobQueue
	
		-- exit if no message in the queue
		IF @@ROWCOUNT = 0
			RETURN;

		-- get id of the scheduled job associated with the currently received conversation handle
		SELECT	@ScheduledJobId = SJ.ID, @JobScheduleId = JobScheduleId, @ValidFrom = ValidFrom
		FROM	ScheduledJobs SJ
		WHERE	ConversationHandle = @ConversationHandle AND IsEnabled = 1

		IF @@ROWCOUNT = 0
		BEGIN 
			DECLARE @ConversationHandleString VARCHAR(36)
			SELECT @ConversationHandleString = @ConversationHandle 
			RAISERROR ('Scheduled job for conversation handle "%s" does NOT EXISTS or is NOT ENABLED.', 16, 1, @ConversationHandleString);
		END

		-- get the true time the job started executing
		SELECT	@LastRunOn = GETUTCDATE() 
		
		EXEC usp_RunScheduledJobSteps @ScheduledJobId

		IF @JobScheduleId = -1
		BEGIN
			-- if it's "run once" job, stop it
			EXEC usp_StopScheduledJob @ScheduledJobId
			SELECT @NextRunOn = NULL
		END
		ELSE
		BEGIN
			-- else restart the job to the next scheduled date
			EXEC usp_StartScheduledJob @ScheduledJobId, @ConversationHandle

			SELECT	-- get the valid from start time to calculate from 
					@NextRunOn = CASE WHEN @ValidFrom > GETUTCDATE() THEN @ValidFrom ELSE GETUTCDATE() END, 
					-- get next run time based on our valid from starting time
					@NextRunOn = dbo.GetNextRunTime(@NextRunOn, @JobScheduleId)
		END
		-- update the job Last run time.
		UPDATE	ScheduledJobs
		SET		LastRunOn = @LastRunOn,
				NextRunOn = @NextRunOn
		WHERE	ID = @ScheduledJobId		
		
	END TRY
	BEGIN CATCH
		INSERT INTO SchedulingErrors (ErrorProcedure, ErrorLine, ErrorNumber, ErrorMessage, ErrorSeverity, ErrorState, ScheduledJobId, ScheduledJobStepId)
		SELECT N'usp_RunScheduledJob', ERROR_LINE(), ERROR_NUMBER(), ERROR_MESSAGE(), ERROR_SEVERITY(), ERROR_STATE(), @ScheduledJobId, @ScheduledJobStepId	
		
		-- if an error happens end our conversation if it exists
		IF @ScheduledJobId IS NOT NULL
			EXEC usp_StopScheduledJob @ScheduledJobId
	END CATCH;	
GO

IF OBJECT_ID('dbo.GetNextRunTime') IS NOT NULL
	DROP FUNCTION dbo.GetNextRunTime
GO
CREATE FUNCTION dbo.GetNextRunTime(@LastRunTime DATETIME, @JobScheduleId INT)
RETURNS DATETIME
AS
BEGIN
	DECLARE @NextRunTime DATETIME,
			@FrequencyType INT, @Frequency INT, @AbsoluteSubFrequency VARCHAR(100), 
			@MontlyRelativeSubFrequencyWhich INT, @MontlyRelativeSubFrequencyWhat INT, @RunAtInSecondsFromMidnight INT,
			@StartIntervalDate DATETIME, @EndIntervalDate DATETIME,		
			@LastRunTimeDayOfYear INT, @LastRunTimeMonth INT, @LastRunTimeISOWeek INT

	-- get required job schedule data
	SELECT	@FrequencyType = FrequencyType, @Frequency = Frequency, @AbsoluteSubFrequency = AbsoluteSubFrequency, 
			@MontlyRelativeSubFrequencyWhich = MontlyRelativeSubFrequencyWhich, @MontlyRelativeSubFrequencyWhat = MontlyRelativeSubFrequencyWhat, 
			@RunAtInSecondsFromMidnight = RunAtInSecondsFromMidnight 
	FROM	JobSchedules
	WHERE	id = @JobScheduleId

	-- no schedule found so return the input date
	IF @@ROWCOUNT = 0
	BEGIN
		RETURN @LastRunTime;		
	END 

	SELECT	-- set the interval start to the first of the month
			@startIntervalDate = DATEADD(m, DATEDIFF(m, 0, @LastRunTime), 0),
			-- set the interval end to 2 times frequency in months in the future
			@endIntervalDate = DATEADD(m, 2*@Frequency, @startIntervalDate),
			-- get ISO week of the year for the last run time
			@LastRunTimeISOWeek = dbo.F_ISO_WEEK_OF_YEAR(@LastRunTime),
			@LastRunTimeMonth = MONTH(@LastRunTime),
			@LastRunTimeDayOfYear = DATEPART(dy, @LastRunTime)

	-- DAILY SCHEDULE TYPE
	IF @FrequencyType = 1
	BEGIN		
		SELECT	TOP 1 @NextRunTime = DATE
		FROM (
				SELECT	DATEADD(s, @RunAtInSecondsFromMidnight, DATE) AS DATE, ROW_NUMBER() OVER(ORDER BY DATE) - 1 AS CorrectDaySelector
				FROM	dbo.F_TABLE_DATE(@LastRunTime, DATEADD(d, 2*@Frequency, @LastRunTime))
			  ) t
		WHERE	DATE > @LastRunTime
				AND CorrectDaySelector % @Frequency = 0
		ORDER BY DATE
	END
	-- WEEKLY SCHEDULE TYPE
	ELSE IF @FrequencyType = 2
	BEGIN
		SELECT @AbsoluteSubFrequency = ',' + REPLACE(@AbsoluteSubFrequency, ' ', '') + ',' -- add prefix and suffix for correct split

		SELECT	TOP 1 @NextRunTime = DATEADD(s, @RunAtInSecondsFromMidnight, DT.DATE)
		FROM	dbo.F_TABLE_DATE(@startIntervalDate, @endIntervalDate) DT
				JOIN
				(	-- split our CSV into table to join to
					SELECT DISTINCT
							CONVERT(INT, SUBSTRING(@AbsoluteSubFrequency, V1.number+1, CHARINDEX(',', @AbsoluteSubFrequency, V1.number+1) - V1.number - 1)) AS D
					FROM	master..spt_values V1
					WHERE	V1.number  < LEN(@AbsoluteSubFrequency)
							AND SUBSTRING(@AbsoluteSubFrequency, V1.number, 1) = ','
				) T ON T.D = DT.ISO_DAY_OF_WEEK
		WHERE	DATEADD(s, @RunAtInSecondsFromMidnight, DT.DATE) > @LastRunTime 
				AND (DT.ISO_WEEK_NO - @LastRunTimeISOWeek) % @Frequency = 0 -- select only weeks that match our frequency
		ORDER BY DT.DATE
	END
	ELSE IF @FrequencyType = 3 -- MONTHLY SCHEDULE TYPE
	BEGIN
		-- RELATIVE SCHEDULE
		IF ISNULL(@AbsoluteSubFrequency, '') = ''
		BEGIN
			-- handle "Last X" option
			IF @MontlyRelativeSubFrequencyWhich = 5
			BEGIN 	
				-- handle Last Day of month option
				IF @MontlyRelativeSubFrequencyWhat = -1
				BEGIN 
					SELECT	TOP 1 @NextRunTime = DATEADD(s, @RunAtInSecondsFromMidnight, DATE)
					FROM	dbo.F_TABLE_DATE(@startIntervalDate, @endIntervalDate)
					WHERE	DATEADD(s, @RunAtInSecondsFromMidnight, DATE) > @LastRunTime 
							AND (MONTH - MONTH(@LastRunTime)) % @Frequency  = 0 -- select only months that match our frequency
							AND DATE = END_OF_MONTH_DATE
					ORDER BY DATE
				END 
				-- handle last Monday, Tuesday, ..., Sunday option
				ELSE
				BEGIN
					DECLARE @temp TABLE (DATE DATETIME PRIMARY KEY CLUSTERED, ISO_DAY_OF_WEEK INT, MONTH INT, DAY_OCCURRENCE_IN_MONTH INT)
					INSERT INTO @temp
					SELECT	DATEADD(s, @RunAtInSecondsFromMidnight, DATE), ISO_DAY_OF_WEEK, MONTH,
							ROW_NUMBER() OVER(PARTITION BY MONTH, ISO_DAY_OF_WEEK ORDER BY DATE) AS DAY_OCCURRENCE_IN_MONTH
					FROM	dbo.F_TABLE_DATE(@startIntervalDate, @endIntervalDate)				
					WHERE	(MONTH - MONTH(@LastRunTime)) % @Frequency  = 0 -- select only months that match our frequency
					
					SELECT	TOP 1 @NextRunTime = T1.DATE
					FROM	@temp T1
							JOIN (
								  SELECT MAX(DAY_OCCURRENCE_IN_MONTH) AS DAY_OCCURRENCE_IN_MONTH, ISO_DAY_OF_WEEK, MONTH
								  FROM @temp
								  WHERE ISO_DAY_OF_WEEK = @MontlyRelativeSubFrequencyWhat 
								  GROUP BY MONTH, ISO_DAY_OF_WEEK
								 ) T2 ON T1.ISO_DAY_OF_WEEK = T2.ISO_DAY_OF_WEEK 
											AND T1.DAY_OCCURRENCE_IN_MONTH = T2.DAY_OCCURRENCE_IN_MONTH
											AND T1.MONTH = T2.MONTH
					WHERE	T1.DATE > @LastRunTime 
					ORDER BY DATE
				END			
			END
			-- handle "1st, 2nd, 3rd, 4th" option
			ELSE
			BEGIN 
				SELECT TOP 1 @NextRunTime = DATEADD(s, @RunAtInSecondsFromMidnight, DATE)
				FROM (	-- get correct months for our frequency
					    SELECT	ROW_NUMBER() OVER(PARTITION BY MONTH, ISO_DAY_OF_WEEK ORDER BY DATE) AS DAY_OCCURRENCE_IN_MONTH,
								DATE, ISO_DAY_OF_WEEK, DAY_OF_MONTH				
					    FROM	dbo.F_TABLE_DATE(@startIntervalDate, @endIntervalDate)
					    WHERE	(MONTH - MONTH(@LastRunTime)) % @Frequency  = 0 -- select only months that match our frequency
					  ) T
				WHERE	DATEADD(s, @RunAtInSecondsFromMidnight, DATE) > @LastRunTime 
						AND
						(
						-- 1st, 2nd, 3rd, 4th day of month option
						1 = CASE WHEN	@MontlyRelativeSubFrequencyWhat = -1 
										AND DAY_OF_MONTH = @MontlyRelativeSubFrequencyWhich THEN 1 ELSE 0 END
						OR
						-- 1st, 2nd, 3rd, 4th Monday, Tuesday, ..., Sunday option
						1 = CASE WHEN	@MontlyRelativeSubFrequencyWhat != -1 
										AND ISO_DAY_OF_WEEK = @MontlyRelativeSubFrequencyWhat 
										AND DAY_OCCURRENCE_IN_MONTH = @MontlyRelativeSubFrequencyWhich THEN 1 ELSE 0 END)
				ORDER BY DATE
			END		
		END
		-- ABSOLUTE SCHEDULE
		ELSE
		BEGIN
			SELECT	@AbsoluteSubFrequency = ',' + REPLACE(@AbsoluteSubFrequency, ' ', '') + ',' -- add prefix and suffix for correct split
			SELECT	TOP 1 @NextRunTime = DATEADD(s, @RunAtInSecondsFromMidnight, DT.DATE)
			FROM	dbo.F_TABLE_DATE(@startIntervalDate, @endIntervalDate) DT
					JOIN
					(
						SELECT DISTINCT
								CONVERT(INT, SUBSTRING(@AbsoluteSubFrequency, V1.number+1, CHARINDEX(',', @AbsoluteSubFrequency, V1.number+1) - V1.number - 1)) AS D
						FROM	master..spt_values V1
						WHERE	V1.number  < LEN(@AbsoluteSubFrequency)
								AND SUBSTRING(@AbsoluteSubFrequency, V1.number, 1) = ','
					) T ON T.D = DT.DAY_OF_MONTH
			WHERE	DATEADD(s, @RunAtInSecondsFromMidnight, DT.DATE) > @LastRunTime 
					AND (DT.MONTH - @LastRunTimeMonth) % @Frequency = 0 -- select only months that match our frequency
			ORDER BY DT.DATE
		END
	END

	RETURN @NextRunTime
END
GO

IF EXISTS(SELECT * FROM sys.services WHERE NAME = N'//ScheduledJobService')
	DROP SERVICE [//ScheduledJobService]

IF EXISTS(SELECT * FROM sys.service_queues WHERE NAME = N'ScheduledJobQueue')
	DROP QUEUE ScheduledJobQueue

IF EXISTS(SELECT * FROM sys.service_contracts  WHERE NAME = N'//ScheduledJobContract')
	DROP CONTRACT [//ScheduledJobContract]

GO
-- CREATE a contract FOR the message
CREATE CONTRACT [//ScheduledJobContract]
	([http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer] SENT BY ANY)

CREATE QUEUE ScheduledJobQueue 
	WITH STATUS = ON, 
	ACTIVATION (	
		PROCEDURE_NAME = usp_RunScheduledJob,
		MAX_QUEUE_READERS = 20,
		EXECUTE AS SELF );

CREATE SERVICE [//ScheduledJobService] 
	AUTHORIZATION dbo
	ON QUEUE ScheduledJobQueue ([//ScheduledJobContract])

-------------------------------------------------------------------------------------
---- CREATE TABLES ------------------------------------------------------------------
-------------------------------------------------------------------------------------

IF OBJECT_ID('ScheduledJobs') IS NOT NULL
	DROP TABLE ScheduledJobs

GO	
CREATE TABLE ScheduledJobs
(
	ID INT IDENTITY(1,1), 
	JobScheduleId INT NOT NULL DEFAULT (-1), -- -1 for Run Once JobTypes
	ConversationHandle UNIQUEIDENTIFIER NULL,
	JobName NVARCHAR(256) NOT NULL DEFAULT (''),
	ValidFrom DATETIME NOT NULL,
	LastRunOn DATETIME, 
	NextRunOn DATETIME, 
	IsEnabled BIT NOT NULL DEFAULT (0),
	CreatedOn DATETIME NOT NULL DEFAULT GETUTCDATE()
)
GO

IF OBJECT_ID('ScheduledJobSteps') IS NOT NULL
	DROP TABLE ScheduledJobSteps
GO	
CREATE TABLE ScheduledJobSteps
(
	ID INT IDENTITY(1,1),
	ScheduledJobId INT NOT NULL,	
	StepName NVARCHAR(256) NOT NULL DEFAULT (''), 
	SqlToRun NVARCHAR(MAX) NOT NULL, -- sql statement to run
	RetryOnFail BIT NOT NULL DEFAULT (0), -- do we wish to retry the job step on failure
	RetryOnFailTimes INT NOT NULL DEFAULT (0), -- if we do how many times do we wish to retry it
	DurationInSeconds DECIMAL(14,4) DEFAULT (0), -- duration of the step with all retries 
	CreatedOn DATETIME NOT NULL DEFAULT GETUTCDATE(),
	FinishedOn DATETIME
)
GO

IF OBJECT_ID('SchedulingErrors') IS NOT NULL
	DROP TABLE SchedulingErrors
GO
CREATE TABLE SchedulingErrors
(
	ID INT IDENTITY(1, 1) PRIMARY KEY,
	ScheduledJobId INT, 
	ScheduledJobStepId INT,	
	ErrorProcedure NVARCHAR(256),
	ErrorLine INT,
	ErrorNumber INT,
	ErrorMessage NVARCHAR(2048),
	ErrorSeverity INT,
	ErrorState INT,	
	ErrorDate DATETIME NOT NULL DEFAULT GETUTCDATE()
)

GO
IF OBJECT_ID('JobSchedules') IS NOT NULL
	DROP TABLE JobSchedules
GO
CREATE TABLE JobSchedules
(
    ID INT IDENTITY(1, 1) PRIMARY KEY,
    FrequencyType INT NOT NULL CHECK (FrequencyType IN (1, 2, 3)), -- , daily = 1, weekly = 2, monthly = 3. "Run once" jobs don't have a job schedule 
    Frequency INT NOT NULL DEFAULT(1) CHECK (Frequency BETWEEN 1 AND 100),
    AbsoluteSubFrequency VARCHAR(100), -- '' if daily, '1,2,3,4,5,6,7' day of week if weekly, '1,2,3,...,28,29,30,31' if montly	
    MontlyRelativeSubFrequencyWhich INT, 
    MontlyRelativeSubFrequencyWhat INT,
    RunAtInSecondsFromMidnight INT NOT NULL DEFAULT(0) CHECK (RunAtInSecondsFromMidnight BETWEEN 0 AND 84599), -- 0-84599 = 1 day in seconds
    CONSTRAINT CK_AbsoluteSubFrequency CHECK 
                ((FrequencyType = 1 AND ISNULL(AbsoluteSubFrequency, '') = '') OR -- daily check
                 (FrequencyType = 2 AND LEN(AbsoluteSubFrequency) > 0) OR -- weekly check (days of week CSV)
                 (FrequencyType = 3 AND (LEN(AbsoluteSubFrequency) > 0 -- monthly absolute option (days of month CSV)
                                         AND MontlyRelativeSubFrequencyWhich IS NULL 
                                         AND MontlyRelativeSubFrequencyWhat IS NULL)
                                    OR ISNULL(AbsoluteSubFrequency, '') = '') -- monthly relative option
                ), 
    CONSTRAINT MontlyRelativeSubFrequencyWhich CHECK -- only allow values if frequency type is monthly
                                              (MontlyRelativeSubFrequencyWhich IS NULL OR 
                                              (FrequencyType = 3 AND 
                                               AbsoluteSubFrequency IS NULL AND 
                                               MontlyRelativeSubFrequencyWhich IN (1,2,3,4,5)) -- 1st-4th, 5=Last
                                              ), 
    CONSTRAINT MontlyRelativeSubFrequencyWhat CHECK  -- only allow values if frequency type is monthly
                                              (MontlyRelativeSubFrequencyWhich IS NULL OR 
                                              (FrequencyType = 3 AND 
                                                AbsoluteSubFrequency IS NULL AND
                                                MontlyRelativeSubFrequencyWhich IN (1,2,3,4,5,6,7,-1)) -- 1=Mon to 7=Sun, -1=Day
                                              )
)
GO
-------------------------------------------------------------------------------------
---- CREATE TEST JOBS  --------------------------------------------------------------
-------------------------------------------------------------------------------------

DECLARE @JobScheduleId INT, @ScheduledJobId INT, @validFrom DATETIME, @ScheduledJobStepId INT, @secondsOffset INT, @NextRunOn DATETIME
SELECT	@validFrom = GETUTCDATE(), -- the job is valid from current UTC time
		 -- run the job 2 minutes after the validFrom time. 
		 -- we need the offset in seconds from midnight of that day for all jobs
		@secondsOffset = 28800, -- set the job time time to 8 in the morning of the selected day
		@NextRunOn = DATEADD(n, 1, @validFrom) -- set next run for once only job to 1 minute from now

-- SIMPLE RUN ONCE SCHEDULING EXAMPLE
-- add new "run once" scheduled job 
EXEC usp_AddScheduledJob @ScheduledJobId OUT, -1, 'test job', @validFrom, @NextRunOn
-- add just one simple step for our job
EXEC usp_AddScheduledJobStep @ScheduledJobStepId OUT, @ScheduledJobId, 'EXEC sp_updatestats', 'step 1'
-- start the scheduled job
EXEC usp_StartScheduledJob @ScheduledJobId 

-- SIMPLE DAILY SCHEDULING EXAMPLE
-- run the job daily
EXEC usp_AddJobSchedule @JobScheduleId OUT,
                        @RunAtInSecondsFromMidnight = @secondsOffset,
                        @FrequencyType = 1,
                        @Frequency = 1 -- run every day                      
-- add new scheduled job 
EXEC usp_AddScheduledJob @ScheduledJobId OUT, @JobScheduleId, 'test job', @validFrom
DECLARE @backupSQL NVARCHAR(MAX)
SELECT  @backupSQL = N'DECLARE @backupTime DATETIME, @backupFile NVARCHAR(512); 
                          SELECT @backupTime = GETDATE(), 
                                 @backupFile = ''C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\Backup\AdventureWorks_'' + 
                                               replace(replace(CONVERT(NVARCHAR(25), @backupTime, 120), '' '', ''_''), '':'', ''_'') + 
                                               N''.bak''; 
                          BACKUP DATABASE AdventureWorks TO DISK = @backupFile;'

EXEC usp_AddScheduledJobStep @ScheduledJobStepId OUT, @ScheduledJobId, @backupSQL, 'step 1'
-- start the scheduled job
EXEC usp_StartScheduledJob @ScheduledJobId 

-- COMPLEX WEEKLY ABSOLUTE SCHEDULING EXAMPLE
-- run the job on every tuesday, wednesday, friday and sunday of every second week
EXEC usp_AddJobSchedule @JobScheduleId OUT,
                        @RunAtInSecondsFromMidnight = @secondsOffset,
                        @FrequencyType = 2, -- weekly frequency type
                        @Frequency = 2, -- run every every 2 weeks,
                        @AbsoluteSubFrequency = '2,3,5,7' -- run every Tuesday(2), Wednesday(3), Friday(5) and Sunday(7)	
-- add new scheduled job 
EXEC usp_AddScheduledJob @ScheduledJobId OUT, @JobScheduleId, 'test job', @validFrom
-- add three steps for our job
EXEC usp_AddScheduledJobStep @ScheduledJobStepId OUT, @ScheduledJobId, 'EXEC sp_updatestats', 'step 1'
EXEC usp_AddScheduledJobStep @ScheduledJobStepId OUT, @ScheduledJobId, 'DBCC CHECKDB', 'step 2'
EXEC usp_AddScheduledJobStep @ScheduledJobStepId OUT, @ScheduledJobId, 'select 1,', 'step 3 will fail', 1, 2 -- retry on fail 2 times
-- start the scheduled job
EXEC usp_StartScheduledJob @ScheduledJobId 

-- COMPLEX RELATIVE SCHEDULING SCHEDULING EXAMPLE
DECLARE @relativeWhichDay INT, @relativeWhatDay INT
SELECT	@relativeWhichDay = 4, -- 1 = First, 2 = Second, 3 = Third, 4 = Fourth, 5 = Last
		@relativeWhatDay = 3 -- 1 = Monday, 2 = Tuesday, ..., 7 = Sunday, -1 = Day
-- run the job on the 4th monday of every month 
EXEC usp_AddJobSchedule @JobScheduleId OUT,
                        @RunAtInSecondsFromMidnight = @secondsOffset, -- int
                        @FrequencyType = 3, -- monthly frequency type
                        @Frequency = 1, -- run every month,
                        @AbsoluteSubFrequency = NULL, -- no aboslute frequence if relative is set
						@MontlyRelativeSubFrequencyWhich = @relativeWhichDay,
						@MontlyRelativeSubFrequencyWhat = @relativeWhatDay
/*
some more relative monthly scheduling examples
run on:
the first day of the month:
  - @MontlyRelativeSubFrequencyWhich = 1, @MontlyRelativeSubFrequencyWhat = -1
the third thursday of the month:
  - @MontlyRelativeSubFrequencyWhich = 3, @MontlyRelativeSubFrequencyWhat = 4
the last sunday of the month:
  - @MontlyRelativeSubFrequencyWhich = 5, @MontlyRelativeSubFrequencyWhat = 7
the second wedensday of the month:
  - @MontlyRelativeSubFrequencyWhich = 2, @MontlyRelativeSubFrequencyWhat = 3
*/
-- add new scheduled job 
EXEC usp_AddScheduledJob @ScheduledJobId OUT, @JobScheduleId, 'test job', @validFrom
-- add just one simple step for our job
EXEC usp_AddScheduledJobStep @ScheduledJobStepId OUT, @ScheduledJobId, 'EXEC sp_updatestats', 'step 1'
-- start the scheduled job
EXEC usp_StartScheduledJob @ScheduledJobId 

-- SEE WHAT GOING ON WITH OUR JOBS
-- show the currently active conversations
-- look at dialog_timer column (in UTC time) to see when will the job be run next
SELECT GETUTCDATE(), dialog_timer, * FROM sys.conversation_endpoints
-- shows the number of currently executing activation procedures
SELECT * FROM sys.dm_broker_activated_tasks
-- see how many unreceived messages are still in the queue. should be 0 when no jobs are running
SELECT * FROM ScheduledJobQueue WITH (NOLOCK)
-- view our scheduled jobs' statuses
SELECT * FROM ScheduledJobs  WITH (NOLOCK)
SELECT * FROM ScheduledJobSteps WITH (NOLOCK)
SELECT * FROM JobSchedules  WITH (NOLOCK)
SELECT * FROM SchedulingErrors WITH (NOLOCK)