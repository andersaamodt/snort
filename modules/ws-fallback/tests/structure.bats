#!/usr/bin/env bats

setup() {
  cd "$(dirname "$BATS_TEST_FILENAME")/.."
}

@test "module has README" {
  [ -f README.md ]
}

@test "module has .env.sample" {
  [ -f .env.sample ]
}

@test "module has install script" {
  [ -f install.sh ]
}

@test "module has uninstall script" {
  [ -f uninstall.sh ]
}

@test "module has scripts directory" {
  [ -d scripts ]
}

@test "module has systemd service" {
  [ -f ops/snort-ws-fallback.service ]
}
