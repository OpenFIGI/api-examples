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

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpResponse.BodyHandlers;

class OpenFigi {

    static String openFigiBaseUrl = "https://api.openfigi.com";
    static String openFigiApiKey = System.getenv("OPENFIGI_API_KEY");
    static HttpClient client = HttpClient.newHttpClient();

    /**
     * Make search and mapping API requests and print the results to the console
     *
     * @param args Not used
     * @return void
     */
    public static void main(String[] args) throws Exception {
        {
            // Search API request example
            String searchRequest = "{\"query\": \"APPLE\"}";
            System.out.println("Making a search request: " + searchRequest);
            String searchResponse = OpenFigi.makePostApiCall("/v3/search", searchRequest);
            System.out.println("Search response: " + searchResponse);
        }

        {
            // Mapping API request example
            String mappingRequest = "[{\"idType\": \"ID_ISIN\", \"idValue\": \"US4592001014\"}]";
            System.out.println("Making a mapping request: " + mappingRequest);
            String mappingResponse = OpenFigi.makePostApiCall("/v3/mapping", mappingRequest);
            System.out.println("Mapping response: " + mappingResponse);
        }
    }

    /**
     * Make a http post api call to `api.openfigi.com`.
     *
     * @param path API endpoint, for example "/v3/search"
     * @param body HTTP post request body.
     * @return API response as string
     */
    public static String makePostApiCall(String path, String body) throws Exception {
        var requestBuilder = HttpRequest.newBuilder()
                .uri(new URI(OpenFigi.openFigiBaseUrl + path))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(body));

        if (OpenFigi.openFigiApiKey != null) {
            requestBuilder = requestBuilder.header("X-OPENFIGI-APIKEY", OpenFigi.openFigiApiKey);
        }

        var request = requestBuilder.build();

        HttpResponse<String> response = OpenFigi.client.send(request, BodyHandlers.ofString());

        return response.body();
    }
};
