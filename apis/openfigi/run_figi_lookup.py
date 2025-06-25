import sys
import json
import os

# Ensure the main package 'apis' is discoverable
current_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(current_dir, '..', '..'))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

# This will import from apis/openfigi/openfigi_api.py
from apis.openfigi import openfigi_api

def main():
    if len(sys.argv) < 2:
        # Output error as JSON to stderr, keep stdout clean for valid JSON result
        print(json.dumps({"status": "ERROR", "error_message": "ISIN argument required"}), file=sys.stderr)
        sys.exit(1)

    isin_to_lookup = sys.argv[1]

    # Ensure environment variables (DB_SERVER, DB_NAME, OPENFIGI_API_KEY, etc.)
    # are accessible by the Python process invoked by xp_cmdshell.
    # These should be set in the environment of the SQL Server service account,
    # or configured via other means if xp_cmdshell runs under a proxy account.

    try:
        # Call the main function from our library
        # The lookup_isin_and_update_db function now handles its own API call retries.
        # The T-SQL sp_LookupISINViaOpenFIGI's @MaxRetries might then pertain to retrying the
        # execution of this python script itself, if, for example, the script crashes.
        result = openfigi_api.lookup_isin_and_update_db(isin=isin_to_lookup)
        print(json.dumps(result)) # Output result as JSON string to stdout
    except Exception as e:
        # Catch any unexpected exceptions during the Python script execution
        error_result = {
            "isin": isin_to_lookup,
            "status": "ERROR",
            "error_message": f"Python script execution failed: {str(e)}",
            "error_category": "Python Execution Error",
            "attempts_used": 0, # Or reflect attempts if tracked before crash
            "figi": None, "bloomberg_code": None, "ticker": None, "security_name": None,
            "exchange_code": None, "currency": None, "security_type": None,
            "data_quality_score": None, "response_code": None
        }
        # Output error as JSON to stdout for T-SQL to potentially parse
        # Or print to stderr and have T-SQL only read stdout for success.
        # For simplicity here, error also goes to stdout for T-SQL to parse one source.
        print(json.dumps(error_result))
        sys.exit(1) # Indicate failure

if __name__ == "__main__":
    main()
