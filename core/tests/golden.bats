#!/usr/bin/env bats

setup() {
  ROOT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  cd "$ROOT_DIR"
  TMPDIR="$(mktemp -d)"
  export SNORT_ROOT="$TMPDIR/root"
  export CACHE_ROOT="$SNORT_ROOT/cache"
  export SITE_ROOT="$SNORT_ROOT/site"
  mkdir -p "$CACHE_ROOT/nostr-cache/posts"
  cat > "$CACHE_ROOT/nostr-cache/posts/test-post.json" << 'JSON'
{"content":"# Hello\nBody","tags":[],"pubkey":"author"}
JSON
  echo '["test-post"]' > "$CACHE_ROOT/nostr-cache/index.json"
  cat > .env << EOF
SNORT_ROOT=$SNORT_ROOT
CACHE_ROOT=$CACHE_ROOT
SITE_ROOT=$SITE_ROOT
MODULES=
EOF
}

teardown() {
  rm -rf "$TMPDIR" .env public
}

@test "render output matches fixtures" {
  run ./scripts/render_from_cache.sh
  [ "$status" -eq 0 ]
  diff -u tests/fixtures/index.html public/index.html
  diff -u tests/fixtures/test-post.html public/posts/test-post/index.html
}
