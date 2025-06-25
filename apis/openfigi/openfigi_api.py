# apis/openfigi/openfigi_api.py

import requests  # For making HTTP requests
import pyodbc    # For database interaction (assuming SQL Server)
import json      # For handling JSON data
import datetime  # For timestamps
import os        # For environment variables (e.g., API key, DB connection)
import time      # For retry delays

# --- Database Connection ---
DB_SERVER = os.environ.get("DB_SERVER", "your_server_name") # User should set this
DB_NAME = os.environ.get("DB_NAME", "your_database_name")   # User should set this
DB_USER = os.environ.get("DB_USER")
DB_PASSWORD = os.environ.get("DB_PASSWORD")
OPENFIGI_API_KEY = os.environ.get("OPENFIGI_API_KEY", "DEFAULT_KEY_IF_NOT_SET") # User should set this
OPENFIGI_API_URL = os.environ.get("OPENFIGI_API_URL", "https://api.openfigi.com/v3/mapping")
RETRY_DELAY_SECONDS = 2 # Default delay for retries

def get_db_connection():
    """
    Establishes and returns a database connection.
    Uses Windows Authentication if DB_USER and DB_PASSWORD are not provided.
    """
    # Prioritize fully specified connection string if provided
    conn_str_env = os.environ.get("DB_CONNECTION_STRING")
    if conn_str_env:
        return pyodbc.connect(conn_str_env)

    if not DB_SERVER or DB_SERVER == "your_server_name" or not DB_NAME or DB_NAME == "your_database_name":
        raise ValueError("DB_SERVER and DB_NAME environment variables must be set to valid values.")

    conn_str_parts = [
        f"DRIVER={{ODBC Driver 17 for SQL Server}}", # Common modern driver
        f"SERVER={DB_SERVER}",
        f"DATABASE={DB_NAME}",
    ]
    if DB_USER and DB_PASSWORD:
        conn_str_parts.append(f"UID={DB_USER}")
        conn_str_parts.append(f"PWD={DB_PASSWORD}")
    elif DB_USER and not DB_PASSWORD: # User specified, but no password (e.g. some trusted scenarios or prompt)
         conn_str_parts.append(f"UID={DB_USER}")
         conn_str_parts.append("Trusted_Connection=No") # Explicitly not trusted if user is given
    else: # No user, no password implies trusted connection
        conn_str_parts.append("Trusted_Connection=yes")

    return pyodbc.connect(";".join(conn_str_parts))

# --- Validation Functions ---

def validate_isin(isin: str) -> bool:
    """
    Validates ISIN format according to ISO 6166 standard.
    """
    if not isinstance(isin, str) or len(isin) != 12:
        return False
    if not (isin[0:2].isalpha() and isin[0:2].isupper()):
        return False
    # Python's isalnum() is fine, but SQL's LIKE '[A-Z0-9]' is more specific for uppercase.
    # We'll enforce uppercase for the alphanumeric part as per common FIGI/ISIN standards.
    if not (isin[2:11].isalnum()): # Check if all chars in this slice are either letters or digits
        return False
    for char_val in isin[2:11]: # Then ensure they are uppercase if they are letters
        if char_val.isalpha() and not char_val.isupper():
            return False

    if not isin[11].isdigit():
        return False
    return True

def validate_figi(figi: str) -> bool:
    """
    Validates FIGI format (Bloomberg Global Identifier).
    """
    if not isinstance(figi, str) or len(figi) != 12:
        return False
    if not figi.startswith("BBG"):
        return False
    # Ensure remaining 9 characters are uppercase alphanumeric
    if not (figi[3:].isalnum()):
        return False
    for char_val in figi[3:]:
        if char_val.isalpha() and not char_val.isupper():
            return False
    return True

