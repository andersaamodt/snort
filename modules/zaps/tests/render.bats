#!/usr/bin/env bats

setup() {
  MODULE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  CORE_DIR="$MODULE_DIR/../../core"
  TMPDIR="$(mktemp -d)"
  export SNORT_ROOT="$TMPDIR/root"
  export CACHE_ROOT="$SNORT_ROOT/cache"
  export SITE_ROOT="$SNORT_ROOT/site"
  mkdir -p "$CACHE_ROOT/nostr-cache/posts" "$CACHE_ROOT/nostr-cache/zaps/test-post"
  cat > "$CACHE_ROOT/nostr-cache/posts/test-post.json" << 'JSON'
{"content":"# Test\nbody","tags":[],"pubkey":"author"}
JSON
  echo '["test-post"]' > "$CACHE_ROOT/nostr-cache/index.json"
  cat > "$CACHE_ROOT/nostr-cache/zaps/test-post/z1.json" << 'JSON'
{"id":"z1","amount":100000,"content":"Great *post*","created_at":1}
JSON
  cat << EOF_ENV > "$CORE_DIR/.env"
SNORT_ROOT=$SNORT_ROOT
CACHE_ROOT=$CACHE_ROOT
SITE_ROOT=$SITE_ROOT
MODULES=zaps
EOF_ENV
}

teardown() {
  rm -rf "$TMPDIR"
  rm -f "$CORE_DIR/.env"
  rm -rf "$CORE_DIR/public"
}

@test "render hook writes zaps fragments" {
  run "$CORE_DIR/scripts/render_from_cache.sh"
  [ "$status" -eq 0 ]
  [ -f "$CORE_DIR/public/posts/test-post/zaps.html" ]
  grep -q '<li class="zap" data-id="zap:z1">' "$CORE_DIR/public/posts/test-post/zaps.html"
  grep -q '100 sats' "$CORE_DIR/public/posts/test-post/zaps.html"
  grep -q '<em>post</em>' "$CORE_DIR/public/posts/test-post/zaps.html"
}
