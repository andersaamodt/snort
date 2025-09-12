#!/usr/bin/env bats
# Tests for the nostr module installer and uninstaller.

# Run tests from the module directory regardless of invocation location.
setup() {
  cd "$(dirname "$BATS_TEST_FILENAME")/.."
}

# Remove any files created during a test run.
teardown() {
  rm -f .env .env.copy
}

# Verify that `install.sh` generates `.env` from the sample template.
@test "install creates .env from sample" {
  rm -f .env
  run ./install.sh
  [ "$status" -eq 0 ]
  run diff .env .env.sample
  [ "$status" -eq 0 ]
}

# Check that running `install.sh` twice leaves the file unchanged.
@test "install is idempotent" {
  rm -f .env
  ./install.sh
  cp .env .env.copy
  ./install.sh
  run diff .env .env.copy
  [ "$status" -eq 0 ]
}

# Ensure that `uninstall.sh` removes the generated configuration.
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
