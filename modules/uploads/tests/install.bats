#!/usr/bin/env bats
# Tests for the uploads module installer and uninstaller.

setup() {
  # Run from the module root for consistent file paths.
  cd "$(dirname "$BATS_TEST_FILENAME")/.."
}

teardown() {
  # Clean up files created during tests.
  rm -f .env .env.copy
}

# Installing should copy the sample configuration.
@test "install creates .env from sample" {
  rm -f .env
  run ./install.sh
  [ "$status" -eq 0 ]
  run diff .env .env.sample
  [ "$status" -eq 0 ]
}

# Re-running install must not modify `.env`.
@test "install is idempotent" {
  rm -f .env
  ./install.sh
  cp .env .env.copy
  ./install.sh
  run diff .env .env.copy
  [ "$status" -eq 0 ]
}

# Uninstall should remove the generated file.
@test "uninstall removes .env" {
  ./install.sh
  [ -f .env ]
  ./uninstall.sh
  [ ! -f .env ]
}

# Uninstalling when `.env` is missing should still succeed.
@test "uninstall succeeds when .env missing" {
  rm -f .env
  run ./uninstall.sh
  [ "$status" -eq 0 ]
}
