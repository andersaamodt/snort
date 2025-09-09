#!/usr/bin/env bats

setup() {
  ROOT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  cd "$ROOT_DIR"
  TMPDIR="$(mktemp -d)"
  export CACHE_ROOT="$TMPDIR/cache"
}

teardown() {
  rm -rf "$TMPDIR" ../modules/demo
}

@test "fetch runs nostr module when enabled" {
  export MODULES="nostr"
  run scripts/fetch.sh
  [ "$status" -eq 0 ]
  [ -f "$CACHE_ROOT/nostr-cache/index.json" ]
}

@test "fetch runs arbitrary module hooks" {
  mkdir -p ../modules/demo/scripts
  cat << 'EOF' > ../modules/demo/scripts/fetch.sh
#!/usr/bin/env bash
touch "$CACHE_ROOT/demo-ran"
EOF
  chmod +x ../modules/demo/scripts/fetch.sh
  export MODULES="nostr,demo"
  run scripts/fetch.sh
  [ "$status" -eq 0 ]
  [ -f "$CACHE_ROOT/nostr-cache/index.json" ]
  [ -f "$CACHE_ROOT/demo-ran" ]
}

@test "fetch is no-op when nostr not enabled" {
  export MODULES=""
  run scripts/fetch.sh
  [ "$status" -eq 0 ]
  [ ! -e "$CACHE_ROOT/nostr-cache/index.json" ]
}
