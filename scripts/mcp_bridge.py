#!/usr/bin/env python3
"""stdio -> HTTP bridge for the Just Paste MCP server.

For MCP clients that only speak stdio. Reads JSON-RPC lines from stdin,
forwards them to http://127.0.0.1:47821 with the Bearer token, prints the
response to stdout.

Config (env): JUSTPASTE_TOKEN (required), JUSTPASTE_URL (default below).
"""
import json
import os
import sys
import urllib.request

URL = os.environ.get("JUSTPASTE_URL", "http://127.0.0.1:47821")
TOKEN = os.environ.get("JUSTPASTE_TOKEN", "")


def main():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        req = urllib.request.Request(
            URL,
            data=line.encode(),
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {TOKEN}",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                body = resp.read().decode()
        except Exception as e:  # noqa: BLE001 - surface any failure as JSON-RPC error
            try:
                rid = json.loads(line).get("id")
            except json.JSONDecodeError:
                rid = None
            body = json.dumps(
                {"jsonrpc": "2.0", "id": rid, "error": {"code": -32000, "message": str(e)}}
            )
        print(body, flush=True)


if __name__ == "__main__":
    main()
