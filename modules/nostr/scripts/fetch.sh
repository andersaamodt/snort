#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="${CACHE_ROOT}/nostr-cache"
mkdir -p "$CACHE_DIR/posts" "$CACHE_DIR/profiles" "$CACHE_DIR/replies" "$CACHE_DIR/zaps"

RELAYS_READ="${RELAYS_READ:-}"
AUTHOR_NPUBS="${AUTHOR_NPUBS:-}"

EVENTS=$(nostr-cli --relays "$RELAYS_READ" --kinds 30023 --authors "$AUTHOR_NPUBS" list 2> /dev/null || echo '[]')

echo "$EVENTS" | jq '[.[] | .tags[] | select(.[0]=="d") | .[1]]' > "$CACHE_DIR/index.json"

PUBKEYS=""
declare -A EVENT_IDS
while read -r event; do
  slug=$(jq -r '.tags[] | select(.[0]=="d") | .[1]' <<< "$event")
  [[ -n "$slug" ]] || continue
  echo "$event" > "$CACHE_DIR/posts/$slug.json"
  id=$(jq -r '.id' <<< "$event")
  [[ -n "$id" ]] && EVENT_IDS["$slug"]="$id"
  pk=$(jq -r '.pubkey // empty' <<< "$event")
  if [[ -n "$pk" ]]; then
    PUBKEYS+="$pk\n"
  fi
done < <(echo "$EVENTS" | jq -c '.[]')

UNIQUE_PUBS=$(printf '%b' "$PUBKEYS" | sort -u | tr '\n' ',' | sed 's/,$//')
if [[ -n "$UNIQUE_PUBS" ]]; then
  PROFILES=$(nostr-cli --relays "$RELAYS_READ" --kinds 0 --authors "$UNIQUE_PUBS" list 2> /dev/null || echo '[]')
  echo "$PROFILES" | jq -c '.[]' | while read -r profile; do
    pk=$(jq -r '.pubkey' <<< "$profile")
    [[ -n "$pk" ]] || continue
    echo "$profile" > "$CACHE_DIR/profiles/$pk.json"
  done
fi

for slug in "${!EVENT_IDS[@]}"; do
  eid="${EVENT_IDS[$slug]}"
  REPLIES=$(nostr-cli --relays "$RELAYS_READ" --kinds 1 --events "$eid" list 2> /dev/null || echo '[]')
  echo "$REPLIES" | jq -c '.[]' | while read -r reply; do
    rid=$(jq -r '.id' <<< "$reply")
    [[ -n "$rid" ]] || continue
    mkdir -p "$CACHE_DIR/replies/$slug"
    echo "$reply" > "$CACHE_DIR/replies/$slug/$rid.json"
  done
  ZAPS=$(nostr-cli --relays "$RELAYS_READ" --kinds 9735 --events "$eid" list 2> /dev/null || echo '[]')
  echo "$ZAPS" | jq -c '.[]' | while read -r zap; do
    zid=$(jq -r '.id' <<< "$zap")
    [[ -n "$zid" ]] || continue
    mkdir -p "$CACHE_DIR/zaps/$slug"
    echo "$zap" > "$CACHE_DIR/zaps/$slug/$zid.json"
  done
done
