#!/usr/bin/env bats

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../scripts" && pwd)"
}

@test "provisioning disabled" {
  export UNIX_PROVISION_ALLOWED=0
  export UNIX_DEFAULT_GROUP=nogroup
  export UNIX_HOME_BASE="$BATS_TEST_TMPDIR/home"
  run "$SCRIPTS_DIR/provision_user.sh" foo key.pub
  [ "$status" -eq 1 ]
}

@test "creates user and installs key" {
  username="snorttestuser"
  group="snortgrp"
  keyfile="$BATS_TEST_TMPDIR/id_ed25519.pub"
  echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMockKeyForTests test" > "$keyfile"
  getent passwd "$username" > /dev/null && userdel -r "$username"
  getent group "$group" > /dev/null && groupdel "$group"
  groupadd "$group"
  export UNIX_PROVISION_ALLOWED=1
  export UNIX_DEFAULT_GROUP="$group"
  export UNIX_HOME_BASE="$BATS_TEST_TMPDIR/home"
  run "$SCRIPTS_DIR/provision_user.sh" "$username" "$keyfile"
  [ "$status" -eq 0 ]
  id "$username" > /dev/null
  [ -f "$UNIX_HOME_BASE/$username/.ssh/authorized_keys" ]
  grep -q "MockKeyForTests" "$UNIX_HOME_BASE/$username/.ssh/authorized_keys"
  userdel -r "$username"
  groupdel "$group"
}