def validate_currency_code(currency_code: str) -> bool:
    """
    Validates currency code against a list of common ISO 4217 codes.
    """
    if not isinstance(currency_code, str) or len(currency_code) != 3:
        return False
    common_currencies = [
        'USD', 'EUR', 'GBP', 'JPY', 'CHF', 'CAD', 'AUD', 'NZD', 'SEK', 'NOK',
        'DKK', 'PLN', 'CZK', 'HUF', 'RUB', 'CNY', 'HKD', 'SGD', 'KRW', 'INR',
        'BRL', 'MXN', 'ZAR', 'TRY', 'ILS', 'THB', 'MYR', 'IDR', 'PHP', 'VND',
        'TWD', 'SAR', 'AED', 'QAR', 'KWD', 'BHD', 'OMR', 'JOD', 'LBP', 'EGP',
        'MAD', 'TND', 'DZD', 'NGN', 'GHS', 'KES', 'UGX', 'TZS', 'ZMW', 'BWP',
        'CLP', 'COP', 'PEN', 'ARS', 'UYU', 'PYG', 'BOB', 'VES', 'GYD', 'SRD'
    ]
    return currency_code.upper() in common_currencies

def validate_ticker_length(ticker: str) -> bool:
    """
    Validates ticker symbol format and length.
    """
    if ticker is None or not isinstance(ticker, str):
        return False
    ticker = ticker.strip()
    if not (0 < len(ticker) <= 20):
        return False
    if not all(c.isalnum() or c in ['.', '-'] for c in ticker):
        return False
    return True

def validate_security_name(name: str) -> bool:
    """
    Validates security name format and length.
    """
    if name is None or not isinstance(name, str):
        return False
    name = name.strip()
    return 0 < len(name) <= 255

def validate_exchange_code(exchange_code: str) -> bool:
    """
    Validates exchange code format.
    """
    if exchange_code is None or not isinstance(exchange_code, str):
        return False
    exchange_code = exchange_code.strip()
    if not (0 < len(exchange_code) <= 10):
        return False
    if len(exchange_code) < 2 or not (exchange_code[0].isalpha() and exchange_code[1].isalpha()):
        return False
    return True

# --- Core API and Database Interaction Functions ---

def call_openfigi_api_v3(isin: str, api_key: str | None = None) -> tuple[int, dict | list | None, str | None]:
    """
    Makes an HTTP POST request to the OpenFIGI API v3 /mapping endpoint.
    """
    effective_api_key = api_key or OPENFIGI_API_KEY
    if not effective_api_key or effective_api_key == "DEFAULT_KEY_IF_NOT_SET":
        return 0, None, "OpenFIGI API key is not configured."

    if not validate_isin(isin):
        return 400, None, "Invalid ISIN format for API call"

    headers = {
        'Content-Type': 'application/json',
        'X-OPENFIGI-APIKEY': effective_api_key
    }
    payload = [{"idType": "ID_ISIN", "idValue": isin}]

    response_obj_for_status = None

    try:
        response = requests.post(OPENFIGI_API_URL, headers=headers, json=payload, timeout=10)
        response_obj_for_status = response

        response_json = None
        try:
            response_json = response.json()
        except json.JSONDecodeError:
            response.raise_for_status()
            return response.status_code, None, "Failed to decode JSON response from OpenFIGI for a 200 OK."

        response.raise_for_status()

        if response_json and isinstance(response_json, list) and len(response_json) > 0:
            first_result = response_json[0]
            if 'data' in first_result and first_result['data'] and isinstance(first_result['data'], list) and first_result['data'][0]:
                return response.status_code, first_result['data'][0], None
            elif 'warning' in first_result:
                return response.status_code, {"warning": first_result['warning']}, None
            elif 'error' in first_result:
                return response.status_code, None, first_result['error']
            else:
                return response.status_code, None, "No data found for ISIN or unexpected response structure"
        else:
            return response.status_code, None, "Empty or invalid response structure from OpenFIGI"

    except requests.exceptions.HTTPError as http_err:
        status_code_to_report = http_err.response.status_code if http_err.response is not None else (response_obj_for_status.status_code if response_obj_for_status is not None else 500)

        error_message_detail = str(http_err)
        try:
            if http_err.response is not None and http_err.response.content:
                err_json = http_err.response.json()
                if isinstance(err_json, list) and len(err_json) > 0 and err_json[0].get('error'):
                    error_message_detail = err_json[0]['error']
                elif isinstance(err_json, dict) and err_json.get('message'):
                     error_message_detail = err_json['message']
        except json.JSONDecodeError:
            pass
        except Exception:
            pass

        return status_code_to_report, None, f"HTTP error: {error_message_detail}"

    except requests.exceptions.RequestException as req_err:
        return 0, None, f"Request exception: {req_err}"
    except Exception as e:
        return 500, None, f"An unexpected error occurred: {str(e)}"


