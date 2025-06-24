-- =====================================================================
-- FILE 2: 02_BJF_CSV_Testing.sql
-- PURPOSE: Modular CSV processing with comprehensive validation and error handling
-- =====================================================================

-- USE [database_name]; 
-- GO

/**
 * @description Creates temporary tables for CSV processing
 * @purpose Provides structured storage for CSV data and processing status
 */
IF OBJECT_ID('tempdb..#BJF_ISINs') IS NOT NULL DROP TABLE #BJF_ISINs;
IF OBJECT_ID('tempdb..#ValidISINs') IS NOT NULL DROP TABLE #ValidISINs;
IF OBJECT_ID('tempdb..#ProcessingStatus') IS NOT NULL DROP TABLE #ProcessingStatus;

CREATE TABLE #BJF_ISINs (
    ISIN_Raw varchar(50),
    RowNumber int IDENTITY(1,1)
);

CREATE TABLE #ValidISINs (
    CleanedISIN char(12),
    FirstRowNumber int,
    DuplicateCount int,
    ValidationStatus varchar(50)
);

CREATE TABLE #ProcessingStatus (
    ISIN char(12) PRIMARY KEY,
    Status varchar(50),
    ProcessedTimestamp datetime2 DEFAULT GETDATE(),
    RetryCount int DEFAULT 0,
    LastError nvarchar(1000) NULL,
    DataQualityScore decimal(3,2) DEFAULT 0.00
);

GO
/**
 * @description Imports ISIN data from CSV file
 * @param @FilePath - Path to CSV file
 * @returns bit - 1 if successful, 0 if failed
 * @purpose Handles CSV import with error handling and logging 
 */
CREATE PROCEDURE sp_ImportCSVData
    @FilePath nvarchar(500)
