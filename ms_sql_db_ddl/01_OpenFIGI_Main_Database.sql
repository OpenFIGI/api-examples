-- =====================================================================
-- FILE 1: 01_OpenFIGI_Main_Database.sql
-- PURPOSE: Modular OpenFIGI integration with comprehensive validation
-- =====================================================================

-- USE [database_name];
-- GO

/**
 * @description Creates custom data types for financial instrument identifiers
 * @purpose Ensures consistent data types across all tables and functions
 */
PRINT 'Creating custom data types...';
CREATE TYPE dbo.ISIN_TYPE FROM char(12) NOT NULL;
CREATE TYPE dbo.TICKER_TYPE FROM varchar(20) NOT NULL;
CREATE TYPE dbo.FIGI_TYPE FROM char(12) NOT NULL;
CREATE TYPE dbo.BLOOMBERG_CODE_TYPE FROM varchar(50) NOT NULL;
CREATE TYPE dbo.CURRENCY_CODE_TYPE FROM char(3) NOT NULL;
CREATE TYPE dbo.EXCHANGE_CODE_TYPE FROM varchar(10) NOT NULL;
PRINT 'Custom data types created successfully!';
GO

/**
 * @description Validates ISIN format according to ISO 6166 standard
 * @param @ISIN - 12-character ISIN code to validate
 * @returns bit - 1 if valid, 0 if invalid
 * @purpose Ensures ISIN codes meet international standard format
 */
CREATE FUNCTION dbo.fn_ValidateISIN(@ISIN char(12))
RETURNS bit
AS
BEGIN
    IF LEN(@ISIN) != 12 RETURN 0;
    IF LEFT(@ISIN, 2) NOT LIKE '[A-Z][A-Z]' RETURN 0;
    IF SUBSTRING(@ISIN, 3, 9) NOT LIKE '[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]' RETURN 0;
    IF RIGHT(@ISIN, 1) NOT LIKE '[0-9]' RETURN 0;
    IF LEFT(@ISIN, 2) IN ('AA', 'ZZ', '00') RETURN 0; -- Exclude test/invalid codes
    
    RETURN 1;
END;
GO

/**
 * @description Validates FIGI format (Bloomberg Global Identifier)
 * @param @FIGI - 12-character FIGI code to validate
 * @returns bit - 1 if valid, 0 if invalid
 * @purpose Ensures FIGI codes follow BBG + 9 alphanumeric format
 */
CREATE FUNCTION dbo.fn_ValidateFIGI(@FIGI char(12))
RETURNS bit
AS
BEGIN
    IF LEN(@FIGI) != 12 RETURN 0;
    IF LEFT(@FIGI, 3) != 'BBG' RETURN 0;
    IF SUBSTRING(@FIGI, 4, 9) NOT LIKE '[A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9][A-Z0-9]' RETURN 0;
    IF @FIGI LIKE '%[^A-Z0-9]%' RETURN 0;
    
    RETURN 1;
END;
GO

/**
 * @description Validates currency code against ISO 4217 standard
 * @param @CurrencyCode - 3-character currency code to validate
 * @returns bit - 1 if valid, 0 if invalid
 * @purpose Ensures currency codes are recognized international standards
 */
CREATE FUNCTION dbo.fn_ValidateCurrencyCode(@CurrencyCode char(3))
RETURNS bit
AS
BEGIN
    RETURN CASE WHEN @CurrencyCode IN (
        'USD', 'EUR', 'GBP', 'JPY', 'CHF', 'CAD', 'AUD', 'NZD', 'SEK', 'NOK', 
        'DKK', 'PLN', 'CZK', 'HUF', 'RUB', 'CNY', 'HKD', 'SGD', 'KRW', 'INR',
        'BRL', 'MXN', 'ZAR', 'TRY', 'ILS', 'THB', 'MYR', 'IDR', 'PHP', 'VND',
        'TWD', 'SAR', 'AED', 'QAR', 'KWD', 'BHD', 'OMR', 'JOD', 'LBP', 'EGP',
        'MAD', 'TND', 'DZD', 'NGN', 'GHS', 'KES', 'UGX', 'TZS', 'ZMW', 'BWP',
        'CLP', 'COP', 'PEN', 'ARS', 'UYU', 'PYG', 'BOB', 'VES', 'GYD', 'SRD'
    ) THEN 1 ELSE 0 END;