def log_api_call(
    isin: str,
    request_payload: str,
    response_payload: dict | list | None,
    response_code: int,
    is_success: bool,
    error_message: str | None = None,
    error_category: str | None = None,
    processing_time_ms: int | None = None,
    retry_attempt: int = 1
) -> int | None:
    """
    Logs the API call details to the OpenFIGI_APILog table.
    Returns LogID (int) if successful, None otherwise.
    """
    sql = """
    INSERT INTO OpenFIGI_APILog (
        ISIN, RequestPayload, ResponsePayload, ResponseCode, IsSuccess,
        ErrorMessage, ErrorCategory, ResponseTimestamp, ProcessingTimeMs, RetryAttempt
    )
    OUTPUT INSERTED.LogID
    VALUES (?, ?, ?, ?, ?, ?, ?, GETDATE(), ?, ?);
    """
    response_payload_str = None
    if response_payload is not None:
        try:
            response_payload_str = json.dumps(response_payload)
        except TypeError:
            response_payload_str = str(response_payload)

    try:
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute(
                    sql,
                    isin,
                    request_payload,
                    response_payload_str,
                    response_code,
                    is_success,
                    error_message,
                    error_category,
                    processing_time_ms,
                    retry_attempt
                )
                log_id_row = cursor.fetchone()
                if log_id_row:
                    conn.commit()
                    return log_id_row[0]
                conn.rollback()
                return None
    except pyodbc.Error as db_err:
        print(f"Database error in log_api_call for ISIN {isin}: {db_err}")
        return None
    except Exception as e:
        print(f"Unexpected error in log_api_call for ISIN {isin}: {e}")
        return None


def upsert_security_data(
    isin: str,
    figi: str | None = None,
    ticker: str | None = None,
    bloomberg_code: str | None = None,
    security_name: str | None = None,
    security_type: str | None = None,
    exchange_code: str | None = None,
    currency: str | None = None,
    data_quality_score: float = 0.00,
    processing_attempts: int = 1
) -> bool:
    """
    Updates or inserts security data into the Securities table.
    Returns True if successful, False otherwise.
    """
    v_figi = figi if figi and validate_figi(figi) else None
    v_ticker = ticker.strip().upper() if ticker and validate_ticker_length(ticker) else None
    v_security_name = security_name.strip() if security_name and validate_security_name(security_name) else "Unknown"
    v_exchange_code = exchange_code.strip().upper() if exchange_code and validate_exchange_code(exchange_code) else None
    v_currency = currency.strip().upper() if currency and validate_currency_code(currency) else None

    allowed_db_security_types = ['EQUITY', 'BOND', 'DERIVATIVE', 'FUND', 'INDEX', 'CURRENCY', 'COMMODITY', 'UNKNOWN']
    v_security_type = security_type.upper() if security_type and security_type.upper() in allowed_db_security_types else 'UNKNOWN'

    v_bloomberg_code = bloomberg_code

    try:
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("SELECT SecurityID FROM Securities WHERE ISIN = ?", isin)
                row = cursor.fetchone()
                exists = bool(row)

                if exists:
                    sql_update = """
                    UPDATE Securities
                    SET FIGI = ?, BloombergCode = ?, Ticker = COALESCE(?, Ticker),
                        SecurityName = COALESCE(?, SecurityName), ExchangeCode = COALESCE(?, ExchangeCode),
                        Currency = COALESCE(?, Currency), DataQualityScore = ?,
                        LastFIGIUpdate = GETDATE(), ProcessingAttempts = ?,
                        LastProcessingAttempt = GETDATE(), ModifiedDate = GETDATE(),
                        SecurityType = COALESCE(?, SecurityType)
                    WHERE ISIN = ?;
                    """
                    cursor.execute(sql_update, v_figi, v_bloomberg_code, v_ticker, v_security_name,
                                   v_exchange_code, v_currency, data_quality_score,
                                   processing_attempts, v_security_type, isin)
                else:
                    sql_insert = """
                    INSERT INTO Securities (
                        ISIN, FIGI, Ticker, BloombergCode, SecurityName,
                        SecurityType, ExchangeCode, Currency, DataQualityScore,
                        LastFIGIUpdate, ProcessingAttempts, LastProcessingAttempt, CreatedDate, ModifiedDate
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, GETDATE(), ?, GETDATE(), GETDATE(), GETDATE());
                    """
                    cursor.execute(sql_insert, isin, v_figi, v_ticker, v_bloomberg_code,
                                   v_security_name, v_security_type, v_exchange_code, v_currency,
                                   data_quality_score, processing_attempts)
                conn.commit()
                return True
    except pyodbc.Error as db_err:
        print(f"Database error in upsert_security_data for ISIN {isin}: {db_err}")
        return False
    except Exception as e:
        print(f"Unexpected error in upsert_security_data for ISIN {isin}: {e}")
        return False

