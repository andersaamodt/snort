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
EOF_ENV
  mkdir -p "$UPLOADS_ROOT"
  SRC_FILE="$TMPDIR/src.txt"
  echo 'hello' > "$SRC_FILE"
}

teardown() {
  rm -rf "$TMPDIR"
  rm -f "$CORE_DIR/.env"
}

@test "upload script copies file" {
  run "$MODULE_DIR/scripts/upload.sh" "$SRC_FILE"
  [ "$status" -eq 0 ]
  dest="$UPLOADS_ROOT/$(basename "$SRC_FILE")"
  [ -f "$dest" ]
  grep -q 'hello' "$dest"
}
