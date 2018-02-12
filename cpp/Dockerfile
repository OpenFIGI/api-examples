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
