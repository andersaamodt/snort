#!/usr/bin/env bats

setup() {
  MODULE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  CORE_DIR="$MODULE_DIR/../../core"
  TMPDIR="$(mktemp -d)"
  export SNORT_ROOT="$TMPDIR/root"
  export UPLOADS_ROOT="$SNORT_ROOT/uploads"
  export LOG_ROOT="$SNORT_ROOT/logs"
  cat << EOF_ENV > "$CORE_DIR/.env"
SNORT_ROOT=$SNORT_ROOT
UPLOADS_ROOT=$UPLOADS_ROOT
LOG_ROOT=$LOG_ROOT
UPLOAD_ROLES=admins,authors
UPLOAD_MAX_MB=1
EOF_ENV
  mkdir -p "$UPLOADS_ROOT"
  SRC_FILE="$TMPDIR/src.txt"
  echo 'hello' > "$SRC_FILE"
}

teardown() {
  rm -rf "$TMPDIR"
  rm -f "$CORE_DIR/.env"
}

@test "upload succeeds for allowed role" {
  export UPLOAD_ROLE=admins
  run "$MODULE_DIR/scripts/upload.sh" "$SRC_FILE"
  [ "$status" -eq 0 ]
  dest="$UPLOADS_ROOT/$(basename "$SRC_FILE")"
  [ -f "$dest" ]
  grep -q 'hello' "$dest"
  [ -f "$LOG_ROOT/uploads.log" ]
}

@test "upload fails for disallowed role" {
  export UPLOAD_ROLE=guests
  run "$MODULE_DIR/scripts/upload.sh" "$SRC_FILE"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "role not permitted" ]]
}

@test "upload fails when file too large" {
  export UPLOAD_ROLE=admins
  big="$TMPDIR/big.bin"
  dd if=/dev/zero bs=1M count=2 of="$big" > /dev/null 2>&1
  run "$MODULE_DIR/scripts/upload.sh" "$big"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "file too large" ]]
}
