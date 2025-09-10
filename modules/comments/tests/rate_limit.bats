#!/usr/bin/env bats

setup_file() {
  cd "$(dirname "$BATS_TEST_FILENAME")/.."
  if ! command -v redis-server > /dev/null; then
    apt-get update > /dev/null && apt-get install -y redis-server > /dev/null
  fi
  redis-server --save "" --appendonly no --port 6382 > /tmp/redis-rl.log 2>&1 &
  REDIS_PID=$!
  sleep 1
}

teardown_file() {
  kill "$REDIS_PID"
}

@test "pub rate limit enforced" {
  export REDIS_URL=redis://127.0.0.1:6382 RATE_IP_PER_MIN=100 RATE_PUB_PER_MIN=1
  run scripts/rate_limit.sh 1.2.3.4 npub1
  [ "$status" -eq 0 ]
  run scripts/rate_limit.sh 1.2.3.4 npub1
  [ "$status" -ne 0 ]
}

@test "ip rate limit enforced" {
  export REDIS_URL=redis://127.0.0.1:6382 RATE_IP_PER_MIN=2 RATE_PUB_PER_MIN=100
  run scripts/rate_limit.sh 9.9.9.9 npub1
  [ "$status" -eq 0 ]
  run scripts/rate_limit.sh 9.9.9.9 npub2
  [ "$status" -eq 0 ]
  run scripts/rate_limit.sh 9.9.9.9 npub3
  [ "$status" -ne 0 ]
}
