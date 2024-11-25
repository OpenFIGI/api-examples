#!/bin/bash

# Copyright 2017 Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# For more information on the format of the request body (-d arg) and the
# response, see https://www.openfigi.com/api

api_call() {
     path=$1
     data=$2
     openfigi_api_key=${OPENFIGI_API_KEY:-""} # Put your API key here or in env var

     cmd="curl -X POST \
     -H 'Content-Type: text/json' \
     -d '$data' "

     if [ -n "$openfigi_api_key" ]; then
          cmd="$cmd -H 'X-OPENFIGI-APIKEY: $openfigi_api_key'"
     fi

     cmd="$cmd 'https://api.openfigi.com/v3/$path'"

     echo "Request:" $cmd
     echo -n "Response: "
     eval "$cmd"
}

echo "Search API Call Example:"
api_call 'search' '{"query":"apple"}'

echo "Mapping API Call Example:"
api_call 'mapping' '[{"idType":"ID_WERTPAPIER","idValue":"851399","exchCode":"US"}]'
