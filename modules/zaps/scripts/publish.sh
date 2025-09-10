#!/usr/bin/env bash
set -euo pipefail

# Usage: publish.sh <slug> <json_file>
# Renders a zap receipt into an HTML fragment and publishes to Redis

slug="$1"
json_file="$2"

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE_DIR="$MODULE_DIR/../../core"
ENV_FILE="$CORE_DIR/.env"
# shellcheck source=../../core/.env
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

REDIS_URL="${REDIS_URL:-redis://127.0.0.1:6379}"

id="$(jq -r '.id' "$json_file")"
msats="$(jq -r '.amount // 0' "$json_file")"
sats=$((msats / 1000))
content="$(jq -r '.content // ""' "$json_file")"
if [[ -n "$content" ]]; then
  body="$(printf '%s' "$content" | lowdown -Thtml)"
  fragment="<li class=\"zap\" data-id=\"zap:$id\">$sats sats - $body</li>"
else
  fragment="<li class=\"zap\" data-id=\"zap:$id\">$sats sats</li>"
fi

redis-cli -u "$REDIS_URL" PUBLISH "zaps:$slug" "$fragment" > /dev/null
