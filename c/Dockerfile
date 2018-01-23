FROM debian

RUN apt-get update && apt-get -y install build-essential git libcurl4-openssl-dev \
   && git clone https://github.com/DaveGamble/cJSON.git \
   && cd cJSON && make all && cd

COPY . /example

WORKDIR /example

RUN gcc ./src/*.c /cJSON/cJSON.c  -I ./include -I /cJSON -lcurl -o example.o

CMD ["/example/example.o"]
