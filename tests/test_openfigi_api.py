import unittest
from unittest.mock import patch, MagicMock, call
import datetime
import os

# Now import the module to be tested
# Assuming the file is apis/openfigi/openfigi_api.py
import apis.openfigi.openfigi_api as openfigi_api

class TestOpenFigiApi(unittest.TestCase):

    def setUp(self):
        # Set up any necessary environment variables for tests if not already set
        os.environ["DB_SERVER"] = "test_server"
        os.environ["DB_NAME"] = "test_db"
        os.environ["OPENFIGI_API_KEY"] = "test_api_key"
        # Reset mocked parts of the module if they persist state across tests
        # For example, if OPENFIGI_API_KEY was loaded at import time and not dynamically
        openfigi_api.OPENFIGI_API_KEY = "test_api_key"
        openfigi_api.OPENFIGI_API_URL = "https://api.openfigi.com/v3/mapping"


    # --- Test Validation Functions ---
    def test_validate_isin(self):
        self.assertTrue(openfigi_api.validate_isin("US0378331005")) # Valid Apple ISIN
        self.assertTrue(openfigi_api.validate_isin("DE000BASF111")) # Valid BASF ISIN
        self.assertFalse(openfigi_api.validate_isin("US037833100"))  # Too short
        self.assertFalse(openfigi_api.validate_isin("US03783310055")) # Too long
        self.assertFalse(openfigi_api.validate_isin("U10378331005"))  # Invalid country code (number)
        self.assertFalse(openfigi_api.validate_isin("US037833100X"))  # Invalid check digit (letter)
        self.assertFalse(openfigi_api.validate_isin("us0378331005"))  # Lowercase (assuming strict uppercase)
        self.assertFalse(openfigi_api.validate_isin(None))
        self.assertFalse(openfigi_api.validate_isin(123))

    def test_validate_figi(self):
        self.assertTrue(openfigi_api.validate_figi("BBG000B9XRY4")) # Valid FIGI
        self.assertFalse(openfigi_api.validate_figi("BG000B9XRY4"))  # Doesn't start with BBG
        self.assertFalse(openfigi_api.validate_figi("BBG000B9XRY"))   # Too short
        self.assertFalse(openfigi_api.validate_figi("BBG000B9XRY44")) # Too long
        self.assertFalse(openfigi_api.validate_figi("BBG000B9XRY_"))  # Invalid char
        self.assertFalse(openfigi_api.validate_figi(None))

    def test_validate_currency_code(self):
        self.assertTrue(openfigi_api.validate_currency_code("USD"))
        self.assertTrue(openfigi_api.validate_currency_code("EUR"))
        self.assertFalse(openfigi_api.validate_currency_code("US"))    # Too short
        self.assertFalse(openfigi_api.validate_currency_code("USDO"))  # Too long
        self.assertFalse(openfigi_api.validate_currency_code("123"))
        self.assertFalse(openfigi_api.validate_currency_code("XXX")) # Assuming XXX is not in our list
        self.assertFalse(openfigi_api.validate_currency_code(None))

    def test_validate_ticker_length(self):
        self.assertTrue(openfigi_api.validate_ticker_length("AAPL"))
        self.assertTrue(openfigi_api.validate_ticker_length("GOOG.L"))
        self.assertTrue(openfigi_api.validate_ticker_length("A" * 20)) # Max length
        self.assertFalse(openfigi_api.validate_ticker_length("A" * 21)) # Too long
        self.assertFalse(openfigi_api.validate_ticker_length(""))      # Empty
        self.assertFalse(openfigi_api.validate_ticker_length("AAPL!")) # Invalid char
        self.assertFalse(openfigi_api.validate_ticker_length(None))

    def test_validate_security_name(self):
        self.assertTrue(openfigi_api.validate_security_name("Apple Inc."))
        self.assertTrue(openfigi_api.validate_security_name("A" * 255)) # Max length
        self.assertFalse(openfigi_api.validate_security_name("A" * 256)) # Too long
        self.assertFalse(openfigi_api.validate_security_name(""))       # Empty
        self.assertFalse(openfigi_api.validate_security_name(None))

    def test_validate_exchange_code(self):
        self.assertTrue(openfigi_api.validate_exchange_code("US"))
        self.assertTrue(openfigi_api.validate_exchange_code("XLON"))
        self.assertTrue(openfigi_api.validate_exchange_code("A" * 10)) # Max length
        self.assertFalse(openfigi_api.validate_exchange_code("A" * 11))# Too long
        self.assertFalse(openfigi_api.validate_exchange_code("U"))     # Too short (assuming min 2 letters start)
        self.assertFalse(openfigi_api.validate_exchange_code("1S"))    # Starts with number
        self.assertFalse(openfigi_api.validate_exchange_code(""))      # Empty
        self.assertFalse(openfigi_api.validate_exchange_code(None))

    # --- Test Helper/Utility Functions ---
    def test_build_bloomberg_code(self):
        self.assertEqual(openfigi_api.build_bloomberg_code("AAPL", "US", "EQUITY"), "AAPL US Equity")
        self.assertEqual(openfigi_api.build_bloomberg_code("GOOG", "US", "COMMON STOCK"), "GOOG US Equity")
        self.assertEqual(openfigi_api.build_bloomberg_code("VOD", "LN", "ADR"), "VOD LN Equity") # Changed from XLON to LN
        self.assertEqual(openfigi_api.build_bloomberg_code("DBR", "GR", "CORP"), "DBR GR Corp")
        self.assertEqual(openfigi_api.build_bloomberg_code("MSFT", "UQ", "Equity"), "MSFT UQ Equity") # Direct type
        self.assertIsNone(openfigi_api.build_bloomberg_code(None, "US", "EQUITY"))
        self.assertIsNone(openfigi_api.build_bloomberg_code("AAPL", None, "EQUITY"))
        self.assertEqual(openfigi_api.build_bloomberg_code("AAPL", "US", None), "AAPL US Equity") # Default type

    def test_calculate_data_quality_score(self):
        # All fields present and valid
        self.assertEqual(openfigi_api.calculate_data_quality_score("BBG000B9XRY4", "AAPL", "AAPL US Equity", "Apple Inc.", "US", "USD"), 1.00)
        # Missing currency
        self.assertEqual(openfigi_api.calculate_data_quality_score("BBG000B9XRY4", "AAPL", "AAPL US Equity", "Apple Inc.", "US", None), 0.95)
        # Missing FIGI
        self.assertEqual(openfigi_api.calculate_data_quality_score(None, "AAPL", "AAPL US Equity", "Apple Inc.", "US", "USD"), 0.70)
        # Only ISIN (not part of this score), so all None effectively
        self.assertEqual(openfigi_api.calculate_data_quality_score(None, None, None, None, None, None), 0.00)
        # Invalid FIGI
        self.assertEqual(openfigi_api.calculate_data_quality_score("INVALIDFIGI", "AAPL", "AAPL US Equity", "Apple Inc.", "US", "USD"), 0.70)


    def test_categorize_api_error(self):
        self.assertEqual(openfigi_api.categorize_api_error(400), "Bad Request")
        self.assertEqual(openfigi_api.categorize_api_error(401), "Unauthorized")
        self.assertEqual(openfigi_api.categorize_api_error(403), "Forbidden")
        self.assertEqual(openfigi_api.categorize_api_error(404), "Not Found")
        self.assertEqual(openfigi_api.categorize_api_error(429), "Rate Limited")
        self.assertEqual(openfigi_api.categorize_api_error(500), "Server Error")
        self.assertEqual(openfigi_api.categorize_api_error(503), "Server Error")
        self.assertEqual(openfigi_api.categorize_api_error(0), "Network Error") # For non-HTTP issues
        self.assertEqual(openfigi_api.categorize_api_error(405), "Client Error") # Other 4xx
        self.assertEqual(openfigi_api.categorize_api_error(201), "HTTP Error") # Other codes

    # --- Test Core API and Database Interaction Functions ---

    @patch('apis.openfigi.openfigi_api.requests.post')
    def test_call_openfigi_api_v3_success(self, mock_post):
        mock_response = MagicMock()
        mock_response.status_code = 200
        # Adjusted to match the expected nested structure from the implementation
        mock_response.json.return_value = [{"data": [{"figi": "BBG000B9XRY4", "name": "Apple Inc."}]}]
        mock_post.return_value = mock_response

        status, data, error = openfigi_api.call_openfigi_api_v3("US0378331005")

        self.assertEqual(status, 200)
        self.assertIsNotNone(data)
        self.assertEqual(data['figi'], "BBG000B9XRY4")
        self.assertIsNone(error)
        mock_post.assert_called_once_with(
            openfigi_api.OPENFIGI_API_URL,
            headers={'Content-Type': 'application/json', 'X-OPENFIGI-APIKEY': 'test_api_key'},
            json=[{"idType": "ID_ISIN", "idValue": "US0378331005"}],
            timeout=10
        )

    @patch('apis.openfigi.openfigi_api.requests.post')
    def test_call_openfigi_api_v3_not_found_warning(self, mock_post):
        mock_response = MagicMock()
        mock_response.status_code = 200
        # OpenFIGI returns 200 but with a warning if no instrument found
        mock_response.json.return_value = [{"warning": "No matching instruments found for V3 request."}]
        mock_post.return_value = mock_response

        status, data, error = openfigi_api.call_openfigi_api_v3("US1234567890") # Non-existent ISIN
        self.assertEqual(status, 200)
        self.assertIsNotNone(data) # data contains the warning
        self.assertIn('warning', data)
        self.assertIsNone(error) # error message is for actual exceptions/errors, not FIGI warnings

    @patch('apis.openfigi.openfigi_api.requests.post')
    def test_call_openfigi_api_v3_openfigi_error_in_response(self, mock_post):
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = [{"error": "Invalid query"}]
        mock_post.return_value = mock_response

        status, data, error_msg = openfigi_api.call_openfigi_api_v3("US0378331005")
        self.assertEqual(status, 200)
        self.assertIsNone(data)
        self.assertEqual(error_msg, "Invalid query")


    @patch('apis.openfigi.openfigi_api.requests.post')
    def test_call_openfigi_api_v3_http_error(self, mock_post):
        mock_response = MagicMock()
        mock_response.status_code = 401 # Unauthorized
        mock_response.raise_for_status.side_effect = openfigi_api.requests.exceptions.HTTPError("Unauthorized")
        mock_post.return_value = mock_response

        status, data, error = openfigi_api.call_openfigi_api_v3("US0378331005")

        self.assertEqual(status, 401)
        self.assertIsNone(data)
        self.assertIn("HTTP error", error)

    @patch('apis.openfigi.openfigi_api.requests.post')
    def test_call_openfigi_api_v3_request_exception(self, mock_post):
        mock_post.side_effect = openfigi_api.requests.exceptions.ConnectionError("Connection failed")

        status, data, error = openfigi_api.call_openfigi_api_v3("US0378331005")

        self.assertEqual(status, 0) # Our convention for non-HTTP network issues
        self.assertIsNone(data)
        self.assertIn("Request exception", error)

    def test_call_openfigi_api_v3_invalid_isin(self):
        status, data, error = openfigi_api.call_openfigi_api_v3("INVALIDISIN")
        self.assertEqual(status, 400)
        self.assertIsNone(data)
        self.assertEqual(error, "Invalid ISIN format for API call")

    @patch('apis.openfigi.openfigi_api.get_db_connection')
    def test_log_api_call_success(self, mock_get_connection):
        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        mock_cursor.fetchone.return_value = [123] # Mock LogID
        mock_conn.cursor.return_value.__enter__.return_value = mock_cursor
        mock_get_connection.return_value.__enter__.return_value = mock_conn

        log_id = openfigi_api.log_api_call(
            isin="US0378331005", request_payload="req", response_payload={"data": "resp"},
            response_code=200, is_success=True, processing_time_ms=100, retry_attempt=1
        )

        self.assertEqual(log_id, 123)
        mock_cursor.execute.assert_called_once()
        args, _ = mock_cursor.execute.call_args
        self.assertIn("INSERT INTO OpenFIGI_APILog", args[0])
        self.assertEqual(args[1], "US0378331005") # ISIN
        self.assertEqual(args[3], '{"data": "resp"}') # response_payload as JSON string
        mock_conn.commit.assert_called_once()

    @patch('apis.openfigi.openfigi_api.get_db_connection')
    def test_log_api_call_db_error(self, mock_get_connection):
        mock_conn = MagicMock()
        mock_conn.cursor.side_effect = openfigi_api.pyodbc.Error("DB error")
        mock_get_connection.return_value.__enter__.return_value = mock_conn

        # Also patch print to suppress output during test
        with patch('builtins.print') as mock_print:
            log_id = openfigi_api.log_api_call("US0378331005", "req", None, 500, False)
            self.assertIsNone(log_id)
            mock_print.assert_any_call(unittest.mock.ANY) # Check that print was called with the error

    @patch('apis.openfigi.openfigi_api.get_db_connection')
    def test_upsert_security_data_insert(self, mock_get_connection):
        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        mock_cursor.fetchone.return_value = None # Simulate ISIN does not exist
        mock_conn.cursor.return_value.__enter__.return_value = mock_cursor
        mock_get_connection.return_value.__enter__.return_value = mock_conn

        result = openfigi_api.upsert_security_data(
            isin="US0378331005", figi="BBG000B9XRY4", security_name="Apple Inc.", security_type="EQUITY"
        )
        self.assertTrue(result)
        mock_cursor.execute.assert_any_call("SELECT SecurityID FROM Securities WHERE ISIN = ?", "US0378331005")
        # Check that the INSERT statement was called
        insert_call = any("INSERT INTO Securities" in c[0][0] for c in mock_cursor.execute.call_args_list)
        self.assertTrue(insert_call)
        mock_conn.commit.assert_called_once()

    @patch('apis.openfigi.openfigi_api.get_db_connection')
    def test_upsert_security_data_update(self, mock_get_connection):
        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        mock_cursor.fetchone.return_value = [1] # Simulate ISIN exists
        mock_conn.cursor.return_value.__enter__.return_value = mock_cursor
        mock_get_connection.return_value.__enter__.return_value = mock_conn

        result = openfigi_api.upsert_security_data(
            isin="US0378331005", figi="BBG000B9XRY4", security_name="Apple Inc. Updated", security_type="EQUITY"
        )
        self.assertTrue(result)
        mock_cursor.execute.assert_any_call("SELECT SecurityID FROM Securities WHERE ISIN = ?", "US0378331005")
        # Check that the UPDATE statement was called
        update_call = any("UPDATE Securities" in c[0][0] for c in mock_cursor.execute.call_args_list)
        self.assertTrue(update_call)
        mock_conn.commit.assert_called_once()

    @patch('apis.openfigi.openfigi_api.get_db_connection')
    def test_upsert_security_data_invalid_data_handling(self, mock_get_connection):
        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        mock_cursor.fetchone.return_value = None # Insert case
        mock_conn.cursor.return_value.__enter__.return_value = mock_cursor
        mock_get_connection.return_value.__enter__.return_value = mock_conn

        openfigi_api.upsert_security_data(
            isin="US0378331005",
            figi="INVALID_FIGI",  # Will be set to None by validation
            ticker="TICKERTOOLONGTICKERTOOLONG", # Will be set to None
            security_name="Valid Name",
            security_type="INVALID_TYPE", # Will be set to UNKNOWN
            exchange_code="EXCHANGETOOLONG", # Will be set to None
            currency="INVALIDCUR" # Will be set to None
        )

        # Check the arguments to the INSERT call
        # The exact call_args can be tricky, so we check key transformations
        args, _ = mock_cursor.execute.call_args_list[-1] # Assuming insert is the last relevant execute

        self.assertEqual(args[2], None) # figi
        self.assertEqual(args[3], None) # ticker
        self.assertEqual(args[6], "UNKNOWN") # security_type
        self.assertEqual(args[7], None) # exchange_code
        self.assertEqual(args[8], None) # currency


    # --- Test Main Orchestration Function ---
    @patch('apis.openfigi.openfigi_api.call_openfigi_api_v3')
    @patch('apis.openfigi.openfigi_api.log_api_call')
    @patch('apis.openfigi.openfigi_api.upsert_security_data')
    @patch('apis.openfigi.openfigi_api.build_bloomberg_code')
    @patch('apis.openfigi.openfigi_api.calculate_data_quality_score')
    def test_lookup_isin_and_update_db_success(self, mock_calc_dq, mock_build_bbg, mock_upsert, mock_log, mock_call_api):
        # Mock API success
        mock_call_api.return_value = (
            200,
            {"figi": "BBG000B9XRY4", "ticker": "AAPL", "name": "Apple Inc.", "exchCode": "US", "currency": "USD", "securityType": "Common Stock"},
            None
        )
        mock_build_bbg.return_value = "AAPL US Equity"
        mock_calc_dq.return_value = 1.0
        mock_upsert.return_value = True
        mock_log.return_value = 123 # Log ID

        result = openfigi_api.lookup_isin_and_update_db("US0378331005")

        self.assertEqual(result["status"], "SUCCESS")
        self.assertEqual(result["isin"], "US0378331005")
        self.assertEqual(result["figi"], "BBG000B9XRY4")
        self.assertEqual(result["security_type"], "EQUITY") # Check mapping
        self.assertEqual(result["data_quality_score"], 1.0)
        mock_call_api.assert_called_once_with("US0378331005")
        mock_log.assert_called_once()
        mock_upsert.assert_called_once()
        mock_build_bbg.assert_called_once_with("AAPL", "US", "EQUITY") # Check mapped security type passed
        mock_calc_dq.assert_called_once()

    @patch('apis.openfigi.openfigi_api.call_openfigi_api_v3')
    @patch('apis.openfigi.openfigi_api.log_api_call')
    @patch('apis.openfigi.openfigi_api.upsert_security_data')
    def test_lookup_isin_and_update_db_api_no_data_warning(self, mock_upsert, mock_log, mock_call_api):
        # API returns 200 but with a warning (no data found)
        mock_call_api.return_value = (200, {"warning": "No instruments found"}, None)
        mock_log.return_value = 124

        result = openfigi_api.lookup_isin_and_update_db("US1234567890")

        self.assertEqual(result["status"], "NO_DATA")
        self.assertEqual(result["error_message"], "No instruments found")
        self.assertEqual(result["error_category"], "No Data")
        mock_call_api.assert_called_once_with("US1234567890")
        mock_log.assert_called_once()
        mock_upsert.assert_not_called() # Should not attempt to upsert if no data

    @patch('apis.openfigi.openfigi_api.call_openfigi_api_v3')
    @patch('apis.openfigi.openfigi_api.log_api_call')
    @patch('apis.openfigi.openfigi_api.upsert_security_data')
    def test_lookup_isin_and_update_db_api_failure_retry(self, mock_upsert, mock_log, mock_call_api):
        # Simulate API failure (rate limit) then success on retry
        mock_call_api.side_effect = [
            (429, None, "Rate limit exceeded"), # First call fails
            (200, {"figi": "BBG000B9XRY4", "name": "Apple Inc."}, None) # Second call succeeds
        ]
        mock_log.return_value = 125
        openfigi_api.lookup_isin_and_update_db("US0378331005", max_retries=2) # Allow 1 retry (total 2 attempts)

        self.assertEqual(mock_call_api.call_count, 2)
        self.assertEqual(mock_log.call_count, 2) # Logged each attempt
        mock_upsert.assert_called_once() # Upserted on final success

    @patch('apis.openfigi.openfigi_api.call_openfigi_api_v3')
    @patch('apis.openfigi.openfigi_api.log_api_call')
    @patch('apis.openfigi.openfigi_api.upsert_security_data')
    def test_lookup_isin_and_update_db_api_persistent_failure(self, mock_upsert, mock_log, mock_call_api):
        # API fails persistently
        mock_call_api.return_value = (500, None, "Server error")
        mock_log.return_value = 126

        result = openfigi_api.lookup_isin_and_update_db("US0378331005", max_retries=3)

        self.assertEqual(result["status"], "ERROR")
        self.assertEqual(result["error_category"], "Server Error")
        self.assertEqual(mock_call_api.call_count, 3) # max_retries
        self.assertEqual(mock_log.call_count, 3)
        mock_upsert.assert_not_called()

    def test_lookup_isin_and_update_db_invalid_isin_format(self):
        result = openfigi_api.lookup_isin_and_update_db("INVALID")
        self.assertEqual(result["status"], "ERROR")
        self.assertEqual(result["error_message"], "Invalid ISIN format")
        self.assertEqual(result["error_category"], "Validation Error")

    @patch('apis.openfigi.openfigi_api.call_openfigi_api_v3')
    @patch('apis.openfigi.openfigi_api.log_api_call')
    @patch('apis.openfigi.openfigi_api.upsert_security_data') # Mock this
    @patch('apis.openfigi.openfigi_api.build_bloomberg_code', return_value="TEST BBG CODE")
    @patch('apis.openfigi.openfigi_api.calculate_data_quality_score', return_value=0.75)
    def test_lookup_isin_and_update_db_upsert_failure(self, mock_calc_dq, mock_build_bbg, mock_upsert, mock_log, mock_call_api):
        mock_call_api.return_value = (200, {"figi": "BBG123", "name": "Test Co"}, None)
        mock_upsert.return_value = False # Simulate DB upsert failure
        mock_log.return_value = 127

        result = openfigi_api.lookup_isin_and_update_db("US0378331005")

        self.assertEqual(result["status"], "ERROR")
        self.assertEqual(result["error_message"], "Failed to update database")
        self.assertEqual(result["error_category"], "Database Error")
        self.assertIsNotNone(result["figi"]) # Data was fetched
        mock_upsert.assert_called_once()


if __name__ == '__main__':
    unittest.main(argv=['first-arg-is-ignored'], exit=False)

# To run these tests from the project root directory:
# python -m unittest tests.test_openfigi_api
# Ensure apis/openfigi/openfigi_api.py exists, even if mostly empty for now.
# And ensure __init__.py files are in `apis` and `apis/openfigi` for module discovery.
# tests/__init__.py might also be needed.
# Example:
# apis/__init__.py (empty)
# apis/openfigi/__init__.py (empty)
# tests/__init__.py (empty)
