#!/usr/bin/env node

/*
Copyright 2017 Bloomberg Finance L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

"use strict";

/**
 * See https://www.openfigi.com/api for more information on the OpenFIGI API.
 *
 * This script is written to be run by Node.js - tested with node v22 - without any external libraries.
 * For more involved use cases, consider using a package manager and open source
 * packages: https://www.npmjs.com/
 */

import https from "https";

const apiKey = process.env.OPENFIGI_API_KEY; // Put your API key here or in env var

/**
 * Make an api call to `api.openfigi.com`.
 * Uses builtin `https` library, end users may prefer to
 * swap out this function with another library of
 * their choice
 *
 * @param {string} path Api path, for example `"/v3/search"`
 * @param {Object} data Http post data,
 * @returns {Promise<Object>} Response from api call parsed as a JSON object
 */
async function apiCall(path, data) {
  const options = {
    hostname: "api.openfigi.com",
    path: path,
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(apiKey && { "X-OPENFIGI-APIKEY": apiKey }),
    },
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let responseData = "";
      res.setEncoding("utf8");
      res.on("data", (chunk) => (responseData += chunk));
      res.on("end", () => resolve(JSON.parse(responseData)));
    });
    req.on("error", (e) => reject(e));
    req.write(JSON.stringify(data));
    req.end();
  });
}

/**
 * Make search and mapping API requests and print the results
 * to the console
 * @return {undefined}
 */
async function main() {
  const searchRequest = { query: "APPLE" };
  console.log("Making a search request:", searchRequest);
  const searchResponse = await apiCall("/v3/search", searchRequest);
  console.log("Search response:", JSON.stringify(searchResponse, null, 2));

  const mappingRequest = [
    { idType: "ID_BB_GLOBAL", idValue: "BBG000BLNNH6", exchCode: "US" },
  ];
  console.log("Making a mapping request:", mappingRequest);
  const mappingResponse = await apiCall("/v3/mapping", mappingRequest);
  console.log("Mapping response:", JSON.stringify(mappingResponse, null, 2));
}

await main();
