#!/bin/sh
# Subscribe to Redis channel and stream payloads to stdout for websocketd
set -e
CHANNEL=$(printf '%s' "$PATH_INFO" | sed 's#^/live/##')
if [ -z "$CHANNEL" ]; then
  exit 1
fi
REDIS_URL="${REDIS_URL:-redis://127.0.0.1:6379}"
redis-cli -u "$REDIS_URL" --raw SUBSCRIBE "$CHANNEL" |
  while read -r type; do
    case "$type" in
    message)
      read -r _chan
      read -r payload
      printf '%s\n' "$payload"
      ;;
    subscribe)
      read -r _
      read -r _
      ;;
    esac
  done
