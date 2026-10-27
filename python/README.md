# OpenFIGI Python3 example

This script is written to be run by python3.15 without any external libraries.
Example code is tested with `Python 3.15.1`.

## Instructions

Prerequisites: `Python3.15` must be installed.

```bash
# Optional: Export your API key
export OPENFIGI_API_KEY=<YOUR_KEY_HERE>
python3 example.py
```

## Docker Instructions

Prerequisites: `Docker` must be installed.

```bash
docker build --tag 'openfigi-python' .

docker run --rm -it --entrypoint ./example.py --volume ./:/OpenFIGI 'openfigi-python'

# OR: If you have acquired an API Key
docker run --rm -it --entrypoint ./example.py --volume ./:/OpenFIGI 'openfigi-python'  -e OPENFIGI_API_KEY=<YOUR_KEY_HERE>
```
