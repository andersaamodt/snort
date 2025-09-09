#!/usr/bin/env bats

setup() {
  cd "$(dirname "$BATS_TEST_FILENAME")/.."
  tmpdir=$(mktemp -d)
}

teardown() {
  rm -rf "$tmpdir"
}

@test "verifies valid signature" {
  ssh-keygen -t ed25519 -N "" -f "$tmpdir/key" > /dev/null 2>&1
  echo "hello" > "$tmpdir/challenge"
  ssh-keygen -Y sign -f "$tmpdir/key" -n snort "$tmpdir/challenge" > /dev/null 2>&1
  run scripts/verify_challenge.sh "$tmpdir/key.pub" "$tmpdir/challenge" "$tmpdir/challenge.sig"
  [ "$status" -eq 0 ]
}

@test "fails when file missing" {
  ssh-keygen -t ed25519 -N "" -f "$tmpdir/key" > /dev/null 2>&1
  echo "hello" > "$tmpdir/challenge"
  ssh-keygen -Y sign -f "$tmpdir/key" -n snort "$tmpdir/challenge" > /dev/null 2>&1
  rm "$tmpdir/challenge.sig"
  run scripts/verify_challenge.sh "$tmpdir/key.pub" "$tmpdir/challenge" "$tmpdir/challenge.sig"
  [ "$status" -ne 0 ]
}

@test "fails on bad signature" {
  ssh-keygen -t ed25519 -N "" -f "$tmpdir/key1" > /dev/null 2>&1
  ssh-keygen -t ed25519 -N "" -f "$tmpdir/key2" > /dev/null 2>&1
  echo "hello" > "$tmpdir/challenge"
  ssh-keygen -Y sign -f "$tmpdir/key1" -n snort "$tmpdir/challenge" > /dev/null 2>&1
  run scripts/verify_challenge.sh "$tmpdir/key2.pub" "$tmpdir/challenge" "$tmpdir/challenge.sig"
  [ "$status" -ne 0 ]
}

@test "fails when challenge modified" {
  ssh-keygen -t ed25519 -N "" -f "$tmpdir/key" > /dev/null 2>&1
  echo "hello" > "$tmpdir/challenge"
  ssh-keygen -Y sign -f "$tmpdir/key" -n snort "$tmpdir/challenge" > /dev/null 2>&1
  echo "tamper" >> "$tmpdir/challenge"
  run scripts/verify_challenge.sh "$tmpdir/key.pub" "$tmpdir/challenge" "$tmpdir/challenge.sig"
  [ "$status" -ne 0 ]
}
