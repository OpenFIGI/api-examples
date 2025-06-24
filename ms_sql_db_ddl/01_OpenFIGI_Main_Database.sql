-- =====================================================================
-- FILE 1: 01_OpenFIGI_Main_Database.sql
-- PURPOSE: Modular OpenFIGI integration with comprehensive validation
-- =====================================================================

-- USE [database_name];
-- GO

/**
 * @description Enables OLE Automation for HTTP API calls
 * @purpose Required for making external HTTP requests to OpenFIGI API
 */
PRINT 'Enabling OLE Automation for HTTP requests...';
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;
PRINT 'OLE Automation enabled successfully!';
GO

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

/**
 * @description Makes HTTP request to OpenFIGI API
 * @param @ISIN - ISIN code to lookup
 * @param @RetryAttempt - Current retry attempt number
 * @returns Table with API response data
 * @purpose Encapsulates OpenFIGI API communication logic
 */
CREATE FUNCTION dbo.fn_CallOpenFIGIAPI(@ISIN char(12), @RetryAttempt int = 1)
RETURNS @Result TABLE (
    FIGI char(12),
    Ticker varchar(20),
    SecurityName nvarchar(255),
    ExchangeCode varchar(10),
    Currency char(3),
    SecurityType varchar(50),
    IsSuccess bit,
    ErrorMessage nvarchar(1000),
    ErrorCategory varchar(50),
    ResponseCode int,
    ResponsePayload nvarchar(max)
)
AS
BEGIN
    -- Validate input
    IF dbo.fn_ValidateISIN(@ISIN) = 0
    BEGIN
        INSERT INTO @Result VALUES (NULL, NULL, NULL, NULL, NULL, NULL, 0, 'Invalid ISIN format', 'Validation Error', 0, NULL);
        RETURN;
    END

    DECLARE @HTTPObject int;
    DECLARE @ResponseText nvarchar(max);
    DECLARE @ResponseCode int;
    DECLARE @IsSuccess bit = 0;
    DECLARE @ErrorMessage nvarchar(1000);
    DECLARE @ErrorCategory varchar(50);
    
    BEGIN TRY
        -- Create and configure HTTP object
        EXEC sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @HTTPObject OUT;
        EXEC sp_OAMethod @HTTPObject, 'open', NULL, 'POST', 'https://api.openfigi.com/v3/mapping', 'false';
        EXEC sp_OAMethod @HTTPObject, 'setRequestHeader', NULL, 'Content-Type', 'application/json';
        EXEC sp_OAMethod @HTTPObject, 'setRequestHeader', NULL, 'X-OPENFIGI-APIKEY', 'edda2f69-53b3-42d9-b832-f6dda111af67';
        
        -- Send request
        DECLARE @RequestPayload nvarchar(max) = '[{"idType":"ID_ISIN","idValue":"' + @ISIN + '"}]';
        EXEC sp_OAMethod @HTTPObject, 'send', NULL, @RequestPayload;
        
        -- Get response
        EXEC sp_OAGetProperty @HTTPObject, 'status', @ResponseCode OUT;
        EXEC sp_OAGetProperty @HTTPObject, 'responseText', @ResponseText OUT;
        EXEC sp_OADestroy @HTTPObject;
        
        IF @ResponseCode = 200
        BEGIN
            SET @IsSuccess = 1;
            
            -- Parse JSON response using utility function
            DECLARE @FIGI char(12) = dbo.fn_ExtractJSONField(@ResponseText, 'figi');
            DECLARE @Ticker varchar(20) = dbo.fn_ExtractJSONField(@ResponseText, 'ticker');
            DECLARE @SecurityName nvarchar(255) = dbo.fn_ExtractJSONField(@ResponseText, 'name');
            DECLARE @ExchangeCode varchar(10) = dbo.fn_ExtractJSONField(@ResponseText, 'exchCode');
            DECLARE @Currency char(3) = dbo.fn_ExtractJSONField(@ResponseText, 'currency');
            DECLARE @SecurityType varchar(50) = dbo.fn_ExtractJSONField(@ResponseText, 'securityType');
            
            -- Validate extracted data
            IF @FIGI IS NOT NULL AND dbo.fn_ValidateFIGI(@FIGI) = 0 SET @FIGI = NULL;
            IF @Ticker IS NOT NULL AND dbo.fn_ValidateTickerLength(@Ticker) = 0 SET @Ticker = NULL;
            IF @SecurityName IS NOT NULL AND dbo.fn_ValidateSecurityName(@SecurityName) = 0 SET @SecurityName = NULL;
            IF @ExchangeCode IS NOT NULL AND dbo.fn_ValidateExchangeCode(@ExchangeCode) = 0 SET @ExchangeCode = NULL;
            IF @Currency IS NOT NULL AND dbo.fn_ValidateCurrencyCode(@Currency) = 0 SET @Currency = NULL;
            
            INSERT INTO @Result VALUES (@FIGI, @Ticker, @SecurityName, @ExchangeCode, @Currency, @SecurityType, @IsSuccess, NULL, NULL, @ResponseCode, @ResponseText);
        END
        ELSE
        BEGIN
            SET @ErrorCategory = dbo.fn_CategorizeAPIError(@ResponseCode);
            SET @ErrorMessage = 'HTTP Error ' + CAST(@ResponseCode AS varchar(10));
            INSERT INTO @Result VALUES (NULL, NULL, NULL, NULL, NULL, NULL, 0, @ErrorMessage, @ErrorCategory, @ResponseCode, @ResponseText);
        END
        
    END TRY
    BEGIN CATCH
        IF @HTTPObject IS NOT NULL EXEC sp_OADestroy @HTTPObject;
        SET @ErrorMessage = ERROR_MESSAGE();
        SET @ErrorCategory = 'Network Error';
        INSERT INTO @Result VALUES (NULL, NULL, NULL, NULL, NULL, NULL, 0, @ErrorMessage, @ErrorCategory, 0, NULL);
    END CATCH
    
    RETURN;
