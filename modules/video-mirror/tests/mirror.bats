#!/usr/bin/env bats

setup() {
  MODULE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  CORE_DIR="$MODULE_DIR/../../core"
  TMPDIR="$(mktemp -d)"
  export SNORT_ROOT="$TMPDIR/root"
  export MIRRORS_ROOT="$SNORT_ROOT/mirrors"
  cat << EOF_ENV > "$CORE_DIR/.env"
SNORT_ROOT=$SNORT_ROOT
MIRRORS_ROOT=$MIRRORS_ROOT
EOF_ENV
  mkdir -p "$MIRRORS_ROOT"
  # ensure ffmpeg installed
  if ! command -v ffmpeg > /dev/null; then
    apt-get update > /dev/null && apt-get install -y ffmpeg > /dev/null
  fi
  ffmpeg -loglevel error -f lavfi -i color=c=black:s=16x16:d=1 -f lavfi -i anullsrc -c:v libx264 -preset ultrafast -crf 28 -c:a aac -shortest "$TMPDIR/in.mp4" > /dev/null 2>&1
}

teardown() {
  rm -rf "$TMPDIR"
  rm -f "$CORE_DIR/.env"
}

@test "mirror script stores raw and transcode" {
  run "$MODULE_DIR/scripts/mirror.sh" "$TMPDIR/in.mp4"
  [ "$status" -eq 0 ]
  [ -f "$MIRRORS_ROOT/raw/in.mp4" ]
  [ -f "$MIRRORS_ROOT/mp4/in.mp4" ]
}
