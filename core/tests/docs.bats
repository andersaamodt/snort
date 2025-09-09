#!/usr/bin/env bats

setup() {
  ROOT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  cd "$ROOT_DIR"
}

@test "core docs are present" {
  [ -f QUICKSTART.md ]
  [ -f OPERATIONS.md ]
  [ -f SECURITY.md ]
  [ -f EXTENSIONS.md ]
  grep -q '^# Quickstart' QUICKSTART.md
  grep -q '^# Operations' OPERATIONS.md
  grep -q '^# Security' SECURITY.md
  grep -q '^# Extensions' EXTENSIONS.md
}
