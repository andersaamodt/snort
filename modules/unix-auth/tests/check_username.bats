#!/usr/bin/env bats

setup() {
  cd "$(dirname "$BATS_TEST_FILENAME")/.."
}

@test "fails on invalid characters" {
  run scripts/check_username.sh 'bad!'
  [ "$status" -ne 0 ]
}

@test "fails on digits or hyphens" {
  run scripts/check_username.sh 'user-1'
  [ "$status" -ne 0 ]
}

@test "fails when longer than 32 chars" {
  run scripts/check_username.sh 'averylongusernamethatisoverthirtytwochars'
  [ "$status" -ne 0 ]
}

@test "fails on existing user" {
  run scripts/check_username.sh 'root'
  [ "$status" -ne 0 ]
}

@test "succeeds on unused name" {
  run scripts/check_username.sh 'snorttestuser'
  [ "$status" -eq 0 ]
}
