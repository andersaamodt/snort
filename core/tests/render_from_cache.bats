#!/usr/bin/env bats

setup() {
  ROOT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  cd "$ROOT_DIR"
  CACHE_DIR="$ROOT_DIR/cache"
  mkdir -p "$CACHE_DIR/nostr-cache/posts"
  cat > "$CACHE_DIR/nostr-cache/posts/hello.json" << 'JSON'
{"content": "# Hello\n\nBody", "tags": [["t","intro"],["t","welcome"]], "pubkey": "alice"}
JSON
  cat > "$CACHE_DIR/nostr-cache/posts/second.json" << 'JSON'
{"content": "# Second\n\nMore", "tags": [["t","intro"]], "pubkey": "bob"}
JSON
  cat > "$CACHE_DIR/nostr-cache/posts/third.json" << 'JSON'
{"content": "# Third\n\nExtra", "tags": [["t","intro"]], "pubkey": "alice"}
JSON
  cat > "$CACHE_DIR/nostr-cache/index.json" << 'JSON'
["hello","second"]
JSON
  cat > .env << EOF2
CACHE_ROOT="$CACHE_DIR"
EOF2
}

teardown() {
  rm -rf public cache .env
}

@test "render_from_cache builds index, posts, tags, authors" {
  run scripts/render_from_cache.sh
  [ "$status" -eq 0 ]

  [ -f public/index.html ]
  grep -q '<a href="/posts/hello/">Hello</a>' public/index.html
  grep -q '<a href="/posts/second/">Second</a>' public/index.html
  ! grep -q '/posts/third/' public/index.html

  [ -f public/posts/hello/index.html ]
  [ -f public/posts/second/index.html ]
  grep -q '<h1 id="hello">Hello</h1>' public/posts/hello/index.html
  grep -q '<h1 id="second">Second</h1>' public/posts/second/index.html
  [ ! -f public/posts/third/index.html ]

  [ -f public/tags/intro/index.html ]
  [ -f public/tags/welcome/index.html ]
  grep -q '/posts/hello/' public/tags/intro/index.html
  grep -q '/posts/second/' public/tags/intro/index.html
  grep -q '/posts/hello/' public/tags/welcome/index.html
  ! grep -q '/posts/third/' public/tags/intro/index.html

  [ -f public/authors/alice/index.html ]
  [ -f public/authors/bob/index.html ]
  grep -q '/posts/hello/' public/authors/alice/index.html
  grep -q '/posts/second/' public/authors/bob/index.html
  ! grep -q '/posts/third/' public/authors/alice/index.html
}
