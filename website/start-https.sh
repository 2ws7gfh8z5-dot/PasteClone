#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
CERT_DIR="$SCRIPT_DIR/.certs"
HOST_NAME="justpaste.localhost"
LAN_IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)"
PORT="${PORT:-4443}"

if ! command -v mkcert >/dev/null 2>&1; then
  print -u2 "mkcert is required. Install it with: brew install mkcert"
  exit 1
fi

mkdir -p "$CERT_DIR"
if [[ "${JUSTPASTE_INSTALL_CA:-0}" == "1" ]]; then
  mkcert -install >/dev/null
fi
if [[ -n "$LAN_IP" ]]; then
  mkcert -cert-file "$CERT_DIR/justpaste.local.pem" \
    -key-file "$CERT_DIR/justpaste.local-key.pem" \
    "$HOST_NAME" localhost 127.0.0.1 "$LAN_IP" >/dev/null
else
  mkcert -cert-file "$CERT_DIR/justpaste.local.pem" \
    -key-file "$CERT_DIR/justpaste.local-key.pem" \
    "$HOST_NAME" localhost 127.0.0.1 >/dev/null
fi

print "Just Paste HTTPS: https://$HOST_NAME:$PORT"
if [[ -n "$LAN_IP" ]]; then
  print "LAN HTTPS: https://$LAN_IP:$PORT (other devices need the mkcert root CA trusted)"
fi
print "Press Ctrl-C to stop."
exec python3 - "$SCRIPT_DIR" "$CERT_DIR/justpaste.local.pem" "$CERT_DIR/justpaste.local-key.pem" "$PORT" <<'PY'
import functools
import http.server
import ssl
import sys

directory, cert_file, key_file, port = sys.argv[1:]
handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=directory)
server = http.server.ThreadingHTTPServer(("0.0.0.0", int(port)), handler)
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain(certfile=cert_file, keyfile=key_file)
server.socket = context.wrap_socket(server.socket, server_side=True)
server.serve_forever()
PY
