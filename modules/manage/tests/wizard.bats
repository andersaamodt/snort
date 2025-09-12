#!/usr/bin/env bats
# Tests for the module management wizard.

setup() {
  cd "$(dirname "$BATS_TEST_FILENAME")/.."
  ROOT="$(cd ../.. && pwd)"
  export ROOT
  rm -f "$ROOT/.env" "$ROOT/modules/nostr/.env"
}

teardown() {
  rm -f "$ROOT/.env" "$ROOT/modules/nostr/.env"
}

@test "wizard enables selected module" {
  MODULES_AUTO=nostr run ./wizard.sh
  [ "$status" -eq 0 ]
  run grep '^MODULES=nostr' "$ROOT/.env"
  [ "$status" -eq 0 ]
  [ -f "$ROOT/modules/nostr/.env" ]
}

@test "wizard disables previously enabled module" {
  MODULES_AUTO=nostr ./wizard.sh
  [ -f "$ROOT/modules/nostr/.env" ]
  MODULES_AUTO="" run ./wizard.sh
  [ "$status" -eq 0 ]
  run grep '^MODULES=' "$ROOT/.env"
  [ "$status" -eq 0 ]
  [ ! -f "$ROOT/modules/nostr/.env" ]
}
