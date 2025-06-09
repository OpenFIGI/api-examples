#!/usr/bin/env python3.12
"""Simple web interface for OpenFIGI API using only stdlib."""

from __future__ import annotations
import json
import os
import urllib.parse
import urllib.request
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path

OPENFIGI_API_KEY = os.environ.get("OPENFIGI_API_KEY")
OPENFIGI_BASE_URL = "https://api.openfigi.com"


def api_call(path: str, data: dict | list) -> dict | list:
    """Make an API call to api.openfigi.com."""
    headers = {"Content-Type": "application/json"}
    if OPENFIGI_API_KEY:
        headers["X-OPENFIGI-APIKEY"] = OPENFIGI_API_KEY
    req = urllib.request.Request(
        urllib.parse.urljoin(OPENFIGI_BASE_URL, path),
        data=bytes(json.dumps(data), "utf-8"),
        headers=headers,
        method="POST",
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))


class Handler(SimpleHTTPRequestHandler):
    """Serve static files and handle search/mapping requests."""

    def __init__(self, *args, **kwargs):
        directory = Path(__file__).resolve().parent / "public"
        super().__init__(*args, directory=str(directory), **kwargs)

    def do_POST(self) -> None:  # noqa: N802 - name from base class
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length).decode("utf-8")
        try:
            payload = json.loads(body or "{}")
        except json.JSONDecodeError:
            self.send_response(400)
            self.end_headers()
            self.wfile.write(b'{"error":"invalid json"}')
            return

        if self.path == "/search":
            result = api_call("/v3/search", payload)
        elif self.path == "/mapping":
            requests = payload.get("requests", [])
            result = api_call("/v3/mapping", requests)
        else:
            self.send_response(404)
            self.end_headers()
            return

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(result).encode("utf-8"))


if __name__ == "__main__":
    httpd = HTTPServer(("localhost", 3000), Handler)
    print("Server running at http://localhost:3000/")
    httpd.serve_forever()