END;
GO

/**
 * @description Validates ticker symbol format and length
 * @param @Ticker - Ticker symbol to validate
 * @returns bit - 1 if valid, 0 if invalid
 * @purpose Ensures ticker symbols meet basic format requirements
 */
CREATE FUNCTION dbo.fn_ValidateTickerLength(@Ticker varchar(20))
RETURNS bit
AS
BEGIN
    IF @Ticker IS NULL RETURN 0;
    IF LEN(RTRIM(@Ticker)) = 0 RETURN 0;
    IF LEN(RTRIM(@Ticker)) > 20 RETURN 0;
    IF @Ticker LIKE '%[^A-Z0-9.-]%' RETURN 0;
    
    RETURN 1;
END;
GO

/**
 * @description Validates security name format and length
 * @param @Name - Security name to validate
 * @returns bit - 1 if valid, 0 if invalid
 * @purpose Ensures security names meet basic format requirements
 */
CREATE FUNCTION dbo.fn_ValidateSecurityName(@Name nvarchar(255))
RETURNS bit
AS
BEGIN
    IF @Name IS NULL RETURN 0;
    IF LEN(RTRIM(@Name)) = 0 RETURN 0;
    IF LEN(RTRIM(@Name)) > 255 RETURN 0;
    
    RETURN 1;
END;
GO

/**
 * @description Validates exchange code format
 * @param @ExchangeCode - Exchange code to validate
 * @returns bit - 1 if valid, 0 if invalid
 * @purpose Ensures exchange codes meet basic format requirements
 */
CREATE FUNCTION dbo.fn_ValidateExchangeCode(@ExchangeCode varchar(10))
RETURNS bit
AS
BEGIN
    IF @ExchangeCode IS NULL RETURN 0;
    IF LEN(RTRIM(@ExchangeCode)) = 0 RETURN 0;
    IF LEN(RTRIM(@ExchangeCode)) > 10 RETURN 0;
    IF @ExchangeCode NOT LIKE '[A-Z][A-Z]%' RETURN 0;
    
    RETURN 1;
END;
GO

PRINT 'Validation functions created successfully!';

/**
 * @description Main securities table with comprehensive validation
 * @purpose Stores all security information with data quality tracking
 */
PRINT 'Creating Securities table...';
CREATE TABLE Securities (
    SecurityID int IDENTITY(1,1) PRIMARY KEY,
    ISIN dbo.ISIN_TYPE,
    FIGI dbo.FIGI_TYPE NULL,
    Ticker dbo.TICKER_TYPE NULL,
    BloombergCode dbo.BLOOMBERG_CODE_TYPE NULL,
    SecurityName nvarchar(255) NOT NULL,
    SecurityType varchar(50) NOT NULL DEFAULT 'UNKNOWN',
    ExchangeCode dbo.EXCHANGE_CODE_TYPE NULL,
    Currency dbo.CURRENCY_CODE_TYPE NULL,
    Country char(2) NULL,
    Sector varchar(100) NULL,
    Industry varchar(100) NULL,
    MarketCap bigint NULL,
    SharesOutstanding bigint NULL,
    DataQualityScore decimal(3,2) DEFAULT 0.00,
    IsActive bit DEFAULT 1,
    CreatedDate datetime2 DEFAULT GETDATE(),
    ModifiedDate datetime2 DEFAULT GETDATE(),
    LastFIGIUpdate datetime2 NULL,
    ProcessingAttempts int DEFAULT 0,
    LastProcessingAttempt datetime2 NULL,
    
    -- Constraints
    CONSTRAINT UQ_Securities_ISIN UNIQUE (ISIN),
    CONSTRAINT UQ_Securities_FIGI UNIQUE (FIGI),
    CONSTRAINT CK_Securities_ISIN_Format CHECK (dbo.fn_ValidateISIN(ISIN) = 1),
    CONSTRAINT CK_Securities_FIGI_Format CHECK (FIGI IS NULL OR dbo.fn_ValidateFIGI(FIGI) = 1),
    CONSTRAINT CK_Securities_Currency_Format CHECK (Currency IS NULL OR dbo.fn_ValidateCurrencyCode(Currency) = 1),
    CONSTRAINT CK_Securities_Ticker_Valid CHECK (Ticker IS NULL OR dbo.fn_ValidateTickerLength(Ticker) = 1),
    CONSTRAINT CK_Securities_SecurityName_Valid CHECK (dbo.fn_ValidateSecurityName(SecurityName) = 1),
    CONSTRAINT CK_Securities_ExchangeCode_Valid CHECK (ExchangeCode IS NULL OR dbo.fn_ValidateExchangeCode(ExchangeCode) = 1),
    CONSTRAINT CK_Securities_DataQuality_Range CHECK (DataQualityScore BETWEEN 0.00 AND 1.00),
    CONSTRAINT CK_Securities_SecurityType CHECK (SecurityType IN ('EQUITY', 'BOND', 'DERIVATIVE', 'FUND', 'INDEX', 'CURRENCY', 'COMMODITY', 'UNKNOWN'))
);
GO

