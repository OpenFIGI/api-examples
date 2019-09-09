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

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# See https://www.openfigi.com/api for more information.

$uri = 'https://api.openfigi.com/v2/mapping'

$openfigi_apikey = ''  # Put API Key here

$headers = @{
    'Content-Type' = 'text/json';
    'X-OPENFIGI-APIKEY' = $openfigi_apikey
}

$jobs = @(
    @{'idType' = 'ID_ISIN'; 'idValue' = 'US4592001014'},
    @{'idType' = 'ID_WERTPAPIER'; 'idValue' = '851399'; 'exchCode' = 'US'},
    @{'idType' = 'ID_BB_UNIQUE'; 'idValue' = 'EQ0010080100001000'; 'currency' = 'USD'},
    @{'idType' = 'ID_SEDOL'; 'idValue' = '2005973'; 'micCode' = 'EDGX'; 'currency' = 'USD'}
)

$JSONBody = $jobs | ConvertTo-Json 

Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $JSONBody -OutFile 'out.json' -PassThru