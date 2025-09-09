#!/usr/bin/env bats

setup() {
  ROOT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  cd "$ROOT_DIR"
  TMPDIR="$(mktemp -d)"
  export SITE_ROOT="$TMPDIR/site"
}

teardown() {
  rm -rf "$TMPDIR"
  rm -f public/index.html
}

@test "release copies public to site root" {
  run scripts/render_from_cache.sh
  [ "$status" -eq 0 ]
  run scripts/release.sh
  [ "$status" -eq 0 ]
  [ -f "$SITE_ROOT/current/public/index.html" ]
  grep -q '<ul>' "$SITE_ROOT/current/public/index.html"
}