/**
 * @description API call logging table with comprehensive tracking
 * @purpose Tracks all API calls for auditing and performance monitoring
 */
PRINT 'Creating OpenFIGI API Log table...';
CREATE TABLE OpenFIGI_APILog (
    LogID int IDENTITY(1,1) PRIMARY KEY,
    RequestID uniqueidentifier DEFAULT NEWID(),
    ISIN dbo.ISIN_TYPE,
    RequestPayload nvarchar(max),
    ResponsePayload nvarchar(max),
    ResponseCode int,
    IsSuccess bit,
    ErrorMessage nvarchar(1000) NULL,
    ErrorCategory varchar(50) NULL,
    RequestTimestamp datetime2 DEFAULT GETDATE(),
    ResponseTimestamp datetime2 NULL,
    ProcessingTimeMs int NULL,
    RetryAttempt int DEFAULT 1,
    
    CONSTRAINT CK_APILog_ISIN_Format CHECK (dbo.fn_ValidateISIN(ISIN) = 1),
    CONSTRAINT CK_APILog_RetryAttempt_Range CHECK (RetryAttempt >= 1 AND RetryAttempt <= 5)
);
GO

/**
 * @description Creates optimized indexes for query performance
 * @purpose Improves query performance for common access patterns
 */
PRINT 'Creating performance indexes...';
CREATE INDEX IX_Securities_ISIN ON Securities(ISIN);
CREATE INDEX IX_Securities_FIGI ON Securities(FIGI);
CREATE INDEX IX_Securities_Ticker ON Securities(Ticker);
CREATE INDEX IX_Securities_DataQuality ON Securities(DataQualityScore);
CREATE INDEX IX_Securities_LastUpdate ON Securities(LastFIGIUpdate);
CREATE INDEX IX_APILog_ISIN ON OpenFIGI_APILog(ISIN);
CREATE INDEX IX_APILog_Timestamp ON OpenFIGI_APILog(RequestTimestamp);
CREATE INDEX IX_APILog_Success ON OpenFIGI_APILog(IsSuccess);
CREATE INDEX IX_APILog_ErrorCategory ON OpenFIGI_APILog(ErrorCategory);
PRINT 'Performance indexes created successfully!';

GO

/**
 * @description Builds Bloomberg terminal code from components
 * @param @Ticker - Ticker symbol
 * @param @ExchangeCode - Exchange code
 * @param @SecurityType - Security type
 * @returns varchar(50) - Bloomberg terminal code
 * @purpose Creates standardized Bloomberg terminal codes
 */
