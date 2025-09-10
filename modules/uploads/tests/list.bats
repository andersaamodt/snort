#!/usr/bin/env bats

setup() {
  MODULE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  CORE_DIR="$MODULE_DIR/../../core"
  TMPDIR="$(mktemp -d)"
  export SNORT_ROOT="$TMPDIR/root"
  export UPLOADS_ROOT="$SNORT_ROOT/uploads"
  cat << EOF_ENV > "$CORE_DIR/.env"
SNORT_ROOT=$SNORT_ROOT
UPLOADS_ROOT=$UPLOADS_ROOT
UPLOAD_ROLES=admins,authors
EOF_ENV
  mkdir -p "$UPLOADS_ROOT"
  touch "$UPLOADS_ROOT/a.txt"
  touch "$UPLOADS_ROOT/b.txt"
}

teardown() {
  rm -rf "$TMPDIR"
  rm -f "$CORE_DIR/.env"
}

@test "list outputs files for allowed role" {
  export UPLOAD_ROLE=authors
  run "$MODULE_DIR/scripts/list.sh"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '. == ["a.txt","b.txt"]' > /dev/null
}

@test "list fails for disallowed role" {
  export UPLOAD_ROLE=guests
  run "$MODULE_DIR/scripts/list.sh"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "role not permitted" ]]
}
