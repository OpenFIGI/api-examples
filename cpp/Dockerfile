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
FROM debian

COPY ./main.cpp /example/

RUN apt-get update && apt-get -y install build-essential libcurl4-openssl-dev wget cmake-data cmake \
    && mkdir /example/json -p \
    && wget https://raw.githubusercontent.com/nlohmann/json/develop/single_include/nlohmann/json.hpp -O /example/json/json.hpp \
    && wget https://github.com/jpbarrette/curlpp/archive/v0.8.1.tar.gz \
    && tar -xf v0.8.1.tar.gz && cd curlpp-0.8.1 \
    && mkdir build && cd build \
    && cmake .. \
    && make && make install \
    && ldconfig \
    && g++ -I /example/json -I /example -Iinclude /example/*.cpp -Llib -lcurl -lcurlpp -std=c++11 -o /example/test.o

CMD ["/example/test.o"]