CREATE FUNCTION dbo.fn_BuildBloombergCode(
    @Ticker varchar(20),
    @ExchangeCode varchar(10),
    @SecurityType varchar(50)
)
RETURNS varchar(50)
AS
BEGIN
    IF @Ticker IS NULL OR @ExchangeCode IS NULL RETURN NULL;
    IF dbo.fn_ValidateTickerLength(@Ticker) = 0 RETURN NULL;
    IF dbo.fn_ValidateExchangeCode(@ExchangeCode) = 0 RETURN NULL;
    
    DECLARE @BBGType varchar(20) = CASE 
        WHEN @SecurityType IN ('EQUITY', 'Common Stock', 'Preferred Stock', 'ADR') THEN 'Equity'
        WHEN @SecurityType LIKE '%Bond%' OR @SecurityType = 'BOND' THEN 'Corp'
        WHEN @SecurityType = 'Government Bond' THEN 'Govt'
        WHEN @SecurityType IN ('FUND', 'ETF', 'Mutual Fund') THEN 'Equity'
        WHEN @SecurityType = 'INDEX' THEN 'Index'
        WHEN @SecurityType = 'CURRENCY' THEN 'Curncy'
        WHEN @SecurityType = 'COMMODITY' THEN 'Comdty'
        ELSE 'Equity'
    END;
    
    RETURN @Ticker + ' ' + @ExchangeCode + ' ' + @BBGType;
END;
GO

/**
 * @description Extracts specific field from JSON response
 * @param @JSON - JSON response text
 * @param @FieldName - Field name to extract
 * @returns nvarchar(500) - Extracted field value
 * @purpose Provides reusable JSON parsing functionality
 */
CREATE FUNCTION dbo.fn_ExtractJSONField(@JSON nvarchar(max), @FieldName varchar(50))
RETURNS nvarchar(500)
AS
BEGIN
    DECLARE @Pattern nvarchar(100) = '"' + @FieldName + '":"';
    DECLARE @StartPos int = CHARINDEX(@Pattern, @JSON);
    
    IF @StartPos = 0 RETURN NULL;
    
    SET @StartPos = @StartPos + LEN(@Pattern);
    DECLARE @EndPos int = CHARINDEX('"', @JSON, @StartPos);
    
    IF @EndPos = 0 OR @EndPos <= @StartPos RETURN NULL;
    
    RETURN SUBSTRING(@JSON, @StartPos, @EndPos - @StartPos);
END;
GO

/**
 * @description Categorizes API errors for better handling
 * @param @ResponseCode - HTTP response code
 * @returns varchar(50) - Error category
 * @purpose Provides consistent error categorization
 */
CREATE FUNCTION dbo.fn_CategorizeAPIError(@ResponseCode int)
RETURNS varchar(50)
AS
BEGIN
    RETURN CASE 
        WHEN @ResponseCode = 400 THEN 'Bad Request'
        WHEN @ResponseCode = 401 THEN 'Unauthorized'
        WHEN @ResponseCode = 404 THEN 'Not Found'
        WHEN @ResponseCode = 429 THEN 'Rate Limited'
        WHEN @ResponseCode >= 500 THEN 'Server Error'
        WHEN @ResponseCode = 0 THEN 'Network Error'
        ELSE 'HTTP Error'
    END;
END;
GO

PRINT 'Utility functions created successfully!';

GO

-- dbo.fn_CallOpenFIGIAPI was removed as Python module now handles API calls.
-- The T-SQL stored procedure sp_LookupISINViaOpenFIGI will call a Python script.

/**
 * @description Logs API call results to database
 * @param @ISIN - ISIN code
 * @param @ResponseCode - HTTP response code
 * @param @IsSuccess - Success flag
 * @param @ErrorMessage - Error message if any
 * @param @ErrorCategory - Error category
 * @param @ResponsePayload - Full response payload
 * @param @ProcessingTimeMs - Processing time in milliseconds
 * @param @RetryAttempt - Retry attempt number
 * @purpose Centralizes API logging functionality
 */
CREATE PROCEDURE sp_LogAPICall
    @ISIN char(12),
    @ResponseCode int,
    @IsSuccess bit,
    @ErrorMessage nvarchar(1000) = NULL,
    @ErrorCategory varchar(50) = NULL,
    @ResponsePayload nvarchar(max) = NULL,
    @ProcessingTimeMs int = NULL,
    @RetryAttempt int = 1
AS
BEGIN
    INSERT INTO OpenFIGI_APILog (
        ISIN, RequestPayload, ResponsePayload, ResponseCode, IsSuccess, 
        ErrorMessage, ErrorCategory, ResponseTimestamp, ProcessingTimeMs, RetryAttempt
    )
    VALUES (
        @ISIN, '[{"idType":"ID_ISIN","idValue":"' + @ISIN + '"}]', @ResponsePayload, 
        @ResponseCode, @IsSuccess, @ErrorMessage, @ErrorCategory, GETDATE(), @ProcessingTimeMs, @RetryAttempt
    );
