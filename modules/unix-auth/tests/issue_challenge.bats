#!/usr/bin/env bats

setup() {
  cd "$(dirname "$BATS_TEST_FILENAME")/.."
  tmpdir=$(mktemp -d)
  export RUNTIME_ROOT="$tmpdir/run"
}

teardown() {
  rm -rf "$tmpdir"
}

@test "emits challenge file path" {
  run scripts/issue_challenge.sh
  [ "$status" -eq 0 ]
  [ -f "$output" ]
  [ -s "$output" ]
}

@test "fails without RUNTIME_ROOT" {
  unset RUNTIME_ROOT
  run scripts/issue_challenge.sh
  [ "$status" -ne 0 ]
}
