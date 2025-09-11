#!/usr/bin/env bats
# Tests for the video-mirror module installer/uninstaller.

setup() {
  # Execute tests from the module directory for consistent paths.
  cd "$(dirname "$BATS_TEST_FILENAME")/.."
}

teardown() {
  # Remove temporary files created during tests.
  rm -f .env .env.copy
}

# The installer should create `.env` from the sample file.
@test "install creates .env from sample" {
  rm -f .env
  run ./install.sh
  [ "$status" -eq 0 ]
  run diff .env .env.sample
  [ "$status" -eq 0 ]
}

# Running install twice shouldn't alter the file.
@test "install is idempotent" {
  rm -f .env
  ./install.sh
  cp .env .env.copy
  ./install.sh
  run diff .env .env.copy
  [ "$status" -eq 0 ]
}

# Uninstall should remove the created configuration file.
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