END;
GO

/**
 * @description Updates or inserts security data
 * @param @ISIN - ISIN code
 * @param @FIGI - FIGI code
 * @param @Ticker - Ticker symbol
 * @param @BloombergCode - Bloomberg code
 * @param @SecurityName - Security name
 * @param @SecurityType - Security type
 * @param @ExchangeCode - Exchange code
 * @param @Currency - Currency code
 * @param @DataQualityScore - Data quality score
 * @param @ProcessingAttempts - Number of processing attempts
 * @purpose Centralizes security data management
 */
CREATE PROCEDURE sp_UpsertSecurityData
    @ISIN char(12),
    @FIGI char(12) = NULL,
    @Ticker varchar(20) = NULL,
    @BloombergCode varchar(50) = NULL,
    @SecurityName nvarchar(255) = NULL,
    @SecurityType varchar(50) = NULL,
    @ExchangeCode varchar(10) = NULL,
    @Currency char(3) = NULL,
    @DataQualityScore decimal(3,2) = 0.00,
    @ProcessingAttempts int = 1
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Securities WHERE ISIN = @ISIN)
    BEGIN
        UPDATE Securities 
        SET FIGI = @FIGI,
            BloombergCode = @BloombergCode,
            Ticker = COALESCE(@Ticker, Ticker),
            SecurityName = COALESCE(@SecurityName, SecurityName),
            ExchangeCode = COALESCE(@ExchangeCode, ExchangeCode),
            Currency = COALESCE(@Currency, Currency),
            DataQualityScore = @DataQualityScore,
            LastFIGIUpdate = GETDATE(),
            ProcessingAttempts = @ProcessingAttempts,
            LastProcessingAttempt = GETDATE(),
            ModifiedDate = GETDATE()
        WHERE ISIN = @ISIN;
    END
    ELSE
    BEGIN
        INSERT INTO Securities (
            ISIN, FIGI, Ticker, BloombergCode, SecurityName, 
            SecurityType, ExchangeCode, Currency, DataQualityScore, 
            LastFIGIUpdate, ProcessingAttempts, LastProcessingAttempt
        )
        VALUES (
            @ISIN, @FIGI, @Ticker, @BloombergCode, 
            COALESCE(@SecurityName, 'Unknown'), 
            COALESCE(@SecurityType, 'UNKNOWN'), 
            @ExchangeCode, @Currency, @DataQualityScore, 
            GETDATE(), @ProcessingAttempts, GETDATE()
        );
    END
END;
GO

/**
 * @description Calculates data quality score based on available fields
 * @param @FIGI - FIGI code (30% weight)
 * @param @Ticker - Ticker symbol (20% weight)  
 * @param @BloombergCode - Bloomberg code (20% weight)
 * @param @SecurityName - Security name (15% weight)
 * @param @ExchangeCode - Exchange code (10% weight)
 * @param @Currency - Currency code (5% weight)
 * @returns decimal(3,2) - Quality score from 0.00 to 1.00
 * @purpose Provides consistent data quality scoring across the system
 */
CREATE FUNCTION dbo.fn_CalculateDataQualityScore(
    @FIGI char(12),
    @Ticker varchar(20),
    @BloombergCode varchar(50),
    @SecurityName nvarchar(255),
    @ExchangeCode varchar(10),
    @Currency char(3)
)
RETURNS decimal(3,2)
AS
BEGIN
    DECLARE @Score decimal(3,2) = 0.00;
    
    IF @FIGI IS NOT NULL SET @Score = @Score + 0.30;
    IF @Ticker IS NOT NULL SET @Score = @Score + 0.20;
    IF @BloombergCode IS NOT NULL SET @Score = @Score + 0.20;
    IF @SecurityName IS NOT NULL SET @Score = @Score + 0.15;
    IF @ExchangeCode IS NOT NULL SET @Score = @Score + 0.10;
    IF @Currency IS NOT NULL SET @Score = @Score + 0.05;
    
    RETURN @Score;