AS
BEGIN
    DECLARE @ImportSuccess bit = 0;
    DECLARE @SQL nvarchar(max) = '
    BULK INSERT #BJF_ISINs
    FROM ''' + @FilePath + '''
    WITH (
        FIELDTERMINATOR = '','',
        ROWTERMINATOR = ''\n'',
        FIRSTROW = 1,
        MAXERRORS = 10,
        ERRORFILE = ''C:\temp\bjf_isin_errors.log'',
        KEEPNULLS
    )';
    
    BEGIN TRY
        EXEC sp_executesql @SQL;
        SET @ImportSuccess = 1;
        PRINT 'CSV file imported successfully from: ' + @FilePath;
        
        DECLARE @ImportedCount int = (SELECT COUNT(*) FROM #BJF_ISINs);
        PRINT 'Imported ' + CAST(@ImportedCount AS varchar(10)) + ' rows from CSV';
        
    END TRY
    BEGIN CATCH
        PRINT 'CSV import failed: ' + ERROR_MESSAGE();
        SET @ImportSuccess = 0;
    END CATCH;
    
    SELECT @ImportSuccess as ImportSuccess;
END;
GO

/**
 * @description Validates and cleans imported ISIN data
 * @purpose Standardizes ISIN format and identifies validation issues
 */
CREATE PROCEDURE sp_ValidateAndCleanISINs
AS
BEGIN
    INSERT INTO #ValidISINs (CleanedISIN, FirstRowNumber, DuplicateCount, ValidationStatus)
    SELECT 
        UPPER(LTRIM(RTRIM(ISIN_Raw))) as CleanedISIN,
        MIN(RowNumber) as FirstRowNumber,
        COUNT(*) as DuplicateCount,
        CASE 
            WHEN LEN(LTRIM(RTRIM(ISIN_Raw))) != 12 THEN 'Invalid Length'
            WHEN LTRIM(RTRIM(ISIN_Raw)) IS NULL OR LTRIM(RTRIM(ISIN_Raw)) = '' THEN 'Empty Value'
            WHEN LEFT(LTRIM(RTRIM(ISIN_Raw)), 2) NOT LIKE '[A-Z][A-Z]' THEN 'Invalid Country Code'
            WHEN SUBSTRING(LTRIM(RTRIM(ISIN_Raw)), 3, 9) NOT LIKE '[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]' THEN 'Invalid Middle Section'
            WHEN RIGHT(LTRIM(RTRIM(ISIN_Raw)), 1) NOT LIKE '[0-9]' THEN 'Invalid Check Digit'
            WHEN dbo.fn_ValidateISIN(UPPER(LTRIM(RTRIM(ISIN_Raw)))) = 0 THEN 'Failed Validation Function'
            ELSE 'Valid Format'
        END as ValidationStatus
    FROM #BJF_ISINs
    WHERE ISIN_Raw IS NOT NULL 
      AND LTRIM(RTRIM(ISIN_Raw)) != ''
      AND LEN(LTRIM(RTRIM(ISIN_Raw))) >= 10
    GROUP BY UPPER(LTRIM(RTRIM(ISIN_Raw)));
END;
GO

/**
 * @description Generates validation summary report
 * @purpose Provides detailed statistics on imported and validated data
 */
CREATE PROCEDURE sp_GenerateValidationSummary
AS
BEGIN
    DECLARE @TotalImported int = (SELECT COUNT(*) FROM #BJF_ISINs);
    DECLARE @UniqueISINs int = (SELECT COUNT(*) FROM #ValidISINs);
    DECLARE @ValidISINs int = (SELECT COUNT(*) FROM #ValidISINs WHERE ValidationStatus = 'Valid Format');
    DECLARE @InvalidISINs int = (SELECT COUNT(*) FROM #ValidISINs WHERE ValidationStatus != 'Valid Format');
    DECLARE @DuplicatesFound int = (SELECT COUNT(*) FROM #ValidISINs WHERE DuplicateCount > 1);

    PRINT 'VALIDATION SUMMARY:';
    PRINT 'Total rows imported: ' + CAST(@TotalImported AS varchar(10));
    PRINT 'Unique ISINs: ' + CAST(@UniqueISINs AS varchar(10));
    PRINT 'Valid ISIN format: ' + CAST(@ValidISINs AS varchar(10));
    PRINT 'Invalid ISIN format: ' + CAST(@InvalidISINs AS varchar(10));
    PRINT 'Duplicates found: ' + CAST(@DuplicatesFound AS varchar(10));
    PRINT '';

    -- Show validation details if there are issues
    IF @InvalidISINs > 0
    BEGIN
        PRINT 'Invalid ISINs by category:';
        SELECT ValidationStatus, COUNT(*) as Count
        FROM #ValidISINs 
        WHERE ValidationStatus != 'Valid Format'
        GROUP BY ValidationStatus
        ORDER BY COUNT(*) DESC;
        PRINT '';
    END

    IF @DuplicatesFound > 0
    BEGIN
        PRINT 'Duplicate ISINs:';
        SELECT CleanedISIN, DuplicateCount 
        FROM #ValidISINs 
        WHERE DuplicateCount > 1
        ORDER BY DuplicateCount DESC;
        PRINT '';
    END
END;
GO

/**
 * @description Filters out already processed ISINs for resume capability
 * @param @HoursBack - Number of hours to look back for processed records
 * @purpose Enables resuming interrupted processing sessions
 */
CREATE PROCEDURE sp_ApplyResumeFilter
    @HoursBack int = 24
AS
BEGIN
    DECLARE @OriginalCount int = (SELECT COUNT(*) FROM #ValidISINs WHERE ValidationStatus = 'Valid Format');
    
    DELETE FROM #ValidISINs 
    WHERE ValidationStatus = 'Valid Format'
      AND CleanedISIN IN (
        SELECT DISTINCT ISIN 
        FROM OpenFIGI_APILog 
        WHERE IsSuccess = 1 
          AND RequestTimestamp >= DATEADD(hour, -@HoursBack, GETDATE())
      );

    DECLARE @RemainingCount int = (SELECT COUNT(*) FROM #ValidISINs WHERE ValidationStatus = 'Valid Format');
    DECLARE @SkippedCount int = @OriginalCount - @RemainingCount;
    
    IF @SkippedCount > 0
        PRINT 'Skipped ' + CAST(@SkippedCount AS varchar(10)) + ' ISINs already processed in last ' + CAST(@HoursBack AS varchar(3)) + ' hours';
    
    SELECT @RemainingCount as RemainingToProcess, @SkippedCount as SkippedCount;
END;
GO

/**
 * @description Initializes processing status tracking
 * @purpose Sets up tracking table for monitoring processing progress
 */
CREATE PROCEDURE sp_InitializeProcessingStatus
AS
BEGIN
    INSERT INTO #ProcessingStatus (ISIN, Status)
    SELECT CleanedISIN, 'Pending'
    FROM #ValidISINs 
    WHERE ValidationStatus = 'Valid Format';
    
    DECLARE @InitializedCount int = @@ROWCOUNT;
    PRINT 'Initialized processing status for ' + CAST(@InitializedCount AS varchar(10)) + ' ISINs';
END;
GO

/**
 * @description Updates processing status for an ISIN
 * @param @ISIN - ISIN code
 * @param @Status - New status
 * @param @RetryCount - Current retry count
 * @param @LastError - Error message if any
 * @param @DataQualityScore - Data quality score if successful
 * @purpose Centralized status tracking for all processing operations
 */
CREATE PROCEDURE sp_UpdateProcessingStatus
    @ISIN char(12),
    @Status varchar(50),
    @RetryCount int = 0,
    @LastError nvarchar(1000) = NULL,
    @DataQualityScore decimal(3,2) = 0.00
AS
BEGIN
    UPDATE #ProcessingStatus 
    SET Status = @Status,
        ProcessedTimestamp = GETDATE(),
        RetryCount = @RetryCount,
        LastError = @LastError,
        DataQualityScore = @DataQualityScore
    WHERE ISIN = @ISIN;
END;
GO

/**
 * @description Calculates dynamic delay based on consecutive failures
 * @param @ConsecutiveFailures - Number of consecutive failures
 * @param @BaseDelay - Base delay in milliseconds
 * @returns int - Calculated delay in milliseconds
 * @purpose Implements intelligent rate limiting with backoff
 */
CREATE FUNCTION dbo.fn_CalculateDynamicDelay(@ConsecutiveFailures int, @BaseDelay int)
RETURNS int
AS
BEGIN
    DECLARE @Delay int = @BaseDelay;
    
    IF @ConsecutiveFailures >= 5
        SET @Delay = @BaseDelay + 3000;
    ELSE IF @ConsecutiveFailures >= 3
        SET @Delay = @BaseDelay + 2000;
    ELSE IF @ConsecutiveFailures >= 1
        SET @Delay = @BaseDelay + 1000;
    
    RETURN @Delay;
END;
GO

/**
 * @description Executes wait delay with proper formatting
 * @param @DelayMs - Delay in milliseconds
 * @purpose Provides consistent delay execution across the system
 */
CREATE PROCEDURE sp_ExecuteDelay
    @DelayMs int
AS
BEGIN
    DECLARE @DelaySeconds int = @DelayMs / 1000;
    DECLARE @DelayMilliseconds int = @DelayMs % 1000;
    DECLARE @DelayString char(12) = 
        RIGHT('00' + CAST(@DelaySeconds / 3600 AS varchar), 2) + ':' +
        RIGHT('00' + CAST((@DelaySeconds % 3600) / 60 AS varchar), 2) + ':' +
        RIGHT('00' + CAST(@DelaySeconds % 60 AS varchar), 2) + '.' +
        RIGHT('000' + CAST(@DelayMilliseconds AS varchar), 3);
    
    WAITFOR DELAY @DelayString;
END;
GO

/**
 * @description Determines if an error is retryable
 * @param @ErrorCategory - Error category from API call
 * @returns bit - 1 if retryable, 0 if not
 * @purpose Provides consistent retry logic across the system
 */
CREATE FUNCTION dbo.fn_IsRetryableError(@ErrorCategory varchar(50))
RETURNS bit
AS
BEGIN
    RETURN CASE WHEN @ErrorCategory IN ('Rate Limited', 'Server Error', 'Network Error') THEN 1 ELSE 0 END;
END;
GO

/**
 * @description Processes a single ISIN with retry logic
 * @param @ISIN - ISIN to process
 * @param @MaxRetries - Maximum retry attempts
 * @param @BaseDelay - Base delay between attempts
 * @returns Table with processing results
 * @purpose Handles individual ISIN processing with comprehensive error handling
 */
CREATE PROCEDURE sp_ProcessSingleISIN
    @ISIN char(12),
    @MaxRetries int = 3,
    @BaseDelay int = 2500
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RetryCount int = 0;
    DECLARE @ProcessingComplete bit = 0;
    DECLARE @ConsecutiveFailures int = 0;
    
    WHILE @RetryCount <= @MaxRetries AND @ProcessingComplete = 0
    BEGIN
        PRINT 'Processing ISIN: ' + @ISIN + 
              CASE WHEN @RetryCount > 0 THEN ' (Retry ' + CAST(@RetryCount AS varchar(2)) + ')' ELSE '' END;
        
        BEGIN TRY
            DECLARE @TestStartTime datetime2 = GETDATE();
            
            -- Call main lookup procedure
            EXEC sp_LookupISINViaOpenFIGI @ISIN = @ISIN, @UpdateSecurityTable = 1, @MaxRetries = 1;
            
            DECLARE @TestDuration int = DATEDIFF(MILLISECOND, @TestStartTime, GETDATE());
            
            -- Check API call results
            DECLARE @APISuccess bit = 0;
            DECLARE @ErrorMsg nvarchar(1000) = NULL;
            DECLARE @ErrorCategory varchar(50) = NULL;
            DECLARE @ResponseCode int = 0;
            
            SELECT TOP 1 
                @APISuccess = IsSuccess,
                @ErrorMsg = ErrorMessage,
                @ErrorCategory = ErrorCategory,
                @ResponseCode = ResponseCode
            FROM OpenFIGI_APILog 
            WHERE ISIN = @ISIN 
            ORDER BY RequestTimestamp DESC;
            
            IF @APISuccess = 1
            BEGIN
                -- Success - get data quality information
                DECLARE @DataQualityScore decimal(3,2) = 0.00;
                SELECT @DataQualityScore = ISNULL(DataQualityScore, 0.00)
                FROM Securities 
                WHERE ISIN = @ISIN;
                
                EXEC sp_UpdateProcessingStatus @ISIN, 'Success', @RetryCount, NULL, @DataQualityScore;
                SET @ProcessingComplete = 1;
                SET @ConsecutiveFailures = 0;
                
                PRINT '  ✅ SUCCESS - Quality Score: ' + CAST(@DataQualityScore AS varchar(5)) + 
                      ' - Response Time: ' + CAST(@TestDuration AS varchar(10)) + 'ms';
            END
            ELSE
            BEGIN
                -- Handle failures
                SET @ConsecutiveFailures = @ConsecutiveFailures + 1;
                
                IF dbo.fn_IsRetryableError(@ErrorCategory) = 1 AND @RetryCount < @MaxRetries
                BEGIN
                    SET @RetryCount = @RetryCount + 1;
                    DECLARE @DelayMs int = dbo.fn_CalculateDynamicDelay(@ConsecutiveFailures, @BaseDelay);
                    
                    EXEC sp_UpdateProcessingStatus @ISIN, 'Retrying', @RetryCount, @ErrorMsg, 0.00;
                    
                    PRINT '  ⚠️ ' + @ErrorCategory + ' - Retrying in ' + CAST(@DelayMs/1000 AS varchar(5)) + ' seconds...';
                    EXEC sp_ExecuteDelay @DelayMs;
                END
                ELSE
                BEGIN
                    DECLARE @FailedStatus varchar(100) = 'Failed - ' + ISNULL(@ErrorCategory, 'Unknown');
                    EXEC sp_UpdateProcessingStatus @ISIN, @FailedStatus, @RetryCount, @ErrorMsg, 0.00;
                    SET @ProcessingComplete = 1;
                    PRINT '  ❌ FAILED - ' + @ErrorCategory + ': ' + ISNULL(@ErrorMsg, 'Unknown error');
                END
            END
            
        END TRY
        BEGIN CATCH
            DECLARE @CatchError nvarchar(1000) = ERROR_MESSAGE();
            SET @ConsecutiveFailures = @ConsecutiveFailures + 1;
            
            IF @RetryCount < @MaxRetries
            BEGIN
                SET @RetryCount = @RetryCount + 1;
                DECLARE @DelayMs2 int = dbo.fn_CalculateDynamicDelay(@ConsecutiveFailures, @BaseDelay);
                
                EXEC sp_UpdateProcessingStatus @ISIN, 'Exception - Retrying', @RetryCount, @CatchError, 0.00;
                
                PRINT '  ⚠️ EXCEPTION - Retrying: ' + @CatchError;
                EXEC sp_ExecuteDelay @DelayMs2;
            END
            ELSE
            BEGIN
                EXEC sp_UpdateProcessingStatus @ISIN, 'Failed - Exception', @RetryCount, @CatchError, 0.00;
                SET @ProcessingComplete = 1;
                PRINT '  ❌ ERROR: ' + @CatchError;
            END
        END CATCH
    END
    
    -- Return processing results
    SELECT @ISIN as ISIN, 
           CASE WHEN @ProcessingComplete = 1 AND @APISuccess = 1 THEN 'Success' ELSE 'Failed' END as Result,
           @RetryCount as RetryCount,
           @ConsecutiveFailures as ConsecutiveFailures;
END;
GO

/**
 * @description Main processing loop for all valid ISINs
 * @param @MaxRetries - Maximum retry attempts per ISIN
 * @param @BaseDelay - Base delay between API calls
 * @purpose Orchestrates the processing of all valid ISINs with progress tracking
 */
CREATE PROCEDURE sp_ProcessAllISINs
    @MaxRetries int = 3,
    @BaseDelay int = 2500
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TotalRows int = (SELECT COUNT(*) FROM #ValidISINs WHERE ValidationStatus = 'Valid Format');
    DECLARE @RowCount int = 1;
    DECLARE @SuccessfulTests int = 0;
    DECLARE @FailedTests int = 0;
    DECLARE @StartTime datetime2 = GETDATE();
    DECLARE @GlobalConsecutiveFailures int = 0;
    DECLARE @CurrentDelay int = @BaseDelay;
    
    PRINT 'Starting processing of ' + CAST(@TotalRows AS varchar(10)) + ' valid ISINs...';
    PRINT 'Configuration: Max Retries = ' + CAST(@MaxRetries AS varchar(2)) + 
          ', Base Delay = ' + CAST(@BaseDelay AS varchar(10)) + 'ms';
    PRINT 'Estimated time: ' + CAST((@TotalRows * @BaseDelay / 1000 / 60) AS varchar(10)) + ' minutes';
    PRINT '================================================================================';
    
    -- Process each ISIN
    DECLARE @CurrentISIN char(12);
    DECLARE isin_cursor CURSOR FOR
    SELECT CleanedISIN 
    FROM #ValidISINs 
    WHERE ValidationStatus = 'Valid Format'
    ORDER BY FirstRowNumber;
    
    OPEN isin_cursor;
    FETCH NEXT FROM isin_cursor INTO @CurrentISIN;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Processing ' + CAST(@RowCount AS varchar(5)) + '/' + CAST(@TotalRows AS varchar(5)) + ': ' + @CurrentISIN;
        
        -- Process single ISIN
        DECLARE @ProcessResult TABLE (ISIN char(12), Result varchar(20), RetryCount int, ConsecutiveFailures int);
        INSERT INTO @ProcessResult EXEC sp_ProcessSingleISIN @CurrentISIN, @MaxRetries, @BaseDelay;
        
        -- Update counters
        DECLARE @Result varchar(20), @ISINRetryCount int, @ISINConsecutiveFailures int;
        SELECT @Result = Result, @ISINRetryCount = RetryCount, @ISINConsecutiveFailures = ConsecutiveFailures 
        FROM @ProcessResult;
        
        IF @Result = 'Success'
        BEGIN
            SET @SuccessfulTests = @SuccessfulTests + 1;
            SET @GlobalConsecutiveFailures = 0;
            SET @CurrentDelay = @BaseDelay; -- Reset delay on success
        END
        ELSE
        BEGIN
            SET @FailedTests = @FailedTests + 1;
            SET @GlobalConsecutiveFailures = @GlobalConsecutiveFailures + 1;
            SET @CurrentDelay = dbo.fn_CalculateDynamicDelay(@GlobalConsecutiveFailures, @BaseDelay);
        END
        
        DELETE FROM @ProcessResult;
        SET @RowCount = @RowCount + 1;
        
        -- Apply delay before next ISIN
        FETCH NEXT FROM isin_cursor INTO @CurrentISIN;
        IF @@FETCH_STATUS = 0
        BEGIN
            PRINT '  Waiting ' + CAST(@CurrentDelay/1000.0 AS varchar(5)) + ' seconds before next call...';
            EXEC sp_ExecuteDelay @CurrentDelay;
        END
    END
    
    CLOSE isin_cursor;
    DEALLOCATE isin_cursor;
    
    -- Return processing summary
    DECLARE @EndTime datetime2 = GETDATE();
    DECLARE @TotalDuration int = DATEDIFF(SECOND, @StartTime, @EndTime);
    DECLARE @SuccessRate decimal(5,2) = CASE WHEN @TotalRows > 0 THEN (@SuccessfulTests * 100.0 / @TotalRows) ELSE 0 END;
    
    SELECT 
        @TotalRows as TotalProcessed,
        @SuccessfulTests as Successful,
        @FailedTests as Failed,
        @SuccessRate as SuccessRatePercent,
        @TotalDuration as DurationSeconds,
        @StartTime as StartTime,
        @EndTime as EndTime;
END;
GO

/**
 * @description Generates comprehensive processing summary report
 * @purpose Provides detailed statistics and analysis of processing results
 */
CREATE PROCEDURE sp_GenerateProcessingSummary
AS
BEGIN
    PRINT '================================================================================';
    PRINT 'PROCESSING COMPLETED!';
    PRINT '';
    
    -- Basic statistics
    DECLARE @TotalProcessed int = (SELECT COUNT(*) FROM #ProcessingStatus);
    DECLARE @Successful int = (SELECT COUNT(*) FROM #ProcessingStatus WHERE Status = 'Success');
    DECLARE @Failed int = (SELECT COUNT(*) FROM #ProcessingStatus WHERE Status NOT LIKE 'Success%');
    DECLARE @SuccessRate decimal(5,2) = CASE WHEN @TotalProcessed > 0 THEN (@Successful * 100.0 / @TotalProcessed) ELSE 0 END;
    DECLARE @AvgQuality decimal(3,2) = (SELECT AVG(DataQualityScore) FROM #ProcessingStatus WHERE DataQualityScore > 0);
    
    PRINT 'PROCESSING SUMMARY:';
    PRINT 'Total ISINs processed: ' + CAST(@TotalProcessed AS varchar(10));
    PRINT 'Successful: ' + CAST(@Successful AS varchar(10)) + ' (' + CAST(@SuccessRate AS varchar(10)) + '%)';
    PRINT 'Failed: ' + CAST(@Failed AS varchar(10));
    PRINT 'Average data quality score: ' + CAST(ISNULL(@AvgQuality, 0) AS varchar(5));
    PRINT '';
    
    -- Processing status breakdown
    PRINT 'STATUS BREAKDOWN:';
    SELECT 
        LEFT(Status, 20) as StatusCategory,
        COUNT(*) as Count,
        CAST(COUNT(*) * 100.0 / @TotalProcessed AS decimal(5,2)) as Percentage
    FROM #ProcessingStatus
    GROUP BY LEFT(Status, 20)
    ORDER BY COUNT(*) DESC;
    PRINT '';
    
    -- Data quality distribution
    PRINT 'DATA QUALITY DISTRIBUTION:';
    SELECT 
        CASE 
            WHEN DataQualityScore >= 0.8 THEN 'Excellent (0.8-1.0)'
            WHEN DataQualityScore >= 0.6 THEN 'Good (0.6-0.79)'
            WHEN DataQualityScore >= 0.4 THEN 'Fair (0.4-0.59)'
            WHEN DataQualityScore >= 0.2 THEN 'Poor (0.2-0.39)'
            WHEN DataQualityScore > 0 THEN 'Very Poor (0.01-0.19)'
            ELSE 'No Data (0.0)'
        END as QualityTier,
        COUNT(*) as Count,
        CAST(COUNT(*) * 100.0 / @TotalProcessed AS decimal(5,2)) as Percentage
    FROM #ProcessingStatus
    GROUP BY 
        CASE 
            WHEN DataQualityScore >= 0.8 THEN 'Excellent (0.8-1.0)'
            WHEN DataQualityScore >= 0.6 THEN 'Good (0.6-0.79)'
            WHEN DataQualityScore >= 0.4 THEN 'Fair (0.4-0.59)'
            WHEN DataQualityScore >= 0.2 THEN 'Poor (0.2-0.39)'
            WHEN DataQualityScore > 0 THEN 'Very Poor (0.01-0.19)'
            ELSE 'No Data (0.0)'
        END
    ORDER BY MIN(ISNULL(DataQualityScore, 0)) DESC;
END;
GO

/**
 * @description Generates detailed results export for BJF Research
 * @purpose Creates export-ready dataset with all processed information
 */
CREATE PROCEDURE sp_GenerateDetailedResults
AS
BEGIN
    PRINT '';
    PRINT 'DETAILED PROCESSING RESULTS:';
    
    SELECT 
        s.ISIN as ISIN_Code,
        s.FIGI as OpenFIGI_Identifier,
        s.BloombergCode as Bloomberg_Terminal_Code,
        s.Ticker as Trading_Symbol,
        s.SecurityName as Company_Name,
        s.ExchangeCode as Exchange_Code,
        s.Currency as Trading_Currency,
        s.DataQualityScore as Data_Quality_Score,
        s.LastFIGIUpdate as Data_Retrieved_Timestamp,
        ps.RetryCount as API_Retry_Count,
        ps.Status as Processing_Status,
        CASE 
            WHEN s.DataQualityScore >= 0.8 THEN 'EXCELLENT'
            WHEN s.DataQualityScore >= 0.6 THEN 'GOOD'
            WHEN s.DataQualityScore >= 0.4 THEN 'FAIR'
            WHEN s.DataQualityScore >= 0.2 THEN 'POOR'
            WHEN s.DataQualityScore > 0 THEN 'VERY_POOR'
            ELSE 'NO_DATA'
        END as Data_Quality_Rating,
        CASE 
            WHEN s.FIGI IS NOT NULL AND s.BloombergCode IS NOT NULL AND s.Ticker IS NOT NULL THEN 'COMPLETE'
            WHEN s.FIGI IS NOT NULL AND s.BloombergCode IS NOT NULL THEN 'MOSTLY_COMPLETE'
            WHEN s.FIGI IS NOT NULL OR s.BloombergCode IS NOT NULL THEN 'PARTIAL'
            ELSE 'FAILED'
        END as Data_Completeness_Status
    FROM Securities s
        LEFT JOIN #ProcessingStatus ps ON s.ISIN = ps.ISIN
    WHERE s.ISIN IN (SELECT ISIN FROM #ProcessingStatus)
    ORDER BY s.DataQualityScore DESC, s.SecurityName;
END;
GO

/**
 * @description Main execution procedure that orchestrates the entire CSV processing workflow
 * @param @FilePath - Path to CSV file
 * @param @MaxRetries - Maximum retry attempts per ISIN
 * @param @BaseDelayMs - Base delay between API calls in milliseconds
 * @purpose Primary entry point for CSV processing with comprehensive workflow management
 */
CREATE PROCEDURE sp_ExecuteCSVProcessing
    @FilePath nvarchar(500) = 'C:\Users\Sam\Downloads\ISIN.csv',
    @MaxRetries int = 3,
    @BaseDelayMs int = 2500
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT 'Starting BJF Research CSV Processing Workflow';
    PRINT 'Configuration: File = ' + @FilePath + ', Max Retries = ' + CAST(@MaxRetries AS varchar(2)) + ', Base Delay = ' + CAST(@BaseDelayMs AS varchar(10)) + 'ms';
    PRINT '================================================================================';
    
    -- Step 1: Import CSV data
    PRINT 'STEP 1: Importing CSV data...';
    EXEC sp_ImportCSVData @FilePath;
    
    -- Step 2: Validate and clean data
    PRINT 'STEP 2: Validating and cleaning data...';
    EXEC sp_ValidateAndCleanISINs;
    
    -- Step 3: Apply resume filter
    PRINT 'STEP 3: Applying resume filter...';
    EXEC sp_ApplyResumeFilter 24; -- Skip ISINs processed in last 24 hours
    
    -- Step 4: Initialize processing
    PRINT 'STEP 4: Initializing processing status...';
    EXEC sp_InitializeProcessingStatus;
    
    -- Step 5: Process all ISINs
    PRINT 'STEP 5: Processing all ISINs...';
    EXEC sp_ProcessAllISINs @MaxRetries, @BaseDelayMs;
    
    -- Step 6: Generate reports
    PRINT 'STEP 6: Generating comprehensive reports...';
    EXEC sp_GenerateProcessingSummary;
    EXEC sp_GenerateDetailedResults;    
    -- Step 7: Executive summary
    PRINT '';
    PRINT 'EXECUTIVE SUMMARY FOR BJF RESEARCH:';
    SELECT 
        'BJF Research ISIN Data Acquisition' as Project_Name,
        GETDATE() as Report_Generated,
        (SELECT COUNT(*) FROM #ProcessingStatus) as Total_ISINs_Processed,
        (SELECT COUNT(*) FROM #ProcessingStatus WHERE Status = 'Success') as Successful_Lookups,
        (SELECT COUNT(*) FROM #ProcessingStatus WHERE Status NOT LIKE 'Success%') as Failed_Lookups,
        CAST((SELECT COUNT(*) FROM #ProcessingStatus WHERE Status = 'Success') * 100.0 / 
             (SELECT COUNT(*) FROM #ProcessingStatus) AS varchar(10)) + '%' as Success_Rate,
        CAST((SELECT AVG(DataQualityScore) FROM #ProcessingStatus WHERE DataQualityScore > 0) AS varchar(5)) as Average_Data_Quality_Score,
        (SELECT COUNT(*) FROM #ProcessingStatus WHERE DataQualityScore >= 0.6) as High_Quality_Records,
        'edda2f69-53b3-42d9-b832-f6dda111af67' as API_Key_Used,
        CASE 
            WHEN (SELECT COUNT(*) FROM #ProcessingStatus WHERE Status = 'Success') * 100.0 / (SELECT COUNT(*) FROM #ProcessingStatus) >= 80 THEN 'EXCELLENT'
            WHEN (SELECT COUNT(*) FROM #ProcessingStatus WHERE Status = 'Success') * 100.0 / (SELECT COUNT(*) FROM #ProcessingStatus) >= 60 THEN 'GOOD'
            WHEN (SELECT COUNT(*) FROM #ProcessingStatus WHERE Status = 'Success') * 100.0 / (SELECT COUNT(*) FROM #ProcessingStatus) >= 40 THEN 'FAIR'
            ELSE 'NEEDS_IMPROVEMENT'
        END as Overall_Status;
    
    PRINT '';
    PRINT '================================================================================';
    PRINT 'BJF RESEARCH CSV PROCESSING COMPLETED SUCCESSFULLY!';
    PRINT '';
    PRINT 'All processing completed with modular, maintainable code architecture.';
    PRINT '================================================================================';
END;
GO

-- Execute the main processing workflow
EXEC sp_ExecuteCSVProcessing 
    @FilePath = 'C:\Users\Sam\Downloads\ISIN.csv',
    @MaxRetries = 3,
    @BaseDelayMs = 2500;

-- Clean up temporary tables
DROP TABLE #BJF_ISINs;
DROP TABLE #ValidISINs;
DROP TABLE #ProcessingStatus;

GO