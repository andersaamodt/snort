#!/bin/sh
# Launch websocketd fallback broker bridging Redis pub/sub to WS clients
set -e
WS_BIND="${WS_BIND:-127.0.0.1:9001}"
REDIS_URL="${REDIS_URL:-redis://127.0.0.1:6379}"
HOST="${WS_BIND%:*}"
PORT="${WS_BIND#*:}"
DIR="$(dirname "$0")"
export REDIS_URL
exec websocketd --address "$HOST" --port "$PORT" --passenv REDIS_URL "$DIR/redis_sub.sh"
