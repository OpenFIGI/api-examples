# OpenFIGI Javascript example

This script is written to be run by Node.js without any external libraries.
Example code is tested with node `v22.11.0`

## Instructions

Prerequisites: `node` must be installed.

```bash
# Optional: Export your API key
export OPENFIGI_API_KEY=<YOUR_KEY_HERE>

./example.mjs
# OR
node example.mjs
```

## Docker Instructions

Prerequisites: `Docker` must be installed.

```bash
docker build --tag 'openfigi-js' .

docker run --rm -it --entrypoint ./example.mjs --volume ./:/OpenFIGI 'openfigi-js'

# OR: If you have acquired an API Key
docker run --rm -it --entrypoint ./example.mjs --volume ./:/OpenFIGI 'openfigi-js' -e OPENFIGI_API_KEY=<YOUR_KEY_HERE>
```
