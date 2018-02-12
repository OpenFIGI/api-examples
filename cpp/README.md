# OpenFIGI API C++ Example


A simple example of using OpenFIGI API with C++.


Dependencies
 - [nlohmann/json](https://github.com/nlohmann/json) to serialize/desirialize JSON.
 - [cURLpp](http://www.curlpp.org) as a REST client.

For a build example, check the Dockerfile

```
docker build . -t api-example
docker run --rm -it api-example
```