# --- Helper/Utility Functions ---

def build_bloomberg_code(ticker: str | None, exchange_code: str | None, security_type: str | None) -> str | None:
    """
    Builds a Bloomberg terminal code. `security_type` is the mapped DB type e.g. 'EQUITY'.
    """
    if not (ticker and validate_ticker_length(ticker)) or \
       not (exchange_code and validate_exchange_code(exchange_code)):
        return None

    sec_type_to_bbg_suffix_map = {
        'EQUITY': 'Equity',
        'BOND': 'Corp',
        'CORP': 'Corp', # Handle direct "CORP" input
        'GOVT': 'Govt',
        'FUND': 'Equity',
        'INDEX': 'Index',
        'CURRENCY': 'Curncy',
        'COMMODITY': 'Comdty',
        'UNKNOWN': 'Equity'
    }
    bbg_suffix = sec_type_to_bbg_suffix_map.get(security_type.upper() if security_type else "UNKNOWN", 'Equity')

    return f"{ticker.strip().upper()} {exchange_code.strip().upper()} {bbg_suffix}"


def calculate_data_quality_score(
    figi: str | None,
    ticker: str | None,
    bloomberg_code: str | None,
    security_name: str | None,
    exchange_code: str | None,
    currency: str | None
) -> float:
    """
    Calculates data quality score.
    """
    score = 0.00
    if figi and validate_figi(figi): score += 0.30
    if ticker and validate_ticker_length(ticker): score += 0.20
    if bloomberg_code: score += 0.20
    if security_name and validate_security_name(security_name) and security_name.lower() != "unknown": score += 0.15
    if exchange_code and validate_exchange_code(exchange_code): score += 0.10
    if currency and validate_currency_code(currency): score += 0.05

    return round(score, 2)

def categorize_api_error(response_code: int | None) -> str:
    """
    Categorizes API errors based on HTTP response code.
    """
    if response_code is None: return 'Unknown Error'
    if response_code == 400: return 'Bad Request'
    if response_code == 401: return 'Unauthorized'
    if response_code == 403: return 'Forbidden'
    if response_code == 404: return 'Not Found'
    if response_code == 429: return 'Rate Limited'
    if response_code >= 500 and response_code <= 599: return 'Server Error'
    if response_code == 0: return 'Network Error'
    if response_code >= 400 and response_code <= 499 : return 'Client Error'
    return 'HTTP Error'

# --- Main Orchestration Function ---

