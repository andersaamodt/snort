#!/usr/bin/env bats
# Tests for the ws-fallback module installer and uninstaller.

setup() {
  # Change to the module directory for reliable relative paths.
  cd "$(dirname "$BATS_TEST_FILENAME")/.."
}

teardown() {
  # Remove any temporary files created by tests.
  rm -f .env .env.copy
}

# Installing should create `.env` from the sample file.
@test "install creates .env from sample" {
  rm -f .env
  run ./install.sh
  [ "$status" -eq 0 ]
  run diff .env .env.sample
  [ "$status" -eq 0 ]
}

# Install should be safe to run multiple times.
@test "install is idempotent" {
  rm -f .env
  ./install.sh
  cp .env .env.copy
  ./install.sh
  run diff .env .env.copy
  [ "$status" -eq 0 ]
}

# The uninstaller must remove the configuration file.
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
