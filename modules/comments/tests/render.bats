#!/usr/bin/env bats

setup() {
  MODULE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  CORE_DIR="$MODULE_DIR/../../core"
  TMPDIR="$(mktemp -d)"
  export SNORT_ROOT="$TMPDIR/root"
  export CACHE_ROOT="$SNORT_ROOT/cache"
  export SITE_ROOT="$SNORT_ROOT/site"
  mkdir -p "$CACHE_ROOT/nostr-cache/posts" "$CACHE_ROOT/nostr-cache/replies/test-post"
  cat > "$CACHE_ROOT/nostr-cache/posts/test-post.json" << 'JSON'
{"content":"# Test\nbody","tags":[],"pubkey":"author"}
JSON
  echo '["test-post"]' > "$CACHE_ROOT/nostr-cache/index.json"
  cat > "$CACHE_ROOT/nostr-cache/replies/test-post/r1.json" << 'JSON'
{"id":"r1","content":"Hello *world*","created_at":1}
JSON
  cat << EOF_ENV > "$CORE_DIR/.env"
SNORT_ROOT=$SNORT_ROOT
CACHE_ROOT=$CACHE_ROOT
SITE_ROOT=$SITE_ROOT
MODULES=comments
EOF_ENV
}

teardown() {
  rm -rf "$TMPDIR"
  rm -f "$CORE_DIR/.env"
  rm -rf "$CORE_DIR/public"
}

@test "render hook writes replies fragments" {
  run "$CORE_DIR/scripts/render_from_cache.sh"
  [ "$status" -eq 0 ]
  [ -f "$CORE_DIR/public/posts/test-post/replies.html" ]
  grep -q '<li class="reply" data-id="nostr:r1">' "$CORE_DIR/public/posts/test-post/replies.html"
  grep -q '<em>world</em>' "$CORE_DIR/public/posts/test-post/replies.html"
}
