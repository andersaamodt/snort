#!/usr/bin/env bash

# Convert cached Nostr posts into static HTML.  The script reads Markdown from
# `$CACHE_ROOT/nostr-cache`, renders it with `lowdown`, builds index/tag/author
# pages, and finally lets each enabled module post-process the output via its
# optional `scripts/render.sh` hook.

set -euo pipefail

# Resolve root and load environment so we respect user configuration for paths
# like `CACHE_ROOT` and `PUBLIC_DIR`.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

# shellcheck source=/dev/null
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

CACHE_ROOT="${CACHE_ROOT:-$ROOT_DIR/../cache}"
TEMPLATE_DIR="$ROOT_DIR/templates"
PUBLIC_DIR="$ROOT_DIR/public"
export PUBLIC_DIR

# Ensure the output directory exists before we start writing files.
mkdir -p "$PUBLIC_DIR"

# Location of cached posts and the optional index file listing known slugs.
POSTS_DIR="$CACHE_ROOT/nostr-cache/posts"
INDEX_FILE="$CACHE_ROOT/nostr-cache/index.json"

# These associative arrays collect metadata while processing posts.
declare -A TITLES       # slug -> title
declare -A TAG_POSTS    # tag  -> newline separated slugs
declare -A AUTHOR_POSTS # pubkey -> newline separated slugs

# Determine which slugs to render. Prefer `index.json` for ordering; fall back
# to scanning the posts directory.
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

# Render each post and collect tag/author associations.
for slug in "${slugs[@]}"; do
  post="$POSTS_DIR/$slug.json"
  [[ -f "$post" ]] || continue

  # Markdown content → HTML body.
  content="$(jq -r '.content' "$post")"
  body="$(printf '%s' "$content" | lowdown -Thtml)"

  # Use the first Markdown heading as the title, falling back to the slug.
  title="$(printf '%s' "$content" | sed -n '1s/^# \(.*\)/\1/p')"
  [[ -n "$title" ]] || title="$slug"
  TITLES["$slug"]="$title"

  # Collect tags (kind-1 "t" entries) to build tag pages later.
  tags=$(jq -r '.tags[]? | select(.[0]=="t") | .[1]' "$post" | tr '\n' ' ')
  for tag in $tags; do
    TAG_POSTS["$tag"]+="$slug\n"
  done

  # Record the author pubkey for author pages if present.
  author="$(jq -r '.pubkey // empty' "$post")"
  if [[ -n "$author" ]]; then
    AUTHOR_POSTS["$author"]+="$slug\n"
  fi

  # Write the rendered post using the shared header/footer templates.
  outdir="$PUBLIC_DIR/posts/$slug"
  mkdir -p "$outdir"
  # shellcheck disable=SC2129
  cat "$TEMPLATE_DIR/header.html" > "$outdir/index.html"
  # shellcheck disable=SC2129
  printf '%s\n' "$body" >> "$outdir/index.html"
  cat "$TEMPLATE_DIR/footer.html" >> "$outdir/index.html"
done

# Build the front-page index listing all posts.
INDEX_ENTRIES=""
for slug in "${!TITLES[@]}"; do
  INDEX_ENTRIES+="$slug|${TITLES[$slug]}\n"
done

# shellcheck disable=SC2129
cat "$TEMPLATE_DIR/header.html" > "$PUBLIC_DIR/index.html"
# shellcheck disable=SC2129
echo "<ul>" >> "$PUBLIC_DIR/index.html"
while IFS='|' read -r slug title; do
  printf '  <li><a href="/posts/%s/">%s</a></li>\n' "$slug" "$title"
done >> "$PUBLIC_DIR/index.html" < <(printf '%b' "$INDEX_ENTRIES" | sort)
# shellcheck disable=SC2129
echo "</ul>" >> "$PUBLIC_DIR/index.html"
cat "$TEMPLATE_DIR/footer.html" >> "$PUBLIC_DIR/index.html"

# Generate tag index pages.
for tag in "${!TAG_POSTS[@]}"; do
  outdir="$PUBLIC_DIR/tags/$tag"
  mkdir -p "$outdir"
  # shellcheck disable=SC2129
  cat "$TEMPLATE_DIR/header.html" > "$outdir/index.html"
  # shellcheck disable=SC2129
  printf '<h1>Tag: %s</h1>\n<ul>\n' "$tag" >> "$outdir/index.html"
  while read -r slug; do
    title="${TITLES[$slug]}"
    printf '  <li><a href="/posts/%s/">%s</a></li>\n' "$slug" "$title"
  done >> "$outdir/index.html" < <(printf '%b' "${TAG_POSTS[$tag]}" | sort)
  # shellcheck disable=SC2129
  echo '</ul>' >> "$outdir/index.html"
  cat "$TEMPLATE_DIR/footer.html" >> "$outdir/index.html"
done

# Generate author index pages using the collected pubkeys.
for author in "${!AUTHOR_POSTS[@]}"; do
  outdir="$PUBLIC_DIR/authors/$author"
  mkdir -p "$outdir"
  # shellcheck disable=SC2129
  cat "$TEMPLATE_DIR/header.html" > "$outdir/index.html"
  # shellcheck disable=SC2129
  printf '<h1>Author: %s</h1>\n<ul>\n' "$author" >> "$outdir/index.html"
  while read -r slug; do
    title="${TITLES[$slug]}"
    printf '  <li><a href="/posts/%s/">%s</a></li>\n' "$slug" "$title"
  done >> "$outdir/index.html" < <(printf '%b' "${AUTHOR_POSTS[$author]}" | sort)
  # shellcheck disable=SC2129
  echo '</ul>' >> "$outdir/index.html"
  cat "$TEMPLATE_DIR/footer.html" >> "$outdir/index.html"
done

# Finally, allow modules to inject additional render steps. If a module provides
# `scripts/render.sh`, execute it now so it can augment the site with its own
# fragments or assets.
MODULES="${MODULES:-}"
IFS=',' read -r -a mods <<< "$MODULES"
for mod in "${mods[@]}"; do
  [[ -n "$mod" ]] || continue
  MOD_RENDER="$ROOT_DIR/../modules/$mod/scripts/render.sh"
  if [[ -x "$MOD_RENDER" ]]; then
    "$MOD_RENDER"
  fi
done
