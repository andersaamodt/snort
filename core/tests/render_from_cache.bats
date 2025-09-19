#!/usr/bin/env bats

setup() {
  ROOT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  cd "$ROOT_DIR"
  PATH="$ROOT_DIR/tests/bin:$PATH"
  CACHE_DIR="$ROOT_DIR/cache"
  mkdir -p "$CACHE_DIR/nostr-cache/posts"
  cat > "$CACHE_DIR/nostr-cache/posts/hello.json" << 'JSON'
{"id":"evt1","content": "# Hello\n\nBody", "tags": [["t","intro"],["t","welcome"]], "pubkey": "alice"}
JSON
  cat > "$CACHE_DIR/nostr-cache/posts/second.json" << 'JSON'
{"id":"evt2","content": "# Second\n\nMore", "tags": [["t","intro"]], "pubkey": "bob"}
JSON
  cat > "$CACHE_DIR/nostr-cache/posts/third.json" << 'JSON'
{"id":"evt3","content": "# Third\n\nExtra", "tags": [["t","intro"]], "pubkey": "alice"}
JSON
  cat > "$CACHE_DIR/nostr-cache/index.json" << 'JSON'
["hello","second"]
JSON
  cat > .env << EOF2
CACHE_ROOT="$CACHE_DIR"
EOF2
}

teardown() {
  rm -rf public cache .env custom-static
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

  grep -q 'data-addr="30023:alice:hello"' public/posts/hello/index.html
  grep -F 'data-relays="[&quot;/nostr&quot;]"' public/posts/hello/index.html
  grep -q '<aside id="reactions"' public/posts/hello/index.html
  grep -q '<section id="replies"' public/posts/hello/index.html
  grep -q '<button id="load-more" hidden>Load more</button>' public/posts/hello/index.html
  grep -q '<button id="reply-btn" hidden>Reply</button>' public/posts/hello/index.html
  grep -q '<script type="module" src="/static/js/snort.js" defer></script>' public/posts/hello/index.html
  grep -q "Content-Security-Policy" public/posts/hello/index.html
  grep -q "connect-src 'self'" public/posts/hello/index.html
  ! grep -q '__CONNECT_SRC__' public/posts/hello/index.html
  [ -f public/static/js/snort.js ]

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

@test "interactivity disabled when INTERACT_ENABLE=0" {
  cat >> .env << 'ENV'
INTERACT_ENABLE=0
ENV
  run scripts/render_from_cache.sh
  [ "$status" -eq 0 ]
  ! grep -q '/static/js/snort.js' public/posts/hello/index.html
}

@test "CSP connect-src lists configured relay" {
  cat >> .env << 'ENV'
INTERACT_RELAYS='["wss://relay.example"]'
ENV
  run scripts/render_from_cache.sh
  [ "$status" -eq 0 ]
  grep -q "connect-src 'self' wss://relay.example" public/posts/hello/index.html
}

@test "CSP connect-src normalizes duplicates and schemes" {
  cat >> .env << 'ENV'
INTERACT_RELAYS='["https://relay.example","wss://relay.example","/nostr","http://localhost:7777"]'
ENV
  run scripts/render_from_cache.sh
  [ "$status" -eq 0 ]
  grep -q "connect-src 'self' wss://relay.example ws://localhost:7777" public/posts/hello/index.html
}

@test "interactivity attributes escape special characters" {
  cat >> .env << 'ENV'
INTERACT_RELAYS='["wss://relay.example/path?token=\"abc\"&q=1","wss://other.example/?x=<tag>"]'
ENV
  run scripts/render_from_cache.sh
  [ "$status" -eq 0 ]
  grep -F 'data-relays="[&quot;wss://relay.example/path?token=\&quot;abc\&quot;&amp;q=1&quot;' public/posts/hello/index.html
  grep -F '&lt;tag&gt;' public/posts/hello/index.html
}

@test "static assets copy tolerates dotfiles only" {
  mkdir -p custom-static
  touch custom-static/.keep
  cat >> .env << EOF
STATIC_SRC="$PWD/custom-static"
EOF
  run scripts/render_from_cache.sh
  [ "$status" -eq 0 ]
  [ -f public/static/.keep ]
}
