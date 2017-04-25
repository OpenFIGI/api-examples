#!/bin/bash


# If you have an API key, add another header line within the curl command below
# as follows:
#
# -H 'X-OPENFIGI-APIKEY: YOUR_API_KEY' \
#
# For more information on the format of the request body (-d arg) and the
# response, see https://www.openfigi.com/api

curl -X POST \
     -H 'Content-Type: text/json' \
     -d '[{"idType":"ID_WERTPAPIER","idValue":"851399","exchCode":"US"}]' \
    'https://api.openfigi.com/v1/mapping'
