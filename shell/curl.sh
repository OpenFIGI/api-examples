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

# If you have an API key, add another header line within the curl command below
# as follows:
# -H 'X-OPENFIGI-APIKEY: YOUR_API_KEY' \
# For more information on the format of the request body (-d arg) and the
# response, see https://www.openfigi.com/api

curl -X POST \
     -H 'Content-Type: text/json' \
     -d '[{"idType":"ID_WERTPAPIER","idValue":"851399","exchCode":"US"}]' \
    'https://api.openfigi.com/v1/mapping'
