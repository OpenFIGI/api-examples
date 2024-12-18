#!/usr/bin/env swift

// Copyright 2017 Bloomberg Finance L.P.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Foundation

/*
 See https://www.openfigi.com/api for more information.
 
 This script is written to be run with Swift 6.0 without any external dependencies.
 For more involved use cases, consider using open source packages via Swift Package Manager.
 */

let OPENFIGI_API_KEY = ProcessInfo.processInfo.environment["OPENFIGI_API_KEY"]
let OPENFIGI_BASE_URL = "https://api.openfigi.com"

func apiCall(path: String, data: Any? = nil, method: String = "POST") async throws -> Any {
    /*
     Make an api call to `api.openfigi.com`.
     Uses builtin `URLSession` library, end users may prefer to
     swap out this function with another library of their choice
     
     Args:
         path: API endpoint, for example "search"
         method: HTTP request method. Defaults to "POST"
         data: HTTP request data. Defaults to nil
     
     Returns:
         Response of the api call parsed as a JSON object
     */
    
    let url = URL(string: OPENFIGI_BASE_URL)!.appendingPathComponent(path)
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    if let apiKey = OPENFIGI_API_KEY {
        request.setValue(apiKey, forHTTPHeaderField: "X-OPENFIGI-APIKEY")
    }
    
    if let data = data {
        request.httpBody = try JSONSerialization.data(withJSONObject: data)
    }
    
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONSerialization.jsonObject(with: data)
}

func main() async throws {
    /*
     Make search and mapping API requests and print the results
     to the console
     
     Returns:
         None
     */
    
    let searchRequest = ["query": "APPLE"]
    print("Making a search request:", searchRequest)
    let searchResponse = try await apiCall(path: "/v3/search", data: searchRequest)
    let searchJson = try JSONSerialization.data(withJSONObject: searchResponse, options: [.prettyPrinted])
    print("Search response:", String(data: searchJson, encoding: .utf8)!)

    let mappingRequest = [
        ["idType": "ID_BB_GLOBAL", "idValue": "BBG000BLNNH6", "exchCode": "US"]
    ]
    print("Making a mapping request:", mappingRequest)
    let mappingResponse = try await apiCall(path: "/v3/mapping", data: mappingRequest)
    let mappingJson = try JSONSerialization.data(withJSONObject: mappingResponse, options: [.prettyPrinted])
    print("Mapping response:", String(data: mappingJson, encoding: .utf8)!)
}

// Create and run async task for main function
Task {
    do {
        try await main()
        exit(0)
    } catch {
        print("Error:", error)
        exit(1)
    }
}

// Keep the program running until the async task completes
RunLoop.main.run()
