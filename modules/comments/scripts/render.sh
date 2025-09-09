#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE_DIR="$MODULE_DIR/../../core"
ENV_FILE="$CORE_DIR/.env"

# shellcheck source=../../core/.env
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

CACHE_ROOT="${CACHE_ROOT:-$CORE_DIR/../cache}"
PUBLIC_DIR="${PUBLIC_DIR:-$CORE_DIR/public}"

REPLIES_DIR="$CACHE_ROOT/nostr-cache/replies"
POSTS_PUBLIC="$PUBLIC_DIR/posts"

[[ -d "$REPLIES_DIR" ]] || exit 0

for slug_dir in "$REPLIES_DIR"/*; do
  [[ -d "$slug_dir" ]] || continue
  slug="$(basename "$slug_dir")"
  outdir="$POSTS_PUBLIC/$slug"
  mkdir -p "$outdir"
  outfile="$outdir/replies.html"
  {
    echo '<ul>'
    find "$slug_dir" -type f -name '*.json' | while read -r file; do
      created="$(jq -r '.created_at // 0' "$file")"
      printf '%s\t%s\n' "$created" "$file"
    done | sort -n | while IFS=$'\t' read -r _ file; do
      id="$(jq -r '.id' "$file")"
      content="$(jq -r '.content' "$file")"
      body="$(printf '%s' "$content" | lowdown -Thtml)"
      printf '  <li class="reply" data-id="nostr:%s">%s</li>\n' "$id" "$body"
    done
    echo '</ul>'
  } > "$outfile"
done
