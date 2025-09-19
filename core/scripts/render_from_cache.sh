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

# Escape HTML special characters so attribute values stay well-formed even when
# relay URLs or other fields contain quotes or angle brackets.
html_escape() {
  python3 - "$1" "${2:-}" << 'PY'
import html, sys
value = sys.argv[1]
keep_single = bool(sys.argv[2:])
escaped = html.escape(value, quote=True)
if keep_single:
    escaped = escaped.replace("&#x27;", "'")
print(escaped)
PY
}

# shellcheck source=/dev/null
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

CACHE_ROOT="${CACHE_ROOT:-$ROOT_DIR/../cache}"
TEMPLATE_DIR="$ROOT_DIR/templates"
PUBLIC_DIR="$ROOT_DIR/public"
export PUBLIC_DIR

INTERACT_ENABLE="${INTERACT_ENABLE:-1}"
if [[ "$INTERACT_ENABLE" != "0" ]]; then
  INTERACT_ENABLE=1
fi

INTERACT_LIMIT="${INTERACT_LIMIT:-80}"
if ! [[ "$INTERACT_LIMIT" =~ ^[0-9]+$ ]]; then
  INTERACT_LIMIT=80
fi

INTERACT_SHOW_REPLY="${INTERACT_SHOW_REPLY:-1}"
if [[ "$INTERACT_SHOW_REPLY" != "0" ]]; then
  INTERACT_SHOW_REPLY=1
fi

INTERACT_RELAYS_RAW="${INTERACT_RELAYS:-}"
if [[ -z "$INTERACT_RELAYS_RAW" ]]; then
  INTERACT_RELAYS_RAW='["/nostr"]'
fi

INTERACT_RELAYS_JSON=$(printf '%s' "$INTERACT_RELAYS_RAW" |
  jq -c '[.[]? | select(type=="string") | gsub("^\\s+|\\s+$"; "") | select(length > 0)]' 2> /dev/null || echo '[]')

mapfile -t INTERACT_RELAYS_LIST < <(printf '%s' "$INTERACT_RELAYS_JSON" | jq -r '.[]')

CONNECT_SRC="'self'"
declare -A CONNECT_SEEN=()
CONNECT_SEEN["'self'"]=1
for raw in "${INTERACT_RELAYS_LIST[@]}"; do
  relay=""
  case "$raw" in
  '')
    continue
    ;;
  /*)
    # Relative paths are already covered by 'self'.
    continue
    ;;
  wss://* | ws://*)
    relay="$raw"
    ;;
  https://*)
    relay="wss://${raw#https://}"
    ;;
  http://*)
    relay="ws://${raw#http://}"
    ;;
  *)
    if [[ "$raw" == *"://"* ]]; then
      relay="$raw"
    else
      continue
    fi
    ;;
  esac
  [[ -n "$relay" ]] || continue
  if [[ -z "${CONNECT_SEEN[$relay]:-}" ]]; then
    CONNECT_SRC+=" $relay"
    CONNECT_SEEN[$relay]=1
  fi
done

HEADER_TMP="$(mktemp)"
trap 'rm -f "$HEADER_TMP"' EXIT
CONNECT_HTML=$(html_escape "$CONNECT_SRC" keep)
python3 - "$TEMPLATE_DIR/header.html" "$HEADER_TMP" "$CONNECT_HTML" << 'PY'
import sys
source, dest, connect = sys.argv[1:4]
with open(source, "r", encoding="utf-8") as fh:
    template = fh.read()
with open(dest, "w", encoding="utf-8") as fh:
    fh.write(template.replace("__CONNECT_SRC__", connect, 1))
PY

# Ensure the output directory exists before we start writing files and copy static assets.
mkdir -p "$PUBLIC_DIR"
STATIC_SRC="${STATIC_SRC:-$ROOT_DIR/static}"
if [[ -d "$STATIC_SRC" ]]; then
  mkdir -p "$PUBLIC_DIR/static"
  cp -R "$STATIC_SRC"/. "$PUBLIC_DIR/static/"
fi

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

  event_id="$(jq -r '.id // empty' "$post")"
  addr="30023:${author}:${slug}"

  event_attr="$(html_escape "$event_id")"
  addr_attr="$(html_escape "$addr")"
  author_attr="$(html_escape "$author")"
  relays_attr="$(html_escape "$INTERACT_RELAYS_JSON")"
  limit_attr="$(html_escape "$INTERACT_LIMIT")"
  show_reply_attr="$(html_escape "$INTERACT_SHOW_REPLY")"

  # Write the rendered post using the shared header/footer templates.
  outdir="$PUBLIC_DIR/posts/$slug"
  mkdir -p "$outdir"
  body_attrs="data-event-id=\"$event_attr\" data-addr=\"$addr_attr\" data-author-pubkey=\"$author_attr\" data-relays=\"$relays_attr\" data-limit=\"$limit_attr\" data-show-reply=\"$show_reply_attr\""
  python3 - "$HEADER_TMP" "$outdir/index.html" "$body_attrs" << 'PY'
import sys
source, dest, attrs = sys.argv[1:4]
with open(source, "r", encoding="utf-8") as fh:
    template = fh.read()
with open(dest, "w", encoding="utf-8") as fh:
    fh.write(template.replace("<body>", f"<body {attrs}>", 1))
PY
  # shellcheck disable=SC2129
  printf '<main>\n%s\n</main>\n' "$body" >> "$outdir/index.html"
  cat >> "$outdir/index.html" << 'HTML'
<aside id="reactions" aria-label="Reactions">
  <span data-reaction="+">0</span>
  <span data-reaction="❤️">0</span>
</aside>
<section id="replies" aria-live="polite"></section>
<button id="load-more" hidden>Load more</button>
<button id="reply-btn" hidden>Reply</button>
HTML
  if [[ "$INTERACT_ENABLE" != 0 ]]; then
    echo '<script type="module" src="/static/js/snort.js" defer></script>' >> "$outdir/index.html"
  fi
  cat "$TEMPLATE_DIR/footer.html" >> "$outdir/index.html"
done

# Build the front-page index listing all posts.
INDEX_ENTRIES=""
for slug in "${!TITLES[@]}"; do
  INDEX_ENTRIES+="$slug|${TITLES[$slug]}\n"
done

# shellcheck disable=SC2129
cat "$HEADER_TMP" > "$PUBLIC_DIR/index.html"
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
  cat "$HEADER_TMP" > "$outdir/index.html"
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
  cat "$HEADER_TMP" > "$outdir/index.html"
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