END;
GO

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
    @UpdateSecurityTable bit = 0,
    @MaxRetries int = 3
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate input
    IF dbo.fn_ValidateISIN(@ISIN) = 0
    BEGIN
        PRINT 'ERROR: Invalid ISIN format: ' + @ISIN;
        SELECT @ISIN as ISIN, 'ERROR' as Status, 'Invalid ISIN format' as ErrorMessage;
        RETURN;
    END
    
    DECLARE @StartTime datetime2 = GETDATE();
    DECLARE @CurrentRetry int = 1;
    DECLARE @Success bit = 0;
    
    -- Retry loop
    WHILE @CurrentRetry <= @MaxRetries AND @Success = 0
    BEGIN
        PRINT 'Lookup attempt ' + CAST(@CurrentRetry AS varchar(2)) + ' for ISIN: ' + @ISIN;
        
        BEGIN TRY
            -- Call API
            DECLARE @APIResult TABLE (
                FIGI char(12), Ticker varchar(20), SecurityName nvarchar(255),
                ExchangeCode varchar(10), Currency char(3), SecurityType varchar(50),
                IsSuccess bit, ErrorMessage nvarchar(1000), ErrorCategory varchar(50),
                ResponseCode int, ResponsePayload nvarchar(max)
            );
            
            INSERT INTO @APIResult SELECT * FROM dbo.fn_CallOpenFIGIAPI(@ISIN, @CurrentRetry);
            
            -- Process results
            DECLARE @FIGI char(12), @Ticker varchar(20), @SecurityName nvarchar(255);
            DECLARE @ExchangeCode varchar(10), @Currency char(3), @SecurityType varchar(50);
            DECLARE @IsSuccess bit, @ErrorMessage nvarchar(1000), @ErrorCategory varchar(50);
            DECLARE @ResponseCode int, @ResponsePayload nvarchar(max);
            
            SELECT @FIGI = FIGI, @Ticker = Ticker, @SecurityName = SecurityName,
                   @ExchangeCode = ExchangeCode, @Currency = Currency, @SecurityType = SecurityType,
                   @IsSuccess = IsSuccess, @ErrorMessage = ErrorMessage, @ErrorCategory = ErrorCategory,
                   @ResponseCode = ResponseCode, @ResponsePayload = ResponsePayload
            FROM @APIResult;
            
            DECLARE @ResponseTime int = DATEDIFF(MILLISECOND, @StartTime, GETDATE());
            DECLARE @BloombergCode varchar(50) = dbo.fn_BuildBloombergCode(@Ticker, @ExchangeCode, @SecurityType);
            DECLARE @DataQuality decimal(3,2) = dbo.fn_CalculateDataQualityScore(@FIGI, @Ticker, @BloombergCode, @SecurityName, @ExchangeCode, @Currency);
            
            -- Log API call
            EXEC sp_LogAPICall @ISIN, @ResponseCode, @IsSuccess, @ErrorMessage, @ErrorCategory, @ResponsePayload, @ResponseTime, @CurrentRetry;
            
            IF @IsSuccess = 1
            BEGIN
                SET @Success = 1;
                PRINT 'SUCCESS - Quality Score: ' + CAST(@DataQuality AS varchar(5));
                
                -- Update security table if requested
                IF @UpdateSecurityTable = 1
                BEGIN
                    EXEC sp_UpsertSecurityData @ISIN, @FIGI, @Ticker, @BloombergCode, @SecurityName, @SecurityType, @ExchangeCode, @Currency, @DataQuality, @CurrentRetry;
                END
                
                -- Return success results
                SELECT @ISIN as ISIN, @FIGI as RetrievedFIGI, @BloombergCode as RetrievedBloombergCode,
                       @Ticker as RetrievedTicker, @SecurityName as RetrievedSecurityName,
                       @ExchangeCode as RetrievedExchangeCode, @Currency as RetrievedCurrency,
                       @DataQuality as DataQualityScore, @ResponseTime as ResponseTimeMs,
                       @CurrentRetry as AttemptsUsed, 'SUCCESS' as Status;
            END
            ELSE
            BEGIN
                -- Handle retries for specific error types
                IF @ErrorCategory IN ('Rate Limited', 'Server Error', 'Network Error') AND @CurrentRetry < @MaxRetries
                BEGIN
                    PRINT 'Retryable error, waiting 5 seconds...';
                    WAITFOR DELAY '00:00:05';
                    SET @CurrentRetry = @CurrentRetry + 1;
                END
                ELSE
                BEGIN
                    SET @Success = 1;
                    SELECT @ISIN as ISIN, 'ERROR' as Status, @ErrorMessage as ErrorMessage,
                           @ErrorCategory as ErrorCategory, @ResponseCode as ResponseCode, @CurrentRetry as AttemptsUsed;
                END
            END
            
        END TRY
        BEGIN CATCH
            DECLARE @CatchError nvarchar(4000) = ERROR_MESSAGE();
            EXEC sp_LogAPICall @ISIN, 0, 0, @CatchError, 'Processing Error', NULL, NULL, @CurrentRetry;
            
            IF @CurrentRetry < @MaxRetries
            BEGIN
                PRINT 'Processing error, retrying...';
                SET @CurrentRetry = @CurrentRetry + 1;
                WAITFOR DELAY '00:00:03';
            END
            ELSE
            BEGIN
                SELECT @ISIN as ISIN, 'ERROR' as Status, @CatchError as ErrorMessage,
                       'Processing Error' as ErrorCategory, @CurrentRetry as AttemptsUsed;
                RETURN;
            END
        END CATCH
    END
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