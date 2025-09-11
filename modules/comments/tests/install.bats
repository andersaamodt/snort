#!/usr/bin/env bats
# Test suite for the comments module install/uninstall scripts.

# Before each test, move to the module root so paths resolve correctly.
setup() {
  cd "$(dirname "$BATS_TEST_FILENAME")/.."
}

# After each test, clean up any files the test may have created.
teardown() {
  rm -f .env .env.copy
}

# Installing should copy the sample configuration to a real one.
@test "install creates .env from sample" {
  rm -f .env
  run ./install.sh
  [ "$status" -eq 0 ]
  # The resulting file should be identical to the sample.
  run diff .env .env.sample
  [ "$status" -eq 0 ]
}

# Running install twice must not change the configuration.
@test "install is idempotent" {
  rm -f .env
  ./install.sh
  cp .env .env.copy
  ./install.sh
  run diff .env .env.copy
  [ "$status" -eq 0 ]
}

# Uninstall should remove the generated configuration file.
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
