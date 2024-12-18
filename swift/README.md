# OpenFIGI Swift example

This script is written to be run with Swift 6.0 without any external dependencies.
Example code is tested with `Swift 6.0.3` on Ubuntu 24.04.1 LTS 

## Instructions

Prerequisites: `Swift 6.0` must be installed.

```bash
# Optional: Export your API key
export OPENFIGI_API_KEY=<YOUR_KEY_HERE>
swift example.swift
```

## Docker Instructions

Prerequisites: `Docker` must be installed.

```bash
docker build --tag 'openfigi-swift' .

docker run --rm -it --volume ./:/OpenFIGI 'openfigi-swift' swift example.swift

# OR: If you have acquired an API Key
docker run --rm -it --volume ./:/OpenFIGI -e OPENFIGI_API_KEY=<YOUR_KEY_HERE> 'openfigi-swift' swift example.swift
```
