#!/usr/bin/env bats
# Tests for the pwa module installer and uninstaller.

setup() {
  # Move to the module root for predictable paths.
  cd "$(dirname "$BATS_TEST_FILENAME")/.."
}

teardown() {
  # Clean up any files produced during tests.
  rm -f .env .env.copy
}

# `install.sh` should copy `.env.sample` to `.env`.
@test "install creates .env from sample" {
  rm -f .env
  run ./install.sh
  [ "$status" -eq 0 ]
  run diff .env .env.sample
  [ "$status" -eq 0 ]
}

# Running install twice should leave `.env` unchanged.
@test "install is idempotent" {
  rm -f .env
  ./install.sh
  cp .env .env.copy
  ./install.sh
  run diff .env .env.copy
  [ "$status" -eq 0 ]
}

# `uninstall.sh` should delete the generated `.env`.
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