END;
GO

/**
 * @description Main ISIN lookup procedure with retry logic
 * @param @ISIN - ISIN code to lookup
 * @param @UpdateSecurityTable - Flag to update security table
 * @param @MaxRetries - Maximum number of retry attempts
 * @purpose Primary interface for ISIN lookups with comprehensive error handling
 */
CREATE PROCEDURE sp_LookupISINViaOpenFIGI
    @ISIN char(12),
    @UpdateSecurityTable bit = 0, -- This parameter is now less directly used by SP, Python script handles upsert logic.
                                 -- Kept for signature compatibility if needed by calling T-SQL.
    @MaxRetries int = 3          -- Retries for executing the Python script itself.
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate input ISIN
    IF dbo.fn_ValidateISIN(@ISIN) = 0
    BEGIN
        PRINT 'ERROR: Invalid ISIN format: ' + @ISIN;
        SELECT
            @ISIN as ISIN,
            NULL as RetrievedFIGI,
            NULL as RetrievedBloombergCode,
            NULL as RetrievedTicker,
            NULL as RetrievedSecurityName,
            NULL as RetrievedExchangeCode,
            NULL as RetrievedCurrency,
            NULL as DataQualityScore,
            0 as ResponseTimeMs, -- Default value
            0 as AttemptsUsed,
            'ERROR' as Status,
            'Invalid ISIN format' as ErrorMessage,
            'Validation Error' as ErrorCategory,
            NULL as ResponseCode;
        RETURN;
    END

    -- Temp table to store output from xp_cmdshell
    DECLARE @PythonOutput TABLE (OutputLine nvarchar(max));
    DECLARE @Cmd nvarchar(4000);
    -- IMPORTANT: Configure these paths appropriately for your environment
    -- It's recommended to store these in a configuration table or use SQL Server Agent tokens if applicable.
    DECLARE @PythonExecutablePath nvarchar(255) = N'python'; -- Or full path e.g., N'C:\Python311\python.exe'
                                                              -- Ensure this python has access to the 'apis' module and dependencies.
    DECLARE @ScriptPath nvarchar(255) = N'/app/apis/openfigi/run_figi_lookup.py'; -- Full path to your script

    DECLARE @CurrentRetry int = 1;
    DECLARE @OverallSuccess bit = 0; -- Indicates if a definitive result (success or final error) was obtained
    DECLARE @JsonOutput nvarchar(max);

    -- Variables to store parsed JSON results
    DECLARE @StatusFromJson nvarchar(50);
    DECLARE @FIGIFromJson char(12);
    DECLARE @BloombergCodeFromJson nvarchar(50);
    DECLARE @TickerFromJson nvarchar(20);
    DECLARE @SecurityNameFromJson nvarchar(255);
    DECLARE @ExchangeCodeFromJson nvarchar(10);
    DECLARE @CurrencyFromJson char(3);
    DECLARE @SecurityTypeFromJson nvarchar(50);
    DECLARE @DataQualityScoreFromJson decimal(3,2);
    DECLARE @AttemptsUsedFromJson int;
    DECLARE @ErrorMessageFromJson nvarchar(1000);
    DECLARE @ErrorCategoryFromJson nvarchar(50);
    DECLARE @ResponseCodeFromJson int;
    DECLARE @StartTime datetime2; -- For overall script execution time
    DECLARE @ResponseTimeMs int;

    WHILE @CurrentRetry <= @MaxRetries AND @OverallSuccess = 0
    BEGIN
        PRINT 'Python script execution attempt ' + CAST(@CurrentRetry AS varchar(2)) + ' for ISIN: ' + @ISIN;
        SET @StartTime = GETDATE();
        SET @Cmd = @PythonExecutablePath + N' ' + @ScriptPath + N' ' + @ISIN;

        -- Clear previous output and execute command
        DELETE FROM @PythonOutput;
        BEGIN TRY
            INSERT INTO @PythonOutput (OutputLine)
            EXEC xp_cmdshell @Cmd;

            -- Concatenate lines if output is multi-line (xp_cmdshell can split)
            -- Python script is designed to print a single JSON line to stdout.
            SELECT @JsonOutput = OutputLine FROM @PythonOutput WHERE OutputLine IS NOT NULL;
                                                                  -- AND OutputLine NOT LIKE '%Warning: Unmapped OpenFIGI securityType%' -- Filter out python print warnings

            IF @JsonOutput IS NULL OR LTRIM(RTRIM(@JsonOutput)) = '' OR LTRIM(RTRIM(@JsonOutput)) = 'NULL'
            BEGIN
                 -- Handle cases where xp_cmdshell returns NULL or empty, or if Python script had no stdout
                IF EXISTS (SELECT 1 FROM @PythonOutput WHERE OutputLine LIKE '%Traceback%')
                BEGIN
                    SELECT @ErrorMessageFromJson = COALESCE(@ErrorMessageFromJson + '; ', '') + OutputLine
                    FROM @PythonOutput WHERE OutputLine LIKE '%Traceback%' OR OutputLine LIKE '%Error:%';
                    SET @ErrorMessageFromJson = LEFT('Python script error: ' + @ErrorMessageFromJson, 1000);
                END
                ELSE
                BEGIN
                     SET @ErrorMessageFromJson = 'Python script returned no parsable output.';
                END
                SET @ErrorCategoryFromJson = 'Python Execution Error';
                SET @StatusFromJson = 'ERROR';
                PRINT 'Error: ' + @ErrorMessageFromJson;
            END
            ELSE IF ISJSON(@JsonOutput) = 1
            BEGIN
                -- Parse the JSON output from Python
                SELECT
                    @StatusFromJson         = JSON_VALUE(@JsonOutput, '$.status'),
                    @FIGIFromJson           = JSON_VALUE(@JsonOutput, '$.figi'),
                    @BloombergCodeFromJson  = JSON_VALUE(@JsonOutput, '$.bloomberg_code'),
                    @TickerFromJson         = JSON_VALUE(@JsonOutput, '$.ticker'),
                    @SecurityNameFromJson   = JSON_VALUE(@JsonOutput, '$.security_name'),
                    @ExchangeCodeFromJson   = JSON_VALUE(@JsonOutput, '$.exchange_code'),
                    @CurrencyFromJson       = JSON_VALUE(@JsonOutput, '$.currency'),
                    @SecurityTypeFromJson   = JSON_VALUE(@JsonOutput, '$.security_type'),
                    @DataQualityScoreFromJson = TRY_CAST(JSON_VALUE(@JsonOutput, '$.data_quality_score') AS decimal(3,2)),
                    @AttemptsUsedFromJson   = TRY_CAST(JSON_VALUE(@JsonOutput, '$.attempts_used') AS int),
                    @ErrorMessageFromJson   = JSON_VALUE(@JsonOutput, '$.error_message'),
                    @ErrorCategoryFromJson  = JSON_VALUE(@JsonOutput, '$.error_category'),
                    @ResponseCodeFromJson   = TRY_CAST(JSON_VALUE(@JsonOutput, '$.response_code') AS int);

                IF @StatusFromJson = 'SUCCESS'
                BEGIN
                    SET @OverallSuccess = 1;
                    PRINT 'Python script SUCCESS - FIGI: ' + ISNULL(@FIGIFromJson, 'N/A') + ', DQ: ' + ISNULL(CAST(@DataQualityScoreFromJson AS varchar(5)), 'N/A');
                END
                ELSE IF @StatusFromJson = 'NO_DATA' -- No data found by FIGI is a final state
                BEGIN
                    SET @OverallSuccess = 1;
                    PRINT 'Python script NO_DATA - ' + @ErrorMessageFromJson;
                END
                ELSE -- Status is ERROR or other from Python
                BEGIN
                     PRINT 'Python script returned ERROR status: ' + ISNULL(@ErrorMessageFromJson, 'Unknown Python Error');
                     -- If error is not retryable from Python's perspective, or if we want SP to decide retries
                     IF @ErrorCategoryFromJson NOT IN ('Rate Limited', 'Server Error', 'Network Error') OR @CurrentRetry >= @MaxRetries
                     BEGIN
                        SET @OverallSuccess = 1; -- Mark as overall success to stop retrying SP call
                     END
                END
            END
            ELSE
            BEGIN
                SET @StatusFromJson = 'ERROR';
                SET @ErrorMessageFromJson = 'Invalid JSON output from Python script: ' + LEFT(@JsonOutput, 500);
                SET @ErrorCategoryFromJson = 'Python JSON Error';
                PRINT @ErrorMessageFromJson;
                SET @OverallSuccess = 1; -- Stop retrying if output is fundamentally broken
            END
        END TRY
        BEGIN CATCH
            SET @StatusFromJson = 'ERROR';
            SET @ErrorMessageFromJson = 'xp_cmdshell execution failed: ' + ERROR_MESSAGE();
            SET @ErrorCategoryFromJson = 'xp_cmdshell Error';
            PRINT @ErrorMessageFromJson;
            -- If xp_cmdshell itself fails, it might be retryable depending on the error
            IF @CurrentRetry >= @MaxRetries SET @OverallSuccess = 1;
        END CATCH

        SET @ResponseTimeMs = DATEDIFF(MILLISECOND, @StartTime, GETDATE());

        -- If not a definitive success/final error from Python, and retries remain, retry script execution
        IF @OverallSuccess = 0 AND @CurrentRetry < @MaxRetries
        BEGIN
            PRINT 'Python script execution issue, retrying in 3 seconds...';
            WAITFOR DELAY '00:00:03';
            SET @CurrentRetry = @CurrentRetry + 1;
        END
        ELSE
        BEGIN
            SET @OverallSuccess = 1; -- Ensure loop terminates
        END
    END -- End WHILE retry loop

    -- Return results based on the outcome of Python script execution
    SELECT
        @ISIN as ISIN,
        @FIGIFromJson as RetrievedFIGI,
        @BloombergCodeFromJson as RetrievedBloombergCode,
        @TickerFromJson as RetrievedTicker,
        @SecurityNameFromJson as RetrievedSecurityName,
        @ExchangeCodeFromJson as RetrievedExchangeCode,
        @CurrencyFromJson as RetrievedCurrency,
        @DataQualityScoreFromJson as DataQualityScore,
        @ResponseTimeMs as ResponseTimeMs, -- This is now overall script exec time for the last attempt
        @AttemptsUsedFromJson as AttemptsUsed, -- This is attempts from Python's internal retry for API
        @StatusFromJson as Status,
        @ErrorMessageFromJson as ErrorMessage,
        @ErrorCategoryFromJson as ErrorCategory,
        @ResponseCodeFromJson as ResponseCode;

