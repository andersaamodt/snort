#!/usr/bin/env bats

setup() {
  MODULE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  CORE_DIR="$MODULE_DIR/../../core"
  TMPDIR="$(mktemp -d)"
  export SNORT_ROOT="$TMPDIR/root"
  export CACHE_ROOT="$SNORT_ROOT/cache"
  export SITE_ROOT="$SNORT_ROOT/site"
  mkdir -p "$CACHE_ROOT/nostr-cache"
  echo '[]' > "$CACHE_ROOT/nostr-cache/index.json"
  cat << EOF_ENV > "$CORE_DIR/.env"
SNORT_ROOT=$SNORT_ROOT
CACHE_ROOT=$CACHE_ROOT
SITE_ROOT=$SITE_ROOT
MODULES=pwa
EOF_ENV
}

teardown() {
  rm -rf "$TMPDIR"
  rm -f "$CORE_DIR/.env"
  rm -f "$CORE_DIR/public/manifest.json" "$CORE_DIR/public/sw.js" "$CORE_DIR/public/index.html"
  rm -rf "$CORE_DIR/public/posts" "$CORE_DIR/public/tags" "$CORE_DIR/public/authors"
}

@test "render hook writes manifest and service worker" {
  run "$CORE_DIR/scripts/render_from_cache.sh"
  [ "$status" -eq 0 ]
  [ -f "$CORE_DIR/public/manifest.json" ]
  [ -f "$CORE_DIR/public/sw.js" ]
  grep -q 'Snort' "$CORE_DIR/public/manifest.json"
}
