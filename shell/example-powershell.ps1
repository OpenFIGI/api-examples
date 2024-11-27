#!/usr/bin/env pwsh

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

$openfigi_apikey = $Env:OPENFIGI_API_KEY  # Put API Key here or in env var

$headers = @{
    'Content-Type' = 'text/json';
    'X-OPENFIGI-APIKEY' = $openfigi_apikey
}

# Search Example
$searchRequest = ConvertTo-Json @{"query" = "APPLE"}
Write-Output "Making a search request:", $searchRequest
$searchResponse = Invoke-RestMethod -Uri 'https://api.openfigi.com/v3/search' -Method Post -Headers $headers -Body $searchRequest
Write-Output "Search response:", ($searchResponse | Format-List -Property *)

# Mapping Example
$mappingRequest = ConvertTo-Json @(
    @{'idType'='ID_BB_GLOBAL';'idValue'='BBG000BLNNH6';'exchCode'='US'}
)
Write-Output "Making a mapping request:", $mappingRequest
$mappingResponse = Invoke-RestMethod -Uri 'https://api.openfigi.com/v3/mapping' -Method Post -Headers $headers -Body $mappingRequest
Write-Output "Mapping response:", ($mappingResponse | Format-List -Property *)