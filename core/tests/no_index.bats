#!/usr/bin/env bats

setup() {
  ROOT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  cd "$ROOT_DIR"
  PATH="$ROOT_DIR/tests/bin:$PATH"
  TMPDIR="$(mktemp -d)"
  export SNORT_ROOT="$TMPDIR/root"
  export CACHE_ROOT="$SNORT_ROOT/cache"
  export SITE_ROOT="$SNORT_ROOT/site"
  mkdir -p "$CACHE_ROOT/nostr-cache/posts"
  cat > "$CACHE_ROOT/nostr-cache/posts/test-post.json" << 'JSON'
{"content":"# Hello\nBody","tags":[],"pubkey":"author"}
JSON
  cat > .env << 'ENV'
SNORT_ROOT=$SNORT_ROOT
CACHE_ROOT=$CACHE_ROOT
SITE_ROOT=$SITE_ROOT
MODULES=
ENV
}

teardown() {
  rm -rf "$TMPDIR" .env public
}

@test "renders without index.json by scanning posts directory" {
  run ./scripts/render_from_cache.sh
  [ "$status" -eq 0 ]
  [ -f public/posts/test-post/index.html ]
}
