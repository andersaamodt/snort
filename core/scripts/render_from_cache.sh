#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

# shellcheck source=/dev/null
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

CACHE_ROOT="${CACHE_ROOT:-$ROOT_DIR/../cache}"
TEMPLATE_DIR="$ROOT_DIR/templates"
PUBLIC_DIR="$ROOT_DIR/public"
export PUBLIC_DIR

mkdir -p "$PUBLIC_DIR"

POSTS_DIR="$CACHE_ROOT/nostr-cache/posts"
INDEX_FILE="$CACHE_ROOT/nostr-cache/index.json"
declare -A TITLES
declare -A TAG_POSTS
declare -A AUTHOR_POSTS

slugs=()
if [[ -f "$INDEX_FILE" ]]; then
  mapfile -t slugs < <(jq -r '.[]' "$INDEX_FILE" 2> /dev/null)
fi
if [[ ${#slugs[@]} -eq 0 && -d "$POSTS_DIR" ]]; then
  for post in "$POSTS_DIR"/*.json; do
    [[ -e "$post" ]] || continue
    slugs+=("$(basename "$post" .json)")
  done
fi

for slug in "${slugs[@]}"; do
  post="$POSTS_DIR/$slug.json"
  [[ -f "$post" ]] || continue
  content="$(jq -r '.content' "$post")"
  body="$(printf '%s' "$content" | lowdown -Thtml)"
  title="$(printf '%s' "$content" | sed -n '1s/^# \(.*\)/\1/p')"
  [[ -n "$title" ]] || title="$slug"
  TITLES["$slug"]="$title"

  tags=$(jq -r '.tags[]? | select(.[0]=="t") | .[1]' "$post" | tr '\n' ' ')
  for tag in $tags; do
    TAG_POSTS["$tag"]+="$slug\n"
  done

  author="$(jq -r '.pubkey // empty' "$post")"
  if [[ -n "$author" ]]; then
    AUTHOR_POSTS["$author"]+="$slug\n"
  fi

  outdir="$PUBLIC_DIR/posts/$slug"
  mkdir -p "$outdir"
  {
    cat "$TEMPLATE_DIR/header.html"
    printf '%s\n' "$body"
    cat "$TEMPLATE_DIR/footer.html"
  } > "$outdir/index.html"
done

INDEX_ENTRIES=""
for slug in "${!TITLES[@]}"; do
  INDEX_ENTRIES+="$slug|${TITLES[$slug]}\n"
done

{
  cat "$TEMPLATE_DIR/header.html"
  echo "<ul>"
  printf '%b' "$INDEX_ENTRIES" | sort | while IFS='|' read -r slug title; do
    printf '  <li><a href="/posts/%s/">%s</a></li>\n' "$slug" "$title"
  done
  echo "</ul>"
  cat "$TEMPLATE_DIR/footer.html"
} > "$PUBLIC_DIR/index.html"

for tag in "${!TAG_POSTS[@]}"; do
  outdir="$PUBLIC_DIR/tags/$tag"
  mkdir -p "$outdir"
  {
    cat "$TEMPLATE_DIR/header.html"
    printf '<h1>Tag: %s</h1>\n<ul>\n' "$tag"
    printf '%b' "${TAG_POSTS[$tag]}" | sort | while read -r slug; do
      title="${TITLES[$slug]}"
      printf '  <li><a href="/posts/%s/">%s</a></li>\n' "$slug" "$title"
    done
    echo '</ul>'
    cat "$TEMPLATE_DIR/footer.html"
  } > "$outdir/index.html"
done

for author in "${!AUTHOR_POSTS[@]}"; do
  outdir="$PUBLIC_DIR/authors/$author"
  mkdir -p "$outdir"
  {
    cat "$TEMPLATE_DIR/header.html"
    printf '<h1>Author: %s</h1>\n<ul>\n' "$author"
    printf '%b' "${AUTHOR_POSTS[$author]}" | sort | while read -r slug; do
      title="${TITLES[$slug]}"
      printf '  <li><a href="/posts/%s/">%s</a></li>\n' "$slug" "$title"
    done
    echo '</ul>'
    cat "$TEMPLATE_DIR/footer.html"
  } > "$outdir/index.html"
done

MODULES="${MODULES:-}"
IFS=',' read -r -a mods <<< "$MODULES"
for mod in "${mods[@]}"; do
  [[ -n "$mod" ]] || continue
  MOD_RENDER="$ROOT_DIR/../modules/$mod/scripts/render.sh"
  if [[ -x "$MOD_RENDER" ]]; then
    "$MOD_RENDER"
  fi
done
