#!/usr/bin/env dotnet-script

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

using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;

const string OpenFigiBaseUrl = "https://api.openfigi.com";
string OpenFigiApiKey = Environment.GetEnvironmentVariable("OPENFIGI_API_KEY"); // Put your API key here or in env var

// Create client with default properties
var client = new HttpClient();
client.BaseAddress = new Uri(OpenFigiBaseUrl);
client.DefaultRequestHeaders.Add("X-OPENFIGI-APIKEY", OpenFigiApiKey);

/// <summary>
/// Make an api call to `api.openfigi.com`.
/// </summary>
/// <param name="path">API endpoint, for example "/v3/search"</param>
/// <param name="httpMethod">HTTP request method, for example "POST"</param>
/// <param name="data">HTTP post data, for example new Dictionary<string, string>(){{ "key", "value" }} </param>
/// <returns>
/// HttpResponseMessage
/// </returns>
async Task<HttpResponseMessage> MakeApiRequest(string path, string httpMethod, object data)
{
  HttpRequestMessage request = new HttpRequestMessage(new HttpMethod(httpMethod), path);
  request.Content = JsonContent.Create(data);

  return await client.SendAsync(request);
}

/// <summary>
/// Make search and mapping API requests and print the results
/// to the console
/// </summary>
async Task Main()
{
  var searchRequest = new Dictionary<string, string>(){
    { "query", "APPLE" },
  };
  Console.WriteLine($"Making a search request: {JsonSerializer.Serialize(searchRequest)}");
  var searchResponse = await MakeApiRequest("/v3/search", "POST", searchRequest);
  Console.WriteLine($"Search response: {await searchResponse.Content.ReadAsStringAsync()}");


  Dictionary<string, string>[] mappingRequest = new[]
  {
    new Dictionary<string, string>(){
    { "idType", "ID_BB_GLOBAL" },
    { "idValue", "BBG000BLNNH6" },
    { "exchCode", "US" },
  },
  };
  Console.WriteLine($"Making a mapping request: {JsonSerializer.Serialize(mappingRequest)}");
  var mappingResponse = await MakeApiRequest("/v3/mapping", "POST", mappingRequest);
  Console.WriteLine($"Mapping response: {await mappingResponse.Content.ReadAsStringAsync()}");
}

await Main()