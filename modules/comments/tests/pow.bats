#!/usr/bin/env bats

@test "passes with adequate PoW" {
  run "$BATS_TEST_DIRNAME/../scripts/verify_pow.sh" 0000007f75db211455fd35db352347bfd6babae3948ed15a6767fd02a6053309 22
  [ "$status" -eq 0 ]
}

@test "fails with insufficient PoW" {
  run "$BATS_TEST_DIRNAME/../scripts/verify_pow.sh" 000004ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff 22
  [ "$status" -ne 0 ]
}

@test "fails on invalid id" {
  run "$BATS_TEST_DIRNAME/../scripts/verify_pow.sh" nothex 22
  [ "$status" -ne 0 ]
}
