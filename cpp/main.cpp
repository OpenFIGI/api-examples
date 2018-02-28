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
#include <iostream>
#include <stdexcept>


#include <json.hpp>


#include <curlpp/cURLpp.hpp>
#include <curlpp/Easy.hpp>
#include <curlpp/Options.hpp>
#include <curlpp/Infos.hpp>


using json = nlohmann::json;
using namespace std::placeholders;


class ResponseWriter {
public:
    std::string response() {
        return _resp.str();
    }
    size_t operator() (curlpp::Easy *handle, char* ptr, size_t size, size_t nmemb) {
        _resp << ptr;
        return size * nmemb;
    }
private:
    std::stringstream _resp;
};


class ApiException : public std::runtime_error {
public:
    ApiException(const std::string &what_arg)
    : runtime_error(what_arg)
    { }
};


json createSampleRequest() {
    json request = json::array();

    json job = {
        {"idType", "ID_WERTPAPIER"},
        {"idValue", "851399"},
        {"exchCode", "US"}
    };

    request.push_back(job);

    job = {
        {"idType", "ID_BB_UNIQUE"},
        {"idValue", "EQ0010080100001000"},
        {"currency", "USD"}
    };

    request.push_back(job);

    job = {
        {"idType", "ID_SEDOL"},
        {"idValue", "EQ0010080100001000"},
        {"micCode", "EDGX"},
        {"currency", "USD"}
    };

    request.push_back(job);

    return request;
}


std::string sendRequest(const std::string &request, const std::string &apiKey = "") {
    curlpp::Easy handle;
    std::string url = "https://api.openfigi.com/v1/mapping";

    // create list of headers
    std::list<std::string> header;
    header.push_back("Content-Type: text/json");
    if (apiKey.size()) {
        header.push_back("X-OPENFIGI-APIKEY: " + apiKey);
    }

    // add request options
    handle.setOpt(new curlpp::options::Url(url));
    handle.setOpt(new curlpp::options::HttpHeader(header));
    handle.setOpt(new curlpp::options::PostFields(request));
    handle.setOpt(new curlpp::options::PostFieldSize(request.size()));

    // create writer callback (read in memory)
    ResponseWriter writer;
    const auto fn = std::bind(&ResponseWriter::operator(), &writer, &handle, _1, _2, _3);
    curlpp::options::WriteFunction *writerCallback = new curlpp::options::WriteFunction(fn);
    handle.setOpt(writerCallback);

    // send request
    handle.perform();
    if (curlpp::infos::ResponseCode::get(handle) != 200) {
        std::cout << writer.response() << std::endl;
        throw ApiException(writer.response());
    }
    return writer.response();
}


int main() {
    const json request = createSampleRequest();
    try {
        const std::string resString = sendRequest(request.dump());
        auto response = json::parse(resString);
        size_t ix = 0;
        for (json::iterator it = response.begin(); it != response.end(); ++it) {
            std::cout << std::endl;
            const auto data = (*it)["data"];
            if (data == nullptr) {
                std::cout << "No match found for " << request[ix].dump() << std::endl;
            }
            else {
                std::cout << "Matches for " << request[ix].dump() << ":" << std::endl;
                for (auto matchIt = data.begin(); matchIt != data.end(); ++matchIt) {
                    std::cout << (*matchIt)["figi"] << std::endl;
                }
            }
        }
    }
    catch(ApiException & e) {
        std::cout << "Error during request: " << e.what() << std::endl;
    }
    catch(curlpp::RuntimeError & e)
    {
        std::cout << e.what() << std::endl;
    }
    catch(curlpp::LogicError & e)
    {
        std::cout << e.what() << std::endl;
    }
    return 0;
}
