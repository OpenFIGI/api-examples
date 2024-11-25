# OpenFIGI Javascript example

This script is written to be build by JDK and run on JVM without any external libraries.
End users are recommended to use a json library for serializing requests and deserializing responses.

Example code is tested with:

```
openjdk 21 2023-09-19
OpenJDK Runtime Environment (build 21+35-2513)
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
