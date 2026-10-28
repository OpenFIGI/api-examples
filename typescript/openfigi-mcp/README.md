# OpenFIGI MCP Server Example

This example demonstrates how to use the [openfigi-mcp](https://www.npmjs.com/package/openfigi-mcp) package - a Model Context Protocol (MCP) server for the OpenFIGI API.

## What is MCP?

The Model Context Protocol (MCP) allows AI assistants to interact with external tools and data sources. The `openfigi-mcp` server enables AI assistants like Claude to map financial identifiers to FIGIs directly.

## Instructions

Prerequisites: `node` (v18+) must be installed.

```bash
# Install dependencies
npm install

# Optional: Export your API key for higher rate limits
export OPENFIGI_API_KEY=<YOUR_KEY_HERE>

# Run the MCP server
npm start
```

## Configuration with Claude Desktop

Add the following to your Claude Desktop configuration file:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "openfigi": {
      "command": "npx",
      "args": ["openfigi-mcp"],
      "env": {
        "OPENFIGI_API_KEY": "<YOUR_KEY_HERE>"
      }
    }
  }
}
```

## Configuration with Claude Code

Add the following to your Claude Code MCP settings:

```json
{
  "mcpServers": {
    "openfigi": {
      "command": "npx",
      "args": ["openfigi-mcp"],
      "env": {
        "OPENFIGI_API_KEY": "<YOUR_KEY_HERE>"
      }
    }
  }
}
```

## Available Tools

Once configured, the MCP server provides tools to:
- Search for financial instruments by various identifiers (ISIN, CUSIP, SEDOL, Ticker)
- Map identifiers to FIGIs
- Validate financial identifiers

## Docker Instructions

Prerequisites: `Docker` must be installed.

```bash
docker build --tag 'openfigi-mcp' .

docker run --rm -it 'openfigi-mcp'

# OR: If you have acquired an API Key
docker run --rm -it -e OPENFIGI_API_KEY=<YOUR_KEY_HERE> 'openfigi-mcp'
```
