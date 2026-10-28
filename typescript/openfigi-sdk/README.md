# OpenFIGI SDK TypeScript Example

This example demonstrates how to use the [openfigi-sdk](https://github.com/viktorlarsson/openfigi/tree/main/packages/openfigi-sdk) package to interact with the OpenFIGI API.

## Features

The SDK provides:
- Type-safe API calls with TypeScript support
- Zod schema validation
- Helper functions for common operations (searchByISIN, searchByTicker, etc.)
- Identifier validation (isValidISIN, isValidCUSIP)
- Batch mapping operations
- Built-in retry logic with exponential backoff

## Instructions

Prerequisites: `node` (v18+) must be installed.

```bash
# Install dependencies
npm install

# Optional: Export your API key for higher rate limits
export OPENFIGI_API_KEY=<YOUR_KEY_HERE>

# Run the example
npm start
```

## Docker Instructions

Prerequisites: `Docker` must be installed.

```bash
docker build --tag 'openfigi-sdk-example' .

docker run --rm -it 'openfigi-sdk-example'

# OR: If you have acquired an API Key
docker run --rm -it -e OPENFIGI_API_KEY=<YOUR_KEY_HERE> 'openfigi-sdk-example'
```
