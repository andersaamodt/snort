#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE_DIR="$MODULE_DIR/../../core"
ENV_FILE="$CORE_DIR/.env"

# shellcheck source=../../core/.env
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

CACHE_ROOT="${CACHE_ROOT:-$CORE_DIR/../cache}"
PUBLIC_DIR="${PUBLIC_DIR:-$CORE_DIR/public}"

ZAPS_DIR="$CACHE_ROOT/nostr-cache/zaps"
POSTS_PUBLIC="$PUBLIC_DIR/posts"

[[ -d "$ZAPS_DIR" ]] || exit 0

for slug_dir in "$ZAPS_DIR"/*; do
  [[ -d "$slug_dir" ]] || continue
  slug="$(basename "$slug_dir")"
  outdir="$POSTS_PUBLIC/$slug"
  mkdir -p "$outdir"
  outfile="$outdir/zaps.html"
  {
    echo '<ul>'
    find "$slug_dir" -type f -name '*.json' | while read -r file; do
      created="$(jq -r '.created_at // 0' "$file")"
      printf '%s\t%s\n' "$created" "$file"
    done | sort -n | while IFS=$'\t' read -r _ file; do
      id="$(jq -r '.id' "$file")"
      msats="$(jq -r '.amount // 0' "$file")"
      sats=$((msats / 1000))
      content="$(jq -r '.content // ""' "$file")"
      if [[ -n "$content" ]]; then
        body="$(printf '%s' "$content" | lowdown -Thtml)"
        printf '  <li class="zap" data-id="zap:%s">%s sats - %s</li>\n' "$id" "$sats" "$body"
      else
        printf '  <li class="zap" data-id="zap:%s">%s sats</li>\n' "$id" "$sats"
      fi
    done
    echo '</ul>'
  } > "$outfile"
done
