#!/usr/bin/env bats

setup() {
  ROOT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  cd "$ROOT_DIR"
}

teardown() {
  rm -f .env
}

@test "wizard creates .env from example" {
  run scripts/wizard.sh
  [ "$status" -eq 0 ]
  [ -f .env ]
  diff .env .env.example
}

@test "wizard refuses to overwrite existing .env" {
  touch .env
  run scripts/wizard.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *".env\" already exists"* ]]
}
