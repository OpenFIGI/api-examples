# OpenFIGI Javascript example

This script is written to be build by JDK and run on JVM without any external libraries.
End users are recommended to use a json library for serializing requests and deserializing responses.

Example code is tested with Eclipse Temurin 25 (an OpenJDK build):

```
openjdk version "25.0.4.1" 2026-08-18 LTS
OpenJDK Runtime Environment Temurin-25.0.4.1+1 (build 25.0.4.1+1-LTS)
```

## Instructions

Prerequisites: `jdk` must be installed.

```bash
# Optional: Export your API key
export OPENFIGI_API_KEY=<YOUR_KEY_HERE>

java ./example.java
```

## Docker Instructions

Prerequisites: `Docker` must be installed.

```bash
docker build --tag 'openfigi-java' .

docker run --rm -it --entrypoint java --volume ./:/OpenFIGI 'openfigi-java' ./example.java

# OR: If you have acquired an API Key
docker run -e OPENFIGI_API_KEY=<YOUR_KEY_HERE> --rm -it --entrypoint java --volume ./:/OpenFIGI 'openfigi-java' ./example.java
```
