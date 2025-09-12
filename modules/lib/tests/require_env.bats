#!/usr/bin/env bats
# Tests for the require_env helper.

setup() {
  cd "$(dirname "$BATS_TEST_FILENAME")/.."
}

@test "require_env fails when variable missing" {
  source scripts/require_env.sh
  run require_env MISSING_VAR
  [ "$status" -ne 0 ]
}

@test "require_env succeeds when variable set" {
  source scripts/require_env.sh
  export PRESENT_VAR=1
  run require_env PRESENT_VAR
  [ "$status" -eq 0 ]
}
