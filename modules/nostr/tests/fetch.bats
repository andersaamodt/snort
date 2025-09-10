#!/usr/bin/env bats

setup() {
  MODULE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  cd "$MODULE_DIR"
  TMPDIR="$(mktemp -d)"
  export CACHE_ROOT="$TMPDIR/cache"
  export LOG_ROOT="$TMPDIR/logs"
  mkdir -p "$TMPDIR/bin"
  PATH="$TMPDIR/bin:$PATH"

  cat << 'EOF' > "$TMPDIR/bin/nostr-cli"
#!/usr/bin/env bash
if [[ "$*" == *"--kinds 30023"* ]]; then
cat <<'JSON'
[
  {
    "kind":30023,
    "pubkey":"npub1test",
    "content":"# Title\nBody",
    "tags":[["d","slug-a"],["title","Title"]]
  }
]
JSON
elif [[ "$*" == *"--kinds 0"* ]]; then
cat <<'JSON'
[
  {
    "kind":0,
    "pubkey":"npub1test",
    "content":"{\"name\":\"Alice\"}"
  }
]
JSON
elif [[ "$*" == *"--kinds 1"* ]]; then
cat <<'JSON'
[
  {
    "kind":1,
    "id":"reply1",
    "content":"first reply"
  }
]
JSON
elif [[ "$*" == *"--kinds 9735"* ]]; then
cat <<'JSON'
[
  {
    "kind":9735,
    "id":"zap1",
    "content":"zap receipt"
  }
]
JSON
else
  echo "[]"
fi
EOF
  chmod +x "$TMPDIR/bin/nostr-cli"
}

teardown() {
  rm -rf "$TMPDIR"
}

@test "nostr fetch populates cache" {
  run scripts/fetch.sh
  [ "$status" -eq 0 ]
  [ -f "$CACHE_ROOT/nostr-cache/index.json" ]
  [ -f "$CACHE_ROOT/nostr-cache/posts/slug-a.json" ]
  [ -f "$CACHE_ROOT/nostr-cache/profiles/npub1test.json" ]
  [ -f "$CACHE_ROOT/nostr-cache/replies/slug-a/reply1.json" ]
  [ -f "$CACHE_ROOT/nostr-cache/zaps/slug-a/zap1.json" ]
  [ -f "$LOG_ROOT/nostr-fetch.log" ]
  grep -q 'fetch start' "$LOG_ROOT/nostr-fetch.log"
  grep -q 'Alice' "$CACHE_ROOT/nostr-cache/profiles/npub1test.json"
  slug=$(jq -r '.[0]' "$CACHE_ROOT/nostr-cache/index.json")
  [ "$slug" = "slug-a" ]
}
