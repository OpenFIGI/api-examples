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

/**
 * See https://www.openfigi.com/api for more information on the OpenFIGI API.
 *
 * This example demonstrates usage of the openfigi-sdk package.
 * For more information: https://github.com/viktorlarsson/openfigi/tree/main/packages/openfigi-sdk
 */

import {
  createClient,
  searchByISIN,
  searchByTicker,
  mapping,
  isValidISIN,
  isValidCUSIP,
} from "openfigi-sdk";

async function main() {
  const apiKey = process.env.OPENFIGI_API_KEY;

  // Example 1: Validate identifiers before making API calls
  console.log("=== Identifier Validation ===");
  const testISIN = "US0378331005"; // Apple Inc.
  const testCUSIP = "037833100";
  console.log(`ISIN ${testISIN} is valid:`, isValidISIN(testISIN));
  console.log(`CUSIP ${testCUSIP} is valid:`, isValidCUSIP(testCUSIP));

  // Example 2: Search by ISIN (without API key - uses default client)
  console.log("\n=== Search by ISIN ===");
  try {
    const isinResult = await searchByISIN(testISIN);
    console.log("ISIN search result:", JSON.stringify(isinResult, null, 2));
  } catch (error) {
    console.error("ISIN search error:", error);
  }

  // Example 3: Search by Ticker with exchange code
  console.log("\n=== Search by Ticker ===");
  try {
    const tickerResult = await searchByTicker("AAPL", "US");
    console.log("Ticker search result:", JSON.stringify(tickerResult, null, 2));
  } catch (error) {
    console.error("Ticker search error:", error);
  }

  // Example 4: Batch mapping request
  console.log("\n=== Batch Mapping ===");
  try {
    const mappingResults = await mapping([
      { idType: "ID_ISIN", idValue: "US0378331005" },
      { idType: "ID_CUSIP", idValue: "037833100" },
      { idType: "ID_BB_GLOBAL", idValue: "BBG000BLNNH6" },
    ]);
    console.log("Mapping results:", JSON.stringify(mappingResults, null, 2));
  } catch (error) {
    console.error("Mapping error:", error);
  }

  // Example 5: Using a configured client with API key
  if (apiKey) {
    console.log("\n=== Using Configured Client with API Key ===");
    const client = createClient({ apiKey });

    try {
      const result = await client.searchByISIN("US5949181045"); // Microsoft
      console.log(
        "Client search result:",
        JSON.stringify(result, null, 2)
      );
    } catch (error) {
      console.error("Client search error:", error);
    }
  } else {
    console.log("\n(Set OPENFIGI_API_KEY env var to test authenticated client)");
  }
}

main().catch(console.error);
