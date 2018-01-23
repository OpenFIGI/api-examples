# OpenFIGI API C Example


A simple example of using OpenFIGI API with C.


Dependencies
 - [cJSON](https://github.com/DaveGamble/cJSON) to serialize/desirialize JSON.
 - [libCurl](https://curl.haxx.se/libcurl/) as a REST client.


See Dockerfile for building steps. To run the example with [Docker](https://www.docker.com):


```
docker build . -t example
docker run example --rm
```
