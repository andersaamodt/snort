#!/usr/bin/env bats
# Tests for the zaps module installer and uninstaller.

setup() {
  # Ensure commands run relative to the module directory.
  cd "$(dirname "$BATS_TEST_FILENAME")/.."
}

teardown() {
  # Clean up any files the tests created.
  rm -f .env .env.copy
}

# Installing should copy `.env.sample` to `.env`.
@test "install creates .env from sample" {
  rm -f .env
  run ./install.sh
  [ "$status" -eq 0 ]
  run diff .env .env.sample
  [ "$status" -eq 0 ]
}

# Running install again must not alter the file.
@test "install is idempotent" {
  rm -f .env
  ./install.sh
  cp .env .env.copy
  ./install.sh
  run diff .env .env.copy
  [ "$status" -eq 0 ]
}

# The uninstaller should delete the `.env` file.
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