def lookup_isin_and_update_db(
    isin: str,
    max_retries: int = 3,
    initial_retry_attempt: int = 1
) -> dict:
    """
    Looks up an ISIN via OpenFIGI, logs, updates DB. Handles retries.
    """
    if not validate_isin(isin):
        return {
            "isin": isin, "status": "ERROR", "error_message": "Invalid ISIN format",
            "error_category": "Validation Error", "attempts_used": 0,
            "figi": None, "bloomberg_code": None, "ticker": None, "security_name": None,
            "exchange_code": None, "currency": None, "security_type": None,
            "data_quality_score": None, "response_code": None
        }

    current_loop_attempt = 0
    actual_log_attempt_number = initial_retry_attempt

    api_response_status_code = None
    api_response_data = None
    api_error_message = None

    while current_loop_attempt < max_retries:
        attempt_start_time = datetime.datetime.now()
        request_payload_for_log = json.dumps([{"idType": "ID_ISIN", "idValue": isin}])

        _resp_status, _resp_data_or_warning, _resp_error_msg_str = call_openfigi_api_v3(isin)

        api_response_status_code = _resp_status

        if _resp_status == 200 and _resp_data_or_warning and 'figi' in _resp_data_or_warning :
            api_response_data = _resp_data_or_warning # Actual data
            api_error_message = None
        elif _resp_status == 200 and _resp_data_or_warning and 'warning' in _resp_data_or_warning:
            api_response_data = _resp_data_or_warning # Warning structure
            api_error_message = _resp_data_or_warning['warning']
        elif _resp_error_msg_str:
            api_error_message = _resp_error_msg_str
            api_response_data = None
        else:
            api_error_message = "Unexpected outcome from call_openfigi_api_v3"
            api_response_data = None


        attempt_end_time = datetime.datetime.now()
        processing_time_ms = int((attempt_end_time - attempt_start_time).total_seconds() * 1000)

        is_log_success = False
        error_category_for_log = None

        # Determine log success and error category
        if api_response_status_code == 200:
            is_log_success = True
            if api_response_data and 'figi' in api_response_data:
                error_category_for_log = None
            elif api_response_data and 'warning' in api_response_data:
                error_category_for_log = "No Data"
            elif api_error_message: # Error from FIGI in 200 response, or anomaly
                is_log_success = False
                error_category_for_log = "OpenFIGI Error" # Default if error in 200
                if not (api_response_data and ('warning' in api_response_data or 'figi' in api_response_data)): # Check if it's not a warning/data case
                     error_category_for_log = "API Anomaly" if not api_error_message.startswith("Invalid query") else "OpenFIGI Error" # Refine based on tests
            else: # Should not be reached if logic is sound
                is_log_success = False
                error_category_for_log = "API Anomaly"
        else:
            is_log_success = False
            error_category_for_log = categorize_api_error(api_response_status_code)

        # Determine what to log as response_payload for the log table
        payload_for_db_log = None
        if api_response_data and ('figi' in api_response_data or 'warning' in api_response_data):
            payload_for_db_log = api_response_data
        else: # Error or unexpected structure
            payload_for_db_log = {"error_detail": api_error_message, "response_code": api_response_status_code}

        log_api_call(
            isin, request_payload_for_log, payload_for_db_log,
            api_response_status_code or 0,
            is_log_success,
            api_error_message if not (api_response_data and 'figi' in api_response_data) else None,
            error_category_for_log,
            processing_time_ms,
            actual_log_attempt_number
        )

        if api_response_data and 'figi' in api_response_data:
            break
        if api_response_data and 'warning' in api_response_data:
            break
        # If FIGI itself returned an error message within a 200 response (e.g. "Invalid Query")
        # This was captured in api_error_message and error_category_for_log would be "OpenFIGI Error"
        if error_category_for_log == "OpenFIGI Error":
            break

        retryable_categories = ['Rate Limited', 'Server Error', 'Network Error']
        if error_category_for_log in retryable_categories and (current_loop_attempt + 1) < max_retries:
            time.sleep(RETRY_DELAY_SECONDS * (current_loop_attempt + 1))
            current_loop_attempt += 1
            actual_log_attempt_number +=1
        else:
            break

    final_attempts_used = actual_log_attempt_number

    if api_response_data and 'figi' in api_response_data:
        figi_val = api_response_data.get('figi')
        ticker_val = api_response_data.get('ticker')
        name_val = api_response_data.get('name')
        exch_code_val = api_response_data.get('exchCode')
        currency_val = api_response_data.get('currency')
        raw_sec_type_val = api_response_data.get('securityType')

        security_type_map_to_db = {
            "COMMON STOCK": "EQUITY", "PREFERRED STOCK": "EQUITY", "ADR": "EQUITY",
            "CORP": "BOND", "GOVERNMENT BOND": "BOND", "MUNI": "BOND",
            "MUTUAL FUND": "FUND", "ETF": "FUND", "ETP": "FUND",
            "INDEX": "INDEX", "CURRENCY": "CURRENCY", "COMMODITY": "COMMODITY",
            "POOL": "BOND",
        }
        db_security_type = security_type_map_to_db.get(str(raw_sec_type_val).upper() if raw_sec_type_val else "", "UNKNOWN")
        if raw_sec_type_val and db_security_type == "UNKNOWN" and str(raw_sec_type_val).upper() not in ["UNKNOWN", ""]:
            print(f"Warning: Unmapped OpenFIGI securityType '{raw_sec_type_val}' for ISIN {isin}. Defaulted to UNKNOWN.")

        bbg_code = build_bloomberg_code(ticker_val, exch_code_val, db_security_type)
        dq_score = calculate_data_quality_score(figi_val, ticker_val, bbg_code, name_val, exch_code_val, currency_val)

        upsert_ok = upsert_security_data(
            isin=isin, figi=figi_val, ticker=ticker_val, bloomberg_code=bbg_code,
            security_name=name_val, security_type=db_security_type,
            exchange_code=exch_code_val, currency=currency_val,
            data_quality_score=dq_score, processing_attempts=final_attempts_used
        )

        if upsert_ok:
            return {
                "isin": isin, "status": "SUCCESS", "figi": figi_val, "bloomberg_code": bbg_code,
                "ticker": ticker_val, "security_name": name_val, "exchange_code": exch_code_val,
                "currency": currency_val, "security_type": db_security_type, "data_quality_score": dq_score,
                "attempts_used": final_attempts_used, "error_message": None, "error_category": None,
                "response_code": api_response_status_code
            }
        else:
            return {
                "isin": isin, "status": "ERROR", "error_message": "Failed to update database",
                "error_category": "Database Error", "attempts_used": final_attempts_used,
                "figi": figi_val, "bloomberg_code": bbg_code, "ticker": ticker_val,
                "security_name": name_val, "exchange_code": exch_code_val, "currency": currency_val,
                "security_type": db_security_type, "data_quality_score": dq_score,
                "response_code": api_response_status_code
            }

    elif api_response_data and 'warning' in api_response_data:
        return {
            "isin": isin, "status": "NO_DATA",
            "error_message": api_response_data.get('warning'), # This is already set in api_error_message
            "error_category": "No Data", "attempts_used": final_attempts_used,
            "figi": None, "bloomberg_code": None, "ticker": None, "security_name": None,
            "exchange_code": None, "currency": None, "security_type": None,
            "data_quality_score": None, "response_code": api_response_status_code
        }
    else:
        final_error_category = categorize_api_error(api_response_status_code)
        final_err_msg = api_error_message if api_error_message else "API call failed or no data after retries"

        # Refine error message if it's a 200 OK but no data/warning/FIGI error was parsed
        if api_response_status_code == 200 and not (api_response_data and ('warning' in api_response_data or 'figi' in api_response_data)) and not (final_error_category == "OpenFIGI Error"):
            final_err_msg = "Unexpected empty success response or structure from OpenFIGI"
            final_error_category = "API Anomaly"

        return {
            "isin": isin, "status": "ERROR", "error_message": final_err_msg,
            "error_category": final_error_category, "attempts_used": final_attempts_used,
            "figi": None, "bloomberg_code": None, "ticker": None, "security_name": None,
            "exchange_code": None, "currency": None, "security_type": None,
            "data_quality_score": None, "response_code": api_response_status_code
        }

if __name__ == '__main__':
    pass
