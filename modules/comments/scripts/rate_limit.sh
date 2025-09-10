#!/usr/bin/env bash
set -euo pipefail

IP="$1"
PUB="$2"
REDIS_URL="${REDIS_URL:-redis://127.0.0.1:6379}"
RATE_IP_PER_MIN="${RATE_IP_PER_MIN:-0}"
RATE_PUB_PER_MIN="${RATE_PUB_PER_MIN:-0}"

cli() {
  redis-cli -u "$REDIS_URL" "$@" > /dev/null
}

if [[ "$RATE_IP_PER_MIN" -gt 0 ]]; then
  count=$(redis-cli -u "$REDIS_URL" incr "ip:$IP")
  if [[ "$count" -eq 1 ]]; then cli expire "ip:$IP" 60; fi
  if [[ "$count" -gt "$RATE_IP_PER_MIN" ]]; then
    echo "ip rate limit exceeded" >&2
    exit 1
  fi
fi

if [[ -n "$PUB" && "$RATE_PUB_PER_MIN" -gt 0 ]]; then
  count=$(redis-cli -u "$REDIS_URL" incr "pub:$PUB")
  if [[ "$count" -eq 1 ]]; then cli expire "pub:$PUB" 60; fi
  if [[ "$count" -gt "$RATE_PUB_PER_MIN" ]]; then
    echo "pub rate limit exceeded" >&2
    exit 1
  fi
fi
