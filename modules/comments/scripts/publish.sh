#!/usr/bin/env bash
set -euo pipefail

# Usage: publish.sh <slug> <json_file>
# Renders a reply event into an HTML fragment and publishes to Redis

slug="$1"
json_file="$2"

# Load environment
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE_DIR="$MODULE_DIR/../../core"
ENV_FILE="$CORE_DIR/.env"
# shellcheck source=../../core/.env
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

REDIS_URL="${REDIS_URL:-redis://127.0.0.1:6379}"

id="$(jq -r '.id' "$json_file")"
content="$(jq -r '.content' "$json_file")"
html="$(printf '%s' "$content" | lowdown -Thtml)"
fragment="<li class=\"reply\" data-id=\"nostr:$id\">$html</li>"

redis-cli -u "$REDIS_URL" PUBLISH "replies:$slug" "$fragment" > /dev/null