END;
GO

/**
 * @description Comprehensive securities view with quality metrics
 * @purpose Provides easy access to securities data with status indicators
 */
CREATE VIEW vw_SecuritiesWithQuality AS
SELECT 
    SecurityID, ISIN, FIGI, Ticker, BloombergCode, SecurityName, SecurityType,
    ExchangeCode, Currency, Country, DataQualityScore, IsActive, LastFIGIUpdate,
    ProcessingAttempts, LastProcessingAttempt,
    CASE 
        WHEN DataQualityScore >= 0.80 THEN 'Excellent'
        WHEN DataQualityScore >= 0.60 THEN 'Good'
        WHEN DataQualityScore >= 0.40 THEN 'Fair'
        WHEN DataQualityScore > 0.00 THEN 'Poor'
        ELSE 'No Data'
    END as QualityRating,
    CASE 
        WHEN FIGI IS NOT NULL AND BloombergCode IS NOT NULL THEN 'Complete'
        WHEN FIGI IS NOT NULL THEN 'Partial'
        ELSE 'Missing'
    END as DataStatus
FROM Securities
WHERE IsActive = 1;
GO

PRINT '=====================================================================';
PRINT 'SUCCESS! OpenFIGI Main Database completed successfully!';
PRINT '';
PRINT 'Test Commands:';
PRINT '1. EXEC sp_LookupISINViaOpenFIGI @ISIN = ''US0378331005'', @UpdateSecurityTable = 1;';
PRINT '2. SELECT * FROM vw_SecuritiesWithQuality;';
PRINT '3. SELECT * FROM vw_DataQualityDistribution;';
PRINT '=====================================================================';
GO


/**
 * Testing commit
 */